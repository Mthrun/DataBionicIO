function [InFileName,InDirectory] = ask2loadFile(DialogFilename,extension,dialogTitle,FilePrefix);
% Benutzerdialog zum Einstellen eines Directory und zum Vorbereiten des 
% Lesens des entsprechenden NDM Dateityps
%
% INPUT
% DialogFilename        Dateiname der als Default im Dateidialog erscheint
% extension             Angabe welcher dateityp gelesen werden soll Beispiel:  extension ='lrn'
%
% OPTIONAL
% dialogTitle          the dialog title. if omitted or 0, a default title will be generated
% FilePrefix           when searing only files names FilePrefix*.extension are sought
%
% OUTPUT
% InFileName          Dateiname der vom Benutzer ausgeaaehlt wurde
% InDirectory         Directory welches vom Benutzer bestimmt wurde
%
% WARNINGS
% - fuktioniert nicht mit Octave
% - nach dem Aufruf von ask2loadfile ist dies das current directory

% funktioniert nicht mit octave wg. uigetfile
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if octave
  error(['ask2loadFile not available in Octave!']); 
end

% Directory und tatsächlichen Dateinamen feststellen
if ~isstr(DialogFilename), 
   error(['ask2loadfile:  no valid Filename ' DialogFilename]); 
end;
if ~isstr(extension), 
   error(['ask2loadfile:  no valid NDM Type ' extension]); 
end;
extension = deblank(extension);
if nargin ==4 % FilePrefix given
	SearchFor = deblank([FilePrefix '*.' extension]);
else
	SearchFor = deblank(['*.' extension]);
end;  % if nargin ==4 % FilePrefix given

if (nargin<3) | (dialogTitle == 0)% no dialogTitle specified
    [InFileName,InDirectory] = uigetfile(SearchFor,['--> Please look for: '  DialogFilename]) ;
else % dialogTitle specified
    if isstr(dialogTitle)
        [InFileName,InDirectory] = uigetfile(SearchFor,dialogTitle) ;
    end
end

%Directory einstellen
if InDirectory==0
   error(['ask2loadfile:  no valid Directory ' InDirectory]); 
else
   cd(InDirectory);
end; % if InDirectory==0

