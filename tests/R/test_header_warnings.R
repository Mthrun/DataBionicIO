# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Run with the path to an isolated test library.
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) .libPaths(c(normalizePath(args[1]), .libPaths()))
library(cdbt.DataIO)
directory <- tempfile("DataIO-header-warnings-")
dir.create(directory)

observe <- function(expr) {
  warnings <- character()
  output <- capture.output(value <- withCallingHandlers(force(expr),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }))
  list(value = value, warnings = warnings, output = output)
}
has_warning <- function(result, text) {
  any(grepl(text, c(result$warnings, result$output), fixed = TRUE))
}
names <- c("1.0.4", "1.0.5", "1.0.5", "1", "1.0.1")
keys <- c(2147483648, 2, 3, 4, 5)
texts <- cbind(Currency = c("EUR", "USD", "GBP", "EUR", "CAD"),
               Country = c("DE", "US", "GB", "DE", "CA"))
text_header <- colnames(texts)

# Name values are text. The two header expressions have different lengths.
stopifnot(identical(paste("Version", text_header), c("Version Currency", "Version Country")),
          identical(c("Version", text_header), c("Version", "Currency", "Country")))
for (joined in c(FALSE, TRUE)) {
  header <- if (joined) paste("Version", text_header) else c("Version", text_header)
  result <- observe(WriteNAMES("versions", names, Key = keys, FurtherTexts = texts,
    Header = header, OutDirectory = directory, Verbose = FALSE))
  if (joined) stopifnot(has_warning(result, "Removed spaces, tabs, commas, or semicolons"),
                       has_warning(result, "Adding Names"))
  else stopifnot(!has_warning(result, "WARNING"), length(result$warnings) == 0L)
  read <- observe(ReadNAMES("versions", directory, Verbose = FALSE))
  stopifnot(identical(read$value$Names, names), identical(read$value$Key, keys),
            identical(unname(as.matrix(read$value$FurtherTexts)), unname(texts)),
            identical(as.character(read$value$Header), if (joined) gsub("[ \t,;]", "", header) else text_header))
}

# Filter only the specified header separators, including those in the last label.
labels <- c("Version Currency", "Version\tCurrency", "Amount, EUR; net", "1.0.4", "Price/EUR", "Größe", "tail ")
filtered <- gsub("[ \t,;]", "", labels)
for (format in c("names", "lrn")) {
  write <- function(header = labels, key = keys) {
    if (format == "names") WriteNAMES("labels", names, Key = key,
      FurtherTexts = matrix("text", length(names), length(labels) - 1L),
      Header = header, OutDirectory = directory, Verbose = FALSE)
    else WriteLRN("labels", matrix(seq_len(length(names) * length(labels)), nrow = length(names)),
      Key = key, Header = header, OutDirectory = directory, Verbose = FALSE)
  }
  read <- function() {
    if (format == "names") ReadNAMES("labels", directory, Verbose = FALSE)
    else ReadLRN("labels", directory, Verbose = FALSE)
  }
  written <- observe(write())
  stopifnot(has_warning(written, "Removed spaces, tabs, commas, or semicolons"),
            has_warning(written, "Keeping it unchanged"))
  result <- observe(read())
  stopifnot(has_warning(result, "Keeping it unchanged"),
            identical(as.character(result$value$Header), if (format == "names") filtered[-1L] else filtered))

  # Structural errors and invalid supplied keys must not replace an existing file.
  path <- file.path(directory, paste0("labels.", format))
  original <- readBin(path, "raw", n = file.info(path)$size)
  for (bad_label in c("A\nB", "A\rB", "", " \t,;")) {
    header <- labels
    header[2] <- bad_label
    stopifnot(inherits(try(write(header), silent = TRUE), "try-error"),
              identical(readBin(path, "raw", n = file.info(path)$size), original))
  }
  for (bad_key in list(c(1, 1, 3, 4, 5), 1:2, c(1, NA, 3, 4, 5))) {
    stopifnot(inherits(try(write(key = bad_key), silent = TRUE), "try-error"),
              identical(readBin(path, "raw", n = file.info(path)$size), original))
  }
}

# Missing, NULL, and empty keys must give one R warning, even with Verbose=FALSE.
for (format in c("names", "lrn")) {
  for (verbose in c(FALSE, TRUE)) {
    for (key_case in 1:3) {
      input <- list(FileName = "generated", Header = "Value",
                    OutDirectory = directory, Verbose = verbose)
      if (key_case == 2L) input["Key"] <- list(NULL)
      if (key_case == 3L) input["Key"] <- list(numeric())
      if (format == "names") {
        input$Names <- names
        written <- observe(do.call(WriteNAMES, input))
        result <- ReadNAMES("generated", directory, Verbose = FALSE)
      } else {
        input$Data <- matrix(seq_along(names), ncol = 1)
        written <- observe(do.call(WriteLRN, input))
        result <- ReadLRN("generated", directory, Verbose = FALSE)
      }
      stopifnot(length(written$warnings) == 1L,
                has_warning(written, "Supply Key"),
                !any(grepl("Supply Key", written$output, fixed = TRUE)),
                identical(result$Key, as.numeric(seq_along(names))))
    }
  }
}

# Separators in text values must not be filtered as if they were header labels.
text_values <- c("1.0.4", "Version Currency", "A,B;C", "  padded  ", "Price/EUR")
observe(WriteNAMES("text-values", text_values, Key = keys,
  FurtherTexts = matrix(text_values, ncol = 1), Header = c("Names", "Description"),
  OutDirectory = directory, Verbose = FALSE))
result <- ReadNAMES("text-values", directory, Verbose = FALSE)
stopifnot(identical(result$Names, text_values),
          identical(as.character(result$FurtherTexts[, 1]), text_values))

# The same NAMES label policy applies to an old file without a column count.
writeLines(c("% 1", "% Key\tVersion Currency\t1.0.4", "1\t1.0.5\tEUR"),
           file.path(directory, "old.names"))
result <- observe(ReadNAMES("old", directory, Verbose = FALSE))
stopifnot(has_warning(result, "Keeping it unchanged"),
          identical(result$value$Names, "1.0.5"), identical(as.character(result$value$Header), "1.0.4"))
unlink(directory, recursive = TRUE)
cat("Header and missing-key warning tests passed.\n")
