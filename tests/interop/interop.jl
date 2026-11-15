# INPUT
# ARGS: generate or verify, exchange directory, and optional writer names.
# OUTPUT
# Four Julia files, or assertions for all four formats from each selected writer.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

using DataBionicIO
using Test

length(ARGS) >= 2 && ARGS[1] in ("generate", "verify") ||
    error("Supply generate or verify, an exchange directory, and optional writer names")
mode, directory = ARGS[1:2]
isdir(directory) || error("Exchange directory does not exist")
keys = Int64[-2^53, 2^31, 2^53]
values = [1.25 10.0; NaN -2.5; 3.75 30.0]
classes = [2.0, NaN, 1.0]
names = ["1.0.4", missing, "München"]
texts = ["A1" "B1"; missing "B2"; "A3" missing]
times = ["2024-10-27 00:30:00.125", "2024-06-15 13:45:10.250", "2024-10-27 01:30:00.999"]
comment = "language exchange"

if mode == "generate"
    write_lrn(joinpath(directory, "julia.lrn"), values; keys, header=["X", "Y"], comment)
    write_cls(joinpath(directory, "julia.cls"), classes; keys, comment)
    write_names(joinpath(directory, "julia.names"), names; keys, further_texts=texts,
        header=["Names", "Extra1", "Extra2"], comment)
    write_dates(joinpath(directory, "julia.dts"), times, values;
        keys, header=["X", "Y"], timezone="UTC", format=3, comment)
else
    writers = length(ARGS) > 2 ? ARGS[3:end] : ["r", "python", "julia"]
    @testset "File exchange -> Julia" begin
        for writer in writers
            @testset "$writer -> Julia" begin
                for (extension, reader) in (("lrn", read_lrn), ("cls", read_cls),
                        ("names", read_names), ("dts", read_dates))
                    actual = reader(joinpath(directory, writer * "." * extension))
                    @test actual.keys == keys
                    @test actual.comment == comment
                    if extension in ("lrn", "dts")
                        @test isequal(actual.data, values)
                        @test actual.header == ["X", "Y"]
                    elseif extension == "cls"
                        @test isequal(actual.classes, classes)
                    else
                        @test isequal(actual.names, names)
                        @test isequal(actual.further_texts, texts)
                        @test actual.header == ["Extra1", "Extra2"]
                        @test actual.file_header == ["Key", "Names", "Extra1", "Extra2"]
                    end
                    if extension == "dts"
                        @test actual.times == times
                        @test actual.timezone == "UTC"
                    end
                end
            end
        end
    end
end
