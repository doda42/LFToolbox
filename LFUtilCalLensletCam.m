% LFUtilCalLensletCam - calibrate a lenslet-based light field camera
%
% Usage:
%
%     LFUtilCalLensletCam
%     LFUtilCalLensletCam( Inputpath )
%     LFUtilCalLensletCam( InputPath, CalOptions )
%     LFUtilProcessCalibrations( [], CalOptions )
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
%     InputPath : Path to folder containing decoded checkerboard images -- note the function
%                 operates recursively, i.e. it will search sub-folders.
%
%     CalOptions : struct controlling calibration parameters
%          .ExpectedCheckerSize : Number of checkerboard corners, as recognized by the automatic
%                                 corner detector; edge corners are not recognized, so a standard
%                                 8x8-square chess board yields 7x7 corners
%     .ExpectedCheckerSpacing_m : Physical extents of the checkerboard, in meters
%           .LensletBorderSize : Number of pixels to skip around the edges of lenslets; a low
%                                 value of 1 or 0 is generally appropriate, as invalid pixels are
%                                 automatically skipped
%                   .SaveResult : Set to false to perform a "dry run"
%                  .ShowDisplay : Enables various displays throughout the calibration process
%       .ForceRedoCornerFinding : Forces the corner finding procedure to run, overwriting existing
%                                 results
%                .ForceRedoInit : Forces the parameter initialization step to run, overwriting
%                                 existing results
%                   .OptTolX : Determines when the optimization process terminates. When the
%                              estimted parameter values change by less than this amount, the
%                              optimization terminates. See the Matlab documentation on lsqnonlin,
%                              option `TolX' for more information. The default value of 5e-5 is set
%                              within the LFCalRefine function; a value of 0 means the optimization
%                              never terminates based on this criterion.
%                 .OptTolFun : Similar to OptTolX, except this tolerance deals with the error value.
%                              This corresponds to Matlab's lsqnonlin option `TolFun'. The default
%                              value of 0 is set within the LFCalRefine function, and means the
%                              optimization never terminates based on this criterion.
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
% See also:  LFCalFindCheckerCorners, LFCalInit, LFCalRefine, LFUtilDecodeLytroFolder, LFSelectFromDatabase

% Copyright (c) 2013-2020 Donald G. Dansereau

function LFUtilCalLensletCam( InputPath, CalOptions )

%---Tweakables---
InputPath = LFDefaultVal('InputPath', '.');

CalOptions = LFDefaultField( 'CalOptions', 'ExpectedCheckerSize', [19, 19] );
CalOptions = LFDefaultField( 'CalOptions', 'ExpectedCheckerSpacing_m', [3.61, 3.61] * 1e-3 );
CalOptions = LFDefaultField( 'CalOptions', 'LensletBorderSize', 1 );
CalOptions = LFDefaultField( 'CalOptions', 'SaveResult', true );
CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoCornerFinding', false );
CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoInit', false );
CalOptions = LFDefaultField( 'CalOptions', 'ShowDisplay', true );
CalOptions = LFDefaultField( 'CalOptions', 'CalInfoFname', 'CalInfo.json' );

%---Check for previously started calibration---
CalInfoFname = fullfile(InputPath, CalOptions.CalInfoFname);
if( ~CalOptions.ForceRedoInit && exist(CalInfoFname, 'file') )
    fprintf('---File %s already exists\n   Loading calibration state and options\n', CalInfoFname);
    CalOptions = LFStruct2Var( LFReadMetadata(CalInfoFname), 'CalOptions' );
else
    CalOptions.Phase = 'Start';
end

RefineComplete = false; % always at least refine once

%---Step through the calibration phases---
while( ~strcmp(CalOptions.Phase, 'Refine') || ~RefineComplete )
    switch( CalOptions.Phase )
        
        case 'Start'
            %---Find checkerboard corners---
            CalOptions.Phase = 'Corners';
            CalOptions = LFCalFindCheckerCorners( InputPath, CalOptions );
            
        case 'Corners'
            %---Initialize calibration process---
            CalOptions.Phase = 'Init';
            CalOptions = LFCalInit( InputPath, CalOptions );
            
            if( CalOptions.ShowDisplay )
                LFFigure(2);
                clf
                LFCalDispEstPoses( InputPath, CalOptions, [], [0.7,0.7,0.7] );
            end
            
        case 'Init'
            %---First step of optimization process will exclude distortion---
            CalOptions.Phase = 'NoDistort';
            CalOptions = LFCalRefine( InputPath, CalOptions );
            
            if( CalOptions.ShowDisplay )
                LFFigure(2);
                LFCalDispEstPoses( InputPath, CalOptions, [], [0,0.7,0] );
            end
            
        case 'NoDistort'
            %---Next step of optimization process adds distortion---
            CalOptions.Phase = 'WithDistort';
            CalOptions = LFCalRefine( InputPath, CalOptions );
            if( CalOptions.ShowDisplay )
                LFFigure(2);
                LFCalDispEstPoses( InputPath, CalOptions, [], [0,0,1] );
            end
            
        otherwise
            %---Subsequent calls refine the estimate---
            CalOptions.Phase = 'Refine';
            CalOptions = LFCalRefine( InputPath, CalOptions );
            RefineComplete = true;
            if( CalOptions.ShowDisplay )
                LFFigure(2);
                LFCalDispEstPoses( InputPath, CalOptions, [], [1,0,0] );
            end
    end
end
