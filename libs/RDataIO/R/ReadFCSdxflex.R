ReadFCSdxflex = function(FileName, FilePath = "", Dataset = NULL,
                   VarsToCompensate = NULL, tryToCompensate = T,
                   Anonymize = F){
  # # Read fcs files
  # V = ReadFCSdxflex(InFileName, InDirectory)
  # V = ReadFCSdxflex(FileName, FilePath, Dataset = 2)
  # Data       = as.matrix(V$PlainData)
  # Header     = V$VarNames ; Header
  # 
  # INPUT
  # FileName             name of the file.
  #
  # OPTIONAL
  # FilePath             name of the file's directory.
  # Dataset              in FCS files, multiple datasets can be saved. If
  #                      another than the last shall be loaded, this gives its
  #                      index
  # VarsToCompensate     Vector of TRUE and FALSE for each variable in the data.
  #                      If TRUE, the variable will be compensated.
  #                      If not given, the function will try to find the right
  #                      variables itself. Boolean Vector the length of number
  #                      of variables.
  # tryToCompensate      tries to compensate the PlainData if a compensation
  #                      matrix can be found
  # Anonymize            tries(!) to remove common keywords containing
  #                      information about patients.
  #                      THIS IN NO WAY MAKES DATA SAVE TO GIVE OUT!
  #
  # OUTPUT
  # v$FCSData                     object of class flowFrame.
  #                               relates to flowCore::read.FCS
  # v$PlainData[1:n,1:d]          Data in a plain matrix format. This is the data as
  #                               it was found in the lmd/fcs file which might
  #                               already be compensated
  # CompensationMatrix[1:d2,1:d2] Compensation Matrix if existing
  #                               Inverse of spill after setting its diagonal
  #                               to 1, or Moore-Penrose inverse if singular.
  #                               A missing axis name vector is copied from
  #                               the other axis if available (same order).
  # CompensatedData[1:n,1:d]      Matrix with compensated data
  # VarNames[1:d]                 variable names (e.g. "FS_PEAK_LIN", "FS",
  #                               "SS_PEAK_LIN", "SS", "TCRgd-FITC", "CD45-KrO")
  # VarIdentifiers[1:d]           detector names used by the machine to adress
  #                               the variable) (e.g. "FS-H", "FS-A", "SS-H",
  #                               "SS-A","FL1-A", "FL1-H", "FL2-A", "FL2-H",...,
  #                               "TIME")
  #                               
  # DeviceName                    Flowcytometer device name.
  # Cls[1:n]                      Classes from Clustering
  # 
  # Temporarily REMOVED INPUT  
  # Anonymize if T, then parts of FCS Data get overwritten by placeholders to remove links to patients
  # AUTHOR: Michael Thrun (IAP-GmbH Intelligent Analytics Projects)
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  FileName  = addext(FileName,'fcs');     #  checks for the right extension and adds it if necessary
  
  if(nchar(FilePath) > 0){
    if(substr(FilePath, nchar(FilePath), nchar(FilePath)) != '/')
      FilePath = paste0(FilePath, '/')
  }
  
  useDataset = 1
  # wenn dataset gegeben, dann benutze immer diesen
  # sonst springe bis zum letzten enthaltenen Datensatz
  
  # move to the correct dataset
  if(!is.null(Dataset)){
    useDataset = Dataset
    frame = flowCore::read.FCS(paste0(FilePath, FileName), dataset = useDataset,truncate_max_range = FALSE)
  }
  
  if(is.null(Dataset)){
    # read the first dataset
    useDataset = 1
    
    frame = flowCore::read.FCS(paste0(FilePath, FileName), dataset = useDataset,truncate_max_range = FALSE)
    # load further datasets as long as they are available
 #   while(frame@description$`$NEXTDATA` != 0){
 #     useDataset = useDataset + 1
 #     frame = flowCore::read.FCS(paste0(FilePath, FileName), dataset = useDataset)
 #   }
  }
  
  data_raw = as.matrix(frame@exprs)
  print(paste0("ReadFCSdxflex: Dataset ", useDataset, " was read."))
  

  
  # load spillover matrix
  # navios: spill or spillover and same order of chanels and compensation matrix
  # dxflex: different order of spillover and chanels matrix
  spill = frame@description$'SPILL'
  if(is.null(spill)) spill = frame@description$'$SPILLOVER'

  if(is.null(spill)){
        tryToCompensate = F
        warning("ReadFCSdxflex: Compensation Matrix could not be extracted!")
  }
  
 
  # go from spillover to compensation matrix
  compensation = NULL
  if(!is.null(spill)){
    # Both axes use the same detector order; only fill missing names.
    if(is.null(rownames(spill))) rownames(spill) = colnames(spill)
    if(is.null(colnames(spill))) colnames(spill) = rownames(spill)
    for(i in 1:ncol(spill)){
      spill[i,i] = 1
    }
    
    FLAG_invertible=FALSE
    tryCatch({
      compensation = solve(spill)
      FLAG_invertible=TRUE
    },error=function(e){
      warning(e)
   })
   if(isFALSE(FLAG_invertible)){
     warning("ReadFCSdxflex: spill matrix is not invertible.Using the Moore-Penrose generalized inverse.")
     compensation=MASS::ginv(spill)
     # Restore inverse-axis names also for the generalized inverse.
     dimnames(compensation)=list(colnames(spill),rownames(spill))
   #   spill=spill+runif(length(spill),min = -0.0000001,max=0.0000001)
   #   compensation = solve(spill)
   #   minax=quantile(compensation)
   #   compensation[compensation<minax[1]]=0
   #   compensation[compensation>compensation[2]]=0
   #   compensation=round(compensation,3)
   #   warning("ReadFCSdxflex: spill matrix is not invertible. Adding some epsilon random noise to make matrix invertible.")
    }
  }#end is not null spill
  
  # search for names and descriptions
  parameterDescriptions = sapply(1:ncol(data_raw), function(i){
    c( ifelse(is.null((a = frame@description[paste0("$P",i, "N")][[1]])), NA, a),
       ifelse(is.null((a = frame@description[paste0("$P",i, "S")][[1]])), NA, a))
  })
  
  RowsComp=rownames(compensation)
  parameterIdentifiers = parameterDescriptions[1,]
  parameterNames = parameterDescriptions[2,]
  
  if(all(is.na(parameterNames))){
    Colnames = parameterIdentifiers
  }else{
    # fix naming notation
    Colnames = parameterNames
    Colnames = gsub(" ", "_", Colnames)
    Colnames = gsub("-", "_", Colnames)
    Colnames = gsub("\\.", "_", Colnames)
  }

  CompensatedData = NULL
  if (tryToCompensate) {
    ind_data = match(RowsComp, parameterDescriptions[1, ], nomatch = 0)
    #select data that can be compensated
    DataToCompensate = data_raw[, ind_data]
    if (all(colnames(DataToCompensate) == RowsComp)) {
      #apply compensation to the part of data that can be compensated
      CompensatedDataPart = DataToCompensate %*% (compensation)
      
      #combine data that is compensated with data that is not
      CompensatedData = data_raw
      #CompensatedData[, ind_back] = CompensatedDataPart
      CompensatedData[, ind_data] = CompensatedDataPart
      #set names correctly
      colnames(CompensatedData)=Colnames
      
      # fixedParameterNames   /  VarNames
      print(paste(
        "The following variables were be compensated: ",
        paste(
          paste0(Colnames[ind_data], "(", RowsComp, ")"),
          collapse = ", "
        )
      ))
      
      # print(paste(
      #   "The following variables WILL NOT be compensated: ",
      #   paste(
      #     paste0(fixedParameterNames[!VarsToCompensate], "(", parameterIdentifiers[!VarsToCompensate], ")"),
      #     collapse = ", "
      #   )
      # ))
    } else{
      #set names correctly
      colnames(CompensatedData)=Colnames
      
      message("ReadFCSdxflex: No compensation is performed as variable match failed.")
    }
    
  } else{
    message("ReadFCSdxflex: No compensation is performed.")
  }

  if(Anonymize){
     frame@description$"$FIL" = "John Doe"
     frame@description$"@SAMPLEID1" = "John Doe"
     frame@description$"$RUNNUMBER" = "Muster Strasse"
     frame@description$"@LOCATION" = "Muster Strasse"
     frame@description$"$INSTADDRESS" = "Muster Strasse"
     frame@description$"$GUID" = "Muster GUID"
     frame@description$"$FILENAME" = "Muster Filename"
  }
  if(!is.null(frame@description$"$CLS")){
    cls = frame@description$"$CLS"
  }else{
    cls = NULL
  }
  DeviceName = frame@description$`$CYT`
  return(list(FCSData = frame,
              PlainData = data_raw,
              CompensationMatrix = compensation,
              CompensatedData = CompensatedData, 
              VarNames = Colnames,
              VarIdentifiers = parameterIdentifiers,
              DeviceName = DeviceName,
              Cls = cls))
}




