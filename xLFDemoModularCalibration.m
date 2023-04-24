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
FileOptionsWhiteImg.OutputPath = WhiteImagesProcPath;
InputPath = fullfile(WhiteImagesInPath, CameraSerial);
LFUtilProcessWhiteImages( InputPath, FileOptionsWhiteImg, GridModelOptions );

% ---Decode---
CurInPath = fullfile( TopInPath, RawPath, CurDataset );
FileOptionsDecode.OutputPrecision = 'uint8';
FileOptionsDecode.SaveWeight = true;
FileOptionsDecode.OutputFormat = 'mat';
FileOptionsDecode.OutputPath = fullfile( TopInPath, DecodePath, CurDataset );

CalInputImagesPath = FileOptionsDecode.OutputPath;
FileOptionsCal.WorkingPath = fullfile( TopInPath, CalibrationPath, CurDataset );
RectOptions.CalibrationDatabasePath = FileOptionsCal.WorkingPath;

LFUtilDecodeLytroFolder( CurInPath, FileOptionsDecode, DecodeOptions, RectOptions );

% ---Calibrate---
tic
LFUtilCalFeatureBased( CalInputImagesPath, CalOptions, FileOptionsCal );
toc

% ---Rectify---
%---Rectify a single test file---
LFUtilProcessCalibrations( RectOptions.CalibrationDatabasePath );
DecodeOptions.OptionalTasks = 'ModRectify';
FileOptionsRect = FileOptionsDecode; % copy over the file format info
FileOptionsRect.OutputPath = fullfile( TopInPath, ['Rectified_', CurMethod], CurDataset );

% Find first decoded (non-rectified) file and copy it into the dest folder
% Copying this over avoids having to re-decode it
TestFile = LFFindFilesRecursive( FileOptionsDecode.OutputPath, {'*.mat'} );
TestFile = TestFile{1};
system(sprintf('mkdir -p %s', FileOptionsRect.OutputPath))
CpCmd = sprintf('cp %s %s', fullfile(FileOptionsDecode.OutputPath, TestFile), FileOptionsRect.OutputPath);
system(CpCmd);

% optionally take control over the rectified camera's intrinsics
DemoIntrinsicsControl = true;
if( DemoIntrinsicsControl )
	load(fullfile(FileOptionsDecode.OutputPath, TestFile), 'LF', 'LFMetadata', 'RectOptions');

	% visualise the default intrins sampling pattern
	sfigure(10);
	RectOptions = LFModCalDispRectIntrinsics( LF, LFMetadata, RectOptions ); 

	% manipulate the default intrins to cover a larger range of u,v
	RectOptions.RectCameraModel.EstCamIntrinsicsH(3,3) = 1.1 * RectOptions.RectCameraModel.EstCamIntrinsicsH(3,3);
	RectOptions.RectCameraModel.EstCamIntrinsicsH(4,4) = 1.1 * RectOptions.RectCameraModel.EstCamIntrinsicsH(4,4);
	RectOptions.RectCameraModel.EstCamIntrinsicsH = ...
		LFRecenterIntrinsics( RectOptions.RectCameraModel.EstCamIntrinsicsH, size(LF) );

	% visualise the manipulated intrins sampling pattern
	sfigure(11);
	LFModCalDispRectIntrinsics( LF, LFMetadata, RectOptions );
end

% Now find the corresponding (first) raw file and decode it with rectify turned on
TestFile = LFFindFilesRecursive( CurInPath, {'*.lfr', '*.LFR'} );
TestFile = TestFile{1};
sfigure(3);
LFUtilDecodeLytroFolder( fullfile(CurInPath, TestFile), FileOptionsRect, DecodeOptions, RectOptions );

