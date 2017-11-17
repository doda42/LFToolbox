%  Start at a depth estimation demo
% Based on [1] "Gradient-based Depth Estimation from 4D Light Fields" by Dansereau and Bruton, 2004.
% Metric depth (rather than just slopes) requires a rectified light field

clearvars

MinGradient = 0.05;
MaxSlope = 5;
MinSlope = -5;
MinDepth = 0.14;
MaxDepth = 100;

load(fullfile('~/Data.local/2016_Lytro','Images','F01','IMG_0005__Decoded.mat'),'LF','RectOptions');

LFFigure(1);
subplot(221);
LFDisp(LF);
axis image
colorbar
title('In');

LF = squeeze(LF(:,:,:,:,2));  % green channel only
LF = LFConvertToFloat(LF, 'double');

[Ls,Lt,Lv,Lu] = gradient(LF);  % careful of the ordering of outputs from the gradient function

Mag1 = abs(Lu);
Mag2 = abs(Lv);
TotMag = Mag1+Mag2;

Slope1 = Ls./Lu;
Slope2 = Lt./Lv;
SlopeEst = (Mag1.*Slope1 + Mag2.*Slope2) ./ TotMag;

% threshold to remove invalid values and saturate to inrange values
SlopeEst( TotMag < MinGradient ) = NaN; 
InvalidMask = find(isnan(SlopeEst));
SlopeEst = max(MinSlope, min(MaxSlope, SlopeEst));
SlopeEst(InvalidMask) = NaN;

LFFigure(1);
subplot(223);
LFDisp(SlopeEst);
colorbar
axis image
title('Slope');

%---Find metric depth---
% Assumes identical parameterization in horz, vert dimensions... 
% it would be better to find independent vertical/horizontal depths and fuse them
H = RectOptions.RectCamIntrinsicsH;
duds = (H(3,1) + H(3,3) .* -SlopeEst) ./  (H(1,1) + H(1,3) .* -SlopeEst); % the negative is due to an axis direction mismatch (?)

D = 1;
Pz = D./(1-duds);
Pz(Pz<MinDepth) = NaN;
Pz(Pz>MaxDepth) = NaN;
mean(Pz(~isnan(Pz)))

LFFigure(1);
subplot(224);
LFDisp(1./(Pz));
axis image
colorbar
title('1/Pz [m^{-1}]');

colormap jet


LFFigure(2);
LFDisp(1./(Pz));
axis image
axis off
colorbar
title('1/P_z [m^{-1}]');
CMap = jet;
CMap(1,:) = 0;
colormap(CMap);
