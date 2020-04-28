% LFCalDispEstPoses - Visualize pose estimates associated with a calibration info file
%
% Usage: 
%     LFCalDispEstPoses( InputPath, CalOptions, DrawFrameSizeMult, BaseColour )
%
% Draws a set of frames, one for each camera pose, in the colour defined by BaseColour. All inputs
% except InputPath are optional. Pass an empty array "[]" to omit a parameter. See
% LFUtilCalLensletCam for example usage.
% 
% Inputs:
% 
%     InputPath : Path to folder containing CalInfo file.
% 
%     [optional] CalOptions : struct controlling calibration parameters
%                 .CalInfoFname : Name of the file containing calibration estimate; note that this
%                                 parameter is automatically set in the CalOptions struct returned
%                                 by LFCalInit
% 
%     [optional] DrawFrameSizeMult : Multiplier on the displayed frame sizes
% 
%     [optional] BaseColour : RGB triplet defining a base drawing colour, RGB values are in the
%                             range 0-1
%
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFUtilCalLensletCam

% Copyright (c) 2013-2020 Donald G. Dansereau

function LFCalDispEstPoses( InputPath, CalOptions, DrawFrameSizeMult, BaseColour )

%---Defaults---
CalOptions = LFDefaultField( 'CalOptions', 'CalInfoFname', 'CalInfo.json' );
DrawFrameSizeMult = LFDefaultVal( 'DrawFrameSizeMult', 1 );
BaseColour = LFDefaultVal( 'BaseColour', [1,1,0] );


%---
Fname = fullfile(CalOptions.CalInfoFname);
EstCamPosesV = LFStruct2Var( LFReadMetadata(fullfile(InputPath, Fname)), 'EstCamPosesV' );

% Establish an appropriate scale for the drawing
AutoDrawScale = EstCamPosesV(:,1:3);
AutoDrawScale = AutoDrawScale(:);
AutoDrawScale = (max(AutoDrawScale) - min(AutoDrawScale))/10;

%---Draw cameras---
BaseFrame = ([0 1 0 0 0 0; 0 0 0 1 0 0; 0 0 0 0 0 1]);
DrawFrameMed = [AutoDrawScale * DrawFrameSizeMult * BaseFrame; ones(1,6)];
DrawFrameLong = [AutoDrawScale*3/2 * DrawFrameSizeMult * BaseFrame; ones(1,6)];

for( PoseIdx = 1:size(EstCamPosesV, 1) )
    CurH = eye(4);
    CurH(1:3,1:3) = rodrigues( EstCamPosesV(PoseIdx,4:6) );
    CurH(1:3,4) = EstCamPosesV(PoseIdx,1:3);
    
    CurH = CurH^-1;
    
    CamFrame = CurH * DrawFrameMed(:,1:4);
    plot3( CamFrame(1,:), CamFrame(2,:), CamFrame(3,:), '-', 'color', BaseColour.*0.5, 'LineWidth',2 );
    hold on
    
    CamFrame = CurH * DrawFrameLong(:,5:6);
    plot3( CamFrame(1,:), CamFrame(2,:), CamFrame(3,:), '-', 'color', BaseColour, 'LineWidth',2 );
end

axis equal
grid on
xlabel('x [m]');
ylabel('y [m]');
zlabel('z [m]');
title('Estimated camera poses');
