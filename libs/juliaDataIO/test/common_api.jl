# INPUT
# The built DataBionicIO package.
# OUTPUT
# Assertions for common positional calls, fixed fields, and Chicago DTS metadata.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
using DataBionicIO, Test

@testset "Common API" begin
    mktempdir() do directory
        key = Int64[11, 22]
        WriteLRN("matrix", [7.0 1.5; 8.0 2.5], ["Unused", "Value"], key,
                 [0, 1], directory, "LRN", nothing, nothing, false, false, false)
        WriteCLS("classes", [2, 3], directory, key, "CLS", nothing, false, false)
        WriteNAMES("names", ["A", "B"], key, reshape(["x", "y"], 2, 1),
                   ["Group"], directory, "NAMES", false, false)
        times = ["2026-01-15 12:00:00", "2026-07-15 12:00:00",
                 "2026-11-01 01:30:00", "2026-11-01 01:30:00"]
        dst = ["CST", "CDT", "CDT", "CST"]
        WriteDates("times", (Time=times, Value=1:4, DST=dst), Int64[1,2,3,4],
                   directory, "DTS", "America/Chicago", 2, false, false)
        value = ReadLRN("matrix", directory, false)
        @test keys(value) == (:Key, :Data, :Header, :DataDefined, :Comments)
        @test value.Data == [7 1.5; 8 2.5]
        @test value.DataDefined == [9, 0, 1]
        @test keys(ReadCLS("classes", directory, false)) == (:Key, :Cls, :UniqueClasses, :Comments)
        @test keys(ReadNAMES("names", directory, false)) == (:Key, :Names, :FurtherTexts, :Header, :Comments)
        value = ReadDates("times", directory, false)
        @test keys(value) == (:Key, :Time, :Data, :Header, :Comments, :Timezone, :DST)
        @test value.Time == times
        @test value.Timezone == "America/Chicago"
        @test value.DST == dst
        WriteNAMES("empty", ["A", "B"]; Key=key, OutDirectory=directory, Verbose=false)
        value = ReadNAMES("empty"; InDirectory=directory, Verbose=false)
        @test size(value.FurtherTexts) == (2, 0)
        @test isempty(value.Header) && value.Comments == ""
        WriteDates("only-time", times[1:1]; Key=[1], OutDirectory=directory, Verbose=false)
        value = ReadDates("only-time"; InDirectory=directory, Verbose=false)
        @test size(value.Data) == (1, 0)
        @test isempty(value.Header) && value.Comments == ""
    end
end
