% LFConvertToFloat - Helper function to convert light fields to floating-point representation
% 
% Usage:
%     LF = LFConvertToFloat( LF, [Precision] )
% 
% For float inputs, this converts between single and double without changes in scale. For integer
% inputs, the full input precision's range is mapped to a floating point range 0.0-1.0.
% 
% Inputs:
% 
%    LF :  Must be of type single, double, uint8, or uint16
% 
% Optional Inputs:
% 
%    Precision : one of 'single' or 'double', default 'single'
% 
% Outputs:
% 
%    LF : the converted LF
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFConvertToInt

% Copyright (c) 2013-2020 Donald G. Dansereau

function LF = LFConvertToFloat( LF, Precision )

Precision = LFDefaultVal('Precision', 'single');

OrigClass = class(LF);

if( strcmp( OrigClass, Precision ) )
	
	% already in the right precision, nothing to do
	
else
	IsInt = isinteger(LF);
	
	LF = cast(LF, Precision);
	
	if( IsInt )
		LF = LF ./ cast(intmax(OrigClass), Precision);
	end

end
