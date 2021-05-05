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
%          [Optional] ResampMethod : 'fast'(default)
%                                    'triangulation' slower.
%                                    'barycentric': slow but generates larger images by a factor 3*sqrt(3)/2.
%                                    'none': No interpolation -> Generates many incomplete views with a weight map per RGB component (zero weight indicate missing pixel).
%          [Optional]   Precision : 'single'(default) or 'double'
%          [Optional] LevelLimits : a two-element vector defining the black and white levels
%          [Optional] WeightedDemosaic : Do White Image guided demosaicing (default=false).
%          [Optional] WeightedInterp : Do White Image guided interpolations for lenslet image rotation/translation/scaling operations (default=false).
%          [Optional] NormaliseWIColours : Normalise sensor responses of Red and Blue pixels realtively to Green pixels in the White Image (prevents interference betweeen devignetting and white balance settings).
%                                          The option is true by default. But it is desactivated in LFUtilDecodeLytroFolder when ColourCompatibility is true, to avoid changing colours compared to versions v0.4 and v0.5.
%          [Optional] NormaliseWIExposure : Normalises White image exposure to have value 1 at microlens centers (prevents interference between devignetting and exposure settings).
%                                           The option is true by default. But it is desactivated in LFUtilDecodeLytroFolder when ColourCompatibility is true, to avoid changing exosure compared to versions v0.4 and v0.5.
%          [Optional] EarlyWhiteBalance : Perform white balance directly on the RAW data, before demosaicing (default = false).
%          [Optional] CorrectSaturated : Process saturated pixels on the sensor so that they appear white after white balance (default = false).
%          [Optional] ClipMode : 'hard', 'soft', 'none'. The default is 'soft' if CorrectSaturated is true, 'hard' otherwise.
%          [Optional] HotPixelCorrect : Performs hot pixel correction using a list of hot pixels detected on the sensor (default=false).
%                                       If the option is active, the vertical and horizontal indices of the hot pixels must be defined temporarily in DecodeOptions.HotPixelsX and DecodeOptions.HotPixelsY (these fields are removed after the hot pixel correction is done).
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
DecodeOptions = LFDefaultField( 'DecodeOptions', 'ResampMethod', 'fast' ); %'fast', 'triangulation', 'barycentric', 'none'
DecodeOptions = LFDefaultField( 'DecodeOptions', 'Precision', 'single' );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'DoDehex', true );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'DoSquareST', true );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'WeightedDemosaic', false );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'WeightedInterp', false );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'NormaliseWIColours', true );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'NormaliseWIExposure', true );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'EarlyWhiteBalance', false );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'CorrectSaturated', false );
if( DecodeOptions.CorrectSaturated )
	DefaultClipMode='soft';
else
    DefaultClipMode='hard';
end
DecodeOptions = LFDefaultField( 'DecodeOptions', 'ClipMode', DefaultClipMode );% 'none', 'soft', 'hard'
if(strcmp(DecodeOptions.ResampMethod,'none') || strcmp(DecodeOptions.ResampMethod,'none'))
    %Weigthed interpolation not compatible with the ResampMode modes 'barycentric' and 'none'
    DecodeOptions.WeightedInterp=false;
    fprintf('ResampMethod not compatible with WeightedInterp, disabling\n');
end

%---Rescale image values, remove black level---
DecodeOptions.LevelLimits = cast(DecodeOptions.LevelLimits, DecodeOptions.Precision);
BlackLevel = DecodeOptions.LevelLimits(1);
WhiteLevel = DecodeOptions.LevelLimits(2);
ExpFactor = 2^DecodeOptions.ExposureBias;
WhiteImage = cast(WhiteImage, DecodeOptions.Precision);
WhiteImage = (WhiteImage - BlackLevel) ./ (WhiteLevel - BlackLevel);

LensletImage = cast(LensletImage, DecodeOptions.Precision);
LensletImage = (LensletImage - BlackLevel) ./ (WhiteLevel - BlackLevel);

%Define variables for bayer pattern
if(strcmp(DecodeOptions.DemosaicOrder,'grbg'))
    G1stY=1;G1stX=1;
    RstY=1;RstX=2;
    BstY=2;BstX=1;
    G2stY=2;G2stX=2;
elseif(strcmp(DecodeOptions.DemosaicOrder,'bggr'))
    BstY=1;BstX=1;
    G1stY=1;G1stX=2;
    G2stY=2;G2stX=1;
    RstY=2;RstX=2;
else
    error('unrecognized Demosaic Order');
end

%---White Image normalization and devignetting---
  %Color response normalization:
if(DecodeOptions.NormaliseWIColours)
    WhiteImage(RstY:2:end,RstX:2:end) = WhiteImage(RstY:2:end,RstX:2:end) * DecodeOptions.SensorNormalizeRBGains(1);%Red component
    WhiteImage(BstY:2:end,BstX:2:end) = WhiteImage(BstY:2:end,BstX:2:end) * DecodeOptions.SensorNormalizeRBGains(2);%Blue component
end
if(DecodeOptions.NormaliseWIExposure)
  %Global normalization (=> value 1 at microlens centers which are not supposed to have vignetting).
    WhiteImage = WhiteImage./prctile(WhiteImage(:),99.9);
end

LensletImage = LensletImage ./ WhiteImage; % Devignette

%Separate R,G and B pixels for the next steps (Correction of highlights + White Balance)
if(DecodeOptions.CorrectSaturated || DecodeOptions.EarlyWhiteBalance)
    R=LensletImage(RstY:2:end,RstX:2:end);
    G1=LensletImage(G1stY:2:end,G1stX:2:end);
    G2=LensletImage(G2stY:2:end,G2stX:2:end);
    B=LensletImage(BstY:2:end,BstX:2:end);
end

%--- Highlights Processing ---
if(DecodeOptions.CorrectSaturated)
    fact=max(DecodeOptions.ColourBalance);%RGB dependent factor to force pixels saturated on all components to be white after the White Balance step.
    ThSatCol=.99;%saturation threshold
    
    %Detect pixels saturated on the sensor (i.e. close to 1 before division by White image).
    RSat = find(R>ThSatCol./WhiteImage(RstY:2:end,RstX:2:end));
    G1Sat = find(G1>ThSatCol./WhiteImage(G1stY:2:end,G1stX:2:end));
    G2Sat = find(G2>ThSatCol./WhiteImage(G2stY:2:end,G2stX:2:end));
    BSat =  find(B>ThSatCol./WhiteImage(BstY:2:end,BstX:2:end));

    %Determine the component with lowest value (the last one to saturate).
    [MinSat,MinId] = min(cat(3,R,G1,G2,B),[],3);
    %Compute the value of the lowest component after White Balance.
    ColMult = DecodeOptions.ColourBalance([1,2,2,3]);
    MinSatBal = MinSat.*ColMult(MinId);
    %Compute weight indicating the amount of saturation on the sensor (i.e. before devignetting) . If all components are saturated on the sensor, the weight is 1.
    MinSat = min(MinSat.*(WhiteImage(G1stY:2:end,G1stX:2:end)+WhiteImage(G2stY:2:end,G2stX:2:end)+WhiteImage(RstY:2:end,RstX:2:end)+WhiteImage(BstY:2:end,BstX:2:end))/4,1).^2;
    clear MinId

    %Final formula combining two behaviours : only left term when at least one component is far from saturation on the sensor/ only right term when All R,G1,G2 and B pixels are saturated on the sensor.
    %In both cases inverse white balance is applied (division by WB coeff) because the White Balance will be applied later on the whole image.
    R(RSat) =   max( ( MinSatBal(RSat) .*(1-MinSat(RSat))  +  R(RSat)*fact .* MinSat(RSat) )/DecodeOptions.ColourBalance(1) ,  R(RSat));
    G1(G1Sat) = max( ( MinSatBal(G1Sat) .*(1-MinSat(G1Sat)) + G1(G1Sat)*fact .* MinSat(G1Sat) )/DecodeOptions.ColourBalance(2) , G1(G1Sat)) ;
    G2(G2Sat) = max( ( MinSatBal(G2Sat) .*(1-MinSat(G2Sat)) + G2(G2Sat)*fact .* MinSat(G2Sat) )/DecodeOptions.ColourBalance(2) , G2(G2Sat));
    B(BSat) =   max( ( MinSatBal(BSat) .*(1-MinSat(BSat))  +  B(BSat)*fact .* MinSat(BSat) )/DecodeOptions.ColourBalance(3) ,  B(BSat));
    clear RSat G1Sat G2Sat BSat MinSat MinSatBal
end

%--- White Balance ---
if(DecodeOptions.EarlyWhiteBalance)
    % White Balance on RAW data before the demosaicing
    LensletImage(RstY:2:end,RstX:2:end) = R * DecodeOptions.ColourBalance(1);
    LensletImage(G1stY:2:end,G1stX:2:end) = G1 * DecodeOptions.ColourBalance(2);
    LensletImage(G2stY:2:end,G2stX:2:end) = G2 * DecodeOptions.ColourBalance(2);
    LensletImage(BstY:2:end,BstX:2:end) = B * DecodeOptions.ColourBalance(3);
elseif(DecodeOptions.CorrectSaturated)
    %Otherwise, the White Balance will be performed later
    LensletImage(RstY:2:end,RstX:2:end) = R;
    LensletImage(G1stY:2:end,G1stX:2:end) = G1;
    LensletImage(G2stY:2:end,G2stX:2:end) = G2;
    LensletImage(BstY:2:end,BstX:2:end) = B;
end
clear G1 G2 R B

%Exposure correction
LensletImage = LensletImage * ExpFactor;

% Clip
switch DecodeOptions.ClipMode
    case 'hard'
        LensletImage = min(1, max(0, LensletImage));
    case 'soft'
        LensletImage = max(0, softClip(LensletImage,7));
    case 'none'
    otherwise
        error(['Unknown ClipMode ''' DecodeOptions.ClipMode '''. Valid values are ''none'', ''soft'', ''hard''.']);
end

% Hot pixel correction 
% todo[refactor]: encapsulate hot pixel list, lenslet grid model, ...
if(DecodeOptions.HotPixelCorrect)
    LensletImage = LFHotPixelCorrection(LensletImage,DecodeOptions.HotPixelsX,DecodeOptions.HotPixelsY);
    DecodeOptions = rmfield(DecodeOptions,{'HotPixelsX','HotPixelsY'});
end

if(DecodeOptions.WeightedDemosaic || DecodeOptions.WeightedInterp)
    [Belonging, MLCenters, ~] = LFMicrolensBelonging(size(LensletImage,1),size(LensletImage,2), LensletGridModel);
    Weights = cast(WhiteImage.*double(intmax('uint16')), 'uint16');
    Weights = demosaic(Weights, DecodeOptions.DemosaicOrder);
    Weights = cast(Weights, DecodeOptions.Precision);
    Weights = Weights ./  double(intmax('uint16'));
    Weights = 0.2126 * Weights(:,:,1) + 0.7152 * Weights(:,:,2) + .0722 * Weights(:,:,3);   
    Weights = Weights.^10;
else
     Weights=[];
     Belonging=[];
     MLCenters=[];
end


if( nargout < 2 )
    clear WhiteImage
end

%---Demosaic---
if DecodeOptions.WeightedDemosaic
    LensletImage = LFWeightedDemosaic( LensletImage, Weights, Belonging, DecodeOptions );
else
% This uses Matlab's demosaic, which is "gradient compensated". This likely has implications near
% the edges of lenslet images, where the contrast is due to vignetting / aperture shape, and is not
% a desired part of the image
    MaxLum=max(LensletImage(:));
    LensletImage = cast(LensletImage.*(double(intmax('uint16'))/MaxLum), 'uint16');
    LensletImage = demosaic(LensletImage, DecodeOptions.DemosaicOrder);
    LensletImage = cast(LensletImage, DecodeOptions.Precision);
    LensletImage = LensletImage .* (MaxLum/double(intmax('uint16')));
end
DecodeOptions.NColChans = 3;

if( nargout >= 2 )
    if(strcmp(DecodeOptions.ResampMethod,'none'))
        DecodeOptions.NWeightChans = 3;
    else
        DecodeOptions.NWeightChans = 1;
    end
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


if(~strcmp(DecodeOptions.ResampMethod,'barycentric') && ~strcmp(DecodeOptions.ResampMethod,'none'))
% The following rotation can rotate parts of the lenslet image out of frame.
% todo[optimization]: attempt to keep these regions, offer greater user-control of what's kept
    FixAll = RRot*RScale*RTrans;
    LensletImage(:,:,4) = WhiteImage;
    clear WhiteImage
    LF = SliceXYImage( FixAll, NewLensletGridModel, LensletImage, DecodeOptions, Weights, Belonging, MLCenters);
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

else %Alternative Resampling modes 'none' and 'barycentric
    
    fprintf('\nInterpolating subaperture images from raw data...');
    
    USize = LensletGridModel.UMax;
    VSize = LensletGridModel.VMax;
    HOffset = LensletGridModel.HOffset;
    VOffset = LensletGridModel.VOffset;
    HSpacing = LensletGridModel.HSpacing;
    VSpacing = LensletGridModel.VSpacing;
    HexShiftStart = LensletGridModel.FirstPosShiftRow;
    
    [uu, vv] = meshgrid( 0:USize-1 , 0:VSize-1 );
    centerX = HOffset + HSpacing * uu;
    centerX(HexShiftStart:2:end,:) = centerX(HexShiftStart:2:end,:) + HSpacing/2;
    centerY = VOffset + VSpacing * vv;

    RotatedCenters = [centerX(:),centerY(:)] * RRot(1:2,1:2)';
    centerX(:) = RotatedCenters(:,1);
    centerY(:) = RotatedCenters(:,2);
    
    if(strcmp(DecodeOptions.ResampMethod,'barycentric'))
        STVec = linspace(-HSpacing/2,HSpacing/2, NewLensletGridModel.HSpacing+1);%view positions cover the full lenslet diameter (=hspacing)
        VSizeNew = floor(VSize*3*sqrt(3)/2);
        USizeNew = USize*3;
        LF = ones(length(STVec), length(STVec), VSizeNew, USizeNew, DecodeOptions.NColChans + DecodeOptions.NWeightChans, DecodeOptions.Precision);
        
        first = true;
        for row = 1:length(STVec)
            for col = 1:length(STVec)
                vecFix = RRot * [STVec(col); STVec(row); 1];
                colOffset = vecFix(1)/vecFix(3);
                rowOffset = vecFix(2)/vecFix(3);
                hex = zeros(2*VSize,2*USize,DecodeOptions.NColChans+DecodeOptions.NWeightChans);
                img = zeros(VSizeNew,USizeNew,DecodeOptions.NColChans+DecodeOptions.NWeightChans);
                for ch = 1:DecodeOptions.NColChans+DecodeOptions.NWeightChans
                    if(ch<=DecodeOptions.NColChans)
                        InterpSlice = interpn(squeeze(LensletImage(:,:,ch)), centerY+rowOffset, centerX+colOffset, 'cubic');
                    else
                        InterpSlice = interpn(squeeze(WhiteImage), centerY+rowOffset, centerX+colOffset, 'cubic');
                    end
                    hex(1:4:end,3-HexShiftStart:2:end,ch) = InterpSlice(1:2:end,:);
                    hex(3:4:end,HexShiftStart:2:end,ch) = InterpSlice(2:2:end,:);
                    if(first)
                        [img(:,:,ch), InterpData] = baryCentric(hex(:,:,ch),VSize/2,USize, HexShiftStart);
                        first = false;
                    else
                       img(:,:,ch) = baryCentric(hex(:,:,ch),VSize/2,USize, HexShiftStart, InterpData);
                    end
                end
                LF(row, col,:,:,1:DecodeOptions.NColChans+DecodeOptions.NWeightChans) = cast(img,DecodeOptions.Precision);
            end
        end
        
    else  % ResampMode 'none' -> only nearest interpolations with 
        
        G1Xparity = mod(G1stX,2); G1Yparity = mod(G1stY,2);
        G2Xparity = mod(G2stX,2); G2Yparity = mod(G2stY,2);
        RXparity  = mod(RstX,2);  RYparity  = mod(RstY,2);
        BXparity  = mod(BstX,2);  BYparity  = mod(BstY,2);
        
        radius = (HSpacing-1)/2 - DecodeOptions.LensletBorderSize;
        STVec = linspace(-radius, radius, DecodeOptions.NumViewsDiameter);%oversample in ST dimension for better accuracy of nearest interpolation.
        [S,T]=meshgrid(STVec,STVec);
        STkeep = (S.^2+T.^2)<=radius.^2;
        S = S(STkeep);
        T = T(STkeep);
        STVec = RRot * [S(:)'; T(:)'; ones(1,numel(S))];
        S = STVec(1,:);
        T = STVec(2,:);
        nViews = numel(S);
        DecodeOptions.Sampling.ST = [S(:), T(:)];%[S(:), T(:)*2/sqrt(3)];
        DecodeOptions.Sampling.HexShiftStart = HexShiftStart;
        DecodeOptions.Sampling.SubPixAccuracy=2*radius/(DecodeOptions.NumViewsDiameter-1);

        LF = zeros(nViews, 1, VSize, USize, DecodeOptions.NColChans + DecodeOptions.NWeightChans, DecodeOptions.Precision);

        %Only assign a sensor pixel value to its nearest pixel in the light field.
        nearPxThreshold = DecodeOptions.Sampling.SubPixAccuracy/sqrt(2);
        buffer_IdOut = zeros(size(LensletImage,1),size(LensletImage,2));
        buffer_Dist = inf(size(LensletImage,1),size(LensletImage,2));
        numPixPerView = USize*VSize;
        DecodeOptions.Sampling.ViewWeights = ones(numel(S),1);
        for viewId = 1:numel(S)
            %Find the colour view and mask (unknown->0 / known->weight from the white image).
            for xId=1:USize
                for yId=1:VSize
                    vxyId = (viewId-1)*numPixPerView + (xId-1)*VSize + yId;
                    Xreq = centerX(yId,xId) + S(viewId);
                    Yreq = centerY(yId,xId) + T(viewId);
                    Xnear = min(max(round(Xreq),1),size(LensletImage,2));
                    Ynear = min(max(round(Yreq),1),size(LensletImage,1));
                    dist2 = (Xnear-Xreq).^2+(Ynear-Yreq).^2;
                    LF(viewId,1,yId,xId,1:DecodeOptions.NColChans) = LensletImage(Ynear,Xnear,:);
                    
                    if( DecodeOptions.NWeightChans==3 && dist2 < buffer_Dist(Ynear,Xnear) )
                        isNeighbour = abs(Xreq-Xnear) < nearPxThreshold  & abs(Yreq-Ynear) < nearPxThreshold;
                        weight = WhiteImage(Ynear,Xnear);
                        LF(viewId,1,yId,xId,DecodeOptions.NColChans+1) = weight * ( isNeighbour & mod(Xnear,2) == RXparity & mod(Ynear,2) == RYparity );
                        LF(viewId,1,yId,xId,DecodeOptions.NColChans+2) = weight * ( isNeighbour & (mod(Xnear,2) == G1Xparity & mod(Ynear,2) == G1Yparity | mod(Xnear,2) == G2Xparity & mod(Ynear,2) == G2Yparity) );
                        LF(viewId,1,yId,xId,DecodeOptions.NColChans+3) = weight * ( isNeighbour & mod(Xnear,2) == BXparity & mod(Ynear,2) == BYparity );
                        
                        %Remove previous closest pixel (set its mask value to zero)
                        vxyIdPrev = buffer_IdOut(Ynear,Xnear);
                        if(vxyIdPrev>0)
                            viewIdPrev = 1+floor((vxyIdPrev-1)/numPixPerView);
                            xIdPrev = 1 + floor((vxyIdPrev-(viewIdPrev-1)*numPixPerView-1)/VSize);
                            yIdPrev = vxyIdPrev - (viewIdPrev-1)*numPixPerView - (xIdPrev-1)*VSize;
                            LF(viewIdPrev,1,yIdPrev,xIdPrev,1+DecodeOptions.NColChans:DecodeOptions.NColChans+3) = 0;
                        end
                        %Update index and distance buffers with new closest pixel info.
                        buffer_IdOut(Ynear,Xnear) = vxyId;
                        buffer_Dist(Ynear,Xnear) = dist2;
                    end
                end
            end
        end
    end
end

%---Trim s,t---
if(~strcmp(DecodeOptions.ResampMethod,'none'))
    LF = LF(2:end-1,2:end-1, :,:, :);
end

%---Slice out LFWeight if it was requested---
if( nargout >= 2 )
    LFWeight = LF(:,:,:,:,DecodeOptions.NColChans+1:end);
    LFWeight = LFWeight./max(LFWeight(:));
    LF = LF(:,:,:,:,1:DecodeOptions.NColChans);
end

end

%------------------------------------------------------------------------------------------------------
function LF = SliceXYImage( ImXform, LensletGridModel, LensletImage, DecodeOptions, Weights, Belong, Centers )
% todo[optimization]: The SliceIdx and InvalidIdx variables could be precomputed

fprintf('\nSlicing lenslets into LF...');

USize = LensletGridModel.UMax;
VSize = LensletGridModel.VMax;
MaxSpacing = max(LensletGridModel.HSpacing, LensletGridModel.VSpacing);  % Enforce square output in s,t
SSize = MaxSpacing + 1; % force odd for centered middle pixel -- H,VSpacing are even, so +1 is odd
TSize = MaxSpacing + 1;

LF = zeros(TSize, SSize, VSize, USize, DecodeOptions.NColChans + DecodeOptions.NWeightChans, DecodeOptions.Precision);

if( DecodeOptions.WeightedInterp )
    ChansGridInterp = 1+DecodeOptions.NColChans : DecodeOptions.NColChans + DecodeOptions.NWeightChans;
else
    ChansGridInterp = 1:DecodeOptions.NColChans + DecodeOptions.NWeightChans;
end

for( Chan=ChansGridInterp )
	Interpolant{Chan} = griddedInterpolant( LensletImage(:,:,Chan) );
	Interpolant{Chan}.Method = 'linear';
	Interpolant{Chan}.ExtrapolationMethod = 'none';
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

    if( DecodeOptions.WeightedInterp )
         IDirect = LFWeightedInterp(LensletImage(:,:,1:DecodeOptions.NColChans), Weights, ImCoords, Belong, Centers);
         IDirect(InValidIdx(:),:)=0;
         LF(:,:,:,1 + (UStart:UStop),1:DecodeOptions.NColChans) = reshape(IDirect, [size(ss) DecodeOptions.NColChans]);
    end
    
    for( Chan=ChansGridInterp )
		IDirect = Interpolant{Chan}( ImCoords );
        IDirect(isnan(IDirect)) = 0;
        IDirect(InValidIdx) = 0;
        LF(:,:,:,1 + (UStart:UStop),Chan) = reshape(IDirect, size(ss));
    end
        
    fprintf('.');
end
end


%------------------------------------------------------------------------------------------------------
%Soft clipping function (high value of R -> hard clipping)
function O = softClip(I,R)
b = exp(R);
O = log((1+b)./(1+b*exp(-R*I)))./log(1+b);
end
