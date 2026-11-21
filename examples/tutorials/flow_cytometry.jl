# INPUT
# Input path and optional output directory.
# OUTPUT
# An LRN file with 1000 selected rows and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
using DataBionicIO
InFile = abspath(ARGS[1])
OutDirectory = length(ARGS) >= 2 ? ARGS[2] : "build/tutorials/flow-cytometry/julia"
mkpath(OutDirectory)
Result = ReadLRN(basename(InFile); InDirectory=dirname(InFile), Verbose=false)
Key = Result.Key
Data = Result.Data
Header = Result.Header
DataDefined = Result.DataDefined
Comments = Result.Comments

# Select the same rows for measurements and keys.
Rows = 1:1000
WriteLRN("Dresden_subset", Data[Rows, :]; Header=Header, Key=Key[Rows],
         DataDefined=DataDefined, OutDirectory=OutDirectory,
         Comments=Comments, Overwrite=false, Verbose=false)
Result = ReadLRN("Dresden_subset"; InDirectory=OutDirectory, Verbose=false)
Key2 = Result.Key
@assert TheSameKey(Key[Rows], Key2)
println("Flow cytometry example complete.")
