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
%   TopStruct.NestedStruct = LFDefaultField( 'TopStruct.NestedStruct', 'HasAField', 'yes' )
%
%   Results in :
%       ExistingStruct =
%           ExistingField: 42
%                NewField: 36
%       OtherStruct =
%                Cheese: 'Indeed'
%       TopStruct.NestedStruct =
%                HasAField: 'yes'
% 
% Usage for setting up default function arguments is demonstrated in most of the LF Toolbox
% functions.
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFDefaultVal

% Copyright (c) 2013-2020 Donald G. Dansereau
%
% Enabled nested structs, 2025, Donald Dansereau

function ParentStruct = LFDefaultField( ParentStruct, FieldName, DefaultVal )

%---First make sure the struct exists---
try
    ParentStruct = evalin( 'caller', ParentStruct );
catch ME
    switch ME.identifier
        case 'MATLAB:undefinedVarOrClass'
        case 'MATLAB:UndefinedFunction'
        case 'MATLAB:nonExistentField'
        otherwise
            rethrow(ME); % Unexpected error - rethrow it
    end
    ParentStruct = [];
end

%---Now make sure the field exists---
if( ~isfield( ParentStruct, FieldName ) )
    ParentStruct.(FieldName) = DefaultVal;
end

end
