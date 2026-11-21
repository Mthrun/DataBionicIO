# INPUT
# No external input. The program uses the installed DataBionicIO package.
# OUTPUT
# An LRN file in a temporary directory and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
library(DataBionicIO)
OutDirectory <- tempfile("DataBionicIO-")
dir.create(OutDirectory)
Data <- matrix(c(1.5, 2, 3.5, NA_real_), nrow = 2, byrow = TRUE)
Key <- c(101, 205)
WriteLRN("example", Data, Header = c("Length", "Mass"),
         Key = Key, OutDirectory = OutDirectory, Overwrite = FALSE,
         Verbose = FALSE)
Result <- ReadLRN("example", InDirectory = OutDirectory, Verbose = FALSE)
Key2 <- Result$Key
stopifnot(TheSameKey(Key, Key2))
cat("Quick start complete.\n")
