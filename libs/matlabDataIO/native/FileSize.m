function NrOfBytes = FileSize(FileName,Directory);
% NrOfBytes = FileSize(FileName,Directory);
% get number of bytes in a file
% INPUT
% FileName    name of the file
% 
% OPTIONAL
% Directory   directory of the file, current directory  if not given
%
% OUTPUT 
% NrOfBytes Number of bytes in the file
%
% Uses d = dir(FileName)

% $Author: ALU $ 2015
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

% FileName=OGCfileName;
% Directory=OGCFileDir;

if nargin <2 ; Directory= pwd; end;

CurrentDirrectory = pwd; % Save current Directory

try
  cd(Directory);
  d = dir(FileName);
  NrOfBytes = d.bytes;
catch % could find the file
  NrOfBytes = nan;
end; % try
cd(CurrentDirrectory);

