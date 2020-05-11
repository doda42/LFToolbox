% LFDispTiles - Tile a 4D light field into a 2D array of 2D slices, optionally display to the screen
%
% Usage: 
% 
%     LFDispTiles( LF )
%     [Img, XAxisLabel, YAxisLabel, XTicks, YTicks, XTickLabels, YTickLabels] = 
%         LFDispTiles( LF, [DimOrder], [RenderOptions], [<LFDisp options>] )
% 
% All parameters except LF are optional. If an output argument is assigned, the result is not
% displayed to the screen. 
% 
% Optionally adds RenderOptions.BorderWidth pixels with color RenderOptions.BorderColor between
% tiles. 
% 
% To display asymmetrically dimensioned LFs, it can be useful to subsample along larger dimensions.
% This is done via the RenderOptions.SubsampRate and RenderOptions.SubsampMethod arguments.
%
% Inputs :
% 
%    LF : a light field to display.
% 
% Optional Inputs :
% 
%    RenderOptions : struct controlling rendering
% 
%           .DimOrder : one of 'stuv', 'tvsu', 'sutv', 'uvst', 'svtu', 'tusv'; default 'stuv'.
%
%         .BorderSize : How many pixels to insert between tiles; default 0.
% 
%        .BorderColor : Color of border pixels; default 0 (mono), [0,0,0] (rgb).
% 
%        .SubsampRate : 1D value or 4D array controlling subsampling in each dimension; 1 means no
%                       subsampling, 2 means take every 2 samples, ...; default is no subsampling. A
%                       1D value is applied to all four dimensions; a 4D vector is in the order
%                       [t,s,v,u]. SubsampRate is capped to ensure at least two entries remain in
%                       each dimension.
% 
%      .SubsampMethod : One of 'skip, 'sum', 'mean', 'max', or 'min'; how the neighbourhood of
%                       pixels skipped via SubsampRate get combined into one sample. 'skip' ignores
%                       all but the selected samples. Default: skip.
% 
%    <LFDisp options> : any additional parameters get passed along to LFDisp
%
% Outputs : 
%
%     Img: A 2D bitmap of the generated image
% 
%     XAxisLabel, YAxisLabel: labels for the x and y axes
% 
%     XTicks, YTicks: positions for the x and y tickmarks
% 
%     XTickLabel, YTickLabels: labels for the x and y tickmarks
% 
% Examples :
% 
%     LFDispTiles( LF );             % displays LF as u,v slices tiled in s,t
% 
%     LFDispTiles( LF, 'uvst' );     % displays LF as s,t slices tiled in u,v
% 
%     I = LFDispTiles( LF );         % returns tiling as I, does not display to screen
%     LFDisp( I, 'Renormalize' );    % display I with renormalisation
% 
%     % tile in 'stuv' with default parameters, enable renormalisation in LFDisp
%     LFDispTiles( LF, [], [], 'Renormalize' );
% 
%     % use a 20-pixel border with white colour
%     LFDispTiles( LF, [], struct('BorderSize', 20, 'BorderColor', 1 ))
% 
%     % subsample by 2 in s,t using default subsamp method
%     LFDispTiles( LF, [], struct('SubsampRate',[2,2,1,1]))
% 
%     % display as s,t tiles in u,v, subsampling by 10 in u,v 
%     LFDispTiles( LF, 'uvst', struct('SubsampRate',[1,1,10,10]))
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDispTilesSubfigs, LFDisp, LFDispMousePan, LFDispVidCirc, LFDispLawnmower, LFDispProj

% Copyright (c) 2012-2020 Donald G. Dansereau

% todo[refactoring]: whole function could use refactoring, updating to use recent matlab tricks

function [Img, XAxisLabel,YAxisLabel,XTicks,YTicks,XTickLabels,YTickLabels] = ...
	LFDispTiles( LF, DimOrder, RenderOptions, varargin )

DimOrder = LFDefaultVal('DimOrder', 'stuv');
RenderOptions = LFDefaultField('RenderOptions','BorderSize', 0);
RenderOptions = LFDefaultField('RenderOptions','BorderColor', 0);
RenderOptions = LFDefaultField('RenderOptions','SubsampRate', [1,1,1,1]);
RenderOptions = LFDefaultField('RenderOptions','SubsampMethod', 'skip');

%---Subsample the LF---
[LF, SampGrid] = LFSubsamp( LF, RenderOptions.SubsampRate, RenderOptions.SubsampMethod );

LFSize = size(LF);
TSize = LFSize(1);
SSize = LFSize(2);
VSize = LFSize(3);
USize = LFSize(4);

if( ndims(LF) == 5 )
	NChans = LFSize(5);
else
	NChans = 1;
end

if( length(RenderOptions.BorderColor) < NChans )
	RenderOptions.BorderColor = RenderOptions.BorderColor .* ones(1,NChans);
end

switch lower(DimOrder)
	case 'sutv'
		ImgW = SSize*TSize+(SSize+1)*RenderOptions.BorderSize;
		ImgH = USize*VSize+(USize+1)*RenderOptions.BorderSize;
		Img = zeros( ImgH, ImgW, NChans, 'like',LF );
		for( i=1:NChans )
			Img(:,:,i) = RenderOptions.BorderColor(i);
		end
		for( u=1:USize )
			for( s=1:SSize )
				for( c=1:NChans )
					Img( (u-1)*(VSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:VSize), (s-1)*(TSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:TSize), c) = squeeze(LF(:,s,:,u,c))';
				end
			end
		end
		XAxisLabel = 's';
		YAxisLabel = 'u';
		x2 = 't';
		y2 = 'v';
		XTicks = (0:SSize-1).*(TSize+RenderOptions.BorderSize) + (ceil(TSize/2)+RenderOptions.BorderSize) + 1;
		YTicks = (0:USize-1).*(VSize+RenderOptions.BorderSize) + (ceil(VSize/2)+RenderOptions.BorderSize) + 1;
		XTickLabels=SampGrid.SVec;
		YTickLabels=SampGrid.UVec;
		
	case 'tvsu'
		ImgW = SSize*TSize+(TSize+1)*RenderOptions.BorderSize;
		ImgH = USize*VSize+(VSize+1)*RenderOptions.BorderSize;
		Img = zeros( ImgH, ImgW, NChans, 'like',LF );
		for( i=1:NChans )
			Img(:,:,i) = RenderOptions.BorderColor(i);
		end
		for( v=1:VSize )
			for( t=1:TSize )
				for( c=1:NChans )
					Img( (v-1)*(USize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:USize), (t-1)*(SSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:SSize), c) = squeeze(LF(t,:,v,:,c))';
				end
			end
		end
		XAxisLabel = 't';
		YAxisLabel = 'v';
		x2 = 's';
		y2 = 'u';
		XTicks = (0:TSize-1).*(SSize+RenderOptions.BorderSize) + (ceil(SSize/2)+RenderOptions.BorderSize) + 1;
		YTicks = (0:VSize-1).*(USize+RenderOptions.BorderSize) + (ceil(USize/2)+RenderOptions.BorderSize) + 1;
		XTickLabels=SampGrid.TVec;
		YTickLabels=SampGrid.VVec;
		
	case 'stuv'
		ImgW = SSize*USize+(SSize+1)*RenderOptions.BorderSize;
		ImgH = TSize*VSize+(TSize+1)*RenderOptions.BorderSize;
		Img = zeros( ImgH, ImgW, NChans, 'like',LF );
		for( i=1:NChans )
			Img(:,:,i) = RenderOptions.BorderColor(i);
		end
		for( t=1:TSize )
			for( s=1:SSize )
				Img( (t-1)*(VSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:VSize), (s-1)*(USize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:USize), :) = LF(t,s,:,:,:);
			end
		end
		XAxisLabel = 's';
		YAxisLabel = 't';
		x2 = 'u';
		y2 = 'v';
		XTicks = (0:SSize-1).*(USize+RenderOptions.BorderSize) + (ceil(USize/2)+RenderOptions.BorderSize) + 1;
		YTicks = (0:TSize-1).*(VSize+RenderOptions.BorderSize) + (ceil(VSize/2)+RenderOptions.BorderSize) + 1;
		XTickLabels=SampGrid.SVec;
		YTickLabels=SampGrid.TVec;
		
	case 'uvst'
		ImgW = SSize*USize+(USize+1)*RenderOptions.BorderSize;
		ImgH = TSize*VSize+(VSize+1)*RenderOptions.BorderSize;
		Img = zeros( ImgH, ImgW, NChans, 'like',LF );
		for( i=1:NChans )
			Img(:,:,i) = RenderOptions.BorderColor(i);
		end
		for( v=1:VSize )
			for( u=1:USize )
				Img( (v-1)*(TSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:TSize), (u-1)*(SSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:SSize), :) = LF(:,:,v,u,:);
			end
		end
		XAxisLabel = 'u';
		YAxisLabel = 'v';
		x2 = 's';
		y2 = 't';
		XTicks = (0:USize-1).*(SSize+RenderOptions.BorderSize) + (ceil(SSize/2)+RenderOptions.BorderSize) + 1;
		YTicks = (0:VSize-1).*(TSize+RenderOptions.BorderSize) + (ceil(TSize/2)+RenderOptions.BorderSize) + 1;
		XTickLabels=SampGrid.UVec;
		YTickLabels=SampGrid.VVec;
		
	case 'svtu'
		ImgW = TSize*SSize+(SSize+1)*RenderOptions.BorderSize;
		ImgH = USize*VSize+(VSize+1)*RenderOptions.BorderSize;
		Img = zeros( ImgH, ImgW, NChans, 'like',LF );
		for( i=1:NChans )
			Img(:,:,i) = RenderOptions.BorderColor(i);
		end
		for( v=1:VSize )
			for( s=1:SSize )
				for( c=1:NChans )
					Img( (v-1)*(USize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:USize), (s-1)*(TSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:TSize), c) = squeeze(LF(:,s,v,:,c))';
				end
			end
		end
		XAxisLabel = 's';
		YAxisLabel = 'v';
		x2 = 't';
		y2 = 'u';
		XTicks = (0:SSize-1).*(TSize+RenderOptions.BorderSize) + (ceil(TSize/2)+RenderOptions.BorderSize) + 1;
		YTicks = (0:VSize-1).*(USize+RenderOptions.BorderSize) + (ceil(USize/2)+RenderOptions.BorderSize) + 1;
		XTickLabels=SampGrid.SVec;
		YTickLabels=SampGrid.VVec;
		
	case 'tusv'
		ImgW = SSize*TSize+(TSize+1)*RenderOptions.BorderSize;
		ImgH = VSize*USize+(USize+1)*RenderOptions.BorderSize;
		Img = zeros( ImgH, ImgW, NChans, 'like',LF );
		for( i=1:NChans )
			Img(:,:,i) = RenderOptions.BorderColor(i);
		end
		for( u=1:USize )
			for( t=1:TSize )
				for( c=1:NChans )
					Img( (u-1)*(VSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:VSize), (t-1)*(SSize+RenderOptions.BorderSize)+RenderOptions.BorderSize + (1:SSize), c) = squeeze(LF(t,:,:,u,c))';
				end
			end
		end
		XAxisLabel = 't';
		YAxisLabel = 'u';
		x2 = 's';
		y2 = 'v';
		XTicks = (0:TSize-1).*(SSize+RenderOptions.BorderSize) + (ceil(SSize/2)+RenderOptions.BorderSize) + 1;
		YTicks = (0:USize-1).*(VSize+RenderOptions.BorderSize) + (ceil(VSize/2)+RenderOptions.BorderSize) + 1;
		XTickLabels=SampGrid.TVec;
		YTickLabels=SampGrid.UVec;
		
end

%---Display-----------------------------------------------------------------------------------------
if( nargout < 1 )
	LFDisp(Img, varargin{:});
	
	xlabel(XAxisLabel);
	ylabel(YAxisLabel);
	
	set(gca,'xtick', XTicks);
	set(gca,'xticklabel', XTickLabels);
	set(gca,'ytick', YTicks);
	set(gca,'yticklabel', YTickLabels);
	
	clear Img
end
