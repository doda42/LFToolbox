% LFUtilProcessCalibrations - process a folder/tree of camera calibrations
%
% Usage:
% 
%     LFUtilProcessCalibrations
%     LFUtilProcessCalibrations( CalibrationsPath )
%     LFUtilProcessCalibrations( CalibrationsPath, FileOptions )
%     LFUtilProcessCalibrations( [], FileOptions )
%
% All parameters are optional and take on default values as set in the "Defaults" section at the top
% of the implementation. As such, this can be called as a function or run directly by editing the
% code. When calling as a function, pass an empty array "[]" to omit a parameter.
% 
% This function recursively crawls through a folder identifying camera "calibration info" files and
% building a database for use in selecting a calibration appropriate to a light field. An example
% usage is in the image rectification code in LFUtilDecodeLytroFolder / LFSelectFromDatabase.
% 
% Inputs -- all are optional, see code below for default values :
% 
%    CalibrationsPath : Path to folder containing calibrations -- note the function operates
%                       recursively, i.e. it will search sub-folders. The calibration database will
%                       be created at the top level of this path. A typical configuration is to
%                       create a "Cameras" folder with a separate subfolder of calibrations for each
%                       camera in use. The appropriate path to pass to this function is the top
%                       level of that cameras folder.
% 
% 
%     FileOptions : struct controlling file naming and saving
%                       .OutputPath : By default files are saved alongside input files; specifying
%                                     an output path will mirror the folder structure of the input,
%                                     and save generated files in that structure, leaving the input
%                                     untouched
%                       .SaveResult : Set to false to perform a "dry run"
%         .CalibrationDatabaseFname : Name of file to which white image database is saved
%           .CalInfoFilenamePattern : File search pattern for finding calibrations
% 
% Output takes the form of a saved calibration database.
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFUtilDecodeLytroFolder, LFCalRectifyLF, LFSelectFromDatabase, LFUtilCalLensletCam,
% LFUtilProcessWhiteImages

% Copyright (c) 2013-2020 Donald G. Dansereau

function LFUtilProcessCalibrations( CalibrationsPath, FileOptions )

%---Defaults---
CalibrationsPath = LFDefaultVal( 'CalibrationsPath', 'Cameras' );

FileOptions = LFDefaultField( 'FileOptions', 'OutputPath', CalibrationsPath );
FileOptions = LFDefaultField( 'FileOptions', 'SaveResult', true );
FileOptions = LFDefaultField( 'FileOptions', 'CalibrationDatabaseFname', 'CalibrationDatabase.json' );
FileOptions = LFDefaultField( 'FileOptions', 'CalInfoFilenamePattern', 'CalInfo*.json' );

%---Crawl folder structure locating calibrations---
fprintf('Building database of calibrations in %s\n', CalibrationsPath);
CamInfo = LFGatherCamInfo( CalibrationsPath, FileOptions.CalInfoFilenamePattern );

%---Optionally save---
if( FileOptions.SaveResult )
    SaveFpath = fullfile(FileOptions.OutputPath, FileOptions.CalibrationDatabaseFname);
    fprintf('Saving to %s\n', SaveFpath);

	%---Make sure destination folder exists, and record relative path---
	warning('off','MATLAB:MKDIR:DirectoryExists');
	mkdir( FileOptions.OutputPath ); % make sure folder exists
	AbsoluteOutputPath = what( FileOptions.OutputPath );
	AbsoluteOutputPath = AbsoluteOutputPath.path;
	AbsoluteCalFilesPath = what( CalibrationsPath );
	AbsoluteCalFilesPath = AbsoluteCalFilesPath.path;
	% we need to be able to find the calibration files given the path to the database
	RelCalFilePath = relativepath( AbsoluteCalFilesPath, AbsoluteOutputPath );
	[CamInfo.RelCalFilePath] = deal(RelCalFilePath);
	
    TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
    GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);
    LFWriteMetadata(SaveFpath, LFVar2Struct(GeneratedByInfo, CamInfo));
end
