% LFStruct2Var - Convenience function to break a subset of variables out of a struct
%
% Usage:
%     [var1, var2, ...] = LFStruct2Var( StructIn, 'var1', 'var2', ... )
% 
% This would ideally exclude the named variables in the argument list, but there was no elegant way
% to do this given the absence of an `outputname' function to match Matlab's `inputname'.
% 
% Example:
%     FruitCount = struct('Apples', 3, 'Bacon', 42, 'Oranges', 4);
%     [Apples, Oranges] = LFStruct2Var( FruitCount, 'Apples', 'Oranges' )
% 
%     Results in
%          Apples =
%               3
%          Oranges =
%               4
%
% User guide: <a href="matlab:which LFToolbox.pdf; open('LFToolbox.pdf')">LFToolbox.pdf</a>
% See also: LFVar2Struct

% Copyright (c) 2013-2020 Donald G. Dansereau

function varargout = LFStruct2Var( StructIn, varargin )

for( i=1:length(varargin) )
    varargout{i} = StructIn.(varargin{i});
end

end
