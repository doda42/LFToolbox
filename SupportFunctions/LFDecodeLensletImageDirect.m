% LFDecodeLensletImageDirect - decodes a 2D lenslet image into a 4D light field, called by LFUtilDecodeLytroFolder
%
% Usage:
%
%   [LF, LFWeight, DecodeOptions, DebayerLensletImage] = ...
%      LFDecodeLensletImageDirect( LensletImage, WhiteImage, LensletGridModel, DecodeOptions )
%
% This function follows the simple decode process described in:
% D. G. Dansereau, O. Pizarro, and S. B. Williams, "Decoding, calibration and rectification for
% lenslet-based plenoptic cameras," in Computer Vision and Pattern Recognition (CVPR), IEEE
% Conference on. IEEE, Jun 2013.
%
% This involves demosaicing, devignetting, transforming and slicing the input lenslet image to
% yield a 4D structure. More sophisticated approaches exist which combine steps into joint
% solutions, and they generally yield superior results, particularly near the edges of lenslets.
% The approach taken here was chosen for its simplicity and flexibility.
%
% Input LensletImage is a raw lenslet iamge as found within Lytro's LFP picture files. Though
% this function is written with Lytro imagery in mind, it should be possible to adapt it for use
% with other lenslet-based cameras. LensletImage is ideally of type uint16.
%
% Input WhiteImage is a white image as found within Lytro's calibration data. A white image is an
% image taken through a diffuser, and is useful for removing vignetting (darkening near edges of
% images) and for locating lenslet centers. The white image should be taken under the same zoom and
% focus settings as the light field. In the case of Lytro imagery, the helper functions
% LFUtilProcessWhiteImages and LFSelectFromDatabase are provided to assist in forming a list of
% available white images, and selecting the appropriate image based on zoom and focus settings.
%
% Input LensletGridModel is a model of the lenslet grid, as estimated, for example, using
% LFBuildLensletGridModel -- see that function for more on the required structure.
%
% Optional Input DecodeOptions is a structure containing:
%          [Optional] ResampMethod : 'fast'(default) or 'triangulation', the latter is slower
%          [Optional]   Precision : 'single'(default) or 'double'
%          [Optional] LevelLimits : a two-element vector defining the black and white levels
%
% Output LF is a 5D array of size [Nj,Ni,Nl,Nk,3]. See [1] and the documentation accompanying this
% toolbox for a brief description of the light field structure.
%
% Optional output LFWeight is of size [Nj,Ni,Nl,Nk]. LFWeight contains a confidence measure
% suitable for use in filtering applications that accept a weight parameter. This parameter is kept
% separate from LF rather than building in as a fourth channel in order to allow an optimization:
% when the parameter is not requested, it is not computed, saving significant processing time and
% memory.
%
% Optional output DebayerLensletImage is useful for inspecting intermediary results. The debayered
% lenslet image is the result of devignetting and debayering, with no further processing. Omitting
% this output variable saves memory.
%
% A less direct / slower version of this function LFDecodeLensletImageSimple also generates an
% intermediate CorrectedLensletImage that has been rotated and scaled to an integer-spaced grid.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFLytroDecodeImage, LFUtilDecodeLytroFolder, LFDecodeLensletImageSimple

% Copyright (c) 2013-2020 Donald G. Dansereau

function [LF, LFWeight, DecodeOptions, DebayerLensletImage] = ...
    LFDecodeLensletImageDirect( LensletImage, WhiteImage, LensletGridModel, DecodeOptions )

%---Defaults---
 % LevelLimits defaults are a failsafe, should be passed in / come from the white image metadata
DecodeOptions = LFDefaultField( 'DecodeOptions', 'LevelLimits', [min(WhiteImage(:)), max(WhiteImage(:))] );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'ResampMethod', 'fast' ); %'fast', 'triangulation'
DecodeOptions = LFDefaultField( 'DecodeOptions', 'Precision', 'single' );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'DoDehex', true );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'DoSquareST', true );

%---Rescale image values, remove black level---
DecodeOptions.LevelLimits = cast(DecodeOptions.LevelLimits, DecodeOptions.Precision);
BlackLevel = DecodeOptions.LevelLimits(1);
WhiteLevel = DecodeOptions.LevelLimits(2);
WhiteImage = cast(WhiteImage, DecodeOptions.Precision);
WhiteImage = (WhiteImage - BlackLevel) ./ (WhiteLevel - BlackLevel);

LensletImage = cast(LensletImage, DecodeOptions.Precision);
LensletImage = (LensletImage - BlackLevel) ./ (WhiteLevel - BlackLevel);
LensletImage = LensletImage ./ WhiteImage; % Devignette
% Clip -- this is aggressive and throws away bright areas; there is a potential for an HDR approach here
LensletImage = min(1, max(0, LensletImage));

if( nargout < 2 )
    clear WhiteImage
end

%---Demosaic---
% This uses Matlab's demosaic, which is "gradient compensated". This likely has implications near
% the edges of lenslet images, where the contrast is due to vignetting / aperture shape, and is not
% a desired part of the image
LensletImage = cast(LensletImage.*double(intmax('uint16')), 'uint16');
LensletImage = demosaic(LensletImage, DecodeOptions.DemosaicOrder);
LensletImage = cast(LensletImage, DecodeOptions.Precision);
LensletImage = LensletImage ./  double(intmax('uint16'));
DecodeOptions.NColChans = 3;

if( nargout >= 2 )
    DecodeOptions.NWeightChans = 1;
else
    DecodeOptions.NWeightChans = 0;
end

if( nargout > 3 )
    DebayerLensletImage = LensletImage;
end

%---Tranform to an integer-spaced grid---
fprintf('\nAligning image to lenslet array...');
InputSpacing = [LensletGridModel.HSpacing, LensletGridModel.VSpacing];
NewLensletSpacing = ceil(InputSpacing);
% Force even so hex shift is a whole pixel multiple
NewLensletSpacing = ceil(NewLensletSpacing/2)*2;
XformScale = NewLensletSpacing ./ InputSpacing;  % Notice the resized image will not be square

NewOffset = [LensletGridModel.HOffset, LensletGridModel.VOffset] .* XformScale;
RoundedOffset = round(NewOffset);
XformTrans =  RoundedOffset-NewOffset;

NewLensletGridModel = struct('HSpacing',NewLensletSpacing(1), 'VSpacing',NewLensletSpacing(2), ...
    'HOffset',RoundedOffset(1), 'VOffset',RoundedOffset(2), 'Rot',0, ...
    'UMax', LensletGridModel.UMax, 'VMax', LensletGridModel.VMax, 'Orientation', LensletGridModel.Orientation, ...
    'FirstPosShiftRow', LensletGridModel.FirstPosShiftRow);

%---Fix image rotation and scale---
RRot = LFRotz( LensletGridModel.Rot );

RScale = eye(3);
RScale(1,1) = XformScale(1);
RScale(2,2) = XformScale(2);
DecodeOptions.OutputScale(1:2) = XformScale;
DecodeOptions.OutputScale(3:4) = [1,2/sqrt(3)];  % hex sampling

RTrans = eye(3);
RTrans(end,1:2) = XformTrans;

% The following rotation can rotate parts of the lenslet image out of frame.
% todo[optimization]: attempt to keep these regions, offer greater user-control of what's kept
FixAll = RRot*RScale*RTrans;
LensletImage(:,:,4) = WhiteImage;
clear WhiteImage
LF = SliceXYImage( FixAll, NewLensletGridModel, LensletImage, DecodeOptions );
clear LensletImage

%---Correct for hex grid and resize to square u,v pixels---
LFSize = size(LF);
HexAspect = 2/sqrt(3);
switch( DecodeOptions.ResampMethod )
    case 'fast'
        fprintf('\nResampling (1D approximation) to square u,v pixels');
        NewUVec = 0:1/HexAspect:(size(LF,4)+1);  % overshoot then trim
        NewUVec = NewUVec(1:ceil(LFSize(4)*HexAspect));
        OrigUSize = size(LF,4);
        LFSize(4) = length(NewUVec);
        %---Allocate dest and copy orig LF into it (memory saving vs. keeping both separately)---
        LF2 = zeros(LFSize, DecodeOptions.Precision);
        LF2(:,:,:,1:OrigUSize,:) = LF;
        LF = LF2;
        clear LF2
        
        if( DecodeOptions.DoDehex )
            ShiftUVec = -0.5+NewUVec;
            fprintf(' and removing hex sampling...');
        else
            ShiftUVec = NewUVec;
            fprintf('...');
        end
        for( ColChan = 1:size(LF,5) )
            CurUVec = ShiftUVec;
            for( RowIter = 1:2 )
                RowIdx = mod(NewLensletGridModel.FirstPosShiftRow + RowIter, 2) + 1;
                ShiftRows = squeeze(LF(:,:,RowIdx:2:end,1:OrigUSize, ColChan));
                SliceSize = size(ShiftRows);
                SliceSize(4) = length(NewUVec);
                ShiftRows = reshape(ShiftRows, [size(ShiftRows,1)*size(ShiftRows,2)*size(ShiftRows,3), size(ShiftRows,4)]);
                ShiftRows = interp1( (0:size(ShiftRows,2)-1)', ShiftRows', CurUVec' )';
                ShiftRows(isnan(ShiftRows)) = 0;
                LF(:,:,RowIdx:2:end,:,ColChan) = reshape(ShiftRows,SliceSize);
                CurUVec = NewUVec;
            end
        end
        clear ShiftRows
        DecodeOptions.OutputScale(3) = DecodeOptions.OutputScale(3) * HexAspect;
        
    case 'triangulation'
        fprintf('\nResampling (triangulation) to square u,v pixels');
        OldVVec = (0:size(LF,3)-1);
        OldUVec = (0:size(LF,4)-1) * HexAspect;
        
        NewUVec = (0:ceil(LFSize(4)*HexAspect)-1);
        NewVVec = (0:LFSize(3)-1);
        LFSize(4) = length(NewUVec);
        LF2 = zeros(LFSize, DecodeOptions.Precision);
        
        [Oldvv,Olduu] = ndgrid(OldVVec,OldUVec);
        [Newvv,Newuu] = ndgrid(NewVVec,NewUVec);
        if( DecodeOptions.DoDehex )
            fprintf(' and removing hex sampling...');
            FirstShiftRow = NewLensletGridModel.FirstPosShiftRow;
            Olduu(FirstShiftRow:2:end,:) = Olduu(FirstShiftRow:2:end,:) + HexAspect/2;
        else
            fprintf('...');
        end
        
        DT = delaunayTriangulation( Olduu(:), Oldvv(:) );  % use DelaunayTri in older Matlab versions
        [ti,bc] = pointLocation(DT, Newuu(:), Newvv(:));
        ti(isnan(ti)) = 1;
        
        for( ColChan = 1:size(LF,5) )
            fprintf('.');
            for( tidx= 1:LFSize(1) )
                for( sidx= 1:LFSize(2) )
                    CurUVSlice = squeeze(LF(tidx,sidx,:,:,ColChan));
                    triVals = CurUVSlice(DT(ti,:));
                    CurUVSlice = dot(bc',triVals')';
                    CurUVSlice = reshape(CurUVSlice, [length(NewVVec),length(NewUVec)]);
                    
                    CurUVSlice(isnan(CurUVSlice)) = 0;
                    LF2(tidx,sidx, :,:, ColChan) = CurUVSlice;
                end
            end
        end
        LF = LF2;
        clear LF2
        DecodeOptions.OutputScale(3) = DecodeOptions.OutputScale(3) * HexAspect;
        
    otherwise
        fprintf('\nNo valid dehex / resampling selected\n');
end

%---Resize to square s,t pixels---
% Assumes only a very slight resampling is required, resulting in an identically-sized output light field
if( DecodeOptions.DoSquareST )
    fprintf('\nResizing to square s,t pixels using 1D linear interp...');
    
    ResizeScale = DecodeOptions.OutputScale(1)/DecodeOptions.OutputScale(2);
    ResizeDim1 = 1;
    ResizeDim2 = 2;
    if( ResizeScale < 1 )
        ResizeScale = 1/ResizeScale;
        ResizeDim1 = 2;
        ResizeDim2 = 1;
    end
    
    OrigSize = size(LF, ResizeDim1);
    OrigVec = floor((-(OrigSize-1)/2):((OrigSize-1)/2));
    NewVec = OrigVec ./ ResizeScale;
    
    OrigDims = [1:ResizeDim1-1, ResizeDim1+1:5];
    
    UBlkSize = 32;
    USize = size(LF,4);
    LF = permute(LF,[ResizeDim1, OrigDims]);
    for( UStart = 1:UBlkSize:USize )
        UStop = UStart + UBlkSize - 1;
        UStop = min(UStop, USize);
        LF(:,:,:,UStart:UStop,:) = interp1(OrigVec, LF(:,:,:,UStart:UStop,:), NewVec);
        fprintf('.');
    end
    LF = ipermute(LF,[ResizeDim1, OrigDims]);
    LF(isnan(LF)) = 0;
    
    DecodeOptions.OutputScale(ResizeDim2) = DecodeOptions.OutputScale(ResizeDim2) * ResizeScale;
end


%---Trim s,t---
LF = LF(2:end-1,2:end-1, :,:, :);

%---Slice out LFWeight if it was requested---
if( nargout >= 2 )
    LFWeight = LF(:,:,:,:,end);
    LFWeight = LFWeight./max(LFWeight(:));
    LF = LF(:,:,:,:,1:end-1);
end

end

%------------------------------------------------------------------------------------------------------
function LF = SliceXYImage( ImXform, LensletGridModel, LensletImage, DecodeOptions )
% todo[optimization]: The SliceIdx and InvalidIdx variables could be precomputed

fprintf('\nSlicing lenslets into LF...');

USize = LensletGridModel.UMax;
VSize = LensletGridModel.VMax;
MaxSpacing = max(LensletGridModel.HSpacing, LensletGridModel.VSpacing);  % Enforce square output in s,t
SSize = MaxSpacing + 1; % force odd for centered middle pixel -- H,VSpacing are even, so +1 is odd
TSize = MaxSpacing + 1;

LF = zeros(TSize, SSize, VSize, USize, DecodeOptions.NColChans + DecodeOptions.NWeightChans, DecodeOptions.Precision);

for( chan=1:4 )
	Interpolant{chan} = griddedInterpolant( LensletImage(:,:,chan) );
	Interpolant{chan}.Method = 'linear';
	Interpolant{chan}.ExtrapolationMethod = 'none';
end

TVec = cast(floor((-(TSize-1)/2):((TSize-1)/2)), 'int16');
SVec = cast(floor((-(SSize-1)/2):((SSize-1)/2)), 'int16');
VVec = cast(0:VSize-1, 'int16');
UBlkSize = 32;
for( UStart = 0:UBlkSize:USize-1 )  % note zero-based indexing
    UStop = UStart + UBlkSize - 1;
    UStop = min(UStop, USize-1);  
    UVec = cast(UStart:UStop, 'int16');
    
    [tt,ss,vv,uu] = ndgrid( TVec, SVec, VVec, UVec );
    
    %---Build indices into 2D image---
    LFSliceIdxX = LensletGridModel.HOffset + uu.*LensletGridModel.HSpacing + ss;
    LFSliceIdxY = LensletGridModel.VOffset + vv.*LensletGridModel.VSpacing + tt;
    
    HexShiftStart = LensletGridModel.FirstPosShiftRow;
    LFSliceIdxX(:,:,HexShiftStart:2:end,:) = LFSliceIdxX(:,:,HexShiftStart:2:end,:) + LensletGridModel.HSpacing/2;

    %---Lenslet mask in s,t and clip at image edges---
    CurSTAspect = DecodeOptions.OutputScale(1)/DecodeOptions.OutputScale(2);
    R = sqrt((cast(tt,DecodeOptions.Precision)*CurSTAspect).^2 + cast(ss,DecodeOptions.Precision).^2);
    
    %---try going back to uncorrected lenslet img---
    ImCoords = double([LFSliceIdxX(:), LFSliceIdxY(:), ones(size(LFSliceIdxX(:)))]);
    ImCoords = (ImXform'^-1) * ImCoords';
	ImCoords = ImCoords([2,1],:)';

    InValidIdx = find(R >= LensletGridModel.HSpacing/2  );

    for( ColChan=1:4 )
		IDirect = Interpolant{ColChan}( ImCoords );
        IDirect(isnan(IDirect)) = 0;
        IDirect(InValidIdx) = 0;
        LF(:,:,:,1 + (UStart:UStop),ColChan) = reshape(IDirect, size(ss));
	end
        
    fprintf('.');
end
end
