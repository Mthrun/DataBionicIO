# INPUT
# Command arguments: mode, exchange directory, isolated R library.
# Mode is generate, verify, verify-r-python, or verify-julia (Julia files only).
# OUTPUT
# Four R output files, or checks of files from R, Python, and MATLAB.
# Full verification writes r-verified.txt. A failed check stops execution.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L || !args[1] %in% c("generate", "verify", "verify-r-python", "verify-julia"))
  stop("Supply generate, verify, verify-r-python, or verify-julia; exchange directory; R library")
mode <- args[1]
out <- normalizePath(args[2], mustWork = TRUE)
.libPaths(c(normalizePath(args[3], mustWork = TRUE), .libPaths()))
library(cdbt.DataIO)
key <- c(-2^53, 2^31, 2^53)
values <- matrix(c(1.25, 10, NaN, -2.5, 3.75, 30), nrow = 3, byrow = TRUE)
classes <- c(2, NaN, 1)
names <- c("1.0.4", NA_character_, "M\u00fcnchen")
texts <- matrix(c("A1", "B1", NA, "B2", "A3", NA), nrow = 3, byrow = TRUE)
times <- c("2024-10-27 00:30:00.125", "2024-06-15 13:45:10.250", "2024-10-27 01:30:00.999")
comment <- "language exchange"
marker <- file.path(out, "r-verified.txt")
unlink(marker)

if (mode == "generate") {
  WriteLRN("r", values, Header = c("X", "Y"), Key = key,
           OutDirectory = out, Comments = comment, Verbose = FALSE)
  WriteCLS("r", classes, Key = key, OutDirectory = out,
           Comment = comment, Verbose = FALSE)
  WriteNAMES("r", names, Key = key, FurtherTexts = texts,
             Header = c("Names", "Extra1", "Extra2"), OutDirectory = out,
             Comments = comment, Verbose = FALSE)
  WriteDates("r", data.frame(Time = times, X = values[,1], Y = values[,2]),
             Key = key, OutDirectory = out, Comments = comment,
             tz = "UTC", Format = 3, Verbose = FALSE)
} else {
  writers <- if (mode == "verify-julia") "julia" else if (mode == "verify") c("r", "python", "matlab") else c("r", "python")
  for (writer in writers) {
    for (extension in c("lrn", "cls", "names", "dts")) {
      reader <- switch(extension, lrn = ReadLRN, cls = ReadCLS,
                       names = ReadNAMES, dts = ReadDates)
      actual <- reader(paste0(writer, ".", extension), out, Verbose = FALSE)
      stopifnot(identical(actual$Key, key), identical(actual$Comments, comment))
      if (extension %in% c("lrn", "dts")) {
        stopifnot(identical(dim(actual$Data), dim(values)),
                  identical(unname(is.na(actual$Data)), is.na(values)),
                  all(actual$Data[!is.na(values)] == values[!is.na(values)]),
                  identical(actual$Header, c("X", "Y")))
      }
      if (extension == "cls")
        stopifnot(identical(is.na(actual$Cls), is.na(classes)),
                  all(actual$Cls[!is.na(classes)] == classes[!is.na(classes)]))
      if (extension == "names")
        stopifnot(identical(actual$Names, names), identical(unname(actual$FurtherTexts), texts),
                  identical(actual$Header, c("Extra1", "Extra2")))
      if (extension == "dts") {
        expected <- as.POSIXct(times, format = "%Y-%m-%d %H:%M:%OS", tz = "UTC")
        stopifnot(identical(actual$Timezone, "UTC"),
                  identical(is.na(actual$Time), is.na(expected)),
                  all(abs(as.numeric(actual$Time[!is.na(expected)]) -
                          as.numeric(expected[!is.na(expected)])) < 1e-6))
      }
      cat("PASS", writer, "-> R:", extension, "\n")
    }
  }
  if (mode == "verify")
    writeLines("PASS: R verified all four formats from r, python, matlab.", marker)
}
