%---------------------------------------------------------------------------------------------------
function [EstCamPosesV, CameraModel] = HD_OptParamsToModel( Params, CalOptions, ParamsInfo )
P = UnflattenStruct(Params, ParamsInfo);
EstCamPosesV = P.EstCamPosesV;

CameraModel = CalOptions.PreviousCameraModel;

CameraModel.EstCamIntrinsicsH(CalOptions.IntrinsicsToOpt) = P.IntrinParams;
CameraModel.Distortion(CalOptions.DistortionParamsToOpt) = P.DistortParams;

CameraModel.EstCamIntrinsicsH = LFRecenterIntrinsics(CameraModel.EstCamIntrinsicsH, CalOptions.LFSize);
end

