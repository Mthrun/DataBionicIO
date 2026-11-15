function WriteTXT(FileName,Names,OutDirectory,StrTrim,Header,RemoveTrailingBlanks);
% WriteTXT(FileName,Names,OutDirectory);
% WriteTXT(FileName,Names,OutDirectory,StrTrim,Header);
% Save Only names 
%
% Alternatively
% WriteTXT(FileName,[],OutDirectory,CharArray);
%
% INPUT
% FileName                 name of the  file to be written
% Names(1:d,1:s) or []     cell array or string matrix with column names  	
%
% OPTIONAL
% OutDirectory             the directory where to write into; if not given: current dir.
% StrTrim                  ==1 (default) bedeutet keine leading+ trailing blanks  schreiben
% Header                  Ueberschriften als array of char
% RemoveTrailingBlanks     Blanks am ende der Zeile werden nicht mit geschreiben
%
% OUTPUT
% No return value. Writes Names, or the alternative character array, as text lines.

% $Author: ultsch $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.5 $

[NrData,NameLength] = size(Names);
% (FileName,Names,OutDirectory,StrTrim,Header,RemoveTrailingBlanks);
%    1       2          3        4       5         6
if nargin < 3  OutDirectory=pwd;                         end; % default output directory
if nargin < 4; StrTrim=1;                                end; % ==1 (default) bedeutet keine leading+ trailing blanks 
if nargin < 5; Header=[];                                end; % Ueberschriften als array of char
if nargin < 5; RemoveTrailingBlanks =1;                  end; % Blanks am ende der Zeile werden nicht mit geschreiben
% Directory aendern 
CurrentDirrectory = pwd; % Save current Directory
cd(OutDirectory);

fid = fopen(FileName,'w');
if fid == (-1) error(['WriteTXT: could not open file ', filename]); end;

if isempty(Names) % nurCharArray schreiben  WriteTXT(FileName,[],OutDirectory,CharArray);
   CharArray = StrTrim;
   [n,d] = size(CharArray);
   for i=1:n
       if RemoveTrailingBlanks==1; Line = deblank(CharArray(i,:));else Line = CharArray(i,:); end; 
       fprintf(fid, '%s', Line);
       fprintf(fid, '\n'); 
   end; % for i                 
else % WriteTXT(FileName,Names,OutDirectory,StrTrim,Header);
    [AnzCols dummy] = size(Header);
    if AnzCols >0 % Ueberschrifen schreiben
        for i = 1:AnzCols 
            fprintf(fid, '%s', strtrim(Header(i,:)));
            if i<AnzCols ;    fprintf(fid, '\t'); else fprintf(fid, '\n'); end;            
        end;% for i
    end; % if length(Header)>0) 
    [AnzCols dummy] = size(Names);
    if StrTrim==1
        % zeilenweise Datei schreiben: Names
        for l = 1:NrData       
           fprintf(fid, '%s\n', strtrim(char(Names(l,:))));
        end;% for l
    else % mit leading/trailing blanks
        % zeilenweise Datei schreiben: Names
        for l = 1:NrData       
           fprintf(fid, '%s\n', char(Names(l,:)));
        end;% for l
    end; % if StrTrim==1
end; % if isempty(Names) % nurCharArray schreiben  WriteTXT(FileName,[],OutDirectory,CharArray);

fclose(fid);
cd(CurrentDirrectory);   % Restore current Directory

