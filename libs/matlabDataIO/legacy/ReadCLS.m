function [Key,Cls,Comment,UniqueClasses,ClassColors] = ReadCLS(FileName,Directory,Int4NaN)
% ReadCLS Read old CLS files without a compiler. Colour metadata is ignored.
% INPUT
% FileName  Input file name.
% Directory  Optional input directory; empty or absent uses pwd.
% Int4NaN  Optional replacement for missing class values.
%

% OUTPUT
% Key, Cls, Comment, and UniqueClasses from a legacy CLS file.
% ClassColors is empty. Int4NaN can replace missing class values.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 2, Directory = []; end
Result = dataio_legacy_read(FileName,Directory,'cls');
Key = Result.Key; Cls = Result.Cls; Comment = Result.Comment;
UniqueClasses = unique(Cls); ClassColors = [];
if nargin >= 3 && ~isempty(Int4NaN), Cls(isnan(Cls)) = Int4NaN; end
end

