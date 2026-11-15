# Legacy reader tests

The `samples/` folder contains nine files from the previous MATLAB DataIO archive.
The sample files keep their initial contents and relative paths.

The tests read LRN, CLS, and NAMES files.
They compare the data values with the expected values.
They also examine missing fields, other fields, large keys, and LF and CRLF line endings.
The format tests distinguish legacy layouts from format 2.0.
The CLS reader does not use color metadata.

## R tests

Start the test script from the project folder with the path to an isolated R test library:

```sh
Rscript --vanilla tests/legacy/test_readers.R /path/to/test/library
```

The direct C++ test uses `test_readers.cpp`.
The [test instructions](../README.md) give the C++ build commands.
