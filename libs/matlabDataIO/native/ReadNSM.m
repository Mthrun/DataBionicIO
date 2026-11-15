function [Matrix,LineKey,LineHeader,ColumnHeader,ColumnKey] =  ReadNSM(FileNameWithoutExt,InDirectory);
%  Schreiben einer Named Sparse Matrix(NSM): i.e sparse Matrix mit  mit Zeilen- und Spaltennamen sowie Zeilen und Spalten Keys
% Matrix =  ReadSparseMatrix(FileNameWithoutExt,InDirectory);  % lesen einer Sparse Matrix
% [Matrix,LineKey,LineHeader,ColumnHeader,ColumnKey] =  ReadSparseMatrix(FileNameWithoutExt,InDirectory);
% INPUT
% FileNameWithoutExt                 Dateiname ohne extension
%
% OPTIONAL
% InDirectory                        Directory aus dem gelesen wird
%
% OUTPUT
% Matrix(1:l,1:c)                    Matrix mit l zeilen und c Spalten in sparse Darstellun
%                                    (MATLAB sparse/full)  R: see Matrix package 
% LineKey(1:l)                       Schluessel fuer die Zeilen                            
% LineHeader(1:l,:)                  Char Array mit Bezeichnungen fuer die Zeilen der Matrix       
% ColumnKey(1:c)                     Schluessel für die Spalten der Matrix
% ColumnHeader(1:c,:)                Char Array mit Bezeichnungen fuer die Spalten der Matrix
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2
    InDirectory = cd();
end;
colexist = 1
if exist(fullfile(InDirectory,[FileNameWithoutExt,'.NSMmat.lrn'])) ~= 2
   error( ['ReadNSM: could not find file ',FileNameWithoutExt,'.NSMmat.lrn']);
end;
if exist(fullfile(InDirectory,[FileNameWithoutExt,'.NSMrow.names'])) ~= 2
   error( ['ReadNSM: could not find file ',FileNameWithoutExt,'.NSMrow.names']);
end;
if exist(fullfile(InDirectory,[FileNameWithoutExt,'.NSMcol.names'])) ~= 2
   warning(sprintf( ['ReadNSM: could not find file ',FileNameWithoutExt,'.NSMmat.names \nAssuming the matrix to be square and rows and columns to be the same']));
    colexist = 0;
end;

smatrix = ReadLRN([FileNameWithoutExt,'.NSMmat.lrn'],InDirectory);

% [NamesKey,Names] = ReadNAMES(NamesFileName,Directory);
[LineKey,LineHeader] = ReadNAMES([FileNameWithoutExt, '.NSMrow.names'], InDirectory);
m = length(LineKey)

if colexist == 1
    [ColumnKey,ColumnHeader] = ReadNAMES([FileNameWithoutExt, '.NSMcol.names'], InDirectory);
    n = length(ColumnKey);
else
    ColumnKey = LineKey;
    ColumnHeader = LineHeader;
    n = m;
end;

Matrix = sparse(smatrix(:,1),smatrix(:,2),smatrix(:,3),m,n);


