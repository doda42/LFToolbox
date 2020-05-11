% LFBuild2DLPF - construct a 2D lowpass filter in the frequency domain
% 
% Usage: 
% 
%     H = LFBuild2DLPF( LFSize, BW )
%     [H, FiltOptions] = LFBuild2DLPF( LFSize, BW, [FiltOptions] )
% 
% This file constructs a real-valued lowpass frequency-domain filter in 2D. Anisotropic filtering is
% possible using FiltOptions.Aspect2D.
%
% Once constructed the filter may be applied to a light field using LFFilt2DFFT. The
% LFDemoBasicFilt* files demonstrate how to contruct and apply frequency-domain filters.
% 
% A more technical discussion, including the use of filters for denoising and volumetric focus, is
% included in:
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
%     BW : 3-db Bandwidth of the passband.
% 
%     [optional] FiltOptions : struct controlling filter construction
%                 Precision : 'single' or 'double', default 'single'
%                   Rolloff : 'Gaussian', 'Butter', or 'Sinc', default 'Gaussian'
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

function [H, FiltOptions] = LFBuild2DLPF( LFSize, BW, FiltOptions )

FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single');

DistFunc = @(P, FiltOptions) DistFunc_2DPt( P, FiltOptions );
[H, FiltOptions] = LFHelperBuild2DFreq( LFSize, BW, FiltOptions, DistFunc );

TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.PassbandInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

end

%-----------------------------------------------------------------------------------------------------------------------
function Dist = DistFunc_2DPt( P, FiltOptions )
Dist = sum( P.^2 );
end
