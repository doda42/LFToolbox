% LFDemoBasicFiltGantry - demonstrate basic filters on stanford-style gantry light fields
% 
% Generates and displays a set of filtered light field images as separate figures. Demonstrates
% the shift sum filter and 4D planar and 4D hyperfan linear filters.
%
% Before running this you must download sample light fields from the stanford light field archive.
% Run the demo from the top of the stanford light fields folder. Please see the accompanying documentation for
% more information.
%
% To change input light fields, uncomment the appropriate line below.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>

% Copyright (c) 2013-2020 Donald G. Dansereau

clearvars

%---Tweakables---
UVLimit = 300;  % Light fields get scaled to this size in u,v 
InPathPattern = '%s/rectified'; % Pattern for where the light fields are unzipped

% Select an input light field from the list below
% InFile: Which of the Stanford lightfields to load
% SFlip: Some of the light fields are of a different "handedness", and need to be flipped in s

% InFile = 'Amethyst'; SFlip = true;
% InFile = 'Bracelet'; SFlip = false;
% InFile = 'Bulldozer'; SFlip = true;
% InFile = 'Bunny'; SFlip = true;
% InFile = 'Chess'; SFlip = true;
% InFile = 'Eucalyptus'; SFlip = true;
% InFile = 'JellyBeans'; SFlip = true;
InFile = 'LegoKnights'; SFlip = false;
% InFile = 'Tarot_Coarse'; SFlip = false;
% InFile = 'Tarot_Fine'; SFlip = false;
% InFile = 'Treasure'; SFlip = true;
% InFile = 'Truck'; SFlip = true;

%- Params for linear filters
% These must be tuned to conform to the characteristics of the light field
ShiftSumSlope1 = -0.6 * UVLimit/400;
ShiftSumSlope2 = 0;
PlanarSlope = 0;
PlanarBW = 0.06;
HyperfanSlope1 = 0;
HyperfanSlope2 = 2;
HyperfanBW = 0.035;
FiltOptions = [];

%---Load the light field---
FullPath = sprintf(InPathPattern, InFile);
fprintf('%s : ', FullPath);
LF = LFReadGantryArray(FullPath, struct('UVLimit', UVLimit) );
LFSize = size(LF);
if( SFlip ) % Some of the light fields are of a different "handedness", and need to be flipped in s
    LF = LF(:,end:-1:1,:,:,:);
end

CurFigure = 1;
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LF);
axis image off
truesize
title('Input');
drawnow

%---Demonstrate shift sum filter---
for( Slope = [ShiftSumSlope1, ShiftSumSlope2] )
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

%---Demonstrate 2D line filter---
fprintf('Building 2D frequency line... ');
Htv = LFBuild2DFreqLine( LFSize([1,3]), PlanarSlope, PlanarBW, FiltOptions);
fprintf('Applying filter in t,v');
[LFFilt, FiltOptionsOut] = LFFilt2DFFT( LF, Htv, [1,3], FiltOptions );
FiltOptionsOut
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Freq. line filt. t,v; slope %.3g, BW %.3g', PlanarSlope, PlanarBW));
drawnow

fprintf('Building 2D frequency line... ');
Hsu = LFBuild2DFreqLine( LFSize([2,4]), PlanarSlope, PlanarBW, FiltOptions);
fprintf('Applying filter in s,u');
[LFFilt, FiltOptionsOut] = LFFilt2DFFT( LFFilt, Hsu, [2,4], FiltOptions );
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Freq. line filt. t,v then s,u; slope %.3g, BW %.3g', PlanarSlope, PlanarBW));
drawnow

%---Demonstrate 4D Planar filter---
fprintf('Building 4D frequency plane... ');
[H, FiltOptionsOut] = LFBuild4DFreqPlane( LFSize, PlanarSlope, PlanarBW );
fprintf('Applying filter');
[LFFilt, FiltOptionsOut] = LFFilt4DFFT( LF, H, FiltOptionsOut );
FiltOptionsOut
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Frequency planar filter, slope %.3g, HyperfanBW %.3g', PlanarSlope, PlanarBW));
drawnow

%---Demonstrate 4D Hyperfan filter---
fprintf('Building 4D frequency hyperfan... ');
[H, FiltOptionsOut] = LFBuild4DFreqHyperfan( LFSize, HyperfanSlope1, HyperfanSlope2, HyperfanBW );
fprintf('Applying filter');
[LFFilt, FiltOptionsOut] = LFFilt4DFFT( LF, H, FiltOptionsOut );
FiltOptionsOut
LFFigure(CurFigure);
CurFigure = CurFigure + 1;
LFDisp(LFFilt);
axis image off
truesize
title(sprintf('Frequency hyperfan filter, slopes %.3g, %.3g, HyperfanBW %.3g', HyperfanSlope1, HyperfanSlope2, HyperfanBW));
drawnow
