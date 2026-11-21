# INPUT
# Optional command-line input directory and output directory.
# Defaults use examples/tutorials/data and build/tutorials/hydrology/julia.
# OUTPUT
# A DTS copy and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
using DataBionicIO
InDirectory = length(ARGS) >= 1 ? ARGS[1] : "examples/tutorials/data"
OutDirectory = length(ARGS) >= 2 ? ARGS[2] : "build/tutorials/hydrology/julia"
mkpath(OutDirectory)

Result = ReadDates("HydrologyDaily2013_2014.dts";
              InDirectory=InDirectory, Verbose=false)
Key = Result.Key
Time = Result.Time
Data = Result.Data
Header = Result.Header
Comments = Result.Comments
Timezone = Result.Timezone

# Keep the calendar dates. The data does not identify an acquisition time zone.

# The common writer accepts a NamedTuple of columns.
Columns = (Time, eachcol(Data)...)
Labels = Tuple(Symbol.(["Time"; Header]))
TSdata = NamedTuple{Labels}(Columns)
WriteDates("Hydrology_copy", TSdata; Key=Key, OutDirectory=OutDirectory,
           Comments=Comments, tz=Timezone, Format=1,
           Overwrite=false, Verbose=false)
Result = ReadDates("Hydrology_copy"; InDirectory=OutDirectory, Verbose=false)
Key2 = Result.Key
@assert TheSameKey(Key, Key2)
println("Hydrology example complete.")
