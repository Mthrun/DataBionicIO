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
for(name in names(contract)) stopifnot(identical(setdiff(names(formals(get(name))), "..."), unlist(contract[[name]]$inputs)))
for(name in names(contract)) {
 defaults <- list(InDirectory=quote(getwd()), OutDirectory=quote(getwd()),
  Verbose=TRUE, Overwrite=TRUE, Scientific=FALSE, Key=NULL, Header=NULL,
  DataDefined=NULL, FurtherTexts=NULL, SignificantDigits=NULL, DecimalDigits=NULL,
  Int4NaN=NULL, Comment=NULL, Comments=if(name == 'WriteNAMES') '' else NULL,
  tz=NULL, Format=NULL)
 actual <- formals(get(name))
 for(argument in intersect(names(actual), names(defaults)))
  stopifnot(identical(actual[[argument]], defaults[[argument]]))
}
directory <- tempfile(); dir.create(directory)
local({
 previous <- getwd()
 on.exit({setwd(previous); unlink(directory, recursive=TRUE)})
 # Load the package first, then change directories before minimal calls.
 for(folder in c('first','second')) {
  working <- file.path(directory,folder); dir.create(working); setwd(working)
  times <- as.POSIXct(c('2026-01-01','2026-01-02'),tz='UTC')
  cases <- list(
   list('WriteLRN','ReadLRN','lrn',matrix(c(1,2),2),matrix(c(3.25,4.5),2),'Data',matrix(c(3.25,4.5),2)),
   list('WriteCLS','ReadCLS','cls',c(1,2),c(3,4),'Cls',c(3,4)),
   list('WriteNAMES','ReadNAMES','names',c('A','B'),c('C','D'),'Names',c('C','D')),
   list('WriteDates','ReadDates','dts',data.frame(Time=times,Value=c(1,2)),data.frame(Time=times,Value=c(3.25,4.5)),'Data',matrix(c(3.25,4.5),2)))
  for(case in cases) {
   writer <- get(case[[1]]); reader <- get(case[[2]])
   writer('defaults',case[[4]])
   writer('defaults',case[[5]])
   path <- file.path(working,paste0('defaults.',case[[3]]))
   stopifnot(file.exists(path))
   value <- reader('defaults')
   stopifnot(isTRUE(all.equal(unname(value[[case[[6]]]]),case[[7]],check.attributes=FALSE)),
    identical(as.numeric(value$Key),c(1,2)), identical(value$Comments,''))
   if(case[[3]] == 'dts') stopifnot(identical(value$Timezone,'UTC'))
   original <- readBin(path,'raw',file.info(path)$size)
   result <- try(writer('defaults',case[[4]],Overwrite=FALSE),silent=TRUE)
   stopifnot(inherits(result,'try-error'),identical(readBin(path,'raw',file.info(path)$size),original))
  }
 }
 setwd(previous)
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
cat('Common R API, defaults, current paths, overwrite protection, and Chicago DST passed.\n')
