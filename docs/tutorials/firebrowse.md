# Firebrowse: identifiers and annotations

## Task

Read the gene identifiers in their input order.
Write a NAMES copy with the primary column label from the input.
Connect case classes to diagnosis descriptions.

The source dataset contains 19,637 gene columns and 10,446 cases.
This example uses its four small annotation files.
The 1.4 GB expression matrix is not necessary for this example.
Refer to [data sources](../reference/sources.md#firebrowse).

## Key meanings

| File | Meaning of `Key` | Meaning of the next field |
| --- | --- | --- |
| `13ColumnNCBIs_Firebrowse_N19637.names` | NCBI gene identifier. | Expression-matrix column name. |
| `14Genexpression_Firebrowse_Cls_N10446.cls` | Case identifier. | Diagnosis class. |
| `15Genexpression_Cls2Diagnosis_N33.names` | Diagnosis class. | Diagnosis description. |
| `16Genexpression_Cases_N10446.names` | Case identifier. | Case name. |

The first six gene keys are `1, 2, 9, 10, 12, 13`.
Their names are `C1` thru `C6`.
The gaps in gene keys are permitted.
Gene keys and case keys have different meanings.

## R

Run the R example:

```sh
Rscript --vanilla examples/tutorials/firebrowse.R
```

The default output directory is `build/tutorials/firebrowse/r/`.
Download the {download}`R program <../../examples/tutorials/firebrowse.R>`.

```{literalinclude} ../../examples/tutorials/firebrowse.R
:language: r
:start-after: Example starts here
```

## Python

Run the Python example:

```sh
python examples/tutorials/firebrowse.py
```

The default output directory is `build/tutorials/firebrowse/python/`.
Download the {download}`Python program <../../examples/tutorials/firebrowse.py>`.

```{literalinclude} ../../examples/tutorials/firebrowse.py
:language: python
:start-after: Example starts here
```

## MATLAB

Run `setupDataIO('modern')` from the installed package directory.
Then, use the repository directory as the working directory.

Run the MATLAB example:

```matlab
addpath(fullfile(pwd, 'examples', 'tutorials'));
Summary = firebrowse();
```

The default output directory is `build/tutorials/firebrowse/matlab/`.
Download the {download}`MATLAB program <../../examples/tutorials/firebrowse.m>`.

```{literalinclude} ../../examples/tutorials/firebrowse.m
:language: matlab
```

## Julia

Use the Julia project from your installation.
The command here uses the source build from the [installation guide](../guide/installation.md).

Run the Julia example:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO examples/tutorials/firebrowse.jl
```

The default output directory is `build/tutorials/firebrowse/julia/`.
Download the {download}`Julia program <../../examples/tutorials/firebrowse.jl>`.

```{literalinclude} ../../examples/tutorials/firebrowse.jl
:language: julia
:start-after: Example starts here
```

## Keep the header

The primary label in the gene file is `Column_Name`.
`ReadNAMES` returns primary names independently from `FurtherTexts`.
Its `Header` field contains labels only for `FurtherTexts`.
The writer thus receives `Key` and `Column_Name` in the full header.

## Input and output arguments

The optional first argument is the input directory.
Its default is `examples/tutorials/data/`.
The optional second argument is the output directory.
R, Python, and Julia accept these arguments after the program filename.
MATLAB accepts them as function arguments.

For a subsequent run, supply a new output directory.
The DataBionicIO writer does not replace its NAMES output.

## Expected result

`Firebrowse_copy.names` keeps the gene records and primary label.
Each program ends with the `Summary` object.
It contains the class value, diagnosis description, and number of cases for each class.
R and MATLAB use table columns named `Class`, `Diagnosis`, and `Cases`.
Python and Julia use tuples with these three fields in the same order.

`TheSameKey` first compares `ClassKey` with `CaseKey`.
If the keys agree, the program keeps the input order.
Otherwise, it puts `Cls` and `ClassKey` in the order of `CaseKey`.
It keeps `CaseNames` in the case-file order.
R uses `match`, MATLAB uses `ismember`, and Python and Julia use dictionaries.

The program uses class values to find diagnosis descriptions.
It compares these values with `DiagnosisKey` before it changes the diagnosis order.
It does not use case keys for this lookup.

These counts give information about the input annotations.
They give no prediction results or new classification results.
