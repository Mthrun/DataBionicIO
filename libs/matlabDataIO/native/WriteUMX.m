function WriteUMX(UmxFileName,UMatrix,OutDirectory);
% WriteUMX(UmxFileName,UMatrix);
% WriteUMX(UmxFileName,UMatrix,UmxDirectory);
%
% write U-matrix to *.umx file
% 
% INPUT
% UmxFileName                      name of the *.umx file
% UMatrix(1:NrClines,1:NrCols)     matrix with U-Matrix height values
%
% OPTIONAL
% OutDirectory                     directory where *.umx file is written, default: current directory
%
% OUTPUT
%
% Copyright (C) 2005 Databionics Research Group

% ALU 2008
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 3  OutDirectory=pwd;                         end; % default output directory

% Directory aendern & call saveumx
CurrentDirrectory = pwd; % Save current Directory
cd(OutDirectory);

saveumx(UmxFileName, UMatrix);

cd(CurrentDirrectory);   % Restore current Directory


%%%%%%%%%%%%%%%%%%SUBFUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRIVATE SECTION
function saveumx(filename, umx);
% OUTPUT
% No return value. Writes matrix dimensions and numeric values to an UMX file.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

% saveumx(filename, umx);
%
% Save height matrix to an *.umx file
% 
% INPUT
% filename  name of the target file
% umx       matrix with height values

% parameter check
if nargin < 2
  error('saveumx: all 2 input parameters needed!');
end

% make sure extension is there
filename = addfileext(filename,'.umx');

% open file
fid = fopen(filename,'w');
if fid == (-1) error(['saveumx: could not open file ', filename]); end;

% save header: rows+columns
fprintf(fid,'%% %d %d\n',size(umx));
% save data
format = repmat('%E\t',1,size(umx,2));
format(length(format)-1:length(format)) = '\n';
fprintf(fid,format,reshape(umx',prod(size(umx)),1));
fclose(fid);

