function MapMask = ReadIMX(ImxFileName,ImxDirectory);
%  MapMask = ReadIMX(ImxFileName,ImxDirectory);
% read a mask for a tiled UMX to display a ESOM-map
% INPUT
% ImxFileName         the name of the file to read 
% OPTIONAL
% ImxDirectory        the directory where *.imx is, default: current dir
% OUTPUT        
% MapMask             a binary array 1 where the map is displayed 0 otherwise

% 2008 ALU
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin<2 ; ImxDirectory= pwd; end;

% Constants
firstMeta = '%'; commentChar = '#';

CurrentDirrectory = pwd; % Save current Directory
cd(ImxDirectory);

% parameter check
if ~isstr(ImxFileName) error('loadimx: Filename must be a string argument!'); end ;
% datei oeffnen
fid = fopen(ImxFileName,'r');
if fid == (-1) error(['loadimx: Could not open file ', ImxFileName ]); end;

% temporaere datei oeffnen
fidout = fopen('zndIOhlp','w');
if fidout == (-1) error('loadimx: Could not open file zndIOhlp'); end;

% ignoriere metazeilen
line = fgets(fid);
while (line(1) == firstMeta ) + (line(1) == commentChar )
 line = fgets(fid);
end;

% line enthaelt jetzt die erste non-meta zeile
while ~feof(fid) % alles lesen und schreiben
  fprintf(fidout,'%s',line);
  line = fgets(fid);
end;
fprintf(fidout,'%s',line);

% alles zumachen
fclose(fid);
fclose(fidout);

% array aus hilfedatei  bilden
load zndIOhlp;

% hilfsdatei wegwerfen
delete('zndIOhlp');

% for the moment invert it
MapMask = (zndIOhlp==0); 
cd(CurrentDirrectory);   % Restore current Directory




