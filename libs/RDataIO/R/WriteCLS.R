WriteCLS <- function(FileName, Cls, OutDirectory=getwd(), Key=NULL, Comment=NULL, Int4NaN = NULL, Overwrite = TRUE, Verbose = TRUE){

# WriteCLS(FileName,Cls)
# Write CLS file
#
# INPUT
# FileName                 name of the  file to be written
# Cls (1:n)                Integer class vector, one-column matrix/data frame, or two columns Key and Cls.
#                          An explicit Key overrides the first column of a two-column input.
# OPTIONAL
# OutDirectory             the directory where to write into; if not given: current dir.
# Key (1:n)                Unique whole-number keys in an ordinary numeric or integer vector.  Default 1:n
#                          Keys must be finite whole numbers within +/- 2^53. bit64::integer64 is not accepted.
# Comment                  Vector, Char Array or matrix, these lines will be inserted at top of file with leading #. Default is no comment.
# Int4NaN                  An integer value, which is used to replace NaN values. Default is to keep NaN values 
# Overwrite                Boolean indicating if file should be overwritten. Default is TRUE
# Verbose                  Logical flag for information messages; warnings remain active.
#
# OUTPUT
# A format 2.0 CLS file with keys, classes, and comments.
# Returns NULL invisibly through the native writer.
#
# author: Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects) 05/2024
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
# Reimplemented from the original R function WriteCLS by Michael Thrun.

  if(!is.character(FileName)) {
    stop("FileName has to be character/string")
  } else {
      invalid_chars = "[/\\\\:*?\"<>|]"
    if (grepl(invalid_chars, FileName)) {
      message(paste("FileName", FileName, "contains invalid symbol. The symbols / \\ : * ? \" < > | are invalid for a file name. Will remove them"))
      FileName = gsub(invalid_chars, "", FileName)
    }
  }
  
  if(!is.character(FileName)) {
    stop("Filename has to be a character/string")
  }

  if(!is.character(OutDirectory)) {
    stop("OutDirectory has to be a character/string")
  }

  if(!is.logical(Overwrite)) {
    stop("Error: Overwrite has to be logical")
  }
  if(!is.logical(Verbose)) {
    stop("Error: Verbose has to be logical")
  }

  OutDirectory = normalizePath(OutDirectory, mustWork = FALSE)

  path = file.path(OutDirectory, FileName)

  if(missing(Key)) {
    Key = NULL
  }

  
  if(!is.null(Comment) && !is.character(Comment)) {
    Comment = as.character(Comment)
  } else if (is.null(Comment)){
    Comment = ""
  }
  
  if (is.data.frame(Cls) || is.matrix(Cls)) {
    # Single-index matrix access selected cells and data-frame access kept lists.
    # Select whole columns; an explicit Key takes precedence over the first column.
    if(ncol(Cls) == 2L) {
      if(is.null(Key)) Key = Cls[, 1L]
      Cls = Cls[, 2L]
    } else if(ncol(Cls) == 1L) {
      Cls = Cls[, 1L]
    } else {
      stop("Cls must have one class column or two columns containing Key and Cls")
    }
  }
  # The old 32-bit limit rejected large keys. Use the exact double range; check before the C++ cast.
  if(!is.null(Key) && (!is.numeric(Key) || is.complex(Key) || inherits(Key, "integer64") || anyNA(Key) ||
      any(!is.finite(Key) | Key != trunc(Key) | abs(Key) > 2^53))) {
    stop("Key must contain finite integer values between -2^53 and 2^53")
  }
  if (!is.numeric(Cls)) { 
    stop("Cls has to be numeric!")
  }

  
  if(is.null(Int4NaN) || !is.numeric(Int4NaN)) {
    Int4NaN = NaN
  }

  write_cls(Cls, Key, Int4NaN, path, Comment, overwrite = Overwrite, verbose = Verbose) 
  
}