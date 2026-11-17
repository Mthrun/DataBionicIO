function [Key, Names, RowRest, Comment, Header, FurtherTexts] = ReadNAMES(FileName, Directory, Options)
% ReadNAMES Read NAMES format 2.0 or an old NAMES file.
% [Key,Names,RowRest,Comment,Header,FurtherTexts] = ReadNAMES(FileName,Directory,Options)
% OPTIONS: struct('Verbose',false). Directory defaults to pwd.
% INPUT
% FileName  Input file name.
% Directory  Optional input directory; empty or absent uses pwd.
% Options  Optional struct with the Verbose field; default false.
%

% OUTPUT: Key is a double column vector. Names and Header are character matrices.
% RowRest is one cell per row, with tabs between additional text fields.
% FurtherTexts is an optional cell matrix, with one cell per field.
% Empty text fields and missing text fields contain 'NA'.
% AUTHOR: Alfred Ultsch
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% Based on the original MATLAB ReadNAMES interface by Alfred Ultsch.
if nargin < 2, Directory = []; end
if nargin < 3, Options = []; end
Options = dataio_options(Options, struct('Verbose', false));
Result = dataio_call('read_names', struct('Path', dataio_path(FileName, Directory)), Options.Verbose);
Key = Result.Key; Names = char(Result.Names); Header = char(Result.Header);
Comment = Result.Comment; FurtherTexts = Result.FurtherTexts;
RowRest = cell(numel(Key), 1);
for I = 1:numel(Key), RowRest{I} = strjoin(FurtherTexts(I, :), sprintf('\t')); end
end

