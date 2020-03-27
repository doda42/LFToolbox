% Display each of the 6 possible light field tilings
% 
% todo: doc

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function LFDispTilesSubfigs(H, varargin)

subplot(231)
LFDispTiles(H,'stuv',varargin{:});
subplot(234)
LFDispTiles(H,'uvst',varargin{:});
subplot(232)
LFDispTiles(H,'sutv', varargin{:});
subplot(235)
LFDispTiles(H,'tvsu',varargin{:});
subplot(233)
LFDispTiles(H,'svtu',varargin{:});
subplot(236)
LFDispTiles(H,'tusv',varargin{:});
