% Builds a 2D tiling of 2D images
% Order is one of 'sutv', 'stuv', 'tvsu' or 'sutv', 'svtu', or 'tusv'

% Part of LF Toolbox xxxVersionTagxxx
% Copyright (C) 2012-2018 by Donald G. Dansereau

function [Img, x1,y1,XTick,YTick,XLabels,YLabels] = LFXBuildLFTiles( LF, Order, BorderSize, BorderColor, FoldingRate, FoldingMethod )

BorderSize = LFDefaultVal('BorderSize', 0);
BorderColor = LFDefaultVal('BorderColor', 0);
FoldingRate = LFDefaultVal('FoldingRate', [1,1,1,1]);
FoldingMethod = LFDefaultVal('FoldingMethod', 'sum');

%---Fold the LF taking sum or max---
LF = LFXResampLF( LF, FoldingRate, FoldingMethod );

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

switch lower(Order)
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
		x1 = 's'; 
		y1 = 'u';
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
		x1 = 't';
		y1 = 'v';
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
		x1 = 's';
		y1 = 't';
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
		x1 = 'u';
		y1 = 'v';
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
		x1 = 's';
		y1 = 'v';
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
		x1 = 't';
		y1 = 'u';
		x2 = 's';
		y2 = 'v';
        XTick = (0:TSize-1).*(SSize+BorderSize) + (ceil(SSize/2)+BorderSize) + 1;
        YTick = (0:USize-1).*(VSize+BorderSize) + (ceil(VSize/2)+BorderSize) + 1;
        XLabels=(1:TSize);
        YLabels=(1:USize);
		
end
