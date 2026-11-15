function WriteNSM(FileNameWithoutExt,Matrix,LineKey,OutDirectory,LineHeader,ColumnHeader,ColumnKey);
% Schreiben einer Named Sparse Matrix(NSM): i.e sparse Matrix mit  mit Zeilen- und Spaltennamen sowie Zeilen und Spalten Keys
% WriteSparseMatrix(FileNameWithoutExt,Matrix); % schreiben einer spaerlichen Matrix
% WriteSparseMatrix(FileNameWithoutExt,Matrix,LineKey,OutDirectory,LineHeader,ColumnHeader,ColumnKey);
% INPUT
% FileNameWithoutExt                 Dateiname ohne extension
% Matrix(1:l,1:c)                    Matrix mit l zeilen und c Spalten in sparse Darstellun
%                                    (MATLAB sparse/full)  R: see Matrix package 
% OPTIONAL
% OutDirectory                       Directory in das geschrieben wird,                       default: current directory
% LineKey(1:l)                       Schluessel fuer die Zeilen,                              default: [1:l]                
% LineHeader(1:l,:)                  Char Array mit Bezeichnungen fuer die Zeilen der Matrix, default: []      
% ColumnKey(1:c)                     Schluessel für die Spalten der Matrix                    default: [1:c]  
% ColumnHeader(1:c,:)                Char Array mit Bezeichnungen fuer die Spalten der Matrix default: [] 

% OUTPUT
% A named sparse-matrix file. The function has no return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

[i, j, x] = find(Matrix);
m = [i, j, x];
[numlines, numcols] = size(Matrix);
cols = true
if nargin < 6
    if numlines == numcols
        %assume matrix to be symmetric
        cols = false
    end;
    ColumnHeader = strcat('C',num2str(transpose([1:numcols])));
elseif nargin < 7
    ColumnKey = [1:numcol];
end;
if nargin < 5
    LineHeader = strcat('L',num2str(transpose([1:numlines])));
end;
if nargin < 4
    OutDirectory = cd();
end;
if nargin < 3
    LineKey = transpose([1:numlines]);
end;
% if nocols
%     ColumnHeader = LineHeader;
%     ColumnKey    = LineKey;
% end;
WriteLRN(strcat(FileNameWithoutExt, '.NSMmat.lrn'), m, [],[],[], OutDirectory);
WriteNAMES(strcat(FileNameWithoutExt, '.NSMrow.names'), LineHeader, LineKey, [], OutDirectory);
% WriteNAMES(FileName,Names,Key,RowRest, Directory,[],Comment);
if cols
    WriteNAMES(strcat(FileNameWithoutExt, '.NSMcol.names'), ColumnHeader, ColumnKey, [], OutDirectory);  
end;

