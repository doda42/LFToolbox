% todo[doc]
function [CameraModel, CalOptions] = D2D_Init( CameraModel, CalOptions )

CalOptions.DistortionParamsToOpt = CalOptions.DistortionModel.ParamsToOpt;

if( isempty(CameraModel.Distortion) && ~isempty(CalOptions.DistortionParamsToOpt) )
	CameraModel.Distortion( CalOptions.DistortionParamsToOpt ) = 0;
end

end
