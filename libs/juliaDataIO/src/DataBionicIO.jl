# INPUT
# Paths, data arrays, and format options supplied to the public functions.
# OUTPUT
# Named read results or files written through the shared C++ core.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

module DataBionicIO

using CxxWrap
using Dates
using Logging

export TheSameKey, the_same_key
export read_lrn, write_lrn, read_cls, write_cls
export read_names, write_names, read_dates, write_dates, MAX_EXACT_KEY

module Native
using CxxWrap
using Libdl
@wrapmodule(() -> joinpath(@__DIR__, "..", "lib", "libdatabionicio_julia." * Libdl.dlext))

# INPUT
# Julia module initialization after loading or restoring a precompiled package.
# OUTPUT
# Initializes CxxWrap function pointers for this process.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function __init__()
    @initcxx
end
end

const MAX_EXACT_KEY = Int64(2)^53
const MissingText = Union{Missing,String}

# INPUT
# values: a numeric vector or nothing for an empty vector.
# OUTPUT
# Exact Float64 values, or nothing for missing or unsupported input.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _comparison_values(values)
    values === nothing && return Float64[]
    values isa AbstractVector || return nothing
    result = Float64[]
    for value in values
        value isa Real || return nothing
        number = try
            Float64(value)
        catch error
            error isa InterruptException && rethrow()
            return nothing
        end
        if value isa Integer
            isfinite(number) && BigInt(number) == BigInt(value) || return nothing
        else
            value == number || return nothing
        end
        push!(result, number)
    end
    return result
end

# INPUT
# keyA, keyB: numeric vectors in their original order.
# OUTPUT
# One Bool from the common core. Missing or unsupported inputs give false.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
"""
    the_same_key(keyA, keyB)
    TheSameKey(keyA, keyB)

Compare length and values in order, without a tolerance. Empty vectors compare
equal; missing values give false. No sorting, uniqueness check, or input changes.
Values must convert to Float64 without loss. Unsupported inputs give false.
"""
function the_same_key(keyA, keyB)
    a = _comparison_values(keyA)
    b = _comparison_values(keyB)
    (a === nothing || b === nothing) && return false
    return Native._the_same_key(StdVector(a), StdVector(b))
end

const TheSameKey = the_same_key


# INPUT
# value: a string at the Julia/C++ boundary.
# OUTPUT
# An owned String without embedded NUL bytes, or ArgumentError.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _string(value::AbstractString)
    occursin('\0', value) && throw(ArgumentError("Strings cannot contain NUL bytes"))
    return String(value)
end

# INPUT
# values: a vector of strings.
# OUTPUT
# An owned C++ string vector whose elements remain alive for the native call.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
_strings(values) = StdVector{StdString}(StdString[StdString(_string(x)) for x in values])

# INPUT
# value: a real numeric cell or missing.
# OUTPUT
# Float64, with missing represented by NaN, or ArgumentError.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _number(value)
    ismissing(value) && return NaN
    value isa Real || throw(ArgumentError("Numeric data must contain real numbers or missing"))
    return Float64(value)
end

# INPUT
# value: a text cell or missing.
# OUTPUT
# File text, with missing represented by NA. Rejects table delimiters.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _text(value)
    ismissing(value) && return "NA"
    value isa AbstractString || throw(ArgumentError("Text must contain strings or missing"))
    text = _string(value)
    any(c -> c in ('\t', '\r', '\n'), text) &&
        throw(ArgumentError("Text cells cannot contain tabs or line breaks"))
    return text
end

# INPUT
# keys: nothing or a vector of whole real values. n: row count.
# OUTPUT
# Exact C++ Int64 keys. Invalid, duplicate, or out-of-range keys cause ArgumentError.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _keys(keys, n)
    keys === nothing && return StdVector{Int64}()
    keys isa AbstractVector || throw(ArgumentError("keys must be a vector"))
    length(keys) == n || throw(ArgumentError("keys must have one value per row"))
    result = Int64[]
    for key in keys
        (key isa Real && !(key isa Bool) && isfinite(key) && isinteger(key) &&
         -MAX_EXACT_KEY <= key <= MAX_EXACT_KEY) ||
            throw(ArgumentError("Keys must be whole numbers in [-2^53, 2^53]"))
        push!(result, Int64(key))
    end
    length(unique(result)) == n || throw(ArgumentError("Keys must be unique"))
    return StdVector(result)
end

# INPUT
# data: a matrix with one observation per row. converter: scalar conversion.
# T: scalar C++ element type.
# OUTPUT
# C++ vectors containing rows, independent of Julia's column-major storage.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _rows(data::AbstractMatrix, converter, ::Type{T}) where T
    Base.require_one_based_indexing(data)
    rows = StdVector{StdVector{T}}()
    for i in axes(data, 1)
        push!(rows, StdVector{T}(T[T(converter(data[i, j])) for j in axes(data, 2)]))
    end
    return rows
end

# INPUT
# rows: C++ numeric rows. n and d: result dimensions.
# OUTPUT
# A Julia-owned Float64 matrix. Invalid dimensions cause an error.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _numeric_rows(rows, n, d)
    length(rows) == n || error("Native result has an incorrect row count")
    result = Matrix{Float64}(undef, n, d)
    for i in 1:n
        row = rows[i]
        length(row) == d || error("Native result has an incorrect column count")
        for j in 1:d
            result[i, j] = row[j]
        end
    end
    return result
end

# INPUT
# columns: C++ columns. n: row count. converter and T: Julia cell conversion.
# OUTPUT
# A Julia-owned matrix with one observation per row, including n-by-zero results.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _columns(columns, n, converter, ::Type{T}) where T
    result = Matrix{T}(undef, n, length(columns))
    for j in 1:length(columns)
        column = columns[j]
        length(column) == n || error("Native result has an incorrect row count")
        for i in 1:n
            result[i, j] = converter(column[i])
        end
    end
    return result
end

# INPUT
# key: a native signed 64-bit identifier.
# OUTPUT
# Julia missing for the core sentinel, otherwise the exact integer.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
_read_key(key) = key == typemin(Int64) ? missing : Int64(key)

# INPUT
# value: a native string from a text column.
# OUTPUT
# Julia missing for the reserved NA token, otherwise an owned String.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
_read_text(value) = String(value) == "NA" ? missing : String(value)

# INPUT
# messages: diagnostic text captured from one native call.
# OUTPUT
# Warning records through Julia Logging and other messages on stdout.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _messages(messages)
    for line in split(String(messages), '\n'; keepempty=false)
        if startswith(strip(line), "WARNING")
            @warn line
        else
            println(line)
        end
    end
    return nothing
end

"""
    read_lrn(path; verbose=false)

Read LRN through the C++ core. Return `(header, keys, data, types, comment)`.
`data` is a Float64 matrix with observations in rows. Numeric missing values are NaN.
`keys` contains Int64 values or missing. `types` includes the key column type.
"""
function read_lrn(path::AbstractString; verbose::Bool=false)
    # INPUT
    # path: input file path. verbose: select native information messages.
    # OUTPUT
    # NamedTuple of Julia-owned LRN values. Warnings remain active with verbose=false.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    header, keys, data, types, comment, messages = Native._read_lrn(StdString(_string(path)), verbose)
    _messages(messages)
    return GC.@preserve header keys data types comment (header=String[String(x) for x in header],
            keys=Union{Missing,Int64}[_read_key(x) for x in keys],
            data=_numeric_rows(data, length(keys), length(header)),
            types=Int[Int(x) for x in types], comment=String(comment))
end

"""
    write_lrn(path, data; header=String[], keys=nothing, types=Int[], comment="",
              significant_digits=-1, decimal_digits=-1, scientific=false,
              overwrite=true, verbose=false)

Write a numeric matrix to LRN 2.0. Rows contain observations.
`missing` becomes NaN. Omitted keys select 1:n with a warning.
`types` can describe the data columns or all columns with key type 9 first.
Return nothing. An existing file requires `overwrite=true`.
"""
function write_lrn(path::AbstractString, data::AbstractMatrix;
        header::AbstractVector=String[], keys=nothing, types::AbstractVector=Int[],
        comment::AbstractString="", significant_digits::Integer=-1,
        decimal_digits::Integer=-1, scientific::Bool=false,
        overwrite::Bool=true, verbose::Bool=false)
    # INPUT
    # path and data: output path and observation matrix. Keywords: metadata and writer options.
    # OUTPUT
    # Creates or replaces a LRN file. Invalid inputs cause exceptions before the core write.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    _messages(Native._write_lrn(_strings(header), _keys(keys, size(data, 1)),
        _rows(data, _number, Float64), StdVector{Int32}(Int32.(types)),
        StdString(_string(path)), StdString(_string(comment)),
        Int32(significant_digits), Int32(decimal_digits), scientific, overwrite, verbose))
end

"""
    read_cls(path; verbose=false)

Read CLS. Return `(keys, classes, unique_classes, comment)`.
Invalid keys become missing. Missing classes are NaN.
"""
function read_cls(path::AbstractString; verbose::Bool=false)
    # INPUT
    # path: input file path. verbose: select information messages.
    # OUTPUT
    # NamedTuple of owned class data and metadata, with native diagnostics.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    keys, classes, unique_classes, comment, messages = Native._read_cls(StdString(_string(path)), verbose)
    _messages(messages)
    return GC.@preserve keys classes unique_classes comment (keys=Union{Missing,Int64}[_read_key(x) for x in keys],
            classes=Float64[x for x in classes], unique_classes=Float64[x for x in unique_classes],
            comment=String(comment))
end

"""
    write_cls(path, classes; keys=nothing, comment="", missing_class=NaN,
              overwrite=true, verbose=false)

Write CLS 2.0. Replace missing or NaN classes with `missing_class`.
Class values must be whole numbers in the C++ int range.
The core replaces invalid classes with NaN and gives a warning.
Return nothing.
"""
function write_cls(path::AbstractString, classes::AbstractVector;
        keys=nothing, comment::AbstractString="", missing_class::Real=NaN,
        overwrite::Bool=true, verbose::Bool=false)
    # INPUT
    # path and classes: output path and class vector. Keywords: keys, comment, missing value, flags.
    # OUTPUT
    # Creates or replaces a CLS file and reports diagnostics.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    _messages(Native._write_cls(_keys(keys, length(classes)),
        StdVector{Float64}(_number.(classes)), Float64(missing_class),
        StdString(_string(path)), StdString(_string(comment)), overwrite, verbose))
end

"""
    read_names(path; verbose=false)

Read NAMES. Return `(header, file_header, keys, names, further_texts, comment)`.
`header` labels the additional text columns. `file_header` contains all column labels.
The text matrix contains observations in rows. The reserved NA token becomes missing.
"""
function read_names(path::AbstractString; verbose::Bool=false)
    # INPUT
    # path: input file path. verbose: select information messages.
    # OUTPUT
    # NamedTuple with owned names, nullable text matrix, keys, and metadata.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    header, keys, names, texts, comment, messages = Native._read_names(StdString(_string(path)), verbose)
    _messages(messages)
    labels = GC.@preserve header String[String(x) for x in header]
    return GC.@preserve keys names texts comment (header=labels[3:end], file_header=labels,
            keys=Union{Missing,Int64}[_read_key(x) for x in keys],
            names=MissingText[_read_text(x) for x in names],
            further_texts=_columns(texts, length(keys), _read_text, MissingText),
            comment=String(comment))
end

"""
    write_names(path, names; further_texts=Matrix{String}(undef, length(names), 0),
                header=String[], keys=nothing, comment="", overwrite=true, verbose=false)

Write NAMES 2.0. `names` is a vector. `further_texts` is a matrix with observations in rows.
`header` labels Names and the additional text columns. It can include Key first.
Missing text becomes NA. Text cells cannot contain tabs or line breaks.
Return nothing.
"""
function write_names(path::AbstractString, names::AbstractVector;
        further_texts::AbstractMatrix=Matrix{String}(undef, length(names), 0),
        header::AbstractVector=String[], keys=nothing, comment::AbstractString="",
        overwrite::Bool=true, verbose::Bool=false)
    # INPUT
    # path, names: output path and name vector. Keywords: extra text matrix, labels, keys, comment, flags.
    # OUTPUT
    # Creates or replaces a NAMES file. Inconsistent matrix rows cause ArgumentError.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    size(further_texts, 1) == length(names) ||
        throw(ArgumentError("further_texts must have one row per name"))
    _messages(Native._write_names(_strings(_text.(names)), _strings(header),
        _keys(keys, length(names)), _rows(further_texts, _text, StdString),
        StdString(_string(path)), StdString(_string(comment)), overwrite, verbose))
end

# INPUT
# value: a Date, DateTime, timestamp string, or missing.
# OUTPUT
# A core-compatible timestamp string, without time zone conversion.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
function _timestamp(value)
    value isa DateTime && return Dates.format(value, dateformat"yyyy-mm-dd HH:MM:SS.sss")
    value isa Date && return Dates.format(value, dateformat"yyyy-mm-dd")
    return _text(value)
end

"""
    read_dates(path; verbose=false)

Read DATES. Return `(header, file_header, keys, times, data, dst, timezone, comment)`.
`times` contains timestamp strings or missing. `data` contains numeric observations in rows.
`dst` retains the daylight saving time markers. No time zone conversion occurs.
"""
function read_dates(path::AbstractString; verbose::Bool=false)
    # INPUT
    # path: input file path. verbose: select information messages.
    # OUTPUT
    # NamedTuple of owned DATES values, raw timestamps, DST markers, and zone metadata.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    header, keys, dst, times, data, comment, zone, messages = Native._read_dates(StdString(_string(path)), verbose)
    _messages(messages)
    labels = GC.@preserve header String[String(x) for x in header]
    return GC.@preserve keys times data dst zone comment (header=labels[3:end], file_header=labels,
            keys=Union{Missing,Int64}[_read_key(x) for x in keys],
            times=MissingText[_read_text(x) for x in times],
            data=_columns(data, length(keys), Float64, Float64),
            dst=MissingText[_read_text(x) for x in dst], timezone=String(zone), comment=String(comment))
end

"""
    write_dates(path, times, data; header=["C1", ...], keys=nothing, comment="",
                timezone="UTC", format=-1, overwrite=true, verbose=false)

Write DATES 2.0. `times` accepts Date, DateTime, timestamp strings, or missing.
`header` labels only numeric columns. The default labels are C1, C2, and so on.
`format` selects automatic resolution (-1), dates (1), seconds (2), or milliseconds (3).
`timezone` supplies metadata. Input times must already use that time zone.
Timestamp strings can include a DST abbreviation, such as CEST.
Return nothing. No time zone conversion occurs.
"""
function write_dates(path::AbstractString, times::AbstractVector, data::AbstractMatrix;
        header::AbstractVector=["C$j" for j in axes(data, 2)], keys=nothing,
        comment::AbstractString="", timezone::AbstractString="UTC", format::Integer=-1,
        overwrite::Bool=true, verbose::Bool=false)
    # INPUT
    # path, times, data: output path, timestamps, numeric matrix. Keywords: metadata and writer options.
    # OUTPUT
    # Creates or replaces a DATES file. Invalid shapes or zone declarations cause ArgumentError.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    size(data, 1) == length(times) || throw(ArgumentError("data must have one row per timestamp"))
    length(header) == size(data, 2) || throw(ArgumentError("header must label every numeric column"))
    format in (-1, 1, 2, 3) || throw(ArgumentError("format must be -1, 1, 2, or 3"))
    zone = _text(timezone)
    isempty(strip(zone)) && throw(ArgumentError("timezone cannot be empty"))
    any(line -> startswith(strip(line), "Timezone:"), split(comment, '\n')) &&
        throw(ArgumentError("Use the timezone keyword for zone metadata"))
    _messages(Native._write_dates(_strings(header), _keys(keys, length(times)),
        _strings(_timestamp.(times)), _rows(data, _number, Float64), StdString(_string(path)),
        StdString("Timezone: " * zone * "\n" * _string(comment)), Int32(format), overwrite, verbose))
end

include("common.jl")

end
