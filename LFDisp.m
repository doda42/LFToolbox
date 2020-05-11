% LFDisp - Convenience function to display a 2D slice of a light field using imagesc
%
% Usage:
%      LFDisp( LF )
%      [LFSlice, WOut] = LFDisp( LF, Renormalize )
%
% The centermost image is taken in s and t. Also works with 3D arrays of images. If an output
% argument is included, no display is generated, but the extracted slice is returned instead.
%
% Inputs:
%
%      LF : a colour or single-channel light field, can be floating point or integer format. For
%           display, it is scaled as in imagesc.  If LF contains more than three colour channels, as
%           is the case when a weight channel is present, only the first three are used.
%
% Optional Inputs:
%
%      Renormalize : optionally rescale the image intensities between 0 and 1, only applies for
%                    float inputs; this accepts false or empty array or string to disable, and true
%                    or any nonempty string to enable.
%
% Outputs:
%
%     LFSlice : if an output argument is used, no display is generated, but the extracted slice is
%               returned.
%
%     WOut : for inputs with a weight channel, the weight is stripped and returned separately
% 
% Examples:
% 
%     LFDisp( LF );  % display centermost u,v slice of LF
%     LFDisp( LF( 9,:,100,:, :) ); % display s,u slice at t=9, v=100
%     LFDisp( LF, true );          % enable renormalisation
%     LFDisp( LF, 'Renormalize' ); % enable renormalisation
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDispMousePan, LFDispVidCirc, LFDispLawnmower, LFDispProj, LFDispTiles

% Copyright (c) 2013-2020 Donald G. Dansereau

function [ImgOut, WOut] = LFDisp( LF, Renormalize )

Renormalize = LFDefaultVal('Renormalize', false);

LF = squeeze(LF);
LFSize = size(LF);

HasWeight = (ndims(LF)>2 && (LFSize(end)==2 || LFSize(end)==4));
HasColor = (ndims(LF)>2 && (LFSize(end)==3 || LFSize(end)==4) );
HasMonoAndWeight = (ndims(LF)>2 && LFSize(end)==2);

if( HasColor || HasMonoAndWeight )
	GoalDims = 3;
else
	GoalDims = 2;
end
while( ndims(LF) > GoalDims )
	LF = squeeze(LF(round(end/2),:,:,:,:,:,:));
end
if( HasWeight )
	if( nargout >= 2 )
		WOut = LF(:,:,end);
	end
	LF = squeeze(LF(:,:,1:end-1));
end

if( (~isempty( Renormalize )) && ~(isa(Renormalize,'logical') && Renormalize == false) )
	if( isfloat( LF ) )
		LF = LF - min(LF(:));
		LF = LF ./ max(LF(:));
	end
end

if( nargout >= 1 )
	ImgOut = LF;
else
	imagesc(LF);
end


