% LFDispMousePan - visualize a 4D light field using the mouse to pan through two dimensions
%
% Usage:
%     FigureHandle = LFDispMousePan( LF )
%     FigureHandle = LFDispMousePan( LF, ScaleFactor, InitialViewIdx, Verbose )
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
%     ScaleFactor : Adjusts the size of the display -- 1 means no change, 2 means twice as big, etc.
%                   Integer values are recommended to avoid scaling artifacts. Note that the scale
%                   factor is only applied the first time a figure is created. To change the scale
%                   factor, close the figure before calling LFDispMousePan.
%
%     InitialViewIdx : [s,t] index of first view to display
%
%     Verbose : if true, the s,t index of the currently displayed frame is displayed to the matlab
%               command terminal
%
% Outputs:
%
%     FigureHandle
%
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDisp, LFDispVidCirc, LFDispLawnmower, LFDispProj, LFDispTiles

% Copyright (c) 2013-2020 Donald G. Dansereau

function FigureHandle = LFDispMousePan( LF, ScaleFactor, InitialViewIdx, Verbose )

LFSize = size(LF);

%---Check for a light field with only one spatial dim---
if( ndims(LF) == 3 || (ndims(LF)==4 && (size(LF,4)==3 || size(LF,4)==4)) )
	LF = reshape(LF, [1, size(LF)]);
end
LFSize = size(LF);

%---Defaults---
ScaleFactor = LFDefaultVal('ScaleFactor', 1);
InitialViewIdx = LFDefaultVal('InitialViewIdx', max(1,floor((LFSize(1:2)-1)/2+1)));
Verbose = LFDefaultVal('Verbose', false);

MouseRateDivider = 30./(LFSize(1:2)/9); % todo: should this be a param?

%---Check for weight channel---
HasWeight = (size(LF,5) == 4 || size(LF,5) == 2);

%---Discard weight channel---
if( HasWeight )
	LF = LF(:,:,:,:,1:end-1);
end

%---Rescale for 8-bit display---
if( isfloat(LF) )
	LF = uint8(LF ./ max(LF(:)) .* 255);
else
	LF = uint8(LF.*(255 / double(intmax(class(LF)))));
end

%---Setup the display---
[ImageHandle,FigureHandle] = LFDispSetup( squeeze(LF(InitialViewIdx(1),InitialViewIdx(2),:,:,:)), ScaleFactor );

% Turn off zoom, pan
hZ=zoom(FigureHandle);
hZ.Enable='off';
hP=pan(FigureHandle);
hP.Enable='off';

BDH = @(varargin) ButtonDownCallback(FigureHandle, varargin);
BUH = @(varargin) ButtonUpCallback(FigureHandle, varargin);
set(FigureHandle, 'WindowButtonDownFcn', BDH );
set(FigureHandle, 'WindowButtonUpFcn', BUH );

CurX = InitialViewIdx(2);
CurY = InitialViewIdx(1);
DragStart = 0;
LastIdx = [CurX, CurY];

%---Update frame before first mouse drag---
LFRender = squeeze(LF(round(CurY), round(CurX), :,:,:));
set(ImageHandle,'cdata', LFRender);

%---Nested functions, these have access to variables of parent function---
	function ButtonDownCallback(FigureHandle,varargin)
		set(FigureHandle, 'WindowButtonMotionFcn', @ButtonMotionCallback);
		DragStart = get(gca,'CurrentPoint')';
		DragStart = DragStart(1:2,1)';
	end

	function ButtonUpCallback(FigureHandle, varargin)
		set(FigureHandle, 'WindowButtonMotionFcn', '');
	end

	function ButtonMotionCallback(varargin)
		CurPoint = get(gca,'CurrentPoint');
		CurPoint = CurPoint(1,1:2);
		RelPoint = CurPoint - DragStart;
		CurX = max(1,min(LFSize(2), CurX - RelPoint(1)/MouseRateDivider(2)));
		CurY = max(1,min(LFSize(1), CurY - RelPoint(2)/MouseRateDivider(1)));
		DragStart = CurPoint;
		
		CurIdx = round([CurX, CurY]);
		if( any( CurIdx ~= LastIdx ) )
			LFRender = squeeze(LF(CurIdx(2), CurIdx(1), :,:,:));
			set(ImageHandle,'cdata', LFRender);
			if( Verbose )
				disp( CurIdx )
			end
			LastIdx = CurIdx;
		end
	end

end
