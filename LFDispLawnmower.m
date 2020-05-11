% LFDispLawnmower - visualize a 4D light field animating a lawnmower path through two dimensions
%
% Usage:
%     FigureHandle = LFDispLawnmower( LF )
%     FigureHandle = LFDispLawnmower( LF, [RenderOptions], [ScaleFactor] )
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
%     RenderOptions
%        .FrameDelay         : delay between frames, in seconds. Default 1/30.
%        .NumCycles          : how many times the path should repeat. Default inf.
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
% See also: LFDisp, LFDispMousePan, LFDispVidCirc, LFDispProj, LFDispTiles

% Copyright (c) 2013-2020 Donald G. Dansereau

% todo: smooth transition from vertical to horizontal
% todo: optional horz/vert only

function FigureHandle = LFDispLawnmower( LF, RenderOptions, ScaleFactor )

%---Defaults---
ScaleFactor = LFDefaultVal('ScaleFactor', 1);
RenderOptions = LFDefaultField( 'RenderOptions', 'FrameDelay', 1/30 );
RenderOptions = LFDefaultField( 'RenderOptions', 'NumCycles', inf );

%---Check for a light field with only one spatial dim---
if( ndims(LF) == 3 || (ndims(LF)==4 && (size(LF,4)==3 || size(LF,4)==4)) )
	LF = reshape(LF, [1, size(LF)]);
end
LFSize = size(LF);

%---Check for mono and clip off the weight channel if present---
HasWeight = (ndims(LF)>2 && (LFSize(end)==2 || LFSize(end)==4));
if( HasWeight )
	LF = LF(:,:,:,:,1:end-1);
end

%---Rescale for 8-bit display---
if( isfloat(LF) )
	LF = uint8(LF ./ max(LF(:)) .* 255);
else
	LF = uint8(LF.*(255 / double(intmax(class(LF)))));
end

%---Setup the motion path---
[TSize,SSize, ~,~] = size(LF(:,:,:,:,1));
[tt,ss] = ndgrid(1:TSize, 1:SSize);

%---Setup the display---
TIdx = 1;
SIdx = 1;
[ImageHandle,FigureHandle] = LFDispSetup( squeeze(LF(TIdx,SIdx,:,:,:)), ScaleFactor );

while( 1 )
	CurRep = 0;
	
	% left/right
	TVec = tt;
	SVec = ss;
	SVec(2:2:end,:) = SVec(2:2:end,end:-1:1);
	SVec = SVec';
	TVec = TVec';
	
	for( PoseIdx = 1:numel(tt) )
		
		TIdx = TVec(PoseIdx);
		SIdx = SVec(PoseIdx);
		
		CurFrame =  squeeze(LF( TIdx, SIdx, :,:,: ));
		set(ImageHandle,'cdata', CurFrame );
		
		pause(RenderOptions.FrameDelay)
		
	end
	
	% Up/down
	TVec = tt;
	TVec(:,2:2:end) = TVec(end:-1:1, 2:2:end);
	SVec = ss;
	
	for( PoseIdx = 1:numel(tt) )
		
		TIdx = TVec(PoseIdx);
		SIdx = SVec(PoseIdx);
		
		CurFrame =  squeeze(LF( TIdx, SIdx, :,:,: ));
		set(ImageHandle,'cdata', CurFrame );
		
		pause(RenderOptions.FrameDelay)
		
	end
	CurRep = CurRep + 1;
	
	if( CurRep >= RenderOptions.NumCycles )
		break;
	end
end
