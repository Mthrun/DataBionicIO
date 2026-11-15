function UMatrix = ReadUMX(UmxFileName,UmxDirectory);
% UMatrix = ReadUMX(UmxFileName,UmxDirectory);
%
% Load height matrix from *.umx file
% 
% INPUT
% UmxFileName                        name of the *.umx file
% OPTIONAL
% UmxDirectory                       directory where *.umx file is, default: current dir
%
% OUTPUT
% UMatrix(1:NrClines,1:NrCols)       matrix with U-Matrix height values
%
% Copyright (C) 2005 Databionics Research Group

% ALU 2008
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin <2 ; UmxDirectory = pwd; end;

% constants
COMMENT = '#';
HEADER  = '%'; 

CurrentDirrectory = pwd; % Save current Directory
cd(UmxDirectory);

% make sure extension is there
UmxFileName = addfileext(UmxFileName,'.umx');

% open file
fid = fopen(UmxFileName,'r');
if fid == (-1) error(['ReadUMX: could not open file ', UmxFileName]); end;

% skip over possible comments and headers
line = skiplines(fid, [COMMENT, HEADER]);

% read data
if isstr(line)
    UMatrix  = sscanf(line, '%f');
    cols = length(UMatrix);
    UMatrix  = [UMatrix; fscanf(fid, '%f')];
    UMatrix  = reshape(UMatrix,cols,length(UMatrix)/cols)';
else
    UMatrix = [];
end

% close file
fclose(fid);
cd(CurrentDirrectory);   % Restore current Directory

