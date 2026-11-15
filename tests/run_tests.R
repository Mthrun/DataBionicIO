# OUTPUT
# An isolated test library, test logs, and a results.tsv status table.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Run from any directory: Rscript --vanilla /path/to/DataIO/tests/run_tests.R
# An optional argument selects an existing test library and skips package builds.
args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
setwd(root)
if (length(args) > 1L) stop("Supply at most one argument: an existing test library")
dir.create("build/tests", recursive = TRUE, showWarnings = FALSE)
run <- tempfile(paste0(format(Sys.time(), "%Y%m%d-%H%M%S"), "-"), tmpdir = "build/tests")
dir.create(run)
run <- normalizePath(run)
logs <- file.path(run, "logs")
dir.create(logs)
results <- data.frame(Test = character(), Result = character(), Detail = character())
record <- function(name, status, detail = "") {
  results[nrow(results) + 1L, ] <<- c(name, status, detail)
  write.table(results, file.path(run, "results.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  cat(status, name, if (nzchar(detail)) paste0(" - ", detail) else "", "\n")
}
run_command <- function(name, command, arguments) {
  log <- file.path(logs, paste0(name, ".log"))
  status <- tryCatch(system2(command, vapply(arguments, shQuote, character(1)),
                            stdout = log, stderr = log), error = function(e) {
    writeLines(conditionMessage(e), log)
    1L
  })
  record(name, if (status == 0L) "PASS" else "FAIL", basename(log))
  invisible(status == 0L)
}
windows <- .Platform$OS.type == "windows"
r <- file.path(R.home("bin"), if (windows) "R.exe" else "R")
rscript <- file.path(R.home("bin"), if (windows) "Rscript.exe" else "Rscript")
lib <- if (length(args)) normalizePath(args[1], mustWork = TRUE) else file.path(run, "library")
dir.create(lib, showWarnings = FALSE)
lib <- normalizePath(lib)
Sys.setenv(DATAIO_TEST_LIBRARY = lib)
writeLines(c(R.version.string, paste("Platform:", R.version$platform),
             paste("Source:", root), paste("Library:", lib),
             paste("Build current source:", !length(args))), file.path(run, "environment.txt"))
cat("Results:", run, "\n")

if (!length(args)) {
  dependencies <- c("Rcpp", "lubridate")
  missing <- dependencies[!vapply(dependencies, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    record("dependencies", "FAIL", paste("Install:", paste(missing, collapse = ", ")))
    quit(status = 1L)
  }
  # Build copies: tests must not install packages in the user's library or edit source files.
  stage <- file.path(run, "source")
  dir.create(stage)
  pkg <- file.path(stage, "cdbt.DataIO")
  dir.create(pkg)
  for (name in c("DESCRIPTION", "NAMESPACE", "LICENSE"))
    stopifnot(file.copy(file.path(root, "libs/RDataIO", name), pkg))
  for (sub in c("R", "man", "src")) {
    target <- file.path(pkg, sub)
    dir.create(target)
    files <- list.files(file.path(root, "libs/RDataIO", sub), full.names = TRUE)
    files <- files[file.info(files)$isdir == FALSE]
    stopifnot(all(file.copy(files, target)))
  }
  stopifnot(all(file.copy(list.files("libs/cDataIO/src", pattern = "[.]cpp$", full.names = TRUE),
                         file.path(pkg, "src"))))
  stopifnot(file.copy("libs/cDataIO/include/DataIO", file.path(pkg, "src"), recursive = TRUE))
  stopifnot(file.copy("libs/RDataIO/inst", pkg, recursive = TRUE))
  Rcpp::compileAttributes(pkg)
  if (!run_command("build-dataio", r, c("CMD", "INSTALL", "--preclean", paste0("--library=", lib), pkg)))
    quit(status = 1L)
  # Keep the QS companion and its tests separate from the text legacy readers.
  stopifnot(file.copy("libs/qslegacy", stage, recursive = TRUE))
  run_command("build-qslegacy", r, c("CMD", "INSTALL", "--preclean", paste0("--library=", lib),
                                   file.path(stage, "qslegacy")))
}
if (!file.exists(file.path(lib, "cdbt.DataIO", "DESCRIPTION"))) {
  record("test-library", "FAIL", "cdbt.DataIO is not installed in the selected library")
  quit(status = 1L)
}
.libPaths(c(lib, .libPaths()))
for (package in c("cdbt.DataIO", "qslegacy", "Rcpp", "lubridate", "qs2")) {
  version <- tryCatch(as.character(packageVersion(package)), error = function(e) "not installed")
  cat(package, version, "\n", file = file.path(run, "environment.txt"), append = TRUE)
}
tests <- c(basics = "tests/R/test_package.R", keys = "tests/R/test_key64.R",
           headers = "tests/R/test_header_warnings.R", numbers = "tests/R/test_small_optimizations.R",
           legacy = "tests/legacy/test_readers.R", documentation = "tests/R/test_documentation.R")
for (name in names(tests))
  run_command(name, rscript, c("--vanilla", file.path(root, tests[[name]]), lib))
if (requireNamespace("qs2", quietly = TRUE)) {
  run_command("qs2", rscript, c("--vanilla", file.path(root, "tests/R/test_qs2.R"), lib))
} else record("qs2", "SKIP", "qs2 is not installed")
if (file.exists(file.path(lib, "qslegacy", "DESCRIPTION"))) {
  run_command("qslegacy", rscript, c("--vanilla", file.path(root, "tests/qslegacy/test_reading.R"), lib))
} else record("qslegacy", "SKIP", "qslegacy is not installed in the selected library")

# These tests call the C++ API directly. The R tests above also run the shared C++ code.
cmake <- Sys.which("cmake")
ctest <- Sys.which("ctest")
if (nzchar(cmake) && nzchar(ctest)) {
  native <- file.path(run, "native")
  if (run_command("cpp-configure", cmake, c("-S", file.path(root, "tests"), "-B", native,
                                            "-DCMAKE_BUILD_TYPE=Release")) &&
      run_command("cpp-build", cmake, c("--build", native, "--config", "Release"))) {
    previous <- getwd()
    setwd(native)
    run_command("cpp-tests", ctest, c("-C", "Release", "--output-on-failure"))
    setwd(previous)
  }
} else record("cpp-tests", "SKIP", "CMake/CTest not found; C++ is tested through R")
record("matlab", "SKIP", "MATLAB tests are not part of this R test runner")
record("python", "SKIP", "Optional native binding test: see tests/README.md")
cat("\n", sum(results$Result == "FAIL"), "failed;", sum(results$Result == "SKIP"), "not run.\n")
cat("Report:", file.path(run, "results.tsv"), "\n")
quit(status = if (any(results$Result == "FAIL")) 1L else 0L)
