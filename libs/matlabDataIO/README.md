# DataBionicIO for MATLAB

The project uses GNU AGPL version 3 only, with a MATLAB linking exception.
The built package includes `LICENSE` and `MATLAB-EXCEPTION.txt`.
The exception does not supply a MATLAB license.

This package uses the shared C++ code for LRN, CLS, NAMES, and DATES.
Other formats use MATLAB functions from the DataIO source archive.
The build script uses 64-bit MATLAB R2022a or newer and a C++20 compiler.
Each platform has its own MEX file.

## Folders

| Folder | Contents |
| --- | --- |
| `src/` | The MEX interface to the shared C++ code. |
| `modern/` | MATLAB functions for the four C++ formats. Input helpers are in `private/`. |
| `native/` | MATLAB functions for other formats and their helpers. |
| `legacy/` | MATLAB readers for legacy LRN, CLS, and NAMES files. These readers do not use a compiler. |
| `archive/` | The initial `ReadWIDcsv.m` source file. Setup does not add this folder to the MATLAB path. |
| `bin/` | The MEX file in a built package. |
| `tests/` | MATLAB tests and sample files. |

`ORIGIN.txt` records the source file hashes and changes to copied files.
The copied files keep their author comments.

## Select the package

1. Open the package folder in MATLAB.
2. Start the setup function:

   ```matlab
   setupDataIO
   ```

Setup selects `modern/` on R2022a or newer.
Setup selects `legacy/` on earlier releases.
It also adds `native/`. It does not save the MATLAB path.
A missing MEX file in modern mode causes an error.
A MEX file that MATLAB cannot load also causes an error.

The two modes have the same public function names.
A previous DataIO file in the working folder can hide the selected function.
Setup examines this condition for the core functions.
If a different function hides a selected function, setup sets the path to its previous value.

Do not add the full folder tree with `genpath`.
Remove the previous DataIO folder from the MATLAB path before setup.

To select the readers for legacy file formats, use:

```matlab
setupDataIO('legacy')
```

This mode reads only LRN, CLS, and NAMES files without a version tag or with version 1.0.
The mode gives an error for writer calls and DATES calls.

## Build in MATLAB

The full source tree is necessary for the build.
The compiler and its standard library must be compatible with C++20.
The selected compiler must be compatible with the installed MATLAB release.
On Windows, the build script uses a Microsoft C++ compiler.

1. Open `libs/matlabDataIO/` in MATLAB.
2. Select the C++ compiler:

   ```matlab
   mex -setup C++
   ```

3. Build the package:

   ```matlab
   Package = buildDataIO;
   ```

The default output folder is `build/matlab/<platform>/DataBionicIO/`.
The build stops if a folder already has this path.
The optional argument to `buildDataIO` specifies a different parent folder.

The build uses the C Matrix API with `-R2017b`.
The MEX file contains the compiled C++ core.
The package does not use an external DataIO DLL.
A built package uses the compiler runtime for its MEX file.
A compiler is not necessary to use a built package.

## Build with CMake

The CMake build uses MATLAB and a compatible C++20 compiler.
R and Python are not necessary for this build.

1. Open a shell in the project folder.
2. Set the build options:

   ```sh
   cmake -S . -B build/matlab-cmake -DBUILD_RPACKAGE=OFF -DBUILD_PYPACKAGE=OFF -DBUILD_MATLABPACKAGE=ON -DMatlab_ROOT_DIR="path/to/MATLAB"
   ```

3. Build the package:

   ```sh
   cmake --build build/matlab-cmake --config Release --target MatlabPackage
   ```

The output folder is `build/matlab-cmake/libs/matlabDataIO/DataBionicIO/`.
On Windows, the CMake generator must select a 64-bit compiler.

## Tests

The test script has different modes for the modern and legacy interfaces.
The tests include file formats, array orientation, keys, precision, missing fields, path selection, and UTC conversion.
The native format tests include BM and UMX.
The script saves logs and test files in a temporary folder.

1. Open the built package folder in MATLAB.
2. Start `setupDataIO`.
3. Add the test folder:

   ```matlab
   addpath(fullfile(pwd, 'tests'))
   ```

4. Start the tests for the selected mode:

   ```matlab
   ReportDirectory = runDataIOTests('modern');
   ```

For legacy mode, use `runDataIOTests('legacy')`.

The optional second argument to `runDataIOTests` sets a new report folder.
The script rejects a report folder that already exists.

## GitHub Actions

The MATLAB workflow has these configurations:

| Operating system | Architecture | MATLAB | C++ compiler |
| --- | --- | --- | --- |
| Windows Server 2022 | x64 | R2024b | Microsoft Visual C++ 2022 |
| Ubuntu 24.04 | x64 | R2024b | GCC 13 |
| macOS 15 | Apple Silicon | R2025b | Xcode 16.4 |

The workflow builds the MEX module and starts the modern and legacy test modes.
Each configuration uses the same MATLAB release for both test modes.
GitHub stores build logs, environment information, and test reports as workflow artifacts.

The Linux configuration also starts tests of file exchange between R, Python, and MATLAB.
Each language writes LRN, CLS, NAMES, and DATES files.
The other languages read these files and compare the results with specified values.

The workflow makes a package artifact when all required test results are PASS.
Each package artifact contains a ZIP file and its SHA-256 checksum file.
The ZIP file contains the MATLAB functions, MEX file, license texts, source commit identifier, and test status.
The ZIP filename contains the MATLAB release, architecture, and source commit identifier.

1. Download the package artifact for your platform.
2. Open the downloaded artifact with a ZIP program.
3. Open the `DataBionicIO-*.zip` file.
4. Copy the `DataBionicIO` folder to a local folder.
5. Open the `DataBionicIO` folder in MATLAB.
6. Start `setupDataIO`.

The command for the workflow is in `ci/matlab/runMatlabCI.m` in the source tree.
The command writes reports to `build/ci/matlab/`.
Package ZIP files are in `build/ci/packages/`.

## Public functions

The LRN, CLS, and NAMES functions keep the positional argument order of the previous MATLAB interfaces.
An optional last struct supplies other options.
Empty optional arguments select the default values.

Use `help FunctionName` for the full argument list.

| Function | Result or input |
| --- | --- |
| `ReadLRN` | `[Data,Key,Header,DataDefined,Comment]`. `Header` is a character matrix. `DataDefined` identifies the returned data columns. The reader ignores type 0 columns. |
| `WriteLRN` | A full real numeric matrix, with optional header, keys, types, directory, comment, precision, and options. |
| `ReadCLS` | `[Key,Cls,Comment,UniqueClasses,ClassColors]`. `ClassColors` is empty. `Int4NaN` specifies a value for missing classes. |
| `WriteCLS` | A class vector or a matrix with multiple rows and two columns for `[Key,Cls]`. A row vector supplies class values. |
| `ReadNAMES` | `[Key,Names,RowRest,Comment,Header,FurtherTexts]`. `Names` and `Header` are character matrices. `FurtherTexts` is a cell matrix. |
| `WriteNAMES` | Names as character rows, a string vector, or a cell vector. Without `RowRest`, the writer uses `Names` again. |
| `ReadDates` | `[Time,Data,Key,Header,Comment,Timezone,TZ_DST]`. `Time` contains text in a cell vector. `Header` identifies the numeric columns. |
| `WriteDates` | Time, numeric data, header, keys, directory, comment, and options. |

The modern readers return `Comment` as one character row with newline separators.
The legacy readers return a character matrix for comments.
`ReadNAMES` joins other fields in `RowRest` with tabs.
For `WriteNAMES`, an empty `RowRest` also uses `Names` again.

To write no other text fields, supply `cell(n,0)` as `RowRest`.

The writers use format 2.0. Read functions do not write files.
The modern LRN, CLS, and NAMES readers also accept specified legacy layouts.
`WriteLRN` accepts type 0 columns, which the reader ignores.
`WriteCLS` includes class counts. `ClassSizes=0` causes a warning.

## Keys and file errors

Keys are unique whole numbers in `[-2^53,2^53]`.
Writers accept numeric vectors, with types such as `int64` and `uint64`.
They examine integer types before conversion to double.
Invalid keys cause an error before output.
Without keys, the writer supplies values from 1 to the row count and gives a warning.

Readers return double keys.
A missing or invalid key becomes `NaN`.

Do not convert identifiers not in the permitted range to double values before a write operation.

A short row has `NaN` for missing numeric fields and `'NA'` for missing text fields.
Empty text also becomes `'NA'`.
Other fields do not add columns.
A numeric prefix can supply a value: `12oops` gives 12 and a warning.
The decimal separator is a dot. `3,4oops` gives 3 and a warning.

The LRN and NAMES readers remove spaces, tabs, commas, and semicolons from header labels, with a warning.
Name values are text and can start with digits.
`Verbose=false` hides information messages. It does not hide warnings about file errors.
The warning identifiers include `DataIO:FileWarning` and `DataIO:MissingKey`.
C++ errors use `DataIO:Core`.

MATLAB receives C++ warnings after the file operation returns.
With warnings set to errors, MATLAB can give an error after a completed write operation.

To prevent changes to an existing file, set `Overwrite=false`.

## LRN precision

`SignificantDigits` specifies the number of significant digits.
`DecimalDigits` specifies the number of decimal places.
Scientific notation uses the same significant precision.

```matlab
Options = struct('SignificantDigits',4,'Overwrite',false);
WriteLRN('example', [1;1.23456], {'Value'}, [1;2], [], pwd, ...
         'Example', false, [], Options);
```

This example writes 1 and 1.235.
`DecimalDigits=0` rounds to whole numbers.
The positional `Digits` argument specifies decimal places in fixed notation or in the scientific mantissa.
The writer removes fractional zeros that are not necessary. It keeps exponent zeros.

With fewer than seven input arguments, `Scientific` defaults to true.
With argument 7 and no explicit `Scientific` argument, it defaults to false.

## DATES time values

DATES accepts dates, seconds, or milliseconds.
`Options.Format` accepts -1, 1, 2, or 3.
Text times must use UTC.
The writer converts datetime input with a time zone to UTC.
Input without a time zone causes a warning. The writer uses UTC for this input.

The reader returns `Timezone` and `TZ_DST` as two results.
It does not convert time zones or interpret numeric offsets such as `+11`, `+1030`, or `-02`.
Time precision is at most one millisecond.

## Other MATLAB formats

Native functions include BM, CSV, TSV, TXT, DATA, IMX, NSM, UMX, WTS, DBF, RGB, and YALE helpers.
Some native functions call LRN or NAMES through the selected interface.
Native functions have their own rules for precision and file errors.
The MATLAB package has no QS or QS2 reader or writer.

Some native functions use external dbt helpers.
`ReadCSV` uses `tokenizeLineNaN`, `tokenize2Strings`, `IsDateString`, `date2YYYYMMDD`, and `BlanksArray`.
`ReadDATA` uses `TheSameKey`, `countNaNs`, `head`, and `trim`.
Other functions use `strmat2cell`.
The legacy mode for the three core readers does not set the requirements for these native functions.

`skiplines` reads empty lines and the end of the file without `contains`.
The filenames `FABloadtxt.m` and `WritePRO.m` agree with their function names.
The public `ReadWIDcsv` function gives an error before it opens a file.
The initial `ReadWIDcsv.m` source is in `archive/`.
