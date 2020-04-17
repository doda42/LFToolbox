% LFSelectFromDatabase - support function for selecting white image/calibration by matching serial/zoom/focus
% 
% Usage:
% 
%     SelectedCamInfo = LFSelectFromDatabase( DesiredCamInfo, DatabaseFname )
% 
% This helper function is used when decoding a light field to select an appropriate white image,
% and when rectifying a light field to select the appropriate calibration. It works by parsing a
% database (white image or calibration), and searching its CamInfo structure for the best match to
% the requested DesiredCamInfo. DesiredCamInfo is set based on the camera settings used in
% measuring the light field. See LFUtilDecodeLytroFolder / LFLytroDecodeImage for example usage.
%
% Selection prioritizes the camera serial number, then zoom, then focus. It is unclear whether this
% is the optimal approach.
%
% The output SelectedCamInfo includes all fields in the database's CamInfo struct, including the
% filename of the selected calibration or white image. This facilitates decoding / rectification.
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFUtilProcessWhiteImages, LFUtilProcessCalibrations, LFUtilDecodeLytroFolder, LFLytroDecodeImage

% Copyright (c) 2013-2020 Donald G. Dansereau

function SelectedCamInfo = LFSelectFromDatabase( DesiredCamInfo, DatabaseFname )

%---Load the database---
load(DatabaseFname, 'CamInfo');

%---Find the closest to the desired settings, prioritizing serial, then zoom, then focus---
ValidSerial = find( ismember({CamInfo.CamSerial}, {DesiredCamInfo.CamSerial}) );

% Discard non-matching serials
CamInfo = CamInfo(ValidSerial);
OrigIdx = ValidSerial;

% Find closest zoom
ZoomDiff = abs([CamInfo.ZoomStep] - DesiredCamInfo.ZoomStep);
BestZoomDiff = min(ZoomDiff);
BestZoomIdx = find( ZoomDiff == BestZoomDiff ); % generally multiple hits

% Retain the (possibly multiple) matches for the best zoom setting
% CamInfo.ZoomStep = CamInfo(BestZoomIdx).ZoomStep;
CamInfo = CamInfo(BestZoomIdx);
OrigIdx = OrigIdx(BestZoomIdx);

% Of those that are closest in zoom, find the one that's closest in focus
FocusDiff = abs([CamInfo.FocusStep] - DesiredCamInfo.FocusStep);
[~,BestFocusIdx] = min(FocusDiff);

% Retrieve the index into the original 
BestOriglIdx = OrigIdx(BestFocusIdx);
SelectedCamInfo = CamInfo(BestFocusIdx);


