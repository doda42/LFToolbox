% LFDispTilesSubfigs - Build six subfigures dispaying 2D x 2D tilings of the LF
% 
% Usage: 
%     LFDispTileSubfigs(  LF, [<LFDispTiles options>]  )
% 
% Inputs:
% 
%     LF: Light field to display
%
% Optional Inputs:
% 
%     <LFDispTiles options>: any additional options get passed along to LFDispTiles
% 
% Examples:
% 
%     LFDispTileSubfigs(  LF  );          % displays 6 tilings of the LF with default parameters
% 
%     LFDispTilesSubfigs(  LF, 1, -0.1  ); % ... uses a border size of 1 and color -1
% 
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDispTiles, LFDisp, LFDispMousePan, LFDispVidCirc, LFDispLawnmower, LFDispProj

% Copyright ( C ) 2012-2018 by Donald G. Dansereau

function LFDispTilesSubfigs( LF, varargin )

subplot( 231 )
LFDispTiles( LF, 'stuv', varargin{:} );

subplot( 234 )
LFDispTiles( LF, 'uvst', varargin{:} );

subplot( 232 )
LFDispTiles( LF, 'sutv',  varargin{:} );

subplot( 235 )
LFDispTiles( LF, 'tvsu', varargin{:} );

subplot( 233 )
LFDispTiles( LF, 'svtu', varargin{:} );

subplot( 236 )
LFDispTiles( LF, 'tusv', varargin{:} );
