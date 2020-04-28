% LFRotz - simple 3D rotation matrix, rotation about z
%
% Usage:
%     R = LFRotz( psi )
% 

% Copyright (c) 2013-2020 Donald G. Dansereau

function R = LFRotz(psi)

c = cos(psi);
s = sin(psi);

R = [ c, -s,  0; ...
      s,  c,  0; ... 
      0,  0,  1  ];
