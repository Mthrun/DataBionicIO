# INPUT
# No external input. The program uses the installed DataBionicIO package.
# OUTPUT
# An LRN file in a temporary directory and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
from tempfile import TemporaryDirectory
import numpy as np
import DataBionicIO as io

Data = np.array([[1.5, 2.0], [3.5, np.nan]])
Key = [101, 205]
with TemporaryDirectory(prefix="DataBionicIO-") as OutDirectory:
    io.WriteLRN("example", Data, Header=["Length", "Mass"], Key=Key,
                OutDirectory=OutDirectory, Overwrite=False, Verbose=False)
    Result = io.ReadLRN("example", InDirectory=OutDirectory, Verbose=False)
    Key2 = Result["Key"]
    assert io.TheSameKey(Key, Key2)
print("Quick start complete.")
