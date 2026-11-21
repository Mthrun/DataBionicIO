# INPUT
# Input path and optional output directory.
# OUTPUT
# Three Hepta files, class counts, and key comparisons.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
from pathlib import Path
from collections import Counter
import sys
import DataBionicIO as io

InDirectory = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("examples/tutorials/data")
OutDirectory = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("build/tutorials/hepta/python")
OutDirectory.mkdir(parents=True, exist_ok=True)
Result = io.ReadLRN("hepta", InDirectory=InDirectory, Verbose=False)
Key = Result["Key"]
Data = Result["Data"]
Header = Result["Header"]
DataDefined = Result["DataDefined"]
Comments = Result["Comments"]
Result = io.ReadCLS("hepta", InDirectory=InDirectory, Verbose=False)
ClassKey = Result["Key"]
Cls = Result["Cls"]
ClassComments = Result["Comments"]
Result = io.ReadNAMES("hepta", InDirectory=InDirectory, Verbose=False)
NameKey = Result["Key"]
Names = Result["Names"]
NameComments = Result["Comments"]

# Align the companion records with the measurement keys.
if not io.TheSameKey(Key, ClassKey):
    ClassRow = {key: row for row, key in enumerate(ClassKey)}
    ClassRows = [ClassRow[key] for key in Key]
    Cls = [Cls[row] for row in ClassRows]
    ClassKey = [ClassKey[row] for row in ClassRows]
    assert io.TheSameKey(Key, ClassKey)
if not io.TheSameKey(Key, NameKey):
    NameRow = {key: row for row, key in enumerate(NameKey)}
    NameRows = [NameRow[key] for key in Key]
    Names = [Names[row] for row in NameRows]
    NameKey = [NameKey[row] for row in NameRows]
    assert io.TheSameKey(Key, NameKey)
Counts = Counter(Cls)
print(sorted(Counts.items()))

io.WriteLRN("hepta_copy", Data, Header=Header, Key=Key,
            DataDefined=DataDefined, OutDirectory=OutDirectory,
            Comments=Comments, Overwrite=False, Verbose=False)
io.WriteCLS("hepta_copy", Cls, OutDirectory=OutDirectory, Key=Key,
            Comment=ClassComments, Overwrite=False, Verbose=False)
io.WriteNAMES("hepta_copy", Names, Key=Key, Header=["Key", "Names"],
              OutDirectory=OutDirectory, Comments=NameComments,
              Overwrite=False, Verbose=False)
Result = io.ReadLRN("hepta_copy", InDirectory=OutDirectory, Verbose=False)
Key2 = Result["Key"]
Result = io.ReadCLS("hepta_copy", InDirectory=OutDirectory, Verbose=False)
ClassKey2 = Result["Key"]
Result = io.ReadNAMES("hepta_copy", InDirectory=OutDirectory, Verbose=False)
NameKey2 = Result["Key"]
assert io.TheSameKey(Key, Key2)
assert io.TheSameKey(Key, ClassKey2)
assert io.TheSameKey(Key, NameKey2)
print("Hepta example complete.")
