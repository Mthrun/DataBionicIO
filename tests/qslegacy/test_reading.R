# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Separate from text legacy tests so this support can be removed on its own.
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) .libPaths(c(normalizePath(args[1]), .libPaths()))
library(DataBionicIO)
stopifnot(requireNamespace("qslegacy", quietly = TRUE))
samples <- "tests/qslegacy/samples"
expected <- readRDS(file.path(samples, "expected.rds"))
stopifnot(is.list(expected), all(vapply(expected, is.matrix, logical(1))))
directory <- tempfile("DataIO-qslegacy-")
dir.create(directory)
for (name in c("matrices-zstd.qs", "matrices-lz4.qs"))
  stopifnot(file.copy(file.path(samples, name), directory))
before <- list.files(directory, full.names = TRUE, all.files = TRUE, no.. = TRUE)
hashes <- tools::md5sum(before)
working_directory <- getwd()
options(DataIO.qs.warning_day = NULL)
read_legacy <- function(name) {
  warnings <- character()
  value <- withCallingHandlers(ReadQS(name, directory, Strict = TRUE), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  stopifnot(identical(value, expected))
  warnings
}
warnings <- read_legacy("matrices-zstd.qs")
stopifnot(length(warnings) == 1L, grepl("save it as .qs2", warnings, fixed = TRUE),
          length(read_legacy("matrices-lz4.qs")) == 0L)
# Change only the in-memory marker; no disk marker or 24-hour wait is required.
options(DataIO.qs.warning_day = as.character(Sys.Date() - 1))
stopifnot(length(read_legacy("matrices-zstd.qs")) == 1L,
          identical(getwd(), working_directory),
          identical(list.files(directory, full.names = TRUE, all.files = TRUE, no.. = TRUE), before),
          identical(tools::md5sum(before), hashes))

if (requireNamespace("qs2", quietly = TRUE)) {
  output <- ConvertQSToQS2("matrices-zstd.qs", directory)
  stopifnot(identical(ReadQS2(basename(output), directory, Strict = TRUE), expected),
            identical(tools::md5sum(before), hashes))
  saved <- tools::md5sum(output)
  result <- try(ConvertQSToQS2("matrices-zstd.qs", directory), silent = TRUE)
  stopifnot(inherits(result, "try-error"), identical(tools::md5sum(output), saved))
} else cat("SKIP QS conversion: qs2 is not installed.\n")
unlink(directory, recursive = TRUE)
cat("Legacy QS matrix lists, daily warning, and read-only checks passed.\n")
