% LFFindLytroPartnerFile - Finds metadata / raw data file partner for Lytro white images
% 
% Usage: 
% 
%   PartnerFilename = LFFindLytroPartnerFile( OrigFilename, PartnerFilenameExtension )
% 
% The LF Reader tool prepends filenames extracted from LFP storage files, complicating .txt / .raw
% file association as the prefix can vary between two files in a pair. This function finds a file's
% partner based on a known filename pattern (using underscores to separate the base filename), and a
% know partner filename extension. Note this is set up to work specifically with the naming
% conventions used by the LFP Reader tool.
% 
% Inputs:
%   OrigFilename is the known filename
%   PartnerFilenameExtension is the extension of the file to find
%
% Output:
%   PartnerFilename is the name of the first file found matching the specified extension
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFUtilProcessWhiteImages, LFUtilProcessCalibrations

% Copyright (c) 2013-2020 Donald G. Dansereau

function PartnerFilename = LFFindLytroPartnerFile( OrigFilename, PartnerFilenameExtension )

[CurFnamePath, CurFnameBase] = fileparts( OrigFilename );
PrependIdx = find(CurFnameBase == '_', 1);
CurFnamePattern = strcat('*', CurFnameBase(PrependIdx:end), PartnerFilenameExtension);
DirResult = dir(fullfile(CurFnamePath, CurFnamePattern));
DirResult = DirResult(1).name;
PartnerFilename = fullfile(CurFnamePath, DirResult);

end
