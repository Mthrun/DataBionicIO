function hepta(InDirectory, OutDirectory)
% INPUT
% Input path and optional output directory.
% OUTPUT
% Three Hepta files, class counts, and key comparisons.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 1, InDirectory = fullfile('examples', 'tutorials', 'data'); end
if nargin < 2, OutDirectory = fullfile('build', 'tutorials', 'hepta', 'matlab'); end
if ~isfolder(OutDirectory), mkdir(OutDirectory); end
[Key, Data, Header, DataDefined, Comments] = DataBionicIO.ReadLRN('hepta', InDirectory, false);
[ClassKey, Cls, ~, ClassComments] = DataBionicIO.ReadCLS('hepta', InDirectory, false);
[NameKey, Names, ~, ~, NameComments] = DataBionicIO.ReadNAMES('hepta', InDirectory, false);

% Align the companion records with the measurement keys.
if ~TheSameKey(Key, ClassKey)
    [~, ClassRows] = ismember(Key, ClassKey);
    Cls = Cls(ClassRows);
    ClassKey = ClassKey(ClassRows);
    assert(TheSameKey(Key, ClassKey));
end
if ~TheSameKey(Key, NameKey)
    [~, NameRows] = ismember(Key, NameKey);
    Names = Names(NameRows);
    NameKey = NameKey(NameRows);
    assert(TheSameKey(Key, NameKey));
end
Counts = arrayfun(@(k) sum(Cls == k), (1:7)');
disp(Counts);

DataBionicIO.WriteLRN('hepta_copy', Data, Header, Key, DataDefined, ...
    OutDirectory, Comments, [], [], false, false, false);
DataBionicIO.WriteCLS('hepta_copy', Cls, OutDirectory, Key, ClassComments, [], false, false);
DataBionicIO.WriteNAMES('hepta_copy', Names, Key, [], {'Key', 'Names'}, ...
    OutDirectory, NameComments, false, false);
Key2 = DataBionicIO.ReadLRN('hepta_copy', OutDirectory, false);
ClassKey2 = DataBionicIO.ReadCLS('hepta_copy', OutDirectory, false);
NameKey2 = DataBionicIO.ReadNAMES('hepta_copy', OutDirectory, false);
assert(TheSameKey(Key, Key2));
assert(TheSameKey(Key, ClassKey2));
assert(TheSameKey(Key, NameKey2));
fprintf('Hepta example complete.\n');
end
