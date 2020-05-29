%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% original code from KAIST toolbox written by Donghyeon Cho.
%
% modified by Mikael Le Pendu : 19 Aug.2016
%  - adapted inputs/outputs for the LFtoolbox pipeline.
%
% Name   : baryCentric
% Input  : img           - input image
%          height        - image height
%          width         - image width
%          HexShiftStart - 1 => first column (and all odd columns) of
%          lenslets are shifted horizontally by the lenslet radius.
%                          2=> second column (and all even columns) of
%          lenslets are shifted horizontally by the lenslet radius.
%          InterpData    - (optional) pre-computed Delaunay triangulation
%          data. If not given, it will be computed and returned in output.
%
% Output : result     - images
%          InterpData - Data from Delaunay triangulation (to avoid
%          recomputing Delaunay triangulation for next calls).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result,InterpData] = baryCentric(img,height,width,HexShiftStart,InterpData)
    
    % image coordinate
    result = zeros(floor(height*3*sqrt(3)),width*3);
    [indexX, indexY] = meshgrid(1:width*3,1:floor(height*3*sqrt(3)));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if(nargin<5 || isempty(InterpData))
    
        if(nargin<4 || isempty(HexShiftStart)), HexShiftStart=2;end
        
        % hexagonal grid coordinate
        hex_grid1.X = (1+(2-HexShiftStart)*1.5:3:3*width);
        hex_grid1.Y = (1:3*sqrt(3):3*sqrt(3)*height);
        hex_grid2.X = (1+(HexShiftStart-1)*1.5:3:3*width);
        hex_grid2.Y = (sqrt(3)*3/2+1:3*sqrt(3):3*sqrt(3)*height);

        [X1, Y1] = meshgrid(hex_grid1.X,hex_grid1.Y);
        [X2, Y2] = meshgrid(hex_grid2.X,hex_grid2.Y);
        X = [X1(:) ; X2(:)];
        Y = [Y1(:) ; Y2(:)];
        DT = DelaunayTri(X,Y);

        % find nearest pixel in triangle
        CORESP = nearestNeighbor(DT, indexX(:),indexY(:));

        hx_nearest = round((X(CORESP)-1)*2/3)+1;
        hy_nearest = round((Y(CORESP)-1)*2/(3*sqrt(3)/2))+1;

        hx0 = ((indexX(:)-1)*2/3)+1;
        hy0 = ((indexY(:)-1)*2/(3*sqrt(3)/2))+1;

        % 6 neighbor pixels 
        hnx = [hx_nearest-1 hx_nearest+1 hx_nearest+2 hx_nearest+1 hx_nearest-1 hx_nearest-2];
        hny = [hy_nearest-2 hy_nearest-2 hy_nearest hy_nearest+2 hy_nearest+2 hy_nearest];

        % find second nearest neighbor
        dis = sqrt( (hnx-repmat(hx0,[1 6])).^2 + (hny-repmat(hy0,[1 6])).^2);
        [m,  index]= min(dis,[],2);

        tmp_index = index' + 6*[0:length(index)-1];
        hnx1 = hnx';
        hx1 = hnx1(tmp_index)';
        hny1 = hny';
        hy1 = hny1(tmp_index)';

        % find third 
        index1 = mod(index-1+1+6,6)+1;
        index2 = mod(index-1-1+6,6)+1;

        tmp_index1 = index1' + 6*[0:length(index1)-1];
        hnx2 = hnx';
        tmp1_hx2 = hnx2(tmp_index1)';
        hny2 = hny';
        tmp1_hy2 = hny2(tmp_index1)';

        tmp_index2 = index2' + 6*[0:length(index2)-1];
        hnx2 = hnx';
        tmp2_hx2 = hnx2(tmp_index2)';
        hny2 = hny';
        tmp2_hy2 = hny2(tmp_index2)';

        mask = (tmp1_hx2-hx0).^2 + (tmp1_hy2-hy0).^2 >  (tmp2_hx2-hx0).^2 + (tmp2_hy2-hy0).^2 ;

        hx2 = zeros(size(mask));
        hx2(mask) =  tmp2_hx2(mask);
        hx2(~mask) =  tmp1_hx2(~mask);

        hy2 = zeros(size(mask));
        hy2(mask) =  tmp2_hy2(mask);
        hy2(~mask) =  tmp1_hy2(~mask);    

        clear index index1 index2 hnx hny dis maxk tmp_index1 tmp_index2 tmp_index tmp1_hx2 tmp1_hy2 tmp2_hx2 tmp2_hy2

        mask1 = zeros(size(hx1));
        i1 = hx1<=0 | hx1>size(img,2) | hy1<=0 | hy1>size(img,1);
        mask1(i1) = mask1(i1) + 1;
        hx1(i1) = hx2(i1);
        hy1(i1) = hy2(i1);

        i2 = hx2<=0 | hx2>size(img,2) | hy2<=0 | hy2>size(img,1);
        mask1(i2) = mask1(i2) + 1;

        index = sub2ind(size(result),indexY,indexX);

        index1 = mask1 == 0;
        index2 = mask1 == 1;
        index3 = mask1 == 2;   

        lam1 = zeros(size(mask));
        lam2 = zeros(size(mask));
        lam3 = zeros(size(mask));
        lam1(index1) = ( (hy1(index1)-hy2(index1)).*(hx0(index1)-hx2(index1)) + (hx2(index1)-hx1(index1)).*(hy0(index1)-hy2(index1)) ) ./ ( (hy1(index1)-hy2(index1)).*(hx_nearest(index1)-hx2(index1)) + (hx2(index1)-hx1(index1)).*(hy_nearest(index1)-hy2(index1)) );
        lam2(index1) = ( (hy2(index1)-hy_nearest(index1)).*(hx0(index1)-hx2(index1)) + (hx_nearest(index1)-hx2(index1)).*(hy0(index1)-hy2(index1)) ) ./ ( (hy1(index1)-hy2(index1)).*(hx_nearest(index1)-hx2(index1)) + (hx2(index1)-hx1(index1)).*(hy_nearest(index1)-hy2(index1)) );
        lam3(index1) = 1 - lam1(index1) - lam2(index1);

        index = sub2ind(size(result),indexY(index1),indexX(index1));
        p1 = sub2ind(size(img),hy_nearest(index1),hx_nearest(index1));
        p2 = sub2ind(size(img),hy1(index1),hx1(index1));
        p3 = sub2ind(size(img),hy2(index1),hx2(index1));

        if(nargout>1)
            InterpData.mask1 = mask1;
            InterpData.p1 = p1;
            InterpData.p2 = p2;
            InterpData.p3 = p3;
            InterpData.lam1 = lam1;
            InterpData.lam2 = lam2;
            InterpData.lam3 = lam3;
            InterpData.index = index;
            InterpData.hx1 = hx1;
            InterpData.hy1 = hy1;
            InterpData.hx_nearest = hx_nearest;
            InterpData.hy_nearest = hy_nearest;
        end
    else
        index1 = InterpData.mask1 == 0;
        index2 = InterpData.mask1 == 1;
        index3 = InterpData.mask1 == 2;
        
        p1         = InterpData.p1;
        p2         = InterpData.p2;
        p3         = InterpData.p3;
        lam1       = InterpData.lam1;
        lam2       = InterpData.lam2;
        lam3       = InterpData.lam3;
        index      = InterpData.index;
        hx1        = InterpData.hx1;
        hy1        = InterpData.hy1;
        hx_nearest = InterpData.hx_nearest;
        hy_nearest = InterpData.hy_nearest;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    result(index) = lam1(index1).*img(p1) + lam2(index1).*img(p2) + lam3(index1).*img(p3);
    
    index = sub2ind(size(result),indexY(index2),indexX(index2));
    p1 = sub2ind(size(img),hy_nearest(index2),hx_nearest(index2));
    p2 = sub2ind(size(img),hy1(index2),hx1(index2));
    
    result(index) = 0.5.*img(p1) + 0.5.*img(p2);
    
    index = sub2ind(size(result),indexY(index3),indexX(index3));
    p1 = sub2ind(size(img),hy_nearest(index3),hx_nearest(index3));
    
    result(index) = img(p1);
    
end