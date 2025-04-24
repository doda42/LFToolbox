function Ray = D2D_UndistortRay( Ray, CameraModel, Options )

Options = LFDefaultField( 'Options', 'NInverse_Distortion_Iters', 3 );

%---Apply inverse lens distortion to yield the undistorted ray---
k1 = CameraModel.Distortion(1); % r^2
k2 = CameraModel.Distortion(2); % r^4
k3 = CameraModel.Distortion(3); % r^6
if( length(CameraModel.Distortion) > 3 )
	b1 = CameraModel.Distortion(4); % decentering of lens distortion
	b2 = CameraModel.Distortion(5); % decentering of lens distortion
else
	b1 = 0;
	b2 = 0;
end

Ray(3:4,:) = bsxfun(@minus, Ray(3:4,:), [b1; b2]); % decentering of lens distortion

%---Iteratively estimate the undistorted direction----
DesiredDirection = Ray(3:4,:);
for( InverseIters = 1:Options.NInverse_Distortion_Iters )
    R2 = sum(Ray(3:4,:).^2); % compute radius^2 for the current estimate
    % update estimate based on inverse of distortion model
    Ray(3:4,:) = DesiredDirection ./ repmat((1 + k1.*R2 + k2.*R2.^2 + k3.*R2.^3),2,1);
end
clear R2 DesiredDirection

Ray(3:4,:) = bsxfun(@plus, Ray(3:4,:), [b1; b2]); % decentering of lens distortion
