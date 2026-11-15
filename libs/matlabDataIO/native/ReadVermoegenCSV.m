function [Data,Header,Key]= ReadVermoegenCSV(CSVFileName,CSVDirectory,PlotIt);
% [Data,Header,Key] =  ReadVermoegenCSV(CSVFileName,CSVDirectory);
% [Data,Header,Key] =  ReadVermoegenCSV(CSVFileName,CSVDirectory,PlotIt);
% liest die Datei im *CSV format der World Inequality Database
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

if nargin()<3;  PlotIt = 1; end;

WEALTHVARIABLE = 'ahwealj992';  % string in variable to indcete the wealth data
PERCENTILEbegin = 'p0'          % die ersten 2 Buchtaben fuer percentile
DELIM = ';';                    % der Separator in den WID files
SEPARATOR = ','                 % der Separator in der WealthFile
WEALTHzeile= [WEALTHVARIABLE,'p0']; 
CORRECTNEGATIVEWEALTH = 1;      % bei 1 werden negative Wealth werte positiv interpoliert

CurrentDirrectory = pwd; % Save current Directory
cd(CSVDirectory);

fid = fopen(CSVFileName,'r');
if fid == (-1) error(['ReadVermoegenCSV: could not open file ', CSVFileName]); end;

% header lesen
LineHeader = fgets(fid);
LineHeader = LineHeader(1:length(LineHeader)-1);
% country,variable,percentile,year,value,age,pop,data_quality,CountryNr 
LineHeader = char(tokenize(LineHeader, SEPARATOR)); % Alle Ueberschriften 
[AnzColumns,dummy] = size(LineHeader);          % wieveile Spalten

AnzLines = 1350000;
UpdateTacho= 1000;
i=0;
Tacho = waitbar(i,['reading ', TrimHeader(CSVFileName) ,' analyzing file content:']);% open tacho
% HEader ist gelesen,jetzt werden die Datenzeilen gelesen und verarb
Data = [];
while ~feof(fid)
    i=i+1;
  	if mod(i,UpdateTacho)==0 ; waitbar(i/AnzLines,Tacho,['reading ', TrimHeader(CSVFileName) ,' analyzing file content: ',num2str(i)]); end; % update tacho
    line = fgets(fid);
    % zeile in Tokens zerlegen
    tokens =  tokenizeLineNaN(line,SEPARATOR) ;           % NaN oder NA mit ,KeepNaN ersetzen
    variable = deblank(tokens(2,:));
    percentile =  deblank(tokens(3,:));               % zB p0p97
    ContryNr   = str2num(deblank(tokens(end,:)));     % die Laendernummer
    ZeilenID = [variable, percentile(1:2)];           % zB ahwealj992p0
    switch   ZeilenID
        case WEALTHzeile  % = ahwealj992p0 eine passende Zeile gefunden umwandeln in daten
          Wealthline = line;
          tokens =  tokenizeLineNaN(Wealthline,SEPARATOR) ;
          percentile =  deblank(tokens(3,:));                    % zB p0p97
          PopPercentile = str2num(percentile(4:end));            % zB    97
          PercentileWealth = str2num(deblank(tokens(5,:)))*100; 1% zB  0076700
          Year = str2num(deblank(tokens(4,:)));
          DataLine = [ContryNr,Year,PopPercentile,PercentileWealth];
          Data = [Data;DataLine];
        otherwise
           [ num2str(i),' skip ', ' : ',ZeilenID]
    end; % case
  %  if i >300; break ; end;
end;
close(Tacho);                                                                                  % 
% Aufraeumen: datei zumachen und zurueck ins ausgangsdirectory
fclose(fid);
% nun gibts Data mit
% ContryNr Jahr   percentile_ab_0  Wert
% [4       1980	         97  	1.0077e+007]


% wieviele Zeilen Gibts
[Zeilen,dummy] = size(Data);
if Zeilen <100
    Data = []; Key  =[];Header =[];    
    'ReadVermoegenCSV: File content to small'
    return
end;

% sortieren
[Matrix,SortInd] = sort(Data(:,3)); % nach Perczenilen ab 0 sortieren
Matrix = Data(SortInd,:);
[M2,SortInd] = sort(Matrix(:,2));
Matrix = Matrix(SortInd,:);         %  jetztist matrix nach Jahren dann nach Perzentilen sortiert
[M2,SortInd] = sort(Matrix(:,1));   % jetzt nach Laendern
Matrix = Matrix(SortInd,:);         %  jetztist matrix nach Jahren dann nach Perzentilen sortiert



% umspeichern  gemaess Lender unfJahren
Data = [];
Jahre = unique(Matrix(:,2)) ; % die Jahre 
Laender = unique(Matrix(:,1)) ; % die laender
i =1;Land =1;
[n,d] = size(Matrix);
for LL = length(Laender) % fuer alle LAender
    LandMatrix= Matrix(Matrix(:,1)==Laender(LL),2:end);
    for i=1:length(Jahre)  % fuer alle uniq Jahre
      Y = Jahre(i);
      Ind = find( LandMatrix(:,1)==Y);       % daten dieses jahres
      if length(Ind) >0
          PopPercentiles =  LandMatrix(Ind,3)';  % Percentile des Jahres
          WealthPerc     =  LandMatrix(Ind,2)';  % 
          DataLine =[Laender(LL),Y,PopPercentiles,WealthPerc];
          [n,D] = size(Data); 
          if n>1 & (length(DataLine) ~= D) % keine richtige Anzahl Perzentile
            Data = [];   Key  =[];  Header =[];
            'ReadVermoegenCSV: length(DataLine) ~= D'
            return
           end;  
          Data = [Data;DataLine];
          % testplot
          if PlotIt == 1  
              hold on;
              plot( PopPercentiles,WealthPerc,'b.-'); grid on
             title(['Matlab ABC ',num2str(Y)])
             ylabel('Anteil Vermögen');
             xlabel('Anteil Personen');
          end; %   if PlotIt == 1  
      end; % if length(Ind) >0
    end; % for i=1:length(Jahre)  % fuer alle uniq Jahre
end; % for LL = length(Laender) % fuer alle LAender

  PP = length(PopPercentiles);
  PopHeader  = GenerateHeader(PP ,'PopulationPercentile');
  WP = length(WealthPerc);
  WHeader  = GenerateHeader(WP,'WealthPercentile');
  Header = char('CountryNr','Year',PopHeader,WHeader);
[n,d] = size(Data);
Key = [1:n]';

