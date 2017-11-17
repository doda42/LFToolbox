% todo: doc

function LFXWriteAnimFrames( LF, OutPath, PathRadius_percent, NFrames, DelayTime, ResizeRatio )

%---Defaults---
PathRadius_percent = LFDefaultVal( 'PathRadius_percent', 60 );
NFrames = LFDefaultVal( 'NFrames', 24*4 );
DelayTime = LFDefaultVal( 'DelayTime', 1/24 );
ResizeRatio = LFDefaultVal( 'ResizeRatio', 1 );

%---Check for mono and clip off the weight channel if present---
Mono = (ndims(LF) == 4);
if( ~Mono )
    LF = LF(:,:,:,:,1:3);
end

% %---Rescale for 8-bit display---
% if( isfloat(LF) )
%     LF = uint8(LF ./ max(LF(:)) .* 255);
% else
%     LF = uint8(LF.*(255 / double(intmax(class(LF)))));
% end

%---Setup the motion path---
[TSize,SSize, ~,~] = size(LF(:,:,:,:,1));
TCent = (TSize-1)/2 + 1;
SCent = (SSize-1)/2 + 1;

RotRad = TCent*PathRadius_percent/100;

sfigure(1);
cla
hold on


for( t = 1:NFrames )
	% 	%flowery
	% 	TVal = TCent + RotRad * sin( 2*2*pi*t/NFrames );
	%     SVal = SCent + RotRad * cos( 2*pi*t/NFrames );
	
	TVal = TCent + RotRad * sin( 2*pi*t/NFrames );
	SVal = SCent + RotRad * cos( 2*pi*t/NFrames );
	
	
% 	CurT = 3*pi*t/NFrames;
% 	R = CurT/3;
% 	H = [cos(R),-sin(R); sin(R),cos(R)];
% 	CurX = [0.1.*cos(CurT); 1.*sin(CurT)];
% 	CurX = H*CurX;
% 	
% 	TVal = TCent + RotRad * CurX(1);
%     SVal = SCent + RotRad * CurX(2);
	
    SIdx = round(SVal);
    TIdx = round(TVal);
  
	sfigure(1);
	plot(SVal,TVal,'r.');
	plot(SIdx,TIdx,'b.');
	drawnow
    CurFrame =  squeeze(LF( TIdx, SIdx, :,:,: ));
	CurFrame = imresize(CurFrame,ResizeRatio); 
    
	CurFname = sprintf('frame.%05d.png', t);
	imwrite(CurFrame, fullfile(OutPath,CurFname));
	
    fprintf('.')
end
fprintf(' Done\n');