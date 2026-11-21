# DataBionicIO common interface

The package name is `DataBionicIO` in R, Python, MATLAB, and Julia.
The eight functions in this reference use the same argument names and order in all four languages.
Matrices contain one record in each row.

## Package use

| Language | Package access | Example reader |
| --- | --- | --- |
| R | `library(DataBionicIO)` | `ReadLRN("example", InDirectory = directory, Verbose = FALSE)` |
| Python | `import DataBionicIO as io` | `io.ReadLRN("example", InDirectory=directory, Verbose=False)` |
| MATLAB | `setupDataIO('modern')` | `[Key, Data, Header, DataDefined, Comments] = DataBionicIO.ReadLRN('example', directory, false)` |
| Julia | `using DataBionicIO` | `ReadLRN("example"; InDirectory=directory, Verbose=false)` |

MATLAB uses positional arguments.
Julia accepts optional arguments as keywords after the necessary arguments.
It also accepts positional arguments in the order given in [Input order](#input-order).

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

`WriteCLS` keeps the R argument order and the name `Comment`.
The other writers use `Comments`.
DTS files use `ReadDates` and `WriteDates`.

The filename and writer data are necessary.
The default input and output directories are the working directory at the time of each call.
R uses `getwd()`, Python uses `os.getcwd()`, and MATLAB and Julia use `pwd()`.
The default values of `Overwrite` and `Verbose` are true.
The default value of `Scientific` is false.

| Optional argument | Default behavior |
| --- | --- |
| `InDirectory`, `OutDirectory` | The working directory at the time of the call. |
| `Overwrite`, `Verbose` | True. |
| `Scientific` | False. |
| `Key` | Input keys when the input contains keys. Without input keys, `1:n` and a warning. |
| `Header` | Available input labels or automatic column labels. |
| `DataDefined` | Type `9` for the key and type `1` for data columns. |
| `FurtherTexts` | No text columns after the primary names column. |
| `Comment`, `Comments` | No comment. |
| `SignificantDigits`, `DecimalDigits` | No rounding options. Binary64 precision. |
| `Int4NaN` | No replacement of missing class values. |
| `Format` | The maximum time resolution in the input. |
| `tz` | An available input time zone. UTC if there is no input time zone. Refer to [DTS time zones](#dts-time-zones). |

The interfaces identify missing metadata with `NULL` in R, `None` in Python, `[]` in MATLAB, and `nothing` in Julia.
An empty comment can also be an empty string.

Without supplied keys, writers use `1:n` and give a warning.
Keys must be integers in `[-2^53, 2^53]`.
Each key must occur only one time.
Empty metadata selects the format defaults.
An empty `Int4NaN` keeps missing class values.

For DTS, an empty `Format` selects the maximum time resolution in the input.
Values `1`, `2`, and `3` select dates, seconds, and milliseconds.
`TSdata` contains a time column and optional numeric columns.
A column with the name `Time` supplies times.
If there is no column with that name, the first column supplies times.
A time vector supplies records without numeric columns.

R accepts a data frame or matrix.
Python accepts a DataFrame, dictionary of columns, or NumPy array.
A nested Python list contains columns, with times first.
MATLAB accepts a table or cell matrix.
Julia accepts a NamedTuple of columns or a matrix.

## Output order

Readers always return the fields in the order given in this table.
Empty comments are empty strings.
If there are no data columns, readers return an empty matrix with one row for each record, or equivalent Python rows.
If there are no headers or DST markers, readers return empty vectors for these fields.

| Reader | Output fields, in order |
| --- | --- |
| `ReadLRN` | `Key`, `Data`, `Header`, `DataDefined`, `Comments` |
| `ReadCLS` | `Key`, `Cls`, `UniqueClasses`, `Comments` |
| `ReadNAMES` | `Key`, `Names`, `FurtherTexts`, `Header`, `Comments` |
| `ReadDates` | `Key`, `Time`, `Data`, `Header`, `Comments`, `Timezone`, `DST` |

R returns a named list.
Python returns a dictionary with this insertion order.
Julia returns a NamedTuple.
MATLAB returns one output for each field in this order.
Writers make a file and have no data result.

For LRN and DTS, `Header` contains labels for `Data`.
For NAMES, `Header` contains labels only for `FurtherTexts`.
`DataDefined` includes the key type first.
The common LRN reader keeps columns with type `0`.

## DTS time zones

DTS files can store local times with a named time zone.
The `tz` argument supplies that name, for example `America/Chicago`.
The file contains a `Timezone` declaration.
The reader returns this name as `Timezone`.
`DST` contains the file abbreviations, such as `CST` and `CDT`.
These markers identify the two occurrences of local times when daylight saving time ends.

R and Python readers use the file time zone for native timestamp values.
Their writers convert zoned input to `tz` and keep the same instant.
The MATLAB writer also converts zoned datetime input to `tz`.
Without `tz`, these writers use the named input zone if it is available.
If there is no named input zone, they use UTC.

MATLAB and Julia readers return local timestamp text, `Timezone`, and `DST`.
The Julia writer uses local input times and records `tz` without native time conversion.
Its default time zone is UTC.
For local text, supply times in the zone given by `tz`.
In Python, MATLAB, and Julia, a `DST` column can supply abbreviations for repeated times.
R gets these abbreviations from POSIXt input.

The parser cannot store numeric DST abbreviations, such as `+11` or `-02`.
Before you write timestamps with numeric DST abbreviations, convert the input to UTC.
Then, use `tz = "UTC"`.
This restriction does not make UTC necessary for `America/Chicago`.

## Examples with input and output directories

These examples read `example.lrn` from the current working directory.
They write `copy.lrn` to its `output` subdirectory.
Each example supplies the two directory arguments.
Change `InDirectory` and `OutDirectory` to use other locations.
The examples make the output directory first.
The writers then make the output files.

R:

```r
library(DataBionicIO)
InDirectory <- getwd()
OutDirectory <- file.path(getwd(), "output")
dir.create(OutDirectory, showWarnings = FALSE)
Result <- ReadLRN("example.lrn", InDirectory = InDirectory)
Key <- Result$Key
Data <- Result$Data
Header <- Result$Header
DataDefined <- Result$DataDefined
Comments <- Result$Comments
WriteLRN("copy.lrn", Data, Header = Header, Key = Key,
         DataDefined = DataDefined, OutDirectory = OutDirectory,
         Comments = Comments)
```

Python:

```python
import os
import DataBionicIO as io
InDirectory = os.getcwd()
OutDirectory = os.path.join(os.getcwd(), "output")
os.makedirs(OutDirectory, exist_ok=True)
Result = io.ReadLRN("example.lrn", InDirectory=InDirectory)
Key = Result["Key"]
Data = Result["Data"]
Header = Result["Header"]
DataDefined = Result["DataDefined"]
Comments = Result["Comments"]
io.WriteLRN("copy.lrn", Data, Header=Header, Key=Key,
            DataDefined=DataDefined, OutDirectory=OutDirectory,
            Comments=Comments)
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
Result = ReadLRN("example.lrn"; InDirectory=InDirectory)
Key = Result.Key
Data = Result.Data
Header = Result.Header
DataDefined = Result.DataDefined
Comments = Result.Comments
WriteLRN("copy.lrn", Data; Header=Header, Key=Key,
         DataDefined=DataDefined, OutDirectory=OutDirectory,
         Comments=Comments)
```

All four examples use the default `Overwrite=true`.
Set `Overwrite` to false to keep a file that is in the output directory.
In MATLAB, `Overwrite` is the eleventh argument of `WriteLRN`.
For default values of optional arguments before `Overwrite`, use `[]`.
Without a directory argument, each reader and writer uses the working directory at the time of the call.

## Previous interfaces

The Python import `pyDataIO` keeps the previous Python interface.
Its result aliases are different from those of the common interface.
Its writers also use `Overwrite=True` by default.
The unqualified MATLAB functions keep their previous argument and output order.
Julia functions with names such as `read_lrn` keep their previous interface.

For the same function names and argument order across languages, use the `DataBionicIO` interface in this reference.
The R package name replaces `cdbt.DataIO`.
A new source build does not replace installed packages.

## Advanced text options

These options are not necessary for usual calls.
The positional arguments keep their order.

The four readers accept `Encoding` for a known input encoding.
Without this argument, the reader selects the encoding from a byte order mark (BOM).
If there is no BOM, the reader uses UTF-8.
The permitted `Encoding` values are `UTF-8`, `Windows-1252`, and `ISO-8859-1` (`Latin-1`).

A BOM is necessary for UTF-16 and UTF-32 input.
An `Encoding` value that does not agree with the BOM causes an error.
Text with encoding errors also causes a reader error.
Legacy decoding gives one warning.
The reader ignores one initial UTF-8 BOM without a warning.

Writers always use UTF-8 without a BOM.
They keep Unicode sequences without automatic normalization.

`WriteNAMES` accepts `TextReplacement`, with `_` as the default.
Before the write operation, it replaces each TAB, LF, CR, or NUL character in `Names` and `FurtherTexts`.
A CR followed by LF gives two replacements.
The writer does not change spaces or literal backslash escapes.

The replacement must be a Unicode string that is not empty.
The replacement cannot contain the four characters.

One warning gives the number of replaced characters and the number of fields with replacements.
The writer also gives this warning when `Verbose` is false.
If an encoding or replacement-option error occurs, the writer does not change caller inputs or destination files.
These options do not change header rules, missing-value markers, or the restriction on numeric DST abbreviations.

In R, the argument names in `...` must agree with the specified names.
The Details section of the R help gives information about these options.

Python accepts these settings as keyword-only arguments. Julia uses keyword arguments.
MATLAB accepts trailing name-value pairs through `varargin`, after the positional arguments in the common interface.
For default values of MATLAB positional arguments before the name-value pair, use `[]`.

Unknown, duplicate, and unnamed advanced options cause errors.
The table in [Input order](#input-order) gives the defaults for the positional arguments.
These advanced options do not change the argument order.
