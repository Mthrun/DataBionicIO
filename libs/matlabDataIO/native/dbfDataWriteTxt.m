function [Data,Names,DataTypes,FileDate,info] = dbfDataWriteTxt(DbfDirectory,DbfFileName);
% [Data,Names,DataTypes,FileDate,info] = dbfread(DbfDirectory,DbfFileName);
% INPUT
% DbfDirectory        directory where *.dbf file is
% DbfFileName         name of *.dbf file
% OUTPUT
% Data                Cell array containing the data 
% Names               column names of Data
% DataTypes           Data Type corresponding to Names
% FileDate            YYYYMMDD date when the file was modyfied
% info 
%   INFO is a structure with the following fields:
%      Filename       Char array containing the name of the file that was read
%      DBFVersion     Number specifying the file format version
%      FileModDate    A string containing the modification date of the file
%      NumRecords     A number specifying the number of records in the table
%      NumFields      A number specifying the number of fields in the table
%      FieldInfo      A 1-by-numFields structure array with fields:
%         Name        A string containing the field name 
%         Type        A string containing the field type 
%         ConvFunc    A function handle to convert from DBF to MATLAB type
%         Length      A number of bytes in the field
%      HeaderLength   A number specifying length of the file header in bytes
%      RecordLength   A number specifying length of each record in bytes
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

CurrentDirectoy = pwd;
cd(DbfDirectory);

fid = fopen(DbfFileName,'r','ieee-le');
if fid == (-1) error(['dbfread: could not open file ', DbfFileName]); end;

info = dbfinfoALU(fid); 

% variablen Namen extrahieren
allFieldNames = {info.FieldInfo.Name};
Names = char(allFieldNames);
% datum extrahieren und umwandeln
DDD = datevec(info.FileModDate)
Year = DDD(1); Month = DDD(2); Day = DDD(3);
if Year < 1950 ; Year = Year+100; end; % Y2K
FileDate = Year *10000 + Month*100+Day;

% DataTypes aus info generieren
DataTypes  = char(info.FieldInfo(:).Type);

% Determine which fields to read.
fields2read = 1:info.NumFields;
attributeFieldNames = {info.FieldInfo(fields2read).Name};
AnzDatenSaetze = info.NumRecords 
records2read = 1:100 % AnzDatenSaetze

% The first byte in each record is a deletion indicator
lengthOfDeletionIndicator = 1;
% Loop over the requested fields, reading the attribute data.
Data = cell(numel(records2read),numel(fields2read));
for k = 1:numel(fields2read),
    n = fields2read(k);
    fieldOffset = info.HeaderLength ...
                  + sum([info.FieldInfo(1:(n-1)).Length]) ...
                  + lengthOfDeletionIndicator;
    fseek(fid,fieldOffset,'bof');
    formatString = sprintf('%d*uint8=>char',info.FieldInfo(n).Length);
    skip = info.RecordLength - info.FieldInfo(n).Length;
    data = fread(fid,[info.FieldInfo(n).Length info.NumRecords],formatString,skip);
    Data(:,k) = feval(info.FieldInfo(n).ConvFunc,data(:,records2read)'); % k- ter Datensatz
end;
cd(CurrentDirectoy);



% ausschreiben als Tab separated text
OutFileName = 'hlp.txt';
fid = fopen(OutFileName,'w');
if fid == (-1) error(['savetext: could not open file ', OutFileName]); end;
[AnzZeilen AnzSpalten] = size(Data);  % groesse der matrix

% header zeile Schreiben
OutNames = char(allFieldNames);
for i = 1:AnzSpalten
    fprintf(fid,'%s',OutNames(i,:));
    if i <AnzSpalten
        fprintf(fid,'\t');
    else
        fprintf(fid,'\n');
    end; %  if i <AnzSpalten
end; % for i = 1:AnzSpalten


%Daten Schreiben
    for z = 1:AnzZeilen
        for s= 1:AnzSpalten
          OutData = cell2mat(Data(z,s));
          DataType =  info.FieldInfo(s).Type ; %Alternative: class(Data)
          if  strcmp(Data, 'NA') Data = 'NaN'; end; %convert to NaN
          switch DataType
               case 'char'
                   fprintf(fid,'%s',OutData);
               case 'double'
                   fprintf(fid,'%g',OutData);
               otherwise
           end; % switch
          if s < AnzSpalten 
              fprintf(fid,'\t');
          else
               fprintf(fid,'\n');
          end; % if s < AnzSpalten
        end; % for s
    end % for z 
fclose(fid);

