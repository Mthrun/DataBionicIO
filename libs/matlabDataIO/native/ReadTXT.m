function [Data,Header,StringData,StringNames] = ReadTXT(TxtFileName,TxtDirectory,NrLinesToSkip,HasNamesInColOne,EmptySymbol);
% [Data,Header,StringData,StrimgNames]= ReadTXT(TxtFileName,TxtDirectory);
% [Data,Header,StringData,StrimgNames]= ReadTXT(TxtFileName,TxtDirectory,NrLinesToSkip,HasNamesInColOne,EmptySymbol);
% teilt eine *.txt auf in Zahlen und Strings
% INPUT
% TxtFileName      name of *.txt file
% TxtDirectory     directory where *.txt file is
% 
% OPTIONAL
% NrLinesToSkip        so many lines are skipped bevore reading default: NrLinesToSkip =0;
% HasNamesInCols       ==1 means Colum 1. is a name column default:  HasNamesInCols =0;
% EmptySymbol          Symbol used for NaN  default EmptySymbol='NaN'
%
% OUTPUT
% Data(1:n,1:d)          all numeric colums of *.txt
% Header(1:d,:)          olumn names of Data
% StringData(1:n,1:ds)   all string data as array of char
% StrimgNames(1:ds,:)    column names of StringData

% in $Source: dbt/DataIO/
% Author: ALU
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% Copyright (C) 2009 Databionics Research Group


% default
if nargin < 3;           NrLinesToSkip = 0; end; 
if nargin < 4 ;          HasNamesInColOne=0; end;
if nargin < 5 ;          EmptySymbol='NaN'; end;

%  fclose(fid);
% EmptySymbol='NaN';          % TEST
% TxtFileName = FileName   % TEST
% TxtDirectory  = InDirectory   % TEST
% NrLinesToSkip = 0; 
% HasNamesInColOne=1;
 
% 
CurrentDirrectory = pwd; % Save current Directory
cd(TxtDirectory);

% OUTPUT initialisieren
VariableNames=[]; FirstColumnNames = [];
Data=[];Header=[];StringData=[];StringNames=[];

% open file
fid = fopen(TxtFileName,'r');
if fid == (-1) error(['loadtxt: could not open file ', filename]); end;

% skip liness
for i = 1:NrLinesToSkip;  fgets(fid); end;
Line= fgets(fid); 
if Line ~= -1; 
   if Line(end) ==char(10);  Line= Line(1:end-1); end ;% remove LF
end;
% in Line ist die erste Zeile
i=1;
if HasNamesInColOne==0 % Keine Titelzeile nur StringData besetzen    
   while Line ~= -1
       if Line ~= -1; 
          if Line(end) ==char(10);  Line= Line(1:end-1); end ;% remove LF
          if Line(end) ==char(13);  Line= Line(1:end-1); end ;% remove	Carriage Return
          if i==1; StringData = Line; else StringData = char(StringData,Line); end; % add to String Data
       end;
       Line =  fgets(fid); i=i+1;
   end;
   fclose(fid);
   Data =[];Header=[];StringNames=[];
else % erste Zeide der Datei ist titelzeile
    % Variablennamen entschliesseln
    if HasNamesInColOne> 0 % es gibt titelzeile
    % parse names in first line 
       NamesLine = strtrim(Line);                 % read Line of Names
       NamesLine = strrep(NamesLine, ' ', '_') ;  % remove blanks
       tokens = tokenizeLine(NamesLine);
       size(tokens);
    end; 
     % der rest der Datei
     % erstmal entschlüsseln Was numberic ist 
    line = fgets(fid); % there should be the header line
    tokens = tokenizeLine(line);
    d = length(tokens);
    LineArray =char(tokens);
    Numeric =zeros(d,1);
    for i =1:d
        Numeric(i) = isnumber(LineArray(i,:));
    end %for i
    AnzNumeric = sum(Numeric);
    IsString =ones(d,1);
    IsString(Numeric>0)=0;
    % jetzt für alle Zeilen in der Datei
    while fid ~= -1         
        % if AnzNumeric >0;
            % for i=1:d % alle tokens einer zeile
             % LineData= [];
             % if Numeric(i) ==1
                 % LineData= [LineData,str2num(tokens(i,:))];
             % end; % if
            % end; % For i
        % end; % if  AnzNumeric >0
        
        if  AnzNumeric < d
            TokenStrings = char(tokens);
            StringData=char(StringData,TokenStrings);
           % StringData
        end; % if  AnzNumeric < d
        line = fgets(fid); % Nächste Zeile
        if  line ~= (-1)    
            tokens = tokenizeLine(line);
            d = length(tokens);
            LineArray =char(tokens);     
        else
           fclose(fid);
           fid = -1;
        end; % 
    end; %while
end; % if HasNamesInCols==0 % alles zahlen

cd(CurrentDirrectory);   % Restore current Directory


