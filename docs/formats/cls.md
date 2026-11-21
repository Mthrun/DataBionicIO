# CLS: class assignments

A CLS file connects each key to one integer class value.
One header line gives the number of data rows.
Each data row contains a key and a class value.

```text
#<?cls version="2.0"?>
# Two classes
% 2
101	7
205	8
```

## Header and data fields

| Element | Meaning |
| --- | --- |
| `% n` | Number of data rows. |
| First data field | Integer key for the row. |
| Second data field | Integer class value or `NaN`. |

Each data row has two fields with a tab between them.
In R, `WriteCLS` accepts a vector, a one-column matrix, or a one-column data frame.
It also accepts two columns with keys first and classes second.
A separate `Key` argument has priority over that first column.

## Class values

Class values use the range `[-2147483648, 2147483647]`.
This range is different from the [key range](../guide/keys.md).
Class values that are fractions, infinite values, or values that are not in this range become missing values.
The writer gives a warning.
The writer does not round classes to integers.
`Int4NaN` can replace missing classes with an integer marker in the permitted class range.

## Reader result

`ReadCLS` returns `Key`, `Cls`, `UniqueClasses`, and `Comments`.
`UniqueClasses` contains the sorted class values.
Each class occurs one time, and no missing values occur.
The writer argument for user text is `Comment`.
The reader result uses the plural name `Comments`.

## Statistics and legacy metadata

The writer adds class counts and percentages as comment lines.
The reader does not include that generated section in the user comments.

```text
#	Class	N	Percent
#	7	1	50
#	8	1	50
```

| Field | Meaning |
| --- | --- |
| `Class` | Integer class value. |
| `N` | Number of records with that class. |
| `Percent` | Percentage of records with that class. |

The `Class` line identifies the start of the generated statistics.
Legacy files can also contain class names and colors after the row-count header:

```text
% class	name	red	green	blue
```

The three color fields give the red, green, and blue components.
The reader ignores legacy class-name and color metadata.
The writer does not write class names or colors.
If class descriptions are necessary, store them in a different file.

Legacy CLS files can use spaces between numeric fields.
The row-count header is optional in legacy files.

Refer to [Hepta](../tutorials/hepta.md) for alignment with measurements.
Refer to [Firebrowse](../tutorials/firebrowse.md) for a class-to-description lookup.
