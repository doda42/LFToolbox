% LFFilt2DFFT - Apply a 2D frequency-domain filter to a 4D light field using the FFT
%
% Usage:
%
%     [LF, FiltOptions] = LFFilt2DFFT( LF, H, FiltDims, FiltOptions )
%     LF = LFFilt2DFFT( LF, H, FiltDims )
%
% 
% This filter works on 2D slices of the input light field, applying the 2D filter H to each in turn.  It takes the FFT
% of each slice of the input light field, multiplies by the provided magnitude response H, then calls the inverse FFT.
% 
% The FiltDims input specifies the two dimensions along which H should be applied. The frequency-domain filter H should
% match or exceed the size of the light field LF in these dimensions. If H is larger than the input light field, LF is
% zero-padded to match the filter's size.  If a weight channel is present in the light field it gets used during
% normalization.
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
%  FiltDims : The dimensions along which H should be applied
%
%     [optional] FiltOptions : struct controlling filter operation
%                 Precision : 'single' or 'double', default 'single'
%                 Normalize : default true; when enabled the output is normalized so that darkening near image edges is
%                             removed
%                 MinWeight : during normalization, pixels for which the output value is not well defined (i.e. for
%                             which the filtered weight is very low) get set to 0. MinWeight sets the threshold at which
%                             this occurs, default is 10 * the numerical precision of the output, as returned by eps
%                   DoClamp : clamp the output to range 0-1. Default: true.
%
% Outputs:
% 
%                LF : The filtered 4D light field
%       FiltOptions : The filter options including defaults, with an added FilterInfo field detailing the function and 
%                     time of filtering.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFDemoBasicFiltGantry, LFDemoBasicFiltIllum, LFDemoBasicFiltLytroF01, LFBuild2DFreqFan, LFBuild2DFreqLine,
% LFBuild4DFreqDualFan, LFBuild4DFreqHypercone, LFBuild4DFreqHyperfan, LFBuild4DFreqPlane, LFFilt2DFFT, LFFilt4DFFT,
% LFFiltShiftSum

% Copyright (c) 2013-2020 Donald G. Dansereau

function [LF, FiltOptions] = LFFilt2DFFT( LF, H, FiltDims, FiltOptions )

FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single'); 
FiltOptions = LFDefaultField('FiltOptions', 'Normalize', true);
FiltOptions = LFDefaultField('FiltOptions', 'MinWeight', 10*eps(FiltOptions.Precision));
FiltOptions = LFDefaultField('FiltOptions', 'DoClamp', true);
%---
NColChans = size(LF,5);
HasWeight = ( NColChans == 4 || NColChans == 2 );
if( HasWeight )
	NColChans = NColChans-1;
end

%---
IterDims = 1:4;
IterDims(FiltDims) = 0;
IterDims = find(IterDims~=0);

PermuteOrder = [IterDims, FiltDims, 5];
LF = permute(LF, PermuteOrder);

LF = LFConvertToFloat(LF, FiltOptions.Precision);


%---
LFSize = size(LF);
if( length(LFSize) == 4 )
	LFSize(5) = 1;
end
SlicePaddedSize = size(H);

for( IterDim1 = 1:LFSize(1) )
	fprintf('.');
	for( IterDim2 = 1:LFSize(2) )
		CurSlice = squeeze(LF(IterDim1,IterDim2,:,:,:));
		
		if( FiltOptions.Normalize )
			if( HasWeight )
				for( iColChan = 1:NColChans )
					CurSlice(:,:,iColChan) = CurSlice(:,:,iColChan) .* CurSlice(:,:,end);
				end
			else % add a weight channel
				CurSlice(:,:,end+1) = ones(size(CurSlice(:,:,1)), FiltOptions.Precision);
			end
		end
		
		SliceSize = size(CurSlice);
		for( iColChan = 1:SliceSize(end) )
			X = fftn(CurSlice(:,:,iColChan), SlicePaddedSize);
			X = X .* H;
			x = ifftn(X,'symmetric');
			x = x(1:LFSize(3), 1:LFSize(4));
			CurSlice(:,:,iColChan) = x;
		end
			
		if( FiltOptions.Normalize )
			WeightChan = CurSlice(:,:,end);
			InvalidIdx = find(WeightChan < FiltOptions.MinWeight);
			ChanSize = numel(CurSlice(:,:,1));
			for( iColChan = 1:NColChans )
				CurSlice(:,:,iColChan) = CurSlice(:,:,iColChan) ./ WeightChan;
				CurSlice( InvalidIdx + ChanSize.*(iColChan-1) ) = 0;
			end
	        CurSlice( InvalidIdx + ChanSize.*NColChans ) = 0; % also zero weight channel where invalid
		end
		
		% record channel
		LF(IterDim1,IterDim2,:,:,:) = CurSlice(:,:,1:LFSize(5));
	end
end

%---Clamp---
if( FiltOptions.DoClamp )
	LF = max(0,LF);
	LF = min(1,LF);
end

LF = ipermute(LF, PermuteOrder);

%---
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.FilterInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

fprintf(' Done\n');
