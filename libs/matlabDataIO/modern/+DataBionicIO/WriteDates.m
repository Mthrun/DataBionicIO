function WriteDates(FileName, TSdata, Key, OutDirectory, Comments, tz, Format, Overwrite, Verbose)
% WriteDates Write DTS with the common DataBionicIO argument order.
% INPUT
% FileName  Output file name.
% TSdata  Table, cell matrix with times first, or vector of times.
% A table column named Time supplies times; otherwise its first column does.
% Other columns contain numeric measurements. Optional DST contains abbreviations.
% Key  Optional unique numeric keys; empty uses 1:n with a warning.
% OutDirectory  Optional output directory; default pwd.
% Comments  Optional comment text; default empty.
% tz  Optional IANA time zone. Default: input datetime zone, otherwise UTC.
% Format  Empty selects input resolution; 1 dates, 2 seconds, 3 milliseconds.
% Overwrite  Optional replacement permission; default true.
% Verbose  Optional information-message flag; default true.
% OUTPUT
% A format 2.0 DTS file. No return value.
% Zoned datetime values keep their instants and are expressed in tz.
% Text and unzoned datetime values are local times in tz.
% Numeric DST abbreviations are not supported by the shared parser.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 3, Key = []; end
if nargin < 4 || isempty(OutDirectory), OutDirectory = pwd; end
if nargin < 5, Comments = []; end
if nargin < 6, tz = []; end
if nargin < 7 || isempty(Format), Format = -1; end
if nargin < 8 || isempty(Overwrite), Overwrite = true; end
if nargin < 9 || isempty(Verbose), Verbose = true; end
Markers = [];
if istable(TSdata)
    Labels = TSdata.Properties.VariableNames;
    TimeIndex = find(strcmp(Labels, 'Time'), 1);
    if isempty(TimeIndex), TimeIndex = 1; end
    Time = TSdata{:, TimeIndex};
    DSTIndex = find(strcmp(Labels, 'DST'), 1);
    if ~isempty(DSTIndex), Markers = TSdata{:, DSTIndex}; end
    Numeric = setdiff(1:width(TSdata), [TimeIndex, DSTIndex], 'stable');
    if isempty(Numeric), Data = zeros(numel(Time), 0);
    else, Data = TSdata{:, Numeric}; end
    Header = Labels(Numeric);
elseif iscell(TSdata) && ~isvector(TSdata)
    Time = TSdata(:, 1); Data = cell2mat(TSdata(:, 2:end)); Header = [];
elseif iscell(TSdata) && size(TSdata, 1) == 1 && size(TSdata, 2) > 1 && ~all(cellfun(@ischar, TSdata))
    Time = TSdata(:, 1); Data = cell2mat(TSdata(:, 2:end)); Header = [];
else
    Time = TSdata; Data = zeros(numel(Time), 0); Header = [];
end
if isempty(tz)
    if isdatetime(Time) && ~isempty(Time.TimeZone), tz = Time.TimeZone;
    else, tz = 'UTC'; end
end
tz = char(tz);
% Validate the zone independently of whether Time contains native datetimes.
datetime(2000, 1, 1, 'TimeZone', tz);
if isdatetime(Time)
    if any(isnat(Time(:))), error('DataIO:Time', 'Times cannot contain missing values.'); end
    Time.TimeZone = tz;
    if Format == 1
        Time = cellstr(Time(:), 'yyyy-MM-dd', 'en_US');
    else
        Time = cellstr(Time(:), 'yyyy-MM-dd HH:mm:ss.SSS z', 'en_US');
        if any(cellfun(@isempty, regexp(Time, ' [A-Za-z]+$', 'once')))
            error('DataIO:Timezone', 'The DTS parser cannot store this zone abbreviation. Use tz=''UTC''.');
        end
    end
    if ~isempty(Markers), error('DataIO:Time', 'DST is derived from datetime input. Omit the DST column.'); end
else
    Time = cellstr(string(Time(:)));
    if any(ismember(Time, {'NA','NaT','<missing>',''})), error('DataIO:Time', 'Times cannot contain missing values.'); end
    if ~isempty(Markers)
        Markers = cellstr(string(Markers(:)));
        if numel(Markers) ~= numel(Time), error('DataIO:Time', 'DST must have one value per time.'); end
        Time = cellfun(@(T, M) [T ' ' M], Time, Markers, 'UniformOutput', false);
    end
end
if isempty(Header), Header = arrayfun(@(I) sprintf('C%d', I), 1:size(Data, 2), 'UniformOutput', false); end
Request = struct('Path', fullfile(OutDirectory, FileName), 'Format', Format, 'Overwrite', Overwrite);
Request.Key = Key; Request.Data = Data; Request.Comment = Comments;
Request.Time = Time; Request.Header = Header; Request.Timezone = tz;
dataio_common('write_dates', Request, Verbose);
end
