% LFNormalizedFreqAxis - Helper function to construct a frequency axis 
%
% Output range is from -0.5 to 0.5.  This is designed so that the zero frequency matches the fftshifted output of the
% fft algorithm.

% Part of LF Toolbox v0.4 released 12-Feb-2015
% Copyright (c) 2013-2015 Donald G. Dansereau

function f = LFNormalizedFreqAxis( NSamps, Precision )

Precision = LFDefaultVal( 'Precision', 'double' );

if( NSamps == 1 )
	f = 0;
elseif( mod(NSamps,2) )
	f = [-(NSamps-1)/2:(NSamps-1)/2]/(NSamps-1);
else
	f = [-NSamps/2:(NSamps/2-1)]/NSamps;
end

f = cast(f, Precision);