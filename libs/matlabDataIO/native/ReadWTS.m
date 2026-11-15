function [Wts, rows, columns, topology] = ReadWTS(WtsFileName,WtsDirectory);
% [Wts, rows, columns, topology] = ReadWTS(WtsFileName,WtsDirectory);
%
% Load ESOM weights from a *.wts file  
% 
% INPUT
% WtsFileName      name of the file
% OPTINAL 
% WtsDirectory     the directrory where the *.wts file is
%
% OUTPUT
% Wts              weights  in following oder: 
% rows             number of ESOM rows    from header in *.wts file
% columns          number of ESOM columns from header in *.wts file
% topology         'toroid' or 'planar'   from header in *.wts file
%
% in $Source: /data/CVS/ag/dbt/DataIO/loadwts.m,v $
%
% $Author: ultsch $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 2.0 $
%
if nargin < 2  WtsDirectory=pwd;  end; % default output directory

% constants
COMMENT = '#';
HEADER  = '%'; 

CurrentDirrectory = pwd; % Save current Directory
cd(WtsDirectory);


% make sure extension is there
WtsFileName = addfileext(WtsFileName,'.wts');

% open file
fid = fopen(WtsFileName,'r');
if fid == (-1) error(['loadwts: could not open file ', WtsFileName]); end;

% read params from comment
topology = 'planar';
line = fgets(fid);
while (length(line)==0) || contains(COMMENT, line(1))
    if contains(lower(line), 'toroid')
        topology = 'toroid';
    end
    line = fgets(fid);
end

% parse first row of header for rows and cols
header = sscanf(deblank(head(line,-1)), '%d');
rows = header(1);
columns = header(2);

% skip over rest of header
line = skiplines(fid, HEADER);

% read data NOTE line contains already the first line of data
if isstr(line)
    cleanline= strrep(line, ',', ''); % remove ','
    Wts  = sscanf(cleanline, '%g')';
    cols = length(Wts);
    % read next lines ignoring ','
    line = fgets(fid);
    while isstr(line)
        cleanline= strrep(line, ',', ''); % remove ','
        NextWts  = sscanf(cleanline, '%g')';
        Wts  = [Wts; NextWts];
        line = fgets(fid);
    end; % while
else
    Wts  = [];
end

% close file
fclose(fid);
cd(CurrentDirrectory);   % Restore current Directory

