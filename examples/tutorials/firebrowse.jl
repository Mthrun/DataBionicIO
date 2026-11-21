# INPUT
# Input path and optional output directory.
# OUTPUT
# A NAMES copy, key comparisons, and the diagnosis-count table Summary.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
using DataBionicIO
InDirectory = length(ARGS) >= 1 ? ARGS[1] : "examples/tutorials/data"
OutDirectory = length(ARGS) >= 2 ? ARGS[2] : "build/tutorials/firebrowse/julia"
mkpath(OutDirectory)
Result = ReadNAMES("13ColumnNCBIs_Firebrowse_N19637.names";
                  InDirectory=InDirectory, Verbose=false)
GeneKey = Result.Key
GeneNames = Result.Names
FurtherTexts = Result.FurtherTexts
Header = Result.Header
Comments = Result.Comments

# Keep the primary names label from the input file.
FullHeader = ["Key"; "Column_Name"; Header]
WriteNAMES("Firebrowse_copy", GeneNames; Key=GeneKey,
           FurtherTexts=FurtherTexts, Header=FullHeader,
           OutDirectory=OutDirectory, Comments=Comments,
           Overwrite=false, Verbose=false)
Result = ReadNAMES("Firebrowse_copy"; InDirectory=OutDirectory, Verbose=false)
Key2 = Result.Key
@assert TheSameKey(GeneKey, Key2)

# Use the case-file order. Class values identify diagnosis descriptions.
Result = ReadCLS("14Genexpression_Firebrowse_Cls_N10446.cls";
                  InDirectory=InDirectory, Verbose=false)
ClassKey = Result.Key
Cls = Result.Cls
Result = ReadNAMES("16Genexpression_Cases_N10446.names";
                  InDirectory=InDirectory, Verbose=false)
CaseKey = Result.Key
CaseNames = Result.Names
Result = ReadNAMES("15Genexpression_Cls2Diagnosis_N33.names";
                      InDirectory=InDirectory, Verbose=false)
DiagnosisKey = Result.Key
DiagnosisNames = Result.Names

if !TheSameKey(ClassKey, CaseKey)
    ClassRow = Dict(key => row for (row, key) in enumerate(ClassKey))
    ClassRows = [ClassRow[key] for key in CaseKey]
    Cls = Cls[ClassRows]
    ClassKey = ClassKey[ClassRows]
    @assert TheSameKey(ClassKey, CaseKey)
end
Labels = sort(unique(Cls))
if !TheSameKey(Labels, DiagnosisKey)
    DiagnosisRow = Dict(key => row for (row, key) in enumerate(DiagnosisKey))
    DiagnosisRows = [DiagnosisRow[label] for label in Labels]
    DiagnosisNames = DiagnosisNames[DiagnosisRows]
    DiagnosisKey = DiagnosisKey[DiagnosisRows]
    @assert TheSameKey(Labels, DiagnosisKey)
end
Counts = [count(==(label), Cls) for label in Labels]
Summary = [(Int(label), name, count)
           for (label, name, count) in zip(Labels, DiagnosisNames, Counts)]
