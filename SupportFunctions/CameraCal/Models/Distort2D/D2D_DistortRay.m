function Ray = D2D_DistortRay( Ray, CameraModel, Options )

if( ~isempty(CameraModel.Distortion) && any(CameraModel.Distortion(:)~=0) )
	k1 = CameraModel.Distortion(1);
	k2 = CameraModel.Distortion(2);
	k3 = CameraModel.Distortion(3);
	if( length(CameraModel.Distortion) > 3 )
		b1dir = CameraModel.Distortion(4); % decentering of lens distortion
		b2dir = CameraModel.Distortion(5); % decentering of lens distortion
	else
		b1dir = 0;
		b2dir = 0;
	end
	Direction = Ray(3:4,:);
	Direction = bsxfun(@minus, Direction, [b1dir;b2dir]);
	DirectionR2 = sum(Direction.^2);
	Direction = Direction .* repmat((1 + k1.*DirectionR2 + k2.*DirectionR2.^2 + k3.*DirectionR2.^3),2,1);
	Direction = bsxfun(@plus, Direction, [b1dir;b2dir]);
	Ray(3:4,:) = Direction;
end