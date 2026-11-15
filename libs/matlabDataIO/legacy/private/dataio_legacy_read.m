function Result = dataio_legacy_read(FileName, Directory, Format)
% Read old layouts behind the original MATLAB interfaces. No writer is used.
% The old ReadLRN temporary-file path and external dbt helpers prevented a
% self-contained, read-only fallback. This parser keeps the old layout rules
% in one removable folder and uses only MATLAB R2012 functions.
% INPUT
% FileName  Legacy input file name; a missing extension is added.
% Directory  Input directory, or empty to use pwd.
% Format  Character row: lrn, cls, or names.
%

% OUTPUT
% Result contains Key, Comment, Types, Header, and Rest.
% LRN adds a numeric Data matrix. NAMES adds a Names character matrix.
% CLS adds a Cls vector. Rest holds additional NAMES fields as text cells.
% Invalid keys are NaN. LRN Types and Header omit key and ignored columns.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if isempty(Directory), Directory = pwd; end
[~,~,Extension] = fileparts(FileName);
if isempty(Extension), FileName = [FileName '.' Format]; end
if FileName(1) == '/' || FileName(1) == '\' || (numel(FileName)>1 && FileName(2)==':')
    File = FileName;
else
    File = fullfile(Directory, FileName);
end
Fid = fopen(File, 'rt');
if Fid < 0, error('DataIO:Legacy', 'Cannot open %s.', File); end
CloseFile = onCleanup(@() fclose(Fid)); %#ok<NASGU>
Header = {}; Body = {}; Comments = {}; Started = false;
while true
    Line = fgetl(Fid);
    if ~ischar(Line), break; end
    if numel(Line) >= 2 && Line(1) == '"' && Line(end) == '"', Line = Line(2:end-1); end
    if ~Started && isempty(Line), continue; end
    if ~Started && (strncmp(Line,'<?',2) || strncmp(Line,'#<?',3))
        Version = regexp(Line, 'version="([^"]+)"', 'tokens', 'once');
        if isempty(Version) || ~strcmp(Version{1},'1.0')
            error('DataIO:Legacy', 'This fallback reads only untagged files and version 1.0. Use the C++ package for format 2.0.');
        end
        continue;
    end
    if ~Started && ~isempty(Line) && Line(1) == '#'
        Comments{end+1} = strtrim(Line(2:end)); %#ok<AGROW>
    elseif ~Started && ~isempty(Line) && (Line(1) == '%' || strncmp(Line,'9%',2))
        if strncmp(Line,'9%',2), Line(1:2) = '%9'; end
        Header{end+1} = strtrim(Line(2:end)); %#ok<AGROW>
    else
        Started = true;
        Body{end+1} = Line; %#ok<AGROW>
    end
end
while ~isempty(Body) && isempty(Body{end}), Body(end) = []; end
N = numel(Body);
Result.Comment = char(Comments);
Result.Types = []; Result.Header = {}; Result.Rest = cell(N,0);
KeyColumn = 1;
if strcmp(Format,'lrn')
    if numel(Header) ~= 4, error('DataIO:Legacy', 'LRN requires four header lines.'); end
    Width = str2double(Header{2});
    Result.Types = sscanf(Header{3}, '%f')';
    Result.Header = regexp(Header{4}, '\s+', 'split');
    if ~isfinite(Width) || Width < 1 || Width ~= fix(Width) || numel(Result.Types) ~= Width || numel(Result.Header) ~= Width
        error('DataIO:Legacy', 'LRN column definitions do not match.');
    end
    KeyColumn = find(Result.Types == 9);
    if numel(KeyColumn) > 1, error('DataIO:Legacy', 'LRN has more than one Key column.'); end
elseif strcmp(Format,'names')
    if numel(Header) >= 3
        Width = str2double(Header{2});
        Result.Header = regexp(Header{3}, '\s+', 'split');
    elseif numel(Header) == 2
        Result.Header = regexp(Header{2}, '\s+', 'split');
        Width = numel(Result.Header);
    elseif N > 0
        Width = max(2, numel(regexp(Body{1}, '\t', 'split')));
    else
        Width = 2;
    end
    if ~isfinite(Width) || Width < 2 || Width ~= fix(Width), error('DataIO:Legacy', 'Invalid NAMES width.'); end
    if isempty(Result.Header)
        Result.Header = {'Key','Names'};
        for J=3:Width, Result.Header{J} = sprintf('C%d',J-2); end
    elseif numel(Result.Header) ~= Width
        error('DataIO:Legacy', 'NAMES column names do not match the declared width.');
    end
else
    Width = 2; % CLS colour headers do not define data columns.
end
if ~isempty(Header)
    Count = str2double(Header{1});
    if isfinite(Count) && Count ~= N
        warning('DataIO:Legacy', 'Row count differs. Keeping all data rows.');
    end
end
Result.Key = NaN(N,1);
if strcmp(Format,'names'), Values = repmat({'NA'},N,Width);
else, Values = NaN(N,Width); end
for I=1:N
    if strcmp(Format,'names') || ~isempty(strfind(Body{I},sprintf('\t')))
        Fields = regexp(Body{I}, '\t', 'split');
    else
        Fields = regexp(strtrim(Body{I}), '\s+', 'split');
    end
    if numel(Fields) ~= Width, warning('DataIO:Legacy', 'Row %d: fill missing fields and ignore extra fields.', I); end
    for J=1:min(Width,numel(Fields))
        if strcmp(Format,'names')
            if ~isempty(Fields{J}), Values{I,J} = Fields{J}; end
        else
            Values(I,J) = number(Fields{J});
        end
    end
    if ~isempty(KeyColumn) && KeyColumn <= numel(Fields)
        Text = Fields{KeyColumn}; Value = number(Text);
        % Check decimal text before double rounding can hide a fractional or large ID.
        if isfinite(Value) && Value == fix(Value) && abs(Value) <= 2^53 && exactKey(Text)
            Result.Key(I) = Value;
        else
            warning('DataIO:Legacy', 'Row %d has an invalid Key. Using NaN.', I);
        end
    end
end
if isempty(KeyColumn)
    warning('DataIO:MissingKey','No Key column. Using 1:n.'); Result.Key = (1:N)';
end
ValidKeys = Result.Key(~isnan(Result.Key));
if numel(unique(ValidKeys)) ~= numel(ValidKeys), warning('DataIO:Legacy','Keys are not unique.'); end
if strcmp(Format,'lrn')
    Use = Result.Types ~= 0 & Result.Types ~= 9;
    Result.Data = Values(:,Use); Result.Header = Result.Header(Use); Result.Types = Result.Types(Use);
elseif strcmp(Format,'names')
    Result.Names = char(Values(:,2)); Result.Rest = Values(:,3:end);
else
    Result.Cls = Values(:,2);
end
end

function Value = number(Text)
% Read a numeric prefix from a legacy cell.
%
% INPUT
% Text  Character row with a numeric prefix or a missing-value marker.
%
% OUTPUT
% Value is a double. Empty text, NA, NaN, and ? become NaN.
% Invalid text and ignored suffixes cause warnings.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Text = strtrim(Text);
if isempty(Text) || any(strcmpi(Text,{'NA','NaN','?'})), Value = NaN; return; end
Token = regexp(Text, '^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?|^[+-]?[Ii][Nn][Ff]', 'match', 'once');
if isempty(Token)
    warning('DataIO:Legacy','Invalid number. Using NaN.'); Value = NaN;
else
    Value = str2double(Token);
    if numel(Token) ~= numel(Text), warning('DataIO:Legacy','Keeping numeric prefix of %s.',Text); end
end
end

function Yes = lexicalGreater(A,B)
% Compare equal-length character sequences lexically.
%
% INPUT
% A  First character row.
% B  Second character row with the same length as A.
%
% OUTPUT
% Yes is true when the first different character in A is greater than in B.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

First = find(A ~= B, 1); Yes = ~isempty(First) && A(First) > B(First);
end

function Yes = exactKey(Text)
% Check a legacy key prefix without rounding it to double.
%
% INPUT
% Text  Character row with an optional decimal or exponent numeric prefix.
%
% OUTPUT
% Yes is true for a whole-number prefix in [-2^53, 2^53]; otherwise false.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Yes = false;
Token = regexp(strtrim(Text), '^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?', 'match', 'once');
if isempty(Token), return; end
Parts = regexp(Token, '[eE]', 'split');
Mantissa = regexprep(Parts{1}, '^[+-]', '');
Shift = 0;
if numel(Parts) == 2, Shift = str2double(Parts{2}); end
Point = find(Mantissa == '.', 1);
if ~isempty(Point), Shift = Shift - (numel(Mantissa) - Point); end
Digits = regexprep(strrep(Mantissa,'.',''), '^0+', '');
if isempty(Digits), Yes = true; return; end
if ~isfinite(Shift), return; end
if Shift < 0
    if -Shift >= numel(Digits) || any(Digits(end+Shift+1:end) ~= '0'), return; end
    Digits = Digits(1:end+Shift);
elseif numel(Digits) + Shift <= 16
    Digits = [Digits repmat('0',1,Shift)];
else
    return;
end
Yes = numel(Digits) < 16 || (numel(Digits) == 16 && ~lexicalGreater(Digits,'9007199254740992'));
end

