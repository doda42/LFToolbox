% LFFilt4DFFT -Applies a 4D frequency-domain filter using the FFT
%
% Usage:
%
%     [LF, FiltOptions] = LFFilt4DFFT( LF, H, FiltOptions )
%     LF = LFFilt4DFFT( LF, H )
%
% 
% This filter works by taking the FFT of the input light field, multiplying by the provided magnitude response H, then
% calling the inverse FFT.  The frequency-domain filter H should match or exceed the size of the light field LF. If H is
% larger than the input light field, LF is zero-padded to match the filter's size.  If a weight channel is present in
% the light field it gets used during normalization.
% 
% See LFDemoBasicFiltLytro for example usage.
% 
%
% Inputs
%
%        LF : The light field to be filtered
% 
%         H : The frequency-domain filter to apply, as constructed by one of the LFBuild4DFreq* functions
%
%     [optional] FiltOptions : struct controlling filter operation
%                 Precision : 'single' or 'double', default 'single'
%                 Normalize : default true; when enabled the output is normalized so that darkening near image edges is
%                             removed
%                 MinWeight : during normalization, pixels for which the output value is not well defined (i.e. for
%                             which the filtered weight is very low) get set to 0. MinWeight sets the threshold at which
%                             this occurs, default is 10 * the numerical precision of the output, as returned by eps
%
% Outputs:
% 
%                LF : The filtered 4D light field
%       FiltOptions : The filter options including defaults, with an added FilterInfo field detailing the function and 
%                     time of filtering.
%
% See also:  LFDemoBasicFiltGantry, LFDemoBasicFiltIllum, LFDemoBasicFiltLytroF01, LFBuild2DFreqFan, LFBuild2DFreqLine,
% LFBuild4DFreqDualFan, LFBuild4DFreqHypercone, LFBuild4DFreqHyperfan, LFBuild4DFreqPlane, LFFilt2DFFT, LFFilt4DFFT,
% LFFiltShiftSum

% Part of LF Toolbox v0.4 released 12-Feb-2015
% Copyright (c) 2013-2015 Donald G. Dansereau

function [LF, FiltOptions] = LFFilt4DFFT( LF, H, FiltOptions )

FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single'); 
FiltOptions = LFDefaultField('FiltOptions', 'Normalize', true);
FiltOptions = LFDefaultField('FiltOptions', 'MinWeight', 10*eps(FiltOptions.Precision));

%---
NColChans = size(LF,5);
HasWeight = ( NColChans == 4 || NColChans == 2 );
HasColour = ( NColChans == 4 || NColChans == 3 );

if( HasWeight )
	NColChans = NColChans-1;
end

%---
LFSize = size(LF);
LFPaddedSize = size(H);

LF = LFConvertToFloat(LF, FiltOptions.Precision);

if( FiltOptions.Normalize )
	if( HasWeight )
		for( iColChan = 1:NColChans )
			LF(:,:,:,:,iColChan) = LF(:,:,:,:,iColChan) .* LF(:,:,:,:,end);
		end
	else % add a weight channel
		LF(:,:,:,:,end+1) = ones(size(LF(:,:,:,:,1)), FiltOptions.Precision);
	end
end

SliceSize = size(LF);
for( iColChan = 1:SliceSize(end) )
	fprintf('.');
	X = fftn(LF(:,:,:,:,iColChan), LFPaddedSize);
	X = X .* H;
	x = ifftn(X,'symmetric');
	x = x(1:LFSize(1), 1:LFSize(2), 1:LFSize(3), 1:LFSize(4));
	LF(:,:,:,:,iColChan) = x;
end

if( FiltOptions.Normalize )
	WeightChan = LF(:,:,:,:,end);
	InvalidIdx = find(WeightChan <= FiltOptions.MinWeight);
	ChanSize = numel(LF(:,:,:,:,1));
	for( iColChan = 1:NColChans )
		LF(:,:,:,:,iColChan) = LF(:,:,:,:,iColChan) ./ WeightChan;
		LF( InvalidIdx + ChanSize.*(iColChan-1) ) = 0;
	end
end

LF = max(0,LF);
LF = min(1,LF);

%---
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.FilterInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

fprintf(' Done\n');