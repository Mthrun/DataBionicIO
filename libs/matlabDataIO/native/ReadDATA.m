function [Data,Header,Key,DataDefined,Names,Description,AllStringData] =  ReadDATA(DataFileName,DataDirectory); 
% [Data,Header,Key,DataDefined,Names,Description,AllStringData] =  ReadDATA(DataFileName,DataDirectory)
%
% Version= 0.1 
%
% DESCRIPTION:  ReadDATA reads *.data file, see '...\dbt\ZFileFormatDocuments\data.html'
%
% INPUT:
% DataFilename: name of *.data file, including file extension '*.data'
% OPTIONAL:
% DataDirectory: Directory where *.data file is  (default ==  pwd )              
%
% OUTPUT                     (file has n columns, including m of type "character" and d rows):
% Data(1:n-m,1:d)            matrix containing the data
% Header{1:n}                cell array or string matrix with column names 
% Key(1:d)                   array with key values
% DataDefined(1:n)           the "Defined" line of *.data
%                            Values for DataDefined: 
%                            9 -> key
%                            0 -> columns that are not supposed to be considered
%                            1 -> numeric -> columns that are supposed to be considered
%                            2 -> numeric -> columns that are supposed to be considered for the training, but not for the computation of best matches
%                            3 -> numeric -> columns that contain a pre-classification of the data and that therefore are not supposed to be considered
%                            6 -> character -> the names column
%                            7 -> character -> the description column
%                            8 -> character -> columns that contain a pre-classification of the data and that therefore are not supposed to be considered
% Names(1:d)                 list with first names column (DataDefined == 6)  
% Description(1:d)           cell array with first description column (DataDefined == 7)
% AllStringData(1:m,1:d)     cell array with all non numeric data (incl. Names and Description)
% 
% AUTHOR: Sabine Püls 3/2015
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
%
% NOTA:

% START FUNCTION
% correct file extension?
DataFileName = addfileext(DataFileName,'.data');

CurrentDirectory = pwd; % Save current Directory
cd(DataDirectory);

% file exists?
fid = fopen(DataFileName,'r');
if fid == (-1) error(['ReadDATA: could not open file ', DataFileName]); end;

% START FILE READING

%Default
Names = [NaN];
Description = [NaN];
Header = [NaN];
Data = [NaN];
AllStringData = [NaN];
DataDefined = [NaN];
Key = [NaN];

COMMENT = '%';
HEADER  = '#'; 

% READ FIRST LINES
% skip over possible comments
line = skiplines(fid, [COMMENT]);
% number of rows
if  contains(HEADER, line(1))
   ZeilenZahlToken = strread(trim(head(line,-1)),'%s\t'); % make tokens without first symbol
   CharToken = char(ZeilenZahlToken); 
   AnzLines =str2num(CharToken(1,:)); % after this no interest
else
    error('ReadDATA: NrOfRowsInData not given'); 
end;
% number of columns
line = fgets(fid); % there should be the column number
if  contains(HEADER, line(1))
   AnzColumnsToken = strread(trim(head(line,-1)),'%s\t');% make tokens without first symbol
   CharToken = char(AnzColumnsToken); 
   AnzColumns=str2num(CharToken(1,:)); % after this no interests
else
    error('ReadDATA: NrOfColsInData not given'); 
end;
%Checksums 
line = fgets(fid); % there should be the line of checksums
if  contains(HEADER, line(1))
   CheckSumsToken = strread(trim(head(line,-1)),'%s\t');% make tokens without first symbol
   CheckSums = char(CheckSumsToken);
   else
    error('ReadDATA: Checksums not given'); 
end;
%DataDefined
line = fgets(fid); % there should be the defined data line  
if  contains(HEADER, line(1)) 
   DefinedToken = strread(trim(head(line,-1)),'%s\t'); % make tokens without first symbol
   DataDefined= str2num(char(DefinedToken));
else
    error('ReadDATA: DataDefined line not given'); 
end;
%Header
line = fgets(fid); % there should be the header line
if  contains(HEADER, line(1)) 
   HeaderToken = strread(trim(head(line,-1)),'%s\t'); % make tokens without first symbol
   Header      = deblank(char(HeaderToken));
else
    error('ReadDATA: Header line not given'); 
end; % if  contains(HEADER, line(1)) 

% checks:
% for every column one DataDefined number?
if length(DataDefined) ~= AnzColumns
    disp('ReadDATA: length of DataDefined line not equal NrOfColsInData');
end;
% for every column one header?
[AnzHeader AnzChars] = size(Header);
if AnzHeader ~= AnzColumns;
	disp('ReadDATA: number of Header not equal NrOfColsInData');
end;

% READ TABLE
% C = textscan(fileID,formatSpec,N)
% reads N times line after line columns in specific format
% formatSpec is predefined through DataDefined 
% first read all columns, sort later
format = ''; 	% coding of reading function 
				% '%s' means column of type string
				% '%f' means column of type double float
				% '%*s' or '%*f' skips column of type string or double float
				% more information in documentation of "textscan"
NamesInd = -1;
DescrInd = -1;
i = 0;
for x = DataDefined';
	i = i+1;
	switch x;
		case 0 % not supposed to be considered
			t = '%s';
			format = [format ' ' t];
		case 1 % numeric, supposed to be considered
			t = '%f';
			format = [format ' ' t];
		case 2 % numeric, supposed for training, not for bestmatch
			t = '%f';
			format = [format ' ' t];
		case 3 % numeric, pre classification
			t = '%f';
			format = [format ' ' t]; 
		case 4 %
			t = '%f';
			format = [format ' ' t]; 
		case 5 % 
			t = '%f';
			format = [format ' ' t];
		case 6 % character, names
			t = '%s';
			format = [format ' ' t];
			if NamesInd > -1
				disp('ReadDATA: More than one Names column (DataDefined == 6) exists, first is chosen as Names.')
			else
				NamesInd = i;
			end;
		case 7 % character, description
			t = '%s';
			format = [format ' ' t];
			if DescrInd > -1
				disp('ReadDATA: More than one Description column (DataDefined == 7) exists, first is chosen as Description.')
			else
				DescrInd = i;
			end;
		case 8 % character, pre classification
			t = '%s';
			format = [format ' ' t];
		case 9 % keys
			t = '%f';
			format = [format ' ' t];
		otherwise % alles andere ist fehler
			disp('ReadDATA: DataDefined should be numeric [0:9]')
	end; % end switch
end; %end for

% read AnzLines columns with format from file fid	
hlpData = textscan(fid,format,AnzLines, 'Delimiter', '\t');
% line marker marks now last line of file
% cell array hlpData{i} contains now column i

% close file
fclose(fid);

% PREPARE TABLE DATA
% split hlpData in Data, AllStringData, Header, DataDefined, Names, Description

% Data: all DataDefined == 0,1,2,3,4 or 5
DataInd =  find(DataDefined == 0);
DataInd =  [DataInd,find(DataDefined == 1)];
DataInd =  [DataInd,find(DataDefined == 2)];
DataInd =  [DataInd,find(DataDefined == 3)];
DataInd =  [DataInd,find(DataDefined == 4)];
DataInd =  [DataInd,find(DataDefined == 5)];
DataInd = sort(DataInd);
% Key: only one DataDefined == 9
KeyInd = find(DataDefined == 9 );
% Names: only first DataDefined == 6
NamesInd = find(DataDefined == 6 );
if length(NamesInd) > 0
	NamesInd = NamesInd(1);
else 
	disp('ReadDATA: There is no Names column.')
end; % if length(NamesInd) > 0
% Description: only first DataDefined == 7 
DescrInd = find(DataDefined == 7 );
if length(DescrInd) > 0
	DescrInd = DescrInd(1);
else 
	disp('ReadDATA: There is no Description column.')
end; % if length(DescrInd) > 0
% AllStringData: all DataDefined == 6,7 or 8
AllStringInd = find(DataDefined ==6);
AllStringInd =  [AllStringInd,find(DataDefined == 7)];
AllStringInd =  [AllStringInd,find(DataDefined == 8)];
AllStringInd = sort(AllStringInd);

% CHECKSUMS
% check Checksums
for i = 1: length(DataDefined)
	if DataDefined == 1 | DataDefined == 9;
		CheckData = num2str(hlpData{i});
	else
		CheckData = char(hlpData{i});
	end; % if DataDefined == 1 | DataDefined == 9;
	CalcSum = CRC32(CheckData);
	if CalcSum ~= CheckSums(i);
		%error('ReadData: CheckSums are not correct!');
		disp('ReadData: CheckSums are not correct!');
	end; % if CalsSum ~= CheckSum[i];
end; % for i = 1: length(DataDefined)

% PREPARE OUTPUT
% Data,Header,Key,DataDefined,Names,Description
if length(DataInd) > 0 & length(NamesInd) > 0;
	% there are Names and Data: Output is complete File
		Data = {hlpData{DataInd}};
		Header = cellstr(deblank(Header(DataInd,:)));
		DataDefined = DataDefined(DataInd);
		Names = hlpData{NamesInd};
		if length(DescrInd > 0);
			Description = hlpData{DescrInd};
		end; % if length(DescrInd > 0);
		AllStringData = {hlpData{AllStringInd}};
else 
	if length(NamesInd) == 0
	 % no Names but Data, "lrn" file
		Data = {hlpData{DataInd}};
		Header = cellstr(deblank(Header(DataInd,:)));
		DataDefined = DataDefined(DataInd);
	end; % end if length(NamesInd) == 0
end; % end if length(DataInd) > 0 & length(NamesInd) > 0;

if (length(KeyInd)) >0 & (KeyInd>0)
    Key =  hlpData{KeyInd};
else % no Key is found: generates 1:d
  Key = (1:AnzLines)';
end; % if (length(KeyInd)) >0 & (KeyInd>0)

% reshape OUTPUT
[Z cols] = size(Data);
hlpData = [];
for i = [1:cols];
	hlpData = [hlpData, Data{1,i}];
end; % for i = cols
Data = hlpData;

% check Key
KeyUnique = TheSameKey(sort(Key), unique(Key));
if KeyUnique ==0 ;  disp('ReadDATA: Key is not unique!');                                      end;

KeyInteger = TheSameKey(Key, round(Key));
if KeyInteger ==0 ; disp('ReadDATA: Key is not integer!');                                     end;

AnzNaNinKey = countNaNs(Key);
if AnzNaNinKey>0 ;  disp('ReadDATA: Key contains NaN values!'); end;
MinKey = nanmin(Key);
if MinKey<0 ;       disp('ReadDATA: Key contains  values < 0');                                end;
% end function ReadDATA

