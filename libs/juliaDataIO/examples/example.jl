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
    write_lrn(joinpath(directory, "example.lrn"), data; keys, header)
    @assert isequal(read_lrn(joinpath(directory, "example.lrn")).data, data)

    write_cls(joinpath(directory, "example.cls"), [2, missing, 1]; keys)
    @assert isnan(read_cls(joinpath(directory, "example.cls")).classes[2])

    write_names(joinpath(directory, "example.names"), ["Berlin", missing, "München"];
        keys, header=["Names", "Group"], further_texts=["A"; "B"; "A";;])
    @assert read_names(joinpath(directory, "example.names")).names[3] == "München"

    times = [DateTime(2024, 1, 2, 3, 4, 5, 125), DateTime(2024, 2, 3), DateTime(2024, 3, 4)]
    write_dates(joinpath(directory, "example.dts"), times, data; keys, header, timezone="UTC", format=3)
    result = read_dates(joinpath(directory, "example.dts"))
    @assert result.times[1] == "2024-01-02 03:04:05.125"
    @assert isequal(result.data, data)
    println("All four examples passed.")
end
