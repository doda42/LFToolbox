% LFSign - Like Matlab's sign, but never returns 0, treating 0 as positive

% Part of LF Toolbox v0.4 released 12-Feb-2015
% Copyright (c) 2013-2015 Donald G. Dansereau

function s = LFSign(i)

s = ones(size(i));
s(i<0) = -1;