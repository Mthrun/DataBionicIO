# INPUT
# Arguments: JSON requests, JSON results, isolated R library. Requires jsonlite.
# OUTPUT
# Native public-API observations and diagnostics; requested files are written.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args) == 3L)
.libPaths(c(normalizePath(args[3], mustWork=TRUE), .libPaths()))
library(DataBionicIO)
requests <- jsonlite::read_json(args[1], simplifyVector=FALSE)
num <- function(x) if (is.null(x)) NaN else as.numeric(x)
nums <- function(x) vapply(x, num, numeric(1))
txt <- function(x) if (is.null(x)) NA_character_ else as.character(x)
texts <- function(x) vapply(x, txt, character(1))
matrix_rows <- function(x, fun) {
  if (!length(x)) return(matrix(nrow=0L, ncol=0L))
  matrix(unlist(lapply(x,fun),use.names=FALSE), nrow=length(x), byrow=TRUE)
}
hex <- function(x) if (is.na(x)) 'NaN' else paste(format(writeBin(as.double(x), raw(), size=8L, endian='big')), collapse='')
hexs <- function(x) I(vapply(as.vector(x), hex, character(1)))
from_hex <- function(x) {
  if (x == 'NaN') return(NaN)
  bytes <- as.raw(strtoi(substring(x,seq(1,15,2),seq(2,16,2)),base=16L))
  readBin(bytes,'double',n=1L,size=8L,endian='big')
}
input_data <- function(q) {
  if (!is.null(q$data_bits)) return(matrix_rows(q$data_bits,function(row) vapply(row,from_hex,numeric(1))))
  matrix_rows(q$data,nums)
}
safe_text <- function(x) { x[is.na(x)] <- 'NA'; I(as.character(x)) }
rows <- function(x, fun) lapply(seq_len(nrow(x)), function(i) fun(x[i,,drop=TRUE]))
getopt <- function(q, name, default) if (is.null(q[[name]])) default else q[[name]]

observe <- function(q) {
  if (q$operation == 'helper') {
    a <- nums(q$a); b <- nums(q$other); olda <- a; oldb <- b
    value <- TheSameKey(a, b)
    return(list(value=value, immutable=identical(a,olda) && identical(b,oldb), native_type=typeof(value)))
  }
  filename <- basename(q$path); directory <- dirname(q$path)
  verbose <- getopt(q, 'verbose', FALSE)
  if (q$operation == 'write') {
    common <- list(FileName=filename, Key=nums(q$keys), OutDirectory=directory,
                   Verbose=verbose, Overwrite=getopt(q,'overwrite',TRUE))
    comment <- getopt(q,'comment','')
    options <- getopt(q,'options',list())
    if (q$format == 'lrn') {
      do.call(WriteLRN, c(common, list(Data=input_data(q), Header=texts(q$header), Comments=comment), options))
    } else if (q$format == 'cls') {
      if (!is.null(options$NaNReplacement)) {
        options$Int4NaN <- options$NaNReplacement; options$NaNReplacement <- NULL
      }
      do.call(WriteCLS, c(common,list(Cls=nums(q$classes),Comment=comment),options))
    } else if (q$format == 'names') {
      further <- if (length(q$further_texts[[1]]) == 0L) NULL else matrix_rows(q$further_texts,texts)
      do.call(WriteNAMES,c(common,list(Names=texts(q$names),FurtherTexts=further,Header=texts(q$header),Comments=comment)))
    } else if (q$format == 'dts') {
      d <- as.data.frame(input_data(q)); names(d) <- texts(q$header)
      d <- data.frame(Time=texts(q$times),d,check.names=FALSE)
      if (!is.null(q$native_epoch_ms))
        d$Time <- as.POSIXct(nums(q$native_epoch_ms)/1000,origin='1970-01-01',tz=q$timezone)
      do.call(WriteDates,c(common,list(TSdata=d,Comments=comment,tz=getopt(q,'timezone','UTC'),Format=getopt(q,'time_format',3L))))
    } else stop('Unknown format')
    return(list())
  }
  reader <- switch(q$format,lrn=ReadLRN,cls=ReadCLS,names=ReadNAMES,dts=ReadDates)
  a <- reader(filename,directory,Verbose=verbose)
  keys <- ifelse(is.na(a$Key),'NA',sprintf('%.0f',a$Key))
  out <- list(keys=I(keys),comment=if (is.null(a$Comments)) '' else a$Comments,
              native_comment_null=is.null(a$Comments))
  if (q$format %in% c('lrn','dts')) {
    out$data <- rows(a$Data,hexs); out$shape <- I(dim(a$Data)); out$header <- I(a$Header)
  }
  if (q$format == 'lrn') out$types <- I(a$DataDefined)
  if (q$format == 'cls') out$classes <- hexs(a$Cls)
  if (q$format == 'names') {
    out$names <- safe_text(a$Names); out$header <- I(as.character(a$Header))
    out$further_texts <- if (is.null(a$FurtherTexts)) rep(list(I(character())),length(a$Key)) else rows(a$FurtherTexts,safe_text)
  }
  if (q$format == 'dts') {
    out$timezone <- a$Timezone
    out$native_time_type <- paste(class(a$Time),collapse=',')
    if (inherits(a$Time,'Date')) out$dates <- I(format(a$Time,'%Y-%m-%d'))
    else out$epoch_ms <- I(ifelse(is.na(a$Time),'NA',sprintf('%.0f',round(as.numeric(a$Time)*1000))))
  }
  out
}

results <- lapply(requests, function(q) {
  diagnostics <- character()
  before_directory <- getwd()
  output <- capture.output(result <- withCallingHandlers(tryCatch(
    c(list(id=q$id,ok=TRUE), observe(q)),
    error=function(e) list(id=q$id,ok=FALSE,error=conditionMessage(e),error_type=class(e)[1])),
    warning=function(w) { diagnostics <<- c(diagnostics,conditionMessage(w)); invokeRestart('muffleWarning') }))
  result$diagnostics <- I(diagnostics); result$stdout <- paste(output,collapse='\n')
  result$working_directory_unchanged <- identical(getwd(),before_directory)
  result
})
jsonlite::write_json(results,args[2],auto_unbox=TRUE,pretty=TRUE,null='null')
