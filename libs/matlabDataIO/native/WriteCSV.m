function WriteCSV(FileName,Data,Header,OutDirectory);
% WriteCSV(FileName,Data,Header,OutDirectory);
% write a Coma-separated file eventueally inclunding Header == Names
%
% INPUT
% FileName                 name of the  file to be written
% Data(1:n,1:d)            the data to be written
%
% OPTIONAL
% Header(1:d,1:s) or []     string matrix with column names  	
% OutDirectory             the directory where to write into; if not given: current dir.

%
% OUTPUT
% No return value. Writes comma-separated numeric rows and an optional header.

% $Author: ALU 2011
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.



[NrData NrCols] = size(Data);
if nargin < 4 | isempty(OutDirectory); OutDirectory=pwd; end;
if nargin < 3 | isempty(Header);        HeaderNotGiven=1; else HeaderNotGiven=0;  end;

SEPARATOR = ',' ;                              % dieses zeichen wird zur  Trennung der Felder benutzt

% Directory aendern 
CurrentDirrectory = pwd; % Save current Directory
cd(OutDirectory);
[n,d] = size(Data);

    % open file
    fid = fopen(FileName,'w');
    if fid == (-1) error(['WriteCSV: could not open file ', filename]); end;
    
    % header Zeile schreiben, wenn da
    if HeaderNotGiven==0 % Write Header zeile
        for i = 1:d
            fprintf(fid,'%s',deblank(Header(i,:)));        % einzelueberschrift schreiben
			fprintf(fid,SEPARATOR );                       % komma als trennzeichen
        end; % for i
        fprintf(fid,'\n');                                 % zeileunumberuch fuer Header
    end; %    if HeaderNotGiven=0 % Header zeile
    
    % einfache While Schleife abarbeiten und zeilenweise schreiben
    [NrLines NrCols] = size(Data);
    % schauen ob Daten integer sind
    for l=1:NrLines
        Diff = abs(Data(l,:)-fix(Data(l,:))); % Daten unterscheiden sich von ihren gerundeten ?
        if (max(Diff) <0.000006) & (max(Data(l,:)) <1000000000)OutFormat = '%i'; else  OutFormat = '%g'; end; % entweder integer oder E
        for c =1:d-1
		   fprintf(fid,OutFormat,Data(l,c));             % Comma nur bis vorletzte spalte
		  fprintf(fid,SEPARATOR );                       % komma als trennzeichen
		end; % for c
        fprintf(fid,OutFormat,       Data(l,end));       % letzte spalte
        if l < NrLines; fprintf(fid,'\n'); end;% Newline nur bis vorletzte zeile
    end;

    fclose(fid);    
cd(CurrentDirrectory);   % Restore current Directory

