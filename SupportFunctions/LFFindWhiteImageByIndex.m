% LFFindWhiteImageByIndex - Finds White images names with same structure
% as the given file name (including full path and extension) but with
% different indices.
%
% Usage: 
%     [ImagesDir, WhiteImageNames] = LFFindWhiteImageByIndex(WhiteImageFname,WhiteImageIndices);
% 
% Inputs :
% 
%    WhiteImageFname : Full name of a raw white image.
%
%    WhiteImageIndices : vector containing the indices of the white images
%    to find in the White raw Image Folder.
% 
% Outputs : 
% 
%     ImagesDir : White (and Black) image folder.
%     
%     WhiteImageNames : cell containing the filenames of all the white
%     images found in the folder corresponding to the indices given in
%     WhiteImageIndices.

function [ImagesDir, WhiteImageNames] = LFFindWhiteImageByIndex(WhiteImageFname, WhiteImageIndices)

[ImagesDir, WhiteImageName, ImageExt] = fileparts(WhiteImageFname);

%Search for format of the white image file name
[DigitsStart, DigitsEnd] = regexp(WhiteImageName,'_\d+','start','end');
DigitsStart = DigitsStart(end);
DigitsEnd = DigitsEnd(end);

%Retrieve white images corresponding to the same format and with the target indices
fdir = dir(ImagesDir);
NumExpr = sprintf('%i|',floor(WhiteImageIndices));
NumExpr = ['(' NumExpr(1:end-1) ')'];

WhiteImageNames=regexp({fdir.name},['^' WhiteImageName(1:DigitsStart) '0*' NumExpr WhiteImageName(DigitsEnd+1:end) ImageExt '$'],'match');
WhiteImageNames=[WhiteImageNames{:}];