function GoThroughDirectories(pfad,funktion)
% GoThroughDirectories(pfad,funktion)
%
% arbeitet alle dateien in einem verzeichnis mit unterverzeichnissen mit
% der angegebenen funktion ab
%
% INPUT
% pfad          pfad des verzeichnisses
% funktion      funktion, die auf alle datein in dem verzeichnis angewendet
%               wird
%
% in $Source: /data/CVS/ag/dbt/DataIO/GoThroughDirectories.m,v $
%
% OUTPUT
% No return value. Calls funktion for .lrn files in pfad and its subdirectories.
% The function changes the current directory and uses Windows path separators.

% $Author: kupas $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.2 $
%
% HISTORY
% $Log: GoThroughDirectories.m,v $
% Revision 1.2  2004/11/08 10:24:30  kupas
% geht durch alle unterverzeichnisse eines verzeichnisses und wendet funktion auf die datein in den verzeichnissen an
%

cd(pfad)
Dateien=dir;
for i=3:length(Dateien)
    if (Dateien(i).isdir)
        ['Unterverzeichnis: ' pfad Dateien(i).name '\']
        GoThroughDirectories([pfad Dateien(i).name '\'],funktion)  
        cd(pfad)
    else
        if strcmp(Dateien(i).name(1,end-3:end),'.lrn')==1
           Infilename=Dateien(i).name;
           funktionsaufruf=[funktion,'(' 'Infilename' ');'];
           eval(funktionsaufruf);
       end
    end
end


