Append2LRN = function(FileName, Data, Key, OutDirectory=getwd()){
# DESCRIPTION
# Append rows to an existing LRN file and update its row count.
#
# INPUT
# FileName                         name of the existing file; .lrn is added if needed.
# Data(1:n,1:d)                    numeric matrix, with the same data columns as the file.
# Key(1:n)                        unique finite integer keys within +/- .Machine$integer.max;
#                                  keys must not already occur in the file.
# OPTIONAL
# OutDirectory                    directory containing the file; default is current directory.
#
# OUTPUT
# The updated LRN file. Existing data text and comments are preserved.
# New values use 17 significant digits; missing values are written as NaN.
#
#1.Editor: QMS 2021
# AUTHOR: Quirin Stier (IAP-GmbH Intelligent Analytics Projects)
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
  if(is.list(Data)) stop('Data is a list, but it ought to be a matrix')
  if(is.vector(Data)){
    Data = as.matrix(Data)
    warning('Data is a vector, but it ought to be a matrix')
  }
  if(!is.matrix(Data) || mode(Data) != "numeric") stop('Data must be a numeric matrix')
  # as.integer silently truncated keys; reject invalid keys before touching the file.
  if(!is.numeric(Key) || is.complex(Key) || anyNA(Key) ||
      any(!is.finite(Key) | Key != trunc(Key) | abs(Key) > .Machine$integer.max)) {
    stop("Key must contain finite integer values between -.Machine$integer.max and .Machine$integer.max")
  }
  if(length(Key) != nrow(Data) || anyDuplicated(Key)) stop("Supply one unique Key per data row")
  if(!endsWith(FileName, ".lrn")) FileName = paste0(FileName, ".lrn")
  # setwd and open connections were left behind on errors; use a path and automatic cleanup.
  Path = file.path(normalizePath(OutDirectory, mustWork=TRUE), FileName)
  Lines = readLines(Path, warn=FALSE)
  # The old code assumed at most one comment; find all four LRN header lines instead.
  HeaderLines = which(startsWith(Lines, "%"))
  if(length(HeaderLines) < 4L) stop("The LRN file needs four header lines")
  Counts = suppressWarnings(as.numeric(sub("^%[[:space:]x]*", "", Lines[HeaderLines[1:2]])))
  if(anyNA(Counts) || any(!is.finite(Counts) | Counts < 0 | Counts != trunc(Counts))) {
    stop("The LRN row and column counts must be non-negative integers")
  }
  if(Counts[2] != ncol(Data) + 1L) stop("Data must have the same number of columns as the LRN file")
  Body = Lines[seq_along(Lines) > HeaderLines[4L]]
  ExistingKeys = suppressWarnings(as.numeric(sub("[[:space:]].*$", "", trimws(Body))))
  if(any(Key %in% ExistingKeys)) stop("Key already occurs in the LRN file")
  if(nrow(Data) == 0L) return(invisible(NULL))
  # In-place count edits corrupted headers when the count gained a digit.
  Lines[HeaderLines[1L]] = paste("%", format(Counts[1] + nrow(Data), scientific=FALSE, trim=TRUE), sep="\t")
  TempFile = tempfile(".append-lrn-", tmpdir=dirname(Path))
  Backup = NULL
  Replaced = FALSE
  Connection = NULL
  on.exit({
    if(!is.null(Connection)) close(Connection)
    unlink(TempFile)
    if(!is.null(Backup) && file.exists(Backup)) {
      if(!file.exists(Path)) {
        if(!file.rename(Backup, Path)) warning(paste("Restore the original file from", Backup))
      } else if(Replaced) unlink(Backup)
    }
  }, add=TRUE)
  Connection = file(TempFile, "wt")
  # writeLines supplies the missing final newline, so the new key cannot join the last value.
  writeLines(Lines, Connection)
  for(j in seq_len(nrow(Data))) {
    Values = c(Key[j], Data[j, ])
    Text = trimws(formatC(Values, digits=17, format="g", decimal.mark="."))
    Text[is.na(Values)] = "NaN"
    writeLines(paste(Text, collapse="\t"), Connection)
  }
  close(Connection)
  Connection = NULL
  Sys.chmod(TempFile, file.info(Path)$mode)
  # Write fully before replacing the original. Windows needs a backup because rename
  # cannot overwrite there; on.exit restores that backup if replacement fails.
  if(.Platform$OS.type == "windows") {
    Backup = tempfile(".append-lrn-backup-", tmpdir=dirname(Path))
    if(!file.rename(Path, Backup)) stop("Cannot back up the original LRN file")
  }
  if(!file.rename(TempFile, Path)) stop("Cannot replace the LRN file")
  Replaced = TRUE
  invisible(NULL)
}
