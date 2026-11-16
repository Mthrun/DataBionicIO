# INPUT
# An isolated cdbt.DataIO test library and fixed numeric sequences.
# DATAIO_RUN_LEGACY_AUDIT=1 also checks the generated comparison grid.
# OUTPUT
# Assertions check the public Boolean comparison; no files are written.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

test_library <- Sys.getenv("DATAIO_TEST_LIBRARY")
if (nzchar(test_library)) .libPaths(c(test_library, .libPaths()))
library(cdbt.DataIO)
audit_option <- Sys.getenv("DATAIO_RUN_LEGACY_AUDIT", "0")
stopifnot(audit_option %in% c("0", "1"))
cases <- list(
  list(numeric(), numeric(), TRUE),
  list(NULL, numeric(), TRUE),
  list(numeric(), 1, FALSE),
  list(1:3, c(1, 2, 3), TRUE),
  list(1:3, c(1, 3, 2), FALSE),
  list(1:2, 1:3, FALSE),
  list(c(1, 1), c(1, 1), TRUE),
  list(c(1.5, -0), c(1.5, 0), TRUE),
  list(1, 1 + .Machine$double.eps, FALSE),
  list(c(-2^53, 2^53), c(-2^53, 2^53), TRUE),
  list(c(1, NA), c(1, NA), FALSE),
  list(NA_integer_, NA_integer_, FALSE),
  list(NA, NA, FALSE),
  list(NaN, NaN, FALSE),
  list(c(Inf, -Inf), c(Inf, -Inf), TRUE),
  list(Inf, -Inf, FALSE),
  list(c(TRUE, FALSE), c(1, 0), TRUE),
  list("1", 1, FALSE),
  list(factor("1"), 1, FALSE),
  list(matrix(1:4, 2), matrix(1:4, 2), FALSE),
  list(list(1), list(1), FALSE),
  list(as.Date("2024-01-01"), as.Date("2024-01-01"), FALSE)
)
for (case in cases) stopifnot(identical(TheSameKey(case[[1]], case[[2]]), case[[3]]))
key <- c(third = 3, first = 1, second = 2)
before <- key
stopifnot(identical(TheSameKey(key, unname(key)), TRUE), identical(key, before))
cat(length(cases) + 1L, "TheSameKey cases passed.\n")

# Check the original R implementation on ordinary numeric vectors.
# The fixed fixture retains its original error handler and missing-value behavior.
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
fixture <- file.path(dirname(normalizePath(script, mustWork = TRUE)),
                     "fixtures", "TheSameKey_original.R")
original <- new.env(parent = baseenv())
sys.source(fixture, envir = original)
comparisons <- 0L
if (audit_option == "1") {
  vectors <- list(numeric())
  for (n in 1:4) {
    grid <- expand.grid(rep(list(c(-1, 0, 1)), n), KEEP.OUT.ATTRS = FALSE)
    vectors <- c(vectors, lapply(seq_len(nrow(grid)), function(i) as.numeric(grid[i, ])))
  }
  for (a in vectors) for (b in vectors) {
    expected <- identical(a, b)
    stopifnot(identical(original$TheSameKey(a, b), expected),
              identical(TheSameKey(a, b), expected))
    comparisons <- comparisons + 1L
  }
  stopifnot(comparisons == 14641L)
} else {
  cat("Generated legacy comparison grid not selected; set DATAIO_RUN_LEGACY_AUDIT=1 to include it.\n")
}

# Check large identifiers, exact non-integer comparison, signed zero, and infinity.
boundary_cases <- list(
  list(c(-2^53, -2^31-1, 0, 2^31, 2^53-1, 2^53),
       c(-2^53, -2^31-1, 0, 2^31, 2^53-1, 2^53), TRUE),
  list(c(-2^53, 2^53-1), c(-2^53, 2^53), FALSE),
  list(c(2^53, -2^53), c(-2^53, 2^53), FALSE),
  list(c(1, 2, 3), c(4, 2, 3), FALSE),
  list(c(1, 2, 3), c(1, 4, 3), FALSE),
  list(c(1, 2, 3), c(1, 2, 4), FALSE),
  list(c(0.1, 1.5, -0, Inf), c(0.1, 1.5, 0, Inf), TRUE),
  list(1, 1 + .Machine$double.eps, FALSE)
)
for (case in boundary_cases) {
  stopifnot(identical(original$TheSameKey(case[[1]], case[[2]]), case[[3]]),
            identical(TheSameKey(case[[1]], case[[2]]), case[[3]]))
}

# Missing values now give FALSE instead of the original NA result.
missing_cases <- list(list(NA_integer_, NA_integer_), list(NA_real_, 1),
                      list(NaN, NaN), list(c(1, NA), c(2, NA)))
for (case in missing_cases) {
  stopifnot(identical(original$TheSameKey(case[[1]], case[[2]]), NA),
            identical(TheSameKey(case[[1]], case[[2]]), FALSE))
}

# The original er= handler does not handle ordinary R errors.
error_cases <- list(list(new.env(), new.env()), list(function() 1, function() 1),
                    list(list(1), list(1)))
for (case in error_cases) {
  old_result <- tryCatch(original$TheSameKey(case[[1]], case[[2]]), error = identity)
  stopifnot(inherits(old_result, "error"),
            identical(TheSameKey(case[[1]], case[[2]]), FALSE))
}

# Non-numeric inputs that the original comparison accepted are outside this API.
unsupported_cases <- list(list("1", 1), list(factor("1"), factor("1")),
                          list(matrix(1:4, 2), matrix(1:4, 2)),
                          list(1+1i, 1+1i))
for (case in unsupported_cases) {
  stopifnot(identical(original$TheSameKey(case[[1]], case[[2]]), TRUE),
            identical(TheSameKey(case[[1]], case[[2]]), FALSE))
}
cat(comparisons + length(boundary_cases), "comparisons with the original R function passed.\n")
cat(length(missing_cases) + length(error_cases) + length(unsupported_cases),
    "intentional behavior differences passed.\n")
