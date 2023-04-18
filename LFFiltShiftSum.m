% LFFiltShiftSum - A spatial-domain depth-selective filter with optional refocus super-resolution
%
% Usage:
%
%     [ImgOut, FiltOptions, LF] = LFFiltShiftSum( LF, Slope, FiltOptions )
%     ImgOut = LFFiltShiftSum( LF, Slope )
%
% 
% This filter works by shifting all u,v slices of the light field to a common depth, then adding the slices together to
% yield a single 2D output.  The effect is very similar to planar focus, and by controlling the amount of shift one may
% focus on different depths.  If a weight channel is present in the light field it gets used during normalization.
% 
% 
% See LFDemoBasicFiltLytro for example usage.
% 
%
% Inputs
%
%        LF : The light field to be filtered
% 
%     Slope : The amount by which light field slices should be shifted, this encodes the depth at which the output will
%             be focused. The relationship between slope and depth depends on light field parameterization, but in
%             general a slope of 0 lies near the center of the captured depth of field.
%
%     [optional] FiltOptions : struct controlling filter operation
%                 Precision : 'single' or 'double', default 'single'
%                  Aspect4D : aspect ratio of the light field, default [1 1 1 1]
%                 Normalize : default true; when enabled the output is normalized so that darkening near image edges is
%                             removed
%             FlattenMethod : 'Sum', 'Max', 'Min' or 'Median', default 'Sum'; when the shifted light field slices are combined,
%                             they are by default added together, but median, max and min can also yield useful results.
%              InterpMethod : default 'linear'; this is passed on to griddedInterpolant to determine how shifted light field slices
%                             are found; others are 'nearest', 'cubic'; see griddedInterpolant for others
%              ExtrapMethod : defualt 'nearest'; extrapolation method used by griddedInterpolant; 'none' is also useful, see griddedInterpolant
%                 MinWeight : during normalization, pixels for which the output value is not well defined (i.e. for
%                             which the filtered weight is very low) get set to 0. MinWeight sets the threshold at which
%                             this occurs, default is 10 * the numerical precision of the output, as returned by eps
%                      Mask : ignore samples with weights below MaskThresh; default false
%                MaskThresh : if Mask is true, samples with weights below this value are ignored
%                UpsampRate : linear refocus super-resolution. Each slice is upscaled by this factor before
%                             the flattening step. Default 1, i.e. no upsampling; values of 2 or 3 yield good resuls.
%
% Outputs:
% 
%            ImgOut : A 2D filtered image
%       FiltOptions : The filter options including defaults, with an added FilterInfo field detailing the function and 
%                     time of filtering.
%                LF : The 4D light field resulting from the shifting operation
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFDemoBasicFiltGantry, LFDemoBasicFiltIllum, LFDemoBasicFiltLytroF01, LFBuild2DFreqFan, LFBuild2DFreqLine,
% LFBuild4DFreqDualFan, LFBuild4DFreqHypercone, LFBuild4DFreqHyperfan, LFBuild4DFreqPlane, LFFilt2DFFT, LFFilt4DFFT,
% LFFiltShiftSum

% Copyright (c) 2013-2020 Donald G. Dansereau

function [ImgOut, FiltOptions, LF] = LFFiltShiftSum( LF, Slope, FiltOptions )

FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single'); 
FiltOptions = LFDefaultField('FiltOptions', 'MinWeight', 10*eps(FiltOptions.Precision));  
FiltOptions = LFDefaultField('FiltOptions', 'Aspect4D', 1); 
FiltOptions = LFDefaultField('FiltOptions', 'FlattenMethod', 'sum'); % 'Sum', 'Max', 'Median'
FiltOptions = LFDefaultField('FiltOptions', 'InterpMethod', 'linear'); 
FiltOptions = LFDefaultField('FiltOptions', 'ExtrapMethod', 'nearest');
FiltOptions = LFDefaultField('FiltOptions', 'MaskThresh', 0.5); 
FiltOptions = LFDefaultField('FiltOptions', 'Mask', false);
FiltOptions = LFDefaultField('FiltOptions', 'UpsampRate', 1);

switch( lower(FiltOptions.FlattenMethod) )
	case 'sum'
		DefaultNormalize = true;
	otherwise
		DefaultNormalize = false;
end
FiltOptions = LFDefaultField('FiltOptions', 'Normalize', DefaultNormalize);

%---
if( length(FiltOptions.Aspect4D) == 1 )
	FiltOptions.Aspect4D = FiltOptions.Aspect4D .* [1,1,1,1];
end

LFSize = size(LF);
NColChans = size(LF,5);
HasWeight = ( NColChans == 4 || NColChans == 2 );
if( HasWeight )
	NColChans = NColChans-1;
end

LF = LFConvertToFloat(LF, FiltOptions.Precision);

%---
if( FiltOptions.Normalize )
	if( HasWeight )
		for( iColChan = 1:NColChans )
			LF(:,:,:,:,iColChan) = LF(:,:,:,:,iColChan) .* LF(:,:,:,:,end);
		end
	else % add a weight channel
		LF(:,:,:,:,end+1) = ones(size(LF(:,:,:,:,1)), FiltOptions.Precision);
		LFSize = size(LF);
	end
end

%---
if( FiltOptions.Mask )
	if( HasWeight )
		InvalidIdx = find( LF(:,:,:,:,end) < FiltOptions.MaskThresh );
		ChanSize = numel(LF(:,:,:,:,1));
		for( iColChan = 1:NColChans )
			LF(InvalidIdx + (iColChan-1)*ChanSize) = NaN;
		end
		LF(InvalidIdx + (NColChans)*ChanSize) = 0; % also zero out the invalid in weight
	else
		error('Masking requires a weight channel');
	end
end

%---
TVSlope = Slope * FiltOptions.Aspect4D(3) / FiltOptions.Aspect4D(1);
SUSlope = Slope * FiltOptions.Aspect4D(4) / FiltOptions.Aspect4D(2);

v = linspace(1,LFSize(3), round(LFSize(3)*FiltOptions.UpsampRate));
u = linspace(1,LFSize(4), round(LFSize(4)*FiltOptions.UpsampRate));
NewLFSize = LFSize;
NewLFSize(3:4) = [length(v), length(u)];

VOffsetVec = linspace(-0.5,0.5, LFSize(1)) * TVSlope*LFSize(1);
UOffsetVec = linspace(-0.5,0.5, LFSize(2)) * SUSlope*LFSize(2);

LFOut = zeros(NewLFSize, 'like', LF);
for( TIdx = 1:LFSize(1) )
	VOffset = VOffsetVec(TIdx);
    for( SIdx = 1:LFSize(2) )
		UOffset = UOffsetVec(SIdx);
		CurSlice = squeeze(LF(TIdx, SIdx, :,:, :));
		
		Interpolant = griddedInterpolant( CurSlice );
		Interpolant.Method = FiltOptions.InterpMethod;
		Interpolant.ExtrapolationMethod = FiltOptions.ExtrapMethod;
		
		CurSlice = Interpolant( {v+VOffset, u+UOffset, 1:size(LF,5)} );
		
		LFOut(TIdx,SIdx, :,:, :) = CurSlice;
	end
	if( mod(TIdx, ceil(LFSize(1)/10)) == 0 )
		fprintf('.');
	end
end

LF = LFOut;
clear LFOut

% griddedInterpolant returns NaN for out-of-range extrapolation; make sure these register as invalid
% in the weight channel
if( FiltOptions.Normalize )
	W = LF(:,:,:,:,end);
	W(isnan(W)) = 0;
	LF(:,:,:,:,end) = W;
end

switch( lower(FiltOptions.FlattenMethod) )
	case 'sum'
		ImgOut = squeeze(sum(LF,[1,2], 'omitnan'));
	case 'max'
		ImgOut = squeeze(max(LF, [], [1,2], 'omitnan'));
	case 'min'
		ImgOut = squeeze(min(LF, [], [1,2], 'omitnan'));
	case 'median'
		t = reshape(LF(:,:,:,:,1:NColChans), [prod(LFSize(1:2)), NewLFSize(3:4), NColChans]);
		ImgOut = squeeze(median(t, 'omitnan'));
	otherwise
		error('Unrecognized method');
end

%---
if( FiltOptions.Normalize )
	WeightChan = ImgOut(:,:,end);
	InvalidIdx = find(WeightChan < FiltOptions.MinWeight);
	ChanSize = numel(ImgOut(:,:,1));
	for( iColChan = 1:NColChans )
		ImgOut(:,:,iColChan) = ImgOut(:,:,iColChan) ./ WeightChan;
		ImgOut( InvalidIdx + ChanSize.*(iColChan-1) ) = 0;
	end
end

TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.FilterInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);
