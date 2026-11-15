# DataBionicIO tests

## Source files and output

This folder contains test programs, CMake configuration, and fixed sample files.
The Python build uses `tests/Python` when `BUILD_PYTHON_TESTS` is on.
MATLAB tests are in `libs/matlabDataIO/tests/`.
Julia tests are in `libs/juliaDataIO/test/`.
Generated binaries, libraries, and test output are in `build/` or temporary folders.

Keep the test programs and fixed sample files with the corresponding source revision.

## Requirements

The R tests use R, Rcpp, lubridate, and a C++20 compiler for R.
The QS2 tests also use qs2.
If CMake and CTest are on `PATH`, the script also starts the direct C++ tests.
The R script does not use MATLAB.

## Documentation

The documentation script uses Python 3.9 or newer and its standard library.
It reads the public README files and Python API docstrings.
It reports missing local Markdown link targets, selected wording, semicolons in prose, and long sentences.
It excludes code blocks, inline code, and Python statements.
Its sentence classification and word counts are approximate.
The script does not establish ASD-STE100 conformity.

Start the documentation script from the project folder:

```sh
python3 tests/check_documentation.py
```

Supply file paths to examine other Markdown, plain text, or Python files.
CMake adds this script and its parser tests when it finds Python 3.9 or newer.
The R test group `documentation` examines R help topics and runs the DATES examples.

## R tests

Start the test script from the project folder:

```sh
Rscript --vanilla tests/run_tests.R
```

The script builds copies of the C++ and R sources in an isolated test library.
It also builds the `qslegacy` package.
It does not change the user library or download dependencies.
Each R test group starts in a new R process.

To use an existing test library, supply its path:

```sh
Rscript --vanilla tests/run_tests.R /path/to/test/library
```

This mode uses the installed packages in that library.
It does not build the current source files.

## Results

Each test run has its own folder in `build/tests/`.

| Item | Contents |
| --- | --- |
| `results.tsv` | PASS, FAIL, or SKIP for each group. |
| `logs/` | Build output and test output. |
| `environment.txt` | R version, platform, source path, and library path. |
| `source/` | Copies of the package sources for the build. |
| `library/` | Compiled packages for the tests. |

A group with a FAIL result gives exit status 1.
A build error in DataBionicIO stops the test run.
Exit status 0 means that no completed group has a FAIL result.
A skipped group has the result SKIP.

## Test groups

| Group | Checks |
| --- | --- |
| basics | LRN, CLS, NAMES, DATES, comments, format tags, input conversion, UTC, repeated local times, appended rows, syntax, and overwrite protection. |
| keys | Keys above 32 bits, limits at `+/-2^53`, generated keys, invalid keys, and duplicate keys. |
| headers | Header separators, names, R input vectors, and warnings for missing keys. |
| numbers | Precision, numeric notation, missing values, numeric prefixes, short rows, line endings, and class counts. |
| legacy | Nine MATLAB sample files, legacy text layouts, and format versions. |
| documentation | R help syntax, DATES examples, and NAMES result fields. |
| qs2 | Matrix lists, filename extensions, read operations, and overwrite protection. |
| qslegacy | Legacy QS encodings, matrix attributes, warnings, read operations, and conversion to QS2. |

The tests for `Append2LRN` use keys in its 32-bit key range.
The key tests for C++ readers and writers use the wider range of `[-2^53,2^53]`.

## Direct C++ tests

This build uses CMake and a C++20 compiler.
It does not link R, Python, or MATLAB.
Assertions stay active in Release builds.

1. Open a shell in the project folder.
2. Set the build options:

   ```sh
   cmake -S tests -B build/native-tests -DCMAKE_BUILD_TYPE=Release
   ```

3. Build the tests:

   ```sh
   cmake --build build/native-tests --config Release
   ```

4. Open the build folder:

   ```sh
   cd build/native-tests
   ```

5. Start CTest:

   ```sh
   ctest -C Release --output-on-failure
   ```

## Python tests

The Python build adds key tests and tests of public functions to CTest.
The `PyTests` target starts these tests against the build folder.
The optional R comparison uses all four formats from R to Python and from Python to R.
The [Python instructions](../libs/pyDataIO/README.md) give the build commands and test commands.

## MATLAB tests

The MATLAB test script is `libs/matlabDataIO/tests/runDataIOTests.m`.
It has different modes for the modern and legacy interfaces.
The R script gives SKIP for MATLAB and does not start the MEX module.
The [MATLAB instructions](../libs/matlabDataIO/README.md) give the build commands and test commands.

## Julia tests

The Julia build adds package tests to CTest.
The `JuliaTests` target starts these tests against the build folder.
The tests include all four formats, key limits, missing values, diagnostics, matrix dimensions, and legacy sample files.
The [Julia instructions](../libs/juliaDataIO/README.md) give the build commands and test commands.

## File exchange between languages

The MATLAB workflow starts tests of file exchange between R, Python, and MATLAB on Linux.
The scripts are in `tests/interop/`.
Each language writes LRN, CLS, NAMES, and DATES files through its public functions.
Each language then reads the files from all three languages.

The tests include keys at `-2^53` and `2^53`, array dimensions, numeric values, missing values, text, headers, comments, and UTC timestamps.
The text tests include Unicode characters.
The timestamp tests include milliseconds.
The tests compare values after conversion to each language's data types.

The R and Python scripts accept `generate`, `verify`, or `verify-r-python` as their first argument.
The other arguments specify the exchange folder and the R library or Python package folder.
The `verify` mode requires files from all three languages.
The `verify-r-python` mode reads only R and Python files.
Only the `verify` mode writes the report required for package creation.

The MATLAB function is `runDataIOInterop(Directory)`.
The function uses a built MATLAB package and files from the R and Python scripts.
The workflow supplies the exchange folder through `DATAIO_INTEROP_DIR`.

The Julia script is `tests/interop/interop.jl`.
Its `generate` mode writes Julia files with the same data as the R and Python scripts.
Its `verify` mode reads R, Python, and Julia files by default.
Additional command arguments select writer names.
The R and Python scripts have a `verify-julia` mode for Julia files.
This mode does not supply the MATLAB package report.

Start these commands after the R and Python scripts have written their files:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO tests/interop/interop.jl generate build/interop
julia --project=build/julia/libs/juliaDataIO/DataBionicIO tests/interop/interop.jl verify build/interop
python3 tests/interop/interop.py verify-julia build/interop build/python/libs/pyDataIO
Rscript --vanilla tests/interop/interop.R verify-julia build/interop /path/to/test/library
```

Supply the existing exchange folder, Python package folder, and R test library paths.
