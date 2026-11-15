function [Data,VariableNames] = ReadTSV(TxtFileName,TxtDirectory,CommentChar,HasNamesInColOne);
% [Data,VariableNames] = ReadTSV(TxtFileName,TxtDirectory,CommentChar,HasNamesInColOne);
% read tab separated value datei
% INPUT
% TxtFileName,     name of *.txt file
% 
% OPTIONAL
% TxtDirectory         directory where *.txt file is
% CommentChar          Zeilen, die mit diesem Char anfangen werden ignoriert
% HasNamesInCols       ==1 means Colum 1. is a name column default:  HasNamesInCols =0;
% 
% OUTPUT
% Data(1:AnzLines,1:AnzColumns)   cell array of Data
% VariableNames                   column names of Data

% in $Source: dbt/DataIO/
% Author: ALU
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% Copyright (C) 2011 Databionics Research Group

% default
if nargin < 2;           TxtDirectory = pwd; end; 
if nargin < 3;           CommentChar = '#'; end; 
if nargin < 4 ;          HasNamesInColOne=0; end;

% TxtFileName='AllGOgenes.names';
% TxtDirectory='D:\Mdbt\GeneOntology';
% CommentChar = '#';
% HasNamesInColOne=0;

SaveDirectory = pwd;
cd(TxtDirectory);
% Datei oeffnen
fid = fopen(TxtFileName);
if(fid == -1);  error('ReadTSV: Could not open %s.',TxtFileName); end; 

% skip lines at the beginning
pos = 0;
line = fgetl(fid);
while ~isempty(regexp(line,['^' CommentChar], 'once')) % skip comment lines
    % versionsnummer erfassen 
    pos = ftell(fid);
    line = fgetl(fid);
end;
% line
% line now contains the first valid line

firstline = strread(line,'%s',1,'delimiter','\n');
fseek(fid,pos,'bof'); % set this as first readable byte

AnzColunmns = length(regexp(firstline{1},'(.*?\t)'))+1;
% formatstring zusammenbauen
formatString = '';
for counter = 1:AnzColunmns
        formatString = [formatString '%s'];
end; % for counter = 1:numel(f)
% formatString
% formatString ==  %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s oder ...%*s fuer ignorierbare felder

try        
    % Alles einlesen !
    TextData = textscan(fid,formatString, 'delimiter', '\t'); % tab separated values lesen
    Data = [TextData{:}];  % umpfrimeln zu cellstr
catch theException
        error('ReadTSV: ','%s is not a tab separated value file',TxtFileName);
        rethrow(theException) % terminate and yell
end; % try
fclose(fid);
cd(SaveDirectory);

% header?
if HasNamesInColOne==1 % 1. Zeile mit header
    [AnzLines,AnzColumns] = size(Data);
    VariableNames = char(Data(1,:));
    Data = Data(2:end,:);
else % 1. Zeile ohne header
     VariableNames = [ones(AnzColunmns,1)*'Col' num2str((1:AnzColunmns)')];
end;

