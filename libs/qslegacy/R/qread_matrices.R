qread_matrices = function(file, strict=FALSE) {
  # DataV = qread_matrices(file)
  # Read a legacy qs list of matrices directly in the current R process.
  # INPUT
  # file       Existing legacy .qs file, including its path.
  # OPTIONAL
  # strict     Checksum/recorded-length mismatches are errors if TRUE, warnings otherwise.
  # OUTPUT
  # DataV      List of matrices, including names, dimensions and ordinary attributes.
  # DETAILS
  # Opens the input read-only. Never creates files, launches R, or installs packages.
  # Unsupported internal R objects and structurally damaged input produce errors.
  # Date: 2026-10-18
  if(!is.character(file) || length(file) != 1L || is.na(file))
    stop("file must be one non-missing string")
  if(!is.logical(strict) || length(strict) != 1L || is.na(strict))
    stop("strict must be TRUE or FALSE")
  .read_qs_matrices(enc2utf8(normalizePath(file, mustWork=TRUE)), strict)
}
