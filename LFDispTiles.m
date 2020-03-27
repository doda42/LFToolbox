% Display a 4D light field as a tiling of slices
% Order is one of 'sutv', 'stuv', 'tvsu' or 'sutv', 'svtu', or 'tusv'.

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function [Img, x1,y1,XTick,YTick,XLabels,YLabels] = LFXShowLF_tiles( LF, Order, BorderSize, BorderColor, FoldingRate, FoldingMethod )

BorderSize = LFDefaultVal('BorderSize', []);
BorderColor = LFDefaultVal('BorderColor', []);
FoldingRate = LFDefaultVal('FoldingRate', []);
FoldingMethod = LFDefaultVal('FoldingMethod', []);

[Img, x1,y1,XTick,YTick,XLabels,YLabels] = LFXBuildLFTiles( LF, Order, BorderSize, BorderColor, FoldingRate, FoldingMethod );

if( nargout < 1 )
    LFDisp(Img);
    
    xlabel(x1);
    ylabel(y1);
    
    set(gca,'xtick', XTick);
    set(gca,'xticklabel', XLabels);
    set(gca,'ytick', YTick);
    set(gca,'yticklabel', YLabels);
	
	clear Img
end