% todo[doc]
%---------------------------------------------------------------------------------------------------
function [Params, ParamInfo] = FlattenStruct(P)
Params = [];
ParamInfo.FieldNames = fieldnames(P);
for( i=1:length( ParamInfo.FieldNames ) )
	CurFieldName = ParamInfo.FieldNames{i};
	CurField = P.(CurFieldName);
	ParamInfo.SizeInfo{i} = size(CurField);
	Params = [Params; CurField(:)];
end
end