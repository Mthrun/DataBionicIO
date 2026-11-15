function [AllData,Header] = ReadWIDcsv(CSVFileName,CSVdirectory)
% NOCH NICHT fertig !
% lesen einer *.csv datei der WID database
% Verwendete WID-Variable:
%       ahwealj992
%
% Erwartetes CSV-Format:
%
% country,variable,percentile,year,value,age,pop,data_quality
%
% Beispiel:
% CH;ahwealj992;p0p100;1990;28.9215715912097;999;i;
%
% Beruecksichtigt werden NUR Land/Jahr-Kombinationen,
% fuer die der vollstaendige Satz der generalisierten
% Perzentile vorhanden ist:
%
% 0-1, 1-2, ..., 98-99,
% 99-99.1, 99.1-99.2, ..., 99.9-100
%
% Also insgesamt 109 Perzentilintervalle.

% OUTPUT
% The archived source is incomplete and does not define a usable result.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

WEALTHVARIABLE = 'ahwealj992';  % string in variable to indcete the wealth data
PERCENTILEbegin = 'p0'          % die ersten 2 Buchtaben fuer percentile
DELIM = ';';                    % der Separator in den WID files
SEPARATOR = ','                 % der Separator in der WealthFile

CurrentDir = pwd; % save current dir restore later
cd(CSVdirectory);
    % --- 1. Datei öffnen ,Header parsen und schreiben
    fid = fopen(CSVFileName , 'r');
    if fid == -1; error('ReadWIDtoWealth:Datei "%s" nicht gefunden.', CSVFileName);end;
    HeaderLine = fgetl(fid);
    Header = tokenize2Strings(HeaderLine,DELIM );
 %  Header = country;variable;percentile;year;value;age;pop;data_quality
    % die Spaltennummern herausfinden
    countryind      =findAttrInd(	'country',Header);
    variableind     =findAttrInd(	'variable',Header);
    percentileind	=findAttrInd(	'percentile',Header);
    yearind         =findAttrInd(	'year',Header);
    valueind        =findAttrInd(	'value',Header);
    ageind          =findAttrInd(	'age',Header);
    popind          =findAttrInd(	'pop',Header);

   % --- 2. Alle Daten einlesen ---
    AnzLines = 1E6;
    UpdateTacho= 1000;
    TS = ['ReadWIDcsv: analyzing file content of ',ReplaceUnderline(CSVFileName)];
    i=0;
    Tacho = waitbar(i,TS);% open tacho
    Found = 0;
    LineNumber=0; Data = [];  % init Data
    while ~feof(fid) 
        i=i+1;
        if mod(i,UpdateTacho)==0 ; waitbar(i/AnzLines,Tacho,TS); end; % update tacho
        line = fgets(fid);
        % line = CH;ehfcari999;p0p100;1990;28.9215715912097;999;i;
        Tokens = tokenize2Strings(line ,DELIM );
        Variable   = strtrim(Tokens(variableind,:));
        Percentile = strtrim(Tokens(percentileind,:));
        %  Percentile = p0p100
        PP = Percentile(1:2); % die ersten 2 Buchstaben von prctile
        Found = strcmp(Variable ,WEALTHVARIABLE)& strcmp(PP,PERCENTILEbegin);   
        if Found==1  % eineZeile Gefunden diese wird umcodiert und wieder ausgeschrieben   
             Year  = str2num(Tokens(yearind,:));    % das Jahr
             Value = str2num(Tokens(valueind,:));   % der wert der Variablen
             Data(i,:) = 
               
              OutLine = strrep( line , DELIM, SEPARATOR);
              fprintf(OutFid,'%s',strtrim(OutLine));        % Zeile schreiben
              fprintf(OutFid,'\n');                         % zeileunumberuch 
        end; %   if Found==1  % eineZeile Gefunden diese wird wieder ausgeschrieben   
    end;
    fclose(fid);
    close(Tacho)
end % for l



[n,d] = size(AllData)
%  AllKey= [1:n]';
Comment = 'Wealth in Percentiles per Person, Year and Country, 01PrepareWealthData.m'
Digits = 4
LrnFileName      = '2026Wealth_WID_AllData.lrn'
LrnDirectory  = 'D:\ALUsvn\26WealthInequality\09Originale'
AllHeader = char('Key','LandNummer',HEADER);
OutData   = [AllCountries,AllData];
WriteLRN(LrnFileName,OutData,AllHeader, AllKey,[], LrnDirectory,Comment,0,Digits);


close all;
% wieder einlesen
LrnFileName      ='2026Wealth_WID_AllData.lrn'
LrnDirectory  = 'D:\ALUsvn\26WealthInequality\09Originale'

[Data,Key,Header] =  ReadLRN(LrnFileName,LrnDirectory);
Year                    	=findAttrCol(	'Year',Header,Data);	Yearind	=findAttrInd(	'Year',Header);
PopulationPercentileC001	=findAttrCol(	'PopulationPercentileC001',Header,Data);	PopulationPercentileC001ind	=findAttrInd(	'PopulationPercentileC001',Header);
PopulationPercentileC127	=findAttrCol(	'PopulationPercentileC127',Header,Data);	PopulationPercentileC127ind	=findAttrInd(	'PopulationPercentileC127',Header);
WealthPercentileC001 	=findAttrCol(	'WealthPercentileC001',Header,Data);	WealthPercentileC001ind	=findAttrInd(	'WealthPercentileC001',Header);
WealthPercentileC127 	=findAttrCol(	'WealthPercentileC127',Header,Data);	WealthPercentileC127ind	=findAttrInd(	'WealthPercentileC127',Header);

PopulationPerc = Data(:,PopulationPercentileC001ind:PopulationPercentileC127ind)'
WealthPerc= Data(:,WealthPercentileC001ind:WealthPercentileC127ind)'

for y= 1:n
    Y = Year(y);
    hold on;
    plot( PopulationPerc(:,y),WealthPerc(:,y),'b.-'); grid on;
     title(['Matlab ABC ',num2str(Y)]);
     ylabel('Anteil Vermögen');
     xlabel('Anteil Personen');
end;

