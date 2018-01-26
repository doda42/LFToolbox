% LFNormalizedFreqAxis - Helper function to construct a frequency axis 
%
% Construct a frequency axis matching the fftshifted output of the fft algorithm,
% for a normalized sampling rate, i.e. for a Nyquist frequency of 0.5.

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (c) 2013-2015 Donald G. Dansereau

function f = LFNormalizedFreqAxis( NSamps, Precision )

Precision = LFDefaultVal( 'Precision', 'double' );  % todo: check: double?

df = 1/NSamps;
f = (0:df:(1-df)) - (1-mod(NSamps,2)*df)/2;

f = cast(f, Precision);
