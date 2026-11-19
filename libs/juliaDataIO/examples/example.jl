# INPUT
# The built DataBionicIO package in the active Julia environment.
# OUTPUT
# Four example files in a temporary directory and assertions after reading them.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

using DataBionicIO
using Dates

mktempdir() do directory
    keys = Int64[-2^53, 2^31, 2^53]
    data = [1.25 10.0; NaN -2.5; 3.75 30.0]
    header = ["X", "Y"]
    WriteLRN("example.lrn", data; Key=keys, Header=header, OutDirectory=directory)
    @assert isequal(ReadLRN("example.lrn"; InDirectory=directory).Data, data)

    WriteCLS("example.cls", [2, missing, 1]; Key=keys, OutDirectory=directory)
    @assert isnan(ReadCLS("example.cls"; InDirectory=directory).Cls[2])

    WriteNAMES("example.names", ["Berlin", missing, "München"];
        Key=keys, Header=["Names", "Group"], FurtherTexts=["A"; "B"; "A";;], OutDirectory=directory)
    @assert ReadNAMES("example.names"; InDirectory=directory).Names[3] == "München"

    times = [DateTime(2024, 1, 2, 3, 4, 5, 125), DateTime(2024, 2, 3), DateTime(2024, 3, 4)]
    WriteDates("example.dts", (Time=times, X=data[:,1], Y=data[:,2]);
        Key=keys, OutDirectory=directory, tz="UTC", Format=3)
    result = ReadDates("example.dts"; InDirectory=directory)
    @assert result.Time[1] == "2024-01-02 03:04:05.125"
    @assert isequal(result.Data, data)
    println("All four examples passed.")
end
