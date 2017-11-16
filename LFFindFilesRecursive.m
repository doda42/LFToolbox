% LFFindFilesRecursive - Recursively searches a folder for files matching one or more patterns
% 
% Usage: 
% 
%   [AllFiles, BasePath, FolderList, PerFolderFiles] = LFFindFilesRecursive( InputPath )
% 
% Inputs:
% 
%   InputPath: the folder to recursively search
% 
% Outputs:
% 
%         Allfiles : A list of all files found
%         BasePath : Top of the searched tree, excluding wildcards
%       FolderList : A list of all the folders explored
%   PerFolderFiles : A list of files organied by folder -- e.g. PerFolderFiles{1} are all the files
%                    found in FolderList{1}
% 
% Examples:
% 
%   LFFindFilesRecursive('Images')
%   LFFindFilesRecursive({'*.lfr','*.lfp'})
%   LFFindFilesRecursive({'Images','*.lfr','*.lfp'})
%   LFFindFilesRecursive('Images/*.lfr')
%   LFFindFilesRecursive('*.lfr')
%   LFFindFilesRecursive('Images/IMG_0001.LFR')
%   LFFindFilesRecursive('IMG_0001.LFR')
% 

% Part of LF Toolbox v0.4 released 12-Feb-2015
% Copyright (c) 2013-2015 Donald G. Dansereau

function [AllFiles, BasePath, FolderList, PerFolderFiles] = LFFindFilesRecursive( InputPath, DefaultFileSpec, DefaultPath )

PerFolderFiles = [];
AllFiles = [];

%---Defaults---
DefaultFileSpec = LFDefaultVal( 'DefaultFileSpec', {'*'} );
DefaultPath = LFDefaultVal( 'DefaultPath', '.' );
InputPath = LFDefaultVal( 'InputPath', '.' );

PathOnly = '';
if( ~iscell(InputPath) )
    InputPath = {InputPath};
end
if( ~iscell(DefaultFileSpec) )
    DefaultFileSpec = {DefaultFileSpec};
end
InputFileSpec = DefaultFileSpec;

if( exist(InputPath{1}, 'dir') )  % try interpreting first param as a folder, if it exists, grab is as such
    PathOnly = InputPath{1};
    InputPath(1) = [];
end
if( numel(InputPath) > 0 ) % interpret remaining elements as filespecs
    % Check if the filespec includes a folder name, and crack it out as part of the input path
    [MorePath, Stripped, Ext] = fileparts(InputPath{1});
    PathOnly = fullfile(PathOnly, MorePath);
    InputPath{1} = [Stripped,Ext];
    InputFileSpec = InputPath;
end
PathOnly = LFDefaultVal('PathOnly', DefaultPath);
InputPath = PathOnly;

% Clean up the inputpath to omit trailing slashes
while( InputPath(end) == filesep )
    InputPath = InputPath(1:end-1);
end
BasePath = InputPath;

%---Crawl folder structure locating raw lenslet images---
fprintf('Searching for files [ ');
fprintf('%s ', InputFileSpec{:});
fprintf('] in %s\n', InputPath);

%---
FolderList = genpath(InputPath);
if( isempty(FolderList) )
    error(['Input path not found... are you running from the correct folder? ' ...
        'Current folder: %s'], pwd);
end
FolderList = textscan(FolderList, '%s', 'Delimiter', pathsep);
FolderList = FolderList{1};

%---Compile a list of all files---
PerFolderFiles = cell(length(FolderList),1);
for( iFileSpec=1:length(InputFileSpec) )
    FilePattern = InputFileSpec{iFileSpec};
    for( iFolder = 1:length(FolderList) )
        
        %---Search each subfolder for raw lenslet files---
        CurFolder = FolderList{iFolder};
        CurDirList = dir(fullfile(CurFolder, FilePattern));
        
        CurDirList = CurDirList(~[CurDirList.isdir]);
        CurDirList = {CurDirList.name};
        PerFolderFiles{iFolder} = [PerFolderFiles{iFolder}, CurDirList];
        
        % Prepend the current folder name for a complete path to each file
        % but fist strip off the leading InputPath so that all files are expressed relative to InputPath
        CurFolder = CurFolder(length(InputPath)+1:end);
        while( ~isempty(CurFolder) && CurFolder(1) == filesep )
            CurFolder = CurFolder(2:end);
        end
        
        CurDirList = cellfun(@(Fname) fullfile(CurFolder, Fname), CurDirList, 'UniformOutput',false);
        
        AllFiles = [AllFiles; CurDirList'];
        
    end
end
