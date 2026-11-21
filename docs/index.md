# DataBionicIO

DataBionicIO reads and writes data files in R, Python, MATLAB, and Julia.
The four interfaces use the same C++ code for LRN, CLS, NAMES, and DTS.
The text files contain numeric data, class assignments, names, or time series.
Keys connect records across files.

These pages give instructions and information for source version **{{ version }}**.
Version 1.0.2 contains more text options than release 1.0.1.
The four data tutorials use the common interface available in 1.0.1.
The [installation page](guide/installation.md) gives the package selection procedure.

## Start here

Do these steps:

1. [Install the package](guide/installation.md) for your language.
2. [Start the file example](guide/quickstart.md).
3. [Select a data tutorial](tutorials/index.md).

## Four data tutorials

Each dataset has a complete example in R, Python, MATLAB, and Julia.
The four language versions use the same task, input data, and key comparisons.

| Dataset | R | Python | MATLAB | Julia |
| --- | --- | --- | --- | --- |
| [Hepta](tutorials/hepta.md) | [R](tutorials/hepta.md#r) | [Python](tutorials/hepta.md#python) | [MATLAB](tutorials/hepta.md#matlab) | [Julia](tutorials/hepta.md#julia) |
| [Firebrowse](tutorials/firebrowse.md) | [R](tutorials/firebrowse.md#r) | [Python](tutorials/firebrowse.md#python) | [MATLAB](tutorials/firebrowse.md#matlab) | [Julia](tutorials/firebrowse.md#julia) |
| [Hydrology](tutorials/hydrology.md) | [R](tutorials/hydrology.md#r) | [Python](tutorials/hydrology.md#python) | [MATLAB](tutorials/hydrology.md#matlab) | [Julia](tutorials/hydrology.md#julia) |
| [Flow cytometry](tutorials/flow-cytometry.md) | [R](tutorials/flow-cytometry.md#r) | [Python](tutorials/flow-cytometry.md#python) | [MATLAB](tutorials/flow-cytometry.md#matlab) | [Julia](tutorials/flow-cytometry.md#julia) |

The tutorials contain code, input files or source links, and expected results.
They show file operations on the datasets from the software article.
They do not do the scientific analyses from those articles.

```{toctree}
:maxdepth: 1
:caption: User guide

guide/installation
guide/quickstart
guide/keys
guide/encoding
guide/excel
guide/troubleshooting
```

```{toctree}
:maxdepth: 1
:caption: Tutorials

tutorials/index
tutorials/hepta
tutorials/firebrowse
tutorials/flow-cytometry
tutorials/hydrology
```

```{toctree}
:maxdepth: 1
:caption: Reference

formats/index
formats/lrn
formats/cls
formats/names
formats/dts
reference/api
reference/sources
reference/documentation
```

## Source and license

The source repository is [Mthrun/DataBionicIO](https://github.com/Mthrun/DataBionicIO).
DataBionicIO uses AGPL-3.0-only with the additional permission in `MATLAB-EXCEPTION.txt`.
The repository [license notice](https://github.com/Mthrun/DataBionicIO/blob/main/LICENSING.md) gives the scope and license texts.
Third-party components and datasets keep their applicable notices and terms.
