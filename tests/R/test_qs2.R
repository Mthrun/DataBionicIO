# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

args <- commandArgs(trailingOnly = TRUE)
if (length(args)) .libPaths(c(normalizePath(args[1]), .libPaths()))
library(cdbt.DataIO)
stopifnot(requireNamespace("qs2", quietly = TRUE))
directory <- tempfile("DataIO-qs2-")
dir.create(directory)
value <- list(A = matrix(c(1, NA, NaN, Inf), 2), B = matrix(1:6, 3))
path <- WriteQS2("current", value, OutDirectory = directory)
before <- list.files(directory, all.files = TRUE)
stopifnot(identical(ReadQS2("current", directory, Strict = TRUE), value),
          identical(ReadQS("current", directory, Strict = TRUE), value),
          identical(list.files(directory, all.files = TRUE), before))
original <- readBin(path, "raw", n = file.info(path)$size)
result <- try(WriteQS2("current", list(), OutDirectory = directory, Overwrite = FALSE), silent = TRUE)
stopifnot(inherits(result, "try-error"), identical(readBin(path, "raw", n = file.info(path)$size), original))
# The old writing entry point must write the new format and use the correct suffix.
WriteQS("old-name.qs", value, OutDirectory = directory)
stopifnot(!file.exists(file.path(directory, "old-name.qs")),
          identical(ReadQS2("old-name", directory, Strict = TRUE), value))
unlink(directory, recursive = TRUE)
cat("QS2 read/write and overwrite checks passed.\n")
