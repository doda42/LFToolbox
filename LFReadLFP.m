% LFReadLFP - Load a lytro LFP / LFR file
% 
% Usage:
%     [LFP, ExtraSections] = LFReadLFP( Fname )
% 
% The Lytro LFP is a container format and may contain one of several types of data. The file extension varies based on
% the source of the files, with exported files, on-camera files and image library files variously taking on the
% extensions lfp, lfr, LFP and LFR.
% 
% This function loads all the sections of an LFP and interprets those that it recognizes. Recognized sections include
% thumbnails and focal stacks, raw light field and white images, metadata and serial data. If more than one section of
% the same type appears, a cell array is constructed in the output struct -- this is the case for focal stacks, for
% example. Files generated using Lytro Desktop 4.0 and 3.0 are supported.
% 
% Additional output information includes the appropriate demosaic order for raw light field images, and the size of raw
% images.
% 
% Unrecognized sections are returned in the ExtraSections output argument.
% 
% This function is based in part on Nirav Patel's lfpsplitter.c and Doug Kelley's read_lfp; Thanks to Michael Tao for
% help and samples for decoding Illum imagery.
% 
% Inputs :
%          Fname : path to an input LFP file
% 
% Outputs:
%          LFP : Struct containing decoded LFP sections and supporting information, which may include one or more of
%               .Jpeg : Thumbnails, focal stacks -- see LFUtilExtractLFPThumbs for saving these to disk
%             .RawImg : Raw light field image
%           .WhiteImg : White image bundled into Illum LFP
%           .Metadata, .Serials : Information about the image and camera
%      .DemosaicOrder : The appropriate parameter to pass to Matlab's "demosaic" to debayer a RawImg
%            .ImgSize : Size of RawImg
%
%   ExtraSections : Struct array containing unrecognized LFP sections
%               .Data : Buffer of chars containing the section's uninterpreted data block
%           .SectType : Descriptive name for the section, e.g. "hotPixelRef"
%               .Sha1 : Unique hash identifying the section
%         .SectHeader : Header bytes identifying the section as a table of contents or data
% 
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFUtilExtractLFPThumbs, LFUtilUnpackLytroArchive, LFUtilDecodeLytroFolder

% Copyright (c) 2013-2020 Donald G. Dansereau

function [LFP, ExtraSections] = LFReadLFP( Fname )

%---Consts---
LFPConsts.LFPHeader = hex2dec({'89', '4C', '46', '50', '0D', '0A', '1A', '0A', '00', '00', '00', '01'}); % 12-byte LFPSections header
LFPConsts.SectHeaderLFM = hex2dec({'89', '4C', '46', '4D', '0D', '0A', '1A', '0A'})'; % header for table of contents
LFPConsts.SectHeaderLFC = hex2dec({'89', '4C', '46', '43', '0D', '0A', '1A', '0A'})'; % header for content section
LFPConsts.SecHeaderPaddingLen = 4;
LFPConsts.Sha1Length = 45;
LFPConsts.ShaPaddingLen = 35; % Sha1 codes are followed by 35 null bytes

%---Break out recognized sections---
KnownSectionTypes = { ...
    ... % Lytro Desktop 4
    'Jpeg', 'picture.accelerationArray.vendorContent.imageArray.imageRef', 'jpeg'; ...
    'Jpeg', 'thumbnails.imageRef', 'jpeg'; ...
    'RawImg', 'frames.frame.imageRef', 'raw'; ...
    'WhiteImg', 'frames.frame.modulationDataRef', 'raw';...
    'Metadata', 'frames.frame.metadataRef', 'json'; ...
    'Serials', 'frames.frame.privateMetadataRef', 'json'; ...
    ... % Earlier Lytro Desktop versions
    'RawImg', 'picture.frameArray.frame.imageRef', 'raw'; ...
    'Metadata', 'picture.frameArray.frame.metadataRef', 'json'; ...
    'Serials', 'picture.frameArray.frame.privateMetadataRef', 'json'; ...
    };

%---
ExtraSections = [];
LFP = [];
InFile=fopen(Fname, 'rb');

%---Check for the magic header---
HeaderBytes = fread( InFile, length(LFPConsts.LFPHeader), 'uchar' );
if( (length(HeaderBytes)~=length(LFPConsts.LFPHeader)) || ~all( HeaderBytes == LFPConsts.LFPHeader ) )
    fclose(InFile);
    fprintf( 'Unrecognized file type\n' );
    return
end

%---Confirm headerlength bytes---
HeaderLength = fread(InFile,1,'uint32','ieee-be');
assert( HeaderLength == 0, 'Unexpected length at top-level header' );

%---Read each section---
NSections = 0;
TOCIdx = [];
while( ~feof(InFile) )
    NSections = NSections+1;
    LFPSections( NSections ) = ReadSection( InFile, LFPConsts );
    
    %---Mark the table of contents section---
    if( all( LFPSections( NSections ).SectHeader == LFPConsts.SectHeaderLFM ) )
        assert( isempty(TOCIdx), 'Found more than one LFM metadata section' );
        TOCIdx = NSections;
    end
end
fclose( InFile );

%---Decode the table of contents---
assert( ~isempty(TOCIdx), 'Found no LFM metadata sections' );
TOC = LFReadMetadata( LFPSections(TOCIdx).Data );
LFPSections(TOCIdx).SectType = 'TOC';

%---find all sha1 refs in TOC---
TocData = LFPSections(TOCIdx).Data;
ShaIdx = strfind( TocData, 'sha1-' ); 
SeparatorIdx = find( TocData == ':' );
EolIdx = find( TocData == 10 );

for( iSha = 1:length(ShaIdx) )
    LabelStopIdx = SeparatorIdx( find( SeparatorIdx < ShaIdx(iSha), 1, 'last' ) );
    LabelStartIdx = EolIdx( find( EolIdx < LabelStopIdx, 1, 'last' ) );
    ShaEndIdx = EolIdx( find( EolIdx > ShaIdx(iSha), 1, 'first' ) );
    CurLabel = TocData(LabelStartIdx:LabelStopIdx);
    CurSha = TocData(LabelStopIdx:ShaEndIdx);
    
    CurLabel = strsplit(CurLabel, '"');
    CurSha = strsplit(CurSha, '"');
    
    CurLabel = CurLabel{2};
    CurSha = CurSha{2};
    
    SectNames{iSha} = CurLabel;
    SectIDs{iSha} = CurSha;
end

%---Apply section labels---
for( iSect = 1:length(SectNames) )
    CurSectSHA = SectIDs{iSect};
    MatchingSectIdx = find( strcmp( CurSectSHA, {LFPSections.Sha1} ) );
    if( ~isempty(MatchingSectIdx) )
        LFPSections(MatchingSectIdx).SectType = SectNames{iSect};
    end
end

for( iSect = 1:size(KnownSectionTypes,1) )
    FoundField = true;
    while(FoundField)
        [LFP, LFPSections, TOC, FoundField] = ExtractNamedField(LFP, LFPSections, TOC, KnownSectionTypes(iSect,:) );
    end
end
ExtraSections = LFPSections;

%---unpack the image(s)---
if( isfield( LFP, 'RawImg') )
    LFP.ImgSize = [LFP.Metadata.image.width, LFP.Metadata.image.height];
    switch( LFP.Metadata.camera.model )
        case 'F01'
            assert( LFP.Metadata.image.rawDetails.pixelPacking.bitsPerPixel == 12 );
            assert( strcmp(LFP.Metadata.image.rawDetails.pixelPacking.endianness, 'big') );
            LFP.RawImg = LFUnpackRawBuffer( LFP.RawImg, '12bit', LFP.ImgSize )';
            LFP.DemosaicOrder = 'bggr';
            
        case 'ILLUM'
            assert( LFP.Metadata.image.pixelPacking.bitsPerPixel == 10 );
            assert( strcmp(LFP.Metadata.image.pixelPacking.endianness, 'little') );
            LFP.RawImg = LFUnpackRawBuffer( LFP.RawImg, '10bit', LFP.ImgSize )';
            if( isfield( LFP, 'WhiteImg' ) )
                LFP.WhiteImg =  LFUnpackRawBuffer( LFP.WhiteImg, '10bit', LFP.ImgSize )'; 
            end
            LFP.DemosaicOrder = 'grbg';
            
        otherwise
            warning('Unrecognized camera model');
            return
    end
end

end

% --------------------------------------------------------------------
function LFPSect = ReadSection( InFile, LFPConsts )
LFPSect.SectHeader = fread(InFile, length(LFPConsts.SectHeaderLFM), 'uchar')';
Padding = fread(InFile, LFPConsts.SecHeaderPaddingLen, 'uint8'); % skip padding

SectLength = fread(InFile, 1, 'uint32', 'ieee-be');
LFPSect.Sha1 = char(fread(InFile, LFPConsts.Sha1Length, 'uchar')');
Padding = fread(InFile, LFPConsts.ShaPaddingLen, 'uint8'); % skip padding

LFPSect.Data = char(fread(InFile, SectLength, 'uchar'))';

while( 1 ) 
    Padding = fread(InFile, 1, 'uchar');
    if( feof(InFile) || (Padding ~= 0) )
        break;
    end
end
if ~feof(InFile)
    fseek( InFile, -1, 'cof'); % rewind one byte
end

end

% --------------------------------------------------------------------
function [LFP, LFPSections, TOC, FoundField] = ExtractNamedField(LFP, LFPSections, TOC, FieldInfo)
FoundField = false;

FieldName = FieldInfo{1};
JsonName = FieldInfo{2};
FieldFormat = FieldInfo{3};

JsonTokens = strsplit(JsonName, '.');
TmpToc = TOC;
if( ~iscell(JsonTokens) )
    JsonTokens = {JsonTokens};
end
for( i=1:length(JsonTokens) )
    if( ~isfield(TmpToc, JsonTokens{i}) || isempty([TmpToc.(JsonTokens{i})]) )
        return;
    end
    TmpToc = TmpToc.(JsonTokens{i}); % takes the first one in the case of an array
end

FieldIdx = find( strcmp( TmpToc, {LFPSections.Sha1} ) );
if( ~isempty(FieldIdx) )
    SubField = struct('type','.','subs',FieldName);
    
    %--- detect image array and force progress by removing the currently-processed entry ---
    S = struct('type','.','subs',JsonTokens(1:end-1));
    t = subsref( TOC, S );
    ArrayLen = length(t);
    if( (isstruct(t) && ArrayLen>1) || isfield( LFP, FieldName ) )
        S(end+1).type = '()';
        S(end).subs = {1};
        TOC = subsasgn( TOC, S, [] );

		% Add an indexing subfield for image arrays
        SubField(end+1).type = '{}';
        SubField(end).subs = {ArrayLen};
    end

	%---Copy the data into the LFP struct---
    LFP = subsasgn( LFP, SubField, LFPSections(FieldIdx).Data );
    LFPSections = LFPSections([1:FieldIdx-1, FieldIdx+1:end]);
    
	%---Decode JSON-formatted sections---
    switch( FieldFormat )
        case 'json'
            LFP.(FieldName) = LFReadMetadata( LFP.(FieldName) );
    end
    
    FoundField = true;
end
end

