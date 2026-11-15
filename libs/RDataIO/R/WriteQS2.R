WriteQS2 = function(FileName, Data, Names=NULL, OutDirectory=getwd(), NThreads=1,
                    Compress_level=4L, Shuffle=TRUE, Overwrite=TRUE){
  # WriteQS2(FileName, Data)
  # Saves an R object in the current qs2 format with its checksum.
  #
  # INPUT
  # FileName       Single output file name, with or without .qs2.
  # Data           Any R object supported by R serialization.
  # OPTIONAL
  # Names          Optional unique names for a list; existing names are retained otherwise.
  # OutDirectory   Existing output directory; default is getwd().
  # NThreads       Number of writer threads; default is 1.
  # Compress_level Zstandard compression level; default is 4L.
  # Shuffle        Enable byte shuffling; default is TRUE.
  # Overwrite      Allow replacement of an existing .qs2 file; default is TRUE.
  # OUTPUT
  # FilePath       Full saved path, returned invisibly.
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  # DETAILS
  # An explicit .qs suffix is replaced by .qs2; legacy files are never written.
  # Date: 2026-10-18

  if(!is.character(FileName) || length(FileName) != 1L || is.na(FileName))
    stop("FileName must be one non-missing string")
  if(!requireNamespace("qs2", quietly=TRUE)) stop("Install the qs2 package to write .qs2 files")
  if(!dir.exists(OutDirectory)) stop("OutDirectory does not exist")
  if(!is.logical(Overwrite) || length(Overwrite) != 1L || is.na(Overwrite))
    stop("Overwrite must be TRUE or FALSE")
  if(!is.null(Names)) {
    if(!is.list(Data) || length(Names) != length(Data) || anyNA(Names) || anyDuplicated(Names))
      stop("Names must contain one unique non-missing name per list element")
    names(Data) = Names
  }
  # qs and qs2 are different formats; never put new-format bytes in a .qs file.
  FileName = sub("\\.qs$", ".qs2", FileName, ignore.case=TRUE)
  if(!grepl("\\.qs2$", FileName, ignore.case=TRUE)) FileName = paste0(FileName, ".qs2")
  path = file.path(normalizePath(OutDirectory, mustWork=TRUE), FileName)
  if(file.exists(path) && !Overwrite) stop("Output already exists: ", path)
  qs2::qs_save(Data, path, compress_level=Compress_level, shuffle=Shuffle, nthreads=NThreads)
  invisible(path)
}
