# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Set DATAIO_TEST_LIBRARY to test an isolated build.
test_library <- Sys.getenv("DATAIO_TEST_LIBRARY")
if (nzchar(test_library)) .libPaths(c(test_library, .libPaths()))
library(cdbt.DataIO)
directory <- tempfile("dataio-key64-")
dir.create(directory)

keys <- c(1, 2147483647, 2147483648, -2147483648, 1234567890123,
          2^53 - 1, 2^53, -2^53)
write_file <- function(format, key, file) {
  n <- length(keys)
  if (format == "lrn") WriteLRN(file, matrix(1.23456, n, 1), Header = "Value",
    Key = key, OutDirectory = directory, SignificantDigits = 4, Verbose = FALSE)
  if (format == "cls") WriteCLS(file, rep(1, n), Key = key,
    OutDirectory = directory, Verbose = FALSE)
  if (format == "names") WriteNAMES(file, rep("sample", n), Key = key,
    OutDirectory = directory, Verbose = FALSE)
  if (format == "dts") WriteDates(file,
    data.frame(Time = rep(as.Date("2024-01-01"), n), Value = rep(1.23456, n)),
    Key = key, OutDirectory = directory, Verbose = FALSE)
}
read_file <- function(format, file) {
  reader <- switch(format, lrn = ReadLRN, cls = ReadCLS,
                   names = ReadNAMES, dts = ReadDates)
  reader(file, InDirectory = directory, Verbose = FALSE)
}
for (format in c("lrn", "cls", "names", "dts")) {
  file <- paste0("keys.", format)
  write_file(format, keys, file)
  stopifnot(identical(read_file(format, file)$Key, keys))
  path <- file.path(directory, file)
  original <- readBin(path, "raw", n = file.info(path)$size)

  # Reject invalid keys without changing an existing file.
  invalid <- list(2^53 + 2, -2^53 - 2, 1.25, NA_real_, Inf,
                  "123", factor("1"), structure(1, class = "integer64"))
  for (value in invalid) {
    result <- try(write_file(format, rep(value, length(keys)), file), silent = TRUE)
    stopifnot(inherits(result, "try-error"))
    stopifnot(identical(readBin(path, "raw", n = file.info(path)$size), original))
  }
  result <- try(write_file(format, rep(keys[3], length(keys)), file), silent = TRUE)
  stopifnot(inherits(result, "try-error"))

  text <- readLines(path, warn = FALSE)
  text <- sub("^2147483647\t", "2147483647oops\t", text)
  text <- sub("^2147483648\t", "\t", text)
  text <- sub("^1234567890123\t", "9007199254740993\t", text)
  text <- sub("^9007199254740991\t", "9223372036854775808\t", text)
  writeLines(text, path)
  messages <- capture.output(repaired <- read_file(format, file))
  expected <- keys
  expected[c(3, 5, 6)] <- NA_real_
  stopifnot(identical(repaired$Key, expected), any(grepl("WARNING", messages)))

  # Existing small integer inputs and generated keys must still work.
  write_file(format, seq_along(keys), file)
  stopifnot(identical(read_file(format, file)$Key, as.numeric(seq_along(keys))))
  write_file(format, NULL, file)
  stopifnot(identical(read_file(format, file)$Key, as.numeric(seq_along(keys))))
}

# The registered Rcpp entry point must also check keys before conversion.
result <- try(cdbt.DataIO:::write_cls(c(1, 2), c(1.5, 2), NaN,
  file.path(directory, "direct.cls"), "", TRUE, FALSE), silent = TRUE)
stopifnot(inherits(result, "try-error"), !file.exists(file.path(directory, "direct.cls")))
unlink(directory, recursive = TRUE)
cat("R 64-bit key tests passed for all four formats.\n")
