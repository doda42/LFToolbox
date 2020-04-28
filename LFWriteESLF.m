% LFWriteESLF.m - Write ESLF-encoded light fields
% 
% Usage: 
%   LFWriteESLF( LF, FName )
%   [ImgOut] = LFWriteESLF( LF, FName, [WriteAlpha], [<imwrite options>]  )
%
% This function writes ESLF files commonly used to store light fields, e.g. those at
% lightfields.stanford.edu.
% 
% Inputs:
%   FName: path to output file
% 
% Optional Inputs:
%   WriteAlpha: default false; write the light field weight channel as an alpha channel in the ESLF
%               file; use in conjunction with png or other file formats with alpha channels
% 
%  <imwrite options>: additional options are passed to imwrite; useful examples: 'Quality' for jpegs
% 
% Optional Outputs:
%   ImgOut: a 2D image matching what was written to the ESLF file.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFReadESLF, LFReadGantryArray, LFUtilDecodeLytroFolder

% Copyright (c) 2013-2020 Donald G. Dansereau

function ImgOut = LFWriteESLF( LF, FName, WriteAlpha, varargin )

WriteAlpha = LFDefaultVal('WriteAlpha', false);

LF = LFDispTiles( LF, 'uvst' );
LFSize = size(LF);

HasWeight = (ndims(LF)>2 && (LFSize(end)==2 || LFSize(end)==4));
assert( ~WriteAlpha || HasWeight, 'WriteAlpha requested but no weight channel present' );
if( HasWeight )
	% weight channel present, strip it off
	LFw = LF(:,:,end);
	LF = LF(:,:,1:end-1);
end

if( WriteAlpha )
	imwrite( LF, FName, 'Alpha', LFw, varargin{:} );
else
	imwrite( LF, FName, varargin{:} );
end

if( nargout >= 1 )
	ImgOut = LF;
end

