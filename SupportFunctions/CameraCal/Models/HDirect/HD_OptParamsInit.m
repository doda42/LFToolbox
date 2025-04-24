%---------------------------------------------------------------------------------------------------
function [CalOptions, CameraModel] = HD_OptParamsInit( CameraModel, CalOptions )

% HDirect Model initialize
CalOptions.IntrinsicsToOpt = sub2ind([5,5], [1,3, 2,4, 1,3, 2,4], [1,1, 2,2, 3,3, 4,4]);
fprintf('    Intrinsics: ');
disp(CalOptions.IntrinsicsToOpt);

% On first iteration, this model doesn't use distortion parameters
switch( CalOptions.Iteration )
	case 1
		CalOptions.DistortionParamsToOpt = [];
		CameraModel.Distortion = [];
	otherwise
		% Call the distortion model's init function
		[CameraModel, CalOptions] = feval( CalOptions.Fn_DistortInit, CameraModel, CalOptions );
end

fprintf('    Distortion: ');
disp( CalOptions.DistortionParamsToOpt );


% Save the initialised camera model
CalOptions.PreviousCameraModel = CameraModel;

