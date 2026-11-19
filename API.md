# DataBionicIO common interface

The package name is `DataBionicIO` in R, Python, MATLAB, and Julia.
The eight functions below use the same argument names and order in all four languages.
Matrices contain one record per row.

## Package use

| Language | Package access | Example reader |
| --- | --- | --- |
| R | `library(DataBionicIO)` | `ReadLRN("example", InDirectory = directory, Verbose = FALSE)` |
| Python | `import DataBionicIO as io` | `io.ReadLRN("example", InDirectory=directory, Verbose=False)` |
| MATLAB | `setupDataIO('modern')` | `[Key, Data, Header, DataDefined, Comments] = DataBionicIO.ReadLRN('example', directory, false)` |
| Julia | `using DataBionicIO` | `ReadLRN("example"; InDirectory=directory, Verbose=false)` |

MATLAB uses positional arguments.
Julia accepts optional arguments as keywords after the required arguments, or as positional arguments in the order below.

## Input order

Each reader has these arguments:

```text
ReadLRN(FileName, InDirectory, Verbose)
ReadCLS(FileName, InDirectory, Verbose)
ReadNAMES(FileName, InDirectory, Verbose)
ReadDates(FileName, InDirectory, Verbose)
```

Each writer has these arguments:

```text
WriteLRN(FileName, Data, Header, Key, DataDefined, OutDirectory, Comments,
         SignificantDigits, DecimalDigits, Scientific, Overwrite, Verbose)
WriteCLS(FileName, Cls, OutDirectory, Key, Comment, Int4NaN, Overwrite, Verbose)
WriteNAMES(FileName, Names, Key, FurtherTexts, Header, OutDirectory,
           Comments, Overwrite, Verbose)
WriteDates(FileName, TSdata, Key, OutDirectory, Comments, tz, Format,
           Overwrite, Verbose)
```

`WriteCLS` keeps the existing R argument order and the name `Comment`.
The other writers use `Comments`.
DTS files use `ReadDates` and `WriteDates`.

The file name and writer data are required.
The directory defaults to the current working directory.
The default values of `Overwrite` and `Verbose` are true.
The default value of `Scientific` is false.

Without supplied keys, writers use `1:n` and give a warning.
Keys must be unique whole numbers in `[-2^53, 2^53]`.
Empty metadata selects the format defaults.
An empty `Int4NaN` keeps missing class values.

For DTS, an empty `Format` selects the greatest precision in the input.
Values `1`, `2`, and `3` select dates, seconds, and milliseconds.
`TSdata` contains a time column and optional numeric columns.
A column named `Time` supplies times.
Otherwise, the first column supplies times.
A time vector supplies records without numeric columns.

R accepts a data frame or matrix.
Python accepts a DataFrame, dictionary of columns, or NumPy array.
A nested Python list contains columns, with times first.
MATLAB accepts a table or cell matrix.
Julia accepts a NamedTuple of columns or a matrix.

## Output order

Readers always return the fields below, in this order.
Empty comments are empty strings.
Absent data columns give an empty matrix with one row per record, or equivalent Python rows.
Absent headers and DST markers give empty vectors.

| Reader | Output fields, in order |
| --- | --- |
| `ReadLRN` | `Key`, `Data`, `Header`, `DataDefined`, `Comments` |
| `ReadCLS` | `Key`, `Cls`, `UniqueClasses`, `Comments` |
| `ReadNAMES` | `Key`, `Names`, `FurtherTexts`, `Header`, `Comments` |
| `ReadDates` | `Key`, `Time`, `Data`, `Header`, `Comments`, `Timezone`, `DST` |

R returns a named list.
Python returns a dictionary with this insertion order.
Julia returns a NamedTuple.
MATLAB returns separate outputs in this order.
Writers create a file and have no data result.

`Header` labels `Data` for LRN and DTS.
For NAMES, `Header` labels only `FurtherTexts`.
`DataDefined` includes the key type first.
The common LRN reader keeps columns with type `0`.

## DTS time zones

DTS files can store local times with a named time zone.
The `tz` argument supplies that name, for example `America/Chicago`.
The file contains a `Timezone` declaration.
The reader returns this name as `Timezone`.
`DST` contains the file abbreviations, such as `CST` and `CDT`.
These markers distinguish repeated local times when daylight saving time ends.

R and Python readers use the file time zone for native timestamp values.
Their writers express zoned input in `tz` without changing the instant.
The MATLAB writer also expresses zoned datetime input in `tz`.
Without `tz`, these writers use the named input zone when available, otherwise UTC.

MATLAB and Julia readers return local timestamp text, `Timezone`, and `DST`.
The Julia writer uses local input times and records `tz` without native time conversion.
Its default time zone is UTC.
For local text, supply times in the zone given by `tz`.
In Python, MATLAB, and Julia, a `DST` column can supply abbreviations for repeated times.
R obtains these abbreviations from POSIXt input.

The shared parser cannot store numeric DST abbreviations, such as `+11` or `-02`.
For these timestamps, convert the input to UTC before writing with `tz = "UTC"`.
This restriction does not make UTC necessary for `America/Chicago`.

## Existing interfaces

The Python import `pyDataIO` keeps the previous Python interface.
Its default replacement permission and result aliases differ from the common interface.
The unqualified MATLAB functions keep their previous argument and output order.
Julia functions with names such as `read_lrn` keep their previous interface.

Use the `DataBionicIO` interface above for calls shared across languages.
The R package name replaces `cdbt.DataIO`.
Existing installed packages are separate from a new source build.
