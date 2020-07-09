% todo[doc]
function CurChecker = LFCheckerFixOrient( CurChecker, CalOptions )

assert(size(CurChecker,1) == 2);

Centroid = mean( CurChecker,2 );
IsTopLeft = all(CurChecker(:,1) < Centroid);
IsTopRight = (CurChecker(1,1) > Centroid(1) && CurChecker(2,1) < Centroid(2));
IsBotLeft = (CurChecker(1,1) < Centroid(1) && CurChecker(2,1) > Centroid(2));
IsBotRight = all(CurChecker(:,1) > Centroid);
if( IsTopRight )
	CurChecker = reshape(CurChecker, [2, CalOptions.ExpectedCheckerSize]);
	CurChecker = CurChecker(:, end:-1:1, :);
	CurChecker = permute(CurChecker, [1,3,2]);
	CurChecker = reshape(CurChecker, 2, []);
elseif( IsBotLeft )
	CurChecker = reshape(CurChecker, [2, CalOptions.ExpectedCheckerSize]);
	CurChecker = CurChecker(:, :, end:-1:1);
	CurChecker = permute(CurChecker, [1,3,2]);
	CurChecker = reshape(CurChecker, 2, []);
elseif( IsBotRight )
	CurChecker = reshape(CurChecker, [2, CalOptions.ExpectedCheckerSize]);
	CurChecker = CurChecker(:, end:-1:1, end:-1:1);
	CurChecker = reshape(CurChecker, 2, []);
end
IsTopLeft = all(CurChecker(:,1) < Centroid);
assert( IsTopLeft, 'Error: unexpected point order from detectCheckerboardPoints' );
