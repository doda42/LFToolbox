% todo: document

fprintf('Be sure to "cd" into the top level of the samples folder before running this\n');
fprintf('Trying "ls", this should show the folders "Images" and "Cameras"\n\n');

ls

% decode the white images
LFUtilProcessWhiteImages;

% use the decoded white images to decode the lytro images
LFUtilDecodeLytroFolder;

% redo the image decode with colour correction
DecodeOptions.OptionalTasks = 'ColourCorrect';
LFUtilDecodeLytroFolder([], [], DecodeOptions);

% load a newly decoded light field
load(fullfile('Images','F01','IMG_0002__Decoded.mat'), 'LF');

% display it interactively
LFDispMousePan(LF);