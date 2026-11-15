# DataBionicIO for Julia

This package reads and writes LRN, CLS, NAMES, and DATES files through the shared C++ code.
The Julia package name is `DataBionicIO`.

## Requirements

The build uses Julia 1.10 or newer, CxxWrap 0.17, CMake 3.15 or newer, and a C++20 compiler.
Julia and the compiler must use the same processor architecture.
The build script downloads Julia dependencies when necessary.

The default CxxWrap binaries for Windows use GCC.
Use a compatible GCC toolchain for these binaries.
These binaries cannot link to MSVC code.

## Local build

Start this command from the project folder:

```sh
julia --startup-file=no libs/juliaDataIO/build.jl
```

The output package is in `build/julia/libs/juliaDataIO/DataBionicIO/`.
The script uses the existing C++ source files.
The package contains a native library for the build platform.
The package uses CxxWrap from the Julia depot.

The script accepts a different build directory and CMake executable:

```sh
julia libs/juliaDataIO/build.jl build/julia-local /path/to/cmake
```

Use a build directory below the project `build/` folder.
Use the same Julia version and depot for the build and package use.
After a Julia or CxxWrap update, build the package again.

## Tests

Start the package tests:

```sh
cmake --build build/julia --config Release --target JuliaTests
```

The tests use the package in the build folder.
They examine all four formats, key limits, missing values, warnings, errors, and legacy files.
Test output files use temporary folders.

## GitHub Actions

The source workflow is `.github/workflows/julia.yml`.
It has these configurations:

| Operating system | Processor | Julia versions | Compiler |
| --- | --- | --- | --- |
| Ubuntu 24.04 | x86-64 | 1.10 and latest stable 1.x | GCC. |
| Windows Server 2022 | x86-64 | 1.10 and latest stable 1.x | MinGW-w64 GCC. |
| macOS 15 | ARM64 | 1.10 and latest stable 1.x | Apple Clang. |

Each configuration builds the native library and starts the package tests and examples.
The Linux configuration with the latest Julia release also tests file exchange with R and Python.
These tests include all four formats in both directions.

The workflow uses path filters for pull requests and pushes to `main`.
These filters select changes to source files, tests, documentation, licenses, and build configuration.
To start it manually, select **Actions > Julia tests > Run workflow** in GitHub.
The workflow stores build logs, dependency versions, and test reports as artifacts for 30 days.

## Package use

Start Julia with the output package as its project:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO
```

Use these commands in Julia:

```julia
using DataBionicIO

data = [1.25 10.0; NaN -2.5; 3.75 30.0]
keys = Int64[-2^53, 2^31, 2^53]
write_lrn("example.lrn", data; keys, header=["X", "Y"])
result = read_lrn("example.lrn")
result.data
result.keys
```

To use the package in another Julia environment, start this command in that environment:

```julia
using Pkg
Pkg.develop(path="/absolute/path/to/build/julia/libs/juliaDataIO/DataBionicIO")
```

Keep the output package at that path.
The [example](examples/example.jl) shows all four formats.

## Functions

Each reader takes a file path and the optional keyword `verbose=false`.
Each reader gives a `NamedTuple` with Julia arrays and strings.
Matrices contain observations in rows and variables in columns.

| Reader | Result fields |
| --- | --- |
| `read_lrn(path)` | `header`, `keys`, `data`, `types`, `comment` |
| `read_cls(path)` | `keys`, `classes`, `unique_classes`, `comment` |
| `read_names(path)` | `header`, `file_header`, `keys`, `names`, `further_texts`, `comment` |
| `read_dates(path)` | `header`, `file_header`, `keys`, `times`, `data`, `dst`, `timezone`, `comment` |

`types` includes the key column type.
For NAMES and DATES, `header` labels the additional data columns.
`file_header` contains the file column labels without the optional `TZ_DST` label.

| Writer | Data arguments |
| --- | --- |
| `write_lrn(path, data)` | Numeric matrix. |
| `write_cls(path, classes)` | Class vector. |
| `write_names(path, names)` | Name vector. The `further_texts` keyword supplies an additional text matrix. |
| `write_dates(path, times, data)` | Timestamp vector and numeric matrix. |

Writers use format 2.0 and give `nothing` as their result.
Each writer has `keys=nothing`, `comment=""`, `overwrite=true`, and `verbose=false` as keyword defaults.
Use `overwrite=false` to keep an existing file.
If `keys=nothing`, the writer gives a warning and uses keys from 1 to the row count.

LRN, NAMES, and DATES writers have a `header` keyword for column labels.
LRN also has `types`, `significant_digits`, `decimal_digits`, and `scientific` keywords.
NAMES headers label Names and the additional text columns.
DATES headers label only numeric columns.
The Julia help text gives the keyword defaults for each function.

## Values and diagnostics

Keys must be unique whole numbers in `[-2^53, 2^53]`.
Readers give `Int64` keys or `missing` for an invalid key.
Writers reject invalid keys before they open the output file.
Do not convert a larger identifier to `Float64` before the write operation.

Numeric input can contain `missing` or NaN.
Numeric output uses NaN for missing values.
Text input and output use `missing` for the reserved file token `NA`.
Text cells cannot contain tabs or line breaks.

The CLS writer has a `missing_class=NaN` keyword for the replacement of missing classes.
Class values must be whole numbers in the C++ `int` range.
The core replaces invalid class values with NaN and gives a warning.

The package sends core warnings to Julia Logging.
Warnings can occur when `verbose=false`.
C++ exceptions cause Julia errors.
The package copies read results into Julia arrays before it returns them.

## DATES

The `times` argument can contain `Date`, `DateTime`, timestamp strings, and `missing`.
The reader gives timestamp strings or `missing`.
The `timezone` field contains the file time zone.
The `dst` field contains the daylight saving time markers, if present.
The package does not convert time zones.

Supply times in the time zone given by the writer keyword `timezone`.
The default time zone is `UTC`.
For repeated local times, timestamp strings can include the DST abbreviation.
Examples are `CEST` and `CET`.

The writer keyword `format` selects timestamp resolution:

| Value | Resolution |
| --- | --- |
| `-1` | Automatic selection from the input. |
| `1` | Date. |
| `2` | Seconds. |
| `3` | Milliseconds. |

## License

DataBionicIO uses AGPL-3.0-only with the permission in `MATLAB-EXCEPTION.txt`.
The output package contains `LICENSING.md` and the license texts.
CxxWrap and libcxxwrap-julia keep their MIT licenses.
