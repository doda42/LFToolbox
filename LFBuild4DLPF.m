% LFBuild4DLPF - construct a 4D lowpass filter in the frequency domain
% 
% Usage: 
% 
%     H = LFBuild4DLPF( LFSize, BW )
%     [H, FiltOptions] = LFBuild4DLPF( LFSize, BW, [FiltOptions] )
% 
% This file constructs a real-valued lowpass frequency-domain filter in 4D. Anisotropic filtering is
% possible using FiltOptions.Aspect4D.
%
% Once constructed the filter may be applied to a light field using LFFilt4DFFT. The
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
%     zero-padded to match the filter's size by LFFilt4DFFT.
% 
%     BW : 3-db Bandwidth of the passband.
% 
%     [optional] FiltOptions : struct controlling filter construction
%                 Precision : 'single' or 'double', default 'single'
%                   Rolloff : 'Gaussian', 'Butter', or 'Sinc' default 'Gaussian'
%                     Order : controls the order of the filter when Rolloff is 'Butter', default 3
%                  Aspect4D : aspect ratio of the light field, default [1 1 1 1]
%                    Window : Default false. By default the edges of the passband are sharp; this adds 
%                             a smooth rolloff at the edges when used in conjunction with Extent4D or
%                             IncludeAliased.
%                  Extent4D : controls where the edge of the passband occurs, the default [1 1 1 1]
%                             is the edge of the Nyquist box. When less than 1, enabling windowing
%                             introduces a rolloff after the edge of the passband. Can be greater
%                             than 1 when using IncludeAliased.
%            IncludeAliased : default false; allows the passband to wrap around off the edge of the
%                             Nyquist box; used in conjunction with Window and/or Extent4D. This can 
%                             increase processing time dramatically, e.g. Extent4D = [2,2,2,2] 
%                             requires a 2^4 = 16-fold increase in time to construct the filter. 
%                             Useful when passband content is aliased, see [2].
% 
% Outputs:
% 
%                 H : real-valued frequency magnitude response
%       FiltOptions : The filter options including defaults, with an added PassbandInfo field
%                     detailing the function and time of construction of the filter
% 
% Examples: 
% 
%     H = LFBuild4DLPF( LFSize(1:4), 0.1 );  % symmetric filter, BW = 0.1
%     H = LFBuild4DLPF( LFSize(1:4), 0.25, struct('Aspect4D',[8,8,1,1]) ); % anisotropic filter
% 
%     Display anisotropic example:
%     LFDispTilesSubfigs(fftshift(LFBuild4DLPF(11,0.3, struct('Aspect4D',[8,8,1,1])))); 
% 
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFBuild2DLPF, LFDemoBasicFiltGantry, LFDemoBasicFiltIllum, LFDemoBasicFiltLytroF01,
% LFBuild2DFreqFan, LFBuild2DFreqLine, LFBuild4DFreqDualFan, LFBuild4DFreqHypercone,
% LFBuild4DFreqHyperfan, LFBuild4DFreqPlane, LFFilt2DFFT, LFFilt4DFFT, LFFiltShiftSum

% Copyright (c) 2013-2020 Donald G. Dansereau

function [H, FiltOptions] = LFBuild4DLPF( LFSize, BW, FiltOptions )

FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single');

DistFunc = @(P, FiltOptions) DistFunc_4DPt( P, FiltOptions );
[H, FiltOptions] = LFHelperBuild4DFreq( LFSize, BW, FiltOptions, DistFunc );

TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.PassbandInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

end

%-----------------------------------------------------------------------------------------------------------------------
function Dist = DistFunc_4DPt( P, FiltOptions )
Dist = sum( P.^2 );
end
