% todo[doc]

function CalOptions = LFSetupCalModel( ModelName, CalOptions )

switch( ModelName )
	case 'ThinLens'
		fprintf('Using thin lens camera model\n');
		CalOptions.Fn_CalInit = @TL_CalInit;
		CalOptions.Fn_OptParamsInit = @TL_OptParamsInit;
		CalOptions.Fn_ModelToOptParams = @TL_ModelToOptParams;
		CalOptions.Fn_OptParamsToModel = @TL_OptParamsToModel;
		CalOptions.Fn_ObsToRay = @TL_ObsToRay;
		CalOptions.Fn_RayToObs = @TL_RayToObs;

	case 'DirectH'
		fprintf('Using direct intrinsic matrix H camera model\n');
		CalOptions.Fn_CalInit = @DH_CalInit;
		CalOptions.Fn_OptParamsInit = @DH_OptParamsInit;
		CalOptions.Fn_ModelToOptParams = @DH_ModelToOptParams;
		CalOptions.Fn_OptParamsToModel = @DH_OptParamsToModel;
		CalOptions.Fn_ObsToRay = @DH_ObsToRay;
		CalOptions.Fn_RayToObs = @DH_RayToObs;

	otherwise
		error('Unrecognised camera model name');
end