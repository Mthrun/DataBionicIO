WriteDates=function(FileName, TSdata, Key=c(), OutDirectory=getwd(), Comments=NULL, tz = NULL, Format = NULL, Overwrite = TRUE, Verbose = TRUE) {
  
  # WriteDates(FileName,TSData, key)
  # Write Dates file
  #
  # INPUT
  # FileName                 name of the  file to be written
  # TSdata (1:n,1:(d+1))     Dataframe or matrix of data n cases in rows, d variables in columns, may contain NaN (besides time column). Alternatively a vector of only time/datetime values can be provided.
  #                          Either first column should be time, or the column containing the times should be named "Time". As time input String, Date, POSIXt is accepted.
  #                          Measurement columns should be numeric; nonnumeric measurements use as.numeric(as.character(x)).
  #                          Invalid measurement values become NA with an R warning; the caller is responsible for preparing the input.
  # OPTIONAL
  # Key (1:n)                Unique whole-number keys in an ordinary numeric or integer vector.  Default 1:n
  #                          Keys must be finite whole numbers within +/- 2^53. bit64::integer64 is not accepted.
  # OutDirectory             the directory where to write into; if not given: current dir.
  # Comments                 Vector, Char Array or matrix, these lines will be inserted at top of file with leading #. Default is no comment.
  # tz                       A timezone as string, has to be one of the timezones defined in the return of the function OlsonNames()
  # Format                   Lengthens or shortens the dates/datetimes into a certain format. Integer between 1 and 3:
  #                          1: YYYY-MM-DD
  #                          2: YYYY-MM-DD hh:mm:ss
  #                          3: YYYY-MM-DD hh:mm:ss ms
  #                          Default is keeping the maximal found time resolution
  # Overwrite                Boolean indicating if file should be overwritten. Default is TRUE
  # Verbose                  Logical flag for information messages; warnings remain active.
  #
  # LIMITATIONS
  # Numeric TZ_DST abbreviations (e.g. +11, +1030, -02) are not supported for DATES round trips.
  # Affected zones include Australia/Lord_Howe (Australia/LHI), Pacific/Chatham (NZ-CHAT),
  # and historical DST dates in America/Sao_Paulo (Brazil/East). This list is not exhaustive;
  # support depends on the abbreviations for the actual dates, not only the zone name.
  # Use UTC for these timestamps when writing; date-only values do not need TZ_DST.
  #
  # OUTPUT
  # A format 2.0 DATES file with times, keys, and measurement columns.
  # Returns NULL invisibly through the native writer.
  #
  # author: Luca Brinkmann 05/2024
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  
  if(!is.character(FileName)) {
    stop("FileName has to be character/string")
  } else {
    invalid_chars = "[/\\\\:*?\"<>|]"
    if (grepl(invalid_chars, FileName)) {
      message(paste("FileName", FileName, "contains invalid symbol. The symbols / \\ : * ? \" < > | are invalid for a file name. Will remove them"))
      FileName = gsub(invalid_chars, "", FileName)
    }
  }
  if(length(Key) == 0) {
    Key = NULL;
  }
  # The old 32-bit limit rejected large keys. Use the exact double range; check before the C++ cast.
  if(!is.null(Key) && (!is.numeric(Key) || is.complex(Key) || inherits(Key, "integer64") || anyNA(Key) ||
      any(!is.finite(Key) | Key != trunc(Key) | abs(Key) > 2^53))) {
    stop("Key must contain finite integer values between -2^53 and 2^53")
  }
  if(is.null(Comments)) {
    Comments = ""
  }
  if(!is.character(Comments)) {
    stop("Error: Comments has to be a character String")
  }
  if(!is.logical(Overwrite)) {
    stop("Error: Overwrite has to be logical")
  }
  if(!is.character(OutDirectory)) {
    stop("Error: OutDirectory has to be a string")
  }
  if(!is.null(Format) && !is.numeric(Format)) {
    stop("Error: Format has to be a numeric value")
  } else if(!is.null(Format) && !(Format %in% c(1,2,3))) {
    stop("Error: Format has to be a integer between 1 and 3")
  } else if(is.null(Format)) {
    Format = -1
  }
  if(!is.data.frame(TSdata) && !is.matrix(TSdata)) {
    # Date/POSIXt vectors have a class, so is.vector alone incorrectly rejected them.
    if(is.vector(TSdata) || inherits(TSdata, c("Date", "POSIXt"))) {
      if(Verbose) message("Info: Vector instead of Matrix/Dataframe provided. Assuming this is a time/datetime vector only")
      TSdata =  data.frame(Time = TSdata)
    } else {
      stop("Error: TSdata has to be a dataframe or a matrix")
    }
  }
  
  # Matrix [[i]] selects a cell, not a column; normalize before column processing.
  if(is.matrix(TSdata)) TSdata = as.data.frame(TSdata, stringsAsFactors = FALSE)

  timeIndex = which(colnames(TSdata) == "Time")
  if(length(timeIndex) == 0) {
    timeIndex = 1
  }
  
  foundNonNumeric = FALSE
  for (i in seq_along(TSdata)) {
    if (i != timeIndex) {
      if(!is.numeric(TSdata[[i]])) {
        # Direct factor coercion wrote level codes; parse the displayed labels instead.
        TSdata[[i]] = as.numeric(as.character(TSdata[[i]]))
        foundNonNumeric = TRUE
      }
    }
  }
  if(foundNonNumeric && Verbose) message("Info: Tried to parse non-numeric data columns into numeric (except time)")
  
  
  datetimes = TSdata[[timeIndex]]
  
  if(any(is.nan(datetimes)) || any(is.na(datetimes))) {
    stop("Dates contain NaN or NA values")
  }
  
  getTimeZones = function(datetime) {
    # Read the time-zone attribute.
    #
    # INPUT
    # datetime  R object with an optional tzone attribute.
    #
    # OUTPUT
    # The tzone attribute, or NULL when the attribute is absent.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    return(attr(datetime, "tzone"))
  }
  
  
  if(!is.null(tz)) {
    if(!(tz %in% OlsonNames())) {
      stop("tz is not under the valid timezone names, defined by the function OlsonNames()")
    }
  }
  
  if(inherits(datetimes, "POSIXt") && !is.null(tz)) {
    tz_tmp = getTimeZones(datetimes[1])
    
    # A missing tzone made the comparison length zero; the explicit tz is authoritative.
    if(is.null(tz_tmp) || tz_tmp[1L] != tz) {
      attr(datetimes, "tzone") = tz
    }
    
    Comments = paste0("Timezone: ", tz, "\n", Comments)
  } else if(inherits(datetimes, "Date") && !is.null(tz)) {
    # This should have no effect, since if datetimes Date object, they have per default UTC and
    # maximal offset to UTC is +-14h => changing timezone in this case can not result in another date
    #datetimes = as.Date(datetimes, tz = tz)
    Comments = paste0("Timezone: ", tz, "\n", Comments)
  } else if(!is.null(tz)) {
    Comments = paste0("Timezone: ", tz, "\n", Comments)
  } else if(is.null(tz)) {
    # Use lapply and do.call to account for NULL values
    # POSIXct vectors are only allowed on timezone, or else it will be dropped. 
    # This means we only have to checck the first element for tz. For strings will be
    # NULL or "" either way.
    tz_tmp = getTimeZones(datetimes[1])
    
    #tzs = do.call(c, lapply(datetimes, FUN = getTimeZones))
    if(!is.null(tz_tmp) && tz_tmp != "") {
      Comments = paste0("Timezone: ", tz_tmp, "\n", Comments)
      tz = tz_tmp
    } else {
      Comments = paste0("Timezone: ", "UTC", "\n", Comments)
      tz = "UTC"
    }
  }
  
  
  if(inherits(datetimes, "POSIXt")) {
    tmp = as.POSIXlt(datetimes, tz = tz)
    # Fixed 2024 probes omitted historical DST. Use the input dates and their abbreviations.
    # Retain a marker for either occurrence of a repeated hour, even in a standard-time-only input.
    wall_time = lubridate::force_tz(as.POSIXct(tmp), tzone = "UTC")
    earlier = lubridate::force_tz(wall_time, tzone = tz, roll_dst = c("NA", "pre"))
    later = lubridate::force_tz(wall_time, tzone = tz, roll_dst = c("NA", "post"))
    if(any(tmp$isdst == 1L) || any(earlier != later, na.rm = TRUE)) {
      # Numeric abbreviations still fail in the C++ timestamp parser; see LIMITATIONS above.
      TSdata["DST"] = format(tmp, "%Z")
    }

  } else if(is.character(datetimes)) {
    datetimes = gsub("/", "-", datetimes)
  }
  
  TSdata[[timeIndex]] = as.character(datetimes)
  
  OutDirectory = normalizePath(OutDirectory, mustWork = FALSE)
  
  path = file.path(OutDirectory, FileName)
  write_dates(path, TSdata, Key, Format, Comments, Overwrite, Verbose, 2, 0);
}
