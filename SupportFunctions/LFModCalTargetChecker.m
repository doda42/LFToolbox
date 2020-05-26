function IdealChecker = LFModCalTargetChecker( CalOptions )

IdealCheckerX = CalOptions.ExpectedCheckerSpacing_m(1) .* (0:CalOptions.ExpectedCheckerSize(1)-1);
IdealCheckerY = CalOptions.ExpectedCheckerSpacing_m(2) .* (0:CalOptions.ExpectedCheckerSize(2)-1);
[IdealCheckerY, IdealCheckerX] = ndgrid(IdealCheckerY, IdealCheckerX);
IdealChecker = cat(3,IdealCheckerX, IdealCheckerY, zeros(size(IdealCheckerX)));
IdealChecker = reshape(IdealChecker, [], 3)';
