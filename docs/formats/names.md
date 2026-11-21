# NAMES: names and text

A NAMES file connects keys to a primary name and optional text fields.
Three header lines give the row count, column count, and column names.
There is no column-type line.

```text
#<?names version="2.0"?>
# Sample labels
% 2
% 3
% Key	Names	Description
101	Sample_A	First observation
205	Sample_B	NA
```

## Header and data fields

| Element | Meaning |
| --- | --- |
| First `%` line | Number of data rows. |
| Second `%` line | Number of file columns, including `Key` and the primary names column. |
| Third `%` line | One label for each file column. |
| First data field | Integer key for the row. |
| Second data field | Primary name for the row. |
| Remaining data fields | Optional text descriptions for the row. |

## Field meaning

The first column contains keys.
The second column contains names.
The remaining columns contain more text.
The primary names column can have a different label, such as `Column_Name`.

`ReadNAMES` returns `Key`, `Names`, `FurtherTexts`, `Header`, and `Comments`.
`Header` contains labels only for the text columns after the primary names column.
It does not contain the primary names label from the file.

## Keep the primary label

First assign the reader output fields to separate objects.
To keep a different primary label, supply a full header:

```python
Result = io.ReadNAMES("example", InDirectory=InDirectory)
Key = Result["Key"]
Names = Result["Names"]
FurtherTexts = Result["FurtherTexts"]
Header = Result["Header"]
Comments = Result["Comments"]
FullHeader = ["Key", "Column_Name"] + list(Header)
io.WriteNAMES("copy", Names, Key=Key,
              FurtherTexts=FurtherTexts, Header=FullHeader,
              OutDirectory=OutDirectory, Comments=Comments)
```

The [Firebrowse tutorial](../tutorials/firebrowse.md) uses this procedure.

## Writer labels

The first label of a full header is `Key`.
R and Python replace a different key label with `Key`.
MATLAB and Julia need the literal label `Key`.

`Header` can label all file columns, names and descriptions, or only the description columns.
For a header with only description labels, the writer adds `Names` before those labels.
Without labels, the writer uses `Names`, `C1`, `C2`, and subsequent numbers.

## Text restrictions

Tabs divide fields.
Spaces in a field are text.
Quotation marks do not escape tabs or line breaks.
Missing text uses `NA` or an empty field.

Readers return missing text as `NA` in R, `None` in Python, and `missing` in Julia.
MATLAB returns the text marker `NA`.
An empty string does not stay distinct from missing text after a write and read operation.
Literal `NA` text also represents a missing value.

The reader keeps spaces at the start and end of text fields.
MATLAB character padding can change spaces at the end.
Refer to [text encoding](../guide/encoding.md) for Unicode and version 1.0.2 replacement behavior.

Column labels and text fields have different rules.
LRN and NAMES remove spaces, commas, and semicolons from labels with a warning.
Writers also remove tabs from supplied labels.
Empty labels, line breaks, and NUL cause errors.

## Legacy NAMES

The column count is optional in legacy files.
The column count and column names can also be missing together.
The first data row then sets the number of columns.
Subsequent data rows cannot add columns.
