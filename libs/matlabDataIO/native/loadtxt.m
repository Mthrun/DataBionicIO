function [data,names,Comment] = loadtxt(filename, hasnames, skip);
% [data,names,Comment] = loadtxt(filename);
% [data,names,Comment] = loadtxt(filename, hasnames, skip);
%
% try to load data from *.txt file
% 
% INPUT
% filename  name of the file
% OPTIONAL
% hasnames  flag whether to parse first line for column names  default: 0
% skip      lines to skip at beginning of file,                default: (nargout > 1)
%
% OUTPUT
% data      matrix of data in file
% names     cell array with column names  		 
% Comment   die zeielen die mit # anfangen

% Copyright (C) 2005 Databionics Research Group

% default
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 3 skip = 0; end; 
if nargin < 2 hasnames = (nargout > 1); end;

% open file
fid = fopen(filename,'r');
if fid == (-1) error(['loadtxt: could not open file ', filename]); end;
   
% open temporary file
fidout = fopen('zndIOhlp','w');
if fidout == (-1) error('loadtxt: could not open file zndIOhlp'); end;

% skip lines
for i = 1:skip; fgets(fid); end;

% zeilen mit # 
Line = fgets(fid);
Comment = '';
while(Line(1) =='#')
    Comment = char(Comment,Line); 
    Line = fgets(fid);
end; % while
[n,d] = size(Comment);
if n>1  
    Comment = Comment(2:end,:); 
else 
    Comment = '';
end% if n>1  

% parse names in first line 
if hasnames==1
   NamesLine = strtrim(Line);   % read Line of Names
   names = strread(NamesLine,'%s\t'); % convert to char array
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

