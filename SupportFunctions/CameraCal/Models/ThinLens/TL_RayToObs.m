% todo[doc]
%---Convert a ray to its corresponding feature observation (pixel index) using general H and distortion---
function FeatObs_Idx = TL_RayToObs( FeatObs_Ray, CameraModel, Options )

Options = LFDefaultField( 'Options', 'NInverse_Distortion_Iters', 3 );
Options.NInverse_Distortion_Iters=3;
%---Apply inverse lens distortion to yield the undistorted ray---
k1 = CameraModel.Distortion(1); % r^2
k2 = CameraModel.Distortion(2); % r^4
k3 = CameraModel.Distortion(3); % r^6
% b1 = CameraModel.Distortion(4); % decentering of lens distortion
% b2 = CameraModel.Distortion(5); % decentering of lens distortion

% FeatObs_Ray(3:4,:) = bsxfun(@minus, FeatObs_Ray(3:4,:), [b1; b2]); % decentering of lens distortion

%---Iteratively estimate the undistorted direction----
DesiredDirection = FeatObs_Ray(3:4,:);
for( InverseIters = 1:Options.NInverse_Distortion_Iters )
    R2 = sum(FeatObs_Ray(3:4,:).^2); % compute radius^2 for the current estimate
    % update estimate based on inverse of distortion model
    FeatObs_Ray(3:4,:) = DesiredDirection ./ repmat((1 + k1.*R2 + k2.*R2.^2 + k3.*R2.^3),2,1);
end
clear R2 DesiredDirection

% FeatObs_Ray(3:4,:) = bsxfun(@plus, FeatObs_Ray(3:4,:), [b1; b2]); % decentering of lens distortion

%---Convert the undistorted ray to the corresponding index using the calibrated intrinsics---
FeatObs_Idx = CameraModel.EstCamIntrinsicsH^-1 * FeatObs_Ray;
