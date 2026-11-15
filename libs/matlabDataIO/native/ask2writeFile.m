function [OutFileName,OutDirectory] = ask2writeFile(DialogFilename,extension,dialogTitle);
% [OutFileName,OutDirectory] = ask2writeFile(DialogFilename,extension);
% Benutzerdialog zum Einstellen eines directory und Dateinamens zum 
% Vorbereiten eines anschliessenden Schreibens
%
% INPUT
% DialogFilename      Dateiname der als Default im Dateidialog erscheint
% extension           Angabe welcher dateityp gelesen werden soll Beispiel:  extension ='lrn'
%
% OPTIONAL
% dialogTitle  Character row for the dialog title; absent input uses a default.
%
% OUTPUT
% OutFileName          Dateiname der vom Benutzer ausgeaaehlt wurde
% OutDirectory         Directory welches vom Benutzer bestimmt wurde
% 
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
%
% WARNINGS
% - fuktioniert nicht mit Octave
% - nach dem Aufruf von ask2writeFile ist dies das current directory

% funktioniert nicht mit octave wg. uigetfile
if octave
  error(['ask2writeFile not available in Octave!']); 
end

% Directory und tatsächlichen Dateinamen feststellen
if ~isstr(DialogFilename), 
   error(['ask2writeFile:  no valid Filename ' DialogFilename]); 
end;
if ~isstr(extension), 
   error(['ask2writeFile:  no valid NDM Type ' extension]); 
end;
extension = deblank(extension);

if nargin<3
    [OutFileName,OutDirectory] = uiputfile(['*.' extension],['--> Pleasse select file to write into, perferably: '  DialogFilename]) ;
else
    if isstr(dialogTitle)
        [OutFileName,OutDirectory] = uiputfile(['*.' extension],dialogTitle) ;
    end
end

if not(OutFileName ==0)
    if not(OutDirectory==0), cd(OutDirectory);end;  %Directory einstellen
end; % if OutDirectory==0

