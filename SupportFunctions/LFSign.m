% LFSign - Like Matlab's sign, but never returns 0, treating 0 as positive

% Copyright (c) 2013-2020 Donald G. Dansereau

function s = LFSign(i)

s = ones(size(i));
s(i<0) = -1;
