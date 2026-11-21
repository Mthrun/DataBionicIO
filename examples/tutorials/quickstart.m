% INPUT
% DataBionicIO selected with setupDataIO('modern').
% OUTPUT
% An LRN file in a temporary directory and a comparison of its keys.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

% Example starts here
OutDirectory = tempname;
mkdir(OutDirectory);
Data = [1.5 2; 3.5 NaN];
Key = [101; 205];
DataBionicIO.WriteLRN('example', Data, {'Length','Mass'}, Key, ...
    [], OutDirectory, '', [], [], false, false, false);
Key2 = DataBionicIO.ReadLRN('example', OutDirectory, false);
assert(TheSameKey(Key, Key2));
fprintf('Quick start complete.\n');
