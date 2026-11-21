# DataBionicIO tutorials

Run these programs from the repository directory after package installation.
The [tutorial pages](../../docs/tutorials/index.md) give the inputs, outputs, and expected results.
The [data sources](../../docs/reference/sources.md) give attribution.
`data/manifest.json` records the input hashes and provenance.

Each dataset has programs for R, Python, MATLAB, and Julia:

| Dataset | R | Python | MATLAB | Julia |
| --- | --- | --- | --- | --- |
| Hepta | [R](hepta.R) | [Python](hepta.py) | [MATLAB](hepta.m) | [Julia](hepta.jl) |
| Firebrowse | [R](firebrowse.R) | [Python](firebrowse.py) | [MATLAB](firebrowse.m) | [Julia](firebrowse.jl) |
| Hydrology | [R](hydrology.R) | [Python](hydrology.py) | [MATLAB](hydrology.m) | [Julia](hydrology.jl) |
| Flow cytometry | [R](flow_cytometry.R) | [Python](flow_cytometry.py) | [MATLAB](flow_cytometry.m) | [Julia](flow_cytometry.jl) |


A download of the input file is necessary for the flow-cytometry tutorial.
The programs write to different subdirectories of `build/tutorials/`.
The DataBionicIO writers stop if their output files are in the output directory.
Supply a new output directory for a subsequent run.

No external data is necessary for the quick-start programs.
Before you run the MATLAB examples, run `setupDataIO('modern')` from the package directory.
Then, use the repository directory as the working directory.
Add `examples/tutorials/` to the MATLAB path.
