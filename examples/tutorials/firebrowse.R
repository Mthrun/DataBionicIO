# INPUT
# Input path and optional output directory.
# OUTPUT
# A NAMES copy, key comparisons, and the diagnosis-count table Summary.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Example starts here
library(DataBionicIO)
args <- commandArgs(trailingOnly = TRUE)
InDirectory <- if (length(args) >= 1) args[1] else "examples/tutorials/data"
OutDirectory <- if (length(args) >= 2) args[2] else "build/tutorials/firebrowse/r"
dir.create(OutDirectory, recursive = TRUE, showWarnings = FALSE)
Result <- ReadNAMES("13ColumnNCBIs_Firebrowse_N19637.names",
                   InDirectory = InDirectory, Verbose = FALSE)
GeneKey <- Result$Key
GeneNames <- Result$Names
FurtherTexts <- Result$FurtherTexts
Header <- Result$Header
Comments <- Result$Comments

# Keep the primary names label from the input file.
FullHeader <- c("Key", "Column_Name", Header)
WriteNAMES("Firebrowse_copy", GeneNames, Key = GeneKey,
           FurtherTexts = FurtherTexts, Header = FullHeader,
           OutDirectory = OutDirectory, Comments = Comments,
           Overwrite = FALSE, Verbose = FALSE)
Result <- ReadNAMES("Firebrowse_copy", InDirectory = OutDirectory, Verbose = FALSE)
Key2 <- Result$Key
stopifnot(TheSameKey(GeneKey, Key2))

# Use the case-file order. Class values identify diagnosis descriptions.
Result <- ReadCLS("14Genexpression_Firebrowse_Cls_N10446.cls",
                   InDirectory = InDirectory, Verbose = FALSE)
ClassKey <- Result$Key
Cls <- Result$Cls
Result <- ReadNAMES("16Genexpression_Cases_N10446.names",
                   InDirectory = InDirectory, Verbose = FALSE)
CaseKey <- Result$Key
CaseNames <- Result$Names
Result <- ReadNAMES("15Genexpression_Cls2Diagnosis_N33.names",
                       InDirectory = InDirectory, Verbose = FALSE)
DiagnosisKey <- Result$Key
DiagnosisNames <- Result$Names

if (!TheSameKey(ClassKey, CaseKey)) {
  ClassRows <- match(CaseKey, ClassKey)
  Cls <- Cls[ClassRows]
  ClassKey <- ClassKey[ClassRows]
  stopifnot(TheSameKey(ClassKey, CaseKey))
}
Counts <- table(Cls)
Labels <- as.numeric(names(Counts))
if (!TheSameKey(Labels, DiagnosisKey)) {
  DiagnosisRows <- match(Labels, DiagnosisKey)
  DiagnosisNames <- DiagnosisNames[DiagnosisRows]
  DiagnosisKey <- DiagnosisKey[DiagnosisRows]
  stopifnot(TheSameKey(Labels, DiagnosisKey))
}
Summary <- data.frame(Class = Labels, Diagnosis = DiagnosisNames,
                      Cases = as.integer(Counts))
