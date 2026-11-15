function [data,colnames,defined,key_names,cls_names] = loadyale(filename);
% [data,colnames,defined,key_names,cls_names] = loadyale(filename)
% [data,colnames,defined,key_names] = loadyale(filename)
% [data,colnames,defined] = loadyale(filename)
% [data,colnames] = loadyale(filename)
% [data] = loadyale(filename)
% 
% load data from *.exa file and column names and types *.att file 
% 
% INPUT
% filename  name of the file(s)
%
% OUTPUT
% data      matrix of data in file
% colnames  cell array with column names  		 
% defined   vector of column type keys (0=ignore,1=data,3=class,9=index)
% key_names cell array with key names
% cls_names cell array with cls names
% 
%
% in $Source: /data/CVS/ag/dbt/DataIO/loadyale.m,v $
%
% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.2 $
%
% HISTORY
% $Log: loadyale.m,v $
% Revision 1.2  2005/10/24 05:35:36  fabian
% *** empty log message ***
%
% Revision 1.1  2005/10/13 13:14:28  fabian
% *** empty log message ***
%

att_filename = [filename,'.att'];
exa_filename = [filename,'.exa'];

% open attribute file
fid = fopen(att_filename,'r');
if fid == (-1) error(['loadyale: could not open file ', att_filename]); end;

% read in column names and types
colnames = {};
defined = [];
next_type = 0;
col = 0;
while ~feof(fid)
    line = trim(fgets(fid));    
    if strcmp(head(line,1),'<')
        if strcmp(head(line,3),'<id')
            next_type = 9;
        elseif strcmp(head(line,10),'<attribute')
            next_type = 1;        
        elseif strcmp(head(line,6),'<label')            
            next_type = 3;        
        end
    end            
    if strcmp(head(line,4),'name')
        p = strfind(line, '"');
        name = line(p(1)+1:p(2)-1);
    end
    if strcmp(head(line,9),'sourcecol')
        p = strfind(line, '"');
        col = sscanf(line(p(1)+1:p(2)-1), '%d');
    end
    %if strcmp(head(line,9),'valuetype')
    %    p = strfind(line, '"');
    %    type = line(p(1)+1:p(2)-1);
    %end
    if strcmp(head(line,2),'/>')
        colnames{col} = name;
        defined(col) = next_type;
        %if strcmp(type, 'real') | strcmp(type, 'integer')
        %    defined(col) = 1;
        %else
        %    defined(col) = 0;            
        %end
    end    
end
fclose(fid);

% open example file
fid = fopen(exa_filename,'r');
if fid == (-1) error(['loadyale: could not open file ', exa_filename]); end;

% read in data
data = [];
key_names = {};
key = [];
cls_names = {};
cls = [];
cols = find(defined);
j = 1;
while ~feof(fid)
    line = fgets(fid);    
    tokens = strread(line,'%s ');
    d = zeros(1,length(cols));
    for i = 1:length(cols)
        if defined(cols(i))==9
            if ischar(tokens{cols(i)})
                key_names{j} = tokens{cols(i)};
            else
                key(j) = sscanf(tokens{cols(i)}, '%d');
            end
        elseif defined(cols(i))==3
            if ischar(tokens{cols(i)})
                cls_names{j} = tokens{cols(i)};
            else
                cls(j) = sscanf(tokens{cols(i)}, '%d');
            end
        else    
            if strcmp(tokens{cols(i)}, 'Infinity')
                d(i) = inf;
            else
                d(i) = sscanf(tokens{cols(i)}, '%E');    
            end
        end
    end
    data = [data; d];
    j = j+1;
end
fclose(fid);
defined = defined(cols);
if (length(key_names) > 0) && (length(key)==0)
    [key_names, dummy, key] = unique(key_names);
end
if sum(defined==9) == 1
    data(:,find(defined==9)) = key';
end
if (length(cls_names) > 0) && (length(cls)==0)
    [cls_names, dummy, cls] = unique(cls_names);
end
if sum(defined==3) == 1
    data(:,find(defined==3)) = cls';
end

