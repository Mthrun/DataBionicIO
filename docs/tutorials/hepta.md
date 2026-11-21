# Hepta: connect three files by key

## Task

Connect numeric measurements with classes and names.
Write the connected records to three new files.
Compare the keys of the new files with the input keys.

Hepta contains 212 observations and three numeric measurements.
Class 1 has 32 observations.
Each of the other six classes has 30 observations.
The study preparation program supplied the example names.
Refer to the [source description](../reference/sources.md#hepta).

## Inputs and output

The input files are `hepta.lrn`, `hepta.cls`, and `hepta.names`.
They are in `examples/tutorials/data/`.
The output files use the name `hepta_copy`.
Each language writes to a different output directory.

## R

Run the R example:

```sh
Rscript --vanilla examples/tutorials/hepta.R
```

The default output directory is `build/tutorials/hepta/r/`.
Download the {download}`R program <../../examples/tutorials/hepta.R>`.

```{literalinclude} ../../examples/tutorials/hepta.R
:language: r
:start-after: Example starts here
```

## Python

Run the Python example:

```sh
python examples/tutorials/hepta.py
```

The default output directory is `build/tutorials/hepta/python/`.
Download the {download}`Python program <../../examples/tutorials/hepta.py>`.

```{literalinclude} ../../examples/tutorials/hepta.py
:language: python
:start-after: Example starts here
```

## MATLAB

Run `setupDataIO('modern')` from the installed package directory.
Then, use the repository directory as the working directory.

Run the MATLAB example:

```matlab
addpath(fullfile(pwd, 'examples', 'tutorials'));
hepta();
```

The default output directory is `build/tutorials/hepta/matlab/`.
Download the {download}`MATLAB program <../../examples/tutorials/hepta.m>`.

```{literalinclude} ../../examples/tutorials/hepta.m
:language: matlab
```

## Julia

Use the Julia project from your installation.
The command here uses the source build from the [installation guide](../guide/installation.md).

Run the Julia example:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO examples/tutorials/hepta.jl
```

The default output directory is `build/tutorials/hepta/julia/`.
Download the {download}`Julia program <../../examples/tutorials/hepta.jl>`.

```{literalinclude} ../../examples/tutorials/hepta.jl
:language: julia
:start-after: Example starts here
```

## Record alignment

Each example first compares the measurement keys with each companion key vector.
If `TheSameKey` returns `true`, the program keeps the input order.
Otherwise, it puts the companion data and its keys in the measurement-key order.
R uses `match`, MATLAB uses `ismember`, and Python and Julia use dictionaries.
After a change of order, the program compares the keys again with `TheSameKey`.
The result is the same for different input row orders in the class and name files.

`TheSameKey` does not change the record order.

## Input and output arguments

The optional first argument is the input directory.
Its default is `examples/tutorials/data/`.
The optional second argument is the output directory.
R, Python, and Julia accept these arguments after the program filename.
MATLAB accepts them as function arguments.

For a subsequent run, supply a new output directory.
The writers do not replace output files in these examples.

## Expected result

Each program prints the counts and this result:

```text
Hepta example complete.
```

The count for class 1 is 32.
The count for each of classes 2 thru 7 is 30.
The language controls the display format of the counts.

The program compares the keys after it reads the three output files.
The package reads and writes the measurements, classes, names, labels, column types, and comments.
File bytes can be different because writers add generation metadata.

## Use the same files in a different language

Read `hepta_copy.lrn` with the other language's `ReadLRN` function.
Read its CLS and NAMES companion files with their applicable readers.
Use the [common output fields](../reference/api.md#output-order) to find the data and keys.
Compare the keys before you connect the returned objects.
