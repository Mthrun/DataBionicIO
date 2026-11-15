TrimHeader = function(Header,UnderlineReplacement = " "){
# Header = TrimHeader(Header)
# deblank Header replace _ by " " and remove  
# 
# INPUT
# Header               a string array
#
# OPTIONAL
# UnderlineReplacement replaces "_" in Header default:UnderlineReplacement =' '; 
#
# OUTPUT
# Header               the trimmed Header
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
  
  Header = deblank(Header)
  Header = gsub("_", UnderlineReplacement, Header)
  return(Header)
}


