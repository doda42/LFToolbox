% LFRecenterIntrinsics - Recenter a light field intrinsic matrix
%
% Usage:
%     H = LFRecenterIntrinsics( H, LFSize )
%
% The recentering works by forcing the central sample in a light field of LFSize samples to
% correspond to the ray [s,t,u,v] = 0. Note that 1-based indexing is assumed in [i,j,k,l].
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>

% Copyright (c) 2013-2020 Donald G. Dansereau

function H = LFRecenterIntrinsics( H, LFSize )

CenterRay = [(LFSize([2,1,4,3])-1)/2 + 1, 1]'; % note indices start at 1
H(1:4,5) = 0;
Decentering = H * CenterRay;
H(1:4,5) = -Decentering(1:4);

end
