% todo[doc]
%---Convert a ray to its corresponding feature observation (pixel index) using general H and distortion---
function FeatObs_Idx = TL_RayToObs( FeatObs_Ray, CameraModel, Options )

%---Apply inverse lens distortion to yield the undistorted ray---
FeatObs_Ray = feval( Options.Fn_UndistortRay, FeatObs_Ray, CameraModel, Options );

%---Convert the undistorted ray to the corresponding index using the calibrated intrinsics---
FeatObs_Idx = CameraModel.EstCamIntrinsicsH^-1 * FeatObs_Ray;
