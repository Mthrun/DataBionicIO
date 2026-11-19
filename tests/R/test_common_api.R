# INPUT
# An isolated DataBionicIO test library and the shared interface contract.
# OUTPUT
# Assertions for names, positional arguments, fixed fields, and Chicago DST.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
args <- commandArgs(trailingOnly = TRUE)
if(length(args)) .libPaths(c(args[1], .libPaths()))
library(DataBionicIO)
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value=TRUE)[1])
root <- dirname(dirname(dirname(normalizePath(script))))
schema <- read.delim(file.path(root, 'tests/common_api.tsv'), stringsAsFactors=FALSE)
contract <- setNames(lapply(seq_len(nrow(schema)), function(i) list(inputs=strsplit(schema$Inputs[i], ',')[[1]], outputs=strsplit(schema$Outputs[i], ',')[[1]])), schema$Function)
for(name in names(contract)) stopifnot(identical(names(formals(get(name))), unlist(contract[[name]]$inputs)))
directory <- tempfile(); dir.create(directory)
local({
 on.exit(unlink(directory, recursive=TRUE))
 key <- c(11, 22)
 WriteLRN('matrix', matrix(c(7,8,1.5,2.5),2), c('Unused','Value'), key, c(0,1), directory, 'LRN', NULL, NULL, FALSE, FALSE, FALSE)
 WriteCLS('classes', c(2,3), directory, key, 'CLS', NULL, FALSE, FALSE)
 WriteNAMES('names', c('A','B'), key, matrix(c('x','y'),2), 'Group', directory, 'NAMES', FALSE, FALSE)
 instants <- as.POSIXct(c('2026-01-15 18:00:00','2026-07-15 17:00:00','2026-11-01 06:30:00','2026-11-01 07:30:00'),tz='UTC')
 WriteDates('times', data.frame(Time=instants,Value=1:4), 1:4, directory, 'DTS', 'America/Chicago', 2, FALSE, FALSE)
 for(reader in c('ReadLRN','ReadCLS','ReadNAMES','ReadDates')) {
  file <- c(ReadLRN='matrix',ReadCLS='classes',ReadNAMES='names',ReadDates='times')[[reader]]
  value <- get(reader)(file,directory,FALSE)
  stopifnot(identical(names(value),unlist(contract[[reader]]$outputs)))
 }
 value <- ReadLRN('matrix',directory,FALSE)
 stopifnot(identical(unname(value$Data),matrix(c(7,8,1.5,2.5),2)),identical(value$DataDefined,c(9L,0L,1L)))
 value <- ReadDates('times',directory,FALSE)
 stopifnot(identical(value$Timezone,'America/Chicago'),identical(value$DST,c('CST','CDT','CDT','CST')),identical(as.numeric(value$Time),as.numeric(instants)))
 WriteNAMES('empty',c('A','B'),Key=key,OutDirectory=directory,Verbose=FALSE)
 value <- ReadNAMES('empty',directory,FALSE)
 stopifnot(identical(names(value),unlist(contract$ReadNAMES$outputs)),identical(dim(value$FurtherTexts),c(2L,0L)),identical(value$Header,character()),identical(value$Comments,''))
 WriteDates('only-time',instants[1],Key=1,OutDirectory=directory,Verbose=FALSE)
 value <- ReadDates('only-time',directory,FALSE)
 stopifnot(identical(names(value),unlist(contract$ReadDates$outputs)),identical(dim(value$Data),c(1L,0L)),identical(value$Header,character()),identical(value$Comments,''))
})
cat('Common R API, positional arguments, fixed fields, and Chicago DST passed.\n')
