# DTS: time series

A DTS file contains keys, time values, and optional numeric measurements.
The code also uses the name DATES for this format.
The functions are `ReadDates` and `WriteDates`.

```text
#<?dates version="2.0"?>
# Timezone: Europe/Berlin
% 2
% 4
% Key	Time	TZ_DST	Value
101	2024-10-27 02:30:00	CEST	1.25
205	2024-10-27 02:30:00	CET	2.5
```

## Layout

Three header lines give the row count, column count, and column names.
The column count includes `Key`, `Time`, optional `TZ_DST`, and all measurement columns.
`Key` must be the first column.
`Time` must be the second column.
If there is a `TZ_DST` column, it must be the third column.
There is no column-type line.

Measurement labels start with a letter and contain letters, digits, periods, or underscores.
The reader rejects invalid DTS labels.
It does not remove characters from these labels.

A file can contain only `Key` and `Time`.
`ReadDates` also accepts a `.csv` extension for this same tab-separated layout.
A `.csv` extension does not change the field separator.

| Element | Meaning |
| --- | --- |
| First `%` line | Number of data rows. |
| Second `%` line | Number of file columns. |
| Third `%` line | Labels for all file columns. |
| `Key` | Integer record identifier. |
| `Time` | Calendar date or timestamp. |
| `TZ_DST` | Optional time zone abbreviation. |
| Measurement field | Numeric value or a missing-value marker. |
| `# Timezone: name` | Time zone name for the time values. |

## Time resolution

| `Format` | Output layout |
| --- | --- |
| `1` | `YYYY-MM-DD` |
| `2` | `YYYY-MM-DD hh:mm:ss` |
| `3` | `YYYY-MM-DD hh:mm:ss.fff` |

Without `Format`, the writer selects the maximum time resolution in the input.
A setting with less time resolution removes time components.
A setting with more time resolution adds zero time components.
For automatic selection, use `NULL` in R, `None` in Python, `[]` in MATLAB, or `nothing` in Julia.

DTS files can store milliseconds.
They cannot store time components of less than one millisecond.

## Time zones

The `Timezone` line identifies the time zone.
Without this line, readers use UTC.
The reader does not include this declaration in `Comments`.

R and Python readers return native timestamp values.
MATLAB and Julia readers return local timestamp text, `Timezone`, and `DST`.
When you transfer timestamps, keep these fields together.

R, Python, and MATLAB writers can convert zoned native timestamps to `tz` and keep the same instant.
Julia writes local input times in the supplied zone without native time zone conversion.
Its default zone is UTC.
Without `tz`, R, Python, and MATLAB use an available input zone, or UTC.
For local text, supply values in the time zone given by `tz`.

## Repeated local times

The example contains two different instants with the same local clock value.
`CEST` and `CET` identify the two occurrences of this hour.
Python, MATLAB, and Julia accept a `DST` input column for such markers.
R gets the markers from POSIXt values.

R and Python use the abbreviations to select the correct instant.
An incorrect marker gives a warning and a missing time.
Without a marker, these readers select the later occurrence of a repeated local time.
A local time that does not exist becomes missing.

The writer parser does not accept numeric DST abbreviations such as `+11` or `-02`.
Before you write timestamps with numeric DST abbreviations, convert them to UTC.
Then, use `tz="UTC"`.
In Julia, the writer does not convert local text when you change only `tz`.

## Missing values and output

Missing numeric measurements become NaN.
Readers can keep a row with a missing time.
Invalid timestamp syntax can stop the reader.
The R writer rejects missing input times.

R accepts a time vector, a matrix, or a data frame for `WriteDates`.
Put time in the first column, or use `Time` as its column name.
The R function converts other measurement types with `as.numeric(as.character(x))`.
An incorrect numeric conversion gives an R warning and a missing measurement.

Missing times return as `NA` in R, `None` in Python, and `missing` in Julia.
MATLAB keeps the text marker `NA`.
The writer keeps sufficient digits to read each binary64 measurement again without a change.
It does not use the LRN precision arguments.

`ReadDates` returns `Key`, `Time`, `Data`, `Header`, `Comments`, `Timezone`, and `DST`.
`Header` contains labels for numeric measurements only.
`DST` is empty if the file has no `TZ_DST` column.

The [hydrology tutorial](../tutorials/hydrology.md) uses calendar dates.
Its UTC declaration does not identify the time zone of the source measurements.
