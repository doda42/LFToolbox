% LFLytroDecodeImage - decode a Lytro light field from a raw lenslet image, called by LFUtilDecodeLytroFolder
%
% Usage:
%     [LF, LFMetadata, WhiteImageMetadata, LensletGridModel, DecodeOptions] = ...
%         LFLytroDecodeImage( InputFname, DecodeOptions )
%     [LF, LFMetadata, WhiteImageMetadata, LensletGridModel, DecodeOptions] = ...
%         LFLytroDecodeImage( InputFname )
%
% This function decodes a raw lenslet image into a 4D light field. Its purpose is to tailor the core lenslet decoding
% function, LFDecodeLensletImageDirect, for use with Lytro data. It is envisioned that other camera formats will be
% supported by similar functions in future.
% 
% Supported file formats include Lytro LFP files and extracted .raw files accompanied by metadata, as extracted by using
% LFP Reader v2.0.0, for example. See LFToolbox.pdf for more information.
%
% The white image appropriate to a light field is selected based on a white image database, and so
% LFUtilProcessWhiteImages must be run before this function.
% 
% LFUtilDecodeLytroFolder is useful for decoding multiple images.
%
% The optional DecodeOptions argument includes several fields defining filename patterns. These are
% combined with the input LFFnameBase to build complete filenames. Filename patterns include the
% placeholder '%s' to signify the position of the base filename. For example, the defualt filename
% pattern for a raw input file, LensletImageFnamePattern, is '%s__frame.raw'. So a call of the
% form LFLytroDecodeImage('IMG_0001') will look for the raw input file 'IMG_0001__frame.raw'.
% 
% Inputs:
% 
%     InputFname :  Filename of the input light field -- the extension is used to detect LFP or raw input.
% 
%   [optinal] DecodeOptions : all fields are optional, defaults are for LFP Reader v2.0.0 naming
%         .WhiteProcDataFnameExtension : Grid model from LFUtilProcessWhiteImages, default 'grid.json'
%          .WhiteRawDataFnameExtension : White image file extension, default '.RAW'
%              .WhiteImageDatabasePath : White image database, default 'Cameras/WhiteImageDatabase.mat'
% 
%            For compatibility with extracted .raw and .json files:
%                .MetadataFnamePattern : JSON file containing light field metadata, default '_metadata.json'
%              .SerialdataFnamePattern : JSON file containing serial numbers, default '_private_metadata.json'
%
% Outputs:
% 
%                     LF : 5D array containing a 4-channel (RGB + Weight) light field, indexed in
%                          the order [j,i,l,k, channel]
%             LFMetadata : Contents of the metadata and serial metadata files
%     WhiteImageMetadata : Conents of the white image metadata file
%      LensletGridModel  : Lenslet grid model used to decode the light field, as constructed from
%                          the white image by LFUtilProcessWhiteImages / LFBuildLensletGridModel
%          DecodeOptions : The options as applied, including any default values omitted in the input
% 
% 
% Example:
%     
%     LF = LFLytroDecodeImage('Images/F01/IMG_0001__frame.raw');
%     or
%     LF = LFLytroDecodeImage('Images/Illum/LorikeetHiding.lfp');
%     
%     Run from the top level of the light field samples will decode the respective raw or lfp light fields.
%     LFUtilProcessWhiteImages must be run before decoding will work.
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFUtilDecodeLytroFolder, LFUtilProcessWhiteImages, LFDecodeLensletImageDirect, LFSelectFromDatabase

% Copyright (c) 2013-2020 Donald G. Dansereau

function [LF, LFMetadata, WhiteImageMetadata, LensletGridModel, DecodeOptions] = ...
    LFLytroDecodeImage( InputFname, DecodeOptions )

%---Defaults---
DecodeOptions = LFDefaultField( 'DecodeOptions', 'WhiteProcDataFnameExtension', '.grid.json' );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'WhiteRawDataFnameExtension', '.RAW' );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'WhiteImageDatabasePath', fullfile('Cameras','WhiteImageDatabase.mat'));
% Compatibility: for loading extracted raw / json files
DecodeOptions = LFDefaultField( 'DecodeOptions', 'MetadataFnamePattern', '_metadata.json' );
DecodeOptions = LFDefaultField( 'DecodeOptions', 'SerialdataFnamePattern', '_private_metadata.json' );

%---
LF = [];
LFMetadata = [];
WhiteImageMetadata = [];
LensletGridModel = [];

%---Read the LFP or raw file + external metadata---
FileExtension = InputFname(end-2:end);
switch( lower(FileExtension) )
    case 'raw' %---Load raw light field and metadata---
        FNameBase = InputFname(1:end-4);
        MetadataFname = [FNameBase, DecodeOptions.MetadataFnamePattern];
        SerialdataFname = [FNameBase, DecodeOptions.SerialdataFnamePattern];
        fprintf('Loading lenslet image and metadata:\n\t%s\n', InputFname);
        LFMetadata = LFReadMetadata(MetadataFname);
        LFMetadata.SerialData = LFReadMetadata(SerialdataFname);
        
        switch( LFMetadata.camera.model )
            case 'F01'
                BitPacking = '12bit';
                DecodeOptions.DemosaicOrder = 'bggr';
            case 'B01'
                BitPacking = '10bit';
                DecodeOptions.DemosaicOrder = 'grbg';
        end
        LensletImage = LFReadRaw(InputFname, BitPacking);
        
    otherwise %---Load Lytro LFP format---
        fprintf('Loading LFP %s\n', InputFname );
        LFP = LFReadLFP( InputFname );
        if( ~isfield(LFP, 'RawImg') )
            fprintf('No light field image found, skipping...\n');
            return
        end
        LFMetadata = LFP.Metadata;
        LFMetadata.SerialData = LFP.Serials;
        LensletImage = LFP.RawImg;
        DecodeOptions.DemosaicOrder = LFP.DemosaicOrder;
end

%---Select appropriate white image---
DesiredCam = struct('CamSerial', LFMetadata.SerialData.camera.serialNumber, ...
    'ZoomStep', LFMetadata.devices.lens.zoomStep, ...
    'FocusStep', LFMetadata.devices.lens.focusStep );
DecodeOptions.WhiteImageInfo = LFSelectFromDatabase( DesiredCam, DecodeOptions.WhiteImageDatabasePath );
PathToDatabase = fileparts( DecodeOptions.WhiteImageDatabasePath );
if( isempty(DecodeOptions.WhiteImageInfo) || ~strcmp(DecodeOptions.WhiteImageInfo.CamSerial, DesiredCam.CamSerial) )
    fprintf('No appropriate white image found, skipping...\n');
    return
end

%---Display image info---
%---Check serial number---
fprintf('\nWhite image / LF Picture:\n');
fprintf('%s, %s\n', DecodeOptions.WhiteImageInfo.Fname, InputFname);
fprintf('Serial:\t%s\t%s\n', DecodeOptions.WhiteImageInfo.CamSerial, DesiredCam.CamSerial);
fprintf('Zoom:\t%d\t\t%d\n', DecodeOptions.WhiteImageInfo.ZoomStep, DesiredCam.ZoomStep);
fprintf('Focus:\t%d\t\t%d\n\n', DecodeOptions.WhiteImageInfo.FocusStep, DesiredCam.FocusStep);

%---Load white image, white image metadata, and lenslet grid parameters---
WhiteMetadataFname = fullfile(PathToDatabase, DecodeOptions.WhiteImageInfo.Fname);
WhiteProcFname = LFFindLytroPartnerFile(WhiteMetadataFname, DecodeOptions.WhiteProcDataFnameExtension);
WhiteRawFname = LFFindLytroPartnerFile(WhiteMetadataFname, DecodeOptions.WhiteRawDataFnameExtension);

fprintf('Loading white image and metadata...\n');
LensletGridModel = LFStruct2Var(LFReadMetadata(WhiteProcFname), 'LensletGridModel');
WhiteImageMetadataWhole = LFReadMetadata( WhiteMetadataFname );
WhiteImageMetadata = WhiteImageMetadataWhole.master.picture.frameArray.frame.metadata;
WhiteImageMetadata.SerialData = WhiteImageMetadataWhole.master.picture.frameArray.frame.privateMetadata;

switch( WhiteImageMetadata.camera.model )
    case 'F01'
        assert( WhiteImageMetadata.image.rawDetails.pixelPacking.bitsPerPixel == 12 );
        assert( strcmp(WhiteImageMetadata.image.rawDetails.pixelPacking.endianness, 'big') );
        DecodeOptions.LevelLimits = [LFMetadata.image.rawDetails.pixelFormat.black.gr, LFMetadata.image.rawDetails.pixelFormat.white.gr];
        DecodeOptions.ColourMatrix = reshape(LFMetadata.image.color.ccmRgbToSrgbArray, 3,3);
        DecodeOptions.ColourBalance = [...
            LFMetadata.image.color.whiteBalanceGain.r, ...
            LFMetadata.image.color.whiteBalanceGain.gb, ...
            LFMetadata.image.color.whiteBalanceGain.b ];
        DecodeOptions.Gamma = LFMetadata.image.color.gamma^0.5;
        BitPacking = '12bit';
        
    case 'B01'
        assert( WhiteImageMetadata.image.rawDetails.pixelPacking.bitsPerPixel == 10 );
        assert( strcmp(WhiteImageMetadata.image.rawDetails.pixelPacking.endianness, 'little') );
        DecodeOptions.LevelLimits = [LFMetadata.image.pixelFormat.black.gr, LFMetadata.image.pixelFormat.white.gr];
        DecodeOptions.ColourMatrix = reshape(LFMetadata.image.color.ccm, 3,3);
        DecodeOptions.ColourBalance = [1,1,1];
        DecodeOptions.Gamma = 1;
        BitPacking = '10bit';
        
    otherwise
        fprintf('Unrecognized camera model, skipping...\');
        return
end
WhiteImage = LFReadRaw( WhiteRawFname, BitPacking ); 

%---Decode---
fprintf('Decoding lenslet image :');
[LF, LFWeight, DecodeOptions] = LFDecodeLensletImageDirect( LensletImage, WhiteImage, LensletGridModel, DecodeOptions );
LF(:,:,:,:,4) = LFWeight;
