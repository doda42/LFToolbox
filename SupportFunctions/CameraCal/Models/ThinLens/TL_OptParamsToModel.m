%---------------------------------------------------------------------------------------------------
function [EstCamPosesV, CameraModel] = ...
	TL_OptParamsToModel( Params, CalOptions, ParamsInfo )

P = UnflattenStruct(Params, ParamsInfo);
EstCamPosesV = P.EstCamPosesV;

CameraModel = CalOptions.PreviousCameraModel;
CameraModel.Distortion(CalOptions.DistortionParamsToOpt) = P.DistortParams;

OptParams = P.PtoOpt ./ CalOptions.OptParamsScale;  % bring values to similar scale
OptParams = num2cell(OptParams);

PP = CameraModel.PhysicalParams;
[PP.csx, PP.csy, PP.cux, PP.cuy, PP.du, PP.fMx, PP.fMy, PP.dM] = OptParams{:};
CameraModel.PhysicalParams = PP;

CameraModel.EstCamIntrinsicsH = TL_PhysicalParamsToIntrins( CameraModel.PhysicalParams );

end