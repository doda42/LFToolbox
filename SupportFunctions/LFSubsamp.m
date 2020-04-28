% Subsample a light field by combining neighbourhoods of pixels
% 
%   LF = LFSubsamp( LF, SubsampRate, SubsampMethod )
% 
% Inputs:
% 
%                LF : Light field to subsample
% 
%       SubsampRate : 4D array controlling subsampling in each dimension; 1 means no subsampling,
%                     2 means take every 2 samples, ...; default is no subsampling [1,1,1,1].
%                     SubsampRate is capped to ensure at least two entries remain in each dimension.
% 
%     SubsampMethod : One of 'skip, 'sum', 'mean', 'max', or 'min'; how the neighbourhood of
%                     pixels skipped via SubsampRate get combined into one sample. 'skip' ignores
%                     all but the selected samples.
% 
% Outputs:
% 
%     LF : Subsampled light field
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDispTiles

% Copyright (C) 2012-2020 Donald G. Dansereau

function [LF2, SampGrid] = LFSubsamp( LF, SubsampRate, SubsampMethod )

SubsampMethod = LFDefaultVal('SubsampMethod', 'skip');

%---Cap subsampling rate to ensure at least 2 entries in each dim---
LFSize = size(LF);
if( numel(LFSize)==4 )
	LFSize(5) = 1;
end
SubsampRate = min(SubsampRate, LFSize(1:4)-1);

%---Build resampling grid and grab first sample---
[tt,ss,vv,uu] = ndgrid(1:SubsampRate(1), 1:SubsampRate(2), 1:SubsampRate(3), 1:SubsampRate(4));
SubsampIter = [tt(:), ss(:), vv(:), uu(:)];

TVec = 1:SubsampRate(1):LFSize(1);
SVec = 1:SubsampRate(2):LFSize(2);
VVec = 1:SubsampRate(3):LFSize(3);
UVec = 1:SubsampRate(4):LFSize(4);
LF2 = LF(TVec, SVec, VVec, UVec, :);

SampGrid = LFVar2Struct( SVec, TVec, UVec, VVec );

%---Apply remaining samples---
if( ~strcmpi( SubsampMethod, 'skip' ) )
	for( iIter = 2:size(SubsampIter,1) )
		TVec = SubsampIter(iIter,1):SubsampRate(1):size(LF,1);
		SVec = SubsampIter(iIter,2):SubsampRate(2):size(LF,2);
		VVec = SubsampIter(iIter,3):SubsampRate(3):size(LF,3);
		UVec = SubsampIter(iIter,4):SubsampRate(4):size(LF,4);
		switch( lower(SubsampMethod) )
			case 'max'
				LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) = max(LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:), LF(TVec,SVec, VVec,UVec,:));
			case 'min'
				LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) = min(LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:), LF(TVec,SVec, VVec,UVec,:));
			case 'sum'
				LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) = LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) + LF(TVec,SVec, VVec,UVec,:);
			case 'mean'
				LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) = LF2(1:length(TVec),1:length(SVec),1:length(VVec),1:length(UVec),:) + LF(TVec,SVec, VVec,UVec,:);
			otherwise
				error('unrecognized subsampling method');
		end
	end
	if( strcmp( lower(SubsampMethod), 'mean' ) )
		LF2 = LF2 ./ prod(SubsampRate);
	end
end
