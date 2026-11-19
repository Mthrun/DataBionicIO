# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Execute help examples against the isolated package and verify documented fields.
test_library <- Sys.getenv("DATAIO_TEST_LIBRARY")
if (nzchar(test_library)) .libPaths(c(test_library, .libPaths()))
library(DataBionicIO)
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
root <- dirname(dirname(dirname(normalizePath(script))))
topics <- c("ReadDates", "WriteDates", "ReadNAMES", "ReadLRN", "WriteLRN",
            "ReadTXT2DATA", "DataIO-text-formats")
for (topic in topics) {
  rd <- tools::parse_Rd(file.path(root, "libs/RDataIO/man", paste0(topic, ".Rd")))
  findings <- tools::checkRd(rd)
  if (length(findings)) stop(paste(capture.output(print(findings)), collapse = "\n"))
  if (topic %in% c("ReadDates", "WriteDates")) {
    example_file <- tempfile(fileext = ".R")
    tools::Rd2ex(rd, out = example_file)
    sys.source(example_file, envir = new.env(parent = globalenv()))
    unlink(example_file)
  }
}
local({
  directory <- tempfile("dataio-doc-fields-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  writeLines(c('#<?names version="2.0"?>', '# Example.', '% 2', '% 3',
               '% Key\tNames\tGroup', '11\tA\talpha', '12\tB\tNA'),
             file.path(directory, "labels.names"))
  value <- ReadNAMES("labels", InDirectory = directory, Verbose = FALSE)
  stopifnot(setequal(names(value), c("Key", "Names", "FurtherTexts", "Header", "Comments")),
            identical(value$Header, "Group"), is.matrix(value$FurtherTexts),
            identical(dim(value$FurtherTexts), c(2L, 1L)),
            identical(value$FurtherTexts[, 1], c("alpha", NA_character_)),
            identical(value$Comments, "Example."))
  # Type 0 is metadata. The reader must not silently remove its data column.
  writeLines(c('#<?lrn version="2.0"?>', '% 1', '% 3', '% 9\t0\t1',
               '% Key\tExcluded\tValue', '11\t7\t1.5'),
             file.path(directory, "types.lrn"))
  numeric_value <- ReadLRN("types", InDirectory = directory, Verbose = FALSE)
  stopifnot(identical(numeric_value$DataDefined, c(9L, 0L, 1L)),
            identical(numeric_value$Header, c("Excluded", "Value")),
            identical(dim(numeric_value$Data), c(1L, 2L)),
            identical(as.numeric(numeric_value$Data), c(7, 1.5)))
})
cat("R documentation, examples and result fields passed.\n")
