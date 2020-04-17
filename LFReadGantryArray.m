% LFReadGantryArray - load gantry-style light field, e.g. the Stanford light fields at lightfield.stanford.edu
%
% Usage:
%
%     [LF , DecodeOptions] = LFReadGantryArray( InputPath, DecodeOptions )
%
% To use, download and unzip an image archive from the Stanford light field archive, and pass this function the path to
% the unzipped files. All inputs are optional, by default the light field is loaded from the current directory.
% DecodeOptions.UVScale and DecodeOptions.UVLimit allow the input images to be scaled, either by the constant factor
% UVScale, or to achieve the maximum u,v image size specified by UVLimit. If both UVScale and UVLimit are specified, the
% one resulting in smaller images is applied.
%
% The defaults are all set to load Stanford Lego Gantry light fields, and must be adjusted for differently sized or
% ordered light fields.
%
% Inputs :
%
%          InputPath : path to folder of image files, e.g. as obtained by decompressing a Stanford light field
%
%      DecodeOptions :
%                UVScale : constant scaling factor applied to each input image; default: 1
%                UVLimit : scale is adjusted to ensure a maximum image dimension of DecodeOptions.UVLimit
%                  Order : 'RowMajor' or 'ColumnMajor', specifies the order in which images appear when sorted
%                          alphabetically; default: 'RowMajor'
%                 STSize : Size of the array of images; default: [17, 17]
%           FnamePattern : Pattern used to locate input file, using standard wildcards; default '*.png'
%
% Outputs:
%
%          LF     : 5D array containing a 3-channel (RGB) light field, indexed in the order [j,i,l,k, colour]
%   DecodeOptions : Reflects the parameters as applied, including the UVScale resulting from UVLimit
%
%
% Example 1:
%
%     After unzipping the LegoKnights Stanford light fields into '~/Data/Stanford/LegoKnights/rectified', the following
%     reads the light field at full resolution, yielding a 17 x 17 x 1024 x 1024 x 3 array, occupying 909 MBytes of RAM:
%
%     LF = LFReadGantryArray('~/Data/Stanford/LegoKnights/rectified');
%
% Example 2:
%
%     As above, but scales each image to a maximum dimension of 256 pixels, yielding a 17 x 17 x 256 x 256 x 3 array.
%     LFDIspMousePan then displays the light field, click and pan around to view the light field.
%
%     LF = LFReadGantryArray('~/Data/Stanford/LegoKnights/rectified', struct('UVLimit', 256));
%     LFDispMousePan(LF)
%
% Example 3:
%
%     A few of the Stanford "Gantry" (not "Lego Gantry") light fields follow a lawnmower pattern.  These can be read and
%     adjusted as follows:
%
%     LF = LFReadGantryArray('humvee-tree', struct('STSize', [16,16]));
%     LF(1:2:end,:,:,:,:) = LF(1:2:end,end:-1:1,:,:,:);

% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDispMousePan, LFDispVidCirc

% Copyright (c) 2013-2020 Donald G. Dansereau

function [LF, DecodeOptions] = LFReadGantryArray( InputPath, DecodeOptions )

InputPath = LFDefaultVal('InputPath', '.');
DecodeOptions = LFDefaultField('DecodeOptions','UVScale', 1);
DecodeOptions = LFDefaultField('DecodeOptions','UVLimit', []);
DecodeOptions = LFDefaultField('DecodeOptions','STSize', [17,17]);
DecodeOptions = LFDefaultField('DecodeOptions','FnamePattern', '*.png');
DecodeOptions = LFDefaultField('DecodeOptions','Order', 'RowMajor');

%---Gather info---
FList = dir(fullfile(InputPath, DecodeOptions.FnamePattern));
if( isempty(FList) )
	error('No files found');
end

NumImgs = length(FList);
assert( NumImgs == prod(DecodeOptions.STSize), 'Unexpected image count: expected %d x %d = %d found %d', ...
	DecodeOptions.STSize(1), DecodeOptions.STSize(2), prod(DecodeOptions.STSize), NumImgs );

%---Get size, scaling info from first file, assuming all are same size---
Img = imread(fullfile(InputPath, FList(1).name));
ImgClass = class(Img);
UVSizeIn = size(Img);

if( ~isempty(DecodeOptions.UVLimit) )
	UVMinScale = min(DecodeOptions.UVLimit ./ UVSizeIn(1:2));
	DecodeOptions.UVScale = min(DecodeOptions.UVScale, UVMinScale);
end
Img = imresize(Img, DecodeOptions.UVScale);

UVSize = size(Img);
TSize = DecodeOptions.STSize(2);
SSize = DecodeOptions.STSize(1);
VSize = UVSize(1);
USize = UVSize(2);

%---Allocate mem---
LF = zeros(TSize, SSize, VSize,USize, 3, ImgClass);
LF(1,1,:,:,:) = Img;

switch( lower(DecodeOptions.Order) )
	case 'rowmajor'
		[SIdx,TIdx] = ndgrid( 1:SSize, 1:TSize );
	case 'columnmajor'
		[TIdx,SIdx] = ndgrid( 1:TSize, 1:SSize );
	otherwise
		error( 'Unrecognized image order' );
end

%---Load and scale images---
fprintf('Loading %d images', NumImgs);
for(i=2:NumImgs)
	if( mod(i, ceil(length(FList)/10)) == 0 )
		fprintf('.');
	end
	
	Img = imread(fullfile(InputPath, FList(i).name));
	Img = imresize(Img, DecodeOptions.UVScale);
	
	LF(TIdx(i),SIdx(i),:,:,:) = Img;
end
fprintf(' done\n');
