% LFHelperBuild4DFreq - Helper function used to construct 4D frequency-domain filters
%
% Much of the complexity in constructing MD frequency-domain filters, especially around including
% aliased components and controlling the filter rolloff, is common between filter shapes.  This
% function wraps much of this complexity.
% 
% This gets called by the LFBuild4DFreq* functions.

% Copyright (c) 2013-2020 Donald G. Dansereau

function [H, FiltOptions] = LFHelperBuild4DFreq( LFSize, BW, FiltOptions, DistFunc )

FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single');
FiltOptions = LFDefaultField('FiltOptions', 'Rolloff', 'Gaussian'); %Gaussian or Butter
FiltOptions = LFDefaultField('FiltOptions', 'Aspect4D', 1);
FiltOptions = LFDefaultField('FiltOptions', 'Window', false);
FiltOptions = LFDefaultField('FiltOptions', 'Extent4D', 1.0);
FiltOptions = LFDefaultField('FiltOptions', 'IncludeAliased', false);

% avoid rounding error during comparisons
FiltOptions.Extent4D = cast(FiltOptions.Extent4D, FiltOptions.Precision); 
FiltOptions.Aspect4D = cast(FiltOptions.Aspect4D, FiltOptions.Precision);

if( length(LFSize) == 1 )
	LFSize = LFSize .* [1,1,1,1];
end
if( length(LFSize) == 5 )
	LFSize = LFSize(1:4);
end
if( length(FiltOptions.Extent4D) == 1 )
	FiltOptions.Extent4D = FiltOptions.Extent4D .* [1,1,1,1];
end
if( length(FiltOptions.Aspect4D) == 1 )
	FiltOptions.Aspect4D = FiltOptions.Aspect4D .* [1,1,1,1];
end
ExtentWithAspect = FiltOptions.Extent4D.*FiltOptions.Aspect4D / 2;

t = LFNormalizedFreqAxis( LFSize(1), FiltOptions.Precision ) .* FiltOptions.Aspect4D(1);
s = LFNormalizedFreqAxis( LFSize(2), FiltOptions.Precision ) .* FiltOptions.Aspect4D(2);
v = LFNormalizedFreqAxis( LFSize(3), FiltOptions.Precision ) .* FiltOptions.Aspect4D(3);
u = LFNormalizedFreqAxis( LFSize(4), FiltOptions.Precision ) .* FiltOptions.Aspect4D(4);
[tt,ss,vv,uu] = ndgrid(cast(t,FiltOptions.Precision),cast(s,FiltOptions.Precision), ...
	cast(v,FiltOptions.Precision),cast(u,FiltOptions.Precision));
P = [tt(:),ss(:),vv(:),uu(:)]';
clear s t u v ss tt uu vv

if( ~FiltOptions.IncludeAliased )
	Tiles = [0,0,0,0];
else
	Tiles = ceil(ExtentWithAspect) % todo[optimization]: optimization possible for large extents
end

if( FiltOptions.IncludeAliased )
	AADist = inf(LFSize, FiltOptions.Precision);
end
WinDist = 0;

% Tiling proceeds only in positive directions, symmetry is enforced afterward, saving some computation overall
for( TTile = 0:Tiles(1) )
	for( STile = 0:Tiles(2) )
		for( VTile = 0:Tiles(3) )
			for( UTile = 0:Tiles(4) )
				Dist = inf(LFSize, FiltOptions.Precision);
				
				if( FiltOptions.Window )
					ValidIdx = ':';
					WinDist = bsxfun(@minus, abs(P)', ExtentWithAspect);
					WinDist = sum(max(0,WinDist).^2, 2);
					WinDist = reshape(WinDist, LFSize);
				else
					ValidIdx = find(all(bsxfun(@le, abs(P), ExtentWithAspect')));
				end
				
				Dist(ValidIdx) = DistFunc(P(:,ValidIdx), FiltOptions);
				Dist = Dist + WinDist;
				
				if( FiltOptions.IncludeAliased )
					AADist(:) = min(AADist(:), Dist(:));
				end
				
				P(4,:) = P(4,:) + FiltOptions.Aspect4D(4);
			end
			P(4,:) = P(4,:) - (Tiles(4)+1) .* FiltOptions.Aspect4D(4);
			P(3,:) = P(3,:) + FiltOptions.Aspect4D(3);
		end
		P(3,:) = P(3,:) - (Tiles(3)+1) .* FiltOptions.Aspect4D(3);
		P(2,:) = P(2,:) + FiltOptions.Aspect4D(2);
	end
	P(2,:) = P(2,:) - (Tiles(2)+1) .* FiltOptions.Aspect4D(2);
	P(1,:) = P(1,:) + FiltOptions.Aspect4D(1);
end

if( FiltOptions.IncludeAliased )
	Dist = AADist;
	clear AADist
end

H = zeros(LFSize, FiltOptions.Precision);

switch lower(FiltOptions.Rolloff)
	
	case 'gaussian'
		BW = BW.^2 / log(sqrt(2));
		H(:) = exp( -Dist / BW );  % Gaussian rolloff
		
	case 'butter'
		FiltOptions = LFDefaultField('FiltOptions', 'Order', 3);
		Dist = sqrt(Dist) ./ BW;
		H(:) = sqrt( 1.0 ./ (1.0 + Dist.^(2*FiltOptions.Order)) ); % Butterworth-like rolloff

	case 'sinc'
		Dist = sqrt(Dist) ./ BW;
		H(:) = sinc(Dist); % sinc-shaped rolloff
		
	otherwise
		error('unrecognized rolloff method');
		
end

H = ifftshift(H);

% force symmetric -- needed to visualize in 4D to get this one right
H = max(H, H(mod(LFSize(1):-1:1,LFSize(1))+1, mod(LFSize(2):-1:1,LFSize(2))+1, ...
	mod(LFSize(3):-1:1,LFSize(3))+1, mod(LFSize(4):-1:1,LFSize(4))+1));
H = max(H, H(:, mod(LFSize(2):-1:1,LFSize(2))+1, :, mod(LFSize(4):-1:1,LFSize(4))+1));
H = max(H, H(mod(LFSize(1):-1:1,LFSize(1))+1, :, mod(LFSize(3):-1:1,LFSize(3))+1, :));
% todo: confirm this is sufficient
