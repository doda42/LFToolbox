% LFReadESLF.m - Read ESLF-encoded light fields
% 
% Usage: 
%   LF = LFReadESLF( FName )
%   [LF, Metadata] = LFReadESLF( FName, [LensletSize_pix], [LoadAlpha], [<imread options>] )
%
% This function reads the ESLF files commonly used to store light fields. If an accompanying .json
% file is present, the metadata is also read from that file. json files must be named <FName>.json,
% including all extensions, e.g. "MyImage.eslf.png.json", following the same convention as the
% decode process.
% 
% Inputs:
%   FName: path to input file
% 
% Optional Inputs:
%   LensletSize_pix: number of pixels per lenslet, default 14 unless the field DecodeOptions.LFSize
%   is present in an accompanying metadata file, in which case the light field size recorded in that file gets used as the default.
%  
%   LoadAlpha: default true; if true, aattempts to load an alpha channel from the ESLF and use as
%             a weight channel for the LF; useful for indicating empty subaperture images; use in
%             conjunction with png or other formats with alpha channels
% 
%  <imread options>: additional options are passed to imread; useful examples: 'BackgroundColor'
% 
% Outputs:
%   LF: a 4D light field with index order [t,s,v,u,c], where s,t are horizontal and vertical
%   subaperture index; u,v are horizontal and vertical pixel index; and c is colour channel.
% 
%   Metadata: contents of the accompanying .json file, if present.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFWriteESLF, LFReadGantryArray, LFUtilDecodeLytroFolder

% Copyright (c) 2013-2020 Donald G. Dansereau

function [LF, Metadata] = LFReadESLF( FName, LensletSize_pix, LoadAlpha, varargin )

Metadata = [];

LensletSize_default = [14,14];
LoadAlpha = LFDefaultVal('LoadAlpha', true);
NChans = 3;

% Check if an accompanying metadata .json file exists, and load it
MetadataFname = [FName, '.json'];
if( exist( MetadataFname, 'file' ) == 2 )  % exist returns 2 if a matching file is found
	Metadata = LFReadMetadata( MetadataFname );
	if( isfield( Metadata, 'DecodeOptions' ) && isfield( Metadata.DecodeOptions, 'LFSize' ) )
		LensletSize_default = Metadata.DecodeOptions.LFSize(1:2);
	end
end
LensletSize_pix = LFDefaultVal('LensletSize_pix', LensletSize_default);

%---
if( LoadAlpha )
	[Img,ColorMap, Alpha] = imread( FName, varargin{:} ); % note: requesting Alpha sets bg to black
	if( ~isempty(Alpha) )
		Img(:,:,NChans+1) = Alpha;
		NChans = NChans + 1;
	end
else
	[Img,ColorMap] = imread( FName, varargin{:} );
end

if( ~isempty(ColorMap) )  % indexed colour image
	Img = ind2rgb(Img, ColorMap); % todo[optimization] may wish to convert to uint8
end

ImgSize = size(Img(:,:,1));

LFSize(3:4) = ceil(ImgSize./LensletSize_pix);
PadSize = LFSize(3:4) .* LensletSize_pix;
PadAmt = PadSize-ImgSize;

LFSize(1:2) = PadSize ./ LFSize(3:4);
LFSize(5) = NChans;

ImgPad = padarray(Img, PadAmt, 0,'post');

LF = reshape(ImgPad, LFSize([1,3,2,4,5]));
LF = permute(LF, [1,3,2,4,5]);
