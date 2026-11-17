function [Data, Key, Header, DataDefined, Comment] = ReadLRN(FileName, Directory, Options)
% ReadLRN Read LRN format 2.0 or an old LRN file.
% [Data,Key,Header,DataDefined,Comment] = ReadLRN(FileName,Directory,Options)
% INPUT: FileName is the file name. Directory defaults to the current folder.
% OPTIONS: struct('Verbose',false). Warnings remain active.
% OUTPUT: Data is a numeric matrix. Key is a double column vector.
% Header is a character matrix. DataDefined is a row vector for Data.
% Type 0 columns are omitted, as in the original MATLAB function.
% Comment contains user comments. It does not contain the generation tag.
% AUTHOR: Alfred Ultsch
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% Based on the original MATLAB ReadLRN interface by Alfred Ultsch.
if nargin < 2, Directory = []; end
if nargin < 3, Options = []; end
Options = dataio_options(Options, struct('Verbose', false));
Result = dataio_call('read_lrn', struct('Path', dataio_path(FileName, Directory)), Options.Verbose);
DataDefined = Result.DataDefined(2:end)';
Use = DataDefined ~= 0;
Data = Result.Data(:, Use);
Key = Result.Key;
Header = char(Result.Header(Use));
DataDefined = DataDefined(Use);
Comment = Result.Comment;
end

