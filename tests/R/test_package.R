# OUTPUT
# Test results reported through assertions, errors, or the process exit status.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Basic contracts from the C++ and R work in this project.
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) .libPaths(c(normalizePath(args[1]), .libPaths()))
library(DataBionicIO)
stopifnot(identical(TrimHeader(c(" A_B  ", "C\t\r\n", NA_character_)),
                    c(" A B", "C", NA_character_)),
          identical(TrimHeader("A_B ", UnderlineReplacement = "[sep]"), "A[sep]B"),
          identical(TrimHeader(character()), character()))
directory <- tempfile("DataIO-basics-")
dir.create(directory)
expect_warning <- function(expr) {
  found <- FALSE
  value <- withCallingHandlers(force(expr), warning = function(w) {
    found <<- TRUE
    invokeRestart("muffleWarning")
  })
  stopifnot(found)
  value
}
bytes <- function(path) readBin(path, "raw", n = file.info(path)$size)
fails <- function(expr) stopifnot(inherits(tryCatch(force(expr), error = identity), "error"))
comment <- "Experiment\nSecond line"
keys <- c(10, 20, 30)
data <- matrix(c(1.25, NaN, -2.5, 0, 1e-310, Inf), ncol = 2)

# Each format must return the data, keys, and user comment that were written.
WriteLRN("data", data, Header = c("A", "B"), Key = keys,
         Comments = comment, OutDirectory = directory, Verbose = FALSE)
x <- ReadLRN("data", directory, Verbose = FALSE)
stopifnot(identical(unname(x$Data), data), identical(x$Key, keys),
          identical(x$Header, c("A", "B")), identical(x$Comments, comment))
WriteNAMES("names", c("1.0.4", "", "Sample A"), Key = keys,
           FurtherTexts = matrix(c("a,b;c", NA, "end"), ncol = 1),
           Header = c("Version", "Note"), Comments = comment,
           OutDirectory = directory, Verbose = FALSE)
x <- ReadNAMES("names", directory, Verbose = FALSE)
stopifnot(identical(x$Names, c("1.0.4", NA_character_, "Sample A")),
          identical(as.character(x$FurtherTexts[, 1]), c("a,b;c", NA, "end")),
          identical(x$Key, keys), identical(x$Comments, comment))
# A generation tag must not become part of the comment on a second write.
WriteNAMES("names-copy", x$Names, Key = keys, Comments = x$Comments,
           OutDirectory = directory, Verbose = FALSE)
stopifnot(identical(ReadNAMES("names-copy", directory, Verbose = FALSE)$Comments, comment))
WriteCLS("classes", c(2, 10, 2), Key = keys, Comment = comment,
         OutDirectory = directory, Verbose = FALSE)
x <- ReadCLS("classes", directory, Verbose = FALSE)
stopifnot(identical(as.numeric(x$Cls), c(2, 10, 2)), identical(x$Key, keys),
          identical(x$Comments, comment))
dates <- as.Date("2024-01-01") + 0:2
WriteDates("dates", data.frame(Time = dates, Value = c(1.25, NaN, 3)), Key = keys,
           Comments = comment, OutDirectory = directory, Verbose = FALSE)
x <- ReadDates("dates", directory, Verbose = FALSE)
stopifnot(identical(x$Time, dates), identical(as.numeric(x$Data), c(1.25, NaN, 3)),
          identical(x$Key, keys), identical(x$Comments, comment))
for (file in c("data.lrn", "names.names", "classes.cls", "dates.dts")) {
  path <- file.path(directory, file)
  stopifnot(grepl('version="2.0"', readLines(path, n = 1L), fixed = TRUE))
}

# R performs the agreed input conversion. Standalone factors are not numeric matrices.
frame <- data.frame(A = factor(c("20", "10")), B = c(1.25, 2.5))
expect_warning(WriteLRN("frame", frame, Key = 1:2, OutDirectory = directory, Verbose = FALSE))
stopifnot(identical(unname(ReadLRN("frame", directory, Verbose = FALSE)$Data),
                    matrix(c(20, 10, 1.25, 2.5), ncol = 2)))
fails(WriteLRN("factor", frame$A, OutDirectory = directory, Verbose = FALSE))
WriteDates("factor-dates", data.frame(Time = dates[1:2], Value = frame$A), Key = 1:2,
           OutDirectory = directory, Verbose = FALSE)
stopifnot(identical(as.numeric(ReadDates("factor-dates", directory, Verbose = FALSE)$Data), c(20, 10)))

# Both autumn instants have the same local clock time. The DST marker must distinguish them.
times <- as.POSIXct(c("2024-10-27 00:30:00", "2024-10-27 01:30:00"), tz = "UTC")
for (zone in c("UTC", "Europe/Berlin")) {
  WriteDates("time", times, Key = 1:2, tz = zone, OutDirectory = directory, Verbose = FALSE)
  x <- ReadDates("time", directory, Verbose = FALSE)
  stopifnot(identical(as.numeric(x$Time), as.numeric(times)), identical(x$Timezone, zone))
}

# Base R parsing preserves milliseconds, missing values, and mixed ISO lengths.
writeLines(c('#<?dates version="2.0"?>', '# Timezone: UTC', '% 4', '% 2',
             '% Key\tTime', '1\t2024-01-02 03:04:05.123', '2\tNA',
             '3\t2024-02-29', '4\t1970-01-01 00:00:00.001'),
           file.path(directory, 'parser.dts'))
x <- ReadDates('parser', directory, Verbose = FALSE)
expected <- c(1704164645.123, NA_real_, 1709164800, 0.001)
stopifnot(inherits(x$Time, 'POSIXct'), identical(is.na(x$Time), is.na(expected)),
          max(abs(as.numeric(x$Time) - expected), na.rm = TRUE) < 1e-6,
          !'fasttime' %in% names(getNamespaceImports('DataBionicIO')))

# Recovery keeps rows and the declared width, including the last empty text cell.
path <- file.path(directory, "short.names")
con <- file(path, "wb")
writeBin(charToRaw(paste(c('#<?names version="2.0"?>', "% 3", "% 3", "% Key\tNames\tNote",
                          "1\tAlice", "2\tBob\tx\textra", "3\t"), collapse = "\r\n")), con)
close(con)
output <- capture.output(x <- ReadNAMES("short", directory, Verbose = FALSE))
stopifnot(any(grepl("WARNING", output)), identical(x$Key, as.numeric(1:3)),
          identical(x$Names, c("Alice", "Bob", NA_character_)),
          identical(dim(x$FurtherTexts), c(3L, 1L)),
          identical(as.character(x$FurtherTexts[, 1]), c(NA, "x", NA)))

# Appending must update the count and retain the existing data and comments.
WriteLRN("append", matrix(1:9, ncol = 1), Header = "Value", Key = 1:9,
         Comments = comment, OutDirectory = directory, Verbose = FALSE)
Append2LRN("append", matrix(c(1.2345678901234567, NaN), ncol = 1), Key = 10:11, OutDirectory = directory)
x <- ReadLRN("append", directory, Verbose = FALSE)
stopifnot(identical(x$Key, as.numeric(1:11)), identical(x$Comments, comment),
          identical(as.numeric(x$Data), c(1:9, 1.2345678901234567, NaN)))
path <- file.path(directory, "append.lrn")
original <- bytes(path)
fails(Append2LRN("append", matrix(12), Key = 1, OutDirectory = directory))
stopifnot(identical(bytes(path), original))
fails(WriteLRN("append", matrix(12), Key = 12, Header = "Value", Overwrite = FALSE,
               OutDirectory = directory, Verbose = FALSE))
stopifnot(identical(bytes(path), original))

# Catch syntax errors in native R helpers and their separate help files too.
for (file in list.files("libs/RDataIO/R", pattern = "[.]R$", full.names = TRUE)) parse(file)
for (file in list.files("libs/RDataIO/man", pattern = "[.]Rd$", full.names = TRUE)) tools::parse_Rd(file)
stopifnot(all(c("ReadFCS", "ReadQS", "WriteQS2", "ConvertQSToQS2", "ReadData") %in%
              getNamespaceExports("DataBionicIO")))
unlink(directory, recursive = TRUE)
cat("Basic format, R conversion, date, append, and help checks passed.\n")
