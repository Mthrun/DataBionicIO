# INPUT
# Path to 01SampleDresdenD10n440K.lrn and optional output directory.
# OUTPUT
# An LRN file with the first 1000 rows and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
from pathlib import Path
import sys
import numpy as np
import DataBionicIO as io

InFile = Path(sys.argv[1]).resolve()
OutDirectory = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("build/tutorials/flow-cytometry/python")
OutDirectory.mkdir(parents=True, exist_ok=True)
Result = io.ReadLRN(InFile.name, InDirectory=InFile.parent, Verbose=False)
Key = Result["Key"]
Data = Result["Data"]
Header = Result["Header"]
DataDefined = Result["DataDefined"]
Comments = Result["Comments"]
Data = np.asarray(Data)
Key = np.asarray(Key)

# Select the same rows for measurements and keys.
Rows = slice(0, 1000)
io.WriteLRN("Dresden_subset", Data[Rows], Header=Header, Key=Key[Rows],
            DataDefined=DataDefined, OutDirectory=OutDirectory,
            Comments=Comments, Overwrite=False, Verbose=False)
Result = io.ReadLRN("Dresden_subset", InDirectory=OutDirectory, Verbose=False)
Key2 = Result["Key"]
assert io.TheSameKey(Key[Rows], Key2)
print("Flow cytometry example complete.")
