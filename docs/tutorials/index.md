# Tutorial data and programs

Use the tutorials after [installation](../guide/installation.md).
Run shell commands from the source repository directory.
The programs read the same input files.
Each language writes to a different output directory.
The DataBionicIO writers stop if their output files are in the output directory.
For a subsequent run, supply a new output directory.

## Select a dataset and language

Each dataset has four complete programs.
Each program assigns the necessary reader output fields to separate objects.
The language versions use the same object names and corresponding operations.
Assertions compare keys with `TheSameKey`.
Select the language that you use:

| Dataset | R | Python | MATLAB | Julia |
| --- | --- | --- | --- | --- |
| [Hepta](hepta.md) | [R](hepta.md#r) | [Python](hepta.md#python) | [MATLAB](hepta.md#matlab) | [Julia](hepta.md#julia) |
| [Firebrowse](firebrowse.md) | [R](firebrowse.md#r) | [Python](firebrowse.md#python) | [MATLAB](firebrowse.md#matlab) | [Julia](firebrowse.md#julia) |
| [Hydrology](hydrology.md) | [R](hydrology.md#r) | [Python](hydrology.md#python) | [MATLAB](hydrology.md#matlab) | [Julia](hydrology.md#julia) |
| [Flow cytometry](flow-cytometry.md) | [R](flow-cytometry.md#r) | [Python](flow-cytometry.md#python) | [MATLAB](flow-cytometry.md#matlab) | [Julia](flow-cytometry.md#julia) |

## Data and results

| Dataset | Input | Result |
| --- | --- | --- |
| Hepta | 212 rows, 3 measurements, 7 classes | Three files with the same keys |
| Firebrowse | 19,637 gene labels and 10,446 cases | A NAMES copy and diagnosis counts |
| Flow cytometry | 440,000 rows and 10 measurements | An LRN file with 1,000 selected rows |
| Hydrology | 351 calendar dates and 14 measurements | A DTS copy with the same missing values |

The small input files are in `examples/tutorials/data/`.
The large flow-cytometry input has its [download procedure](flow-cytometry.md#get-the-input).
The programs do not fit statistical models.

(download-individual-files)=
## Download input files

| File | Download |
| --- | --- |
| Hepta measurements | {download}`hepta.lrn <../../examples/tutorials/data/hepta.lrn>` |
| Hepta classes | {download}`hepta.cls <../../examples/tutorials/data/hepta.cls>` |
| Hepta names | {download}`hepta.names <../../examples/tutorials/data/hepta.names>` |
| Firebrowse gene identifiers | {download}`13ColumnNCBIs_Firebrowse_N19637.names <../../examples/tutorials/data/13ColumnNCBIs_Firebrowse_N19637.names>` |
| Firebrowse case classes | {download}`14Genexpression_Firebrowse_Cls_N10446.cls <../../examples/tutorials/data/14Genexpression_Firebrowse_Cls_N10446.cls>` |
| Firebrowse class descriptions | {download}`15Genexpression_Cls2Diagnosis_N33.names <../../examples/tutorials/data/15Genexpression_Cls2Diagnosis_N33.names>` |
| Firebrowse case names | {download}`16Genexpression_Cases_N10446.names <../../examples/tutorials/data/16Genexpression_Cases_N10446.names>` |
| Hydrology time series | {download}`HydrologyDaily2013_2014.dts <../../examples/tutorials/data/HydrologyDaily2013_2014.dts>` |
| Input provenance and digests | {download}`manifest.json <../../examples/tutorials/data/manifest.json>` |

Keep the input filenames after a browser download.
Before you redistribute dataset files, read [data sources and attribution](../reference/sources.md).
