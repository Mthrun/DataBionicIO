function [BestMatches,BMLineCoords,BMColCoords] = ReadBM(BestMatchFileName,BestMatchDirectory);
% BestMatches = ReadBM(BestMatchFileName,BestMatchDirectory);  % oder
% [BMKey,BMLineCoords,BMColCoords] = ReadBM(BestMatchFileName,BestMatchDirectory);
% Load bestmatches from *.bm file
%
% INPUT
% BestMatchFileName     FileName of *.bm file
% OPTIONAL
%
% BestMatchDirectory   directory where *.bm file is, default: current dir
%
% OUTPUT
% BestMatches(1:n,1:n,1:n)   Bestmatches =[BMkey, BMLineCoords, BMColCoords]
%
%

% Neu : ALU 2019 : e-notation, fuer R und 3 Ausabeparameter moeglich
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.


if nargin<2 ; BestMatchDirectory= pwd; end;

% constants
COMMENT = '#';
HEADER  = '%'; 

CurrentDirrectory = pwd; % Save current Directory
cd(BestMatchDirectory);


% make sure extension is there
BestMatchFileName = addfileext(BestMatchFileName,'.bm');
% open file
fid = fopen(BestMatchFileName,'r');
if fid == (-1) error(['loadbm: could not open file ', BestMatchFileName]); end;

% skip over possible comments and headers
line = skiplines(fid, [COMMENT, HEADER]); % line enthaelt jetzt die erste zeile

% read in bestmatches
FirstLine = sscanf(line, '%d');
[RestNumbers,AnzRead] =  fscanf(fid, '%e'); % alle zeilen lesen % eigentlich %d aber wegen R's Glitch
BestMatches = reshape(round([FirstLine;RestNumbers]),3,(AnzRead+3)/3)';


% close file
fclose(fid);
cd(CurrentDirrectory);   % Restore current Directory


% ckeck if Bestmatches o.k.
% Wertebereiche bestimmen
BMKey        = BestMatches(:,1);
BMLineCoords = BestMatches(:,2);
BMColCoords  = BestMatches(:,3);

MinBMx = min(BMLineCoords);MaxBMx = max(BMLineCoords);
MinBMy = min(BMColCoords); MaxBMy = max(BMColCoords); 
if MinBMx*MinBMy <1 % out of Range
    BMLinesRange  = [MinBMx MaxBMx]
    BMColumsRange = [MinBMy MaxBMy]
    warning('loadbm: BestMatches out of Range! use ZZBMRichtigstellen to correct it')
    if MinBMx==0; BMLineCoords=BMLineCoords+1; end;
    if MinBMy==0; BMColCoords =BMColCoords +1; end;
end;

if nargout() ==3; BestMatches = BMKey; end; % [BMKey,BMLineCoords,BMColCoords] = ReadBM(BestMatchFileName,BestMatchDirectory);





