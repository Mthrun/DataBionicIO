# Flow cytometry: select rows from a large matrix

## Task

Read the Dresden example from the software article.
Write its first 1,000 rows to a new LRN file.
Keep the input keys, column labels, and type codes.
Read that file again.
Compare its keys with the keys of the selected rows.

This row selection shows file operations.
It is not a random sample or an estimate of population frequencies.
The programs read the complete input matrix into memory.

## Get the input

To get the input, do these steps:

1. Open [Mendeley Data, version 5](https://data.mendeley.com/datasets/jk4dt6wprv/5).
2. Open the `DresdenData` directory in the file list.
3. Download `01SampleDresdenD10n440K.lrn`.
4. Keep that filename.

The portal lists a file size of 42,569,093 bytes.
Its [file page](https://data.mendeley.com/datasets/jk4dt6wprv/5/files/d9663a09-0394-4103-a6fe-434656753c09)
gives this SHA-256 digest:

```text
6ebbbb42f95a7712598655e96f79776bef682b8043d9a3724e792dd3d2238f7a
```

The complete 1.05 GB dataset archive is not necessary.
Refer to [source attribution](../reference/sources.md#flow-cytometry).

## R

Run the R example:

```sh
Rscript --vanilla examples/tutorials/flow_cytometry.R /path/to/01SampleDresdenD10n440K.lrn
```

The default output directory is `build/tutorials/flow-cytometry/r/`.
Download the {download}`R program <../../examples/tutorials/flow_cytometry.R>`.

```{literalinclude} ../../examples/tutorials/flow_cytometry.R
:language: r
:start-after: Example starts here
```

## Python

Run the Python example:

```sh
python examples/tutorials/flow_cytometry.py /path/to/01SampleDresdenD10n440K.lrn
```

The default output directory is `build/tutorials/flow-cytometry/python/`.
Download the {download}`Python program <../../examples/tutorials/flow_cytometry.py>`.

```{literalinclude} ../../examples/tutorials/flow_cytometry.py
:language: python
:start-after: Example starts here
```

## MATLAB

Run `setupDataIO('modern')` from the installed package directory.
Then, use the repository directory as the working directory.

Run the MATLAB example:

```matlab
addpath(fullfile(pwd, 'examples', 'tutorials'));
flow_cytometry('/path/to/01SampleDresdenD10n440K.lrn');
```

The default output directory is `build/tutorials/flow-cytometry/matlab/`.
Download the {download}`MATLAB program <../../examples/tutorials/flow_cytometry.m>`.

```{literalinclude} ../../examples/tutorials/flow_cytometry.m
:language: matlab
```

## Julia

Use the Julia project from your installation.
The command here uses the source build from the [installation guide](../guide/installation.md).

Run the Julia example:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO examples/tutorials/flow_cytometry.jl /path/to/01SampleDresdenD10n440K.lrn
```

The default output directory is `build/tutorials/flow-cytometry/julia/`.
Download the {download}`Julia program <../../examples/tutorials/flow_cytometry.jl>`.

```{literalinclude} ../../examples/tutorials/flow_cytometry.jl
:language: julia
:start-after: Example starts here
```

## Input and output arguments

The first argument is the path to `01SampleDresdenD10n440K.lrn`.
The optional second argument is the output directory.
R, Python, and Julia accept these arguments after the program filename.
MATLAB accepts them as function arguments.

For a subsequent run, supply a new output directory.
The writers do not replace output files in these examples.

## Expected result

```text
Flow cytometry example complete.
```

`Dresden_subset.lrn` contains 1,000 measurement rows and their input keys.
The file has 11 columns because it contains one key column and 10 measurement columns.
The package keeps missing measurements in the selected rows.
The program does not use the numeric rounding options.

The source file uses a legacy LRN header without a version tag.
The writer makes a format 2.0 file with the same selected measurements.

## Read the selected rows in R

After the Python example, read its output from R:

```r
library(DataBionicIO)
Result <- ReadLRN("Dresden_subset", InDirectory = "build/tutorials/flow-cytometry/python")
Data <- Result$Data
dim(Data)
```

This operation reads the exchanged LRN file.
The initial file format from the flow cytometer and its instrument software are not necessary.
