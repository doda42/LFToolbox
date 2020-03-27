% Display each of the 6 possible light field tilings

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function LFXShowLF_subfigs(H, varargin)

subplot(231)
LFXShowLF_tiles(H,'stuv',varargin{:});
subplot(234)
LFXShowLF_tiles(H,'uvst',varargin{:});
subplot(232)
LFXShowLF_tiles(H,'sutv', varargin{:});
subplot(235)
LFXShowLF_tiles(H,'tvsu',varargin{:});
subplot(233)
LFXShowLF_tiles(H,'svtu',varargin{:});
subplot(236)
LFXShowLF_tiles(H,'tusv',varargin{:});
