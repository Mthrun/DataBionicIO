# INPUT
# The built DataBionicIO package and the fixed samples copied by CMake.
# OUTPUT
# Tests of all four formats, data ownership, errors, warnings, and key boundaries.
# Temporary files are removed when each test group finishes.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

using Test
using Dates
using Logging
using DataBionicIO

@testset "DataBionicIO" begin
    @testset "TheSameKey" begin
        cases = [
            ([], [], true), (nothing, [], true), ([], [1], false),
            ([1, 2, 3], [1.0, 2.0, 3.0], true),
            ([1, 2, 3], [1, 3, 2], false), ([1, 2], [1, 2, 3], false),
            ([1, 1], [1, 1], true), ([1.5, -0.0], [1.5, 0.0], true),
            ([1], [nextfloat(1.0)], false),
            ([-2^53, 2^53], [-2^53, 2^53], true),
            ([1, missing], [1, missing], false), ([NaN], [NaN], false),
            ([Inf, -Inf], [Inf, -Inf], true), ([Inf], [-Inf], false),
            ([true, false], [1, 0], true),
            (["1"], [1], false), ("12", "12", false), (1, 1, false),
            ([1 2; 3 4], [1 2; 3 4], false),
            ([2^53 + 1], [2^53], false),
            ([big(10)^400], [big(10)^400], false),
        ]
        for (a, b, expected) in cases
            @test TheSameKey(a, b) === expected
            @test the_same_key(a, b) === expected
        end
        key = [3, 1, 2]
        before = copy(key)
        @test TheSameKey(key, key) === true
        @test key == before
    end
    mktempdir() do directory
        key = Int64[-2^53, 2^31, 2^53]
        values = [1.25 10.0; NaN -2.5; 3.75 30.0]
        comment = "language exchange\nUnicode: München"

        @testset "LRN data and ownership" begin
            path = joinpath(directory, "matrix.lrn")
            @test write_lrn(path, values; keys=key, header=["X", "Y"], comment) === nothing
            result = read_lrn(path)
            @test isequal(result.data, values)
            @test result.keys == key
            @test result.header == ["X", "Y"]
            @test result.types == [9, 1, 1]
            @test result.comment == comment
            GC.gc()
            @test isequal(result.data, values)
            @test result.header[2] == "Y"
            result.data[1, 1] = 999
            @test read_lrn(path).data[1, 1] == 1.25
            before = read(path)
            @test_throws ErrorException write_lrn(path, values; keys=key, overwrite=false)
            @test read(path) == before
            # Views and transposes must retain observation/feature orientation.
            write_lrn(path, transpose([1.0 2 3; 10 20 30]); keys=key, header=["X", "Y"])
            @test read_lrn(path).data == [1 10; 2 20; 3 30]
            write_lrn(path, view(values, :, 1:1); keys=key, header=["X"], types=[1])
            @test isequal(read_lrn(path).data, values[:, 1:1])
            @test read_lrn(path).types == [9, 1]
            write_lrn(path, [missing 2.0]; keys=[1], header=["X", "Y"])
            @test isnan(read_lrn(path).data[1, 1])
        end

        @testset "CLS and native exception translation" begin
            path = joinpath(directory, "classes.cls")
            @test write_cls(path, [2, missing, 1]; keys=key, comment) === nothing
            result = read_cls(path)
            @test isequal(result.classes, [2, NaN, 1])
            @test result.keys == key
            @test result.comment == comment
            @test sort(filter(!isnan, result.unique_classes)) == [1, 2]
            @test_logs (:warn, r"WARNING") match_mode=:any write_cls(path, [1.5, 2, 3]; keys=key)
            @test isnan(read_cls(path).classes[1])
            write_cls(path, [missing]; keys=[1], missing_class=-1)
            @test read_cls(path).classes == [-1]
            for reader in (read_lrn, read_cls, read_names, read_dates)
                @test_throws ErrorException reader(joinpath(directory, "absent"))
            end
            @test read_cls(path).keys == [1]
        end

        @testset "NAMES strings and matrix dimensions" begin
            path = joinpath(directory, "labels.names")
            names = ["1.0.4", missing, "München"]
            texts = ["A1" "B1"; missing "B2"; "A3" missing]
            @test write_names(path, names; keys=key, further_texts=texts,
                header=["Names", "Extra1", "Extra2"], comment) === nothing
            result = read_names(path)
            GC.gc()
            @test isequal(result.names, names)
            @test isequal(result.further_texts, texts)
            @test result.keys == key
            @test result.file_header == ["Key", "Names", "Extra1", "Extra2"]
            @test result.header == ["Extra1", "Extra2"]
            @test result.comment == comment
            write_names(path, ["plain", "with spaces"]; keys=[1, 2], header=["Names"])
            @test size(read_names(path).further_texts) == (2, 0)
            @test read_names(path).names == ["plain", "with spaces"]
            @test_logs (:warn, r"^Replaced 1 forbidden text characters in 1 fields") write_names(path, ["bad\tcell"]; keys=[1])
            @test read_names(path).names == ["bad_cell"]
            @test_throws ArgumentError write_names(path, ["ok"]; further_texts=["a"; "b";;])
        end

        @testset "DATES resolution and metadata" begin
            path = joinpath(directory, "times.dts")
            times = ["2024-10-27 00:30:00.125", "2024-06-15 13:45:10.250", "2024-10-27 01:30:00.999"]
            @test write_dates(path, times, values; keys=key, header=["X", "Y"], comment, format=3) === nothing
            result = read_dates(path)
            @test isequal(result.data, values)
            @test result.keys == key
            @test result.times == times
            @test result.header == ["X", "Y"]
            @test result.timezone == "UTC"
            @test result.comment == comment
            write_dates(path, [Date(2024, 1, 2), missing], [1.0; 2.0;;]; keys=[1, 2], format=1)
            @test isequal(read_dates(path).times, ["2024-01-02", missing])
            write_dates(path, [DateTime(2024, 1, 2, 3, 4, 5, 123)], zeros(1, 0); keys=[1])
            @test read_dates(path).times == ["2024-01-02 03:04:05.123"]
            @test size(read_dates(path).data) == (1, 0)
            write_dates(path, ["2024-10-27 02:30:00 CEST", "2024-10-27 02:30:00 CET"],
                zeros(2, 0); keys=[1, 2], timezone="Europe/Berlin")
            local_result = read_dates(path)
            @test local_result.timezone == "Europe/Berlin"
            @test local_result.dst == ["CEST", "CET"]
            @test local_result.times == fill("2024-10-27 02:30:00", 2)
            @test_throws ArgumentError write_dates(path, times, zeros(2, 1))
            @test_throws ArgumentError write_dates(path, times, values; format=0)
            @test_throws ArgumentError write_dates(path, times, values; timezone="UTC\nTimezone: other")
        end

        @testset "Key validation before output" begin
            writers = (
                path -> write_lrn(path, ones(3, 1); keys=key, header=["X"]),
                path -> write_cls(path, [1, 2, 3]; keys=key),
                path -> write_names(path, ["a", "b", "c"]; keys=key, header=["Names"]),
                path -> write_dates(path, fill("2024-01-01", 3), ones(3, 1); keys=key),
            )
            for (writer, reader, extension) in zip(writers,
                    (read_lrn, read_cls, read_names, read_dates), ("lrn", "cls", "names", "dts"))
                path = joinpath(directory, "boundary." * extension)
                writer(path)
                @test reader(path).keys == key
            end
            invalid = ([1, 1, 2], [1, 2, MAX_EXACT_KEY + 1],
                [1, 2, -MAX_EXACT_KEY - 1], [1.0, 2, 3.5], [1, 2, missing],
                [1, 2, Inf], [1, 2, NaN], [true, false, true],
                UInt64[1, 2, typemax(UInt64)], BigInt[1, 2, big(2)^100], [1, 2])
            for bad in invalid
                for (extension, writer) in (
                        ("lrn", p -> write_lrn(p, values; keys=bad)),
                        ("cls", p -> write_cls(p, [1, 2, 3]; keys=bad)),
                        ("names", p -> write_names(p, ["a", "b", "c"]; keys=bad)),
                        ("dts", p -> write_dates(p, fill("2024-01-01", 3), values; keys=bad)))
                    path = joinpath(directory, "protected." * extension)
                    write(path, "keep these bytes")
                    @test_throws ArgumentError writer(path)
                    @test read(path, String) == "keep these bytes"
                end
            end
            @test_logs (:warn, r"Key was not supplied") write_lrn(joinpath(directory, "auto"),
                values; header=["X", "Y"])
            @test read_lrn(joinpath(directory, "auto.lrn")).keys == [1, 2, 3]
        end

        @testset "Legacy, malformed input, and warnings" begin
            path = joinpath(directory, "old.lrn")
            write(path, "% 2\n% 3\n% 1\t9\t1\n% Left\tID\tRight\n10\t2147483648\t30\n20\t9007199254740992\t40\n")
            result = read_lrn(path)
            @test result.keys == [2^31, 2^53]
            @test result.data == [10 30; 20 40]
            write(path, "#<?lrn version=\"2.0\"?>\n% 1\n% 2\n% 9\t1\n% Key\tValue\n9007199254740993\t5\n")
            result = @test_logs (:warn, r"WARNING") match_mode=:any read_lrn(path)
            @test ismissing(result.keys[1])
            @test result.data == reshape([5.0], 1, 1)
            write(path, "#<?lrn version=\"9.0\"?>\n% 0\n")
            @test_throws ErrorException read_lrn(path)
            @test_throws ArgumentError read_lrn("bad\0path")
            for (directory, _, files) in walkdir(joinpath(@__DIR__, "samples"))
                for name in files
                    reader = endswith(name, ".lrn") ? read_lrn : endswith(name, ".cls") ? read_cls : read_names
                    result = with_logger(NullLogger()) do
                        reader(joinpath(directory, name))
                    end
                    @test !isempty(result.keys)
                end
            end
        end
    end
end

include("common_api.jl")
include("text_encoding.jl")
