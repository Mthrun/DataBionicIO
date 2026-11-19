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
The input and output directories default to the working directory at the time of each call.
R uses `getwd()`, Python uses `os.getcwd()`, and MATLAB and Julia use `pwd()`.
The default values of `Overwrite` and `Verbose` are true.
The default value of `Scientific` is false.

| Optional argument | Default behavior |
| --- | --- |
| `InDirectory`, `OutDirectory` | Use the current working directory at each call. |
| `Overwrite`, `Verbose` | True. |
| `Scientific` | False. |
| `Key` | Use keys from the input when supported; otherwise use `1:n` with a warning. |
| `Header` | Use available input labels or automatic column labels. |
| `DataDefined` | Use type `9` for the key and type `1` for data columns. |
| `FurtherTexts` | No additional text columns. |
| `Comment`, `Comments` | No comment. |
| `SignificantDigits`, `DecimalDigits` | No requested rounding; keep binary64 precision. |
| `Int4NaN` | Keep missing class values. |
| `Format` | Select timestamp precision from the input. |
| `tz` | Use an available input time zone, otherwise UTC; see the time zone section below. |

The interfaces express absent metadata with `NULL` in R, `None` in Python, `[]` in MATLAB, and `nothing` in Julia.
An empty comment can also be an empty string.

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

## Examples with input and output directories

These examples read `example.lrn` from the current working directory.
They write `copy.lrn` to its `output` subdirectory.
Each example supplies both directory arguments.
Change `InDirectory` and `OutDirectory` to use other locations.
The writers create the output files; the examples create the output directory first.

R:

```r
library(DataBionicIO)
InDirectory <- getwd()
OutDirectory <- file.path(getwd(), "output")
dir.create(OutDirectory, showWarnings = FALSE)
result <- ReadLRN("example.lrn", InDirectory = InDirectory)
WriteLRN("copy.lrn", result$Data, Header = result$Header, Key = result$Key,
         DataDefined = result$DataDefined, OutDirectory = OutDirectory,
         Comments = result$Comments)
```

Python:

```python
import os
import DataBionicIO as io
InDirectory = os.getcwd()
OutDirectory = os.path.join(os.getcwd(), "output")
os.makedirs(OutDirectory, exist_ok=True)
result = io.ReadLRN("example.lrn", InDirectory=InDirectory)
io.WriteLRN("copy.lrn", result["Data"], Header=result["Header"], Key=result["Key"],
            DataDefined=result["DataDefined"], OutDirectory=OutDirectory,
            Comments=result["Comments"])
```

MATLAB:

```matlab
setupDataIO('modern');
InDirectory = pwd;
OutDirectory = fullfile(pwd, 'output');
if ~isfolder(OutDirectory), mkdir(OutDirectory); end
[Key, Data, Header, DataDefined, Comments] = DataBionicIO.ReadLRN('example.lrn', InDirectory);
DataBionicIO.WriteLRN('copy.lrn', Data, Header, Key, DataDefined, OutDirectory, Comments);
```

Julia:

```julia
using DataBionicIO
InDirectory = pwd()
OutDirectory = joinpath(pwd(), "output")
mkpath(OutDirectory)
result = ReadLRN("example.lrn"; InDirectory=InDirectory)
WriteLRN("copy.lrn", result.Data; Header=result.Header, Key=result.Key,
         DataDefined=result.DataDefined, OutDirectory=OutDirectory,
         Comments=result.Comments)
```

All four examples use the default `Overwrite=true`.
Set `Overwrite` to false to keep an existing output file.
In MATLAB, `Overwrite` is the eleventh argument of `WriteLRN`.
Use `[]` for omitted optional arguments before it.
Without a directory argument, each reader and writer uses the working directory at the time of the call.

## Existing interfaces

The Python import `pyDataIO` keeps the previous Python interface.
Its result aliases differ from the common interface.
Its writers also use `Overwrite=True` by default.
The unqualified MATLAB functions keep their previous argument and output order.
Julia functions with names such as `read_lrn` keep their previous interface.

Use the `DataBionicIO` interface above for calls shared across languages.
The R package name replaces `cdbt.DataIO`.
Existing installed packages are separate from a new source build.
