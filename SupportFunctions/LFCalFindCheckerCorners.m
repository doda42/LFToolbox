% LFCalFindCheckerCorners - locates corners in checkerboard images, called by LFUtilCalLensletCam
%
% Usage: 
%     CalOptions = LFCalFindCheckerCorners( InputPath, CalOptions )
%     CalOptions = LFCalFindCheckerCorners( InputPath )
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

function CalOptions = LFCalFindCheckerCorners( InputPath, CalOptions )

%---Defaults---
CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoCornerFinding', false );
CalOptions = LFDefaultField( 'CalOptions', 'LFFnamePattern', '%s__Decoded.mat' );
CalOptions = LFDefaultField( 'CalOptions', 'CheckerCornersFnamePattern', '%s__CheckerCorners.mat' );
CalOptions = LFDefaultField( 'CalOptions', 'ShowDisplay', true );
CalOptions = LFDefaultField( 'CalOptions', 'MinSubimageWeight', 0.2 * 2^16 ); % for fast rejection of dark frames

%---Build a regular expression for stripping the base filename out of the full raw filename---
BaseFnamePattern = regexp(CalOptions.LFFnamePattern, '%s', 'split');
BaseFnamePattern = cell2mat({BaseFnamePattern{1}, '(.*)', BaseFnamePattern{2}});

%---Tagged onto all saved files---
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

%---Crawl folder structure locating raw lenslet images---
fprintf('\n===Locating light fields in %s===\n', InputPath);
[FileList, BasePath] = LFFindFilesRecursive( InputPath, sprintf(CalOptions.LFFnamePattern, '*') );
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
    load(fullfile(BasePath, CurFname), 'LFMetadata');
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
    CurBaseFname = CurBaseFname{1}{1};
    [~,ShortFname] = fileparts(CurBaseFname);
    fprintf(' --- %s [%d / %d]', ShortFname, iFile, length(FileList));
    
    %---Check for already-decoded file---
    SaveFname = sprintf(CalOptions.CheckerCornersFnamePattern, CurBaseFname);
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
    load( CurFname, 'LF', 'LensletGridModel', 'DecodeOptions' );
    LFSize = size(LF);
    
    if( CalOptions.ShowDisplay )
        LFFigure(1);
        clf
    end
    
    fprintf('Processing all subimages');
    for( TIdx = 1:LFSize(1) )
        fprintf('.');
        for( SIdx = 1:LFSize(2) )
            % todo[optimization]: once a good set of corners is found, tracking them through s,u
            % and t,v would be significantly faster than independently recomputing the corners
            % for all u,v slices
            CurW = squeeze(LF(TIdx, SIdx, :,:, 4));
            CurW = mean(CurW(:));
            
            if( CurW < CalOptions.MinSubimageWeight )
                CurCheckerCorners = [];
            else
                CurImg = squeeze(LF(TIdx, SIdx, :,:, 1:3));
                CurImg = rgb2gray(CurImg);
                
                % Disabling partial detections as present toolbox deals only with full grid
                % detections
                [CurCheckerCorners,CheckBoardSize] = detectCheckerboardPoints( CurImg, 'PartialDetections', false );
                warning('off','vision:calibrate:boardShouldBeAsymmetric');  % display once (at most)
                
                % Matlab's detectCheckerboardPoints sometimes expresses the grid in different orders, especially for
                % symmetric checkerbords. It's up to the consumer of this data to treat the points in the correct order.
            end
                            
            HitCount(TIdx,SIdx) = numel(CurCheckerCorners);
            CheckerCorners{TIdx,SIdx} = CurCheckerCorners;
        end
        
        %---Display results---
        if( CalOptions.ShowDisplay )
            clf
            for( SIdx = 1:LFSize(2) )
                if( HitCount(TIdx,SIdx) > 0 )
                    CurImg = squeeze(LF(TIdx, SIdx, :,:, 1:3));
                    CurImg = rgb2gray(CurImg);
                    
                    NImages = LFSize(2);
                    NCols = ceil(sqrt(NImages));
                    NRows = ceil(NImages / NCols);
                    subplot(NRows, NCols, SIdx);
                    imshow(CurImg);
                    colormap gray
                    hold on;
                    cx = CheckerCorners{TIdx,SIdx}(:,1);
                    cy = CheckerCorners{TIdx,SIdx}(:,2);
                    plot(cx(:),cy(:),'r.', 'markersize',15)
                    axis off
                    axis image
                    axis tight
                end
            end
            truesize([150,150]); % bigger display
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
