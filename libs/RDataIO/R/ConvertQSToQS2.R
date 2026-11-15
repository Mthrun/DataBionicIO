ConvertQSToQS2 = function(FileName, InDirectory=getwd(), OutDirectory=InDirectory,
                         NThreads=1, Strict=TRUE, Overwrite=FALSE){
  # FilePath = ConvertQSToQS2(FileName)
  # Converts one legacy qs file to qs2 while retaining the original qs file.
  #
  # INPUT
  # FileName       Legacy file name, with or without .qs.
  # OPTIONAL
  # InDirectory    Directory containing the legacy file; default is getwd().
  # OutDirectory   Destination directory; default is InDirectory.
  # NThreads       Reader/writer threads; default is 1.
  # Strict         Validate the legacy checksum; default is TRUE.
  # Overwrite      Replace an existing .qs2 file; default is FALSE.
  # OUTPUT
  # FilePath       Path of the converted .qs2 file, invisibly.
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  # DETAILS
  # Accepts legacy lists of matrices, read in the current R process.
  # Uses the per-session daily warning from ReadQS(). The source file is never
  # deleted. A temporary destination file avoids publishing incomplete output.
  # Date: 2026-10-18

  if(!is.character(FileName) || length(FileName) != 1L || is.na(FileName))
    stop("FileName must be one non-missing string")
  if(grepl("\\.qs2$", FileName, ignore.case=TRUE)) stop("Input must be a legacy .qs file")
  if(!grepl("\\.qs$", FileName, ignore.case=TRUE)) FileName = paste0(FileName, ".qs")
  if(!requireNamespace("qs2", quietly=TRUE)) stop("Install the qs2 package before converting files")
  if(!is.logical(Overwrite) || length(Overwrite) != 1L || is.na(Overwrite)) stop("Overwrite must be TRUE or FALSE")
  out = normalizePath(OutDirectory, mustWork=TRUE)
  target = file.path(out, sub("\\.qs$", ".qs2", basename(FileName), ignore.case=TRUE))
  if(file.exists(target) && !Overwrite) stop("Output already exists: ", target)
  DataV = ReadQS(FileName, InDirectory, NThreads, Strict)
  temporary = tempfile(".DataIO-convert-", tmpdir=out, fileext=".qs2")
  on.exit(unlink(temporary), add=TRUE)
  qs2::qs_save(DataV, temporary, nthreads=NThreads)
  # Recheck before publishing in case another conversion created the target meanwhile.
  if(file.exists(target) && !Overwrite) stop("Output already exists: ", target)
  if(.Platform$OS.type == "windows" && file.exists(target)) {
    if(!file.copy(temporary, target, overwrite=TRUE)) stop("Could not replace: ", target)
  } else if(!file.rename(temporary, target)) stop("Could not publish: ", target)
  invisible(target)
}
