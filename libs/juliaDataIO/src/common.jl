# INPUT
# File names, row-oriented data, and format-specific metadata.
# OUTPUT
# Common DataBionicIO functions with the same argument and result order as R.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

export ReadLRN, WriteLRN, ReadCLS, WriteCLS, ReadNAMES, WriteNAMES, ReadDates, WriteDates

"""Read LRN. Return Key, Data, Header, DataDefined, Comments in this order."""
function ReadLRN(FileName; InDirectory=pwd(), Verbose=true)
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Data, Header, DataDefined, Comments in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    value = read_lrn(joinpath(InDirectory, FileName); verbose=Verbose)
    return (Key=value.keys, Data=value.data, Header=value.header,
            DataDefined=value.types, Comments=value.comment)
end

"""Read CLS. Return Key, Cls, UniqueClasses, Comments in this order."""
function ReadCLS(FileName; InDirectory=pwd(), Verbose=true)
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Cls, UniqueClasses, Comments in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    value = read_cls(joinpath(InDirectory, FileName); verbose=Verbose)
    return (Key=value.keys, Cls=value.classes, UniqueClasses=value.unique_classes,
            Comments=value.comment)
end

"""Read NAMES. Return Key, Names, FurtherTexts, Header, Comments in this order."""
function ReadNAMES(FileName; InDirectory=pwd(), Verbose=true)
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Names, FurtherTexts, Header, Comments in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    value = read_names(joinpath(InDirectory, FileName); verbose=Verbose)
    return (Key=value.keys, Names=value.names, FurtherTexts=value.further_texts,
            Header=value.header, Comments=value.comment)
end

"""
Read DTS. Return Key, Time, Data, Header, Comments, Timezone, DST in this order.
Time contains local timestamp strings. Timezone and DST retain their interpretation.
No native time zone conversion occurs.
"""
function ReadDates(FileName; InDirectory=pwd(), Verbose=true)
    # INPUT
    # FileName, InDirectory, Verbose. See the function documentation and API.md.
    # OUTPUT
    # Key, Time, Data, Header, Comments, Timezone, DST in this fixed order.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    value = read_dates(joinpath(InDirectory, FileName); verbose=Verbose)
    return (Key=value.keys, Time=value.times, Data=value.data, Header=value.header,
            Comments=value.comment, Timezone=value.timezone, DST=value.dst)
end

"""Write LRN rows. Optional arguments follow the common DataBionicIO order."""
function WriteLRN(FileName, Data; Header=nothing, Key=nothing, DataDefined=nothing,
        OutDirectory=pwd(), Comments=nothing, SignificantDigits=nothing,
        DecimalDigits=nothing, Scientific=false, Overwrite=true, Verbose=true)
    # INPUT
    # FileName, Data, Header, Key, DataDefined, OutDirectory, Comments, SignificantDigits, DecimalDigits, Scientific, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return write_lrn(joinpath(OutDirectory, FileName), Data;
        header=isnothing(Header) ? String[] : Header, keys=Key,
        types=isnothing(DataDefined) ? Int[] : DataDefined,
        comment=isnothing(Comments) ? "" : Comments,
        significant_digits=isnothing(SignificantDigits) ? -1 : SignificantDigits,
        decimal_digits=isnothing(DecimalDigits) ? -1 : DecimalDigits,
        scientific=Scientific, overwrite=Overwrite, verbose=Verbose)
end

"""Write CLS. OutDirectory precedes Key, as in the R interface."""
function WriteCLS(FileName, Cls; OutDirectory=pwd(), Key=nothing, Comment=nothing,
        Int4NaN=nothing, Overwrite=true, Verbose=true)
    # INPUT
    # FileName, Cls, OutDirectory, Key, Comment, Int4NaN, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return write_cls(joinpath(OutDirectory, FileName), Cls; keys=Key,
        comment=isnothing(Comment) ? "" : Comment,
        missing_class=isnothing(Int4NaN) ? NaN : Int4NaN,
        overwrite=Overwrite, verbose=Verbose)
end

"""Write names and optional text rows, with the common argument order."""
function WriteNAMES(FileName, Names; Key=nothing, FurtherTexts=nothing, Header=nothing,
        OutDirectory=pwd(), Comments="", Overwrite=true, Verbose=true)
    # INPUT
    # FileName, Names, Key, FurtherTexts, Header, OutDirectory, Comments, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return write_names(joinpath(OutDirectory, FileName), Names; keys=Key,
        further_texts=isnothing(FurtherTexts) ? Matrix{String}(undef, length(Names), 0) : FurtherTexts,
        header=isnothing(Header) ? String[] : Header,
        comment=isnothing(Comments) ? "" : Comments, overwrite=Overwrite, verbose=Verbose)
end

"""
Write DTS from a NamedTuple of columns, a row-oriented matrix, or a time vector.
A Time column supplies times. Other columns contain numeric data, except DST.
A DST column supplies abbreviations for repeated local times, such as CDT and CST.
Times must already use tz. The default is UTC. No native time zone conversion occurs.
"""
function WriteDates(FileName, TSdata; Key=nothing, OutDirectory=pwd(), Comments=nothing,
        tz=nothing, Format=nothing, Overwrite=true, Verbose=true)
    # INPUT
    # FileName, TSdata, Key, OutDirectory, Comments, tz, Format, Overwrite, Verbose. See the function documentation and API.md.
    # OUTPUT
    # A format 2.0 file. No return value.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    if TSdata isa NamedTuple
        labels = collect(propertynames(TSdata))
        isempty(labels) && throw(ArgumentError("TSdata must contain a time column"))
        time_label = :Time in labels ? :Time : first(labels)
        times = TSdata[time_label]
        numeric_labels = filter(x -> x != time_label && x != :DST, labels)
        data = isempty(numeric_labels) ? zeros(length(times), 0) : hcat((TSdata[x] for x in numeric_labels)...)
        header = string.(numeric_labels)
        if :DST in labels
            length(TSdata.DST) == length(times) || throw(ArgumentError("DST must have one value per time"))
            times = [_timestamp(t) * " " * string(d) for (t, d) in zip(times, TSdata.DST)]
        end
    elseif TSdata isa AbstractMatrix
        size(TSdata, 2) > 0 || throw(ArgumentError("TSdata must contain a time column"))
        times = TSdata[:, 1]
        data = TSdata[:, 2:end]
        header = ["C$j" for j in axes(data, 2)]
    elseif TSdata isa AbstractVector
        times = TSdata
        data = zeros(length(times), 0)
        header = String[]
    else
        throw(ArgumentError("TSdata must be a NamedTuple of columns, matrix, or time vector"))
    end
    any(ismissing, times) && throw(ArgumentError("Times cannot contain missing values"))
    return write_dates(joinpath(OutDirectory, FileName), times, data;
        header=header, keys=Key, comment=isnothing(Comments) ? "" : Comments,
        timezone=isnothing(tz) ? "UTC" : tz, format=isnothing(Format) ? -1 : Format,
        overwrite=Overwrite, verbose=Verbose)
end

# Positional calls use the same order as R, Python, and MATLAB.
ReadLRN(FileName, InDirectory, Verbose=true) = ReadLRN(FileName; InDirectory, Verbose)
ReadCLS(FileName, InDirectory, Verbose=true) = ReadCLS(FileName; InDirectory, Verbose)
ReadNAMES(FileName, InDirectory, Verbose=true) = ReadNAMES(FileName; InDirectory, Verbose)
ReadDates(FileName, InDirectory, Verbose=true) = ReadDates(FileName; InDirectory, Verbose)
WriteLRN(FileName, Data, Header, Key=nothing, DataDefined=nothing, OutDirectory=pwd(),
    Comments=nothing, SignificantDigits=nothing, DecimalDigits=nothing, Scientific=false,
    Overwrite=true, Verbose=true) = WriteLRN(FileName, Data; Header, Key, DataDefined,
    OutDirectory, Comments, SignificantDigits, DecimalDigits, Scientific, Overwrite, Verbose)
WriteCLS(FileName, Cls, OutDirectory, Key=nothing, Comment=nothing, Int4NaN=nothing,
    Overwrite=true, Verbose=true) = WriteCLS(FileName, Cls; OutDirectory, Key, Comment,
    Int4NaN, Overwrite, Verbose)
WriteNAMES(FileName, Names, Key, FurtherTexts=nothing, Header=nothing, OutDirectory=pwd(),
    Comments="", Overwrite=true, Verbose=true) = WriteNAMES(FileName, Names; Key,
    FurtherTexts, Header, OutDirectory, Comments, Overwrite, Verbose)
WriteDates(FileName, TSdata, Key, OutDirectory=pwd(), Comments=nothing, tz=nothing,
    Format=nothing, Overwrite=true, Verbose=true) = WriteDates(FileName, TSdata; Key,
    OutDirectory, Comments, tz, Format, Overwrite, Verbose)
