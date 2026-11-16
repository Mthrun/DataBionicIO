# INPUT
# ARGS: Julia request-data file and TOML result file. Activate the built package.
# The request-data file assigns requests, an array of dictionaries.
# OUTPUT
# Native public-API observations and diagnostics; requested files are written.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

using DataBionicIO, TOML, Logging
include(abspath(ARGS[1]))
num(x) = isnothing(x) ? NaN : parse(Float64,string(x))
txt(x) = isnothing(x) ? missing : x
text(x) = ismissing(x) ? "NA" : string(x)
hex(x) = isnan(x) ? "NaN" : string(reinterpret(UInt64,Float64(x)),base=16,pad=16)
rows(a, f) = [[f(a[i,j]) for j in axes(a,2)] for i in axes(a,1)]
matrix_rows(a,f) = [f(a[i][j]) for i in eachindex(a), j in eachindex(a[1])]
from_hex(x) = x == "NaN" ? NaN : reinterpret(Float64,parse(UInt64,x;base=16))
input_data(q) = haskey(q,"data_bits") ? matrix_rows(q["data_bits"],from_hex) : matrix_rows(q["data"],num)

function observe(q)
    if q["operation"] == "helper"
        a,b = num.(q["a"]),num.(q["other"]); olda,oldb = copy(a),copy(b)
        value = the_same_key(a,b)
        return Dict("value"=>value,"immutable"=>isequal(a,olda)&&isequal(b,oldb),"native_type"=>string(typeof(value)))
    end
    fmt,path = q["format"],q["path"]; verbose = get(q,"verbose",false)
    if q["operation"] == "write"
        common = (keys=num.(q["keys"]),verbose=verbose,overwrite=get(q,"overwrite",true),comment=get(q,"comment",""))
        opts = Dict(Symbol(Dict("SignificantDigits"=>"significant_digits","DecimalDigits"=>"decimal_digits",
                    "Scientific"=>"scientific","NaNReplacement"=>"missing_class")[k])=>v for (k,v) in get(q,"options",Dict()))
        if fmt == "lrn"
            write_lrn(path,input_data(q);header=q["header"],common...,opts...)
        elseif fmt == "cls"
            write_cls(path,num.(q["classes"]);common...,opts...)
        elseif fmt == "names"
            write_names(path,txt.(q["names"]);further_texts=matrix_rows(q["further_texts"],txt),header=q["header"],common...)
        elseif fmt == "dts"
            write_dates(path,txt.(q["times"]),input_data(q);header=q["header"],
                        timezone=get(q,"timezone","UTC"),format=get(q,"time_format",3),common...)
        else
            error("Unknown format")
        end
        return Dict{String,Any}()
    end
    a = Dict("lrn"=>read_lrn,"cls"=>read_cls,"names"=>read_names,"dts"=>read_dates)[fmt](path;verbose)
    out = Dict{String,Any}("keys"=>text.(a.keys),"comment"=>a.comment)
    if fmt in ("lrn","dts")
        out["data"] = rows(a.data,hex); out["shape"] = collect(size(a.data)); out["header"] = a.header
    end
    fmt == "lrn" && (out["types"] = a.types)
    fmt == "cls" && (out["classes"] = hex.(a.classes))
    if fmt == "names"
        out["names"] = text.(a.names); out["further_texts"] = rows(a.further_texts,text)
        out["header"] = a.header; out["file_header"] = a.file_header
    elseif fmt == "dts"
        out["times"] = text.(a.times); out["timezone"] = a.timezone; out["dst"] = text.(a.dst)
        out["native_time_type"] = string(eltype(a.times)); out["file_header"] = a.file_header
    end
    out
end

results = []
for q in requests
    diagnostics = IOBuffer()
    before_directory = pwd()
    # Native progress messages are retained in the process log; warnings use Logging.
    result = with_logger(SimpleLogger(diagnostics,Logging.Warn)) do
        try
            merge(Dict{String,Any}("id"=>q["id"],"ok"=>true),observe(q))
        catch e
            Dict{String,Any}("id"=>q["id"],"ok"=>false,"error"=>sprint(showerror,e),"error_type"=>string(typeof(e)))
        end
    end
    result["diagnostics"] = [String(take!(diagnostics))]
    result["working_directory_unchanged"] = pwd() == before_directory
    push!(results,result)
end
open(ARGS[2],"w") do stream
    TOML.print(stream,Dict("results"=>results))
end
