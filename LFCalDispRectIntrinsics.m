% LFCalDispRectIntrinsics - Visualize sampling pattern resulting from a prescribed intrinsic matrix
%
% Usage: 
%     RectOptions = LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions, PaintColour )
%
% During rectification, the matrix RectOptions.RectCamIntrinsicsH determines which subset of the light field gets
% sampled into the rectified light field.  LFCalDispRectIntrinsics visualizes the resulting sampling pattern.  The
% display is interactive, generated using LFDispMousePan, and can be explored by clicking and dragging the mouse. 
% 
% If no intrinsic matrix is provided, a default best-guess is constructed and returned in
% RectOptions.RectCamIntrinsicsH.
% 
% A typical usage pattern is to load a light field, call LFCalDispRectIntrinsics to set up the default intrinsic
% matrix, manipulate the matrix, then visualize the manipulated sampling pattern prior to employing it in one or more
% rectification calls. The function LFRecenterIntrinsics is useful in maintaining a centered sampling pattern.
% 
% This function relies on the presence of a calibration file and associated database, see LFUtilCalLensletCam and
% LFUtilDecodeLytroFolder.
% 
% Inputs:
% 
%     LF : Light field to visualize
% 
%     LFMetadata : The light field's associated metadata - needed to locate the appropriate calibration file
% 
%     [optional] RectOptions : all fields are optional, see LFCalRectifyLF for all fields
%            .RectCamIntrinsicsH : The intrinsic matrix to visualize
% 
%     [optional] PaintColour : RGB triplet defining a base drawing colour, RGB values are in the range 0-1
%
% Outputs:
% 
%     RectOptions : RectOptions updated with any defaults that were applied
%              LF : The light field with visualized sample pattern
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFCalRectifyLF, LFRecenterIntrinsics, LFUtilCalLensletCam, LFUtilDecodeLytroFolder

% Copyright (c) 2013-2020 Donald G. Dansereau

function [RectOptions, LF] = LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions, PaintColour )

PaintColour = LFDefaultVal( 'PaintColour', [0.5,1,1] );
[CalInfo, RectOptions] = LFFindCalInfo( LFMetadata, RectOptions );

%---Discard weight channel---
HasWeight = (size(LF,5) == 4);
if( HasWeight )
    LF = LF(:,:,:,:,1:3);
end

LFSize = size(LF);

RectOptions = LFDefaultField( 'RectOptions', 'Precision', 'single' );
RectOptions = LFDefaultField( 'RectOptions', 'NInverse_Distortion_Iters', 2 );
RectOptions = LFDefaultField( 'RectOptions', 'RectCamIntrinsicsH', LFDefaultIntrinsics( LFSize, CalInfo ) );

if( isempty( CalInfo ) )
    warning('No suitable calibration found, skipping');
    return;
end

%--- visualize image utilization---
t_in=cast(1:LFSize(1), 'uint16');
s_in=cast(1:LFSize(2), 'uint16');
v_in=cast(1:10:LFSize(3), 'uint16');
u_in=cast(1:10:LFSize(4), 'uint16');
[tt,ss,vv,uu] = ndgrid(t_in,s_in,v_in,u_in);
InterpIdx = [ss(:)'; tt(:)'; uu(:)'; vv(:)'; ones(size(ss(:)'))];
InterpIdx = LFMapRectifiedToMeasured( InterpIdx, CalInfo, RectOptions );
InterpIdx = round(double(InterpIdx));

PaintVal = cast(double(max(LF(:))).*PaintColour, 'like', LF);
LF = 0.7*LF;

%---Clamp indices---
STUVChan = [2,1,4,3];
for( Chan=1:4 )
    InterpIdx(Chan,:) = min(LFSize(STUVChan(Chan)), max(1,InterpIdx(Chan,:)));
end

%---Paint onto LF---
RInterpIdx = sub2ind( LFSize, InterpIdx(2,:), InterpIdx(1,:), InterpIdx(4,:), InterpIdx(3,:), 1*ones(size(InterpIdx(1,:))));
LF(RInterpIdx) = PaintVal(1);
RInterpIdx = sub2ind( LFSize, InterpIdx(2,:), InterpIdx(1,:), InterpIdx(4,:), InterpIdx(3,:), 2*ones(size(InterpIdx(1,:))));
LF(RInterpIdx) = PaintVal(2);
RInterpIdx = sub2ind( LFSize, InterpIdx(2,:), InterpIdx(1,:), InterpIdx(4,:), InterpIdx(3,:), 3*ones(size(InterpIdx(1,:))));
LF(RInterpIdx) = PaintVal(3);

%---Display LF---
LFDispMousePan( LF );
