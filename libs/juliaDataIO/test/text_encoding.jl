# OUTPUT
# Cross-language fixture and field-replacement regression results.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
using DataBionicIO, Test
source = isempty(ARGS) ? joinpath(@__DIR__, "encoding", "fixtures") : abspath(ARGS[1])
if !isdir(source)
    source = joinpath(@__DIR__, "..", "..", "..", "tests", "encoding", "fixtures")
end
directory = mktempdir()
for name in readdir(source)
    cp(joinpath(source, name), joinpath(directory, name))
end
@testset "Encoding policy" begin
    for (reader, ext) in [(ReadLRN, "lrn"), (ReadCLS, "cls"), (ReadNAMES, "names"), (ReadDates, "dts")]
        for enc in ["utf-8-sig", "utf-16", "utf-32", "utf-16-be", "utf-32-be", "cp1252", "latin1"]
            setting = enc == "cp1252" ? "Windows-1252" : enc == "latin1" ? "ISO-8859-1" : nothing
            value = if enc == "utf-8-sig"
                @test_logs reader(enc * "." * ext; InDirectory=directory, Verbose=false, Encoding=setting)
            else
                @test_logs (:warn, r"^Converted input from .* to UTF-8\.$") reader(enc * "." * ext; InDirectory=directory, Verbose=false, Encoding=setting)
            end
            @test value.Key == [17]
            @test occursin("Grüße", value.Comments)
        end
        @test_throws Exception reader("invalid." * ext; InDirectory=directory, Verbose=false)
        @test_throws Exception reader("sample." * ext; InDirectory=directory, Encodin="UTF-8")
    end
    names = ["Sample\tA", "A\r\nB", "N\0Z", " café ", "e\u0301", "é", "🙂\ufeffX"]
    texts = fill("X\nY", length(names), 1)
    saved = copy(texts)
    for replacement in ["_", "[sep]", "🙂"]
        @test_logs (:warn, "Replaced 11 forbidden text characters in 10 fields with \"$replacement\".") WriteNAMES("julia.names", names;
            Key=collect(1:length(names)), FurtherTexts=texts, Header=["Names", "Description"],
            OutDirectory=directory, Verbose=false, TextReplacement=replacement)
        value = ReadNAMES("julia.names"; InDirectory=directory, Verbose=false)
        @test value.Names == [replace(s, '\t'=>replacement, '\r'=>replacement, '\n'=>replacement, '\0'=>replacement) for s in names]
        @test texts == saved
    end
    path = joinpath(directory, "julia.names")
    original = read(path)
    for replacement in ["", "\t", "\0", "\r", "\n"]
        @test_throws Exception WriteNAMES("julia.names", ["A\tB"]; Key=[1], OutDirectory=directory, TextReplacement=replacement)
        @test read(path) == original
    end
end
