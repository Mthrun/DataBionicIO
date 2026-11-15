function [Data,Header,Key,StringHeader,StringCellArray]=  ReadCSV(CSVFileName,CSVDirectory);
% [Data,Header,Key] =  ReadCSV(CSVFileName,CSVDirectory);
% [Data,Header,Key,StringHeader,StringLines] =  ReadCSV(CSVFileName,CSVDirectory);
% reads *.csv file and decomposes into its components
% numeric and date columns are copied int Data
% Colums containing text values are moved into Names and RowRest
%
% INPUT
% CSVFileName           name of *.csv file
% CSVDirectory           directory where *.csv file is
%
% OUTPUT
% Data(1:n,1:d)         data i.e. all colums with numeric data
%                       date colums are converted to one number: YYYYMMDD
% Header(1:d,:)         column names of Data 
%
% StringHeader(1:s,:)   column header of strings
% StringCellArray{1:n}  cell array of strings

% Author: ALU , 2022
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.


CurrentDirrectory = pwd; % Save current Directory
cd(CSVDirectory);

fid = fopen(CSVFileName,'r');
if fid == (-1) error(['ReadCSV: could not open file ', CSVFileName]); end;

% header lesen
LineHeader = fgets(fid);
LineHeader = LineHeader(1:length(LineHeader)-1);
LineHeader = char(tokenize(LineHeader, ',')); % Alle Ueberschriften 
[AnzColumns,dummy] = size(LineHeader);          % wieveile Spalten

% erster durchgang analysieren, was text datum und numerisch ist 
% zeilen zählen
AnzLines = 160000;
NaNreplacement =-99.998;
Quotes ='"'; QUOTEDELIMREPLACE = '^'; % quote handling;

LineLengths = [];TypesInLines=[];
UpdateTacho= 100;
i=0;
Tacho = waitbar(i,['ReadCSV analyzing file content:']);% open tacho
% HEader ist gelesen,jetzt werden die Datenzeilen gelesen und typisiert in
% TypesInLines(1:d) % 0 ist String, 1 = Numeric; 2 is Date
while ~feof(fid)
    i=i+1;
  	if mod(i,UpdateTacho)==0 ; waitbar(i/AnzLines,Tacho,['ReadCSV analyzing file content: ',num2str(i)]); end; % update tacho
    line = fgets(fid);
    % zeile in Tokens zerlegen
    tokens =  tokenizeLineNaN(line,',',NaNreplacement,Quotes,QUOTEDELIMREPLACE) ;           % NaN oder NA mit ,KeepNaN ersetzen
    [AnzTokens,dummy] = size(tokens);
    % Typisierung der Spalten
    TypeInLine = zeros(1,AnzTokens);      % 0 ist String, 1 = Numeric; 2 is Date, 9 = NaN default ==0
     c =1;
    for c=1:AnzTokens
       tok = deblank(tokens(c,:));
       switch length(tok) % je nah anzahl zeichen
           case 0  % leer
                TypeInLine(c) = 9; 
           case 3  % nan
               if tok =='NaN';               TypeInLine(c) = 9; end;
        end; % switch
       if abs(str2num(tok))>=0;              TypeInLine(c) = 1; end;
       if IsDateString(tok);                 TypeInLine(c) = 2; end;
    end; % for c
    
    LineLengths = [LineLengths;AnzTokens];    % zeilenlaengen  speichern
    if i==1 ; TypesInLines =TypeInLine; end; 
    if AnzTokens == AnzColumns % korrecte anzahl spalten
        StringInd = find((TypeInLine==0)|(TypesInLines==0));
        TypesInLines =max([TypeInLine;TypesInLines]);
        TypesInLines(StringInd) =0; 
    else %  AnzTokens ungleich  AnzColumns: keine korrecte anzahl spalten
       error(['ReadCSV: line',num2str(i),' has the wrong number of columns']);  
    end;
end; % while ~feof(fid)
close(Tacho);                                                                                  % 
% Aufraeumen: datei zumachen und zurueck ins ausgangsdirectory
fclose(fid);
% jetzt gibts TypesInLines(1:d) % 0 ist String, 1 = Numeric; 2 is Date,  9  = NaN 
% und LineLengths(1:n)

% jetzt gibts
% TypesInLines und LineLengths 
% check  LineLengths 
FalseInd = find(LineLengths~=AnzColumns);
if length(FalseInd) >0 % einige Zeilen haben falsche Spaltenzahl
    error(['ReadCSV: these lines have the wrong number of columns',num2str(FalseInd)]); 
end;% if length(FalseInd) >0 % einige Zeilen haben falsche Spaltenzahl
[NanLines,NanCols] =  find(TypesInLines==9)

% % haben alle Zeilen die gleichen Typen? Verwendung von Typesums
% if length(unique(TypeSums))>1 % Typen Checken
%     Ind = colvector(find(TypeSums~=TypeSums(1)))';
%     warning(['ReadCSV: different data types in line(s) ',num2str(Ind+1),' of file ',CSVFileName]);
% end; % 

% nochmal lesen unter verwendung Obiger infos
n = length(LineLengths); % sowiele Zeilen in der Datei
fid = fopen(CSVFileName,'r');
% header lesen
LineHeader = fgets(fid);
LineHeader = LineHeader(1:length(LineHeader)-1);
LineHeader = char(tokenize(LineHeader, ',')); % Alle Ueberschriften 
[AnzColumns,dummy] = size(LineHeader);          % wieveile Spalten
StringColumnInd = find(TypesInLines==0);
StringHeader    =deblank(LineHeader(StringColumnInd,:)); % die String Spalten
[AnzStrings,dummy] = size(StringHeader);           % wieveile StringColumns
StringCellArray =  cell(n,1);                        % hierdrin werden die Strings gespeichert

NumericColumnInd = find( TypesInLines>0);
d = length(NumericColumnInd);                   % soviele Numerische Spalten incl Datum
DateColumnInd = find(TypesInLines==2);          % Datumsspalten
AnzDates = length(DateColumnInd);
LineLengths = [];UpdateTacho=100    ;
i=0;
Tacho = waitbar(i,['ReadCSV reading file line: 0 /', num2str(n)]);% open tacho
NumData = ones(n,d)*nan;                        % speicher bereithalten damit es schneller geht
while ~feof(fid)
    i=i+1;
  	if mod(i,UpdateTacho)==0 ; waitbar(i/n,Tacho,['ReadCSV reading file line: ',num2str(i),' /', num2str(n)]); end; % update tacho
    line = fgets(fid);
    tokens =  tokenizeLineNaN(line,',',NaNreplacement,Quotes,QUOTEDELIMREPLACE) ;  % NaN oder NA mit ,KeepNaN ersetzen   % NaN mit ,KeepNaN ersetzen
    StringTokens =  tokenize2Strings(line,',');           % die Strings mit empty strings
    StringTokens = StringTokens(StringColumnInd,:);       % die StringColumns mit empty strings
    StringCellArray{i} = StringTokens;                    % einspeichern der Strings
    [dummy,AnzChar] = size(tokens);
    for dc=1:AnzDates
       c = DateColumnInd(dc);                             % index der Datumsspalte
       DateString = deblank(tokens(c,:));                 % datum
       [yyyy,mm,dd]= date2YYYYMMDD(DateString);           % umwandeln in numerisch
       NumericDate =  yyyy*10000 + mm*100+dd  ;           % 
       tok = num2str(NumericDate);                        % 
       tokens(c,:) =  BlanksArray(AnzChar);               % eintrag loeschen
       tokens(c,1:length(tok)) = tok;                     % Datum eintragen
    end;% for dc=1:AnzDates             
    % jetzt sind alle Datumsangeben nummerisch
    DataArray = str2num(tokens(NumericColumnInd,:));
    NanInd = find(DataArray==NaNreplacement);             % wo waren die NaN
    if length(NanInd) >0 DataArray(NanInd) = nan; end;    % NaN eintragen
    NumData(i,:) = DataArray';                            % Zahlen anfuegen     
end; % while ~feof(fid)
close(Tacho);                                                                                  % 
% Aufraeumen: datei zumachen und zurueck ins ausgangsdirectory
fclose(fid);

cd(CurrentDirrectory);   % Restore current Directory

Key =[1:n]';
Data   =NumData;
Header = deblank(LineHeader(NumericColumnInd,:));

    

