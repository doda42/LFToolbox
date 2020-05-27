% todo: doc
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
%                   .FeatFnamePattern : Pattern for building output checkerboard corner files; %s is
%                                       used as a placeholder for the base filename
%                     .LFFnamePattern : Filename pattern for locating input light fields
%             .ForceRedoFeatFinding : Forces the function to run, overwriting existing results
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

function CalOptions = LFModCalFindCheckerCorners( InputPath, CalOptions, FileOptions )

%---Defaults---
FileOptions = LFDefaultField( 'FileOptions', 'OutputPath', InputPath );

CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoFeatFinding', false );
CalOptions = LFDefaultField( 'CalOptions', 'FeatFnamePattern', '%s__Feat.mat' );
CalOptions = LFDefaultField( 'CalOptions', 'ShowDisplay', true );
CalOptions = LFDefaultField( 'CalOptions', 'MinSubimageWeight', 0.2 ); % for fast rejection of dark frames

%---Make sure dest exists---
warning('off','MATLAB:MKDIR:DirectoryExists');
mkdir( FileOptions.OutputPath );

%---Tagged onto all saved files---
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

%---Find input files---
[FileList, BasePath, BaseFnamePattern, CalOptions] = LFCalFindInputImages( InputPath, CalOptions );

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
	SaveFname = sprintf(CalOptions.FeatFnamePattern, ShortFname);
	SaveFname = fullfile( FileOptions.OutputPath, SaveFname );
	if( ~CalOptions.ForceRedoFeatFinding )
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
		LF = LFReadESLF( CurFname );
	elseif( strfind( CurFname, '.mat' ) )
		load( CurFname, 'LF' );
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
				CurChecker = [];
			else
				CurImg = squeeze(LF(TIdx, SIdx, :,:, 1:3));
				CurImg = rgb2gray(CurImg);
				
				[CurChecker,CheckBoardSize] = detectCheckerboardPoints( CurImg );  % todo: easy-insert alt feature finder here
				warning('off','vision:calibrate:boardShouldBeAsymmetric');  % display once (at most)
				CurValid = (prod(CheckBoardSize-1) == prod(CalOptions.ExpectedCheckerSize));
				CurChecker = CurChecker';
				
				% todo: error message / display for checker size mismatch

				%---For valid poses (having expected corner count) fix orientation---
				% Matlab's detectCheckerboardPoints sometimes expresses the grid in different orders, especially for
				% symmetric checkerbords.
				if( ~CurValid )
					CurChecker = [];
				else
					%--- reorient to expected ---
					CurChecker = LFCheckerFixOrient( CurChecker, CalOptions );
				end
			end
			
			FeatObs{TIdx,SIdx} = CurChecker;
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
				CurFeat = FeatObs{TIdx,SIdx};
				if( numel(CurFeat) > 0 )
					cx = CurFeat(1,:);
					cy = CurFeat(2,:);
					
					CurCol = mod( SIdx-1, NCols );
					CurRow = floor( (SIdx-1) / NCols );
					cx = cx + CurCol * LFSize(4);
					cy = cy + CurRow * LFSize(3);
					cx = cx .* Scaling(2);
					cy = cy .* Scaling(1);
					plot(cx,cy,'r.', 'markersize',15);
					plot(cx(1),cy(1),'g.', 'markersize',20);
					plot(cx(2),cy(2),'c.', 'markersize',20);
					plot(cx(end),cy(end),'y.', 'markersize',20);
				end
			end
			drawnow
		end
	end
	fprintf('\n');
	
	%---Save---
	fprintf('Saving result to %s...\n', SaveFname);
	save(SaveFname, 'GeneratedByInfo', 'FeatObs', 'LFSize', 'CalOptions', 'FileOptions');
	
	TotFileTime = TotFileTime + toc;
	MeanFileTime = TotFileTime / ProcessedFileCount;
	fprintf( 'Mean time per file: %.1f min\n', MeanFileTime/60 );
	TimeRemain_s = MeanFileTime * (length(FileList) - ProcessedFileCount - SkippedFileCount);
	fprintf( 'Est time remain: ~%d min\n', ceil(TimeRemain_s/60) );
end


fprintf(' ---Finished finding checkerboard corners---\n');
