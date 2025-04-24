% todo: doc
%---------------------------------------------------------------------------------------------------
function [P] = UnflattenStruct(Params, ParamInfo)
CurIdx = 1;
for( i=1:length( ParamInfo.FieldNames ) )
	CurFieldName = ParamInfo.FieldNames{i};
	CurSize = ParamInfo.SizeInfo{i};
	CurField = Params(CurIdx + (0:prod(CurSize)-1));
	CurIdx = CurIdx + prod(CurSize);
	CurField = reshape(CurField, CurSize);
	P.(CurFieldName) = CurField;
end
end