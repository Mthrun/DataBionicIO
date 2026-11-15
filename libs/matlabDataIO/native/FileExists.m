function FileIsExistent = FileExists(FileName,Directory);
% FileIsExistent = FileExists(FileName,Directory);
% rcheck if there is such a file

% INPUT
% FileName  File name to check.
% Directory  Directory containing the file.
%
% OUTPUT
% FileIsExistent is 1 if fopen succeeds, otherwise 0.
% The current directory is restored after the check.

% $Author: ALU $ 2011
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.


CurrentDirrectory = pwd; % Save current Directory

cd(Directory);
fid = fopen(FileName,'r');
if fid >0% close file
   fclose(fid);
   FileIsExistent =1;
else
    FileIsExistent =0;
end;



cd(CurrentDirrectory);

