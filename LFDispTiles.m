% Tile a 4D light field into a 2D array of 2D slices, and optionally display it to the screen.
%
% Usage: 
%     [Img, XL,YL,XTick,YTick,XLabels,YLabels] = 
%         LFDispTiles( LF, [DimOrder], [BorderSize], [BorderColor], [SubsampRate], [SubsampMethod], [<LFDisp options>] )
% 
% All parameters except LF are optional. If an output argument is assigned, the result is not
% displayed to the screen. 
% 
% Optionally adds BorderWidth pixels with color BorderColor between tiles.
% For asymetric 
% 
% To display asymmetrically dimensioned LFs, it can be useful to subsample along larger dimensions.
% This is done via the SubsampRate and SubsampMethod arguments.
%
% Inputs :
% 
%     LF : a light field to display.
% 
% Optional Inputs :
% 
%            DimOrder : one of 'stuv', 'tvsu', 'sutv', 'uvst', 'svtu', 'tusv'; default 'stuv'.
%
%          BorderSize : How many pixels to insert between tiles; default 0.
% 
%         BorderColor : Color of border pixels; default 0 (mono), [0,0,0] (rgb).
% 
%         SubsampRate : 4D array controlling subsampling in each dimension; 1 means no subsampling,
%                       2 means take every 2 samples, ...; default is no subsampling [1,1,1,1].
%                       SubsampRate is capped to ensure at least two entries remain in each
%                       dimension.
% 
%       SubsampMethod : One of 'skip, 'sum', 'mean', 'max', or 'min'; how the neighbourhood of
%                       pixels skipped via SubsampRate get combined into one sample. 'skip' ignores
%                       all but the selected samples.
% 
%    <LFDisp options> : any additional parameters get passed along to LFDisp
%
% Outputs : 
%
%     Img: A 2D bitmap of the generated image.
% 
%     XL, YL: labels for the x and y axes.
% 
% Examples :
% 
%     LFDispTiles( LF );             % displays LF as u,v slices tiled in s,t
% 
%     LFDispTiles( LF, 'tsvu' );     % displays LF as s,t slices tiled in u,v
% 
%     I = LFDispTiles( LF );         % returns tiling as I, does not display to screen
%     LFDisp( I, 'Renormalize' );    % display I with renormalisation
% 
%     % tile in 'sutv' with default parameters, enable renormalisation in LFDisp
%     LFDispTiles( LF, 'sutv', [],[],[],[] 'Renormalize' );
% 
%     % use a 1-pixel border with colour -1
%     LFDispTiles( LF, 'sutv', 1, -0.1 )
% 
%     % subsample by 4 in u,v using 'max' subsample method
%     LFDispTiles( LF, 'sutv', [], [], [1,1,4,4], 'max' )
% 
% See also: LFDispTilesSubfigs, LFDispProj, LFDispProjSubfigs, LFDispVidCirc, LFDispMousePan

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function [Img, XL,YL,XTick,YTick,XLabels,YLabels] = LFDispTiles( LF, DimOrder, BorderSize, BorderColor, SubsampRate, SubsampMethod, varargin )

DimOrder = LFDefaultVal('DimOrder', 'stuv');
BorderSize = LFDefaultVal('BorderSize', 0);
BorderColor = LFDefaultVal('BorderColor', 0);
SubsampRate = LFDefaultVal('SubsampRate', [1,1,1,1]);
SubsampMethod = LFDefaultVal('SubsampMethod', 'mean');

%---Subsample the LF---
LF = LFSubsamp( LF, SubsampRate, SubsampMethod );

LFSize = size(LF);
TSize = LFSize(1);
SSize = LFSize(2);
VSize = LFSize(3);
USize = LFSize(4);

if( ndims(LF) == 5 )
	Colors = LFSize(5);
else
	Colors = 1;
end

if( length(BorderColor) < Colors )
	BorderColor = BorderColor .* ones(1,Colors);
end

switch lower(DimOrder)
	case 'sutv'
		ImgW = SSize*TSize+(SSize+1)*BorderSize;
		ImgH = USize*VSize+(USize+1)*BorderSize;
		Img = zeros( ImgH, ImgW, Colors, 'like',LF );
		for( i=1:Colors )
			Img(:,:,i) = BorderColor(i);
		end
		for( u=1:USize )
			for( s=1:SSize )
				for( c=1:Colors )
					Img( (u-1)*(VSize+BorderSize)+BorderSize + (1:VSize), (s-1)*(TSize+BorderSize)+BorderSize + (1:TSize), c) = squeeze(LF(:,s,:,u,c))';
				end
			end
		end
		XL = 's';
		YL = 'u';
		x2 = 't';
		y2 = 'v';
		XTick = (0:SSize-1).*(TSize+BorderSize) + (ceil(TSize/2)+BorderSize) + 1;
		YTick = (0:USize-1).*(VSize+BorderSize) + (ceil(VSize/2)+BorderSize) + 1;
		XLabels=(1:SSize);
		YLabels=(1:USize);
		
	case 'tvsu'
		ImgW = SSize*TSize+(TSize+1)*BorderSize;
		ImgH = USize*VSize+(VSize+1)*BorderSize;
		Img = zeros( ImgH, ImgW, Colors, 'like',LF );
		for( i=1:Colors )
			Img(:,:,i) = BorderColor(i);
		end
		for( v=1:VSize )
			for( t=1:TSize )
				for( c=1:Colors )
					Img( (v-1)*(USize+BorderSize)+BorderSize + (1:USize), (t-1)*(SSize+BorderSize)+BorderSize + (1:SSize), c) = squeeze(LF(t,:,v,:,c))';
				end
			end
		end
		XL = 't';
		YL = 'v';
		x2 = 's';
		y2 = 'u';
		XTick = (0:TSize-1).*(SSize+BorderSize) + (ceil(SSize/2)+BorderSize) + 1;
		YTick = (0:VSize-1).*(USize+BorderSize) + (ceil(USize/2)+BorderSize) + 1;
		XLabels=(1:TSize);
		YLabels=(1:VSize);
		
	case 'stuv'
		ImgW = SSize*USize+(SSize+1)*BorderSize;
		ImgH = TSize*VSize+(TSize+1)*BorderSize;
		Img = zeros( ImgH, ImgW, Colors, 'like',LF );
		for( i=1:Colors )
			Img(:,:,i) = BorderColor(i);
		end
		for( t=1:TSize )
			for( s=1:SSize )
				Img( (t-1)*(VSize+BorderSize)+BorderSize + (1:VSize), (s-1)*(USize+BorderSize)+BorderSize + (1:USize), :) = LF(t,s,:,:,:);
			end
		end
		XL = 's';
		YL = 't';
		x2 = 'u';
		y2 = 'v';
		XTick = (0:SSize-1).*(USize+BorderSize) + (ceil(USize/2)+BorderSize) + 1;
		YTick = (0:TSize-1).*(VSize+BorderSize) + (ceil(VSize/2)+BorderSize) + 1;
		XLabels=(1:SSize);
		YLabels=(1:TSize);
		
	case 'uvst'
		ImgW = SSize*USize+(USize+1)*BorderSize;
		ImgH = TSize*VSize+(VSize+1)*BorderSize;
		Img = zeros( ImgH, ImgW, Colors, 'like',LF );
		for( i=1:Colors )
			Img(:,:,i) = BorderColor(i);
		end
		for( v=1:VSize )
			for( u=1:USize )
				Img( (v-1)*(TSize+BorderSize)+BorderSize + (1:TSize), (u-1)*(SSize+BorderSize)+BorderSize + (1:SSize), :) = LF(:,:,v,u,:);
			end
		end
		XL = 'u';
		YL = 'v';
		x2 = 's';
		y2 = 't';
		XTick = (0:USize-1).*(SSize+BorderSize) + (ceil(SSize/2)+BorderSize) + 1;
		YTick = (0:VSize-1).*(TSize+BorderSize) + (ceil(TSize/2)+BorderSize) + 1;
		XLabels=(1:USize);
		YLabels=(1:VSize);
		
	case 'svtu'
		ImgW = TSize*SSize+(SSize+1)*BorderSize;
		ImgH = USize*VSize+(VSize+1)*BorderSize;
		Img = zeros( ImgH, ImgW, Colors, 'like',LF );
		for( i=1:Colors )
			Img(:,:,i) = BorderColor(i);
		end
		for( v=1:VSize )
			for( s=1:SSize )
				for( c=1:Colors )
					Img( (v-1)*(USize+BorderSize)+BorderSize + (1:USize), (s-1)*(TSize+BorderSize)+BorderSize + (1:TSize), c) = squeeze(LF(:,s,v,:,c))';
				end
			end
		end
		XL = 's';
		YL = 'v';
		x2 = 't';
		y2 = 'u';
		XTick = (0:SSize-1).*(TSize+BorderSize) + (ceil(TSize/2)+BorderSize) + 1;
		YTick = (0:VSize-1).*(USize+BorderSize) + (ceil(USize/2)+BorderSize) + 1;
		XLabels=(1:SSize);
		YLabels=(1:VSize);
		
	case 'tusv'
		ImgW = SSize*TSize+(TSize+1)*BorderSize;
		ImgH = VSize*USize+(USize+1)*BorderSize;
		Img = zeros( ImgH, ImgW, Colors, 'like',LF );
		for( i=1:Colors )
			Img(:,:,i) = BorderColor(i);
		end
		for( u=1:USize )
			for( t=1:TSize )
				for( c=1:Colors )
					Img( (u-1)*(VSize+BorderSize)+BorderSize + (1:VSize), (t-1)*(SSize+BorderSize)+BorderSize + (1:SSize), c) = squeeze(LF(t,:,:,u,c))';
				end
			end
		end
		XL = 't';
		YL = 'u';
		x2 = 's';
		y2 = 'v';
		XTick = (0:TSize-1).*(SSize+BorderSize) + (ceil(SSize/2)+BorderSize) + 1;
		YTick = (0:USize-1).*(VSize+BorderSize) + (ceil(VSize/2)+BorderSize) + 1;
		XLabels=(1:TSize);
		YLabels=(1:USize);
		
end

%---Display-----------------------------------------------------------------------------------------
if( nargout < 1 )
	LFDisp(Img, varargin{:});
	
	xlabel(XL);
	ylabel(YL);
	
	set(gca,'xtick', XTick);
	set(gca,'xticklabel', XLabels);
	set(gca,'ytick', YTick);
	set(gca,'yticklabel', YLabels);
	
	clear Img
end
