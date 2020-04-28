% LFDemoBasicFiltIllum - demonstrate basic filters on illum-captured imagery
% 
% Generates and displays a set of filtered light field images as separate figures. Demonstrates
% the shift sum filter and 4D planar and 4D hyperfan linear filters.
%
% Before running this you must download and decode the sample light field pack. Run the demo from
% the top of the samples folder. Please see the accompanying documentation for more information.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>

% Copyright (c) 2013-2020 Donald G. Dansereau

clearvars

%---Tweakables---
InputFname = fullfile('Images','Illum','LorikeetHiding__Decoded');

%---Load up a light field---
fprintf('Loading %s...', InputFname);
load(InputFname,'LF');
fprintf(' Done\n');
LFSize = size(LF);

CurFigure = 1;
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LF);
axis image off
truesize
title('Input');
drawnow

%---Demonstrate shift sum filter---
for( Slope = [-50/15, 9/15, -4/15] ) % Lorikeet: -4/15;  Background: 9/15;  Foreground: -50/15
	fprintf('Applying shift sum filter');
	[ShiftImg, FiltOptionsOut] = LFFiltShiftSum( LF, Slope );
	fprintf(' Done\n');
	FiltOptionsOut
	
	LFFigure(CurFigure); 
	CurFigure = CurFigure + 1;
	LFDisp(ShiftImg);
	axis image off
 	truesize
	title(sprintf('Shift sum filter, slope %.3g', Slope));
	drawnow
end

%---Setup for linear filters---
LFPaddedSize = LFSize;
% For systems with more memory, consider using some padding to improve performance near s,t edges:
% LFPaddedSize = [20,20, size(LF,3) + 16,size(LF,4) + 16];
BW = 0.04;
FiltOptions = [];

%---Demonstrate 2D line filter---
Slope = -4/15; % Lorikeet
fprintf('Building 2D frequency line... ');
Htv = LFBuild2DFreqLine( LFPaddedSize([1,3]), Slope, BW, FiltOptions);
fprintf('Applying filter in t,v');
[LFFilt, FiltOptionsOut] = LFFilt2DFFT( LF, Htv, [1,3], FiltOptions );
FiltOptionsOut
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Freq. line filt. t,v; slope %.3g, BW %.3g', Slope, BW));
drawnow

fprintf('Building 2D frequency line... ');
Hsu = LFBuild2DFreqLine( LFPaddedSize([2,4]), Slope, BW, FiltOptions);
fprintf('Applying filter in s,u');
[LFFilt, FiltOptionsOut] = LFFilt2DFFT( LFFilt, Hsu, [2,4], FiltOptions );
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Freq. line filt. t,v then s,u; slope %.3g, BW %.3g', Slope, BW));
drawnow

%---Demonstrate 4D Planar filter---
Slope = -4/15; % Lorikeet
fprintf('Building 4D frequency plane... ');
[H, FiltOptionsOut] = LFBuild4DFreqPlane( LFPaddedSize, Slope, BW, FiltOptions );
fprintf('Applying filter');
[LFFilt, FiltOptionsOut] = LFFilt4DFFT( LF, H, FiltOptionsOut );
FiltOptionsOut
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Frequency planar filter, slope %.3g, BW %.3g', Slope, BW));
drawnow
clear LFFilt

%---Demonstrate 4D Hyperfan filter---
Slope1 = -4/15; % Lorikeet
Slope2 = 15/15; % Far background
fprintf('Building 4D frequency hyperfan... ');
[H, FiltOptionsOut] = LFBuild4DFreqHyperfan( LFPaddedSize, Slope1, Slope2, BW, FiltOptions );
fprintf('Applying filter');
[LFFilt, FiltOptionsOut] = LFFilt4DFFT( LF, H, FiltOptionsOut );
FiltOptionsOut
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Frequency hyperfan filter, slopes %.3g, %.3g, BW %.3g', Slope1, Slope2, BW));
drawnow
