%---------------------------------------------------------------------------------------------------
function [OptParams0, ParamsInfo, JacobSensitivity] = ...
	TL_ModelToOptParams( EstCamPosesV, CameraModel, CalOptions )
% This makes use of FlattenStruct to reversibly flatten all params into a single array.
% It also applies the same process to a sensitivity list, to facilitate building a Jacobian
% Sparisty matrix.

% The 'P' structure contains all the parameters to encode, and the 'J' structure mirrors it exactly
% with a sensitivity list. Each entry in 'J' lists those poses that are senstitive to the
% corresponding parameter. e.g. The first estimated camera pose affects only observations made
% within the first pose, and so the sensitivity list for that parameter lists only the first pose. A
% `J' value of 0 means all poses are sensitive to that variable -- as in the case of the intrinsics,
% which affect all observations.
P.EstCamPosesV = EstCamPosesV;
J.EstCamPosesV = zeros(size(EstCamPosesV));
for( i=1:CalOptions.NPoses )
	J.EstCamPosesV(i,:) = i;
end
B.EstCamPosesV = [-inf;inf] .* ones(1,numel(P.EstCamPosesV));

% Subset physical params to optimise
PP = CameraModel.PhysicalParams;
OptParams = [PP.csx, PP.csy, PP.cux, PP.cuy, PP.du, PP.fMx, PP.fMy, PP.dM];
OptParams = OptParams .* CalOptions.OptParamsScale;  % bring values to similar scale
P.PtoOpt = OptParams;
J.PtoOpt = zeros(size(P.PtoOpt));
B.PtoOpt = CalOptions.Bounds;

P.DistortParams = CameraModel.Distortion(CalOptions.DistortionParamsToOpt);
J.DistortParams = zeros(size(CalOptions.DistortionParamsToOpt));
B.DistortParams = [-inf;inf] .* ones(1,numel(J.DistortParams));

[OptParams0, ParamsInfo] = FlattenStruct(P);
JacobSensitivity = FlattenStruct(J);
ParamsInfo.Bounds = FlattenStruct(B);
end