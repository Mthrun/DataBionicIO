# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Run: Rscript tests/legacy/test_readers.R <test-library> [sample-directory]
args <- commandArgs(TRUE)
if (length(args)) .libPaths(c(normalizePath(args[1]), .libPaths()))
library(cdbt.DataIO)
samples <- if (length(args) > 1L) args[2] else "tests/legacy/samples"
directory <- tempfile("DataIO-legacy-")
dir.create(directory)
read_file <- function(path) {
  reader <- switch(tools::file_ext(path), lrn = ReadLRN, cls = ReadCLS, names = ReadNAMES)
  messages <- capture.output(value <- reader(basename(path), dirname(path), Verbose = FALSE))
  list(value = value, messages = messages)
}
fixture <- function(name, lines, ending = "\n") {
  path <- file.path(directory, name)
  con <- file(path, "wb")
  writeBin(charToRaw(paste(lines, collapse = ending)), con)
  close(con) # Test a final row without a newline.
  path
}
same <- function(actual, expected) {
  stopifnot(isTRUE(all.equal(unname(actual), unname(expected), check.attributes = FALSE)))
}
fails <- function(path) {
  stopifnot(inherits(tryCatch(read_file(path), error = identity), "error"))
}

# Compare every value in the original MATLAB samples with an independent text read.
files <- list.files(samples, recursive = TRUE, full.names = TRUE)
stopifnot(length(files) == 9L)
for (path in files) {
  lines <- readLines(path, warn = FALSE)
  body <- lines[nzchar(lines) & !grepl("^[#%]", lines)]
  result <- read_file(path)$value
  format <- tools::file_ext(path)
  if (format == "names") {
    expected <- read.table(text = body, sep = "\t", header = FALSE, quote = "",
                           comment.char = "", colClasses = "character")
    same(result$Key, as.numeric(expected[, 1]))
    same(result$Names, expected[, 2])
    same(result$FurtherTexts, as.matrix(expected[, -(1:2), drop = FALSE]))
  } else {
    expected <- as.matrix(read.table(text = body, header = FALSE,
                                    na.strings = c("NaN", "?"), colClasses = "numeric"))
    if (format == "cls") {
      same(result$Key, expected[, 1]); same(result$Cls, expected[, 2])
      stopifnot(is.null(result$ClassColors))
    } else {
      metadata <- sub("^%[[:space:]]*", "", lines[startsWith(lines, "%")])
      types <- scan(text = metadata[3], quiet = TRUE)
      key <- which(types == 9)[1]
      data_columns <- if (is.na(key)) seq_len(ncol(expected)) else setdiff(seq_len(ncol(expected)), key)
      same(result$Key, if (is.na(key)) seq_len(nrow(expected)) else expected[, key])
      same(result$Data, expected[, data_columns, drop = FALSE])
      same(result$DataDefined, c(9, types[data_columns]))
    }
  }
}

for (ending in c("\n", "\r\n")) {
  # Move only the declared key. Missing cells and extra cells must not shift columns.
  path <- fixture("moved.lrn", c("% 4", "% 3", "% 1\t9\t1", "% Left\tID\tRight",
    "10\t\t30", "\t9007199254740992\t", "20", "21\t43\t31\textra"), ending)
  result <- read_file(path)
  same(result$value$Key, c(NA, 2^53, NA, 43))
  same(result$value$Data, matrix(c(10, NA, 20, 21, 30, NA, NA, 31), ncol = 2))
  same(result$value$Header, c("Left", "Right"))
  stopifnot(length(result$messages) > 0)

  path <- fixture("generated.lrn", c("% 3", "% 2", "% 1\t1", "% A\tB",
    "12oops\t3,4oops", "7", "\t"), ending)
  result <- read_file(path)
  same(result$value$Key, 1:3)
  same(result$value$Data, matrix(c(12, 7, NA, 3, NA, NA), ncol = 2))
  stopifnot(any(grepl("generating keys", result$messages)))

  path <- fixture("old.cls", c("# User comment", "10  2", "11  3oops", "12", "\t4", "13\t5\textra"), ending)
  result <- read_file(path)
  same(result$value$Key, c(10, 11, 12, NA, 13))
  same(result$value$Cls, c(2, 3, NA, 4, 5))
  stopifnot(any(grepl("no row-count header", result$messages)))

  for (metadata in list("% 2", c("% 2", "% Key\tNames\tNote"))) {
    path <- fixture("old.names", c(metadata, "1\tAlice\tleft right", "2\t\tNA\textra"), ending)
    result <- read_file(path)$value
    same(result$Key, 1:2); same(result$Names, c("Alice", NA))
    same(result$FurtherTexts, matrix(c("left right", NA), ncol = 1))
  }
}

# An explicit old version uses the same adapter. The old 9% typo is limited to LRN types.
path <- fixture("tagged.lrn", c('#<?lrn version="1.0"?>', "% 1", "% 2", "9%\t1", "% nr\tA", "7  2.5"))
same(read_file(path)$value$Data, matrix(2.5))

# Current files cannot bypass their header requirements through a legacy retry.
fails(fixture("bad.lrn", c('#<?lrn version="2.0"?>', "% 1", "% 2", "% 9\t1", "% nr\tA", "1\t2")))
fails(fixture("bad.lrn", c('#<?lrn version="2.0"?>', "% 1", "% 2", "% 1\t1", "% A\tB", "1\t2")))
fails(fixture("bad.cls", c('#<?cls version="2.0"?>', "1  2")))
fails(fixture("bad.names", c('#<?names version="2.0"?>', "% 1", "1\tAlice")))
fails(fixture("bad.names", c('#<?names version="2.0"?>', "% 1", "% Key\tNames", "1\tAlice")))
for (format in c("lrn", "cls", "names")) {
  fails(fixture(paste0("future.", format), c(paste0('#<?', format, ' version="3.0"?>'), "% 1", "1\t2")))
}
path <- fixture("current.cls", c('#<?cls version="2.0"?>', "% 1", "1  2"))
result <- read_file(path)
stopifnot(is.na(result$value$Cls[1]), length(result$messages) > 0)

# All normal writers still produce 2.0. Reading must not create side files.
WriteLRN("written", matrix(2.5), OutDirectory = directory, Verbose = FALSE)
WriteCLS("written", c(1, 2), OutDirectory = directory, Verbose = FALSE)
WriteNAMES("written", c("A", "B"), OutDirectory = directory, Verbose = FALSE)
for (format in c("lrn", "cls", "names")) {
  path <- file.path(directory, paste0("written.", format))
  stopifnot(grepl('version="2.0"', readLines(path, n = 1)))
  before <- list.files(directory, all.files = TRUE)
  read_file(path)
  stopifnot(identical(before, list.files(directory, all.files = TRUE)))
}
unlink(directory, recursive = TRUE)
cat("Legacy reader tests passed: nine original samples, row recovery, and version boundaries.\n")
