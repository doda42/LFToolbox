% todo[doc]
% todo[doc] : naming convention for camera models
% note: accepts many feature observations packed as column vectors

%---Convert a feature observation (pixel index) into a ray using general H and distortion---
function FeatObs_Ray = HD_ObsToRay( FeatObs_Idx, CameraModel, Options )

%---Project observed feature indices to [s,t,u,v] rays---
FeatObs_Ray = CameraModel.EstCamIntrinsicsH * FeatObs_Idx;

%---Apply distortion model---
FeatObs_Ray = feval( Options.Fn_DistortRay, FeatObs_Ray, CameraModel, Options );
