% LFCalFindCheckerCorners - locates corners in checkerboard images, called by LFUtilCalLensletCam
%
% Usage:
%     CalOptions = LFCalFindCheckerCorners( InputPath )
%     CalOptions = LFCalFindCheckerCorners( InputPath, [CalOptions], [FileOptions] )
%
% This function is called by LFUtilCalLensletCam to identify the corners in a set of checkerboard
% images.
%
% Inputs:
%
%     InputPath : Path to folder containing decoded checkerboard images.
%
%     [optional] CalOptions : struct controlling calibration parameters, all fields are optional
%         .CheckerCornersFnamePattern : Pattern for building output checkerboard corner files; %s is
%                                       used as a placeholder for the base filename
%                     .LFFnamePattern : Filename pattern for locating input light fields
%             .ForceRedoCornerFinding : Forces the function to run, overwriting existing results
%                        .ShowDisplay : Enables display, allowing visual verification of results
%
%    [optional] FileOptions : struct controlling file naming and saving
%               .OutputPath : By default files are saved alongside input files; specifying an output
%                             path will mirror the folder structure of the input, and save generated
%                             files in that structure, leaving the input untouched
%
% Outputs :
%
%     CalOptions struct as applied, including any default values as set up by the function
%
%     Checker corner files are the key outputs of this function -- one file is generated fore each
%     input file, containing the list of extracted checkerboard corners.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFUtilCalLensletCam, LFCalInit, LFCalRefine

% Copyright (c) 2013-2020 Donald G. Dansereau

function CalOptions = LFCalFindCheckerCorners( InputPath, CalOptions, FileOptions )

%---Defaults---
FileOptions = LFDefaultField( 'FileOptions', 'OutputPath', InputPath );

CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoCornerFinding', false );
CalOptions = LFDefaultField( 'CalOptions', 'LFFnamePattern', ...
	{'%s__Decoded.mat','%s__Decoded.eslf.png'} );
CalOptions = LFDefaultField( 'CalOptions', 'CheckerCornersFnamePattern', '%s__CheckerCorners.mat' );
CalOptions = LFDefaultField( 'CalOptions', 'ShowDisplay', true );
CalOptions = LFDefaultField( 'CalOptions', 'MinSubimageWeight', 0.2 ); % for fast rejection of dark frames

if( ~iscell(CalOptions.LFFnamePattern) )
	CalOptions.LFFnamePattern = {CalOptions.LFFnamePattern};
end

%---Make sure dest exists---
warning('off','MATLAB:MKDIR:DirectoryExists');
mkdir( FileOptions.OutputPath );

%---Build a regular expression for stripping the base filename out of the full raw filename---
BaseFnamePattern = regexp(CalOptions.LFFnamePattern, '%s', 'split');
for( iPat = 1:length(BaseFnamePattern) )
	CurPat = BaseFnamePattern{iPat};
	CurPat = cell2mat({CurPat{1}, '(.*)', CurPat{2}});
	BaseFnamePattern{iPat} = CurPat;
	CalOptions.LFFnamePattern{iPat} = sprintf(CalOptions.LFFnamePattern{iPat}, '*');
end

%---Tagged onto all saved files---
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

%---Crawl folder structure locating raw lenslet images---
fprintf('\n===Locating light fields in %s===\n', InputPath);
[FileList, BasePath] = LFFindFilesRecursive( InputPath, CalOptions.LFFnamePattern );
if( isempty(FileList) )
	error(['No files found... are you running from the correct folder?\n'...
		'       Current folder: %s\n'], pwd);
end;
fprintf('Found :\n');
disp(FileList)

%---Check zoom / focus and serial number settings across light fields---
fprintf('Checking zoom / focus / serial number across all files...\n');
for( iFile = 1:length(FileList) )
	CurFname = FileList{iFile};
	if( strfind( CurFname, '.eslf' ) )
		MetadataFname = [CurFname,'.json'];
		MetadataFname = fullfile(BasePath, MetadataFname);
		AllMetadata = LFReadMetadata( MetadataFname );
		LFMetadata = AllMetadata.LFMetadata;
	elseif( strfind( CurFname, '.mat' ) )
		load(fullfile(BasePath, CurFname), 'LFMetadata');
	else
		error('unknown file format\n');
	end
	
	CamSettings(iFile).Fname = CurFname;
	CamSettings(iFile).ZoomStep = LFMetadata.devices.lens.zoomStep;
	CamSettings(iFile).FocusStep = LFMetadata.devices.lens.focusStep;
	CamSettings(iFile).CamSerial = LFMetadata.SerialData.camera.serialNumber;
end

% Find the most frequent serial number
[UniqueSerials,~,SerialIdx]=unique({CamSettings.CamSerial});
NumSerials = size(UniqueSerials,2);
MostFreqSerialIdx = median(SerialIdx);
CamInfo.CamSerial = UniqueSerials{MostFreqSerialIdx};
CamInfo.CamModel = LFMetadata.camera.model;

% Finding the most frequent zoom / focus is easier
CamInfo.FocusStep = median([CamSettings.FocusStep]);
CamInfo.ZoomStep = median([CamSettings.ZoomStep]);
fprintf( 'Serial: %s, ZoomStep: %d, FocusStep: %d\n', CamInfo.CamSerial, CamInfo.ZoomStep, CamInfo.FocusStep );
InvalidIdx = find( ...
	([CamSettings.ZoomStep] ~= CamInfo.ZoomStep) | ...
	([CamSettings.FocusStep] ~= CamInfo.FocusStep) | ...
	(SerialIdx ~= MostFreqSerialIdx)' );

if( ~isempty(InvalidIdx) )
	warning('Some files mismatch');
	for( iInvalid = InvalidIdx )
		fprintf('Serial: %s, ZoomStep: %d, FocusStep: %d -- %s\n', CamSettings(iInvalid).CamSerial, CamSettings(iInvalid).ZoomStep, CamSettings(iInvalid).FocusStep, CamSettings(iInvalid).Fname);
	end
	fprintf('For significant deviations, it is recommended that these files be removed and the program restarted.');
else
	fprintf('...all files match\n');
end

%---enable warning to display it once; gets disabled after first call to detectCheckerboardPoints--
warning('on','vision:calibrate:boardShouldBeAsymmetric');
fprintf('Skipping subimages with mean weight below MinSubimageWeight %g\n', CalOptions.MinSubimageWeight);

%---clear display---
if( CalOptions.ShowDisplay )
	LFFigure(1);
	FirstRun = true;
	clf
end

%---Process each folder---
SkippedFileCount = 0;
ProcessedFileCount = 0;
TotFileTime = 0;
%---Process each raw lenslet file---
for( iFile = 1:length(FileList) )
	CurFname = FileList{iFile};
	CurFname = fullfile(BasePath, CurFname);
	
	%---Build the base filename---
	CurBaseFname = regexp(CurFname, BaseFnamePattern, 'tokens');
	CurBaseFname = [CurBaseFname{:}]; % only one will match
	CurBaseFname = CurBaseFname{1}{1};
	[~,ShortFname] = fileparts(CurBaseFname);
	fprintf(' --- %s [%d / %d]', ShortFname, iFile, length(FileList));
	
	%---Check for already-decoded file---
	SaveFname = sprintf(CalOptions.CheckerCornersFnamePattern, ShortFname);
	SaveFname = fullfile( FileOptions.OutputPath, SaveFname );
	if( ~CalOptions.ForceRedoCornerFinding )
		if( exist(SaveFname, 'file') )
			fprintf( ' already done, skipping\n' );
			SkippedFileCount = SkippedFileCount + 1;
			continue;
		end
	end
	ProcessedFileCount = ProcessedFileCount + 1;
	fprintf('\n');
	
	%---Load the LF---
	tic  % track time
	if( strfind( CurFname, '.eslf' ) )
		[LF, AllMetadata] = LFReadESLF( CurFname );
		LensletGridModel = AllMetadata.LensletGridModel;
		DecodeOptions = AllMetadata.DecodeOptions;
	elseif( strfind( CurFname, '.mat' ) )
		load( CurFname, 'LF', 'LensletGridModel', 'DecodeOptions' );
	else
		error('unknown file format\n');
	end
	
	LFSize = size(LF);
	
	fprintf('Processing all subimages');
	for( TIdx = 1:LFSize(1) )
		fprintf('.');
		for( SIdx = 1:LFSize(2) )
			% todo[optimization]: once a good set of corners is found, tracking them through s,u
			% and t,v would be significantly faster than independently recomputing the corners
			% for all u,v slices
			CurW = squeeze(LF(TIdx, SIdx, :,:, 4));
			CurW = mean(CurW(:));
			
			if( CurW < CalOptions.MinSubimageWeight * intmax(class(LF)) )
				CurCheckerCorners = [];
			else
				CurImg = squeeze(LF(TIdx, SIdx, :,:, 1:3));
				CurImg = rgb2gray(CurImg);
				
				[CurCheckerCorners,CheckBoardSize] = detectCheckerboardPoints( CurImg );
				warning('off','vision:calibrate:boardShouldBeAsymmetric');  % display once (at most)
				
				% Matlab's detectCheckerboardPoints sometimes expresses the grid in different orders, especially for
				% symmetric checkerbords. It's up to the consumer of this data to treat the points in the correct order.
			end
			
			HitCount(TIdx,SIdx) = numel(CurCheckerCorners);
			CheckerCorners{TIdx,SIdx} = CurCheckerCorners;
		end
		
		%---Display results---
		if( CalOptions.ShowDisplay )
			NImages = LFSize(2);
			NCols = ceil(sqrt(NImages));
			NRows = ceil(NImages / NCols);
			CurSlice = squeeze(LF(TIdx, :, :,:, 2));  % green channel as approx to grayscale
			CurSlice = permute(CurSlice,[2,3,1]);
			
			LFFigure(1);
			hold off
			if( FirstRun )
				h = montage( CurSlice, 'Size', [NRows, NCols] );
				FirstRun = false;
			else
				h = montage( CurSlice, 'Size', [NRows, NCols], 'Parent', gca );
			end
			Scaling = size(h.CData) ./ (LFSize(3:4) .* [NRows, NCols]);
			hold on;
			for( SIdx = 1:LFSize(2) )
				if( HitCount(TIdx,SIdx) > 0 )
					cx = CheckerCorners{TIdx,SIdx}(:,1);
					cy = CheckerCorners{TIdx,SIdx}(:,2);
					
					CurCol = mod( SIdx-1, NCols );
					CurRow = floor( (SIdx-1) / NCols );
					cx = cx + CurCol * LFSize(4);
					cy = cy + CurRow * LFSize(3);
					cx = cx .* Scaling(2);
					cy = cy .* Scaling(2);
					plot(cx(:),cy(:),'r.', 'markersize',15)
				end
			end
			drawnow
		end
	end
	fprintf('\n');
	
	%---Save---
	fprintf('Saving result to %s...\n', SaveFname);
	save(SaveFname, 'GeneratedByInfo', 'CheckerCorners', 'LFSize', 'CamInfo', 'LensletGridModel', 'DecodeOptions');
	
	TotFileTime = TotFileTime + toc;
	MeanFileTime = TotFileTime / ProcessedFileCount;
	fprintf( 'Mean time per file: %.1f min\n', MeanFileTime/60 );
	TimeRemain_s = MeanFileTime * (length(FileList) - ProcessedFileCount - SkippedFileCount);
	fprintf( 'Est time remain: ~%d min\n', ceil(TimeRemain_s/60) );
end


fprintf(' ---Finished finding checkerboard corners---\n');
