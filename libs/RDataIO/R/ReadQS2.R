ReadQS2 = function(FileName, InDirectory=getwd(), NThreads=1, Strict=FALSE){
  # DataV = ReadQS2(FileName)
  # Reads an R object stored in the current qs2 format.
  #
  # INPUT
  # FileName       Single file name, with or without the .qs2 extension.
  # OPTIONAL
  # InDirectory    Input directory; default is getwd().
  # NThreads       Positive number of reader threads; default is 1.
  # Strict         Validate the checksum before reading; default is FALSE.
  # OUTPUT
  # DataV          The stored R object, including its attributes.
  # AUTHOR: Michael Thrun (IAP-GmbH Intelligent Analytics Projects)
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  # DETAILS
  # Use ReadQS() for legacy .qs files and WriteQS2() to save new files.
  # Date: 2026-10-18

  if(!is.character(FileName) || length(FileName) != 1L || is.na(FileName))
    stop("FileName must be one non-missing string")
  if(!requireNamespace("qs2", quietly=TRUE)) stop("Install the qs2 package to read .qs2 files")
  if(!grepl("\\.qs2$", FileName, ignore.case=TRUE)) FileName = paste0(FileName, ".qs2")
  # Passing a full path avoids leaving the caller in another directory after an error.
  qs2::qs_read(file.path(InDirectory, FileName), validate_checksum=Strict, nthreads=NThreads)
}
