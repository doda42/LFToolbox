% LFVar2Struct - Convenience function to build a struct from a set of variables
%
% Usage:
%     StructOut = LFVar2Struct( var1, var2, ... )
% 
% Example:
%     Apples = 3;
%     Oranges = 4;
%     FruitCount = LFVar2Struct( Apples, Oranges )
%
%     Results in a struct FruitCount:
%         FruitCount = 
%            Apples: 3
%            Oranges: 4
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFStruct2Var

% Copyright (c) 2013-2020 Donald G. Dansereau

function StructOut = LFVar2Struct( varargin )

VarNames = arrayfun( @inputname, 1:nargin, 'UniformOutput', false );
StructOut = cell2struct( varargin, VarNames, 2 );

end
