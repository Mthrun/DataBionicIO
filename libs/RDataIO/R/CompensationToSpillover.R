CompensationToSpillover <- function(CompensationMatrix){
  # V = CompensationToSpillover(CompensationMatrix)
  # 
  # INPUT
  #
  # Compensation    [1:d, 1:d] Numerical matrix with compensation matrix for
  #                 given variables.
  # 
  # OUTPUT
  # 
  # SpilloverMatrix [1:d, 1:d] Numerical matrix with spillover matrix for given
  #                            variables.
  # 
  # This function inverts/solves the compensation matrix in order to retrieve
  # the spillover matrix.
  # Author: Quirin Stier (IAP-GmbH Intelligent Analytics Projects) 2021
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  nrow = dim(CompensationMatrix)[1]
  inverseCompensationMatrix =solve(CompensationMatrix)
  SpilloverMatrix = matrix(inverseCompensationMatrix, nrow = nrow)
  colnames(SpilloverMatrix) = 1:dim(CompensationMatrix)[1]
  return(list("SpilloverMatrix"=SpilloverMatrix))
}
