% Display a 4D light field as projection onto planes.

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function Img = LFXShowLF_proj( LF, Plane1, Plane2, Mode, varargin )

%---
Mode = LFDefaultVal('Mode', 'sum');

%---
if( Plane1 > Plane2 )
	t = Plane1;
	Plane1 = Plane2;
	Plane2 = t;
end

Plane2 = Plane2 - 1;

switch( lower(Mode) )
    case 'sum'
        Img = squeeze(sum(squeeze(sum(LF,Plane1)), Plane2));
    case 'max'
        Img = squeeze(max(squeeze(max(LF,[],Plane1)),[],Plane2));
    case 'min'
        Img = squeeze(min(squeeze(max(LF,[],Plane1)),[],Plane2));        
end

if( nargout == 0 )
    LFDisp(Img,true);
	clear Img
end