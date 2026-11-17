`WriteTXT` <-
function(FileName,Names,OutDirectory=getwd(),StrTrim=FALSE){
# WriteTXT(FileName,Names,OutDirectory,StrTrim);
# Save Only names 
#
# INPUT
# FileName                 name of the  file to be written
# Names(1:d,1:s) or []     cell array or string matrix with column names  	
#
# OPTIONAL
# OutDirectory             the directory where to write into; if not given: current dir.
# StrTrim                  ==TRUE bedeutet keine leading+ trailing blanks  schreiben, not implemented yet, default FALSE

# OUTPUT
# A .txt file with Names and no row names, column names, or quotes.
# Returns the previous working directory invisibly after restoration.
#
# author: Michael Thrun (IAP-GmbH Intelligent Analytics Projects) 06/2015
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
# text should be a matrix containing character strings

CurrentDir = getwd()
setwd(OutDirectory)
filename = addext(FileName,'txt')
write.table(Names,filename, row.names=FALSE, col.names=FALSE, quote=FALSE)

setwd(CurrentDir)
}

