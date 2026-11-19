function Result = dataio_common(Command, Request, Verbose)
% Call the shared gateway from the DataBionicIO namespace.
% INPUT
% Command  Native reader or writer command.
% Request  Gateway fields; Path is converted to a character row.
% Verbose  Logical information-message flag.
% OUTPUT
% The gateway result, with diagnostics delivered through MATLAB.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Request.Path = char(Request.Path);
if strcmp(Command, 'write_dates')
    Request.Time = dataio_texts(Request.Time);
    Request.Data = dataio_numeric(Request.Data);
    if size(Request.Data, 1) ~= numel(Request.Time)
        error('DataIO:Time', 'Data must have one row per time.');
    end
    Request.Key = dataio_keys(Request.Key, numel(Request.Time));
    Request.Header = dataio_texts(Request.Header, false);
    Request.Comment = dataio_comment(Request.Comment);
    if ~isempty(regexp(Request.Comment, '(^|\n)\s*Timezone:', 'once'))
        error('DataIO:Timezone', 'Use tz for the time zone declaration.');
    end
    Request.Comment = ['Timezone: ', Request.Timezone, sprintf('\n'), Request.Comment];
end
Result = dataio_call(Command, Request, Verbose);
end
