# Keys and record alignment

A key identifies one record.
The same key can connect measurements in LRN, a class in CLS, and a name in NAMES.
Gaps between key values are permitted.

## Permitted keys

Writers accept integers in `[-2^53, 2^53]`.
Each key must occur only one time.
The two endpoints are permitted.
Missing, infinite, fractional, and duplicate keys cause a writer error.
Writers do not accept integers from the full signed 64-bit range.

Do not first convert a larger identifier to a floating-point number.
That conversion can change digits before the writer examines the value.
R accepts numeric or integer vectors, but not `bit64::integer64` vectors.

## Compare row order

`TheSameKey(a, b)` compares vector lengths and values at the same positions.
It does not sort or align records.
It does not find duplicate keys.
Two vectors with the same duplicate values can give `true`.
Missing values give `false`.

Use `TheSameKey` to compare the keys before you connect records.
If `TheSameKey` returns `true`, keep the input order.
Otherwise, put the companion data and its keys in the reference-key order.
Apply the same row indices to the companion data and its keys.
Then compare the keys again with `TheSameKey`.

The examples use no other assertions.

Assign the necessary reader output fields to separate objects.
Use these objects for record alignment and key comparisons.
For example, `ClassKey` contains class-file keys and `Cls` contains class values.

The [Hepta tutorial](../tutorials/hepta.md) includes an alignment example.

## Select rows

Use the same row selection for data and keys.
After the keys agree with the data keys, apply the same row selection to names and classes.
Keep the input keys in the selected file.

## Column type codes

The type-code line in an LRN header describes columns.
A type code is different from a record key.
The `ZFileFormatDocuments` definitions give these meanings:

| Code | Meaning in software that uses the format |
| --- | --- |
| `9` | Integer key column. |
| `0` | Column for exclusion from a computation. |
| `1` | Numeric column for a computation. |
| `2` | Numeric column for training, with exclusion from best-match calculation. |
| `3` | Numeric column with class assignments, for exclusion from a computation. |
| `4` | Character column with best matching units on a rectangular grid. |
| `5` | Character column with points on a hexagonal grid or another projection. |
| `6` | Character column with names. |
| `8` | Character column with class assignments, for exclusion from a computation. |

DataBionicIO returns the type codes as metadata.
Its common LRN reader returns numeric data columns, including columns with code `0`.
It does not apply the training, projection, or classification meanings.
Character codes do not add text support to the LRN reader.
Use [NAMES](../formats/names.md) for text fields.

## Identifier systems

In the [Firebrowse tutorial](../tutorials/firebrowse.md), gene identifiers identify matrix columns.
Case identifiers identify matrix rows.
These are different identifier systems.
Do not connect these identifier systems through `Key`.
The same field name does not show that the identifiers refer to the same records.
