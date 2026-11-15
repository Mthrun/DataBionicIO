function [data,names] = FABloadtxt(filename, hasnames, skip);
% The old function name was loadtxt. Match FABloadtxt.m to prevent a name conflict.
% [data,names] = FABloadtxt(filename);
%
% try to load data from *.txt file
% 
% INPUT
% filename  name of the file
% hasnames  flag whether to parse first line for column names
% skip      lines to skip at beginning of file
%
% OUTPUT
% data      matrix of data in file
% names     cell array with column names  		 
%
% in $Source: /data/CVS/ag/dbt/DataIO/loadtxt.m,v $
%
% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.5 $
%
% HISTORY
% $Log: loadtxt.m,v $
% Revision 1.5  2005/04/13 10:03:56  fabian
% *** empty log message ***
%
% Revision 1.2  2004/12/03 10:10:48  fabian
% new IO: scientific notation, faster, sexier.
%
%

% default
if nargin < 3
    skip = 0;
end
if nargin < 2
    hasnames = 0;
end

% open file
fid = fopen(filename,'r');
if fid == (-1) error(['loadtxt: could not open file ', filename]); end;
   
% open temporary file
fidout = fopen('zndIOhlp','w');
if fidout == (-1) error('loadtxt: could not open file zndIOhlp'); end;

% skip lines
for i = 1:skip; fgets(fid); end;

% parse names
if hasnames==1
    names = strread(deblank(fgets(fid)),'%s\t');
end

% copy to temporary file
while ~feof(fid)
  line = fgets(fid);
  if line ~= -1
      line = strrep(line,',','.');
      fprintf(fidout,'%s',line);  
  end
end;

% close files
fclose(fid);
fclose(fidout);

% read temp file
load zndIOhlp;
data = zndIOhlp;

% hilfsdatei wegwerfen
delete('zndIOhlp');

