function savesvml(filename, data, cls);
% savesvml(filename, data, cls);
%
% save data and classification in svm light format
% 
% INPUT
% filename  name of the target file
% data      matrix of data in file
% cls       vector with class labels

% open data file
% OUTPUT
% A file with data and class labels in SVMlight format.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

fid = fopen(filename,'w');
if fid == (-1) error(['savesvml: could not open file ', filename]); end;

% save data
%x = zeros(size(data,1),1+2*size(data,2));
%x(:,1) = cls;
%for i = 1:size(data,2)
%    x(:,2*i) = i;
%    x(:,2*i+1) = data(:,i);
%end
format = ['%d    '; repmat('%d:%E ',size(data,2),1)];
format = reshape(format',1,prod(size(format)));
format = sprintf('%s\n', format);
%fprintf(fid,format,reshape(x',prod(size(x)),1));
for i = 1:size(data,1)
    x = zeros(1,1+2*size(data,2));
    x(1) = cls(i);
    x(2:2:end) = 1:size(data,2);
    x(3:2:end) = data(i,:);    
    fprintf(fid,format,x);
end
fclose(fid);

