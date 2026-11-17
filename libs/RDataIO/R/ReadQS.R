ReadQS = function(FileName, InDirectory=getwd(), NThreads=1, Strict=FALSE){
  # DataV = ReadQS(FileName)
  # Reads current qs2 files or legacy qs lists of matrices without writing files.
  #
  # INPUT
  # FileName       Single file name. Explicit .qs selects legacy; .qs2 selects qs2.
  # OPTIONAL
  # InDirectory    Input directory; default is getwd().
  # NThreads       Threads for qs2; the legacy matrix reader is sequential.
  # Strict         Checksum errors instead of warnings; default is FALSE.
  # OUTPUT
  # DataV          Stored object for qs2; a list of matrices for legacy qs.
  # DETAILS
  # Without a suffix, prefer an existing .qs2 file, otherwise try .qs.
  # The qslegacy helper reads old qs data directly in the current R process,
  # including R 4.6. No older R, temporary files or RDS transfer is needed.
  # The migration warning occurs once per calendar day within this R session.
  # Its date is kept only in memory, shared by both DataIO packages.
  # Author: Quirin Stier (IAP-GmbH Intelligent Analytics Projects) 2022; qs2 compatibility update 2026-10-18
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.

  if(!is.character(FileName) || length(FileName) != 1L || is.na(FileName))
    stop("FileName must be one non-missing string")
  if(!grepl("\\.qs2?$", FileName, ignore.case=TRUE)) {
    suffix = if(file.exists(file.path(InDirectory, paste0(FileName, ".qs2")))) ".qs2" else ".qs"
    FileName = paste0(FileName, suffix)
  }
  if(grepl("\\.qs2$", FileName, ignore.case=TRUE)) return(ReadQS2(FileName, InDirectory, NThreads, Strict))
  path = normalizePath(file.path(InDirectory, FileName), mustWork=TRUE)
  if(length(NThreads) != 1L || !is.numeric(NThreads) || is.na(NThreads) || !is.finite(NThreads) || NThreads < 1 || NThreads %% 1 != 0)
    stop("NThreads must be a positive integer")
  if(!is.logical(Strict) || length(Strict) != 1L || is.na(Strict)) stop("Strict must be TRUE or FALSE")
  if(!requireNamespace("qslegacy", quietly=TRUE))
    stop("Install the qslegacy companion package supplied with DataIO to read legacy .qs lists of matrices")

  # The former older-R bridge wrote scripts and RDS files; decode in memory instead.
  DataV = qslegacy::qread_matrices(path, strict=Strict)
  # A disk marker also made reads write files. Keep the warning date only in R memory.
  today = as.character(Sys.Date())
  if(!identical(getOption("DataIO.qs.warning_day", ""), today)) {
    options(DataIO.qs.warning_day=today)
    warning("Legacy .qs file: save it as .qs2 with WriteQS2() or ConvertQSToQS2() for compatibility with current R versions.", call.=FALSE)
  }
  DataV
}
