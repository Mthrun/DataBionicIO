# DataBionicIO for Python

The project uses GNU AGPL version 3 only, with a MATLAB linking exception.
The wheel includes the license texts and the pybind11 license notice.

`DataBionicIO` reads and writes LRN, CLS, NAMES, and DATES files.
Its functions use the same C++ code as the R package `DataBionicIO`.
The writers use format 2.0.
The readers also accept specified legacy layouts for LRN, CLS, and NAMES.

## Requirements

The package uses Python 3.9 or newer.
The runtime dependencies are NumPy 1.21 or newer, Pandas 1.5 or newer, and tzdata.
The build also uses setuptools, wheel, pybind11, CMake 3.15 or newer, and a C++20 compiler.

## Build

1. Open a shell in the project folder.
2. Install the Python dependencies:

   ```sh
   python -m pip install "numpy>=1.21" "pandas>=1.5" tzdata setuptools wheel pybind11
   ```

3. Set the build options:

   ```sh
   cmake -S . -B build/python -DBUILD_RPACKAGE=OFF \
     -DPython_EXECUTABLE="$(python -c 'import sys; print(sys.executable)')" \
     -Dpybind11_DIR="$(python -m pybind11 --cmakedir)" \
     -DCMAKE_BUILD_TYPE=Release
   ```

4. Build the wheel:

   ```sh
   cmake --build build/python --config Release --target PyPackageBuild
   ```

The wheel output folder is `build/python/libs/pyDataIO/dist/`.
The build uses the selected Python interpreter for compilation and package creation.
The build includes the compiled module. It does not download the runtime dependencies.
The wheel filename identifies the Python version and platform.

## Tests

Start the Python tests from the project folder:

```sh
cmake --build build/python --config Release --target PyTests
```

The target includes key tests and tests of the public Python functions.
The tests use the build folder without package installation.
The tests do not download dependencies.

The optional R comparison reads and writes all four formats from R to Python and from Python to R.
It also compares nine pairs of output files.
The comparison uses the Python build and an isolated R test library.

Start the comparison with the paths to the two builds:

```sh
python tests/Python/test_interop.py build/python/libs/pyDataIO /path/to/R/test/library
```

The CMake option `DATAIO_R_TEST_LIBRARY` adds this comparison to `PyTests`.

## Install

To install a wheel, use its full filename:

```sh
python -m pip install /path/to/wheel.whl
```

To install from the build folder, use the CMake target:

```sh
cmake --build build/python --config Release --target PyPackageInstall
```

`PyPackageInstall` installs the package into the selected Python environment.
It does not install dependencies.

## GitHub Actions packages

The source workflow is `.github/workflows/python.yml`.
It selects CPython 3.11, 3.12, 3.13, 3.14, and 3.15 for each configuration:

| Build system | Processor | Wheel platform |
| --- | --- | --- |
| manylinux container | x86-64 | Linux with glibc 2.28 or newer. |
| Windows Server 2022 | x86-64 | Windows, 64-bit. |
| macOS 15 | ARM64 | macOS, Apple Silicon. |
| macOS 15 | x86-64 | macOS, Intel. |

The macOS builds use deployment target 13.0.
Python and its dependencies can have their own operating system requirements.
Each job installs its wheel in an isolated Python environment.
It tests keys, public functions, and `TheSameKey` through that installation.
The job keeps the wheel only after these tests pass.
Each wheel has a SHA-256 checksum and a JSON build record.

To start the workflow, select **Actions > Python wheels > Run workflow** in GitHub.
Open the completed run.
Select an artifact with a name that ends in `-package`.
Extract the artifact ZIP.
Install the wheel with the command in the Install section.

Select a wheel for your CPython version, operating system, and processor.
These wheels use standard CPython builds with the global interpreter lock.
The workflow keeps packages and reports for 30 days.

## macOS build options

The wheel platform tag identifies the compiled architectures.
CMake uses one minimum macOS version for the C++ code, the Python module, and the wheel tag.
The default value is the major version number of the build system.
`CMAKE_OSX_DEPLOYMENT_TARGET` selects a different minimum version.

## Example

```python
import DataBionicIO as io

io.WriteLRN("measurements", [[1.5, 2.0], [3.5, 4.0]],
            Header=["A", "B"], Key=[10, 20], OutDirectory="/path/to/data")
data = io.ReadLRN("measurements", InDirectory="/path/to/data")
frame = io.read_lrn("measurements", Directory="/path/to/data")
```

## Key vectors

`TheSameKey(KeyA, KeyB)` compares numeric vectors in row order through the shared C++ code.
The result is `true` only if the lengths and the values at each position are the same.
Two empty vectors give `true`.
Missing values and unsupported inputs give `false`.
The function does not sort the vectors or change their contents.
It does not test the key constraints of the file formats.

The name `the_same_key` gives the same function.
Numeric values must convert to binary64 without loss.

## Common interface

The common readers are `ReadLRN`, `ReadCLS`, `ReadNAMES`, and `ReadDates`.
The writers are `WriteLRN`, `WriteCLS`, `WriteNAMES`, and `WriteDates`.
Readers take `FileName`, `InDirectory`, and `Verbose`, in this order.
Their dictionaries contain the fixed fields below, in this order.

| Reader | Fields |
| --- | --- |
| `ReadLRN` | `Key`, `Data`, `Header`, `DataDefined`, `Comments` |
| `ReadCLS` | `Key`, `Cls`, `UniqueClasses`, `Comments` |
| `ReadNAMES` | `Key`, `Names`, `FurtherTexts`, `Header`, `Comments` |
| `ReadDates` | `Key`, `Time`, `Data`, `Header`, `Comments`, `Timezone`, `DST` |

`WriteCLS` takes `FileName`, `Cls`, `OutDirectory`, `Key`, `Comment`, `Int4NaN`, `Overwrite`, and `Verbose`.
The other writers keep the argument order shown by their Python help text.

## Additional Python functions

| Format | Dictionary reader | Writer | DataFrame reader |
| --- | --- | --- | --- |
| LRN | `ReadLRN` | `WriteLRN` | `read_lrn` |
| CLS | `ReadCls`, `ReadCLS` | `WriteCls`, `WriteCLS` | `read_cls` |
| NAMES | `ReadNames`, `ReadNAMES` | `WriteNames`, `WriteNAMES` | `read_names` |
| DATES | `ReadDates` | `WriteDates` | `read_dates` |

The default directory is the working directory at the time of the function call.
Paths can be strings or `pathlib.Path` objects.
The common interface has `Overwrite=True` and `Verbose=True` as defaults.
The compatibility import `pyDataIO` also uses these defaults.
The writer examines the input before it opens the output file.

To keep an existing file, set `Overwrite=False`.

## Inputs

| Format | Input |
| --- | --- |
| LRN | A numeric vector, NumPy array, table, dictionary of columns, or DataFrame. A vector supplies one data column. |
| CLS | A vector, one class column, or two columns for keys and classes. |
| NAMES | A vector of names and an optional table of other text. Each row contains one record. A dictionary supplies columns. |
| DATES | A DataFrame, dictionary, NumPy array, time vector, or list of columns. |

For DATES, a `Time` column supplies the time values.
Without this name, the first column after the key column supplies the time values.
NumPy arrays contain one record in each row, with time first.
A nested Python list uses `[times, data_column_1, data_column_2, ...]`.

For LRN, CLS, and DATES, a `Key` column can supply the keys.
An explicit `Key` argument overrides this column.
The writer removes the key column from its data copy.
It does not change the input object.

## Keys

Keys must be unique, finite whole numbers in `[-2**53, 2**53]`.
Writers accept Python integers and numeric arrays with whole numbers.
Writers reject missing keys, fractions, duplicate keys, and values not in this range.
Without a key argument, the C++ writer supplies keys and gives a warning.

Missing keys in a file become `None` in a dictionary result.
A DataFrame uses nullable `Int64` values to keep keys without precision loss.

Do not convert larger identifiers to floating point before the writer examines them.

## Headers and missing values

The number of header labels must agree with the number of columns.
An LRN or NAMES header can include the key column.
The writer changes a custom key label to `Key`.
A short LRN header causes an error.

DataFrame column labels that are not strings become `C1`, `C2`, and subsequent numbered labels.
An explicit `Header` argument must contain strings.

Missing numeric values use `NaN`.
The writers also accept `None` and Pandas missing values in numeric input.
Missing text uses `NA` in the file and `None` in the result.
Text cells cannot contain tabs, line breaks, or NUL characters.
The writers keep spaces, commas, and semicolons in text cells.

## Results

The compatibility import `pyDataIO` returns the additional fields described in this section.
Its dictionary results contain `Key`, `Comments`, and the alias `Comment`.
LRN results contain `DataDefined` and the alias `Types`.

For NAMES, `FurtherTexts` contains one record in each row.
`Header` identifies the other text columns.
`FileHeader` contains all column labels.

For DATES, `Data` contains the numeric rows.
`Header` identifies the numeric columns. `FileHeader` contains all column labels.
`Time` contains date values or datetime values with a time zone.
`Times` contains the timestamp strings from the file.
`DST` and `Timezone` contain the time metadata.

DataFrame readers keep the column names.
LRN type codes are in `frame.attrs['DataDefined']`.
Comments and time metadata are in `frame.attrs`.

To keep this metadata in a new file, supply it to the writer as explicit arguments.

## Time values

DATES accepts ISO dates, timestamps, Python date and datetime values, NumPy datetime values, and Pandas timestamps.
The writer changes slashes in dates to hyphens.
A timestamp with a UTC offset keeps the same instant.
The `tz` argument accepts an IANA time zone name, such as `Europe/Berlin`.

Without `tz`, the writer uses the named time zone of the input or UTC.
For input with a fixed offset and no named time zone, the default is UTC.

| Format value | Output |
| --- | --- |
| `1` | Dates. |
| `2` | Timestamps with seconds. |
| `3` | Timestamps with milliseconds. |
| `-1` | The greatest precision in the input. |

The writer rounds fractions of milliseconds in UTC.
The writer also calculates changes to the next second or day.
Date values without a time stay as dates.

DST abbreviations identify repeated local times when daylight saving time ends.
A `DST` column or an abbreviation after the timestamp supplies this information.
On input, inconsistent DST metadata causes a warning and a `None` result for the affected time.
The reader keeps the row.

A local timestamp without a DST marker selects the second occurrence of an ambiguous time.
The writer rejects nonexistent local times.
The C++ parser does not accept numeric DST abbreviations, such as `+11`.

For these time zones, set `tz='UTC'`.

## Incremental LRN reader

`LRN_reader` reads a file one line at a time.
It accepts LF and CRLF line endings.
It uses the compatibility result conversion.
The `has_nan` attribute identifies missing values.
`get_lrn(True)` returns the same DataFrame structure as `read_lrn`.
