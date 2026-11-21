# Hydrology: calendar dates and missing measurements

## Task

Read a daily measurement series.
Write its calendar dates, keys, and measurements to a new DTS file.
Read the new file.
Compare its keys with the input keys.

The input has 351 dates and 14 measurement columns with numeric values.
Its file header counts 16 columns because it also contains `Key` and `Time`.
The series contains 196 missing numeric values.
Its dates are not a complete sequence of all days in 2013 and 2014.

## Input meaning

`HydrologyDaily2013_2014.dts` contains derived daily means from the article materials.
The preparation program kept the calendar dates.
The file declares UTC for representation.
This declaration does not identify the acquisition time zone of the source measurements.
Refer to [provenance](../reference/sources.md#hydrology).

## R

Run the R example:

```sh
Rscript --vanilla examples/tutorials/hydrology.R
```

The default output directory is `build/tutorials/hydrology/r/`.
Download the {download}`R program <../../examples/tutorials/hydrology.R>`.

```{literalinclude} ../../examples/tutorials/hydrology.R
:language: r
:start-after: Example starts here
```

## Python

Run the Python example:

```sh
python examples/tutorials/hydrology.py
```

The default output directory is `build/tutorials/hydrology/python/`.
Download the {download}`Python program <../../examples/tutorials/hydrology.py>`.

```{literalinclude} ../../examples/tutorials/hydrology.py
:language: python
:start-after: Example starts here
```

## MATLAB

Run `setupDataIO('modern')` from the installed package directory.
Then, use the repository directory as the working directory.

Run the MATLAB example:

```matlab
addpath(fullfile(pwd, 'examples', 'tutorials'));
hydrology();
```

The default output directory is `build/tutorials/hydrology/matlab/`.
Download the {download}`MATLAB program <../../examples/tutorials/hydrology.m>`.

```{literalinclude} ../../examples/tutorials/hydrology.m
:language: matlab
```

## Julia

Use the Julia project from your installation.
The command here uses the source build from the [installation guide](../guide/installation.md).

Run the Julia example:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO examples/tutorials/hydrology.jl
```

The default output directory is `build/tutorials/hydrology/julia/`.
Download the {download}`Julia program <../../examples/tutorials/hydrology.jl>`.

```{literalinclude} ../../examples/tutorials/hydrology.jl
:language: julia
:start-after: Example starts here
```

## Time representation

The R and Python readers return native timestamp values.
The MATLAB and Julia readers return date text.
The writer receives the time values from the reader and `Format=1`.
It thus keeps date-only resolution.

For data with repeated local times, also keep the DST markers.
Refer to [DTS time zones](../formats/dts.md#time-zones).
The calendar-date file in this tutorial has no DST column.

## Input and output arguments

The optional first argument is the input directory.
Its default is `examples/tutorials/data/`.
The optional second argument is the output directory.
R, Python, and Julia accept these arguments after the program filename.
MATLAB accepts them as function arguments.

For a subsequent run, supply a new output directory.
The writers do not replace output files in these examples.

## Expected result

```text
Hydrology example complete.
```

`Hydrology_copy.dts` keeps the dates, keys, measurements, missing values, labels, comments, and time zone metadata.
The program compares the input and output keys.
The program does not replace missing measurements with zero.

(inspect-the-file-in-excel)=
## Examine the file in Excel

Open the output as tab-separated text.
Before conversion, select the text format for keys and dates.
This setting keeps the input text.
Refer to [Excel instructions](../guide/excel.md).
Keep the workbook and the DTS file as different files.
