% Combines adjacent views of a light field by taking the sum or max across views
% todo: doc
% todo: mean, skip

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function LF2 = LFDispResamp( LF, FoldingRate, FoldingMethod )

FoldingMethod = LFDefaultVal('FoldingMethod', 'max');

[tt,ss,vv,uu] = ndgrid(1:FoldingRate(1), 1:FoldingRate(2), 1:FoldingRate(3), 1:FoldingRate(4));
FoldingIter = [tt(:), ss(:), vv(:), uu(:)];
LF2 = LF(1:FoldingRate(1):end, 1:FoldingRate(2):end,1:FoldingRate(3):end, 1:FoldingRate(4):end,:);

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
		otherwise
			error('unrecognized folding method');
	end
end
