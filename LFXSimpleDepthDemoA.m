% Start at a depth estimation demo
% Based on [1] "Gradient-based Depth Estimation from 4D Light Fields" by Dansereau and Bruton, 2004.
% To get from slopes to depth will require calibration and a bit of math

clearvars

MinGradient = 0.025;
MaxAbsSlope = 1;

load(fullfile('~/Data.local/2016_Lytro','Images','Illum','Jacaranda__Decoded.mat'),'LF','RectOptions');

LFFigure(1);
subplot(211);
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
SlopeEst = max(-MaxAbsSlope, min(MaxAbsSlope, SlopeEst));
SlopeEst(InvalidMask) = NaN;

LFFigure(1);
subplot(212);
LFDisp(SlopeEst);
colorbar
axis image
title('Slope');



LFFigure(2);
LFDisp(1./(Pz));
axis image
axis off
colorbar
title('1/P_z [m^{-1}]');
