% todo: doc

function LFXWriteGifAnim( LF, FName, PathRadius_percent, NFrames, DelayTime, ResizeRatio )

%---Defaults---
PathRadius_percent = LFDefaultVal( 'PathRadius_percent', 60 );
NFrames = LFDefaultVal( 'NFrames', 24 );
DelayTime = LFDefaultVal( 'DelayTime', 1/24 );
ResizeRatio = LFDefaultVal( 'ResizeRatio', 1 );

%---Check for mono and clip off the weight channel if present---
Mono = (ndims(LF) == 4);
if( ~Mono )
    LF = LF(:,:,:,:,1:3);
end

%---Rescale for 8-bit display---
if( isfloat(LF) )
    LF = uint8(LF ./ max(LF(:)) .* 255);
else
    LF = uint8(LF.*(255 / double(intmax(class(LF)))));
end

%---Setup the motion path---
[TSize,SSize, ~,~] = size(LF(:,:,:,:,1));
TCent = (TSize-1)/2 + 1;
SCent = (SSize-1)/2 + 1;

RotRad = TCent*PathRadius_percent/100;

map = 256;
WriteMode = 'overwrite';

FirstPass = true;
for( t = 1:NFrames )
    TVal = TCent + RotRad * cos( 2*pi*t/NFrames );
    SVal = SCent + RotRad * sin( 2*pi*t/NFrames );
    
    SIdx = round(SVal);
    TIdx = round(TVal);
    
    CurFrame =  squeeze(LF( TIdx, SIdx, :,:,: ));
	
	CurFrame = imresize(CurFrame,ResizeRatio); 
    
    [im,map] = rgb2ind(CurFrame, 256, 'nodither');
    if( FirstPass )
        imwrite(im,map,FName,'gif', 'Loopcount',inf, 'DelayTime',DelayTime, 'WriteMode',WriteMode);
        WriteMode = 'append';
        FirstPass = false;
    else
        imwrite(im,map,FName,'gif', 'DelayTime',DelayTime, 'WriteMode',WriteMode);
    end
    
    fprintf('.')
end
fprintf(' Done\n');