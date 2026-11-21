# OUTPUT
# Checks for UTF-8, legacy readers, exact optional arguments, and field replacement.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
args = commandArgs(TRUE)
library(DataBionicIO, lib.loc = args[1L])
source = if (length(args) > 1L) args[2L] else {
  script = sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
  file.path(dirname(script), "../encoding/fixtures")
}
directory = tempfile("dataio-encoding-")
dir.create(directory)
stopifnot(all(file.copy(list.files(source, full.names = TRUE), directory)))
failed = function(expression) inherits(tryCatch(force(expression), error = identity), "error")
for (kind in c("LRN", "CLS", "NAMES", "Dates")) {
  read = get(paste0("Read", kind), asNamespace("DataBionicIO"))
  ext = if (kind == "Dates") "dts" else tolower(kind)
  for (enc in c("utf-8-sig", "utf-16", "utf-32", "utf-16-be", "utf-32-be", "cp1252", "latin1")) {
    messages = character()
    options = if (enc == "cp1252") list(Encoding = "Windows-1252") else
      if (enc == "latin1") list(Encoding = "ISO-8859-1") else list()
    value = withCallingHandlers(do.call(read, c(list(paste0(enc, ".", ext), directory, FALSE), options)),
      warning = function(w) { messages <<- c(messages, conditionMessage(w)); invokeRestart("muffleWarning") })
    stopifnot(identical(value$Key, 17), length(messages) == as.integer(enc != "utf-8-sig"))
    stopifnot(grepl("Grüße", value$Comments, fixed = TRUE))
  }
  stopifnot(failed(read(paste0("invalid.", ext), directory, FALSE)))
  stopifnot(failed(read(paste0("sample.", ext), directory, FALSE, Encodin = "UTF-8")))
  stopifnot(failed(read(paste0("sample.", ext), directory, FALSE, "UTF-8")))
  stopifnot(failed(read(paste0("sample.", ext), directory, FALSE, Encoding = "UTF-8", Encoding = "UTF-8")))
}
names = c("Sample\tA", "A\r\nB", " café ", "e\u0301", "é", "🙂\ufeffX", "literal\\t")
extra = matrix(rep("X\nY", length(names)), ncol = 1)
original = extra
for (replacement in c("_", "[sep]", "🙂")) {
  messages = character()
  withCallingHandlers(WriteNAMES("r.names", names, Key = seq_along(names), FurtherTexts = extra,
    Header = c("Names", "Description"), OutDirectory = directory, Verbose = FALSE,
    TextReplacement = replacement), warning = function(w) {
      messages <<- c(messages, conditionMessage(w)); invokeRestart("muffleWarning")
    })
  stopifnot(length(messages) == 1L, grepl("Replaced 10 forbidden text characters in 9 fields", messages, fixed = TRUE))
  expected = names
  for (char in c("\t", "\r", "\n")) expected = gsub(char, replacement, expected, fixed = TRUE)
  value = ReadNAMES("r.names", directory, FALSE)
  stopifnot(identical(value$Names, expected), identical(extra, original))
}
path = file.path(directory, "r.names")
bytes = readBin(path, "raw", file.info(path)$size)
for (replacement in c("", "\t", "\r", "\n")) {
  stopifnot(failed(WriteNAMES("r.names", "A", Key = 1, OutDirectory = directory, TextReplacement = replacement)))
  stopifnot(identical(bytes, readBin(path, "raw", file.info(path)$size)))
}
latin = iconv("Grüße", from = "UTF-8", to = "latin1")
Encoding(latin) = "latin1"
WriteNAMES("latin-native.names", latin, Key = 1, OutDirectory = directory, Verbose = FALSE)
stopifnot(identical(ReadNAMES("latin-native.names", directory, FALSE)$Names, "Grüße"))
suppressWarnings(WriteNAMES("latin-replacement.names", "A\tB", Key = 1, OutDirectory = directory,
  Verbose = FALSE, TextReplacement = latin))
stopifnot(identical(ReadNAMES("latin-replacement.names", directory, FALSE)$Names, "AGrüßeB"))
unknown = rawToChar(as.raw(c(0x47, 0x72, 0xfc)))
Encoding(unknown) = "unknown"
stopifnot(failed(WriteNAMES("r.names", unknown, Key = 1, OutDirectory = directory, Verbose = FALSE)))
stopifnot(identical(bytes, readBin(path, "raw", file.info(path)$size)))
stopifnot(failed(WriteNAMES("r.names", "A\tB", Key = 1, OutDirectory = directory,
  Verbose = FALSE, TextReplacement = unknown)))
stopifnot(identical(bytes, readBin(path, "raw", file.info(path)$size)))
cat("R encoding and text policy checks passed for all four formats.\n")
unlink(directory, recursive = TRUE)
