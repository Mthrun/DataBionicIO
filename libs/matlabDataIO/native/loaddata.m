function [data,colnames,key,cols,cls,rownames,descriptions] = loaddata(prefix, clsnamesprefix);
% [data,colnames,key,cols,cls,rownames,descriptions] = loaddata(prefix, clsnamesprefix)
%
% Load *.lrn file with accompanying *.cls and *.names with same or other given prefix.
% Output parameters cls, rownames, and longnames are generated when files are missing.
%
% INPUT
% prefix          common prefix for *.lrn, *.cls, and *.names files
%
% OPTIONAL
% clsnamesprefix  possibly different prefix for *.cls and *.names files
%
% OUTPUT
% data            data matrix from *.lrn
% colnames        cell array with column names  		 
% key             column number of the index column
% cols            column numbers of the data columns
% cls             class numbers for rows from *.cls file (synchronized by key)
% rownames        cell array row names from *.names file  (synchronized by key)
% descriptions    cell array with long names from *.names file  (synchronized by key)
%
% in $Source: /data/CVS/ag/dbt/DataIO/loaddata.m,v $
%
% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.4 $
%
% HISTORY
% $Log: loaddata.m,v $
% Revision 1.4  2005/04/13 10:03:56  fabian
% *** empty log message ***
%
% Revision 1.2  2004/12/03 10:10:48  fabian
% new IO: scientific notation, faster, sexier.
%
%

if nargin < 2
    clsnamesprefix = prefix;
end    

% load data
[data,colnames,defined] = loadlrn([prefix, '.lrn']);
% fix buggy defined lines by padding with ones
if length(defined) < size(data,2)
    defined = [defined ones(1,size(data,2)-length(defined))];
end
key  = find(defined==9);
% generate key column if missing
if length(key) == 0;
    data = [(1:size(data,1))' data];
    defined = [9 defined];
    key = 1;
end
cols = find(defined==1);
% generate column names if missing
if length(colnames) == 0
    colnames = strmat2cell(int2str(cols'));
end
% load or generate classification
if nargout > 4
    if exist([clsnamesprefix, '.cls'])
        cls = loadcls([clsnamesprefix, '.cls']);
        % synchronize by key if neccessary
        if (size(cls,1)~=size(data,1)) || (sum(cls(:,1)~=data(:,key))>0)
            tmp = zeros(size(data,1),1);
            for i = 1:size(cls,1)
                r = find(data(:,key)==cls(i,1));
                if length(r) == 1
                    tmp(r) = cls(i,2);
                end
            end
            cls = tmp;
        else
            cls = cls(:,2);
        end
    else
        cls = zeros(size(data,1),1);
    end
end    

% load or generate row names
if nargout > 5
    if exist([clsnamesprefix, '.names'])
        [index, rownames, descriptions] =  ReadNAMES([clsnamesprefix, '.names']);
        % synchronize by key if neccessary
        if (length(index)~=size(data,1)) || (sum(index~=data(:,key))>0)
            rtmp = cell(size(data,1),1);
            ltmp = cell(size(data,1),1);            
            for i = 1:length(index)
                r = find(data(:,key)==index(i));
                if length(r) == 1
                    rtmp{r,1} = rownames{i};
                    ltmp{r,1} = descriptions{i};                                        
                end
            end
            rownames = rtmp;
            descriptions = ltmp;                                                    
        end 
    else
        rownames = strmat2cell(int2str(data(:,key)));
        descriptions = rownames;
    end
end    

