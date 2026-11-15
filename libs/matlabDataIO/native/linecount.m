function count = linecount(file);
% count = linecount(filename)
%
% count lines in a file
% 
% INPUT
% file      name of the file of id of open file
%
% OUTPUT
% count     number of lines
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if ischar(file(1))
    fid = fopen(file,'r');
    if fid == (-1) error(['linecount: could not open file ', file]); end;
else
    fid = file;
end
count = 0;
while ~feof(fid)    
    fgets(fid);
    count = count+1;
end
if ischar(file(1))
    fclose(fid);
end

