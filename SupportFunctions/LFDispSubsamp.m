% Combines adjacent views of a light field by taking the sum or max across views
% todo: doc
% FoldingRate is capped to ensure at least two entries remain in each dimension

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function LF2 = LFDispSubsamp( LF, FoldingRate, FoldingMethod )

FoldingMethod = LFDefaultVal('FoldingMethod', 'max');

%---Cap folding rate to ensure at least 2 entries in each dim---
LFSize = size(LF);
if( numel(LFSize)==4 )
	LFSize(5) = 1;
end
FoldingRate = min(FoldingRate, LFSize(1:4)-1);

%---Build resampling grid and grab first sample---
[tt,ss,vv,uu] = ndgrid(1:FoldingRate(1), 1:FoldingRate(2), 1:FoldingRate(3), 1:FoldingRate(4));
FoldingIter = [tt(:), ss(:), vv(:), uu(:)];

TVec = 1:FoldingRate(1):LFSize(1);
SVec = 1:FoldingRate(2):LFSize(2);
VVec = 1:FoldingRate(3):LFSize(3);
UVec = 1:FoldingRate(4):LFSize(4);
LF2 = LF(TVec, SVec, VVec, UVec, :);

%---Apply remaining samples---
if( ~strcmp( lower(FoldingMethod), 'skip' ) )
	for( iFold = 2:size(FoldingIter,1) )
		TVec = FoldingIter(iFold,1):FoldingRate(1):size(LF,1);
		SVec = FoldingIter(iFold,2):FoldingRate(2):size(LF,2);
		VVec = FoldingIter(iFold,3):FoldingRate(3):size(LF,3);
		UVec = FoldingIter(iFold,4):FoldingRate(4):size(LF,4);
		switch( lower(FoldingMethod) )
			case 'max'
				LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) = max(LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:), LF(TVec,SVec, VVec,UVec,:));
			case 'sum'
				LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) = LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) + LF(TVec,SVec, VVec,UVec,:);
			case 'mean'
				LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) = LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) + LF(TVec,SVec, VVec,UVec,:);
			otherwise
				error('unrecognized folding method');
		end
	end
	if( strcmp( lower(FoldingMethod), 'mean' ) )
		LF2 = LF2 ./ prod(FoldingRate);
	end
end
