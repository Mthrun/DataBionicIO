# Troubleshooting

## The package cannot load

Make sure that the installed package is compatible with your operating system and processor.
For Python, also compare its wheel tag with your CPython version.
For Julia, use the project and CxxWrap version of the selected build.
For MATLAB, use `setupDataIO('modern')` from the package directory.

## An incorrect file opens

Supply `InDirectory`.
Use `OutDirectory` for a different output directory.
The default directory is the working directory at the time of the call.
This directory can be different from the directory that contains your script.

## A writer gives an invalid-key error

Make sure that the keys are integers in `[-2^53, 2^53]`.
Make sure that each key occurs only one time.
Select keys and data rows together.
Refer to [keys and record alignment](keys.md).

## A NAMES header changes

The common reader returns labels for `FurtherTexts` in `Header`.
It does not return the primary names label from the input file in that field.
To keep that label, supply a full header.
The [Firebrowse tutorial](../tutorials/firebrowse.md) keeps `Column_Name`.

## A reader gives a warning

The reader can continue after a warning.
A short row can receive missing values.
Fields after the declared column count do not add columns.
The number of returned rows can be different from the declared row count.
Compare dimensions and keys before subsequent analysis.

`Verbose=False` removes progress messages.
The reader can continue to give warnings.
A returned object does not show that the source file is correct.

## Dates have an incorrect meaning

Calendar dates and instants with a time zone are different concepts.
When the reader returns local timestamp text, keep `Time`, `Timezone`, and `DST` together.
Refer to [DTS](../formats/dts.md) for repeated hours and time zone restrictions.

## Numeric values change after a write operation

For the default numeric precision, do not supply `SignificantDigits` or `DecimalDigits`.
These arguments select rounding in `WriteLRN`.
Excel numeric conversion can also change the last digits.
Compare missing-value positions independently from finite values.
File bytes can be different because writers add a new generation timestamp.
