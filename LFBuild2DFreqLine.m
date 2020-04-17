% LFBuild2DFreqLine - construct a 2D line passband filter in the frequency domain
% 
% Usage: 
% 
%     [H, FiltOptions] = LFBuild2DFreqLine( LFSize, Slope, BW, FiltOptions )
%     H = LFBuild2DFreqLine( LFSize, Slope, BW )
% 
% This file constructs a real-valued magnitude response in 2D, for which the passband is a line. The cascade of two line
% filters, applied in s,u and in t,v, is identical to a 4D planar filter, e.g. that constructed by LFBuild4DFreqPlane.
% 
% Once constructed the filter must be applied to a light field, e.g. using LFFilt2DFFT. The
% LFDemoBasicFilt* files demonstrate how to contruct and apply frequency-domain filters.
% 
% A more technical discussion, including the use of filters for denoising and volumetric focus, and
% the inclusion of aliases components, is included in:
% 
% [2] D.G. Dansereau, O. Pizarro, and S. B. Williams, "Linear Volumetric Focus for Light Field
% Cameras," to appear in ACM Transactions on Graphics (TOG), vol. 34, no. 2, 2015.
% 
% Inputs:
% 
%     LFSize : Size of the frequency-domain filter. This should match or exceed the size of the
%     light field to be filtered. If it's larger than the input light field, the input is
%     zero-padded to match the filter's size by LFFilt2DFFT.
% 
%     Slope : Slopes at the extents of the fan passband. 
% 
%     BW : 3-db Bandwidth of the planar passband.
% 
%     [optional] FiltOptions : struct controlling filter construction
%               SlopeMethod : only 'Skew' is supported for now
%                 Precision : 'single' or 'double', default 'single'
%                   Rolloff : 'Gaussian' or 'Butter', default 'Gaussian'
%                     Order : controls the order of the filter when Rolloff is 'Butter', default 3
%                  Aspect2D : aspect ratio of the light field, default [1 1]
%                    Window : Default false. By default the edges of the passband are sharp; this adds 
%                             a smooth rolloff at the edges when used in conjunction with Extent2D or
%                             IncludeAliased.
%                  Extent2D : controls where the edge of the passband occurs, the default [1 1]
%                             is the edge of the Nyquist box. When less than 1, enabling windowing
%                             introduces a rolloff after the edge of the passband. Can be greater
%                             than 1 when using IncludeAliased.
%            IncludeAliased : default false; allows the passband to wrap around off the edge of the
%                             Nyquist box; used in conjunction with Window and/or Extent2D. This can 
%                             increase processing time dramatically, e.g. Extent2D = [2,2] 
%                             requires a 2^2 = 4-fold increase in time to construct the filter. 
%                             Useful when passband content is aliased, see [2].
% 
% Outputs:
% 
%                 H : real-valued frequency magnitude response
%       FiltOptions : The filter options including defaults, with an added PassbandInfo field
%                     detailing the function and time of construction of the filter
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFDemoBasicFiltGantry, LFDemoBasicFiltIllum, LFDemoBasicFiltLytroF01,
% LFBuild2DFreqFan, LFBuild2DFreqLine, LFBuild4DFreqDualFan, LFBuild4DFreqHypercone,
% LFBuild4DFreqHyperfan, LFBuild4DFreqPlane, LFFilt2DFFT, LFFilt4DFFT, LFFiltShiftSum

% Copyright (c) 2013-2020 Donald G. Dansereau

function [H, FiltOptions] = LFBuild2DFreqLine( LFSize, Slope, BW, FiltOptions )

FiltOptions = LFDefaultField('FiltOptions', 'SlopeMethod', 'Skew'); % 'Skew', 'Rotate'

DistFunc = @(P, FiltOptions) DistFunc_2DLine( P, Slope, FiltOptions );
[H, FiltOptions] = LFHelperBuild2DFreq( LFSize, BW, FiltOptions, DistFunc );

TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.PassbandInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

end

%-----------------------------------------------------------------------------------------------------------------------
function Dist = DistFunc_2DLine( P, Slope, FiltOptions )

% Build a transformation, either skew or rotation, to xform the plane to the desired slope
switch( lower(FiltOptions.SlopeMethod) )
	case 'skew'
		R = eye(2);
		R(1,2) = Slope;
		
	case 'rotate'
		Angle = -atan2(Slope,1);
		R = LFRotz( Angle );
		R = R(1:2,1:2);
		
	otherwise
		error('Unrecognized slope method');
end

% Apply the trasformation
P = R * P;

% Find the distance
Dist = P(1,:).^2;

end



