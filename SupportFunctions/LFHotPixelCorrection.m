%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% original code from KAIST toolbox written by Donghyeon Cho.
%
% modified by Mikael Le Pendu
%  - adapted inputs/outputs for the LFtoolbox pipeline.
%
% Name   : hotPixelCorrection  
% Input  : img           - input image
%          HotPixelsX    - list of column indices of hot pixels.
%          HotPixelsY    - list of row indices of hot pixels.
%
% Output : result        - corrected image
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = LFHotPixelCorrection(img, HotPixelsX, HotPixelsY)
    
    RawSize = size(img);
    
    processed = HotPixelsX>1 & HotPixelsY>1 & HotPixelsX<RawSize(2) & HotPixelsY<RawSize(1);
    HotPixelsX = HotPixelsX(processed);
    HotPixelsY = HotPixelsY(processed);
    
    index = sub2ind(RawSize, HotPixelsY, HotPixelsX);
    img(index) = 0;
    
    sum = 0;
    for col=-1:1:1
        for row=-1:1:1
            w = exp(-sqrt(col^2+row^2));
            sum = sum + w;
            ind = sub2ind(RawSize,HotPixelsY+row,HotPixelsX+col);
            img(index) = img(index) + img(ind).*w;
        end
    end
    
    img(index) = img(index)./sum;
    result = img;
    
end

% todo[refactor]
% todo[feature] : alternate (4D) patching methods; zeroing weight channel
