% LFDispProj - Project a 4D light field onto a plane, and optionally display it to the screen
%
% Usage: 
%     [Img,XL,YL] = LFDispProj( LF, [Dim1], [Dim2], [ProjectionMethod], [<LFDisp options>] )
% 
% All parameters except LF are optional. If an output argument is assigned, the result is not
% displayed to the screen. 
%
% Inputs :
% 
%     LF : a light field to display.
% 
% Optional Inputs :
% 
%           Dim1, Dim2 : indices for each of the two dimensions to project onto; Defaults 3, 4.
%
%     ProjectionMethod : One of 'sum', 'mean', 'max', or 'min'; how the remaining two dimensions are
%                        to be collapsed. Default: 'mean'.
% 
%    <LFDisp options> : any additional parameters get passed along to LFDisp
%
% Outputs : 
%
%     Img: A 2D bitmap of the generated image.
% 
%     XL, YL: labels for the x and y axes.
% 
% Examples :
% 
%     LFDispProj( LF );              % projects LF onto dimensions 3,4 and displays to screen
% 
%     LFDispProj( LF, 1, 3, 'max' ); % projects onto dimensions 1,2 by taking the max
% 
%     I = LFDispProj( LF );          % returns projection as I, does not display to screen
%     LFDisp( I, 'Renormalize' );    % display I with renormalisation
% 
%     % project onto dims 1,2 with default projection method, enable renormalisation in LFDisp
%     LFDispProj( LF, 1,2, [], 'Renormalize' );
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDispProjSubfigs, LFDisp, LFDispMousePan, LFDispVidCirc, LFDispLawnmower, LFDispTiles

% Copyright (c) 2012-2020 Donald G. Dansereau

function [Img,XL,YL] = LFDispProj( LF, Dim1, Dim2, ProjectionMethod, varargin )

Dim1 = LFDefaultVal('Dim1', 3);
Dim2 = LFDefaultVal('Dim2', 4);
ProjectionMethod = LFDefaultVal('ProjectionMethod', 'mean');

LF = LFConvertToFloat(LF); % this implementation doesn't deal well with ints

%---Set labels, always display in same order---
if( Dim1 > Dim2 )
	t = Dim1;
	Dim1 = Dim2;
	Dim2 = t;
end
DimLabels = ['t','s','v','u'];
XL = DimLabels(Dim2);
YL = DimLabels(Dim1);

%---Find the two dims to remove---
RemoveDims = 1:4;
RemoveDims([Dim1, Dim2]) = [];

% post-Dim1 squeeze, Dim2 will be lesser by one
RemoveDims(2) = RemoveDims(2) - 1;

switch( lower(ProjectionMethod) )
	case 'sum'
		Img = squeeze(sum(squeeze(sum(LF,RemoveDims(1))), RemoveDims(2)));
	case 'mean'
		Img = squeeze(mean(squeeze(mean(LF,RemoveDims(1))), RemoveDims(2)));
	case 'max'
		Img = squeeze(max(squeeze(max(LF,[],RemoveDims(1))),[],RemoveDims(2)));
	case 'min'
		Img = squeeze(min(squeeze(max(LF,[],RemoveDims(1))),[],RemoveDims(2)));
	otherwise
		error('Unrecognized projection method');
end

%---Display-----------------------------------------------------------------------------------------
if( nargout < 1 )
	LFDisp(Img, varargin{:});
	clear Img
	
	xlabel(XL);
	ylabel(YL);
end
