function WriteDates(FileName, Time, Data, Header, Key, Directory, Comment, Options)
% WriteDates Write DATES format 2.0 with UTC timestamps.
% WriteDates(FileName,Time,Data,Header,Key,Directory,Comment,Options)
% INPUT: Time is a datetime vector or UTC text. Data is a full real numeric
% matrix with one row per time. Header names only the numeric columns.
% Text formats: yyyy-MM-dd, yyyy-MM-dd HH:mm:ss, yyyy-MM-dd HH:mm:ss.SSS.
% Zoned datetimes are converted to UTC. Unzoned datetimes are treated as UTC
% with a warning. NaT and empty time text become 'NA'.
% OPTIONS: Format=-1 (input resolution), 1 (date), 2 (seconds), or 3 (ms);
% Overwrite=true; Verbose=false. No legacy DATES writer is provided.
% Numeric TZ_DST offsets such as +11, +1030, and -02 are not accepted.
% OUTPUT
% A DATES format 2.0 file with UTC times. The function has no return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 3, Data = []; end
if nargin < 4, Header = []; end
if nargin < 5, Key = []; end
if nargin < 6, Directory = []; end
if nargin < 7, Comment = []; end
if nargin < 8, Options = []; end
if isdatetime(Time)
    if ~isvector(Time), error('DataIO:Time', 'Time must be a vector.'); end
    if isempty(Time.TimeZone)
        warning('DataIO:Timezone', 'Time has no time zone. Treating the values as UTC.');
    end
    Missing = isnat(Time);
    Time.TimeZone = 'UTC';
    Time.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
    Time = cellstr(string(Time(:)));
    Time(Missing) = {'NA'};
else
    Time = dataio_texts(Time);
end
if ~isvector(Time), error('DataIO:Time', 'Time must have one value per row.'); end
Time = Time(:);
if isempty(Data), Data = zeros(numel(Time), 0); end
% Text input must already be UTC. Do not silently discard a supplied zone.
Pattern = '^\d{4}-\d{2}-\d{2}( \d{2}:\d{2}:\d{2}(\.\d{3})?)?$';
if any(~strcmp(Time, 'NA') & cellfun(@isempty, regexp(Time, Pattern, 'once')))
    error('DataIO:Time', 'Use UTC date/time text without a zone suffix, or use a zoned datetime vector.');
end
Data = dataio_numeric(Data);
if size(Data, 1) ~= numel(Time), error('DataIO:Time', 'Data and Time must have the same number of rows.'); end
Header = dataio_texts(Header, false);
if isempty(Header), Header = arrayfun(@(x) sprintf('C%d', x), 1:size(Data, 2), 'UniformOutput', false); end
if numel(Header) ~= size(Data, 2), error('DataIO:Header', 'Supply one header for each numeric column.'); end
Comment = dataio_comment(Comment);
if ~isempty(regexp(Comment, '(^|\n)\s*Timezone:', 'once'))
    error('DataIO:Timezone', 'Do not put Timezone metadata in Comment. This writer uses UTC.');
end
Options = dataio_options(Options, struct('Overwrite', true, 'Verbose', false, 'Format', -1));
Request = Options;
Request.Path = dataio_path(FileName, Directory);
Request.Time = Time;
Request.Data = Data;
Request.Header = Header;
Request.Key = dataio_keys(Key, numel(Time));
Request.Comment = ['Timezone: UTC', sprintf('\n'), Comment];
dataio_call('write_dates', Request, Options.Verbose);
end

