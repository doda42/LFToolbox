% LFMapRectifiedToMeasured - Applies a calibrated camera model to map desired samples to measured samples
% 
% Usage:
% 
%     InterpIdx = LFMapRectifiedToMeasured( InterpIdx, CalInfo, RectOptions )
% 
% Helper function used by LFCalRectifyLF.  Based on a calibrated camera model, including distortion parameters and a
% desired intrinsic matrix, the indices of a set of desired sample is mapped to the indices of corresponding measured
% samples.
%
% Inputs :
% 
%     InterpIdx : Set of desired indices, in homogeneous coordinates
%     CalInfo : Calibration info as returned by LFFindCalInfo
%     RectOptions : struct controlling the rectification process, see LFCalRectify
% 
% Outputs:
% 
%      InterpIdx : continuous-domain indices for interpolating from the measured light field
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFCalRectifyLF

% Copyright (c) 2013-2020 Donald G. Dansereau

function InterpIdx = LFMapRectifiedToMeasured( InterpIdx, CalInfo, RectOptions )

RectOptions = LFDefaultField( 'RectOptions', 'Precision', 'single' );

%---Cast the to the required precision---
InterpIdx = cast(InterpIdx, RectOptions.Precision);

%---Convert the index of the desired ray to a ray representation using ideal intrinsics---
InterpIdx = RectOptions.RectCamIntrinsicsH * InterpIdx;

%---Apply inverse lens distortion to yield the undistorted ray---
k1 = CalInfo.EstCamDistortionV(1); % r^2
k2 = CalInfo.EstCamDistortionV(2); % r^4
k3 = CalInfo.EstCamDistortionV(3); % r^6
b1 = CalInfo.EstCamDistortionV(4); % decentering of lens distortion
b2 = CalInfo.EstCamDistortionV(5); % decentering of lens distortion

InterpIdx(3:4,:) = bsxfun(@minus, InterpIdx(3:4,:), [b1; b2]); % decentering of lens distortion

%---Iteratively estimate the undistorted direction----
DesiredDirection = InterpIdx(3:4,:);
for( InverseIters = 1:RectOptions.NInverse_Distortion_Iters )
    R2 = sum(InterpIdx(3:4,:).^2); % compute radius^2 for the current estimate
    % update estimate based on inverse of distortion model
    InterpIdx(3:4,:) = DesiredDirection ./ repmat((1 + k1.*R2 + k2.*R2.^2 + k3.*R2.^3),2,1);
end
clear R2 DesiredDirection

InterpIdx(3:4,:) = bsxfun(@plus, InterpIdx(3:4,:), [b1; b2]); % decentering of lens distortion

%---Convert the undistorted ray to the corresponding index using the calibrated intrinsics---
% todo[optimization]: The variable InterpIdx could be precomputed and saved with the calibration
InterpIdx = CalInfo.EstCamIntrinsicsH^-1 * InterpIdx;

%---Interpolate the required values---
InterpIdx = InterpIdx(1:4,:); % drop homogeneous coordinates
