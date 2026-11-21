# DataBionicIO: C++ File I/O for R, Python, MATLAB, and Julia

Version: 1.0.2.

DataBionicIO contains readers and writers for data files.
The R, Python, MATLAB, and Julia interfaces use the same C++ code for LRN, CLS, NAMES, and DATES.
The R and MATLAB packages also contain functions for other formats.
Excel can open the text files with tab separators.

The package name is `DataBionicIO` in all four languages.
The [common interface](API.md) defines the function names, argument order, and output fields.
The MATLAB build and setup functions are `buildDataIO` and `setupDataIO`.

## Key vectors

`TheSameKey(KeyA, KeyB)` compares numeric vectors in row order through the shared C++ code.
The result is `true` only if the lengths and the values at each position are the same.
Two empty vectors give `true`.
Missing values and unsupported inputs give `false`.
The function does not sort the vectors or change their contents.
It does not test the key constraints of the file formats.

Python and Julia also provide the name `the_same_key`.
The MATLAB function uses the modern MEX interface.

## License

DataBionicIO uses GNU AGPL version 3 only, with a MATLAB linking exception.
The [license notice](LICENSING.md) gives the scope and the license texts.
Commercial use is permitted under these terms.
IAP-GmbH Intelligent Analytics Projects also offers [alternative commercial licenses](COMMERCIAL-LICENSE.txt).
Third-party components keep their own licenses.

## Folders

| Folder | Contents |
| --- | --- |
| `libs/cDataIO/` | C++ source files and headers. |
| `libs/RDataIO/` | R functions, Rcpp interfaces, and help files. |
| `libs/pyDataIO/` | Python functions and the interface to C++. |
| `libs/matlabDataIO/` | MATLAB functions, the MEX interface, and MATLAB tests. |
| `libs/juliaDataIO/` | Julia functions, the CxxWrap interface, and Julia tests. |
| `libs/qslegacy/` | An R package for legacy QS files. |
| `cmake/` | CMake support files. |
| `ci/matlab/` | The MATLAB build and test command for GitHub Actions. |
| `.github/workflows/` | GitHub Actions workflows for Python, MATLAB, Julia, and file-exchange tests. |
| `tests/` | Test programs and fixed sample files. |
| `examples/` | Examples of package use. |
| `build/` | Build output. |

Source files are in `libs/`. Build commands can replace files in `build/`.
Test programs and fixed sample files are part of the project source.
Generated test output is in `build/` or a temporary folder.

Keep the test programs and fixed sample files with the corresponding source revision.

## Tests

The [test instructions](tests/README.md) give the R, C++, Python, MATLAB, and Julia test procedures.
The R test script builds package copies in an isolated test library.

Start the R test script from the project folder:

```sh
Rscript --vanilla tests/run_tests.R
```

The [Julia workflow](.github/workflows/julia.yml) builds and tests the package on Linux, Windows, and macOS.
It uses Julia 1.10 and the latest stable Julia 1 release.
Its Linux job also tests file exchange between Julia, R, and Python.
The workflow tests extracted Julia binary packages before it makes them available as download artifacts.

The [Python workflow](.github/workflows/python.yml) builds wheels for CPython 3.11 through 3.15.
It tests installed wheels on Linux, Windows, and macOS.
Both workflows include macOS configurations for Intel and Apple Silicon processors.

## C++ build

The C++ build uses a C++20 compiler and CMake 3.15 or newer.

Use these commands from the project folder:

```sh
cmake -S . -B build/core -DBUILD_RPACKAGE=OFF -DBUILD_PYPACKAGE=OFF
cmake --build build/core --config Release
```

## R package

The R package is `DataBionicIO`. Its `DESCRIPTION` file gives the R package dependencies.
The CMake build uses R, Rcpp, a C++20 compiler, and a Bash shell.

Use these commands from the project folder:

```sh
cmake -S . -B build/r -DBUILD_PYPACKAGE=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build/r --config Release --target RPackageInstall
```

`RPackageInstall` also builds and installs the `qslegacy` package.
The build output is in `build/r/libs/RDataIO/`.

The script `build_RDataIO.R` gives an alternative build procedure.
It uses `devtools`, `Rcpp`, and `this.path`.
An optional `.pfad` value sets the archive output folder.
Without this value, the script writes archives above the project folder.
The script writes one archive for `DataBionicIO` and one for `qslegacy`.

## Python package

The Python package is `DataBionicIO`.
The [Python instructions](libs/pyDataIO/README.md) give the requirements, build commands, and function interfaces.
The example `examples/python/example.py` shows package use.

## MATLAB package

The MATLAB package uses a MEX module for LRN, CLS, NAMES, and DATES.
The build script uses 64-bit MATLAB R2022a or newer and a C++20 compiler.
The [MATLAB instructions](libs/matlabDataIO/README.md) give the build commands and function interfaces.

## Julia package

The Julia package is `DataBionicIO`.
The build uses Julia 1.10 or newer, CxxWrap 0.17, CMake, and a C++20 compiler.
The [Julia instructions](libs/juliaDataIO/README.md) give the local build commands and function interfaces.

Start the build from the project folder:

```sh
julia --startup-file=no libs/juliaDataIO/build.jl
```

The output package is in `build/julia/libs/juliaDataIO/DataBionicIO/`.

Start Julia with this package:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO
```

The common readers are `ReadLRN`, `ReadCLS`, `ReadNAMES`, and `ReadDates`.
The writers are `WriteLRN`, `WriteCLS`, `WriteNAMES`, and `WriteDates`.

## Excel

Excel can open LRN, CLS, NAMES, DATES, and DATA text files with tab separators.
If Excel is the default application for the file type, a double-click opens the file in Excel.
Otherwise, open the file with Excel.

If the lines appear in one column, select that column.
Use **Data > Text to Columns**.
Select **Delimited**.
Select **Tab** as the separator.
The [Excel instructions](examples/excel/README.md) give the complete procedure and the settings for identifiers and timestamps.

## Keys

The C++ code uses signed 64-bit integers for keys.
The permitted range is `[-2^53, 2^53]`.
R and MATLAB double values can store each integer in this range without loss.

R readers return numeric vectors for keys.
R writers accept numeric or integer vectors with unique whole numbers.
R writers do not accept `bit64::integer64` vectors.
Python and Julia use the same permitted range.

An invalid key causes a reader warning. The reader keeps the row.
C++ uses `MISSING_KEY` for an invalid key. R returns `NA` for an invalid key.
Writers reject invalid keys before they open the output file.

Do not convert a larger identifier to a double value before a write operation.
This conversion can change the identifier before the writer can examine it.

## Text formats

The LRN, CLS, and NAMES readers accept format 2.0 and specified legacy layouts.
Files without a version tag and files with a version 1.0 tag use the legacy layout rules.
Files with a version 2.0 tag use the current header rules.
A read error does not cause a second read with the legacy rules.
The readers reject other versions.

The legacy layout rules are in `libs/cDataIO/src/legacy_readers.cpp`:

- LRN accepts a different key name or key position. Type 9 identifies the key column.
- LRN without a key column causes a warning. The reader supplies keys from 1 to the row count.
- CLS accepts spaces between numeric fields. CLS also accepts files without a header for the row count.
- NAMES accepts files without a column count or column names. The first data row then sets the number of columns.

The LRN, CLS, and NAMES writers use format 2.0.
The CLS reader does not use color metadata.

## QS files

The `qslegacy` package reads legacy QS files that contain lists of matrices.
It does not write files. Its [package instructions](libs/qslegacy/README.txt) give its interface and license.

`ReadQS2` and `WriteQS2` use the QS2 format.
`ConvertQSToQS2` converts a legacy QS file to QS2.
A read operation does not convert or save the source file.
