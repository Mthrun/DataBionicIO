# OUTPUT
# Reference data files and checks for the R/Python format comparison.
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.

# Shared fixtures for test_interop.py. Supply mode, directory, R test library.
args <- commandArgs(trailingOnly=TRUE)
mode <- args[1]
out <- normalizePath(args[2])
.libPaths(c(normalizePath(args[3]),.libPaths()))
library(cdbt.DataIO)
key <- c(1,2^31,2^53)
values <- matrix(c(1.25,10,NaN,-2.5,3.75,30),nrow=3,byrow=TRUE)
times <- c("2024-01-01 12:30:00.125","2024-06-15 13:45:10.250","2024-12-31 23:59:59.999")
texts <- matrix(c("A1","B1",NA,"B2","A3",NA),nrow=3,byrow=TRUE)
instants <- as.POSIXct(c("2024-10-27 00:30:00", "2024-10-27 01:30:00", "1995-07-01 12:00:00"),tz="UTC")
cases <- c("basic.lrn", "basic.cls", "basic.names", "basic.dts", "date-only.dts", "dst.dts", "header.lrn", "header.names", "digits.lrn")
if(mode == "generate") {
  WriteLRN("r-basic",values,Header=c("X","Y"),Key=key,OutDirectory=out,Comments="audit",Verbose=FALSE)
  WriteCLS("r-basic",c(2,NaN,1),Key=key,OutDirectory=out,Comment="audit",Verbose=FALSE)
  WriteNAMES("r-basic",c("1.0.4",NA,"Sample A"),Key=key,FurtherTexts=texts,Header=c("Names","Extra1","Extra2"),OutDirectory=out,Comments="audit",Verbose=FALSE)
  WriteDates("r-basic",data.frame(Time=times,X=values[,1],Y=values[,2]),Key=key,OutDirectory=out,Comments="audit",tz="UTC",Format=3,Verbose=FALSE)
  WriteDates("r-date-only",as.Date("2024-01-01")+0:2,Key=key,OutDirectory=out,Verbose=FALSE)
  WriteDates("r-dst",data.frame(Time=instants,X=c(1,2,3)),Key=key,tz="Europe/Berlin",OutDirectory=out,Verbose=FALSE)
  WriteLRN("r-header",values,Header=c("ID","X","Y"),Key=key,OutDirectory=out,Verbose=FALSE)
  WriteNAMES("r-header",c("1.0.4",NA,"Sample A"),Key=key,FurtherTexts=texts,Header=c("ID","Names","Extra1","Extra2"),OutDirectory=out,Verbose=FALSE)
  WriteLRN("r-digits",values,Header=c("X","Y"),Key=key,DecimalDigits=0,OutDirectory=out,Verbose=FALSE)
} else if(mode == "verify") {
  for(case in cases) {
    reader <- switch(tools::file_ext(case),lrn=ReadLRN,cls=ReadCLS,names=ReadNAMES,dts=ReadDates)
    expected <- reader(paste0("r-",case),out,Verbose=FALSE)
    actual <- reader(paste0("py-",case),out,Verbose=FALSE)
    stopifnot(isTRUE(all.equal(actual,expected,tolerance=0)))
    cat("PASS Python -> R:",case,"\n")
  }
} else stop("Unknown mode")
