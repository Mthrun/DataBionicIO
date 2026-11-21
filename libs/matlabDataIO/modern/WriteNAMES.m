function WriteNAMES(FileName, Names, Key, RowRest, Directory, DescriptionHeader, Comment, Options)
% WriteNAMES Write text rows as NAMES format 2.0.
% WriteNAMES(FileName,Names,Key,RowRest,Directory,DescriptionHeader,Comment,Options)
% INPUT: Names is a character matrix, a string vector, or a cell vector.
% OPTIONAL: Missing Key uses 1:n with a warning. Directory defaults to pwd.
% As in the old function, omitted RowRest or [] repeats Names. Use cell(n,0) for none.
% RowRest is a text matrix, or one text cell per row with tab-separated fields.
% DescriptionHeader names the extra columns, or all text columns, optionally
% with Key. Empty text becomes 'NA'. Text values can start with digits.
% OPTIONS: struct('Overwrite',true,'Verbose',false).
% TextReplacement optionally changes the default underscore for forbidden characters.
% SplitTabs preserves the old RowRest layout by default. The common interface disables it.
% OUTPUT
% A NAMES format 2.0 file. The function has no return value.
% AUTHOR: Alfred Ultsch
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% Based on the original MATLAB WriteNAMES interface by Alfred Ultsch.

if nargin < 3, Key = []; end
Names = dataio_texts(Names);
if ~isvector(Names), error('DataIO:Names', 'Names must have one value per row.'); end
Names = Names(:);
if nargin < 4 || (isempty(RowRest) && ~iscell(RowRest)), RowRest = Names; end
if nargin < 5, Directory = []; end
if nargin < 6, DescriptionHeader = []; end
if nargin < 7, Comment = []; end
if nargin < 8, Options = []; end
Options = dataio_options(Options, struct('Overwrite', true, 'Verbose', false, ...
    'TextReplacement', '_', 'SplitTabs', true));
if isempty(RowRest)
    RowRest = cell(numel(Names), 0);
else
    RowRest = dataio_texts(RowRest);
    if size(RowRest, 1) ~= numel(Names), error('DataIO:Names', 'RowRest must have one row per Name.'); end
    % The old reader joins extra columns with tabs. Split these rows on write.
    if Options.SplitTabs && size(RowRest, 2) == 1
        Parts = cellfun(@(x) regexp(x, '\t', 'split'), RowRest, 'UniformOutput', false);
        Width = max(cellfun(@numel, Parts));
        RowRest = repmat({'NA'}, numel(Names), Width);
        for I = 1:numel(Names), RowRest(I, 1:numel(Parts{I})) = Parts{I}; end
        RowRest = dataio_texts(RowRest);
    end
end

Request = Options;
Request.TextReplacement = dataio_text_option({'TextReplacement', Request.TextReplacement}, 'TextReplacement', '_');
Request.Path = dataio_path(FileName, Directory);
Request.Names = Names;
Request.Key = dataio_keys(Key, numel(Names));
Request.FurtherTexts = RowRest;
Request.Header = dataio_texts(DescriptionHeader, false);
Request.Comment = dataio_comment(Comment);
dataio_call('write_names', Request, Options.Verbose);
end

