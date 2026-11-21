# INPUT
# Input path and optional output directory.
# OUTPUT
# Three Hepta files, class counts, and key comparisons.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
using DataBionicIO
InDirectory = length(ARGS) >= 1 ? ARGS[1] : "examples/tutorials/data"
OutDirectory = length(ARGS) >= 2 ? ARGS[2] : "build/tutorials/hepta/julia"
mkpath(OutDirectory)
Result = ReadLRN("hepta"; InDirectory=InDirectory, Verbose=false)
Key = Result.Key
Data = Result.Data
Header = Result.Header
DataDefined = Result.DataDefined
Comments = Result.Comments
Result = ReadCLS("hepta"; InDirectory=InDirectory, Verbose=false)
ClassKey = Result.Key
Cls = Result.Cls
ClassComments = Result.Comments
Result = ReadNAMES("hepta"; InDirectory=InDirectory, Verbose=false)
NameKey = Result.Key
Names = Result.Names
NameComments = Result.Comments

# Align the companion records with the measurement keys.
if !TheSameKey(Key, ClassKey)
    ClassRow = Dict(key => row for (row, key) in enumerate(ClassKey))
    ClassRows = [ClassRow[key] for key in Key]
    Cls = Cls[ClassRows]
    ClassKey = ClassKey[ClassRows]
    @assert TheSameKey(Key, ClassKey)
end
if !TheSameKey(Key, NameKey)
    NameRow = Dict(key => row for (row, key) in enumerate(NameKey))
    NameRows = [NameRow[key] for key in Key]
    Names = Names[NameRows]
    NameKey = NameKey[NameRows]
    @assert TheSameKey(Key, NameKey)
end
Counts = [count(==(k), Cls) for k in 1:7]
println(Counts)

WriteLRN("hepta_copy", Data; Header=Header, Key=Key,
         DataDefined=DataDefined, OutDirectory=OutDirectory,
         Comments=Comments, Overwrite=false, Verbose=false)
WriteCLS("hepta_copy", Cls; OutDirectory=OutDirectory, Key=Key,
         Comment=ClassComments, Overwrite=false, Verbose=false)
WriteNAMES("hepta_copy", Names; Key=Key, Header=["Key", "Names"],
           OutDirectory=OutDirectory, Comments=NameComments,
           Overwrite=false, Verbose=false)
Result = ReadLRN("hepta_copy"; InDirectory=OutDirectory, Verbose=false)
Key2 = Result.Key
Result = ReadCLS("hepta_copy"; InDirectory=OutDirectory, Verbose=false)
ClassKey2 = Result.Key
Result = ReadNAMES("hepta_copy"; InDirectory=OutDirectory, Verbose=false)
NameKey2 = Result.Key
@assert TheSameKey(Key, Key2)
@assert TheSameKey(Key, ClassKey2)
@assert TheSameKey(Key, NameKey2)
println("Hepta example complete.")
