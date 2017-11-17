% xRectifiedIntrinsicsForParallelViews - Demonstrate rectification to a virtual, parallel array of cameras
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
% See also Section 3.1 of the paper "Panorama Light-Field Imaging", 2014 by Birklbauer and Bimber.

% Copyright (c) 2016 Donald G. Dansereau

clearvars

% set this to true to modify the default rectification matrix to yield parallel views
ForceParallel = false;

% load an unrectified light field
cd ~/Data.local/2016_Lytro  % set this to your top-level light field path
load('Images/F01/IMG_0002__Decoded.mat');  % set this to an unrectified light field

assert( ~isfield(RectOptions,'RectCamIntrinsicsH'), 'Start with an unrectified light field');

% set up the default rectified intrinsic matrix
RectOptions = LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions );

% Optionally make all views parallel
if( ForceParallel )
	fprintf('forcing cameras to be parallel\n');
	RectOptions.RectCamIntrinsicsH(3:4,1:2) = 0;%RectOptions.RectCamIntrinsicsH(1:2,1:2);
	RectOptions.RectCamIntrinsicsH = LFRecenterIntrinsics( RectOptions.RectCamIntrinsicsH, size(LF) );

	% show updated sampling pattern
 	RectOptions = LFCalDispRectIntrinsics( LF, LFMetadata, RectOptions );
end

fprintf('Requested rectified intrinsics:\n');
disp(RectOptions.RectCamIntrinsicsH)

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
		plot([Ray(1), Ray(3)+Ray(1)], [0,1], '-')
	end
end

ax = axis;
ax(4) = 1.1;
axis(ax);
plot(ax(1:2), [0,0],'r');
plot(ax(1:2), [1,1],'r');
text(0.9*ax(1), 0.05, 's,t', 'color','r');
text(0.9*ax(1), 1.05, 'u,v', 'color','r');
xlabel('x');
ylabel('z');

% % To apply this rectification, use this:
% DecodeOptions.OptionalTasks = 'Rectify';
% LFUtilDecodeLytroFolder('Images/F01/IMG_0002*', [], DecodeOptions, RectOptions);
% load('/home/danserea/Data.local/2016_Lytro/Images/F01/IMG_0002__Decoded.mat')
% LFDispMousePan(LF)
