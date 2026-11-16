TheSameKey <- function(keyA, keyB) {
# KeyOK= TheSameKey(KeyA, KeyB)
# KeyOK= TheSameKey(Key, ClsKey ); KeyOK
# Compare numeric vectors by length, values, and row order.
# Two empty vectors compare equal. Missing values give FALSE.
# No sorting or uniqueness check is done; unsupported inputs give FALSE.
# INPUT
# KeyA[1:n]      ordinary real numeric or logical vector
# KeyB[1:n]      ordinary real numeric or logical vector
#
# OUTPUT
# KeyOK         one logical value: TRUE if the same, otherwise FALSE
#
# $Author: MT 04/2016
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
  
return(the_same_key(keyA, keyB))
}
