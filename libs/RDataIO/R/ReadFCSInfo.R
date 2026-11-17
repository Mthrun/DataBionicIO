ReadFCSInfo = function(FileName, FilePath = "",truncate_max_range=FALSE){
  # V = ReadFCSInfo(FileName, FilePath)
  # INPUT
  # FileName
  # FilePath
  # truncate_max_range        TRUE: does something (see flowCore doku, irrelecant for this function), FALSE disables warning for range
  # OUTPUT
  # ParamaeterDescription     String Matrix containing Name, Description and Scale of the dataset. In case of multiple datasets in the
  #                               same file, a list of matrices is returned.
  # DeviceType                Cytometer used, usually either "DxFLEX" or "Navios"
  # Keywords                  All annotation keywords
  # FileName  = addext(FileName,'fcs');     #  checks for the right extension and adds it if necessary
  # if(is.null(FileName)){
  #   FileName  = addext(FileName,'LMD');
  # }
  # AUTHOR: Michael Thrun (IAP-GmbH Intelligent Analytics Projects)
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  if (!grepl("\\.[^./\\\\]+$", FileName)) {
    FileName <- paste0(FileName, ".fcs")
  }
  
  if(nchar(FilePath) > 0){
    if(substr(FilePath, nchar(FilePath), nchar(FilePath)) != '/')
      FilePath = paste0(FilePath, '/')
  }
  
  readOutDescription = function(frame){
    # Extract FCS parameter metadata.
    #
    # INPUT
    # frame  flowFrame with parameter fields in its description slot.
    #
    # OUTPUT
    # Character matrix with Name, Description, and Scale columns.
    # The first absent parameter ends the scan, up to 1000 parameters.
    # Missing individual fields contain the text NA.
    # SPDX-License-Identifier: AGPL-3.0-only
    # Additional permission: see MATLAB-EXCEPTION.txt.
    V = frame
    # count number of parameters
    for(nrOfPar in 1:1000){
      p = nrOfPar
      if(is.null(V@description[paste0("$P",p, "N")][[1]]) &
         is.null(V@description[paste0("$P",p, "S")][[1]]) &
         is.null(V@description[paste0("@P",p, "C")][[1]])){
        nrOfPar = nrOfPar - 1
        break
      }
    }
    
    res = matrix(ncol = 3, nrow = nrOfPar)
    colnames(res) = c('Name', 'Description', 'Scale')
    
    for(p in 1:nrOfPar){
        
      v1 = V@description[paste0("$P",p, "N")][[1]]
      v2 = V@description[paste0("$P",p, "S")][[1]]
      v3 = V@description[paste0("@P",p, "C")][[1]]
      
      res[p,] = c(ifelse(is.null(v1), 'NA', v1),
                  ifelse(is.null(v2), 'NA', v2),
                  ifelse(is.null(v3), 'NA', v3))
      
    }
    return(res)
  }
  
  useDataset = 1
  
  frame = flowCore::read.FCS(file.path(FilePath, FileName), dataset = useDataset,truncate_max_range = truncate_max_range)
  
  if(frame@description$`$NEXTDATA` != 0){
    print("ReadFCSInfo: There is more than one dataset found in file. Result will be a list!")
    results = list(readOutDescription(frame))
  } else{
    results = readOutDescription(frame)
  }
  keywords_list <- flowCore::keyword(frame)
  names(keywords_list) <- gsub("^[@$]", "", names(keywords_list))
  
  # description_list <- flowCore::description(frame)
  # names(description_list) <- gsub("^[@$]", "", names(description_list))
  #nota:
  # all(names(description_list)==names(keywords_list))
  while(frame@description$`$NEXTDATA` != 0){
    useDataset = useDataset + 1
    frame = flowCore::read.FCS(file.path(FilePath, FileName), dataset = useDataset,truncate_max_range = truncate_max_range)
    results = c(results, list( readOutDescription(frame)))
    
    keywords_list_cur <- flowCore::keyword(frame)
    names(keywords_list_cur) <- gsub("^[@$]", "", names(keywords_list_cur))
    keywords_list=c(keywords_list,keywords_list_cur)
    
    #description_list_cur <- flowCore::description(frame)
    #names(description_list_cur) <- gsub("^[@$]", "", names(description_list_cur))
    
    #description_list=c(description_list,description_list_cur)
  }

  
  return(list(Variables=results,DeviceType=keywords_list$CYT,Keywords=keywords_list))
}
