% LFWriteESLF.m - Write ESLF-encoded light fields
%
% Usage:
%   LFWriteESLF( LF, FName )
%   [ImgOut] = LFWriteESLF( LF, FName, [WriteAlpha], [<imwrite options>]  )
%
% This function writes ESLF files commonly used to store light fields. File saving is carried out by
% imwrite, see imwrite for details. By convention the toolbox names these files .eslf.png,
% .eslf.jpg, etc, and imwrite interprets the final extension to determine file format.
%
% Saving the weight channel is only supported for file formats with an alpha channel, e.g.
% png files.
%
% Saving 16-bit data is not supported by all formats; .png will save 16-bit colour data, and .jpg
% will save 16-bit monochrome images if provided with an input LF in uint16 format (see
% LFConvertToInt).
%
% The function automatically strips weight channel and reduces colour bit depth when saving as .jpg.
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
% Examples:
%
% LF = LFConvertToInt(LF,'uint16');
% WriteAlpha = true;
% LFWriteESLF(LF, 'MyFile.eslf.png', WriteAlpha); % saves as 16-bit png with weight channel
% LFWriteESLF(LF, 'MyFile.eslf.png'); % saves as 16-bit png without weight channel
% LFWriteESLF(LF, 'MyFile.eslf.jpg'); % saves as jpg, no weight channel, reduces to 8-bit
% LFWriteESLF(LF, 'MyFile.eslf.jpg', [], 'quality',99); % sets jpeg compression quality
% LF = LFConvertToInt(LF,'uint8');
% LFWriteESLF(LF, 'MyFile.eslf.png'); % saves as 8-bit png without weight channel
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFReadESLF, LFReadGantryArray, LFUtilDecodeLytroFolder

% Copyright (c) 2013-2020 Donald G. Dansereau

function ImgOut = LFWriteESLF( LF, FName, WriteAlpha, varargin )

WriteAlpha = LFDefaultVal('WriteAlpha', false);
ImriteOptions = varargin;

%---
LF = LFDispTiles( LF, 'uvst' );
LFSize = size(LF);

%---Automate some of the bit-depth and alpha channel details---
HasWeight = (ndims(LF)>2 && (LFSize(end)==2 || LFSize(end)==4));
HasColor = (ndims(LF)>2 && (LFSize(end)==3 || LFSize(end)==4) );
IsJpeg = strcmp(FName(end-3:end), '.jpg') || strcmp(FName(end-4:end), '.jpeg');
IsUint16 = strcmp(class(LF), 'uint16');

assert( ~WriteAlpha || HasWeight, 'WriteAlpha requested but no weight channel present' );

if( IsJpeg && WriteAlpha )
	fprintf('Jpeg doesn''t support writing weight channel, setting WriteAlpha=false\n');
	WriteAlpha = false;
end

if( IsJpeg && IsUint16 )
	if( HasColor )
		fprintf('Jpeg doesn''t support writing 16-bit colour images, reducing to uint8\n');
		LF = LFConvertToInt(LF, 'uint8');
	else
		fprintf('Saving to monochrome uint16 Jpeg\n');
		ImriteOptions = cat(2, ImriteOptions, {'bitdepth', 16});
	end
end

%---
if( HasWeight )
	% weight channel present, strip it off
	LFw = LF(:,:,end);
	LF = LF(:,:,1:end-1);
end

if( WriteAlpha )
	imwrite( LF, FName, 'Alpha', LFw, ImriteOptions{:} );
else
	imwrite( LF, FName, ImriteOptions{:} );
end

if( nargout >= 1 )
	ImgOut = LF;
end

