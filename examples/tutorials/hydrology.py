# INPUT
# Input path and optional output directory.
# OUTPUT
# A DTS copy and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import DataBionicIO as io

InDirectory = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("examples/tutorials/data")
OutDirectory = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("build/tutorials/hydrology/python")
OutDirectory.mkdir(parents=True, exist_ok=True)
Result = io.ReadDates("HydrologyDaily2013_2014.dts", InDirectory=InDirectory, Verbose=False)
Key = Result["Key"]
Time = Result["Time"]
Data = Result["Data"]
Header = Result["Header"]
Comments = Result["Comments"]
Timezone = Result["Timezone"]
Data = np.asarray(Data)

# Keep the calendar dates. The source does not identify an acquisition time zone.
Time = pd.DatetimeIndex(Time)
TSdata = pd.DataFrame(Data, columns=Header)
TSdata.insert(0, "Time", Time)
io.WriteDates("Hydrology_copy", TSdata, Key=Key, OutDirectory=OutDirectory,
              Comments=Comments, tz=Timezone, Format=1,
              Overwrite=False, Verbose=False)
Result = io.ReadDates("Hydrology_copy", InDirectory=OutDirectory, Verbose=False)
Key2 = Result["Key"]
assert io.TheSameKey(Key, Key2)
print("Hydrology example complete.")
