%todo[doc]
function CalOptions = LFModCalCollectFeatures( FileOptions, CalOptions )

CalOptions = LFDefaultField( 'CalOptions', 'FeatFnamePattern', '%s__Feats.mat' );
CalOptions = LFDefaultField( 'CalOptions', 'AllFeatsFname', 'AllFeats.mat' );

%---Crawl folder structure locating feature observation info files---
fprintf('\n===Locating feature observation files in %s===\n', FileOptions.WorkingPath);
[CalOptions.FileList, BasePath] = LFFindFilesRecursive( FileOptions.WorkingPath, sprintf(CalOptions.FeatFnamePattern, '*') );
fprintf('Found :\n');
disp(CalOptions.FileList)

%---Load each feature observation file---

fprintf('Loading feature observations...\n');
for( iFile = 1:length(CalOptions.FileList) )
    CurFname = CalOptions.FileList{iFile};
    [~,ShortFname] = fileparts(CurFname);
    fprintf('---%s [%3d / %3d]...', ShortFname, iFile, length(CalOptions.FileList));
    
    load(fullfile(BasePath, CurFname), 'FeatObs', 'LFSize', 'LFMetadata');
    PerImageValidCount = 0;
    for( TIdx = 1:size(FeatObs,1) )
        for( SIdx = 1:size(FeatObs,2) )
            CurFeat = FeatObs{TIdx, SIdx};
            if( ~isempty(CurFeat) )
                PerImageValidCount = PerImageValidCount + 1;
                AllFeatObs{iFile, TIdx, SIdx} = CurFeat;
            end
        end
    end
    CalOptions.ValidSubimageCount(iFile) = PerImageValidCount;
    fprintf(' %d / %d valid.\n', PerImageValidCount, prod(LFSize(1:2)));
end

TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

SaveFname = fullfile(FileOptions.WorkingPath, CalOptions.AllFeatsFname);
fprintf('\nSaving to %s...\n', SaveFname);
save(SaveFname, 'GeneratedByInfo', 'AllFeatObs', 'LFSize', 'CalOptions', 'FileOptions', 'LFMetadata' );
