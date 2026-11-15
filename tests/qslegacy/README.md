# Legacy QS tests

These tests use the `qslegacy` package.
The current QS2 tests are in `tests/R/test_qs2.R`.

## Sample files

The two QS sample files contain the same synthetic list of matrices.
The qs 0.27.3 package wrote these files.
One file uses Zstandard. The other file uses LZ4HC.
The two files use shuffle mask 14 and a checksum.

The file `expected.rds` contains the expected data in R serialization version 2.
The initial generation procedure wrote this file independently of the new reader.

The matrices include numeric, integer, logical, character, complex, raw, and list storage.
The data also include dimensions, names, missing values, and empty dimensions.
The tests do not use the previous qs package.

## Tests

Start the test script from the project folder with the path to an isolated R test library:

```sh
Rscript --vanilla tests/qslegacy/test_reading.R /path/to/test/library
```

## SHA-256 checksums

```text
matrices-zstd.qs 45a36b2a24e4b623ae3b7e5e0e04b190c31171c4648bdcd7c576606aa5f1d2a6
matrices-lz4.qs  13e74f13172e3dd90d94c99091edf46e9a9de81621613298311a85f3b00c2288
expected.rds    9d20968c151dfdf0648c07e0933799a42475e0477174687d7d5e708f43ec7549
```
