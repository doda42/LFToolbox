% LFDispVidCirc - visualize a 4D light field animating a circular path through two dimensions
% 
% Usage: 
%     FigureHandle = LFDispVidCirc( LF )
%     FigureHandle = LFDispVidCirc( LF, [RenderOptions], [ScaleFactor] )
% 
% 
% Inputs:
% 
%     LF : a colour or single-channel light field, and can a floating point or integer format. For
%          display, it is converted to 8 bits per channel. If LF contains more than three colour
%          channels, as is the case when a weight channel is present, only the first three are used.
% 
% Optional Inputs: 
% 
%     RenderOptions : struct controlling rendering
%        .PathRadius_percent : radius of the circular path taken by the viewpoint. Values that are
%                              too high can result in collision with the edges of the lenslet image,
%                              while values that are too small result in a less impressive
%                              visualization. The default value is 60%.
%        .FrameDelay         : delay between frames, in seconds. Default 1/30.
%        .NumCycles          : how many times the circular path should repeat. Default inf.
%        .FramesPerCycle     : how many frames along a single cycle. Default 20.
% 
%     ScaleFactor : Adjusts the size of the display -- 1 means no change, 2 means twice as
%                   big, etc. Integer values are recommended to avoid scaling artifacts.
% 
% Outputs:
% 
%     FigureHandle
%
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFDisp, LFDispMousePan, LFDispLawnmower, LFDispProj, LFDispTiles

% Copyright (c) 2013-2020 Donald G. Dansereau

function FigureHandle = LFDispVidCirc( LF, RenderOptions, ScaleFactor )

%---Defaults---
ScaleFactor = LFDefaultVal('ScaleFactor', 1);
RenderOptions = LFDefaultField( 'RenderOptions', 'PathRadius_percent', 60 );
RenderOptions = LFDefaultField( 'RenderOptions', 'FrameDelay', 1/30 );
RenderOptions = LFDefaultField( 'RenderOptions', 'NumCycles', inf );
RenderOptions = LFDefaultField( 'RenderOptions', 'FramesPerCycle', 20 );

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

t = 0;
RotRad = TCent*RenderOptions.PathRadius_percent/100;
NumFrames = RenderOptions.NumCycles * RenderOptions.FramesPerCycle;

%---Setup the display---
TIdx = round(TCent + RotRad);
SIdx = round(SCent);
[ImageHandle,FigureHandle] = LFDispSetup( squeeze(LF(TIdx,SIdx,:,:,:)), ScaleFactor );

while(1)
    TVal = TCent + RotRad * cos( 2*pi*t/RenderOptions.FramesPerCycle );
    SVal = SCent + RotRad * sin( 2*pi*t/RenderOptions.FramesPerCycle );
    
    SIdx = round(SVal);
    TIdx = round(TVal);
	
    CurFrame =  squeeze(LF( TIdx, SIdx, :,:,: ));
    set(ImageHandle,'cdata', CurFrame );
    
    pause(RenderOptions.FrameDelay)
    t = t + 1;
	
	if( t > NumFrames )
		break;
	end
end
