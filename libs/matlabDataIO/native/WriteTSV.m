function WriteTSV(FileName,Data,Header,OutDirectory);
% WriteTSV(FileName,Data,Header,OutDirectory);
% write a tab-separated file eventueally inclunding Header == NAmes
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
% No return value. Writes tab-separated numeric rows and an optional header.

% $Author: ALU 2011
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

[NrData NrCols] = size(Data);
if nargin < 4 | isempty(OutDirectory); OutDirectory=pwd; end;
if nargin < 3 | isempty(Header);        HeaderNotGiven=1; else HeaderNotGiven=0;  end;


% Directory aendern 
CurrentDirrectory = pwd; % Save current Directory
cd(OutDirectory);

    % open file
    fid = fopen(FileName,'w');
    if fid == (-1) error(['WriteTSV: could not open file ', filename]); end;
    
    % header Zeile schreiben, wenn da
    if HeaderNotGiven==0 % Write Header zeile
        for i = 1:length(Header)
            fprintf(fid,'%s\t',Header(i,:));
        end; % for i
        fprintf(fid,'\n');
    end; %    if HeaderNotGiven=0 % Header zeile
    
    % einfache While Schleife abarbeiten und zeilenweise schreiben
    [NrLines NrCols] = size(Data);
    % schauen ob Daten integer sind
    for l=1:NrLines
        Diff = abs(Data(l,:)-fix(Data(l,:))); % Daten unterscheiden sich von ihren gerundeten ?
        if (max(Diff) <0.000006) & (max(Data(l,:)) <1000000000)OutFormat = '%i'; else  OutFormat = '%g'; end; % entweder integer oder E
        fprintf(fid,[OutFormat '\t'],Data(l,1:end-1));   % Tabs nur bis vorletzte spalte
        fprintf(fid,OutFormat,       Data(l,end));       % letzte spalte
        if l < NrLines; fprintf(fid,'\n'); end;% Newline nur bis vorletzte zeile
    end;

    fclose(fid);    
cd(CurrentDirrectory);   % Restore current Directory

