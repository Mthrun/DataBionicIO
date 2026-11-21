# INPUT
# No external input. The program uses the active DataBionicIO project.
# OUTPUT
# An LRN file in a temporary directory and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
using DataBionicIO
Data = [1.5 2.0; 3.5 NaN]
Key = [101, 205]
mktempdir() do OutDirectory
    WriteLRN("example", Data; Header=["Length", "Mass"], Key=Key,
             OutDirectory=OutDirectory, Overwrite=false, Verbose=false)
    Result = ReadLRN("example"; InDirectory=OutDirectory, Verbose=false)
    Key2 = Result.Key
    @assert TheSameKey(Key, Key2)
end
println("Quick start complete.")
