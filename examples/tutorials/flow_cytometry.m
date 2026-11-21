function flow_cytometry(InFile, OutDirectory)
% INPUT
% InFile: path to 01SampleDresdenD10n440K.lrn.
% OutDirectory: directory for the selected rows.
% OUTPUT
% An LRN file with the first 1000 rows and a comparison of its keys.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

% Example starts here
if nargin < 2, OutDirectory = fullfile('build', 'tutorials', 'flow-cytometry', 'matlab'); end
[InDirectory, FileName, Extension] = fileparts(InFile);
if isempty(InDirectory), InDirectory = pwd; end
if ~isfolder(OutDirectory), mkdir(OutDirectory); end
[Key, Data, Header, DataDefined, Comments] = ...
    DataBionicIO.ReadLRN([FileName Extension], InDirectory, false);

% Select the same rows for measurements and keys.
Rows = 1:1000;
DataBionicIO.WriteLRN('Dresden_subset', Data(Rows,:), Header, Key(Rows), ...
    DataDefined, OutDirectory, Comments, [], [], false, false, false);
Key2 = ...
    DataBionicIO.ReadLRN('Dresden_subset', OutDirectory, false);
assert(TheSameKey(Key(Rows), Key2));
fprintf('Flow cytometry example complete.\n');
end
