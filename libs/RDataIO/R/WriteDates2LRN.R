WriteDates2LRN=function(FileName, Data, DatesTime, Header, DataDefined=c(), OutDirectory=getwd(),  Comments=NULL, SignificantDigits = NULL, DecimalDigits = NULL, Scientific = F){
  # WriteDates2LRN(FileName,Data,Header,Time,DataDefined,OutDirectory,CommentOrDigits);
  # WriteDates2LRN(FileName,Data,Header,Time,c(),OutDirectory);
  # save data, column Header, and column type definition to a *.lrn file, converts TSAT::ReadDates to LRN for ALU
  #
  # INPUT
  # FileName                         name of the  file to be written
  # Data(1:n,1:d)                    matrix of data , cases in rows , variables in columns, may contain NaN, NA or any other missing number symbol
  #                                  for is.infinite(x) and  is.nan(x) all these x are written as NaN
  # DatesTime                        Dates that define the Key in the LRN, if R Dates, then "-" is just deleted, otherwise as-numeric is called
  #
  # OPTIONAL
  # OutDirectory                    the directory where to write into; if not given: current dir.
  #
  # Header(1:d) OR Header(1:d+1)    cell array or string matrix with column Header (d data columns) plus eventual header for Key as first entry
  #
  # DataDefined(1:d+1)              vector of column type: keys (0=ignore,1=data,3=class,9=key)
  #                                 default is leading 9 and d-times 1
  #
  # Comments                        User comment text, written as lines starting with #.
  # SignificantDigits               number of significant digits (takes precedence over DecimalDigits)
  # DecimalDigits                   number of decimal digits
  # Scientific                      flag whether to use scientific notation, default false
  #
  # OUTPUT
  # A .lrn file with Date keys in YYYYMMDD form, or numeric keys for other inputs.
  # Keys must be unique finite integers within +/- .Machine$integer.max.
  #author: MT 2021
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.
  #example
  #ElectricityBRD=TSAT::ElectricityBRD
  #WriteDates2LRN("ElectricityBRD",ElectricityBRD$Mrd_KWh,ElectricityBRD$Time)

  if(lubridate::is.Date(DatesTime)){
    Key=as.numeric(gsub("-","",as.character(DatesTime)))
  }else{
    Key=as.numeric(DatesTime)
  }
  if(missing(Header))
    Header=colnames(Data)


  # The lowercase name was undefined; pass the public Scientific argument unchanged.
  WriteLRN(FileName = FileName, Data = Data, Header = Header, Key=Key, DataDefined = DataDefined, OutDirectory = OutDirectory,  Comments = Comments, SignificantDigits = SignificantDigits, DecimalDigits = DecimalDigits, Scientific = Scientific)
}
