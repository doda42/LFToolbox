% Reads the light fields at lightfields.stanford.edu
% Experimental
% Please report issues to the Light Field Toolbox Google+ Community at 
% https://plus.google.com/communities/114934462920613225440

% Copyright (c) 2016 Donald G. Dansereau

function [LF, Alpha] = LFXReadStanfordIllum( FName, LensletSize, HasAlpha )

LensletSize = LFDefaultVal('LensletSize',[14,14]);
HasAlpha = LFDefaultVal('HasAlpha',false);
NChans = 3;

if( HasAlpha )
	[Img,ColorMap, Alpha] = imread( FName ); % note: requesting Alpha sets bg to black
else
	[Img,ColorMap] = imread( FName );
end

if( ~isempty(ColorMap) )  % indexed colour image
	Img = ind2rgb(Img, ColorMap); % todo[optimization] may wish to convert to uint8
end

ImgSize = size(Img(:,:,1));

LFSize(3:4) = ceil(ImgSize./LensletSize);
PadSize = LFSize(3:4) .* LensletSize;
PadAmt = PadSize-ImgSize;

LFSize(1:2) = PadSize ./ LFSize(3:4);
LFSize(5) = NChans;

ImgPad = padarray(Img, PadAmt, 0,'post');

LF = reshape(ImgPad, LFSize([1,3,2,4,5]));
LF = permute(LF, [1,3,2,4,5]);
