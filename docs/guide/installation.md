# Installation

The package name is `DataBionicIO` in all four languages.
The examples use its common interface.

## Select a version

The [GitHub releases](https://github.com/Mthrun/DataBionicIO/releases) contain published packages.
Select a package for your language, operating system, and processor.
For Python, select a wheel for your CPython version.
For Julia and MATLAB, obey the instructions supplied with the selected archive.

The source metadata gives version {{ version }}.
A source version does not show that a release package is available.
For the [text options](encoding.md) in version 1.0.2, build source version 1.0.2.
The tutorials use the reader and writer arguments from release 1.0.1.

## R

Rcpp, lubridate, methods, and a C++20 compiler are necessary for a source installation.
Install the R dependencies first:

```r
install.packages(c("Rcpp", "lubridate"))
```

Then install the source archive from its download directory:

```r
install.packages("DataBionicIO_1.0.1.tar.gz", repos = NULL, type = "source")
library(DataBionicIO)
packageVersion("DataBionicIO")
```

For a different version, use the filename of that archive.

The tutorials do not use `qslegacy`.
That package reads legacy QS files.

To build the R package from this repository, use a shell in the repository directory:

```sh
cmake -S . -B build/r -DBUILD_PYPACKAGE=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build/r --config Release --target RPackageInstall
```

This target also builds and installs `qslegacy`.
CMake 3.15 or a subsequent version and a Bash shell are necessary for this build.

## Python

Install the selected wheel with the Python interpreter that will use it:

```sh
python -m pip install /path/to/the/downloaded.whl
python -c "import DataBionicIO; print(DataBionicIO.__file__)"
```

Replace the example path with the complete wheel filename.
NumPy, Pandas, and tzdata are necessary at runtime.
The package metadata gives Python 3.9 as the minimum version.
Each release has its specified set of wheels.

To build from source, use these commands in the repository directory:

```sh
python -m pip install "numpy>=1.21" "pandas>=1.5" tzdata setuptools wheel pybind11
cmake -S . -B build/python -DBUILD_RPACKAGE=OFF \
  -DPython_EXECUTABLE="$(python -c 'import sys; print(sys.executable)')" \
  -Dpybind11_DIR="$(python -m pybind11 --cmakedir)" \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build/python --config Release --target PyPackageBuild
```

CMake 3.15 or a subsequent version and a C++20 compiler are necessary for this build.
Install the wheel from `build/python/libs/pyDataIO/dist/`.

## MATLAB

Extract a package for your platform.
Open its `DataBionicIO` directory in MATLAB.
Run the setup function:

```matlab
setupDataIO('modern');
which DataBionicIO.ReadLRN
```

The modern interface uses 64-bit MATLAB R2022a or a subsequent version.
A compatible MEX file is necessary.
A compiler is not necessary to use a built package.
Do not add the complete directory tree with `genpath`.

To build from source, open `libs/matlabDataIO/` in MATLAB:

```matlab
mex -setup C++
Package = buildDataIO;
```

A compatible C++20 compiler is necessary for this build.
Its default output is `build/matlab/<platform>/DataBionicIO/`.
Run setup from that output directory.

## Julia

Build from the repository directory:

```sh
julia --startup-file=no libs/juliaDataIO/build.jl
```

Julia 1.10 or a subsequent version, CxxWrap 0.17, CMake, and a C++20 compiler are necessary for this build.
The build script gets Julia dependencies when they are necessary.
Julia and the compiler must use the same processor architecture.

Start Julia with the output package:

```sh
julia --project=build/julia/libs/juliaDataIO/DataBionicIO
```

```julia
using DataBionicIO
```

When you run the Julia tutorial, keep this project active.
For a binary archive, use its supplied installation instructions and specified Julia version.

## Get the examples

To get the source repository, use one of these methods:

- Download the repository as a ZIP.
- Clone the repository with these commands:

```sh
git clone https://github.com/Mthrun/DataBionicIO.git
cd DataBionicIO
```

The tutorial programs are in `examples/tutorials/`.
Run the shell commands on these pages from the repository directory.
The programs write their output in subdirectories of `build/tutorials/`.
