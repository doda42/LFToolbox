% LFHelperBuild2DFreq - Helper function used to construct 2D frequency-domain filters
%
% Much of the complexity in constructing MD frequency-domain filters, especially around including aliased components and
% controlling the filter rolloff, is common between filter shapes.  This function wraps much of this complexity.
% 
% This gets called by the LFBuild2DFreq* functions.

% Copyright (c) 2013-2020 Donald G. Dansereau

function [H, FiltOptions] = LFHelperBuild2DFreq( LFSize, BW, FiltOptions, DistFunc )

FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single');
FiltOptions = LFDefaultField('FiltOptions', 'Rolloff', 'Gaussian'); %Gaussian or Butter
FiltOptions = LFDefaultField('FiltOptions', 'Aspect2D', 1);
FiltOptions = LFDefaultField('FiltOptions', 'Window', false);
FiltOptions = LFDefaultField('FiltOptions', 'Extent2D', 1.0);
FiltOptions = LFDefaultField('FiltOptions', 'IncludeAliased', false);

FiltOptions.Extent2D = cast(FiltOptions.Extent2D, FiltOptions.Precision); % avoid rounding error during comparisons
FiltOptions.Aspect2D = cast(FiltOptions.Aspect2D, FiltOptions.Precision); % avoid rounding error during comparisons

if( length(LFSize) == 1 )
	LFSize = LFSize .* [1,1];
end
if( length(FiltOptions.Extent2D) == 1 )
	FiltOptions.Extent2D = FiltOptions.Extent2D .* [1,1];
end
if( length(FiltOptions.Aspect2D) == 1 )
	FiltOptions.Aspect2D = FiltOptions.Aspect2D .* [1,1];
end
ExtentWithAspect = FiltOptions.Extent2D.*FiltOptions.Aspect2D / 2;

s = LFNormalizedFreqAxis( LFSize(1), FiltOptions.Precision ) .* FiltOptions.Aspect2D(1);
u = LFNormalizedFreqAxis( LFSize(2), FiltOptions.Precision ) .* FiltOptions.Aspect2D(2);
[ss,uu] = ndgrid(s,u);
P = [ss(:),uu(:)]';
clear s u ss uu

if( ~FiltOptions.IncludeAliased )
	Tiles = [0,0];
else
	Tiles = ceil(ExtentWithAspect);
end

if( FiltOptions.IncludeAliased )
	AADist = inf(LFSize, FiltOptions.Precision);
end
WinDist = 0;

% Tiling proceeds only in positive directions, symmetry is enforced afterward, saving some computation overall
for( STile = 0:Tiles(1) )
	for( UTile = 0:Tiles(2) )
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
		
		P(2,:) = P(2,:) + FiltOptions.Aspect2D(2);
	end
	P(2,:) = P(2,:) - (Tiles(2)+1) .* FiltOptions.Aspect2D(2);
	P(1,:) = P(1,:) + FiltOptions.Aspect2D(1);
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
		H(:) = sinc(Dist); % sinc-shaped rolloff, sinc function is in the signal processing toolbox
		
	otherwise
		error('unrecognized rolloff method');

end

H = ifftshift(H);

% force symmetric
H = max(H, H(mod(LFSize(1):-1:1,LFSize(1))+1, mod(LFSize(2):-1:1,LFSize(2))+1));

% todo: confirm this is sufficient
