RelPath = function(MoveUpLevels = 1, Subdir){
  # Path = RelPath()
  # Get the path of the directory from the current file
  # You can move up to higher directory paths from there
  # 
  # INPUT
  # MoveUpLevels    Number of directories to move up from the current file
  #                 location, default dir of project, i.e., one level up from 08AnalyseProgramme
  # Optional
  # Subdir          String for the location of Subdir after MoveUpLevels is applied
  #
  # OUTPUT
  # RelativePath    Relative location from that file
  # 
  # DETAILS
  # Get the path of the file, from which the call is made
  # Remove the name of the script of the path to yield the directory path
  # Remove more parts, to move up to higher directory levels
  # Author: Quirin Stier (IAP-GmbH Intelligent Analytics Projects) 2023
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  
  if(requireNamespace("this.path", quietly = TRUE)){
    Path = this.path::this.path()
  }else{
    if(requireNamespace("rstudioapi", quietly = TRUE)){
      Path = rstudioapi::getSourceEditorContext()$path
    }else{
      stop("Administration/SubversionDirectory.R: You are missing basic dbt dependencies: this.path, rstudioapi")
    }
  }
  # Move up x levels towards root directory to access directories of current R file
  MoveUpLevels = MoveUpLevels + 1
  if(MoveUpLevels > 0){
    for(i in 1:MoveUpLevels){
      Path = sub("/[^/]+$", "", Path)
    }
  }
  # If sub directory is given, then check if it is exists
  # If so, then add, else throw warning
  if(!missing(Subdir)){
    if(file.exists(file.path(Path,Subdir))){
      Path=file.path(Path,Subdir)
    }else{
      warning(paste0("Given subdirectory is not found on system: ", file.path(Path,Subdir)))
    }
  }
  return(Path)
}

