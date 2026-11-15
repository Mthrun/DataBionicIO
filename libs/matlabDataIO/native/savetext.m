function savetext(filename, text);
% savetext(filename, text);
%
% save strings in text file
% 
% INPUT
% filename  name of the target files without extension
% text      cell array with strings
%
% in $Source: /data/CVS/ag/dbt/DataIO/savetext.m,v $
%
% OUTPUT
% No return value. Writes one text cell per line to filename; no extension is added.

% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.1 $
%
% HISTORY
% $Log: savetext.m,v $
% Revision 1.1  2005/05/09 09:39:34  fabian
% *** empty log message ***
%

% make sure extension is there
%filename = addfileext(filename,'.txt');

% open file
fid = fopen(filename,'w');
if fid == (-1) error(['savetext: could not open file ', filename]); end;

% save lines
for i = 1:length(text)
    fprintf(fid,'%s\n', text{i});
end
fclose(fid);

