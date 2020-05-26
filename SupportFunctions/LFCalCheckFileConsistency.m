function [FileList, InvalidIdx] = LFCalFindInputImages( InputPath, CalOptions )

%---Crawl folder structure locating raw lenslet images---
fprintf('\n===Locating light fields in %s===\n', InputPath);
[FileList, BasePath] = LFFindFilesRecursive( InputPath, CalOptions.LFFnamePattern );
if( isempty(FileList) )
	error(['No files found... are you running from the correct folder?\n'...
		'       Current folder: %s\n'], pwd);
end
fprintf('Found :\n');
disp(FileList)

%---Check zoom / focus and serial number settings across light fields---
fprintf('Checking zoom / focus / serial number across all files...\n');
for( iFile = 1:length(FileList) )
	CurFname = FileList{iFile};
	if( strfind( CurFname, '.eslf' ) )
		MetadataFname = [CurFname,'.json'];
		MetadataFname = fullfile(BasePath, MetadataFname);
		AllMetadata = LFReadMetadata( MetadataFname );
		LFMetadata = AllMetadata.LFMetadata;
	elseif( strfind( CurFname, '.mat' ) )
		load(fullfile(BasePath, CurFname), 'LFMetadata');
	else
		error('unknown file format\n');
	end
	
	CamSettings(iFile).Fname = CurFname;
	CamSettings(iFile).ZoomStep = LFMetadata.devices.lens.zoomStep;
	CamSettings(iFile).FocusStep = LFMetadata.devices.lens.focusStep;
	CamSettings(iFile).CamSerial = LFMetadata.SerialData.camera.serialNumber;
end

% Find the most frequent serial number
[UniqueSerials,~,SerialIdx]=unique({CamSettings.CamSerial});
NumSerials = size(UniqueSerials,2);
MostFreqSerialIdx = median(SerialIdx);
CamInfo.CamSerial = UniqueSerials{MostFreqSerialIdx};
CamInfo.CamModel = LFMetadata.camera.model;

% Finding the most frequent zoom / focus is easier
CamInfo.FocusStep = median([CamSettings.FocusStep]);
CamInfo.ZoomStep = median([CamSettings.ZoomStep]);
fprintf( 'Serial: %s, ZoomStep: %d, FocusStep: %d\n', CamInfo.CamSerial, CamInfo.ZoomStep, CamInfo.FocusStep );
InvalidIdx = find( ...
	([CamSettings.ZoomStep] ~= CamInfo.ZoomStep) | ...
	([CamSettings.FocusStep] ~= CamInfo.FocusStep) | ...
	(SerialIdx ~= MostFreqSerialIdx)' );

if( ~isempty(InvalidIdx) )
	warning('Some files mismatch');
	for( iInvalid = InvalidIdx )
		fprintf('Serial: %s, ZoomStep: %d, FocusStep: %d -- %s\n', CamSettings(iInvalid).CamSerial, CamSettings(iInvalid).ZoomStep, CamSettings(iInvalid).FocusStep, CamSettings(iInvalid).Fname);
	end
	fprintf('For significant deviations, it is recommended that these files be removed and the program restarted.');
else
	fprintf('...all files match\n');
end