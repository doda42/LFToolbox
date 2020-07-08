% todo[doc]
% LFMapRectifiedToMeasured - Applies a calibrated camera model to map desired samples to measured samples
% 
% Usage:
% 
%     InterpIdx = LFMapRectifiedToMeasured( InterpIdx, CalInfo.CameraModel, RectOptions )
% 
% Helper function used by LFCalRectifyLF.  Based on a calibrated camera model, including distortion parameters and a
% desired intrinsic matrix, the indices of a set of desired sample is mapped to the indices of corresponding measured
% samples.
%
% Inputs :
% 
%     InterpIdx : Set of desired indices, in homogeneous coordinates
%     CalInfo.CameraModel : Calibration info as returned by LFFindCalInfo
%     RectOptions : struct controlling the rectification process, see LFCalRectify
% 
% Outputs:
% 
%      InterpIdx : continuous-domain indices for interpolating from the measured light field
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFCalRectifyLF

% Copyright (c) 2013-2020 Donald G. Dansereau

function InterpIdx = LFModCalInvertDistortion( InterpIdx, CalInfo, RectOptions )

RectOptions = LFDefaultField( 'RectOptions', 'Precision', 'single' );

%---Cast the to the required precision---
InterpIdx = cast(InterpIdx, RectOptions.Precision);

%---Convert the index of the desired ray to a ray representation using ideal intrinsics---
Ray = RectOptions.RectCamIntrinsicsH * InterpIdx;

% Convert the desired ray observation back 
% todo[optimization]: The variable InterpIdx could be precomputed and saved with the calibration
InterpIdx = feval( CalInfo.CalOptions.Fn_RayToObs, ...
	Ray, CalInfo.CameraModel, RectOptions );

InterpIdx = InterpIdx(1:4,:); % drop homogeneous coordinates
