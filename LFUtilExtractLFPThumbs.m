% LFUtilExtractLFPThumbs - extract thumbnails from LFP files and write to disk
%
% Usage:
%
%     LFUtilExtractLFPThumbs
%     LFUtilExtractLFPThumbs( InputPath )
%
% This extracts the thumbnail preview and focal stack images from LFR and LFP files, and is useful in providing a
% preview, e.g. when copying files directly from an Illum camera.
% 
% Inputs -- all are optional :
%
%     InputPath : Path / filename pattern for locating LFP files. The function will move recursively through a tree,
%     matching one or more filename patterns. See LFFindFilesRecursive for a full description.
%
%     The default input path is {'.', '*.LFP','*.LFR','*.lfp','*.lfr'}, i.e. the current folder, recursively searching
%     for all files matching uppercase and lowercase 'LFP' and 'LFR' extensions.
%
% Examples:
%
%   LFUtilExtractLFPThumbs
% 
%     Will extract thumbnails from all LFP and LFR images in the current folder and its subfolders. 
% 
% The following are also valid, see LFFindFilesRecursive for more.
% 
%   LFUtilExtractLFPThumbs('Images')
%   LFUtilExtractLFPThumbs({'*.lfr','*.lfp'})
%   LFUtilExtractLFPThumbs({'Images','*.lfr','*.lfp'})
%   LFUtilExtractLFPThumbs('Images/*.lfr')
%   LFUtilExtractLFPThumbs('*.lfr')
%   LFUtilExtractLFPThumbs('Images/IMG_0001.LFR')
%   LFUtilExtractLFPThumbs('IMG_0001.LFR')
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFFindFilesRecursive

% Copyright (c) 2013-2020 Donald G. Dansereau

function LFUtilExtractLFPThumbs( InputPath )

%---Defaults---
InputPath = LFDefaultVal( 'InputPath','.' );
DefaultFileSpec = {'*.LFP','*.LFR','*.lfp','*.lfr'}; % gets overriden below, if a file spec is provided

[FileList, BasePath] = LFFindFilesRecursive( InputPath, DefaultFileSpec );

fprintf('Found :\n');
disp(FileList)

%---Process each file---
for( iFile = 1:length(FileList) )
    CurFname = fullfile(BasePath, FileList{iFile});
    
    fprintf('Processing [%d / %d] %s\n', iFile, length(FileList), CurFname);
    LFP = LFReadLFP( CurFname );
    
    if( ~isfield(LFP, 'Jpeg') )
        continue;
    end
    if( ~iscell(LFP.Jpeg) )
        LFP.Jpeg = {LFP.Jpeg};
    end
    for( i=1:length(LFP.Jpeg) )
        OutFname = sprintf('%s-%03d.jpg', CurFname, i-1);
        fprintf('%s', OutFname);
        if( exist(OutFname,'file') )
            fprintf(' Exists, skipping\n');
        else
            OutFile = fopen(OutFname, 'wb');
            fwrite(OutFile, LFP.Jpeg{i});
            fclose(OutFile);
            fprintf('\n');
        end
    end
end
    
