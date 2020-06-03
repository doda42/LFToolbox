% todo[doc]
% todo[doc] : naming convention for camera models

%---Convert a feature observation (pixel index) into a ray using general H and distortion---
function CurFeatObs_Ray = ObsToRay_FreeIntrinH( CurFeatObs, CameraModel )
%---Project observed feature indices to [s,t,u,v] rays---
CurFeatObs_Ray = CameraModel.IntrinsicsH * CurFeatObs;

%---Apply direction-dependent distortion model---
if( ~isempty(CameraModel.Distortion) && any(CameraModel.Distortion(:)~=0))
	k1 = CameraModel.Distortion(1);
	k2 = CameraModel.Distortion(2);
	k3 = CameraModel.Distortion(3);
	b1dir = CameraModel.Distortion(4);
	b2dir = CameraModel.Distortion(5);
	Direction = CurFeatObs_Ray(3:4,:);
	Direction = bsxfun(@minus, Direction, [b1dir;b2dir]);
	DirectionR2 = sum(Direction.^2);
	Direction = Direction .* repmat((1 + k1.*DirectionR2 + k2.*DirectionR2.^2 + k3.*DirectionR2.^3),2,1);
	Direction = bsxfun(@plus, Direction, [b1dir;b2dir]);
	CurFeatObs_Ray(3:4,:) = Direction;
end
end