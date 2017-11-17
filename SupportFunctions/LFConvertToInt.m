% LFConvertToInt - Helper function to convert light fields to integer representations
%
% Float inputs are assumed to be normalized to a maximum value of 1.0.

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (c) 2013-2015 Donald G. Dansereau

function LF = LFConvertToInt( LF, Precision )

Precision = LFDefaultVal('Precision', 'uint16');

OrigClass = class(LF);
IsInt = isinteger(LF);

if( ~IsInt )
	LF = LF .* cast(intmax(Precision), OrigClass);
else
	LF = double(LF) .* double(intmax(Precision)) ./ double(intmax(OrigClass)); % todo: less memory-hungry implementation
end

LF = cast(LF, Precision);

