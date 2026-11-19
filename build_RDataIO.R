# OUTPUT
# Source archives for DataBionicIO and qslegacy in the selected output folder.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

message("Starting build process")

library(devtools)
library(Rcpp)
library(this.path)

if(!require(devtools)) {
  stop("Package build requires devtools package!")
}

if(!require(Rcpp)) {
  stop("Package build requires Rcpp package!")
}

if(!require(this.path)) {
  stop("Package build requires this.path package!")
}


# Resolve this checkout independently of its folder name.
data_IO_dir = normalizePath(this.dir(), mustWork = TRUE)
configured_dbt_path = get0(".pfad", ifnotfound = "")
dbt_path = NULL
if(is.character(configured_dbt_path) && length(configured_dbt_path) == 1L &&
   !is.na(configured_dbt_path) && nzchar(configured_dbt_path) &&
   dir.exists(configured_dbt_path)) {
  dbt_path = normalizePath(configured_dbt_path)
}

r_data_io_dir = paste0(data_IO_dir, "/libs/RDataIO")

if(!dir.exists(r_data_io_dir)) {
  stop("Could not locate RDataIO folder")
}

r_dataIO_src_dir = paste0(r_data_io_dir, "/src")

if(!dir.exists(r_dataIO_src_dir)) {
  stop("Could not locate RDataIO/src folder")
}


message("Compiling Rcpp exports")


rcpp_export_path = Rcpp::compileAttributes(pkgdir = r_data_io_dir)


#c_data_io_dir = paste0(data_IO_dir, "/libs/CDataIO")

c_data_io_dir = file.path(data_IO_dir, "libs/cDataIO")


if(!dir.exists(c_data_io_dir)) {
  stop("Could not locate CDataIO folder")
}

folders = list.dirs(c_data_io_dir, full.names = TRUE)

src_include_paths =  c(file.path(c_data_io_dir, "src"), file.path(c_data_io_dir, "include"))

if(all(src_include_paths %in% folders)) {
  files_to_copy = list.files(path = src_include_paths[1], pattern = "\\.cpp$|\\.hpp$", full.names = FALSE)
  new_locations = file.path(r_dataIO_src_dir, files_to_copy)
  files_to_copy = file.path(src_include_paths[1], files_to_copy)
  copied = file.copy(from = files_to_copy, to = r_dataIO_src_dir)
  files_to_delete = files_to_copy[copied]
  #files_to_copy <- list.files(path = tmp, pattern = "*.hpp")
  c_src_headers = file.path(src_include_paths[2], "DataIO")
  file.copy(from = c_src_headers, to = r_dataIO_src_dir , recursive = TRUE)
  r_src_headers = file.path(r_dataIO_src_dir, "DataIO")
} else {
  message("No CDataIO/src or CDataIO/include folder could be located")
}


if(is.null(dbt_path)) {
  message("Building package archives in the parent of the project folder")
  build_path = build(pkg = r_data_io_dir, path = dirname(data_IO_dir))
} else {
  message("Building R package archive in the configured output folder")
  build_path = build(pkg = r_data_io_dir, path = dbt_path)
}

# Build the read-only legacy helper separately; ReadQS never compiles it on demand.
legacy_build_path = build(pkg = file.path(data_IO_dir, "libs/qslegacy"), path = dirname(build_path))

message("Cleaning RDataIO/src up")

removed = file.remove(new_locations)
removed = file.remove(rcpp_export_path)
unlink(r_src_headers, recursive = TRUE)

message(paste("Finished build successfully!", build_path))


