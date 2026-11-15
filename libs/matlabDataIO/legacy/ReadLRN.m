function [Data,Key,Header,DataDefined,Comment] = ReadLRN(FileName,Directory)
% ReadLRN Read old LRN files without a compiler. This fallback is read-only.
% The original output order is retained. Use the C++ package for format 2.0.
% INPUT
% FileName  Input file name.
% Directory  Optional input directory; empty or absent uses pwd.
%

% OUTPUT
% Data is a numeric matrix; Key is a double column vector.
% Header is a character matrix. DataDefined contains the retained column types.
% Type 0 and type 9 columns are excluded from Data. Comment is a character matrix.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 2, Directory = []; end
Result = dataio_legacy_read(FileName,Directory,'lrn');
Data = Result.Data; Key = Result.Key; Header = char(Result.Header);
DataDefined = Result.Types; Comment = Result.Comment;
end

