%---------------------------------------------------------------------------------------------------
function [CalOptions, CameraModel] = HD_OptParamsInit( CameraModel, CalOptions )
CalOptions.IntrinsicsToOpt = sub2ind([5,5], [1,3, 2,4, 1,3, 2,4], [1,1, 2,2, 3,3, 4,4]);
switch( CalOptions.Iteration )
	case 1
		CalOptions.DistortionParamsToOpt = [];
	otherwise
		CalOptions.DistortionParamsToOpt = 1:5;
end

if( isempty(CameraModel.Distortion) && ~isempty(CalOptions.DistortionParamsToOpt) )
	CameraModel.Distortion( CalOptions.DistortionParamsToOpt ) = 0;
end
CalOptions.PreviousCameraModel = CameraModel;

fprintf('    Intrinsics: ');
disp(CalOptions.IntrinsicsToOpt);
if( ~isempty(CalOptions.DistortionParamsToOpt) )
	fprintf('    Distortion: ');
	disp(CalOptions.DistortionParamsToOpt);
end
end