function hydrology(InDirectory, OutDirectory)
% INPUT
% Input path and optional output directory.
% OUTPUT
% A DTS copy and a comparison of its keys.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 1, InDirectory = fullfile('examples', 'tutorials', 'data'); end
if nargin < 2, OutDirectory = fullfile('build', 'tutorials', 'hydrology', 'matlab'); end
if ~isfolder(OutDirectory), mkdir(OutDirectory); end
[Key, Time, Data, Header, Comments, Timezone] = ...
    DataBionicIO.ReadDates('HydrologyDaily2013_2014.dts', InDirectory, false);

% Keep the calendar dates. The source does not identify an acquisition time zone.
TSdata = array2table(Data, 'VariableNames', cellstr(string(Header(:)))');
TSdata = addvars(TSdata, Time, 'Before', 1, 'NewVariableNames', 'Time');
DataBionicIO.WriteDates('Hydrology_copy', TSdata, Key, OutDirectory, ...
    Comments, Timezone, 1, false, false);
Key2 = ...
    DataBionicIO.ReadDates('Hydrology_copy', OutDirectory, false);
assert(TheSameKey(Key, Key2));
fprintf('Hydrology example complete.\n');
end
