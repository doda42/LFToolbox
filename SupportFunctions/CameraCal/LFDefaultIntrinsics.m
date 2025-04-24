% LFDefaultIntrinsics - Initializes a set of intrinsics for use in rectifying light fields
% 
% Usage:
% 
%     RectCamIntrinsicsH = LFDefaultIntrinsics( LFSize, CalInfo )
% 
% This gets called by LFCalDispRectIntrinsics to set up a default set of intrinsics for rectification. Based on the
% calibration information and the dimensions of the light field, a set of intrinsics is selected which yields square
% pixels in ST and UV. Ideally the values will use the hypercube-shaped light field space efficiently, leaving few black
% pixels at the edges, and bumping as little information /outside/ the hypercube as possible.
% 
% The sampling pattern yielded by the resulting intrinsics can be visualized using LFCalDispRectIntrinsics.
%
% Inputs :
% 
%     LFSize : Size of the light field to rectify
%
%     CalInfo : Calibration info as loaded by LFFindCalInfo, for example.
% 
% Outputs:
% 
%     RectCamIntrinsicsH : The resulting intrinsics.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFCalDispRectIntrinsics, LFRecenterIntrinsics, LFFindCalInfo, LFUtilDecodeLytroFolder

% Copyright (c) 2013-2020 Donald G. Dansereau

function RectCamIntrinsicsH = LFDefaultIntrinsics( LFSize, CalInfo )

RectCamIntrinsicsH = CalInfo.EstCamIntrinsicsH;

ST_ST_Slope = mean([CalInfo.EstCamIntrinsicsH(1,1), CalInfo.EstCamIntrinsicsH(2,2)]);
ST_UV_Slope = mean([CalInfo.EstCamIntrinsicsH(1,3), CalInfo.EstCamIntrinsicsH(2,4)]);
UV_ST_Slope = mean([CalInfo.EstCamIntrinsicsH(3,1), CalInfo.EstCamIntrinsicsH(4,2)]);
UV_UV_Slope = mean([CalInfo.EstCamIntrinsicsH(3,3), CalInfo.EstCamIntrinsicsH(4,4)]);

RectCamIntrinsicsH(1,1) = ST_ST_Slope;
RectCamIntrinsicsH(2,2) = ST_ST_Slope;
RectCamIntrinsicsH(1,3) = ST_UV_Slope;
RectCamIntrinsicsH(2,4) = ST_UV_Slope;

RectCamIntrinsicsH(3,1) = UV_ST_Slope;
RectCamIntrinsicsH(4,2) = UV_ST_Slope;
RectCamIntrinsicsH(3,3) = UV_UV_Slope;
RectCamIntrinsicsH(4,4) = UV_UV_Slope;

%---force s,t translation to CENTER---
RectCamIntrinsicsH = LFRecenterIntrinsics( RectCamIntrinsicsH, LFSize );
