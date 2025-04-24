% LFFindCalInfo - Find and load the calibration info file appropriate for a specific camera, zoom and focus
% 
% Usage: 
% 
%   [CalInfo, RectOptions] = LFFindCalInfo( LFMetadata, RectOptions )
% 
% This uses a calibration info database to locate a calibration appropriate to a given camera under a given set of zoom
% and focus settings. It is called during rectification.
% 
% Inputs:
% 
%  LFMetadata : loaded from a decoded light field, this contains the camera's serial number and zoom and focus settings.
%  RectOptions : struct controlling rectification
%      .CalibrationDatabasePath : full path to the calibration file database
%
% 
% Outputs:
% 
%   CalInfo: The resulting calibration info, or an empty array if no appropriate calibration found
%   RectOptions : struct controlling rectification, the following fields are added
%     .CalInfoFname : Name of the calibration file that was loaded
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFUtilProcessCalibrations, LFSelectFromDatabase

% Copyright (c) 2013-2020 Donald G. Dansereau

function [CalInfo, RectOptions] = LFFindCalInfo( LFMetadata, RectOptions )

CalInfo = [];

DesiredCam = struct('CamSerial', LFMetadata.SerialData.camera.serialNumber, ...
    'ZoomStep', LFMetadata.devices.lens.zoomStep, ...
    'FocusStep', LFMetadata.devices.lens.focusStep );
CalFileInfo = LFSelectFromDatabase( DesiredCam, RectOptions.CalibrationDatabasePath );

if( isempty(CalFileInfo) )
    return;
end

PathToDatabase = fileparts( RectOptions.CalibrationDatabasePath );
RectOptions.CalInfoFname = CalFileInfo.Fname;
PathToCalFile = fullfile(PathToDatabase,CalFileInfo.RelCalFilePath);
PathToCalFile = fullfile(PathToCalFile, RectOptions.CalInfoFname);
assert( exist(PathToCalFile, 'file')~=0, ...
	['Unable to locate %s, pointed to by calibration file database at %s. '...
	'Check / rebuild white image database.'], ...
	PathToCalFile, RectOptions.CalibrationDatabasePath );

fprintf('Loading %s\n', RectOptions.CalInfoFname);
CalInfo = LFReadMetadata( PathToCalFile );

%---Check that the decode options and calibration info are a good match---
fprintf('\nCalibration / LF Picture (ideally these match exactly):\n');
fprintf('Serial:\t%s\t%s\n', CalInfo.CamInfo.CamSerial, LFMetadata.SerialData.camera.serialNumber);
fprintf('Zoom:\t%d\t\t%d\n', CalInfo.CamInfo.ZoomStep, LFMetadata.devices.lens.zoomStep);
fprintf('Focus:\t%d\t\t%d\n\n', CalInfo.CamInfo.FocusStep, LFMetadata.devices.lens.focusStep);

if( ~strcmp(CalInfo.CamInfo.CamSerial, LFMetadata.SerialData.camera.serialNumber) )
    warning('Calibration is for a different camera, rectification may be invalid.');
end
if( CalInfo.CamInfo.ZoomStep ~= LFMetadata.devices.lens.zoomStep || ...
        CalInfo.CamInfo.FocusStep ~= LFMetadata.devices.lens.focusStep )
    warning('Zoom / focus mismatch -- for significant deviations rectification may be invalid.');
end

