% LFUtilUnpackLytroArchive - extract white images and other files from a multi-volume Lytro archive
%
% Usage:
%     LFUtilUnpackLytroArchive
%     LFUtilUnpackLytroArchive( InputPath )
%     LFUtilUnpackLytroArchive( InputPath, FirstVolumeFname )
%     LFUtilUnpackLytroArchive( [], FirstVolumeFname )
% 
% This extracts all the files from all Lytro archives found in the requested path. Archives typically take on names like
% data.C.0, data.C.1 and so forth, and contain white images, metadata and other information.
% 
% The function searches for archives recursively, so if there are archives in multiple sub-folders, they will all be
% expanded. The file LFToolbox.json is created to mark completion of the extraction in a folder.  Already-expanded
% archives are skipped; delete LFToolbox.json to force re-extraction in a folder.
% 
% Based in part on Nirav Patel and Doug Kelley's LFP readers. Thanks to Michael Tao for help and samples for decoding
% Illum imagery.
% 
% Inputs -- all are optional :
%
%            InputPath : Path to folder containing the archive, default 'Cameras'
%     FirstVolumeFname : Name of the first file in the archive, default 'data.C.0'
%
% Example:
%
%   LFUtilUnpackLytroArchive
% 
%     Will extract the contents of all archives in all subfolders of the current folder. If you are working with
%     multiple cameras, place each multi-volume archve in its own sub-folder, then call this from the top-level folder
%     to expand them all.
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFUtilProcessWhiteImages, LFReadLFP, LFUtilExtractLFPThumbs

% Copyright (c) 2013-2020 Donald G. Dansereau

function LFUtilUnpackLytroArchive( InputPath, FirstVolumeFname )

%---Defaults---
InputPath = LFDefaultVal('InputPath','Cameras');
FirstVolumeFname = LFDefaultVal('FirstVolumeFname','data.C.0');


[AllVolumes, BasePath] = LFFindFilesRecursive(InputPath, FirstVolumeFname);
fprintf('Found :\n');
disp(AllVolumes)

%---Consts---
LFPConsts.LFPHeader = hex2dec({'89', '4C', '46', '50', '0D', '0A', '1A', '0A', '00', '00', '00', '01'}); % 12-byte LFPSections header
LFPConsts.SectHeaderLFM = hex2dec({'89', '4C', '46', '4D', '0D', '0A', '1A', '0A'})'; % header for table of contents
LFPConsts.SectHeaderLFC = hex2dec({'89', '4C', '46', '43', '0D', '0A', '1A', '0A'})'; % header for content section
LFPConsts.SecHeaderPaddingLen = 4;
LFPConsts.Sha1Length = 45;
LFPConsts.ShaPaddingLen = 35; % Sha1 codes are followed by 35 null bytes
LFToolboxInfoFname = 'LFToolbox.json';

%---
for( VolumeIdx = 1:length(AllVolumes) )
    
    CurFile = fullfile(BasePath, AllVolumes{VolumeIdx});
    OutPath = fileparts(CurFile);
    
    fprintf('Extracting files in "%s"...\n', OutPath);
    CurInfoFname = fullfile( OutPath, LFToolboxInfoFname );
    if( exist(CurInfoFname, 'file') )
        fprintf('Already done, skipping (delete "%s" to force redo)\n\n', CurInfoFname);
        continue;
    end
    
    while( 1 )
        fprintf('    %s...\n', CurFile);
        InFile=fopen(CurFile, 'rb');
        
        %---Check for the magic header---
        HeaderBytes = fread( InFile, length(LFPConsts.LFPHeader), 'uchar' );
        if( ~all( HeaderBytes == LFPConsts.LFPHeader ) )
            fclose(InFile);
            fprintf( 'Unrecognized file type' );
            return
        end
        
        %---Confirm headerlength bytes---
        HeaderLength = fread(InFile,1,'uint32','ieee-be');
        assert( HeaderLength == 0, 'Unexpected length at top-level header' );
        
        %---Read each section---
        % This implementation assumes the TOC appears first in each file
        clear TOC
        while( ~feof(InFile) )
            CurSection = ReadSection( InFile, LFPConsts );
            
            if( all( CurSection.SectHeader == LFPConsts.SectHeaderLFM ) )
                TOC = LFReadMetadata( CurSection.Data );
            else
                assert( exist('TOC','var')==1, 'Expected to find table of contents at top of file' );
                assert( all( CurSection.SectHeader == LFPConsts.SectHeaderLFC ), 'Expected LFC section, header error' );
                MatchingSectIdx = find( strcmp( CurSection.Sha1, {TOC.files.dataRef} ) );
                CurFname = TOC.files(MatchingSectIdx).name;
                CurFname = strrep( CurFname, 'C:\', '' );
                CurFname = strrep( CurFname, '\', '__' );
                OutFile = fopen( fullfile(OutPath, CurFname), 'wb' );
                fwrite( OutFile, uint8(CurSection.Data), 'uint8' );
                fclose(OutFile);
            end
        end
        fclose( InFile );
        
        if( isfield(TOC, 'nextFile') )
            CurFile = fullfile(OutPath, TOC.nextFile);
        else
            break;
        end
    end
    
    TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
    GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);
    fprintf( 'Marking completion in "%s"\n\n', CurInfoFname );
    LFWriteMetadata( CurInfoFname, GeneratedByInfo );
end
fprintf('Done\n');

end

% --------------------------------------------------------------------
function LFPSect = ReadSection( InFile, LFPConsts )
LFPSect.SectHeader = fread(InFile, length(LFPConsts.SectHeaderLFM), 'uchar')';
Padding = fread(InFile, LFPConsts.SecHeaderPaddingLen, 'uint8'); % skip padding

SectLength = fread(InFile, 1, 'uint32', 'ieee-be');
LFPSect.Sha1 = char(fread(InFile, LFPConsts.Sha1Length, 'uchar')');
Padding = fread(InFile, LFPConsts.ShaPaddingLen, 'uint8'); % skip padding

LFPSect.Data = char(fread(InFile, SectLength, 'uchar'))';

while( 1 ) 
    Padding = fread(InFile, 1, 'uchar');
    if( feof(InFile) || (Padding ~= 0) )
        break;
    end
end
if ~feof(InFile)
    fseek( InFile, -1, 'cof' ); % rewind one byte
end

end

