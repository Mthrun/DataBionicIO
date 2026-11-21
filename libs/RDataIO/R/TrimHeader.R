TrimHeader = function(Header,UnderlineReplacement = " "){
# Header = TrimHeader(Header)
# Remove trailing whitespace, then replace underscores by the selected text.
# 
# INPUT
# Header               a string array
#
# OPTIONAL
# UnderlineReplacement replaces "_" in Header default:UnderlineReplacement =' '; 
#
# OUTPUT
# Header               the trimmed Header
# AUTHOR: Michael Thrun (IAP-GmbH Intelligent Analytics Projects)
# SPDX-License-Identifier: AGPL-3.0-only
# Additional permission: see MATLAB-EXCEPTION.txt.
  
  Header = trimws(Header, which = "right")
  Header = gsub("_", UnderlineReplacement, Header)
  return(Header)
}


