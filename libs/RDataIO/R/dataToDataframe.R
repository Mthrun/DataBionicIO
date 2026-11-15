#' load a *.data file into a data.frame
#' 
#' Converts the outputted List from \code{ReadData} into a data.frame.
#' 
#' 
#' @param V list from \code{ReadData} call
#' @return \item{data.frame}{Data columns with optional Names and Description columns.
#' Row names follow data.frame(V$Data); V$Key is not assigned as row names.}
#' @author Tim Schneider
#' @seealso \code{addext}, \code{WriteData},\code{ReadData}
#' @keywords dataToDataframe,file
#' @examples
#' 
#' 	#needs a *.data file "test.data" in current directory (getwd())
#' 	#dataToDataFrame( ReadData("test.data") )
#' 
dataToDataframe <- function(V){
  # CALL: data <- dataToDataframe(V)
  #
  # VERSION: 0.1
  #
  # DESCRIPTION: Converts a *.data file form the dbt function ReadData() into a data.frame
  #
  #
  # INPUT:  
  # V          A list from ReadData with Data, Names, and Description fields.
  #
  # OUTPUT:    data.frame with Data columns and optional Names and Description.
  # 
  # Row names follow data.frame(V$Data); V$Key is not assigned as row names.
  #           
  # AUTHOR: Tim Schneider 02/2015 <schnei5t@students.uni-marburg.de>
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  #
  V=as.list(V) # Accept values that can be converted to a list.
  if(length(V)!= 6) warning("Not enough elements in list"); #error if the list has not the correct length
  
  frame = data.frame( V$Data );
  row.names <- V$Key;

  if( length(V$Names) > 0) frame = data.frame(frame, Names=V$Names) #append the Names 
  if( length(V$Description) > 0) frame = data.frame(frame, Description = V$Description) #append the Description
  
  return(frame); 
  
}
