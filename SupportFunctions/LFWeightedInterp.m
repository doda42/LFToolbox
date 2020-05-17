function [ val ] = LFWeightedInterp(A, W, ImCoords, Belong, Centers)

%Belong : contains, for each pixel of the input image, the index of the
%closest microlens center in the list of Centers.

Nchan = size(A,3);
W = double(W);
A = double(A);
W = W./max(W(:));

u = ImCoords(:,2);
v = ImCoords(:,1);

val = zeros(size(u,1),Nchan);


%% Positions of the 4 neighboring pixels (used for linear interpolation)
uf = floor(u);
vf = floor(v);

ok = uf >= 1 & uf < size(A,2) & vf >= 1 & vf < size(A,1);
vf=vf(ok);
uf=uf(ok);
u=u(ok);
v=v(ok);

%indices of the 4 neighboring pixels in the input image.
id_uv(:,1) = sub2ind(size(A(:,:,1)), vf, uf);
id_uv(:,2) = sub2ind(size(A(:,:,1)), vf, uf+1);
id_uv(:,3) = sub2ind(size(A(:,:,1)), vf+1, uf);
id_uv(:,4) = sub2ind(size(A(:,:,1)), vf+1, uf+1);

%%
%Coefficients of the 4 neighbors for a classical linear interpolation.
alpha = u - uf;
beta = v - vf;
alphabeta(:,1) = (1 - alpha).*(1 - beta);
alphabeta(:,2) = alpha.*(1 - beta);
alphabeta(:,3) = (1 - alpha).*beta;
alphabeta(:,4) = alpha.*beta;

clear alpha beta xx yy uf vf uvw

%(x,y) positions of the microlens centers associated to each of the 4 neighbors.
xcenters(:,1) = Centers(Belong(id_uv(:,1)),1); %Belong(id_uv(:,i)) => index of the center (in the centers list) of the ith neighbor.
xcenters(:,2) = Centers(Belong(id_uv(:,2)),1);
xcenters(:,3) = Centers(Belong(id_uv(:,3)),1);
xcenters(:,4) = Centers(Belong(id_uv(:,4)),1);

ycenters(:,1) = Centers(Belong(id_uv(:,1)),2);
ycenters(:,2) = Centers(Belong(id_uv(:,2)),2);
ycenters(:,3) = Centers(Belong(id_uv(:,3)),2);
ycenters(:,4) = Centers(Belong(id_uv(:,4)),2);

%Index of the closest microlens center from the current pixel (among the centers associated to each of the 4 neighbors).
radius2 = bsxfun(@minus,xcenters,u).^2 + bsxfun(@minus,ycenters,v).^2;
[~, id_min] = min(radius2,[],2);
%Select the closest microlens center (among the list of 4) using the index id_min.
xcenter = zeros(size(xcenters,1),1);
ycenter = zeros(size(xcenters,1),1);
for i = 1:4
    xcenter(id_min == i) = xcenters(id_min == i,i);
    ycenter(id_min == i) = ycenters(id_min == i,i);
end

%Define weights for the 4 neighbors depending on their belonging to the
%same microlens as the current pixel:
[~, belonging] = ismember([xcenter,ycenter],Centers, 'rows'); %Index of the center (chosen for the current pixel) in the centers list.
belong = bsxfun(@eq, Belong(id_uv), belonging);  %For each of the 4 neighbors, true=associated to the same microlens as the current pixel.
belong = bsxfun(@rdivide, belong, sum(belong,2));%Normalize: the sum of the weights of the 4 neighbors must be 1.

clear xcenters ycenters radius2 xcenter ycenter belonging Belong u v


%Weight from the white image
w = W(id_uv);
w = bsxfun(@rdivide, w, sum(w,2));
w(~isfinite(w)) = 0.25;

%Combine weights of White image with weights from distances (alphabeta) and belonging.
w = w .* alphabeta .* belong;
%w = w .* alphabeta;
w = bsxfun(@rdivide, w, sum(w,2));
w(~isfinite(w)) = 0.25;

for ch = 1:Nchan    
    %Perform linear interpolation with the combined weights.
    val(ok,ch) = sum(w .* A(id_uv + numel(A(:,:,1))*(ch - 1)), 2);
end

end

