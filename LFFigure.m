function h = LFFigure(h, varargin)
% LFFIGURE - Create a figure window without stealing focus
%
% Usage is identical to figure.
%
% originally published at sfigure
% Daniel Eaton, 2005
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: figure

if nargin>=1 
	if ishandle(h)
		set(0, 'CurrentFigure', h);
	else
		h = figure(h, varargin{:});
	end
else
	h = figure;
end
