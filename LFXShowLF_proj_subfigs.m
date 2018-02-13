% Display each of the 6 possible 2D light field projections

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function LFXShowLF_proj_subfigs(H, varargin)

subplot(231)
LFXShowLF_proj(H,3,4,varargin{:});
subplot(234)
LFXShowLF_proj(H,1,2,varargin{:});
subplot(232)
LFXShowLF_proj(H,2,4, varargin{:});
subplot(235)
LFXShowLF_proj(H,1,3,varargin{:});
subplot(233)
LFXShowLF_proj(H,2,3,varargin{:});
subplot(236)
LFXShowLF_proj(H,1,4,varargin{:});
