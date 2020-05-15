function [ Raw ] = LFWeightedDemosaic( Raw1C, Weights, Belonging, DecodeOptions )
%LFWEIGHTEDDEMOSAIC Perform a white lenslet image guided demosaicing on
%a raw lenslet image
%   Raw = LFWeightedDemosaic(Raw1C, Weights, Belonging, DecodeOptions)
%   Raw: demosaiced lenslet image
%   Raw1C: raw lenslet image
%   Weights: weights derived from the white lenslet image serving as guide for the demosaicing
%   Belonging: labelling of each pixel of the lenslet image defining their
%   belonging to a lenslet
%   DecodeOptions: use of the "Precision" and "DemosaicOrder" fields
fprintf('\nDemosaicing the lenslet image: \n');

[M, N] = size(Raw1C);

Raw = zeros(M,N,3, DecodeOptions.Precision);

padsize = 2;
Raw = padarray(Raw, [padsize,padsize,0],0);
Raw1C = padarray(Raw1C, [padsize,padsize],0);
Weights = padarray(Weights, [padsize,padsize],0);
Belonging = padarray(Belonging, [padsize,padsize],0);
[M, N] = size(Raw1C);

a = 0.5;
b = 0.625;
c = 0.75;

BayerPattern = DecodeOptions.DemosaicOrder;
if strcmp(BayerPattern, 'bggr')
    Rstart = padsize + [2,2];
    G1start = padsize + [2,1];
    G2start = padsize + [1,2];
    Bstart = padsize + [1,1];

elseif strcmp(BayerPattern, 'rggb')
    Rstart = padsize + [1,1];
    G1start = padsize + [1,2];
    G2start = padsize + [2,1];
    Bstart = padsize + [2,2];

elseif strcmp(BayerPattern, 'gbrg')
    Rstart = padsize + [1,2];
    G1start = padsize + [1,1];
    G2start = padsize + [2,2];
    Bstart = padsize + [2,1];

elseif strcmp(BayerPattern, 'grbg')
    Rstart = padsize + [2,1];
    G1start = padsize + [2,2];
    G2start = padsize + [1,1];
    Bstart = padsize + [1,2];
else
    fprintf('Error : BayerPattern not valid\n');
    return
end

% DEMOSAICING THE RED PIXELS
fprintf('\t Red pixels:');
u = Rstart(1):2:(N - padsize);
v = Rstart(2):2:(M - padsize);

[uu, vv] = meshgrid(u,v);

uu = uu(:);
vv = vv(:);

id = sub2ind([M, N], vv, uu);
Raw(id) = Raw1C(id);
id_grad(:,1) = sub2ind([M, N], vv + 2, uu);
id_grad(:,2) = sub2ind([M, N], vv - 2, uu);
id_grad(:,3) = sub2ind([M, N], vv, uu + 2);
id_grad(:,4) = sub2ind([M, N], vv, uu - 2);
Rvals = Raw1C(id_grad);
Rconf = Weights(id_grad);
Rbelong = Belonging(id_grad) == repmat(Belonging(id),1,4);
Rsum = sum(Rconf.*Rbelong,2);
Rweight = Rconf.*Rbelong./repmat(Rsum,1,4);
gradR = Raw1C(id) - sum(Rvals.*Rweight,2);
gradR(~isfinite(gradR)) = 0;

clear id_grad Rvals Rconf Rbelong Rweight 

id_valG(:,1) = sub2ind([M, N], vv-1, uu);
id_valG(:,2) = sub2ind([M, N], vv+1, uu);
id_valG(:,3) = sub2ind([M, N], vv, uu-1);
id_valG(:,4) = sub2ind([M, N], vv, uu+1);
Gvals = Raw1C(id_valG);
Gconf = Weights(id_valG);
Gbelong = Belonging(id_valG) == repmat(Belonging(id),1,4);
Gsum = sum(Gconf.*Gbelong,2);
Gweight = Gconf.*Gbelong./repmat(Gsum,1,4);
Gweight(~isfinite(Gweight)) = 0.25;
% Raw(id + M*N) = sum(Gvals.*Gweight,2) + a.*min(4/5*(Rsum + Weights(id))./Gsum,1).^2.*gradR;
Raw(id + M*N) = sum(Gvals.*Gweight,2) + a.*gradR;

clear id_valG Gvals Gconf Gbelong Gweight Gsum

id_valB(:,1) = sub2ind([M, N], vv-1, uu-1);
id_valB(:,2) = sub2ind([M, N], vv-1, uu+1);
id_valB(:,3) = sub2ind([M, N], vv+1, uu+1);
id_valB(:,4) = sub2ind([M, N], vv+1, uu-1);
Bvals = Raw1C(id_valB);
Bconf = Weights(id_valB);
Bbelong = Belonging(id_valB) == repmat(Belonging(id),1,4);
Bsum = sum(Bconf.*Bbelong,2);
Bweight = Bconf.*Bbelong./repmat(Bsum,1,4);
Bweight(~isfinite(Bweight)) = 0.25;
% Raw(id + M*N*2) = sum(Bvals.*Bweight,2) + c.*min(4/5*(Rsum+ Weights(id))./Bsum,1).^2.*gradR;
Raw(id + M*N*2) = sum(Bvals.*Bweight,2) + c.*gradR;

clear id_valB Bvals Bconf Bbelong Bweight Bsum gradR Rsum id uu vv
fprintf(' done\n');
% DEMOSAICING THE GREEN PIXELS
fprintf('\t Green pixels:');
u = G1start(1):2:(N - padsize);
v = G1start(2):2:(M - padsize);
[uu1, vv1] = meshgrid(u,v);
uu1 = uu1(:);
vv1 = vv1(:);
g1 = 2*ones(size(vv1));

u = G2start(1):2:(N - padsize);
v = G2start(2):2:(M - padsize);
[uu2, vv2] = meshgrid(u,v);
uu2 = uu2(:);
vv2 = vv2(:);
g2 = zeros(size(vv2));

uu = [uu1;uu2];
vv = [vv1;vv2];
gg = [g1;g2];

clear uu1 vv1 uu2 vv2 g1 g2

id = sub2ind([M,N], vv, uu);
Raw(id + M*N) = Raw1C(id);
id_grad(:,1) = sub2ind([M,N], vv + 2, uu);
id_grad(:,2) = sub2ind([M,N], vv - 2, uu);
id_grad(:,3) = sub2ind([M,N], vv, uu + 2);
id_grad(:,4) = sub2ind([M,N], vv, uu - 2);
id_grad(:,5) = sub2ind([M,N], vv - 1, uu - 1);
id_grad(:,6) = sub2ind([M,N], vv - 1, uu + 1);
id_grad(:,7) = sub2ind([M,N], vv + 1, uu + 1);
id_grad(:,8) = sub2ind([M,N], vv + 1, uu - 1);
id_grad(:,9) = id;
Gvals = Raw1C(id_grad);
Gconf = Weights(id_grad);
Gbelong = Belonging(id_grad) == repmat(Belonging(id),1,9);
Gsum = sum(Gconf.*Gbelong,2);
Gweight = Gconf.*Gbelong;

H_v = diag([0.1, 0.1, -0.2, -0.2, -0.2, -0.2, -0.2, -0.2, 1]);
Gweight_v = Gweight*H_v;
sum_pos = sum(Gweight_v(:,1:2),2) + Gweight_v(:,9);
Gweight_v(:,1:2) = Gweight_v(:,1:2) ./ repmat(sum_pos,1,2);
Gweight_v(:,9) = Gweight_v(:,9) ./ sum_pos;

sum_neg = sum(Gweight_v(:,3:8),2);
Gweight_v(:,3:8) = -Gweight_v(:,3:8) ./ repmat(sum_neg,1,6);

gradG_v = sum(Gweight_v.*Gvals,2);
gradG_v(~isfinite(gradG_v)) = 0;

H_h = diag([-0.2, -0.2, 0.1, 0.1, -0.2, -0.2, -0.2, -0.2, 1]);
Gweight_h = Gweight*H_h;
sum_pos = sum(Gweight_h(:,3:4),2) + Gweight_h(:,9);
Gweight_h(:,3:4) = Gweight_h(:,3:4) ./ repmat(sum_pos,1,2);
Gweight_h(:,9) = Gweight_h(:,9) ./ sum_pos;

sum_neg = sum(Gweight_h(:,1:2),2) + sum(Gweight_h(:,5:8),2);
Gweight_h(:,1:2) = -Gweight_h(:,1:2) ./ repmat(sum_neg,1,2);
Gweight_h(:,5:8) = -Gweight_h(:,5:8) ./ repmat(sum_neg,1,4);

gradG_h = sum(Gweight_h.*Gvals,2);
gradG_h(~isfinite(gradG_h)) = 0;

clear id_grad Gvals Gconf Gbelong Gweight  Gweight_h Gweight_v H_h H_v sum_pos sum_neg

id_valv(:,1) = sub2ind([M,N], vv-1, uu);
id_valv(:,2) = sub2ind([M,N], vv+1, uu);
vals_v = Raw1C(id_valv);
conf_v = Weights(id_valv);
belong_v = Belonging(id_valv) == repmat(Belonging(id),1,2);
sum_v = sum(conf_v.*belong_v,2);
weight_v = conf_v.*belong_v./repmat(sum_v,1,2);
weight_v(~isfinite(weight_v)) = 0.5;
% Raw(id + M*N.*(2 - gg)) = sum(vals_v.*weight_v,2) + b*min(2/9.*Gsum./sum_v,1).^2.*gradG_v;
Raw(id + M*N.*(2 - gg)) = sum(vals_v.*weight_v,2) + b.*gradG_v;

clear id_valv vals_v conf_v belong_v weight_v

id_valh(:,1) = sub2ind([M,N], vv, uu-1);
id_valh(:,2) = sub2ind([M,N], vv, uu+1);
vals_h = Raw1C(id_valh);
conf_h = Weights(id_valh);
belong_h = Belonging(id_valh) == repmat(Belonging(id),1,2);
sum_h = sum(conf_h.*belong_h,2);
weight_h = conf_h.*belong_h./repmat(sum_h,1,2);
weight_h(~isfinite(weight_h)) = 0.5;
% Raw(id + M*N.*gg) = sum(vals_h.*weight_h,2) + b*min((2/9.*Gsum./sum_h),1).^2.*gradG_h;
Raw(id + M*N.*gg) = sum(vals_h.*weight_h,2) + b.*gradG_h;

clear id_valh vals_h conf_h belong_h weight_h gradG_h gradG_v uu vv gg id
fprintf(' done\n');
% DEMOSAICING THE BLUE PIXELS
fprintf('\t Blue pixels:');
u = Bstart(1):2:(N - padsize);
v = Bstart(2):2:(M - padsize);

[uu, vv] = meshgrid(u,v);

uu = uu(:);
vv = vv(:);

id = sub2ind([M,N], vv, uu);
Raw(id + M*N*2) = Raw1C(id);
id_grad(:,1) = sub2ind([M,N], vv + 2, uu);
id_grad(:,2) = sub2ind([M,N], vv - 2, uu);
id_grad(:,3) = sub2ind([M,N], vv, uu + 2);
id_grad(:,4) = sub2ind([M,N], vv, uu - 2);
Bvals = Raw1C(id_grad);
Bconf = Weights(id_grad);
Bbelong = Belonging(id_grad) == repmat(Belonging(id),1,4);
Bsum = sum(Bconf.*Bbelong,2);
Bweight = Bconf.*Bbelong./repmat(Bsum,1,4);
gradB = Raw1C(id) - sum(Bvals.*Bweight,2);
gradB(~isfinite(gradB)) = 0;

clear id_grad Bvals Bconf Bbelong Bweight 

id_valG(:,1) = sub2ind([M,N], vv-1, uu);
id_valG(:,2) = sub2ind([M,N], vv+1, uu);
id_valG(:,3) = sub2ind([M,N], vv, uu-1);
id_valG(:,4) = sub2ind([M,N], vv, uu+1);
Gvals = Raw1C(id_valG);
Gconf = Weights(id_valG);
Gbelong = Belonging(id_valG) == repmat(Belonging(id),1,4);
Gsum = sum(Gconf.*Gbelong,2);
Gweight = Gconf.*Gbelong./repmat(Gsum,1,4);
Gweight(~isfinite(Gweight)) = 0.25;
% Raw(id + M*N) = sum(Gvals.*Gweight,2) + a*min(4/5*(Bsum + Weights(id))./Gsum,1).^2.*gradB;
Raw(id + M*N) = sum(Gvals.*Gweight,2) + a.*gradB;

clear id_valG Gvals Gconf Gbelong Gweight

id_valR(:,1) = sub2ind([M,N], vv-1, uu-1);
id_valR(:,2) = sub2ind([M,N], vv-1, uu+1);
id_valR(:,3) = sub2ind([M,N], vv+1, uu+1);
id_valR(:,4) = sub2ind([M,N], vv+1, uu-1);
Rvals = Raw1C(id_valR);
Rconf = Weights(id_valR);
Rbelong = Belonging(id_valR) == repmat(Belonging(id),1,4);
Rsum = sum(Rconf.*Rbelong,2);
Rweight = Rconf.*Rbelong./repmat(Rsum,1,4);
Rweight(~isfinite(Rweight)) = 0.25;
% Raw(id) = sum(Rvals.*Rweight,2) + c*min(4/5*(Bsum + Weights(id))./Rsum,1).^2.*gradB;
Raw(id) = sum(Rvals.*Rweight,2) + c.*gradB;
fprintf(' done');

Raw = Raw(3:end-2,3:end-2,:);
%Raw = min(1, max(0, Raw));
end