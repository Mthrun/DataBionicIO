function [Time, Data, Key, Header, Comment, Timezone, TZ_DST] = ReadDates(FileName, Directory, Options)
% ReadDates Read DATES through the shared C++ reader.
% [Time,Data,Key,Header,Comment,Timezone,TZ_DST] = ReadDates(FileName,Directory,Options)
% INPUT: FileName uses .dts, or the .csv extension accepted by the core.
% OPTIONS: struct('Verbose',false). Directory defaults to pwd.
% OUTPUT: Time is a cell vector of file time text. No time-zone conversion is
% done. Missing times contain 'NA'. Data is a numeric matrix. Key is a double
% vector. Header names the numeric columns. Timezone and TZ_DST keep metadata.
% This function returns TZ_DST as text; it does not interpret offsets such as
% +11, +1030, or -02. WriteDates accepts UTC text or zoned datetime input.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2, Directory = []; end
if nargin < 3, Options = []; end
Options = dataio_options(Options, struct('Verbose', false));
Result = dataio_call('read_dates', struct('Path', dataio_path(FileName, Directory)), Options.Verbose);
Time = Result.Time; Data = Result.Data; Key = Result.Key;
Header = char(Result.Header(3:end));
Comment = Result.Comment; Timezone = Result.Timezone; TZ_DST = Result.DST;
end

