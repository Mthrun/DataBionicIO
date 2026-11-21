# INPUT
# Optional command-line input directory and output directory.
# Defaults use examples/tutorials/data and build/tutorials/hepta/r.
# OUTPUT
# Three Hepta files, a class-count table, and key comparisons.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
library(DataBionicIO)
args <- commandArgs(trailingOnly = TRUE)
InDirectory <- if (length(args) >= 1) args[1] else "examples/tutorials/data"
OutDirectory <- if (length(args) >= 2) args[2] else "build/tutorials/hepta/r"
dir.create(OutDirectory, recursive = TRUE, showWarnings = FALSE)

# Read the measurements, classes, and labels independently.
Result <- ReadLRN("hepta", InDirectory = InDirectory, Verbose = FALSE)
Key <- Result$Key
Data <- Result$Data
Header <- Result$Header
DataDefined <- Result$DataDefined
Comments <- Result$Comments
Result <- ReadCLS("hepta", InDirectory = InDirectory, Verbose = FALSE)
ClassKey <- Result$Key
Cls <- Result$Cls
ClassComments <- Result$Comments
Result <- ReadNAMES("hepta", InDirectory = InDirectory, Verbose = FALSE)
NameKey <- Result$Key
Names <- Result$Names
NameComments <- Result$Comments

# Align each companion file to the measurement keys.
if (!TheSameKey(Key, ClassKey)) {
  ClassRows <- match(Key, ClassKey)
  Cls <- Cls[ClassRows]
  ClassKey <- ClassKey[ClassRows]
  stopifnot(TheSameKey(Key, ClassKey))
}
if (!TheSameKey(Key, NameKey)) {
  NameRows <- match(Key, NameKey)
  Names <- Names[NameRows]
  NameKey <- NameKey[NameRows]
  stopifnot(TheSameKey(Key, NameKey))
}
Counts <- table(Cls)
print(Counts)

# Keep the keys, labels, column types, and user comments.
WriteLRN("hepta_copy", Data, Header = Header, Key = Key,
         DataDefined = DataDefined, OutDirectory = OutDirectory,
         Comments = Comments, Overwrite = FALSE, Verbose = FALSE)
WriteCLS("hepta_copy", Cls, OutDirectory = OutDirectory, Key = Key,
         Comment = ClassComments, Overwrite = FALSE, Verbose = FALSE)
WriteNAMES("hepta_copy", Names, Key = Key,
           Header = c("Key", "Names"), OutDirectory = OutDirectory,
           Comments = NameComments, Overwrite = FALSE, Verbose = FALSE)

# Read the files and compare their keys.
Result <- ReadLRN("hepta_copy", InDirectory = OutDirectory, Verbose = FALSE)
Key2 <- Result$Key
Result <- ReadCLS("hepta_copy", InDirectory = OutDirectory, Verbose = FALSE)
ClassKey2 <- Result$Key
Result <- ReadNAMES("hepta_copy", InDirectory = OutDirectory, Verbose = FALSE)
NameKey2 <- Result$Key
stopifnot(TheSameKey(Key, Key2))
stopifnot(TheSameKey(Key, ClassKey2))
stopifnot(TheSameKey(Key, NameKey2))
cat("Hepta example complete.\n")
