function [ Belonging, Centers, Dist ] = LFMicrolensBelonging(M,N, LensletGridModel)
%LFMICROLENSBELONGING

theta = LensletGridModel.Rot;
%Horizontal and vertical spacing in the hexagonal microlens space.
Dh = LensletGridModel.HSpacing;
Dv = sqrt((Dh/2)^2 + LensletGridModel.VSpacing^2);

%Define the microlens space (conversion matrix = TI)
RRotI = [cos(theta), sin(theta); -sin(theta), cos(theta)];%counter-clockwise (for theta>0)
RHexaI = [1, -LensletGridModel.HSpacing/2/LensletGridModel.VSpacing; 0, Dv/LensletGridModel.VSpacing];%conversion from orthogonal to hexagonal (60 deg shearing of the vertical axis).
RScaleI = [1/Dh,0;0,1/Dv];%scaling so that the unit is the distance between microlens centers.
TI = RScaleI*RHexaI*RRotI;

%Inverse conversion matrices
RRot = [cos(theta), -sin(theta); sin(theta), cos(theta)];%clockwise rotation (for theta>0)
RHexa = [1, LensletGridModel.HSpacing/2/Dv; 0, LensletGridModel.VSpacing/Dv];
RScale = [Dh,0;0,Dv];
T = RRot*RHexa*RScale;

%Offset : position of the first (top left) microlens center
o = [LensletGridModel.HOffset;LensletGridModel.VOffset];
if LensletGridModel.FirstPosShiftRow == 1
   o(1) = o(1) + LensletGridModel.HSpacing/2; 
end
o = RRot * o;%Inverse rotation must be applied (the data in LensletGridModel assumes the rotation has already been corrected).

[u, v] = meshgrid(1:N,1:M);
u = u(:);
v = v(:);
uv = [u';v'];
c = repmat(o,1,length(u));%offset to take the first microlens center as the origin.
kr = TI*(uv - c);

%Find 4 closest centers in hexagonal space by rounding (integer position in
%this space are microlens centers). One of them is the closest in the sensor space.
k = zeros(size(kr,1), size(kr,2), 4);
k(:,:,1) = [floor(kr(1,:));floor(kr(2,:))];
k(:,:,2) = [ceil(kr(1,:));floor(kr(2,:))];
k(:,:,3) = [floor(kr(1,:));ceil(kr(2,:))];
k(:,:,4) = [ceil(kr(1,:));ceil(kr(2,:))];

%Convert centers positions back to sensor space.
X = zeros(size(kr,1), size(kr,2), 4);
X(:,:,1) = T*k(:,:,1) + c;
X(:,:,2) = T*k(:,:,2) + c;
X(:,:,3) = T*k(:,:,3) + c;
X(:,:,4) = T*k(:,:,4) + c;
%Find the closest among the 4 in sensor space.
radius2 = (X(1,:,:) - repmat(uv(1,:),1,1,4)).^2 + (X(2,:,:) - repmat(uv(2,:),1,1,4)).^2;

clear k
[Dist, idx] = min(radius2,[],3);
Xf = zeros(size(kr));
for i = 1:4
   Xf(:,idx == i) = X(:,idx == i,i);
end
clear X

[Centers, ~, idx] = unique(Xf','rows');
Belonging = reshape(idx, M,N);
Dist = reshape(Dist, M,N);

end

