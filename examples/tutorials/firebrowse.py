# INPUT
# Optional command-line input directory and output directory.
# Defaults use examples/tutorials/data and build/tutorials/firebrowse/python.
# OUTPUT
# A NAMES copy, key comparisons, and the diagnosis-count table Summary.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
from pathlib import Path
from collections import Counter
import sys
import DataBionicIO as io

InDirectory = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("examples/tutorials/data")
OutDirectory = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("build/tutorials/firebrowse/python")
OutDirectory.mkdir(parents=True, exist_ok=True)

# These keys identify genes, and the names identify matrix columns.
Result = io.ReadNAMES("13ColumnNCBIs_Firebrowse_N19637.names",
                     InDirectory=InDirectory, Verbose=False)
GeneKey = Result["Key"]
GeneNames = Result["Names"]
FurtherTexts = Result["FurtherTexts"]
Header = Result["Header"]
Comments = Result["Comments"]

# The reader does not return the primary names label in Header.
FullHeader = ["Key", "Column_Name"] + list(Header)
io.WriteNAMES("Firebrowse_copy", GeneNames, Key=GeneKey,
              FurtherTexts=FurtherTexts, Header=FullHeader,
              OutDirectory=OutDirectory, Comments=Comments,
              Overwrite=False, Verbose=False)
Result = io.ReadNAMES("Firebrowse_copy", InDirectory=OutDirectory, Verbose=False)
Key2 = Result["Key"]
assert io.TheSameKey(GeneKey, Key2)

# These keys identify cases. They are different from the gene keys.
Result = io.ReadCLS("14Genexpression_Firebrowse_Cls_N10446.cls",
                     InDirectory=InDirectory, Verbose=False)
ClassKey = Result["Key"]
Cls = Result["Cls"]
Result = io.ReadNAMES("16Genexpression_Cases_N10446.names",
                     InDirectory=InDirectory, Verbose=False)
CaseKey = Result["Key"]
CaseNames = Result["Names"]
Result = io.ReadNAMES("15Genexpression_Cls2Diagnosis_N33.names",
                         InDirectory=InDirectory, Verbose=False)
DiagnosisKey = Result["Key"]
DiagnosisNames = Result["Names"]

if not io.TheSameKey(ClassKey, CaseKey):
    ClassRow = {key: row for row, key in enumerate(ClassKey)}
    ClassRows = [ClassRow[key] for key in CaseKey]
    Cls = [Cls[row] for row in ClassRows]
    ClassKey = [ClassKey[row] for row in ClassRows]
    assert io.TheSameKey(ClassKey, CaseKey)
Counts = Counter(Cls)
Labels = sorted(Counts)
if not io.TheSameKey(Labels, DiagnosisKey):
    DiagnosisRow = {key: row for row, key in enumerate(DiagnosisKey)}
    DiagnosisRows = [DiagnosisRow[label] for label in Labels]
    DiagnosisNames = [DiagnosisNames[row] for row in DiagnosisRows]
    DiagnosisKey = [DiagnosisKey[row] for row in DiagnosisRows]
    assert io.TheSameKey(Labels, DiagnosisKey)
Summary = [(label, name, Counts[label])
           for label, name in zip(Labels, DiagnosisNames)]
