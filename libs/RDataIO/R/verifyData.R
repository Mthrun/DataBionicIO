#' Verify *.data files
#' 
#' *.data files contain checksums.  To avoid warning messages the checksums
#' must be new calculated every time the data is intentionally altered.
#' 
#' 
#' @param DataFilename string, name of file the data will be loaded/saved in
#' @param DataDirectory string, name of directory the data will be saved in,
#' default \code{getwd()}
#' @author Tim Schneider
#' @seealso \code{ReadData}, \code{WriteData}
#' @references \url{www.uni-marburg.de/fb12/datenbionik}
#' \email{databionics@mathematik.uni-marburg.de}
#' @keywords ReadData WriteData
#' @examples
#' 
#' 	#assume the is a file called test.data
#' 	#verifyData("test.data")
#' 
verifyData <-
function(DataFilename,DataDirectory=getwd()){
  # CALL: verifyData(DataFileName,DataDirectory)
  #
  # Version= 0.1 
  #
  # DESCRIPTION:  Verify a '*.data' file after changing the file
  #
  # INPUT:          DataFilename: Name of the .data file.
  # OPTIONAL:       DataDirectory: Input and output directory; default getwd().
  #
  # OUTPUT:
  # Rewrites the file through WriteData with recalculated checksums.
  # Returns NULL invisibly. ReadData warnings are suppressed.
  #
  # AUTHOR: Tim Schneider 06/2014 <schnei5t@students.uni-marburg.de>
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  # 1.Editor: MT 10/2014 *.lrna in *.data umdefiniert
  ##ruft read auf 
  # berechnet ckecksummen
  # schreibt datei wieder
  
  #warnmeldungen unterdrücken die aufgrund der falschen Checksummen ausgebeben werden
# NOTA
# Wenn man von Hand eine Datei aenderst, (z.B. in excel), kannst m die Datei 
# mit verifyData wieder gueltig machen. Weil die Checksums nach dem aendern nicht mehr stimmen
  
  suppressWarnings(  (w=ReadData(DataFilename,DataDirectory)) )

  WriteData(FileName=DataFilename, 
            Data = w$Data, 
            OutDirectory=DataDirectory, 
            Header=w$Header,
            DataDefined = w$DataDefined,
            Key = w$Key,
            Comment = w$Comment,
            Names = w$Names)
  rm(w);
  
}
