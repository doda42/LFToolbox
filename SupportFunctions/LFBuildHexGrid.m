% todo[doc]
function [GridCoords] = LFBuildHexGrid( LensletGridModel )

ToOffset = eye(3);
ToOffset(1:2,3) = [LensletGridModel.HOffset, LensletGridModel.VOffset];

R = ToOffset * LFRotz(LensletGridModel.Rot);

[vv,uu] = ndgrid((0:LensletGridModel.VMax-1).*LensletGridModel.VSpacing, (0:LensletGridModel.UMax-1).*LensletGridModel.HSpacing);

uu(LensletGridModel.FirstPosShiftRow:2:end,:) = uu(LensletGridModel.FirstPosShiftRow:2:end,:) + 0.5.*LensletGridModel.HSpacing;

GridCoords = [uu(:), vv(:), ones(numel(vv),1)];
GridCoords = (R*GridCoords')';

GridCoords = reshape(GridCoords(:,1:2), [LensletGridModel.VMax,LensletGridModel.UMax,2]);

end
