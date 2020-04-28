% LFMatlabPathSetup - convenience function to add the light field toolbox to matlab's path
%
% It may be convenient to add this to your startup.m file.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>

% Copyright (c) 2013-2020 Donald G. Dansereau

function LFMatlabPathSetup

if (~isdeployed)
	% Find the path to this script, and use it as the base path
	LFToolboxPath = fileparts(mfilename('fullpath'));
	
	fprintf('Adding paths for LF Toolbox ');
	addpath( fullfile(LFToolboxPath) );
	addpath( fullfile(LFToolboxPath, 'SupportFunctions') );
	addpath( fullfile(LFToolboxPath, 'SupportFunctions', 'CameraCal') );
	
	fprintf('%s, done.\n', LFToolboxVersion);
end
