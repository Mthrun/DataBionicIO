function WriteBM(FileName, BestMatches,OutDirectory,UmxSize);
% WriteBM(FileName, BestMatches);
% WriteBM(FileName, BestMatches,OutDirectory);
%
% Save bestmatches to a *.bm file.
%
% INPUT
% FileName              FileName of *.bm file
% BestMatches           3 column integer matrix with key, row, column
%
% OPTIONAL
% OutDirectory          where to write, default = current dir
% UmxSize==[Lines,Columns] of the corresponding U-matrix 
%                       Lines=    max(BestMatches(:,2) if not given
%                       Columns=  max(BestMatches(:,3) if not given

% OUTPUT
% A BM file with best-match coordinates. The function has no return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 4
     Lines=    max(BestMatches(:,2));
     Columns=  max(BestMatches(:,3));
else
    Lines  = UmxSize(1);
    Columns= UmxSize(2);
end; % if nargin < 4
if nargin < 3  OutDirectory=pwd;  end; % default output directory
if nargin < 2
  error('WriteBM: parameter BestMatches not found');
end

% make sure extension is there
FileName = addfileext(FileName,'.bm');

% Directory aendern
CurrentDirrectory = pwd; % Save current Directory
cd(OutDirectory);

    % save bestmatches
    fid = fopen(FileName,'w');
    if fid == (-1) error(['WriteBM: could not open file ', FileName]); end;
    % write header
    fprintf(fid,'%%\t%d\t%d\n',Lines,Columns); % Lines & Columns
    fprintf(fid,'%%\t%d\n',length(BestMatches(:,2))); % Number of BM
    % write data
    fprintf(fid,'%d\t%d\t%d\n',reshape(BestMatches',prod(size(BestMatches)),1));
    fclose(fid);

cd(CurrentDirrectory);   % Restore current Directory



