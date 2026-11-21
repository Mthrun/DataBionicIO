# LRN: numeric measurements

An LRN file contains a key column and numeric data columns.
Four header lines give the row count, column count, type codes, and column names.
The column count includes the key column.

```text
#<?lrn version="2.0"?>
# Two observations
% 2
% 3
% 9	1	1
% Key	Length	Mass
101	1.5	2
205	3.5	NaN
```

## Header and data fields

| Element | Meaning |
| --- | --- |
| `n` | Number of data rows. |
| `d` | Number of numeric data columns. |
| `m` | Number of file columns, including `Key`. Thus, `m = d + 1`. |
| First `%` line | `n`. |
| Second `%` line | `m`. |
| Third `%` line | One type code for each file column. |
| Fourth `%` line | One label for each file column. |
| First data field | Integer key for the row. |
| Remaining data fields | Numeric measurements for the row. |

In format 2.0, put the key column first.
Give only that column type code `9`.

## Column types

Type `9` identifies the key column.
Type `1` identifies numeric data.
Type `0` identifies a column for exclusion by software that uses the file.
The common `ReadLRN` interface returns that column.

The [column-type table](../guide/keys.md#column-type-codes) gives all codes from the format documentation.

The reader returns type codes.
It does not apply training or classification rules.
Character type codes do not cause `ReadLRN` to return text columns.
Use NAMES for text fields.

## Reader result

`ReadLRN` returns `Key`, `Data`, `Header`, `DataDefined`, and `Comments`.
`Header` contains labels for the numeric data columns only.
`DataDefined` includes the key type first.

## Writer input

Supply a numeric matrix with one observation in each row.
Supply the keys independently.
For two data columns, supply two data labels or a full header with `Key` first.
If you supply `DataDefined`, use one type code for each file column.

Use labels that start with a letter and contain letters, digits, periods, or underscores.
LRN removes spaces, commas, and semicolons from labels with a warning.
Writers also remove tabs from supplied labels.
Empty labels, line breaks, and NUL cause errors.
Other nonstandard labels remain, with a warning.

R converts a data frame to a numeric matrix and gives a warning.
Before this conversion, select the necessary values from factor columns.
R and Python replace a different key label with `Key`.
MATLAB and Julia need the literal key label `Key` in a full header.

## Numeric precision

Without a precision argument, the writer keeps sufficient digits to read each binary64 value again without a change.
`SignificantDigits` selects the number of significant digits.
`DecimalDigits` selects the number of decimal places.
If you supply the two arguments, the writer uses `SignificantDigits`.

`Scientific` selects the notation after rounding.
`DecimalDigits=0` rounds to integers.

For input values `1` and `1.23456`, the precision options give these results:

| Options | Output |
| --- | --- |
| `SignificantDigits=4`, `Scientific=false` | `1`, `1.235` |
| `SignificantDigits=4`, `Scientific=true` | `1e+00`, `1.235e+00` |

The writer removes decimal zeros at the end.
It keeps exponent digits.

## Add rows in R

`Append2LRN` adds rows to an existing LRN file and updates its row count.
It keeps the existing data text and comments.
It writes a temporary file before it replaces the input file.

This R function has a different key limit from the common writers.
Its keys must be unique integers in `[-2147483647, 2147483647]`.
The new keys must not occur in the file.
The data must have the same number of measurement columns as the file.

## Legacy LRN

A legacy key column can have a different name or position.
Type `9` identifies that column.
Without a key column, the reader supplies keys from 1 to the row count and gives a warning.

Refer to [Hepta](../tutorials/hepta.md) and [flow cytometry](../tutorials/flow-cytometry.md) for complete examples.
