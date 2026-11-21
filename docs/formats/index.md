# File formats

The same C++ code reads and writes four text formats.
The R, Python, MATLAB, and Julia common interfaces use that code.
These chapters include the applicable format definitions from `ZFileFormatDocuments`.
They give the format rules for DataBionicIO and its language interfaces.

| Extension | Contents | Reader | Writer |
| --- | --- | --- | --- |
| `.lrn` | Keys and numeric measurements. | `ReadLRN` | `WriteLRN` |
| `.cls` | Keys and integer class assignments. | `ReadCLS` | `WriteCLS` |
| `.names` | Keys, names, and optional text fields. | `ReadNAMES` | `WriteNAMES` |
| `.dts` | Keys, time values, and optional numeric measurements. | `ReadDates` | `WriteDates` |

## Common layout

Each data line contains one record.
Tabs divide fields.
Comment lines start with `#`.
Header lines start with `%`.
Numbers use a decimal point.

The generation tag identifies the format and version.
A writer also adds a creation timestamp to that tag.
User comments and the generation tag are different metadata.
Writers use format 2.0.
The file-format version and the package version are different numbers.

The examples on the format pages use tab separators in their data blocks.
The [tutorial files](../tutorials/index.md) give complete examples.

## Generation tags and comments

```text
#<?lrn version="2.0" created_at="2026-10-19 12:00:00"?>
# User comment
#
# Another comment line
```

The tag is the first line.
For the other formats, the tag name is `cls`, `names`, or `dates`.
`created_at` gives the local file creation time.
It does not identify the time of a measurement.

Each user comment line starts with `#`.
A line with only `#` represents an empty comment line.
Readers return user comments in `Comments` and exclude the generation tag.
DTS also excludes its `Timezone` declaration from `Comments`.

## Text layout

Use UTF-8 for file exchange.
Readers accept LF and CRLF line endings.
The last line does not need a newline.
Empty lines do not add data rows.
Quotation marks do not escape field separators.
Put all header lines before the data rows.

Refer to [encoding and text replacement](../guide/encoding.md) for version 1.0.2 options.
Readers keep the stored row order.
Refer to [keys and record alignment](../guide/keys.md) before you connect records.

## Missing values

Use `NaN` for missing numeric measurements or classes.
The numeric readers also accept `NA` and empty numeric fields.
Use `NA` for missing NAMES text.
An empty text field also identifies missing text.

## Legacy input

For LRN, CLS, and NAMES, a file without a version tag uses the legacy layout rules.
A version 1.0 tag also selects those rules.
Version 2.0 uses the headers for format 2.0.
Other versions cause an error.
A read error does not cause a second read operation with the legacy rules.

## Recovery and errors

Readers can keep records with missing fields and a warning.
Fields after the declared column count do not increase the number of columns.
A different row count causes a warning.
Readers keep the rows that they can parse.
Invalid timestamps or errors in necessary headers can stop a read operation.

Before you connect records from different files, compare their keys.
Recovery does not show that the source file is correct.

A readable numeric prefix remains a numeric value.
For example, `12oops` gives `12`, and `3,4oops` gives `3`.
Each conversion gives a warning.
A comma does not act as a decimal point.

Missing text fields use the NAMES missing-value marker.
Invalid keys become `NA` in R, `None` in Python, `NaN` in MATLAB, and `missing` in Julia.
The [key rules](../guide/keys.md) give the permitted values and writer restrictions.

DTS uses its separate header parser.
The LRN, CLS, and NAMES legacy layout rules do not apply to DTS.

## Other formats

R and MATLAB also contain functions for other formats.
Those functions do not all use the same C++ implementation.
A function in R or MATLAB can have no equivalent in Python or Julia.
Use the package help for DATA, BM, FCS, QS, QS2, and other formats.
