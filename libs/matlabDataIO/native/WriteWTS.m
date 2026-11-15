function WriteWTS(FileName, wts, rows, columns,OutDirectory);
%  WriteWTS(FileName, wts, rows, columns,OutDirectory);
%
% Save ESOM weights to a *.wts file
% 
% INPUT
% FileName                 name of the target file
% data                      matrix of data in file
% wts                       weights as 2D matrix
% rows                      number of ESOM rows from header
% columns                   number of ESOM columns from header
% OPTINAL
% OutDirectory              where to write, default = current dir


% OUTPUT
% A WTS file with ESOM weights. The function has no return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 5  OutDirectory=pwd;                         end; % default output directory
if nargin < 4
  error('WriteWTS: at least 4 input parameters needed!');
end

% make sure extension is there
FileName = addfileext(FileName,'.wts');

% Directory aendern
CurrentDirrectory = pwd; % Save current Directory
cd(OutDirectory);

% open file
    fid = fopen(FileName,'w');
    if fid == (-1) error(['WriteWTS: could not open file ', FileName]); end;

    % save header
    fprintf(fid,'%% %d %d\n',rows, columns);
    fprintf(fid,'%% %d\n',size(wts,2));
    fprintf(fid,'%% ');
    fprintf(fid,'%d\t',ones(1,size(wts,2)));
    fprintf(fid,'\n');

    % save data
    format = repmat('%E\t',1,size(wts,2));
    format(length(format)-1:length(format)) = '\n';
    fprintf(fid,format,reshape(wts',prod(size(wts)),1));
    fclose(fid);
    
cd(CurrentDirrectory);   % Restore current Directory


