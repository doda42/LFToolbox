% LFUtilCalLensletCam - calibrate a lenslet-based light field camera
%
% Usage:
%
%     LFUtilCalLensletCam
%     LFUtilCalLensletCam( [InputImagePath], [CalOptions], [FileOptions] )
%
% All parameters are optional and take on default values as set in the "Defaults" section at the top
% of the implementation. As such, this can be called as a function or run directly by editing the
% code. When calling as a function, pass an empty array "[]" to omit a parameter.
%
% This function recursively crawls through a folder identifying decoded light field images and
% performing a calibration based on those images. It follows the calibration procedure described in:
%
% D. G. Dansereau, O. Pizarro, and S. B. Williams, "Decoding, calibration and rectification for
% lenslet-based plenoptic cameras," in Computer Vision and Pattern Recognition (CVPR), IEEE
% Conference on. IEEE, Jun 2013.
%
% Minor differences from the paper: camera parameters are automatically initialized, so no prior
% knowledge of the camera's parameters is required; the free intrinsic parameters have been reduced
% by two: H(3:4,5) were previously redundant with the camera's extrinsics, and are now automatically
% centered; and the light field indices [i,j,k,l] are 1-based in this implementation, and not
% 0-based as described in the paper.
%
% The calibration produced by this process is saved in a JSON file, by default named 'CalInfo.json',
% in the top-level folder of the calibration images. The calibration includes a 5x5 homogeneous
% intrinsic matrix EstCamIntrinsicsH, a 5-element vector EstCamDistortionV describing its distortion
% parameters, and the lenslet grid model formed from the white image used to decode the
% checkerboard images. Taken together, these relate light field indices [i,j,k,l] to spatial rays
% [s,t,u,v], and can be utilized to rectify light fields, as demonstrated in LFUtilDecodeLytroFolder
% / LFCalRectifyLF.
%
% The input light fields are ideally of a small checkerboard (order mm per square), taken at close
% range, and over a diverse set of poses to maximize the quality of the calibration. The
% checkerboard light field images should be decoded without rectification, and colour correction is
% not required.
%
% Calibration is described in more detail in LFToolbox.pdf, including links to example datasets and
% a walkthrough of a calibration process.
%
% Inputs -- all are optional, see code below for default values :
%
%     InputImagePath : Default '.'; Path to folder containing decoded checkerboard images -- note the
%                 function operates recursively, i.e. it will search sub-folders.
%
%     CalOptions : struct controlling calibration parameters
%          .ExpectedCheckerSize : Number of checkerboard corners, as recognized by the automatic
%                                 corner detector; edge corners are not recognized, so a standard
%                                 8x8-square chess board yields 7x7 corners
%     .ExpectedCheckerSpacing_m : Physical extents of the checkerboard, in meters
%           .LensletBorderSize : Number of pixels to skip around the edges of lenslets; a low
%                                 value of 1 or 0 is generally appropriate, as invalid pixels are
%                                 automatically skipped
%                  .ShowDisplay : Enables various displays throughout the calibration process
%       .ForceRedoFeatFinding : Forces the corner finding procedure to run, overwriting existing
%                                 results
%                .ForceRedoInit : Forces the parameter initialization step to run, overwriting
%                                 existing results
%                   .OptTolX : Determines when the optimization process terminates. When the
%                              estimted parameter values change by less than this amount, the
%                              optimization terminates. See the Matlab documentation on lsqnonlin,
%                              option `TolX' for more information. The default value of 5e-5 is set
%                              within the LFModCalRefine function; a value of 0 means the optimization
%                              never terminates based on this criterion.
%                 .OptTolFun : Similar to OptTolX, except this tolerance deals with the error value.
%                              This corresponds to Matlab's lsqnonlin option `TolFun'. The default
%                              value of 0 is set within the LFModCalRefine function, and means the
%                              optimization never terminates based on this criterion.
%
%     FileOptions : struct controlling file naming and saving
%               .WorkingPath : By default files are saved alongside input files; specifying an output
%                             path will mirror the folder structure of the input, and save generated
%                             files in that structure, leaving the input untouched
%
%
% Output takes the form of saved checkerboard info and calibration files.
%
% Example :
%
%   LFUtilCalLensletCam('.', ...
%     struct('ExpectedCheckerSize', [8,6], 'ExpectedCheckerSpacing_m', 1e-3*[35.1, 35.0]))
%
%   Run from within the top-level path of a set of decoded calibration images of an 8x6 checkerboard
%   of dimensions 35.1x35.0 mm, will carry out all the stages of a calibration. See the toolbox
%   documentation for a more complete example.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFCalFindCheckerCorners, LFCalInit, LFModCalRefine, LFUtilDecodeLytroFolder, LFSelectFromDatabase

% Copyright (c) 2013-2020 Donald G. Dansereau

function LFUtilCalFeatureBased( InputImagePath, CalOptions, FileOptions )

%---Tweakables---
InputImagePath = LFDefaultVal('InputImagePath', '.');

FileOptions = LFDefaultField( 'FileOptions', 'WorkingPath', InputImagePath );

CalOptions = LFDefaultField( 'CalOptions', 'ExpectedCheckerSize', [19, 19] );
CalOptions = LFDefaultField( 'CalOptions', 'ExpectedCheckerSpacing_m', [3.61, 3.61] * 1e-3 );
CalOptions = LFDefaultField( 'CalOptions', 'LensletBorderSize', 1 );
CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoFeatFinding', false );
CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoInit', false );
CalOptions = LFDefaultField( 'CalOptions', 'ShowDisplay', true );
CalOptions = LFDefaultField( 'CalOptions', 'CalInfoFname', 'CalInfo.json' );
CalOptions = LFDefaultField( 'CalOptions', 'NumIterations', 2 );

CalOptions = LFDefaultField( 'CalOptions', 'Fn_CalInit', 'HD_CalInit' );

if( ~isfield(CalOptions, 'CalTarget') )
	CalOptions.CalTarget = LFModCalTargetChecker( CalOptions );
end

%---Check for previously started calibration---
ForceRedoInit = CalOptions.ForceRedoInit; % save current ForceRedoInit state
CalInfoFname = fullfile(FileOptions.WorkingPath, CalOptions.CalInfoFname);
if( ~CalOptions.ForceRedoInit && ~CalOptions.ForceRedoFeatFinding && exist(CalInfoFname, 'file') )
	fprintf('---File %s already exists\n   Loading calibration state and options\n', CalInfoFname);
	CalOptions = LFStruct2Var( LFReadMetadata(CalInfoFname), 'CalOptions' );
else
	CalOptions.Iteration = 0;
end
CalOptions.ForceRedoInit = ForceRedoInit; % restore current ForceRedoInit state

%---Step through the calibration phases---
CalOptions = LFModCalFind2DFeats( InputImagePath, CalOptions, FileOptions );
CalOptions = LFModCalCollectFeatures( FileOptions, CalOptions );
CalOptions = ... 
	feval( CalOptions.Fn_CalInit, FileOptions, CalOptions );

if( CalOptions.ShowDisplay )
	LFFigure(2);
	clf
	LFCalDispEstPoses( FileOptions, CalOptions, [], [0.7,0.7,0.7] );
end

while( CalOptions.Iteration < CalOptions.NumIterations )
	CalOptions.Iteration = CalOptions.Iteration + 1;
	
	tic
	CalOptions = LFModCalRefine( FileOptions, CalOptions );
	toc
	
	if( CalOptions.ShowDisplay )
		LFFigure(2);
		LFCalDispEstPoses( FileOptions, CalOptions, [], [0,0.7,0] );
	end
end
