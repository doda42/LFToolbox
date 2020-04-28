% LFConvertToInt - Helper function to convert light fields to integer representations.
%
% Usage:
%     LF = LFConvertToInt( LF, [Precision] )
% 
% For float inputs, this maps floats in the range 0.0-1.0 to output ints covering the maximum range
% for the selected representation. For integer inputs, the full input precision's range is mapped to
% the full output precision's range.
% 
% Inputs:
% 
%    LF :  Must be of type single, double, uint8, or uint16
% 
% Optional Inputs:
% 
%    Precision : one of 'uint8' or 'uint16', default 'uint16'
% 
% Outputs:
% 
%    LF : the converted LF
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFConvertToFloat

% Copyright (c) 2013-2020 Donald G. Dansereau

function LF = LFConvertToInt( LF, Precision )

Precision = LFDefaultVal('Precision', 'uint16');

OrigClass = class(LF);

if( strcmp( OrigClass, Precision ) )
	
	% already in the right precision, nothing to do
	
elseif( isfloat(LF) )
	
	% input is a float, scale up to maximum range for requested precision
	LF = LF .* cast(intmax(Precision), OrigClass);
	LF = cast(LF, Precision);
	
elseif( isinteger(LF) )
	
	% input is an int
	switch( Precision )
		case 'uint8'
			LF = bitshift(LF, -8);
			LF = cast(LF, Precision);

		case 'uint16'
			LF = cast(LF, Precision);
			LF = bitshift(LF, 8);
			
		otherwise
			error('Unsupported output precision');
	end
	
else
	
	error('Unsupported input type');

end



