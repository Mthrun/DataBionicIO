function WriteFigureAsTIFF(TIFFfileName,TIFFDirectory);
% WriteFigureAsTIFF(TIFFfileName,TIFFDirectory);
% write current figure As TIFF
%
% INPUT
% TIFFfileName                 Name of the TIFF output file
%
% OPTIONAL
% TIFFDirectory              where to write, default = current dir

% OUTPUT
% No return value. Writes the current figure as TIFF in TIFFDirectory.

% Author: ALU 2020
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 2  TIFFDirectory=pwd;   end; % default output directory

% Directory aendern & call savecls
CurrentDirrectory = pwd; % Save current Directory
cd(TIFFDirectory);

print('-dtiff',TIFFfileName); % als tiff auschreiben
cd(CurrentDirrectory);   % Restore current Directory

