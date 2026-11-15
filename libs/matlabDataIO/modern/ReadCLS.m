function [Key, Cls, Comment, UniqueClasses, ClassColors] = ReadCLS(FileName, Directory, Int4NaN, Options)
% ReadCLS Read CLS format 2.0 or an old CLS file.
% [Key,Cls,Comment,UniqueClasses,ClassColors] = ReadCLS(FileName,Directory,Int4NaN,Options)
% OPTIONAL: Directory defaults to pwd. Int4NaN replaces missing class values.
% Options is struct('Verbose',false). Warnings remain active.
% INPUT
% FileName  Input file name.
% Directory  Optional input directory; empty or absent uses pwd.
% Int4NaN  Optional replacement for missing class values.
% Options  Optional struct with the Verbose field; default false.
%

% OUTPUT: Key and Cls are double column vectors. ClassColors is always empty.
% UniqueClasses comes from the file reader, before optional NaN replacement.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2, Directory = []; end
if nargin < 3, Int4NaN = []; end
if nargin < 4, Options = []; end
Options = dataio_options(Options, struct('Verbose', false));
Result = dataio_call('read_cls', struct('Path', dataio_path(FileName, Directory)), Options.Verbose);
Key = Result.Key; Cls = Result.Cls; Comment = Result.Comment;
UniqueClasses = Result.UniqueClasses; ClassColors = [];
if ~isempty(Int4NaN)
    validateattributes(Int4NaN, {'numeric'}, {'real','scalar'});
    Cls(isnan(Cls)) = Int4NaN;
end
end

