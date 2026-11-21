function Summary = firebrowse(InDirectory, OutDirectory)
% INPUT
% Input path and optional output directory.
% OUTPUT
% A NAMES copy, key comparisons, and the diagnosis-count table Summary.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 1, InDirectory = fullfile('examples', 'tutorials', 'data'); end
if nargin < 2, OutDirectory = fullfile('build', 'tutorials', 'firebrowse', 'matlab'); end
if ~isfolder(OutDirectory), mkdir(OutDirectory); end
[GeneKey, GeneNames, FurtherTexts, Header, Comments] = ...
    DataBionicIO.ReadNAMES('13ColumnNCBIs_Firebrowse_N19637.names', InDirectory, false);

% Keep the primary names label from the input file.
FullHeader = [{'Key'; 'Column_Name'}; cellstr(string(Header(:)))];
DataBionicIO.WriteNAMES('Firebrowse_copy', GeneNames, GeneKey, FurtherTexts, ...
    FullHeader, OutDirectory, Comments, false, false);
Key2 = ...
    DataBionicIO.ReadNAMES('Firebrowse_copy', OutDirectory, false);
assert(TheSameKey(GeneKey, Key2));

% Use the case-file order. Class values identify diagnosis descriptions.
[ClassKey, Cls] = DataBionicIO.ReadCLS('14Genexpression_Firebrowse_Cls_N10446.cls', InDirectory, false);
[CaseKey, CaseNames] = DataBionicIO.ReadNAMES('16Genexpression_Cases_N10446.names', InDirectory, false);
[DiagnosisKey, DiagnosisNames] = DataBionicIO.ReadNAMES('15Genexpression_Cls2Diagnosis_N33.names', InDirectory, false);

if ~TheSameKey(ClassKey, CaseKey)
    [~, ClassRows] = ismember(CaseKey, ClassKey);
    Cls = Cls(ClassRows);
    ClassKey = ClassKey(ClassRows);
    assert(TheSameKey(ClassKey, CaseKey));
end
Labels = unique(Cls);
if ~TheSameKey(Labels, DiagnosisKey)
    [~, DiagnosisRows] = ismember(Labels, DiagnosisKey);
    DiagnosisNames = DiagnosisNames(DiagnosisRows);
    DiagnosisKey = DiagnosisKey(DiagnosisRows);
    assert(TheSameKey(Labels, DiagnosisKey));
end
Counts = arrayfun(@(k) sum(Cls == k), Labels);
Summary = table(Labels, DiagnosisNames, Counts, ...
    'VariableNames', {'Class', 'Diagnosis', 'Cases'});
end
