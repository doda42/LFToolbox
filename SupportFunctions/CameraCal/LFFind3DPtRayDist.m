% todo[doc]

%---Compute distances from 3D rays to a 3D points---
function [Dist] = LFFind3DPtRayDist( PtOnRay, RayDir, Pt3D )

RayDir = RayDir ./ repmat(sqrt(sum(RayDir.^2)), 3,1); % normalize ray
Pt3D = Pt3D - PtOnRay;    % Vector to point

PD1 = dot(Pt3D, RayDir);
PD1 = repmat(PD1,3,1).*RayDir; % Project point vec onto ray vec

Pt3D = Pt3D - PD1;
Dist = sqrt(sum(Pt3D.^2, 1)); % Distance from point to projected point

end