# Write and read a small file

This example makes two observations with keys 101 and 205.
Each observation has two measurements.
The second observation has one missing measurement.

Run one program after [installation](installation.md).
Each program uses a different temporary directory.
No external dataset is necessary.

## R

```{literalinclude} ../../examples/tutorials/quickstart.R
:language: r
:start-after: Example starts here
```

## Python

```{literalinclude} ../../examples/tutorials/quickstart.py
:language: python
:start-after: Example starts here
```

## MATLAB

First, run `setupDataIO('modern')` from the installed package directory.

```{literalinclude} ../../examples/tutorials/quickstart.m
:language: matlab
:start-after: Example starts here
```

## Julia

```{literalinclude} ../../examples/tutorials/quickstart.jl
:language: julia
:start-after: Example starts here
```

## Result

Each program prints `Quick start complete.`
`TheSameKey` compares the input and output keys.
The package reads and writes the measurements and labels.
The file contains a key column and two measurement columns.

The default writer settings let the writer replace an output file.
These examples set `Overwrite` to false.
Refer to the [common interface](../reference/api.md) for the full argument order.
