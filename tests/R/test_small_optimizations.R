# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Run with the test library path. An optional second argument saves comparison results.
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) .libPaths(c(normalizePath(args[1]), .libPaths()))
library(DataBionicIO)
directory <- tempfile("DataIO-small-optimizations-")
dir.create(directory)
results <- list()
record <- function(name, expr) {
  output <- capture.output(value <- force(expr))
  results[[name]] <<- list(value = value, output = output)
  value
}
record_file <- function(name) {
  path <- file.path(directory, name)
  text <- rawToChar(readBin(path, "raw", n = file.info(path)$size))
  # Only the generation timestamp can differ between builds.
  results[[name]] <<- substring(text, regexpr("\n", text, fixed = TRUE) + 1L)
}
fixture <- function(name, lines, ending = "\n") {
  con <- file(file.path(directory, name), "wb")
  writeBin(charToRaw(paste(lines, collapse = ending)), con)
  close(con) # The final line intentionally has no newline.
}

# Reused streams must retain every precision mode, exponent, and special value.
values <- c(1, 1.23456, 9.9996, 99.95, 120056, 0, -0, 0.00123456,
            Inf, -Inf, NaN, NA, 1e-310, -1e-310, 1.23456e-300,
            1.23456e300, .Machine$double.xmax, .Machine$double.xmin * .Machine$double.eps)
settings <- list(list(), list(SignificantDigits = 1), list(SignificantDigits = 4),
                 list(SignificantDigits = 17), list(DecimalDigits = 0),
                 list(DecimalDigits = 2), list(DecimalDigits = 308))
for (scientific in c(FALSE, TRUE)) {
  for (i in seq_along(settings)) {
    name <- paste0("round-", scientific, "-", i, ".lrn")
    record(paste0(name, "-write"), do.call(WriteLRN,
      c(list(FileName = name, Data = matrix(values, ncol = 1), Header = "Value",
             OutDirectory = directory, Scientific = scientific, Verbose = FALSE), settings[[i]])))
    record_file(name)
    result <- record(paste0(name, "-read"), ReadLRN(name, directory, Verbose = FALSE))
    stopifnot(nrow(result$Data) == length(values), all(is.nan(result$Data[11:12, 1])))
    if (i == 3L) {
      stopifnot(identical(as.numeric(result$Data[1:4, 1]), c(1, 1.235, 10, 99.95)))
      # One stays compact; scientific notation must keep the exponent zeros.
      first <- if (scientific) "1\t1e+00" else "1\t1"
      stopifnot(first %in% readLines(file.path(directory, name), warn = FALSE))
    }
    # DecimalDigits=0 must round to whole numbers in both notation modes.
    if (i == 5L) stopifnot(identical(as.numeric(result$Data[1:6, 1]), c(1, 1, 10, 100, 120056, 0)))
  }
}

# Missing fields must keep their warnings. Other text must keep prefix parsing.
tokens <- c("", "NA", "NaN", "nan", "NA ", " NA", "  ", "\v", "12oops",
            "3,4oops", "1.25e2tail", "Inf", "-Inf", "-0", "1e-310",
            "1e999", "1e-9999", "bad", "7")
for (ending in c("\n", "\r\n")) {
  suffix <- if (ending == "\n") "lf" else "crlf"
  for (format in c("lrn", "cls", "dts")) {
    name <- paste0("missing-", suffix, ".", format)
    body <- paste(seq_along(tokens), tokens, sep = "\t")
    if (format == "dts") body <- paste(seq_along(tokens), "2024-01-01", tokens, sep = "\t")
    extra <- if (format == "dts") "99\t2024-01-01\t5\textra" else "99\t5\textra"
    body <- c(body, "\t", "98", extra)
    header <- switch(format,
      lrn = c(paste("%", length(body)), "% 2", "% 9\t1", "% Key\tValue"),
      cls = paste("%", length(body)),
      dts = c(paste("%", length(body)), "% 3", "% Key\tTime\tValue"))
    fixture(name, c(header, body, ""), ending)
    reader <- switch(format, lrn = ReadLRN, cls = ReadCLS, dts = ReadDates)
    result <- record(name, reader(name, directory, Verbose = FALSE))
    data <- if (format == "cls") result$Cls else result$Data[, 1]
    stopifnot(length(data) == length(body), all(is.nan(data[1:8])),
              identical(as.numeric(data[9:11]), c(12, 3, 125)),
              data[19] == 7, tail(data, 1) == 5,
              length(results[[name]]$output) > 0)
    # A final empty field without a newline must also retain its row.
    fixture(name, c(header, body[-length(body)], "99\t"), ending)
    result <- record(paste0(name, "-empty-last"), reader(name, directory, Verbose = FALSE))
    stopifnot(length(result$Key) == length(body))
  }
}

# Integer counting must preserve string order, percentages, and NaN replacement.
classes <- c(2, 10, 1, 2, NaN, NA, -2, -10, 0, 2147483647, -2147483648, 10)
for (replacement in c(NaN, 1, -2147483648, Inf, 1.5)) {
  name <- paste0("counts-", replacement, ".cls")
  record(paste0(name, "-write"), WriteCLS(name, classes, OutDirectory = directory,
    Comment = "User comment", Int4NaN = replacement, Verbose = FALSE))
  record_file(name)
  result <- record(paste0(name, "-read"), ReadCLS(name, directory, Verbose = FALSE))
  stopifnot(length(result$Cls) == length(classes))
  labels <- sub("^#\t([^\t]+).*", "\\1", readLines(file.path(directory, name), warn = FALSE))
  labels <- labels[grepl("^(-?[0-9]+|NaN)$", labels)]
  stopifnot(identical(labels, sort(labels)))
}
record("all-missing-write", WriteCLS("all-missing", c(NA, NaN),
  OutDirectory = directory, Verbose = FALSE))
record_file("all-missing.cls")
stopifnot(all(is.nan(ReadCLS("all-missing", directory, Verbose = FALSE)$Cls)))
if (length(args) >= 2L) saveRDS(results, args[2])
unlink(directory, recursive = TRUE)
cat("Small optimization regression tests passed.\n")
