% todo[doc]
% shows how to run a calibration with the new modular calibration setup
% includes all steps from scratch: processing white images, decoding, calibration, rectification
clearvars

% ------------------------------------------------------------
TopInPath = '/home/don/Data.local/2023_Modcal_Example';
WhiteImagesInPath = fullfile(TopInPath, 'Cameras');
CameraSerial = 'B5143104560';
RawPath = 'RAW';

CurDataset  = '2021_May_50mm_B';
CurMethod = 'TL';

GridModelOptions = [];
DecodeOptions = [];
CalOptions = [];
RectOptions = [];

% Set up common cal options
CalOptions.ForceRedoInit = true;
CalOptions.ExpectedCheckerSize =  [12,7];
CalOptions.ExpectedCheckerSpacing_m =  [20,20]*1e-3;

switch( CurMethod )
	case 'TL'
		WhiteImagesProcPath = fullfile(WhiteImagesInPath, [CameraSerial, '_ProcLegacy']);
		DecodePath = 'ModDecode_Legacy';
		CalOptions.NumIterations = 1;
		CalOptions = LFSetupCalModel( 'ThinLens', '2DNoBias', CalOptions );

	case 'HD'
		WhiteImagesProcPath = fullfile(WhiteImagesInPath, [CameraSerial, '_ProcLegacy']);
		DecodePath = 'ModDecode_Legacy';
		CalOptions.NumIterations = 1;
		CalOptions = LFSetupCalModel( 'HDirect', '2DNoBias', CalOptions );

	otherwise
		error('unrecognised method');
end

CalibrationPath = ['Cal_', CurMethod];
DecodeOptions.WhiteImageDatabasePath = WhiteImagesProcPath;

% ---Process White Images---
FileOptions.OutputPath = WhiteImagesProcPath;
InputPath = fullfile(WhiteImagesInPath, CameraSerial);
LFUtilProcessWhiteImages( InputPath, FileOptions, GridModelOptions );

% ---Decode---
FileOptions = [];
CurInPath = fullfile( TopInPath, RawPath, CurDataset );
FileOptions.OutputPrecision = 'uint8';
FileOptions.SaveWeight = true;
FileOptions.OutputFormat = 'mat';
FileOptions.OutputPath = fullfile( TopInPath, DecodePath, CurDataset );
LFUtilDecodeLytroFolder( CurInPath, FileOptions, DecodeOptions );

% ---Calibrate---
CalInputImagesPath = FileOptions.OutputPath;
CalFileOptions.WorkingPath = fullfile( TopInPath, CalibrationPath, CurDataset );
tic
LFUtilCalFeatureBased( CalInputImagesPath, CalOptions, CalFileOptions );
toc

% ---Rectify---
% todo : this decodes and rectifies all files in the set, could pick out one or two for testing
RectOptions.CalibrationDatabasePath = CalFileOptions.WorkingPath;
LFUtilProcessCalibrations( RectOptions.CalibrationDatabasePath );
DecodeOptions.OptionalTasks = 'ModRectify';
FileOptions.OutputPath = fullfile( TopInPath, ['Rectified_', CurMethod], CurDataset );
FileOptions.ForceRedo = true;
sfigure(1);  
LFUtilDecodeLytroFolder( CurInPath, FileOptions, DecodeOptions, RectOptions );

