function WriteDATA(DataFilename,Data,Header,Key,DataDefined,DataDirectory,Comment,Names,Description,AllStringData)
% WriteData(DataFilename,Data,Header,Key,DataDefined,DataDirectory,Comment,Names,Description,AllStringData)
% WriteData(DataFilename,Data,~,~,~,DataDirectory)
% WriteData(DataFilename,Data)
% WriteData(DataFilename,Names)
% WriteData(DataFilename,Names,~,~,~,DataDirectory)
% Writes data to a *.data file
%
%
% INPUT:
% DataFilename               string, name of the file to be written
% Data(1:n,1:d)              matrix, data in file excluding Key, n lines, d columns         
% OPTIONAL
% DataDirectory              string, the directory where to write into; if not given: current dir.
% Comment                    array of char, to be written in the first line as % Comment
% Header(1:d+s+1)            cell array, column names
%                            d data columns, s string columns, optional 1 key column
% DataDefined(1:d+s)         vector, type of Data columns
%                            d data columns, s string columns, 1 key column
%                            Values for DataDefined: 
%                            9 -> key
%                            0 -> columns that are not supposed to be considered
%                            1 -> numeric -> columns that are supposed to be considered
%                            2 -> numeric -> columns that are supposed to be considered for the training, but not for the computation of bestmatches
%                            3 -> numeric -> columns that contain a pre-classification of the data and that therefore are not supposed to be considered
%                            6 -> character -> the names column
%                            7 -> character -> the description column
%                            8 -> character -> all other columns with string or character data
% Key(1:n)                   vector of row type, unique key for each line, by default: [1:n]' 
% Names{1:n}                 cell array, text to be put in names column
% Description{1:n}           cell array, row descriptions to be put in last column
% AllStringData{1:n,1:s}     cell array, string data columns, n lines, s columns
%
% OUTPUT: 
% saves file DataFilename in DataDirectory or default pwd
%           
% AUTHOR: Sabine Püls 3/2015
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

% START FUNCTION
% CHECK AND PREPARE INPUT

% is there AllStringData
if nargin < 10;
	AllStringData = [NaN];
	NrCols = 0;
	NrData = 0;
else
	[NrData NrCols] = size(AllStringData{1,1});
	if ~iscell(AllStringData);
		AllStringData = cellstr(AllStringData);
	end;
	data = AllStringData{1,1};
	[X AllSD] = size(AllStringData);
	if AllSD > 1;
		for i = 2:AllSD;
			data = [AllStringData{1,i}, data];
		end;
	end;
end;

% is there Description
if nargin < 9 | isempty(Description);
	Description = [NaN];
else
	NrCols = NrCols +1;
	[NrData2 X] = size(Description{1,1});
	NrData = max(NrData, NrData2);
	if exist('data');
		data = [Description, data];
	else
		data = cellstr(Description);
	end;
end;

% is there Names
if nargin < 8 | isempty(Names);
	if isempty(Data); % and no Data
		error('WriteDATA: Names or Data are necessary!');
	else % only Data
		[NrData2 NrCols2] = size(Data);
		NrCols = NrCols + NrCols2;
		NrData = max(NrData, NrData2);
	end;
else 
	if isempty(Data); % only Names
		NrCols = NrCols +1;
		[NrData2 X] = size(Names{1,1});
		NrData = max(NrData, NrData2);
	else % Names and Data
		[NrData2 NrCols2] = size(Data);
		[NrData3 NrCols3] = size(Names);
		NrCols = NrCols + NrCols2 + NrCols3;
		NrData = max(NrData, NrData2);
		NrData = max(NrData, NrData3);
	end;
	if ~iscell(Names);
		Names = cellstr(Names);
	end;
	if exist('data');
		data = [Names, data];
	else
		data = Names;
	end;
end;

% is there Comment
if nargin < 7 | isempty(Comment);
	Comment = [NaN];
	C = -1;
end;

% is there DataDirectory
if nargin < 6 | isempty(DataDirectory);    
	DataDirectory=pwd;                                                  
end;

% is there DataDefined
if nargin < 5 | isempty(DataDefined);  
	if Data ~= [NaN]; [X NrD] = size(Data); else NrD = 0; end;
	if Names ~= [NaN]; [X NrN] = size(Names); else NrN = 0; end;
	if Description ~= [NaN]; [X NrDes] = size(Descritpion); else NrDes = 0; end;
	if AllStringData ~= [NaN]; [X NrASD] = size(AllStringData); else NrASD = 0; end;
	% 9: Key, 1: Data, 6: names, 7: description, 8: allstringdata 
	DataDefined = [9, ones(1,NrD), ones(1,NrN)*6, ones(1,NrDes)*7, ones(1,NrASD)*8];                                      
end;

% is there Key
NrCols = NrCols+1;
if nargin < 4 | isempty(Key);             
	Key =(1:NrData)'; 
else
	NrOfKeys = length(Key);
	if NrOfKeys~=NrData;
		if NrOfKeys ~= length(Names);
			error('WriteDATA: number of Keys does not match number of Data or number of Names');
		end;
	end;
end;

% is there Header
if nargin < 3 | isempty(Header);           
	Header = cell('Key', [ones(NrCols,1)*'C' int2str([1: NrCols]')]);
else % check if header fit
	[AnzHeader NameSize] = size( Header);
	if strcmp(Header{1,1},'Key') == 0;    
		Header = {'Key', Header{:}}; 
	end;
end;

% is there Data
if exist('data');
	data = [num2cell(Data), data];
else
	data = Data;
end;

% SAVE/PRINT DATA

CurrentDirectory = pwd; % Save current Directory
cd(DataDirectory);

fid = fopen(DataFilename,'w');
if fid == (-1) error(['WriteDATA: could not open file ', filename]); end;

% Comment
if Comment ~= [NaN];
    fprintf(fid,'# '); 
    fprintf(fid,'%s',Comment);
    fprintf(fid,'\n');
end;
[NrData NrCols] = size(data);
NrCols = NrCols+1; %Key

% number of Rows/Columns
fprintf(fid,'%%\t%d\n%%\t%d\n',NrData, NrCols);

% DataDefined
fprintf(fid,'%% ');
fprintf(fid,'%d\t',DataDefined);
fprintf(fid,'\n');

% Header
fprintf(fid,'%% ');
for i = 1:length(Header)
    fprintf(fid,'%s\t',Header{i});
end; % for i = 1:length(Header)
fprintf(fid,'\n');

% calculate and print CheckSums
fprintf(fid,'%% ');
for i = 1:length(DataDefined);
	if DataDefined == 1 | DataDefined == 9;
		CheckData = num2str(data{i});
	else
		CheckData = char(data{i});
	end; % if DataDefined == 1 | DataDefined == 9;
	CalcSum = CRC32(CheckData);
	fprintf(fid,'%u\t',CalcSum); % %u means integer value
end; % for i = 1:length(DataDefined);
fprintf(fid,'\n');

% SAVE/PRINT DATA TABLE
% construct line format string
% %d means double float
% %f means float
% %s means string
% %u means integer
fkey  = '%u\t'; % default for key
felse = '%f\t'; % default for data
format = repmat(' ',size(data,2),4);
% keys
key = find(DataDefined==9);
if length(key) > 0
    format(key,:) = '%d\t';
end
% names
nam = find(DataDefined==6);
if length(nam) > 0 & length(nam) < 2
    format(nam,:) = '%s\t';
else
	for i = 1: length(nam);
		format(nam(i),:) = '%s\t';
	end; % for
end; % if
% description
des = find(DataDefined==7);
if length(des) > 0 & length(des) < 2
    format(des,:) = '%s\t';
else
	for i = 1: length(des);
		format(des(i),:) = '%s\t';
	end; % for
end; % if
% allstringdata
asd = find(DataDefined==8);
if length(asd) > 0 & length(asd) < 2
    format(asd,:) = '%s\t';
else
	for i = 1: length(asd);
		format(asd(i),:) = '%s\t';
	end; % for
end; % if
% all non string data
cols = find(DataDefined~= 9 & DataDefined~= 8 & DataDefined~= 7 & DataDefined~= 6 );
for i = 1:length(cols)
    format(cols(i),:) = '%f\t';
end

format = reshape(format',1,prod(size(format)));
format(length(format)-1:length(format)) = '\n';

% save data
data = [num2cell(Key),data];

data = data';
fprintf(fid,format,data{:});
fclose(fid);

cd(CurrentDirectory);   % Restore current Directory

