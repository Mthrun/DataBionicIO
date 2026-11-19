WriteLRN = function(FileName, Data, Header=NULL, Key=NULL, DataDefined=NULL, OutDirectory=getwd(),  Comments=NULL, SignificantDigits = NULL, DecimalDigits = NULL, Scientific = FALSE, Overwrite = TRUE, Verbose = TRUE) {
  # WriteLRN(FileName,Data,Header);
  # Write LRN file
  #
  # INPUT
  # FileName                 name of the  file to be written
  # Data (1:n,1:d)           Numeric matrix; may contain NA or NaN.
  #                          Data frames are converted with a warning using as.matrix(), then mode(Data) = "numeric".
  #                          The caller is responsible for preparing values for this conversion.
  # OPTIONAL
  # Header (1:d) or (1:d+1)  Column names, if (1:d), then column names for Data, if (1:d+1) first entry has to be "Key", or else it will be overwritten to be "Key".
  #                          Other nonempty header lengths are rejected before writing.
  #                          Remove spaces, tabs, commas, and semicolons from labels with a warning.
  #                          Labels must not become empty. Line breaks are not accepted.
  #                          If not given will create column names of the form "Key", "C1", "C2", ...   
  # Key (1:n)                Unique whole-number keys in an ordinary numeric or integer vector. Default 1:n
  #                          If Key is omitted or empty, use 1:n and warn, also with Verbose=FALSE.
  #                          Keys must be finite whole numbers within +/- 2^53. bit64::integer64 is not accepted.
  # DataDefined (1:d) or (1:d+1)  Vector of column type: keys(0=ignore,1=data,2,3=class,9=key), default is only 1's with leading 9. If d+1 first entry has to be 0 for key or it will
  #                          be overwritten. 
  # Comments                 Vector, Char Array or matrix, these lines will be inserted at top of file with leading #. Default is no comment.
  # SignificantDigits        One finite positive integer, at most .Machine$integer.max; redundant decimal zeros are omitted.
  # DecimalDigits            One finite non-negative integer, at most .Machine$integer.max; zero rounds to whole numbers.
  # Scientific               Flag wheather to use scientific notation, (Default: FALSE)
  # OutDirectory             the directory where to write into; if not given: current dir.
  # Overwrite                Boolean indicating if file should be overwritten. Default is TRUE
  # Verbose                  Logical flag for information messages; warnings remain active.
  #
  # OUTPUT
  # A format 2.0 LRN file with keys, column types, labels, and values.
  # Returns NULL invisibly through the native writer.
  #
  # author: Luca Brinkmann (IAP-GmbH Intelligent Analytics Projects) 05/2024
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  # Reimplemented from the original R function WriteLRN by Michael Thrun.



  # Direct factor coercion wrote level codes; convert data frames through their labels.
  if(is.data.frame(Data)) {
    warning("Data should be a numeric matrix; converting the data frame using as.matrix() and numeric mode")
    Data = as.matrix(Data)
    mode(Data) = "numeric"
  }
  # Reject unsupported inputs instead of attempting the old per-element coercion.
  if(!is.matrix(Data) || mode(Data) != "numeric") {
    stop("Data has to be a numeric matrix")
  }

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
  
  if(missing(Header)){
    if(!is.null(colnames(Data))){
      Header = colnames(Data)
    }else{
      Header = NULL
    }
  }      
  
  # A short header made C++ discard data columns; reject a mismatched schema before writing.
  if(length(Header) > 0L && !(length(Header) %in% c(ncol(Data), ncol(Data) + 1L))) {
    stop("Header must have one name per data column, optionally preceded by the key name")
  }
  # A full header with a different key name added a spurious data column in C++.
  # The R API identifies a full header by matrix width and names its first entry Key.
  if(length(Header) == ncol(Data) + 1L) Header[1L] = "Key"

  if(length(Key) == 0) {
    # The default key was silent with Verbose=FALSE. Warn and keep every row.
    warning("Key was not supplied. Using 1:n. Supply Key to keep row identifiers stable.", call. = FALSE)
    Key = seq_len(nrow(Data))
  }

  # The old 32-bit limit rejected large keys. Use the exact double range; check before the C++ cast.
  if(!is.null(Key) && (!is.numeric(Key) || is.complex(Key) || inherits(Key, "integer64") || anyNA(Key) ||
      any(!is.finite(Key) | Key != trunc(Key) | abs(Key) > 2^53))) {
    stop("Key must contain finite integer values between -2^53 and 2^53")
  }
  

  if(length(DataDefined) == 0) {
    DataDefined = NULL
  }
  
  if(is.null(Comments) && !is.character(Comments)) {
    Comments = ""
  }

  # The old && checks let invalid precision reach Rcpp's integer conversion.
  # Validate each supplied setting before installing the internal -1 defaults.
  valid_digits = function(x, minimum) {
    # Check an integer precision setting before conversion to C++.
    #
    # INPUT
    # x        Candidate numeric scalar.
    # minimum  Inclusive lower bound for the setting.
    #
    # OUTPUT
    # TRUE for a finite whole number from minimum to .Machine$integer.max.
    # FALSE for other values, lengths, or types.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    is.numeric(x) && !is.complex(x) && length(x) == 1L && is.finite(x) &&
      x >= minimum && x <= .Machine$integer.max && x == trunc(x)
  }
  if(!is.null(SignificantDigits) && !valid_digits(SignificantDigits, 1)) {
    stop("SignificantDigits has to be one finite positive integer, at most .Machine$integer.max")
  }
  if(!is.null(DecimalDigits) && !valid_digits(DecimalDigits, 0)) {
    stop("DecimalDigits has to be one finite non-negative integer, at most .Machine$integer.max")
  }
  if(is.null(SignificantDigits)) SignificantDigits = -1
  if(is.null(DecimalDigits)) DecimalDigits = -1

  if(!is.logical(Scientific)) {
    stop("Scientific has to be a logical value!")
  }
  
  if(!is.logical(Overwrite)) {
    stop("Overwrite has to be a logical value!")
  }
  if(!is.logical(Verbose)) {
    stop("Error: Verbose has to be logical")
  }
  
  write_lrn(Data, Header, Key, DataDefined, path, Comments, SignificantDigits, DecimalDigits, Scientific, overwrite = Overwrite, verbose = Verbose) 
}
  
  