%---------------------------------------------------------------------------------------------------
function [CalOptions, CameraModel] = TL_OptParamsInit( CameraModel, CalOptions )

NDistortionParams = 5;

% switch( CalOptions.Iteration )
% 	case 1
% 		CalOptions.DistortionParamsToOpt = [];
% 	otherwise
		CalOptions.DistortionParamsToOpt = 1:3;
% end

if( isempty(CameraModel.Distortion) && ~isempty(CalOptions.DistortionParamsToOpt) )
	CameraModel.Distortion( 1:NDistortionParams ) = 0;
end
CalOptions.PreviousCameraModel = CameraModel;

CalOptions.OptParamsScale = [1,1,1/100,1/100,1e5,1e3,1e3,1e3];
UpperBound = inf(size(CalOptions.OptParamsScale));
LowerBound = -UpperBound;

% Lensletsize_Pix(1) = CameraModel.PhysicalParams.Fsx/CameraModel.PhysicalParams.Fux;
% Lensletsize_Pix(2) = CameraModel.PhysicalParams.Fsy/CameraModel.PhysicalParams.Fuy;
% max plus or minus two pixels off on lenslet image centering
LowerBound(1:2) = [CameraModel.PhysicalParams.csx,CameraModel.PhysicalParams.csy] - 2;
UpperBound(1:2) = [CameraModel.PhysicalParams.csx,CameraModel.PhysicalParams.csy] + 2;

CalOptions.Bounds = [LowerBound; UpperBound];

if( ~isempty(CalOptions.DistortionParamsToOpt) )
	fprintf('    Distortion: ');
	disp(CalOptions.DistortionParamsToOpt);
end
