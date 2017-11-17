% LFDispMousePan - visualize a 4D light field using the mouse to pan through two dimensions
% 
% Usage: 
%     FigureHandle = LFDispMousePan( LF )
%     FigureHandle = LFDispMousePan( LF, ScaleFactor )
% 
% A figure is set up for high-performance display, with the tag 'LFDisplay'. Subsequent calls to
% this function and LFDispVidCirc will reuse the same figure, rather than creating a new window on
% each call.  The window should be closed when changing ScaleFactor.
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
% Outputs:
% 
%     FigureHandle
%
%
% See also: LFDisp, LFDispVidCirc

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (c) 2013-2015 Donald G. Dansereau

function FigureHandle = LFDispMousePan( LF, ScaleFactor, InitialViewIdx )

%todo: document InitialViewIdx and change to default mouse rate, probably make param
LFSize = size(LF);

%---Check for a light field with only one spatial dim---
if( ndims(LF) == 3 || (ndims(LF)==4 && (size(LF,4)==3 || size(LF,4)==4)) )
	LF = reshape(LF, [1, size(LF)]);
end
LFSize = size(LF);

%---Defaults---
ScaleFactor = LFDefaultVal('ScaleFactor', 1);
InitialViewIdx = LFDefaultVal('InitialViewIdx', max(1,floor((LFSize(1:2)-1)/2+1)));
MouseRateDivider = 30./(LFSize(1:2)/9);

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
[ImageHandle,FigureHandle] = LFDispSetup( squeeze(LF(max(1,floor(end/2)),max(1,floor(end/2)),:,:,:)), ScaleFactor );

BDH = @(varargin) ButtonDownCallback(FigureHandle, varargin);
BUH = @(varargin) ButtonUpCallback(FigureHandle, varargin);
set(FigureHandle, 'WindowButtonDownFcn', BDH );
set(FigureHandle, 'WindowButtonUpFcn', BUH );

CurX = InitialViewIdx(2);
CurY = InitialViewIdx(1);
DragStart = 0;

%---Update frame before first mouse drag---
LFRender = squeeze(LF(round(CurY), round(CurX), :,:,:));
set(ImageHandle,'cdata', LFRender);

fprintf('Click and drag to shift perspective\n');

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
   
    LFRender = squeeze(LF(round(CurY), round(CurX), :,:,:));
    set(ImageHandle,'cdata', LFRender);
end

end