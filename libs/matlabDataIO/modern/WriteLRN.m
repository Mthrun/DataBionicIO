function WriteLRN(FileName, Data, Header, Key, DataDefined, Directory, CommentOrDigits, Scientific, Digits, Options)
% WriteLRN Write a full real numeric matrix as LRN format 2.0.
% WriteLRN(FileName,Data,Header,Key,DataDefined,Directory,Comment,Scientific,Digits,Options)
% OPTIONAL: Header and DataDefined can include the leading Key entry.
% Missing Key gives a warning and uses 1:n. Directory defaults to pwd.
% Argument 7 can be a comment or the old numeric Digits argument.
% Old Digits sets decimal places (fixed notation) or mantissa decimal
% places (scientific notation). Without explicit precision, use 17 significant
% digits. As before, Scientific defaults
% to true with fewer than seven inputs, and to false when argument 7 is given.
% OPTIONS: Overwrite=true, Verbose=false, SignificantDigits=-1, DecimalDigits=-1.
% Explicit precision options replace the old Digits setting.
% SignificantDigits applies to each value in either notation. DecimalDigits=0
% rounds to whole numbers. Redundant fractional zeros are removed.
% INPUT
% FileName  Output file name.
% Data  Full real numeric matrix with records in rows.
% Header  Optional text labels for data, with an optional leading Key label.
% Key  Optional unique keys in [-2^53, 2^53].
% DataDefined  Optional column type codes.
% Directory  Optional output directory; the default is pwd.
% CommentOrDigits  Optional comment text or legacy decimal-place setting.
% Scientific  Optional flag selecting exponent notation.
% Digits  Optional legacy decimal-place setting.
% Options  Optional struct with overwrite, verbosity, and precision settings.
%

% OUTPUT
% An LRN format 2.0 file. The function has no return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 3, Header = []; end
if nargin < 4, Key = []; end
if nargin < 5, DataDefined = []; end
if nargin < 6, Directory = []; end
if nargin < 7, CommentOrDigits = []; end
if nargin < 8 || isempty(Scientific), Scientific = nargin < 7; end
if nargin < 9, Digits = []; end
if nargin < 10, Options = []; end
Data = dataio_numeric(Data);
Comment = '';
OldDigits = [];
if isnumeric(CommentOrDigits) && ~isempty(CommentOrDigits)
    OldDigits = CommentOrDigits;
else
    Comment = dataio_comment(CommentOrDigits);
end
if ~isempty(Digits), OldDigits = Digits; end
if ~isempty(OldDigits) && (~isnumeric(OldDigits) || ~isscalar(OldDigits) || ~isfinite(OldDigits) || OldDigits < 0 || OldDigits ~= fix(OldDigits))
    error('DataIO:Precision', 'Digits must be a nonnegative whole number.');
end
Options = dataio_options(Options, struct('Overwrite', true, 'Verbose', false, ...
    'SignificantDigits', -1, 'DecimalDigits', -1, 'Scientific', Scientific));
if Options.SignificantDigits == -1 && Options.DecimalDigits == -1
    if isempty(OldDigits), Options.SignificantDigits = 17;
    elseif Options.Scientific, Options.SignificantDigits = OldDigits + 1;
    else, Options.DecimalDigits = OldDigits; end
end
Request = Options;
Request.Path = dataio_path(FileName, Directory);
Request.Data = Data;
Request.Header = dataio_texts(Header, false);
Request.Key = dataio_keys(Key, size(Data, 1));
Request.DataDefined = dataio_numeric(DataDefined);
Request.Comment = Comment;
dataio_call('write_lrn', Request, Options.Verbose);
end

