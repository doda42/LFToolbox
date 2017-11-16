% LFRotz - simple 3D rotation matrix, rotation about z
%
% Usage:
%     R = LFRotz( psi )
% 

% Part of LF Toolbox v0.4 released 12-Feb-2015
% Copyright (c) 2013-2015 Donald G. Dansereau

function R = LFRotz(psi)

c = cos(psi);
s = sin(psi);

R = [ c, -s,  0; ...
      s,  c,  0; ... 
      0,  0,  1  ];
