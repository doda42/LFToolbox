function CalOptions = LFModCalCollectFeatures( InputPath, CalOptions )

CalOptions = LFDefaultField( 'CalOptions', 'FeatFnamePattern', '%s__Feats.mat' );
CalOptions = LFDefaultField( 'CalOptions', 'AllFeatsFname', 'AllFeats.mat' );

%---Crawl folder structure locating feature observation info files---
fprintf('\n===Locating feature observation files in %s===\n', InputPath);
[CalOptions.FileList, BasePath] = LFFindFilesRecursive( InputPath, sprintf(CalOptions.FeatFnamePattern, '*') );
fprintf('Found :\n');
disp(CalOptions.FileList)

%---Load each feature observation file---
ValidSuperPoseCount = 0;

fprintf('Loading feature observations...\n');
for( iFile = 1:length(CalOptions.FileList) )
    ValidSuperPoseCount = ValidSuperPoseCount + 1;
    CurFname = CalOptions.FileList{iFile};
    [~,ShortFname] = fileparts(CurFname);
    fprintf('---%s [%3d / %3d]...', ShortFname, ValidSuperPoseCount, length(CalOptions.FileList));
    
    load(fullfile(BasePath, CurFname), 'FeatObs', 'LFSize');
    PerImageValidCount = 0;
    for( TIdx = 1:size(FeatObs,1) )
        for( SIdx = 1:size(FeatObs,2) )
            CurFeat = FeatObs{TIdx, SIdx};
            if( ~isempty(CurFeat) )
                PerImageValidCount = PerImageValidCount + 1;
                AllFeatObs{ValidSuperPoseCount, TIdx, SIdx} = CurFeat;
            end
        end
    end
    CalOptions.ValidSubimageCount(iFile) = PerImageValidCount;
    fprintf(' %d / %d valid.\n', PerImageValidCount, prod(LFSize(1:2)));
end


TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

SaveFname = fullfile(InputPath, CalOptions.AllFeatsFname);
fprintf('\nSaving to %s...\n', SaveFname);
save(SaveFname, 'GeneratedByInfo', 'AllFeatObs', 'LFSize', 'CalOptions' );
