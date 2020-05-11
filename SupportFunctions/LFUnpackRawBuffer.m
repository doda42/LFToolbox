% LFUnpackRawBuffer - Unpack a buffer of packed raw binary data into an image
% 
% Usage:
% 
%     ImgOut = LFUnpackRawBuffer( Buff, BitPacking, ImgSize )
% 
% Used by LFReadRaw and LFReadLFP, this helper function unpacks a raw binary data buffer in one of several formats.
%
% Inputs :
% 
%     Buff : Buffer of chars to be unpacked
%     BitPacking : one of '12bit', '10bit' or '16bit'; default is '12bit'
%     ImgSize : size of the output image
% 
% Outputs:
% 
%      Img : an array of uint16 gray levels. No demosaicing (decoding Bayer pattern) is performed.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDecodeLensletImageDirect, demosaic

% Copyright (c) 2013-2020 Donald G. Dansereau

function ImgOut = LFUnpackRawBuffer( Buff, BitPacking, ImgSize )

switch( BitPacking )
    case '8bit'
        ImgOut = reshape(Buff, ImgSize);
    
    case '10bit'
        t0 = uint16(Buff(1:5:end));
        t1 = uint16(Buff(2:5:end));
        t2 = uint16(Buff(3:5:end));
        t3 = uint16(Buff(4:5:end));
        lsb = uint16(Buff(5:5:end));
        
        t0 = bitshift(t0,2);
        t1 = bitshift(t1,2);
        t2 = bitshift(t2,2);
        t3 = bitshift(t3,2);
        
        t0 = t0 + bitand(lsb,bin2dec('00000011'));
        t1 = t1 + bitshift(bitand(lsb,bin2dec('00001100')),-2);
        t2 = t2 + bitshift(bitand(lsb,bin2dec('00110000')),-4);
        t3 = t3 + bitshift(bitand(lsb,bin2dec('11000000')),-6);
        
        ImgOut = zeros(ImgSize, 'uint16');
        ImgOut(1:4:end) = t0;
        ImgOut(2:4:end) = t1;
        ImgOut(3:4:end) = t2;
        ImgOut(4:4:end) = t3;
        
    case '12bit'
        t0 = uint16(Buff(1:3:end));
        t1 = uint16(Buff(2:3:end));
        t2 = uint16(Buff(3:3:end));
        
        a0 = bitshift(t0,4) + bitshift(bitand(t1,bin2dec('11110000')),-4);
        a1 = bitshift(bitand(t1,bin2dec('00001111')),8) + t2;
        
        ImgOut = zeros(ImgSize, 'uint16');
        ImgOut(1:2:end) = a0;
        ImgOut(2:2:end) = a1;
   
    case '16bit'
        t0 = uint16(Buff(1:2:end));
        t1 = uint16(Buff(2:2:end));
        a0 = bitshift(t1, 8) + t0;
        ImgOut = zeros(ImgSize, 'uint16');
        ImgOut(:) = a0;
        
    otherwise
        error('Unrecognized bit packing');
end
