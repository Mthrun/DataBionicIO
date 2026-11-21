function [Key, Time, Data, Header, Comments, Timezone, DST] = ReadDates(FileName, InDirectory, Verbose, varargin)
% ReadDates Read Dates through the common DataBionicIO interface.
% INPUT
% FileName  Input file name.
% InDirectory  Optional input directory; default pwd.
% Verbose  Optional information-message flag; default true.
% varargin  Optional Encoding name-value pair; normally unnecessary.
% OUTPUT
% Key, Time, Data, Header, Comments, Timezone, DST in this fixed order.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2 || isempty(InDirectory), InDirectory = pwd; end
if nargin < 3 || isempty(Verbose), Verbose = true; end
Result = dataio_common('read_dates', struct('Path', fullfile(InDirectory, FileName), ...
    'Encoding', dataio_text_option(varargin, 'Encoding', '')), Verbose);
Result.Header = Result.Header(3:end);
Key = Result.Key;
Time = Result.Time;
Data = Result.Data;
Header = Result.Header;
Comments = Result.Comment;
Timezone = Result.Timezone;
DST = Result.DST;
end
