% LFReadHotPixels - Read HotPixel binary file storing the indices of the hotpixels in the lenslet image.
%
% Usage: 
%     HotPixelsXY = LFReadHotPixels( HotPixelsFname )
%
% Input :
%     HotPixelsFname : Name of the hotpixel binary file.
%
% Outputs : 
% 
%     HotPixelsXY : Array containing the horizontal and vertical indices of
%     the hotpixels. HotPixelsXY(:,1) contains horizontal indices and
%     HotPixelsXY(:,2) contains the vertical indices.
%

function [HotPixelsXY] = LFReadHotPixels(HotPixelsFname)
    fid=fopen(HotPixelsFname,'r','l');
    numHotPixels = fread(fid,1,'uint32');
    HotPixelsXY = 1+fread(fid,[numHotPixels,2],'uint16');
    fclose(fid);
end