% todo[doc]
% shows how to run a calibration with the new modular calibration setup
% includes all steps from scratch: processing white images, decoding, calibration, rectification
clearvars

% ------------------------------------------------------------
TopInPath = '/home/don/Data.local/2025_PC_LFCal';
WhiteImagesInPath = fullfile(TopInPath, 'Cameras');
RawPath = 'RAW';

GridModelOptions = [];
DecodeOptions = [];
CalOptions = [];
RectOptions = [];

% Set up common cal options
CalOptions.ForceRedoInit = false;

% CurDataset  = 'B01-10mm'; % MOD_0032, 13 images
% CurDataset  = 'B01-16mm'; % MOD_0026, 17 images
% CurDataset  = 'B01-55mm'; % MOD_0012, 11 images
% CurDataset  = 'B01-80mm'; % MOD_0001, 8 images
CurDataset  = 'F01-6.5mm'; % MOD_0001, 15 images

CalOptions = LFReadMetadata( fullfile( TopInPath, RawPath, CurDataset, 'CalOptions.json' ) );
% CurMethod = 'HD';
CurMethod = 'TL';

switch( CurMethod )
	case 'TL'
		WhiteImagesProcPath = fullfile(WhiteImagesInPath, [CalOptions.CameraSerial, '_Proc']);
		DecodePath = 'Decoded';
		CalOptions = LFSetupCalModel( 'ThinLens', '2DNoBias', CalOptions );

	case 'HD'
		WhiteImagesProcPath = fullfile(WhiteImagesInPath, [CalOptions.CameraSerial, '_Proc']);
		DecodePath = 'Decoded';
		CalOptions = LFSetupCalModel( 'HDirect', '2DNoBias', CalOptions );

	otherwise
		error('unrecognised method');
end

CalibrationPath = ['Cal_', CurMethod];
DecodeOptions.WhiteImageDatabasePath = WhiteImagesProcPath;

% ---Process White Images---
FileOptionsWhiteImg.OutputPath = WhiteImagesProcPath;
InputPath = fullfile(WhiteImagesInPath, CalOptions.CameraSerial);
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
DecodeOptions.OptionalTasks = 'Rectify';
FileOptionsRect = FileOptionsDecode; % copy over the file format info
FileOptionsRect.OutputPath = fullfile( TopInPath, ['Rectified_', CurMethod], CurDataset );

% Find first decoded (non-rectified) file and copy it into the dest folder
% Copying this over avoids having to re-decode it
TestFile = LFFindFilesRecursive( FileOptionsDecode.OutputPath, {'*.mat'} );
TestFile = TestFile{1};
system(sprintf('mkdir -p %s', FileOptionsRect.OutputPath));
CpCmd = sprintf('cp %s %s', fullfile(FileOptionsDecode.OutputPath, TestFile), FileOptionsRect.OutputPath);
system(CpCmd);

% optionally take control over the rectified camera's intrinsics
DemoIntrinsicsControl = true;
if( DemoIntrinsicsControl )
	load(fullfile(FileOptionsDecode.OutputPath, TestFile), 'LF', 'LFMetadata', 'RectOptions');

	% visualise the default intrins sampling pattern
	sfigure(10);
	RectOptions = LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions ); 

	% manipulate the default intrins to cover a larger range of u,v
	RectOptions.RectCameraModel.EstCamIntrinsicsH(3,3) = 1.1 * RectOptions.RectCameraModel.EstCamIntrinsicsH(3,3);
	RectOptions.RectCameraModel.EstCamIntrinsicsH(4,4) = 1.1 * RectOptions.RectCameraModel.EstCamIntrinsicsH(4,4);
	RectOptions.RectCameraModel.EstCamIntrinsicsH = ...
		LFRecenterIntrinsics( RectOptions.RectCameraModel.EstCamIntrinsicsH, size(LF) );

	% visualise the manipulated intrins sampling pattern
	sfigure(11);
	LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions );
end

% Now find the corresponding (first) raw file and decode it with rectify turned on
TestFile = LFFindFilesRecursive( CurInPath, {'*.lfr', '*.LFR'} );
TestFile = TestFile{1};
sfigure(3);
LFUtilDecodeLytroFolder( fullfile(CurInPath, TestFile), FileOptionsRect, DecodeOptions, RectOptions );

