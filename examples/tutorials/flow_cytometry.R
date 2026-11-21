# INPUT
# Input path and optional output directory.
# OUTPUT
# An LRN file with 1000 selected rows and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
library(DataBionicIO)
args <- commandArgs(trailingOnly = TRUE)
InFile <- normalizePath(args[1], mustWork = TRUE)
OutDirectory <- if (length(args) >= 2) args[2] else "build/tutorials/flow-cytometry/r"
dir.create(OutDirectory, recursive = TRUE, showWarnings = FALSE)
Result <- ReadLRN(basename(InFile), InDirectory = dirname(InFile), Verbose = FALSE)
Key <- Result$Key
Data <- Result$Data
Header <- Result$Header
DataDefined <- Result$DataDefined
Comments <- Result$Comments

# Select the same rows for measurements and keys.
Rows <- seq_len(1000)
WriteLRN("Dresden_subset", Data[Rows, , drop = FALSE], Header = Header,
         Key = Key[Rows], DataDefined = DataDefined, OutDirectory = OutDirectory,
         Comments = Comments, Overwrite = FALSE, Verbose = FALSE)
Result <- ReadLRN("Dresden_subset", InDirectory = OutDirectory, Verbose = FALSE)
Key2 <- Result$Key
stopifnot(TheSameKey(Key[Rows], Key2))
cat("Flow cytometry example complete.\n")
