% LFDefaultField - Convenience function to set up structs with default field values
% 
% Usage: 
% 
%   ParentStruct = LFDefaultField( ParentStruct, FieldName, DefaultVal )
% 
% This provides an elegant way to establish default field values in a struct. See LFDefaultValue for
% setting up non-struct variables with default values. 
% 
% Inputs:
% 
%   ParentStruct: string giving the name of the struct; the struct need not already exist
%   FieldName: string giving the name of the field
%   DefaultVal: default value for the field
%
% Outputs:
% 
%   ParentStruct: if the named struct and field already existed, the output matches the struct's
%                 original value; otherwise the output is a struct with an additional field taking
%                 on the specified default value
% 
% Example: 
% 
%   clearvars
%   ExistingStruct.ExistingField = 42;
%   ExistingStruct = LFDefaultField( 'ExistingStruct', 'ExistingField', 3 )
%   ExistingStruct = LFDefaultField( 'ExistingStruct', 'NewField', 36 )
%   OtherStruct = LFDefaultField( 'OtherStruct', 'Cheese', 'Indeed' )
%   
% 
%   Results in :
%       ExistingStruct = 
%           ExistingField: 42
%                NewField: 36
%       OtherStruct = 
%                  Cheese: 'Indeed'
%
% Usage for setting up default function arguments is demonstrated in most of the LF Toolbox
% functions.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDefaultVal

% Copyright (c) 2013-2020 Donald G. Dansereau

function ParentStruct = LFDefaultField( ParentStruct, FieldName, DefaultVal )

%---First make sure the struct exists---
CheckIfExists = sprintf('exist(''%s'', ''var'') && ~isempty(%s)', ParentStruct, ParentStruct);
VarExists = evalin( 'caller', CheckIfExists );
if( ~VarExists )
    ParentStruct = [];
else
    ParentStruct = evalin( 'caller', ParentStruct );
end

%---Now make sure the field exists---
if( ~isfield( ParentStruct, FieldName ) )
    ParentStruct.(FieldName) = DefaultVal;
end

end
