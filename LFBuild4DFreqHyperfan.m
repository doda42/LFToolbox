% LFBuild4DFreqHyperfan - construct a 4D hyperfan passband filter in the frequency domain
% 
% Usage: 
% 
%     [H, FiltOptions] = LFBuild4DFreqHyperfan( LFSize, Slope1, Slope2, BW, FiltOptions )
%     H = LFBuild4DFreqHyperfan( LFSize, Slope1, Slope2, BW )
% 
% This file constructs a real-valued magnitude response in 4D, for which the passband is a hyperfan.
% This is useful for selecting objects over a range of depths from a lightfield, i.e. volumetric
% focus.
%
% Once constructed the filter must be applied to a light field, e.g. using LFFilt4DFFT. The 
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
%     zero-padded to match the filter's size by LFFilt4DFFT.
% 
%     Slope : The slope of the planar passband. If different slopes are desired in s,t and u,v,
%     the optional aspect parameter should be used.
% 
%     BW : 3-db Bandwidth of the planar passband.
% 
%     [optional] FiltOptions : struct controlling filter construction
%            HyperfanMethod : 'sweep' or 'direct', controls how the hyperfan is constructed. 'sweep'
%                             concatenates frequency planes, while 'direct' evaluates a single 4D 
%                             equation; default 'direct'. Warning: sweep can be very slow.
%               HyperconeBW : Sets the underlying hypercone's BW separately from the dual-fan,
%                             default is to use the BW parameter for both; only applies when
%                             HyperfanMethod is 'direct'
%               SlopeMethod : 'Skew' or 'Rotate' default 'skew'
%                 Precision : 'single' or 'double', default 'single'
%                   Rolloff : 'Gaussian' or 'Butter', default 'Gaussian'
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
%                SweepSteps : For HyperfanMethod 'sweep', how many steps to use in the sweep.
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

function [H, FiltOptions] = LFBuild4DFreqHyperfan( LFSize, Slope1, Slope2, BW, FiltOptions )

FiltOptions = LFDefaultField('FiltOptions', 'HyperfanMethod', 'Direct'); % 'Direct', 'Sweep'

switch( lower(FiltOptions.HyperfanMethod ))
	case 'sweep'
		FiltOptions = LFDefaultField('FiltOptions', 'SweepSteps', 5);
		SweepVec = linspace(Slope1, Slope2, FiltOptions.SweepSteps);
		[H, FiltOptions] = LFBuild4DFreqPlane( LFSize, SweepVec(1), BW, FiltOptions );
		for( CurSlope = SweepVec(2:end) )
			H = max(H, LFBuild4DFreqPlane( LFSize, CurSlope, BW, FiltOptions ));
		end
		
	case 'direct'
		FiltOptions = LFDefaultField('FiltOptions', 'HyperconeBW', BW);
		[H, FiltOptions] = LFBuild4DFreqHypercone( LFSize, FiltOptions.HyperconeBW, FiltOptions );
		[Hdf, FiltOptions] = LFBuild4DFreqDualFan( LFSize, Slope1, Slope2, BW, FiltOptions );
		H = H .* Hdf;
		
	otherwise
		error('Unrecognized hyperfan construction method');
end
	
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.PassbandInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

