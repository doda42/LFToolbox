% todo: doc
% LFCalInit - initialize calibration estimate, called by LFUtilCalLensletCam
%
% Usage: 
%     CalOptions = LFCalInit( FileOptions, CalOptions )
%     CalOptions = LFCalInit( FileOptions )
%
% This function is called by LFUtilCalLensletCam to initialize a pose and camera model estimate
% given a set of extracted checkerboard corners.
% 
% Inputs:
% 
%     FileOptions : struct controlling file locations
%       .WorkingPath : Path to folder containing processed checkerboard images. Checkerboard corners must
%                      be identified prior to calling this function, by running LFCalFindCheckerCorners
%                      for example. This is demonstrated by LFUtilCalLensletCam.
% 
%     [optional] CalOptions : struct controlling calibration parameters, all fields are optional
%                   .SaveResult : Set to false to perform a "dry run"
%            .FeatsFnamePattern : Pattern for finding checkerboard corner files, as generated by
%                                 LFCalFindCheckerCorners; %s is a placeholder for the base filename
%             .CheckerInfoFname : Name of the output file containing the summarized checkerboard
%                                 information
%                 .CalInfoFname : Name of the file containing an initial estimate, to be refined.
%                                 Note that this parameter is automatically set in the CalOptions
%                                 struct returned by LFCalInit
%                .ForceRedoInit : Forces the function to overwrite existing results
%
% Outputs :
% 
%     CalOptions struct as applied, including any default values as set up by the function.
% 
%     The checkerboard info file and calibration info file are the key outputs of this function.
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also:  LFUtilCalLensletCam, LFCalFindCheckerCorners, LFCalRefine

% Copyright (c) 2013-2020 Donald G. Dansereau

function CalOptions = HD_CalInit( FileOptions, CalOptions )

CalOptions = LFDefaultField( 'CalOptions', 'AllFeatsFname', 'AllFeats.mat' );

%---Defaults---
CalOptions = LFDefaultField( 'CalOptions', 'CalInfoFname', 'ModCalInfo.json' );
CalOptions = LFDefaultField( 'CalOptions', 'ForceRedoInit', false );

%---Start by checking if this step has already been completed---
fprintf('\n===Initializing calibration process===\n');
CalInfoSaveFname = fullfile(FileOptions.WorkingPath, CalOptions.CalInfoFname);
if( ~CalOptions.ForceRedoInit && exist(CalInfoSaveFname, 'file') )
    fprintf(' ---File %s exists, already initialized, skipping---\n', CalInfoSaveFname);
    return;
end

%---Load feature observations---
AllFeatsFile = fullfile(FileOptions.WorkingPath, CalOptions.AllFeatsFname);
load( AllFeatsFile, 'AllFeatObs', 'LFSize', 'LFMetadata', 'CamInfo' );

%---Initial estimate of focal length---

% setup t,s index ranges
TVec = (1+CalOptions.LensletBorderSize):(size(AllFeatObs,2)-CalOptions.LensletBorderSize);
SVec = (1+CalOptions.LensletBorderSize):(size(AllFeatObs,3)-CalOptions.LensletBorderSize);

%---Compute homography for each subcam pose---
fprintf('Initial estimate of focal length...\n');
ValidFeatCount = 0;
for( iFile = 1:length(CalOptions.FileList) )
    for( TIdx = TVec )
        for( SIdx = SVec )
			CurFeatObs = AllFeatObs{iFile, TIdx, SIdx};
			if( ~isempty(CurFeatObs) )
				CurFeatObs = CurFeatObs(3:4,:);
				ValidFeatCount = ValidFeatCount + 1;			
				%---Compute homography for each subcam pose---
				% todo[optimisation]: for non-square decode, better performance in single-FocLen est
				% if we adjusted CurFeatObs based on DecodeOptions.OutputScale:
				%
				% DecodeAspectRatio = LFMetadata.DecodeOptions.OutputScale(4) / LFMetadata.DecodeOptions.OutputScale(3);
				% CurFeatObs(2,:) = CurFeatObs(2,:) .* DecodeAspectRatio;
				% 
				% Also adjust centering CInit, below				
				CurH = compute_homography( CurFeatObs, CalOptions.CalTarget(1:2,:) );
				H(ValidFeatCount, :,:) = CurH;
			end
        end
    end
    fprintf('.');
end
fprintf('\n');

A = [];
b = [];

%---Initialize principal point at the center of the image---
% This section of code is based heavily on code from the Camera Calibration Toolbox for Matlab by
% Jean-Yves Bouguet
LFSizeAdjusted = LFSize;
% LFSizeAdjusted(3) = LFSizeAdjusted(3) .* DecodeAspectRatio;
CInit = LFSizeAdjusted([4,3])'/2 - 0.5;
RecenterH = [1, 0, -CInit(1); 0, 1, -CInit(2); 0, 0, 1];

for iHomography = 1:size(H,1)
    CurH = squeeze(H(iHomography,:,:));
    CurH = RecenterH * CurH;
     
    %---Extract vanishing points (direct and diagonal)---
    V_hori_pix = CurH(:,1);
    V_vert_pix = CurH(:,2);
    V_diag1_pix = (CurH(:,1)+CurH(:,2))/2;
    V_diag2_pix = (CurH(:,1)-CurH(:,2))/2;
    
    V_hori_pix = V_hori_pix/norm(V_hori_pix);
    V_vert_pix = V_vert_pix/norm(V_vert_pix);
    V_diag1_pix = V_diag1_pix/norm(V_diag1_pix);
    V_diag2_pix = V_diag2_pix/norm(V_diag2_pix);
    
    a1 = V_hori_pix(1);
    b1 = V_hori_pix(2);
    c1 = V_hori_pix(3);
    
    a2 = V_vert_pix(1);
    b2 = V_vert_pix(2);
    c2 = V_vert_pix(3);
    
    a3 = V_diag1_pix(1);
    b3 = V_diag1_pix(2);
    c3 = V_diag1_pix(3);
    
    a4 = V_diag2_pix(1);
    b4 = V_diag2_pix(2);
    c4 = V_diag2_pix(3);
    
    CurA = [a1*a2, b1*b2; a3*a4, b3*b4];
    CurB = -[c1*c2; c3*c4];

    if( isempty(find(isnan(CurA), 1)) && isempty(find(isnan(CurB), 1)) )
        A = [A; CurA];
        b = [b; CurB];
    end
end

FocInit = sqrt(b'*(sum(A')') / (b'*b)) * ones(2,1); % try single-focal model for initial guess

InvalidSingleFocEst = (b'*(sum(A')') < 0) || any(imag(FocInit) ~= 0);
if( InvalidSingleFocEst )
	fprintf('Estimating independent horz, vertical focal lengths\n');
	FocInit = sqrt(abs(1./(inv(A'*A)*A'*b))); % fall back to two-focal model for initial guess
end
fprintf('Init focal length est: %.2f, %.2f\n', FocInit);

%---Initial estimate of extrinsics---
fprintf('\nInitial estimate of extrinsics...\n');

ValidSuperPoseCount = size(AllFeatObs,1);
for( iSuperPoseIdx = 1:ValidSuperPoseCount )
    fprintf('---[%d / %d]', iSuperPoseIdx, ValidSuperPoseCount);
    for( TIdx = TVec )  
        fprintf('.');
        for( SIdx = SVec ) 
            CurFeatObs = AllFeatObs{iSuperPoseIdx, TIdx, SIdx};
            if( isempty(CurFeatObs) )
                continue;
			end
			CurFeatObs = CurFeatObs(3:4,:);
			
            [CurRot, CurTrans] = compute_extrinsic_init(CurFeatObs, CalOptions.CalTarget, FocInit, CInit, zeros(1,5), 0);
            [CurRot, CurTrans] = compute_extrinsic_refine(CurRot, CurTrans, CurFeatObs, CalOptions.CalTarget, FocInit, CInit, zeros(1,5), 0,20,1000000);
            
            RotVals{iSuperPoseIdx, TIdx, SIdx} = CurRot;
            TransVals{iSuperPoseIdx, TIdx, SIdx} = CurTrans;
        end
    end
    
    %---Approximate each superpose as the median of its sub-poses---
    % note the approximation in finding the mean orientation: mean of rodrigues... works because all
    % sub-orientations within a superpose are nearly identical.
    MeanRotVals(iSuperPoseIdx,:) = median([RotVals{iSuperPoseIdx, :, :}], 2);
    MeanTransVals(iSuperPoseIdx,:) = median([TransVals{iSuperPoseIdx, :, :}], 2);
    fprintf('\n');
    
    %---Track the apparent "baseline" of the camera at each pose---
    CurDist = bsxfun(@minus, [TransVals{iSuperPoseIdx, :, :}], MeanTransVals(iSuperPoseIdx,:)');
    CurAbsDist = sqrt(sum(CurDist.^2));
    % store as estimated diameter; the 3/2 comes from the mean radius of points on a disk (2R/3)
    BaselineApprox(iSuperPoseIdx) = 2 * 3/2 * mean(CurAbsDist); 
end

%---Initialize the superpose estimates---
EstCamPosesV = [MeanTransVals, MeanRotVals];

%---Estimate full intrinsic matrix---
ST_IJ_SlopeApprox = mean(BaselineApprox) ./ (LFSize(2:-1:1)-1);
UV_KL_SlopeApprox = 1./FocInit';

EstCamIntrinsicsH = eye(5);
EstCamIntrinsicsH(1,1) = ST_IJ_SlopeApprox(1);
EstCamIntrinsicsH(2,2) = ST_IJ_SlopeApprox(2);
EstCamIntrinsicsH(3,3) = UV_KL_SlopeApprox(1);
EstCamIntrinsicsH(4,4) = UV_KL_SlopeApprox(2);

% Force central ray as s,t,u,v = 0, note all indices start at 1, not 0
EstCamIntrinsicsH = LFRecenterIntrinsics( EstCamIntrinsicsH, LFSize );

fprintf('\nInitializing estimate of camera intrinsics to: \n');
disp(EstCamIntrinsicsH);

%---Start with no distortion estimate---
CameraModel.EstCamIntrinsicsH = EstCamIntrinsicsH;
CameraModel.Distortion = [];

%---Save the results---
TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
GeneratedByInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);

fprintf('Saving to %s...\n', CalInfoSaveFname);
LFWriteMetadata(CalInfoSaveFname, LFVar2Struct(GeneratedByInfo, CameraModel, EstCamPosesV, CalOptions, LFMetadata, CamInfo));

fprintf(' ---Calibration initialization done---\n');
