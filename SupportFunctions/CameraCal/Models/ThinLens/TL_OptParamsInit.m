%---------------------------------------------------------------------------------------------------
function [CalOptions, CameraModel] = TL_OptParamsInit( CameraModel, CalOptions )

% This model includes distortion parameters on all iterations
% Call the distortion model's init function
[CameraModel, CalOptions] = feval( CalOptions.Fn_DistortInit, CameraModel, CalOptions );

fprintf('    Distortion: ');
disp( CalOptions.DistortionParamsToOpt );

%---Setup common scale for params, helps convergence---  % todo: make param, eval built-in version
CalOptions.OptParamsScale = [1,1,1/100,1/100,1e5,1e3,1e3,1e3]; % todo: distortion params

%---Setup bounds---
UpperBound = inf(size(CalOptions.OptParamsScale));
LowerBound = -UpperBound;

% Lensletsize_Pix(1) = CameraModel.PhysicalParams.Fsx/CameraModel.PhysicalParams.Fux;
% Lensletsize_Pix(2) = CameraModel.PhysicalParams.Fsy/CameraModel.PhysicalParams.Fuy;
% max plus or minus two pixels off on lenslet image centering     % todo: make param
LowerBound(1:2) = [CameraModel.PhysicalParams.csx,CameraModel.PhysicalParams.csy] - 2;
UpperBound(1:2) = [CameraModel.PhysicalParams.csx,CameraModel.PhysicalParams.csy] + 2;

CalOptions.Bounds = [LowerBound; UpperBound];

% Save the initialised camera model
CalOptions.PreviousCameraModel = CameraModel;

