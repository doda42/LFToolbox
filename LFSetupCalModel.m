% todo[doc]

function CalOptions = LFSetupCalModel( CameraModel, DistortionModel, CalOptions )

CameraModel = LFDefaultVal('CameraModel', 'HDirect');
DistortionModel = LFDefaultVal('DistortionModel', '2DWithBias');

switch( CameraModel )
	case 'ThinLens'
		fprintf('Using thin lens camera model\n');
		CalOptions.Fn_CalInit = @TL_CalInit;
		CalOptions.Fn_OptParamsInit = @TL_OptParamsInit;
		CalOptions.Fn_ModelToOptParams = @TL_ModelToOptParams;
		CalOptions.Fn_OptParamsToModel = @TL_OptParamsToModel;
		CalOptions.Fn_ObsToRay = @TL_ObsToRay;
		CalOptions.Fn_RayToObs = @TL_RayToObs;

	case 'HDirect'
		fprintf('Using direct intrinsic matrix H camera model\n');
		CalOptions.Fn_CalInit = @HD_CalInit;
		CalOptions.Fn_OptParamsInit = @HD_OptParamsInit;
		CalOptions.Fn_ModelToOptParams = @HD_ModelToOptParams;
		CalOptions.Fn_OptParamsToModel = @HD_OptParamsToModel;
		CalOptions.Fn_ObsToRay = @HD_ObsToRay;
		CalOptions.Fn_RayToObs = @HD_RayToObs;

	otherwise
		error('Unrecognised camera model name');
end

switch( DistortionModel )
	case '2DNoBias'
		CalOptions.Fn_DistortRay = @D2D_DistortRay;
		CalOptions.Fn_UndistortRay = @D2D_UndistortRay;
		CalOptions.Fn_DistortInit = @D2D_Init;
		CalOptions.DistortionModel.ParamsToOpt = 1:3;		
	case '2DWithBias'
		CalOptions.Fn_DistortRay = @D2D_DistortRay;
		CalOptions.Fn_UndistortRay = @D2D_UndistortRay;
		CalOptions.Fn_DistortInit = @D2D_Init;
		CalOptions.DistortionModel.ParamsToOpt = 1:5;
	otherwise
		error('Unrecognised distortion model name');
end