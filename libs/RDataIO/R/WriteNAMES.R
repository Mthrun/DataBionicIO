WriteNAMES = function(FileName, Names, Key, FurtherTexts, Header, OutDirectory=getwd(),
                      Comments = "", Overwrite = TRUE, Verbose = TRUE){   

  # WriteNames(FileName,Names,Key,FurtherTexts,Header);
  # Write Names file
  #
  # INPUT
  # FileName                 name of the  file to be written
  # Names (1:n)              Character vector. Values can start with digits and contain spaces or periods.
  # OPTIONAL
  # Key (1:n)                Unique whole-number keys in an ordinary numeric or integer vector.  Default 1:n
  #                          If Key is omitted or empty, use 1:n and warn, also with Verbose=FALSE.
  #                          Keys must be finite whole numbers within +/- 2^53. bit64::integer64 is not accepted.
  # FurtherTexts (1:d,1:n)   Character matrix or dataframe	
  # Header (1:d+1) or (1:d+2)  Column names, if (1:d+1), then column names for Names and FurtherTexts, if (1:d+2) first entry has to be "Key", or else it will be overwritten to be "Key".
  #                          Remove spaces, tabs, commas, and semicolons from labels with a warning.
  #                          Labels must not become empty. Line breaks are not accepted.
  #                          If not given will create column names of the form "Key", "C1", "C2", ...   
  # OutDirectory             the directory where to write into; if not given: current dir.
  # Comments                 Vector, Char Array or matrix, these lines will be inserted at top of file with leading #. Default is no comment.
  # Overwrite                Boolean indicating if file should be overwritten. Default is TRUE
  # Verbose                  Logical flag for information messages; warnings remain active.
  #
  # OUTPUT
  # A format 2.0 NAMES file with keys, names, and additional text.
  # Returns NULL invisibly through the native writer.
  #
  # author: Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects) 05/2024
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  # Reimplemented from the original R function WriteNAMES by Michael Thrun.
  
  if(!is.character(FileName)) {
    stop("FileName has to be character/string")
  } else {
      invalid_chars = "[/\\\\:*?\"<>|]"
    if (grepl(invalid_chars, FileName)) {
      message(paste("FileName", FileName, "contains invalid symbol. The symbols / \\ : * ? \" < > | are invalid for a file name. Will remove them"))
      FileName = gsub(invalid_chars, "", FileName)
    }
  }

  OutDirectory = normalizePath(OutDirectory, mustWork = FALSE)
  path = file.path(OutDirectory, FileName)

  if(!is.logical(Verbose)) {
    stop("Error: Verbose has to be logical")
  }
  
  if(is.null(Names)) {
    stop('WriteNAMES: Names input is missing!')
  }
  
  if(missing(FurtherTexts)) {
    FurtherTexts = NULL
  }
  
  if(!is.null(FurtherTexts)){ 
    if(!is.vector(FurtherTexts) && !is.matrix(FurtherTexts) && !is.data.frame(FurtherTexts)) {
      stop("FurtherTexts has to be a matrix/vector or data frame!")
    }
    if(!is.character(as.matrix(FurtherTexts))) stop("FurtherTexts must consist of Strings!")
  }
  
  if(missing(Header)){
    if(!is.null(colnames(FurtherTexts))){
      Header = colnames(FurtherTexts)
    }else{
      Header = NULL
    }
  }
  
  # A full header with a custom key name shifted labels and lost the last label.
  # Identify the key entry by column count, as in WriteLRN, and normalize its name.
  text_columns = if(is.null(FurtherTexts)) 0L else NCOL(FurtherTexts)
  if(length(Header) == text_columns + 2L) Header[1L] = "Key"

  if(missing(Key) || length(Key) == 0) {
    # The default key was silent with Verbose=FALSE. Warn and keep every row.
    warning("Key was not supplied. Using 1:n. Supply Key to keep row identifiers stable.", call. = FALSE)
    Key = seq_len(length(Names))
  }

  # The old 32-bit limit rejected large keys. Use the exact double range; check before the C++ cast.
  if(!is.null(Key) && (!is.numeric(Key) || is.complex(Key) || inherits(Key, "integer64") || anyNA(Key) ||
      any(!is.finite(Key) | Key != trunc(Key) | abs(Key) > 2^53))) {
    stop("Key must contain finite integer values between -2^53 and 2^53")
  }
  
  write_names(Names, FurtherTexts, Header, Key, path, Comments, overwrite = Overwrite, verbose = Verbose) 
  
}
