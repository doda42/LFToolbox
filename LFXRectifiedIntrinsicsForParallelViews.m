% xRectifiedIntrinsicsForParallelViews - Demonstrate rectification to a virtual, parallel array of cameras
% todo: update LFDefaultIntrinsics to offer the two levels of simplification derived here
% todo: this might involve tracking a dZ along with the ref planes to simplify application of
% diagonal intrinsic matrices
%
% Experimental / not well tested, feedback solicited.
%
% The LF toolbox allows calibration and rectification of light field imagery. During rectification, a "rectified
% intrinsic matrix" H determines the intrinsics of the rectified light field. See the toolbox documentation for more
% info on this process.
% 
% By default the toolbox uses nonzero entries at H(3:4,1:2), making virutal cameras point in different directions. Many
% light field processing algorithms assume a set of parallel projective camera views.  This code shows how to zero the
% appropriate entries in H to force parallel virtual projective views. It also visualizes the views, illustrating how
% the projection center of each virtual view is not on the s,t plane, but just in front of the s,t plane along the z
% direction.
%
% Once the program's run, try zooming in on the virtual camera positions near 0,0.  Also try zooming on the central ray
% of each of the three visualized virtual cameras -- they should cross midway between the reference planes if
% ForceParallel is not set to true, but otherwise come out parallel.
% 
% Applying the parallel version of the intrinsics matrix, running LFDispMousePan(LF) should reveal that objects in the
% distance (e.g. the building in F01/IMG_0002) have small or zero apparent motion between virtual views.
%
% The above gives you parallel camera views, but because H(1:2, 3:4) are nonzero, the projection
% centers generally lie off the s,t plane. It is trivial to further adjust rectification to a
% diagonal intrinsic matrix, by shifting the locations of the s,t and u,v planes in z. Like the
% above, the result is a new RectCamIntrinsicsH, but also a delta-z describing the plane shift.
% 
% See also Section 3.1 of the paper "Panorama Light-Field Imaging", 2014 by Birklbauer and Bimber;
% and "Structure from Plenoptic Imaging", 2018 by Marto et al

% Copyright (c) 2016 Donald G. Dansereau

clearvars

% set this to true to modify the default rectification matrix to yield parallel views
ForceParallel = true;
ForceDiagonal = true;
dZ = 0; % shift of reference plane position along Z, used by ForceDiagonal
ZShift = eye(5);
	
% load an unrectified light field
% cd ~/Data.local/2016_Lytro  % set this to your top-level light field path
cd /home/don/tmp/2020_ToolboxTest/LFToolbo0.5_Samples/
load('Images/F01/IMG_0002__Decoded.mat');  % set this to an unrectified light field

assert( ~isfield(RectOptions,'RectCamIntrinsicsH'), 'Start with an unrectified light field');

% set up the default rectified intrinsic matrix
LFFigure(1);
RectOptions = LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions );

% optionally shift reference plane for diagonal intrinsic matrix
if( ForceDiagonal )
	H = RectOptions.RectCamIntrinsicsH;
	% see derivation below
	D = 1;
	dZ = -H(1,3) * D / H(3,3);
	ZShift(1:2,3:4) = [dZ/D,0; 0,dZ/D];
	RectOptions.RectCamIntrinsicsH = ZShift * H;
end

% Optionally make all views parallel
if( ForceParallel || ForceDiagonal )
	fprintf('forcing cameras to be parallel\n');
	RectOptions.RectCamIntrinsicsH(3:4,1:2) = 0;
	RectOptions.RectCamIntrinsicsH = LFRecenterIntrinsics( RectOptions.RectCamIntrinsicsH, size(LF) );
end

% Visualize what the sub-views see, for a horizontal slice, i.e. fix nt, nv
LFFigure(2);
clf
hold on
grid on
nt=round(size(LF,1)/2);
nv=round(size(LF,3)/2);
for( ns=[1,round(size(LF,2)/2),size(LF,2)] ) % center view and extents
	for( nu=[0:(size(LF,4)-1)/8:size(LF,4)-1]+1) % split into 8
		Ray = RectOptions.RectCamIntrinsicsH * [ns,nt,nu,nv,1]';
		plot([Ray(1), Ray(3)+Ray(1)], dZ+[0,1], '-')
	end
end
ax = axis;
ax(4) = 1.1;
axis(ax);
plot(ax(1:2), dZ+[0,0],'r');
plot(ax(1:2), dZ+[1,1],'r');
text(0.9*ax(1), 0.05, 's,t +dZ', 'color','r');
text(0.9*ax(1), 1.05, 'u,v +dZ', 'color','r');
xlabel('x');
ylabel('z');

% the toolbox funcions don't know about the z shift, so speak to it in terms of the s,t and u,v
% planes at their original positions:
RectOptions.RectCamIntrinsicsH = ZShift^-1 * RectOptions.RectCamIntrinsicsH;

fprintf('Requested rectified intrinsics:\n');
disp(RectOptions.RectCamIntrinsicsH)

% show final sampling pattern
LFFigure(11);
RectOptions = LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions );

% To apply this rectification, use this:
% DecodeOptions.OptionalTasks = 'Rectify';
% LFUtilDecodeLytroFolder('Images/F01/IMG_0002*', [], DecodeOptions, RectOptions);
% load('Images/F01/IMG_0002__Decoded.mat','LF');
% LFFigure(3);
% LFDispMousePan(LF)

% derivation for dZ shift; derive in s,u, with obvious generalisation to t,v
% find the shift in Z required to further simplify the matrix to be diagonal
syms dZ D real
syms dSdi dSdk dUdi dUdk real

ZShift = [1,dZ/D; 0,1];
H = [dSdi, dSdk; dUdi, dUdk];

NewH = ZShift * H
dZ = solve(NewH(1,2)==0,dZ)
NewH = eval(ZShift * H)

% the above gives us
% dZ = -dSdk * D/dUdk;
% newdSdi = dSdi + (dUdi*dZ)/D;
% or
% newdSdi = dSdi - (dSdk*dUdi)/dUdk;
