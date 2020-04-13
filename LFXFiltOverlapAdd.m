% todo: doc, example
function [LF, FiltOptions] = LFFiltOverlapAdd( LF, h, FiltOptions )

%---
LFSize = size(LF(:,:,:,:,1));
STSize = LFSize([2,1]);
UVSize = LFSize([4,3]);
HSize = size(h);
HstSize = HSize([2,1]);
HuvSize = HSize([4,3]);
NColChans = size(LF,5);
HasWeight = ( NColChans == 4 || NColChans == 2 );
if( HasWeight )
	NColChans = NColChans-1;
end

%---
FiltOptions = LFDefaultField('FiltOptions', 'Precision', 'single');
FiltOptions = LFDefaultField('FiltOptions', 'Normalize', true);
FiltOptions = LFDefaultField('FiltOptions', 'MinWeight', 10*eps(FiltOptions.Precision));  
FiltOptions = LFDefaultField('FiltOptions', 'ShowPartial', false);
FiltOptions = LFDefaultField('FiltOptions', 'FFTLen', 128);
FiltOptions = LFDefaultField('FiltOptions', 'STPaddedSize',  max(HstSize, STSize));
FiltOptions = LFDefaultField('FiltOptions', 'DoClamp', true);

if( length(FiltOptions.FFTLen) == 1 )
    FiltOptions.FFTLen = FiltOptions.FFTLen.*[1,1];
end
if( length(FiltOptions.STPaddedSize) == 1 )
    FiltOptions.STPaddedSize = FiltOptions.STPaddedSize.*[1,1];
end

%---
LF = LFConvertToFloat(LF, FiltOptions.Precision);
h = LFConvertToFloat(h, FiltOptions.Precision);

if( FiltOptions.Normalize )
	if( HasWeight )
		for( iColChan = 1:NColChans )
			LF(:,:,:,:,iColChan) = LF(:,:,:,:,iColChan) .* LF(:,:,:,:,end);
		end
	else % add a weight channel
		LF(:,:,:,:,end+1) = ones(size(LF(:,:,:,:,1)), FiltOptions.Precision);
	end
end
NChans = size(LF,5);
%---

ChunkSize = FiltOptions.FFTLen - HuvSize + 1; % input chunk size
assert(all(ChunkSize>0), 'Assertion failed: FFTLen must be greater than impulse response size');
FFTSize = [FiltOptions.STPaddedSize([2,1]),FiltOptions.FFTLen([2,1])];

% mixed modes in s,t and u,v:
% s,t is zero-phase and manually padded to match filter size,
% u,v is centered, and we leave fftn to pad as appropriate
% todo: use xLFPadForFFT?
EvenPad = floor((FFTSize(1:2) - size(h(:,:,1,1)))/2);
h2 = padarray(h, EvenPad);
OddPad = FFTSize(1:2) - size(h2(:,:,1,1));
if( mod(FFTSize(1),2) == 1 )
	PadMode{1} = 'post';
else
	PadMode{1} = 'pre';
end
if( mod(FFTSize(2),2) == 1 )
	PadMode{2} = 'post';
else
	PadMode{2} = 'pre';
end
h2 = padarray(h2, [OddPad(1),0], PadMode{1});  % todo: check pre vs post, etc
h2 = padarray(h2, [0,OddPad(2)], PadMode{2});  % todo: check pre vs post, etc
h2 = ifftshift(ifftshift(h2,1),2);

H = fftn(h2, FFTSize);

OutStrip = zeros([STSize, UVSize(2)+HuvSize(2), FiltOptions.FFTLen(1), NChans], FiltOptions.Precision);

for( UIdx=1:ChunkSize(1):UVSize(1)+floor(size(h,4)/2) )
    UEnd = min(UIdx + ChunkSize(1)-1, UVSize(1));
    for( VIdx=1:ChunkSize(2):UVSize(2) )
        VEnd = min(VIdx + ChunkSize(2)-1, UVSize(2));
		
        for( ColChan = 1:NChans )
            CurImg = LF(:,:, VIdx:VEnd, UIdx:UEnd, ColChan);
            CurImg = cast(CurImg, FiltOptions.Precision);
            CurImg = fftn(CurImg,FFTSize);
            CurImg = CurImg .* H;
            CurImg = ifftn(CurImg, 'symmetric');
            
            VOutEnd = min(UVSize(2)+HuvSize(2), VIdx+FiltOptions.FFTLen(2)-1);
            UOutEnd = min(UVSize(1)+HuvSize(1), UIdx+FiltOptions.FFTLen(1)-1);
            VOutSize = VOutEnd - VIdx + 1;
            UOutSize = UOutEnd - UIdx + 1;

            OutStrip(:,:,VIdx:VOutEnd,1:UOutSize, ColChan) = OutStrip(:,:,VIdx:VOutEnd,1:UOutSize, ColChan) + CurImg(1:STSize(2), 1:STSize(1), 1:VOutSize,1:UOutSize);
        end
	end
    UStart = UIdx - floor(size(h,4)/2);
    UEnd = min(UVSize(1), UIdx + ChunkSize(1)-1 -floor(size(h,4)/2));
    USize = UEnd-UStart+1;
    LF(:,:,:, max(1,(UStart:UEnd)),:) = OutStrip(:,:,1+floor(size(h,3)/2) + (1:UVSize(2))-1, 1:USize, :);
    
    OutStripSave = OutStrip(:,:, :, ChunkSize(1)+1:end,:);
    OutStrip = zeros(size(OutStrip), FiltOptions.Precision);
    OutStrip(:,:, :,1:size(OutStripSave,4),:) = OutStripSave;
    
    if( FiltOptions.ShowPartial )
        LFDisp(max(0,min(1,LF)));
        axis image
        colormap gray
        drawnow
	end
	fprintf('.');
end
fprintf('\n');

%---Normalize---
if( FiltOptions.Normalize )
	WeightChan = LF(:,:,:,:,end);
	InvalidIdx = find(WeightChan < FiltOptions.MinWeight);
	ChanSize = numel(LF(:,:,:,:,1));
	for( iColChan = 1:NColChans )
		LF(:,:,:,:,iColChan) = LF(:,:,:,:,iColChan) ./ WeightChan;
		LF( InvalidIdx + ChanSize.*(iColChan-1) ) = 0;
	end
	LF( InvalidIdx + ChanSize.*NColChans ) = 0; % also zero weight channel where invalid  % todo: propagate to other filts
end

%---Clamp---
if( FiltOptions.DoClamp )
	LF = max(0,LF);
	LF = min(1,LF);
end

TimeStamp = datestr(now,'ddmmmyyyy_HHMMSS');
FiltOptions.FilterInfo = struct('mfilename', mfilename, 'time', TimeStamp, 'VersionStr', LFToolboxVersion);