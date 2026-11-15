WriteIMX = function(FileName,MapMask, OutDirectory=getwd(),Comment){
#   WriteIMX(FileName,MapMask,OutDirectory)
#   saves a mask for a tiled UMX to display a ESOM-map-Isle
#
# INPUT
#   FileName         the name of the file to write 
#   MapMask             a binary array 0 where the map is displayed 1 otherwise
# OPTIONAL
#   OutDirectory        the directory where to write into; if not given: current dir.
# 
  # Comment                   array of characters to be written in the first line of the file, it 
  #  										      will be marked with '\#', more than one line, use '\n#'
  #                           Not More than 3 seperate Lines of Comments allowed
  #
# OUTPUT
# An IMX file with the mask dimensions and mask values.
# Returns the previous working directory invisibly after restoration.
#
# author: MT/2014
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
  
  
  filename = addext(FileName, 'imx')
  imx = MapMask
  
  CurrentDir = getwd()
  setwd(OutDirectory)
  
  if (is.vector(imx)) {
    k = length(imx)
    l = 1
  }
  else {
    k = nrow(imx)
    l = ncol(imx)
  }
  header = paste0('%', "\t", k, "\t",l)
  append=F
  if (!missing(Comment)){
    write(paste0('#\t',Comment), file = filename,append=F)
    append=T
	}
  write(header, file = filename,    append=append)
  write.table(
    imx,
    file = filename,
    append = TRUE,
    quote = FALSE,
    sep = '\t',
    row.names = FALSE,
    col.names = FALSE,
    na = 'NaN'
  )
  
  setwd(CurrentDir)
  
}
