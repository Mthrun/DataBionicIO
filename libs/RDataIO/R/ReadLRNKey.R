ReadLRNKey = function(FileName, InDirectory){
  # Read the first field of each non-comment LRN row.
  #
  # INPUT
  # FileName     LRN file name, or NULL to open the file chooser.
  # InDirectory  Input directory; the file chooser can supply it.
  #
  # OUTPUT
  # Character vector of first tab-separated fields.
  # Lines that start with # or % are excluded.
  # 
  # 
  # Author: Quirin Stier (IAP-GmbH Intelligent Analytics Projects)
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  
  if(is.null(FileName)){
    res <- ask2loadFile(".lrn")
    if(is.null(res)) stop("no file selected")
    FileName = res$FileName
    InDirectory = res$InDirectory
  }  
  
  FileName  = addext(FileName,'lrn')              #  checks for the right extension and adds it if necessary
  
  
  InDirectory = normalizePath(InDirectory)    # see if the Directory is there and has a canonical name
  checkFilename(FileName, Directory = InDirectory, Extension = 'lrn',
                ReadOrWrite = TRUE, NameOfFunctionCalled = 'ReadLRN()')
  currentWD   = getwd()             # Aktuelles verzeichnis merken
  setwd(InDirectory)                # Ins Verzeichnis wo sich Datei befindet wechseln
  Header      = NULL
  ColNameFlag = T
  
  Key = c()
  con = file(FileName, "r")
  while(TRUE){
    line = readLines(con, n = 1)
    if(length(line) == 0){
      break
    }
    if((substr(line, 1, 1) != "#") & substr(line, 1, 1) != "%"){
      tmpline = unlist(strsplit(line, "\t"))
      Key = c(Key, tmpline[1])
    }
  }
  close(con)
  setwd(currentWD)
  return(Key)
}