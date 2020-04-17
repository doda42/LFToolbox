% LFColourCorrect - applies a colour correction matrix, balance vector, and gamma, called by LFUtilDecodeLytroFolder
%
% Usage: 
%     LF = LFColourCorrect( LF, ColMatrix, ColBalance, Gamma )
% 
% This implementation deals with saturated input pixels by aggressively saturating output pixels.
%
% Inputs :
% 
%     LF : a light field or image to colour correct. It should be a floating point array, and
%          may be of any dimensinality so long as the last dimension has length 3. For example, a 2D
%          image of size [Nl,Nk,3], a 4D image of size [Nj,Ni,Nl,Nk,3], and a 1D list of size [N,3]
%          are all valid.
%
%    ColMatrix : a 3x3 colour conversion matrix. This can be built from the metadata provided
%                with Lytro imagery using the command:
%                     ColMatrix = reshape(cell2mat(LFMetadata.image.color.ccmRgbToSrgbArray), 3,3);
%                as demonstrated in LFUtilDecodeLytroFolder.
% 
%    ColBalance : 3-element vector containing a multiplicative colour balance.
% 
%    Gamma : rudimentary gamma correction is applied of the form LF = LF.^Gamma.
%
% Outputs : 
% 
%     LF, of the same dimensionality as the input.
% 
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFHistEqualize, LFUtilDecodeLytroFolder

% Copyright (c) 2013-2020 Donald G. Dansereau

function LF = LFColourCorrect(LF, ColMatrix, ColBalance, Gamma)

LFSize = size(LF);

% Flatten input to a flat list of RGB triplets
NDims = numel(LFSize);
LF = reshape(LF, [prod(LFSize(1:NDims-1)), 3]);

LF = bsxfun(@times, LF, ColBalance);
LF = LF * ColMatrix;

% Unflatten result
LF = reshape(LF, [LFSize(1:NDims-1),3]);

% Saturating eliminates some issues with clipped pixels, but is aggressive and loses information
% todo[optimization]: find a better approach to dealing with saturated pixels
SaturationLevel = ColBalance*ColMatrix;
SaturationLevel = min(SaturationLevel);
LF = min(SaturationLevel,max(0,LF)) ./ SaturationLevel; 

% Apply gamma
LF = LF .^ Gamma;
