%todo[doc]
% todo[refactor]: use this throughout code instead of doing manually

function [LF, Metadata] = LFRead( Fname )

if( strfind( Fname, '.eslf' ) )
	[LF, Metadata] = LFReadESLF( Fname );
elseif( strcmp(Fname(end-length('.mat')+1:end), '.mat') )
	Metadata = load( Fname );
	LF = Metadata.LF;
	Metadata = rmfield(Metadata, 'LF');
else
	error('unknown file format\n');
end