# INPUT
# Input path and optional output directory.
# OUTPUT
# A DTS copy and a comparison of its keys.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
library(DataBionicIO)
args <- commandArgs(trailingOnly = TRUE)
InDirectory <- if (length(args) >= 1) args[1] else "examples/tutorials/data"
OutDirectory <- if (length(args) >= 2) args[2] else "build/tutorials/hydrology/r"
dir.create(OutDirectory, recursive = TRUE, showWarnings = FALSE)
Result <- ReadDates("HydrologyDaily2013_2014.dts", InDirectory = InDirectory, Verbose = FALSE)
Key <- Result$Key
Time <- Result$Time
Data <- Result$Data
Header <- Result$Header
Comments <- Result$Comments
Timezone <- Result$Timezone

# Keep the calendar dates. The source does not identify an acquisition time zone.
TSdata <- data.frame(Time = Time, Data, check.names = FALSE)
names(TSdata) <- c("Time", Header)
WriteDates("Hydrology_copy", TSdata, Key = Key, OutDirectory = OutDirectory,
           Comments = Comments, tz = Timezone, Format = 1,
           Overwrite = FALSE, Verbose = FALSE)
Result <- ReadDates("Hydrology_copy", InDirectory = OutDirectory, Verbose = FALSE)
Key2 <- Result$Key
stopifnot(TheSameKey(Key, Key2))
cat("Hydrology example complete.\n")
