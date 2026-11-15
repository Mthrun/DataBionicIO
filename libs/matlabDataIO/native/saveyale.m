function saveyale(filename, data, cls, names, key, lbltype);
% saveyale(filename, data, cls, names, key);
%
% save data and classification *.att and *.exa yale files
% 
% INPUT
% filename  name of the target files without extension
% data      matrix of data in file
%
% OPTIONAL
% cls       vector with class labels
% names     cell array with column names for data (not key or class)
% key       vector unique ids for rows in data, default 1:n
% lbltype   Optional class attribute type; default nominal.
%
% in $Source: /data/CVS/ag/dbt/DataIO/saveyale.m,v $
%
% OUTPUT
% No return value. Writes filename.att metadata and filename.exa records.

% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.4 $
%
% HISTORY
% $Log: saveyale.m,v $
% Revision 1.4  2006/01/16 06:44:35  fabian
% *** empty log message ***
%
% Revision 1.3  2005/10/13 13:14:28  fabian
% *** empty log message ***
%
% Revision 1.2  2005/04/18 10:07:39  fabian
% io fixes: better error messages and optional better readable lrn
%
% Revision 1.1  2005/04/13 10:10:55  fabian
% *** empty log message ***
%
% Revision 1.2  2005/03/02 13:37:31  fabian
% *** empty log message ***
%
% Revision 1.1  2005/01/13 14:59:13  fabian
% *** empty log message ***
%

% parameter check and defaults
if nargin < 2
  error('saveyale: at least 2 input parameters needed!');
end
if nargin < 5
    key = (1:size(data,1))';
end
if nargin < 6
    lbltype = 'nominal';
end
if nargin > 3
    % convert to cell array if string matrix is given
    if ~iscell(names)
        names = strmat2cell(names);
    end
else
    for i = 1:size(data,2)
        names{i} = ['C', int2str(i)];
    end
end
if (nargin > 2) && (size(cls,1) > 0)
    if size(data,1) ~= size(cls,1)
        error(sprintf('saveyale: size of data and cls do not match: %d vs. %d', size(data,1), size(cls,1)));
    end
end

exa_filename = [filename, '.exa'];
att_filename = [filename, '.att'];

% open data file
fid = fopen(exa_filename,'w');
if fid == (-1) error(['saveyale: could not open file ', exa_filename]); end;

% save data
exa = [key data];
format = ['%d\t'; repmat('%E\t',size(data,2),1)];
if (nargin > 2) && (size(cls,1) > 0)
%    exa = [exa cls];
    format = [format; '%d\t'];
end
format = reshape(format',1,prod(size(format)));
format(length(format)-1:length(format)) = '\n';
%fprintf(fid,format,reshape(exa',prod(size(exa)),1));
for i = 1:size(exa,1)
    if (nargin > 2) && (size(cls,1) > 0)
        fprintf(fid,format,exa(i,:),cls(i));
    else
        fprintf(fid,format,exa(i,:));
    end
end
fclose(fid);

% open attribute file
fid = fopen(att_filename,'w');
if fid == (-1) error(['saveyale: could not open file ', att_filename]); end;
[path, file, ext] = fileparts(exa_filename);
fprintf(fid,'<attributeset default_source="%s">\n', [file, ext]);
% key
fprintf(fid,'\t<id\n');
fprintf(fid,'\t\tname       ="%s"\n', 'Key');
fprintf(fid,'\t\tsourcecol  ="%d"\n', 1);
fprintf(fid,'\t\tvaluetype  ="integer"\n');
fprintf(fid,'\t\tblocktype  ="single_value"\n');
fprintf(fid,'\t/>\n');
% data
for i = 1:size(data,2)
    fprintf(fid,'\t<attribute\n');
    if length(names) > 0
        fprintf(fid,'\t\tname       ="%s"\n', names{i});
    else
        fprintf(fid,'\t\tname       ="%d"\n', i);        
    end
    fprintf(fid,'\t\tsourcecol  ="%d"\n', i+1);
    fprintf(fid,'\t\tvaluetype  ="real"\n');        
    fprintf(fid,'\t\tblocktype  ="single_value"\n');
    fprintf(fid,'\t/>\n');
end
% class
if (nargin > 2) && (size(cls,1) > 0)
    fprintf(fid,'\t<label\n');
    fprintf(fid,'\t\tname       ="%s"\n', 'Class');
    fprintf(fid,'\t\tsourcecol  ="%d"\n', size(data,2)+2);
    fprintf(fid,'\t\tvaluetype  ="%s"\n', lbltype);
    fprintf(fid,'\t\tblocktype  ="single_value"\n');
    fprintf(fid,'\t/>\n');
end
fprintf(fid,'</attributeset>\n');
fclose(fid);

