% LFReadRaw - Reads 8, 10, 12 and 16-bit raw image files
%
% Usage:
% 
%     Img = LFReadRaw( Fname )
%     Img = LFReadRaw( Fname, BitPacking, ImgSize )
%     Img = LFReadRaw( Fname, [], ImgSize )
% 
% There is no universal `RAW' file format. This function reads a few variants, including the 12-bit and 10-bit files
% commonly employed in Lytro cameras, and the 16-bit files produced by some third-party LFP extraction tools. The output
% is always an array of type uint16, except for 8-bit files which produce an 8-bit output.
% 
% Raw images may be converted to more portable formats, including .png, using an external tool such as the
% cross-platform ImageMagick tool.
%
% Inputs :
% 
%     Fname : path to raw file to read
%
%     [optional] BitPacking : one of '12bit', '10bit', '8bit' or '16bit'; default is '12bit'
% 
%     [optional] ImgSize : a 2-element vector defining the size of the image, in pixels. The default value varies according to
%     the value of 'BitPacking', to correspond to commonly-found Lytro file formats: 12 bit images are employed by the
%     Lytro F01, producing images of size 3280x3280, while 10-bit images are produced by the Illum at a resolution of
%     7728x5368; 16-bit images default to 3280x3280.
%
% Outputs:
% 
%     Img : an array of uint16 gray levels. No demosaicing (decoding Bayer pattern) is performed.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFReadLFP, LFDecodeLensletImageDirect, demosaic

% Copyright (c) 2013-2020 Donald G. Dansereau

function Img = LFReadRaw( Fname, BitPacking, ImgSize )

%---Defaults---
BitPacking = LFDefaultVal( 'BitPacking', '12bit' );

switch( BitPacking )
    case '8bit'
        ImgSize = LFDefaultVal( 'ImgSize', [3280,3280] );
        BuffSize = prod(ImgSize);
    
    case '12bit'
        ImgSize = LFDefaultVal( 'ImgSize', [3280,3280] );
        BuffSize = prod(ImgSize) * 12/8;

    case '10bit'
        ImgSize = LFDefaultVal( 'ImgSize', [7728, 5368] );
        BuffSize = prod(ImgSize) * 10/8;
        
    case '16bit'
        ImgSize = LFDefaultVal( 'ImgSize', [3280,3280] );
        BuffSize = prod(ImgSize) * 16/8;

    otherwise
        error('Unrecognized bit packing format');
end

%---Read and unpack---
f = fopen( Fname );
Img = fread( f, BuffSize, 'uchar' );
Img = LFUnpackRawBuffer( Img, BitPacking, ImgSize )'; % note the ' is necessary to get the rotation right
fclose( f );
