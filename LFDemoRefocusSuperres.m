% LFDemoRefocusSuperres - Demonstrate super-resolution using LFFiltShiftSum's UpsampRate parameter
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>

% Copyright (c) 2013-2020 Donald G. Dansereau

clearvars

%---Tweakables---
InputFname = fullfile('Images','ESLF','Plant.eslf.jpg');
CropRegion = [247, 288, 220, 261, 4, 11];
Slope = -0.15;
UpsampRate = 10;

%---Read file---
LF = LFReadESLF(InputFname);
LFFigure(1);
clf
LFDisp(LFHistEqualize(LFDisp(LF)))
axis image
axis off
hold on
plot(CropRegion([1,2,2,1,1]), CropRegion([4,4,3,3,4]), 'r-');

%---Crop---
LF = LF(CropRegion(5):CropRegion(6), CropRegion(5):CropRegion(6), ...
	CropRegion(3):CropRegion(4), CropRegion(1):CropRegion(2), :);
LFFigure(2);
clf
subplot(221);
LFDisp(LFHistEqualize(LFDisp(LF)));
axis image
axis off
title('Input');

%---Focus---
t1 = LFFiltShiftSum(LF,Slope);
subplot(222);
LFDisp(LFHistEqualize(LFDisp(t1)));
axis image
axis off
title('Focused');

%---2D cubic interpolation for comparison---
Interpolant = griddedInterpolant( t1 );
Interpolant.Method = 'cubic';
UVec = linspace(1,size(t1,2), size(t1,2)*UpsampRate);
VVec = linspace(1,size(t1,1), size(t1,1)*UpsampRate);
t1r = Interpolant( {VVec, UVec, 1:3} );
subplot(223);
LFDisp(LFHistEqualize(LFDisp(t1r)));
axis image
axis off
title('2D Cubic Interpolation');

%---Focus with super-res---
t2 = LFFiltShiftSum(LF,Slope,struct('UpsampRate',UpsampRate,'InterpMethod','cubic'));
subplot(224);
LFDisp(LFHistEqualize(LFDisp(t2)));
axis image
axis off
title('Focused with super-resolution');
