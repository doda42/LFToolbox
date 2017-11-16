% LFMatlabPathSetup - convenience function to add the light field toolbox to matlab's path
%
% It may be convenient to add this to your startup.m file.

% Part of LF Toolbox v0.4 released 12-Feb-2015
% Copyright (c) 2013-2015 Donald G. Dansereau

function LFMatlabPathSetup

% Find the path to this script, and use it as the base path
LFToolboxPath = fileparts(mfilename('fullpath'));

fprintf('Adding paths for LF Toolbox ');
addpath( fullfile(LFToolboxPath) );
addpath( fullfile(LFToolboxPath, 'SupportFunctions') );
addpath( fullfile(LFToolboxPath, 'SupportFunctions', 'CameraCal') );
fprintf('%s, done.\n', LFToolboxVersion);