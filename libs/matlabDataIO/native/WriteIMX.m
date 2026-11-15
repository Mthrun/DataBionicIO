function WriteIMX(ImxFileName,Imx, ImxDirectory,Inverted)
% WriteIMX(ImxFileName,Imx, ImxDirectory)
% 
% write an Mask for an Tiled Umatrix Island
% INPUT
% ImxFileName              name of the  file to be written
% Imx(1:Lines,1:Columns)   a binary array of data 
%
% OPTIONAL
% Inverted                 default ==1 means 1 i  Imx is where the map is displayed 0 otherwise	 
%
% The *.imx file contains the information to draw an isle from an U-matrix:
% % k l
% h11	h21	h31	..	hk1
% h12	h22	h32	..	hk2
% .	 .	 .	..	 .
% .	 .	 .	.. 	 .
% h1l	h2l	h3l	..	hkl
% 
% Elements of *.imx file
% k	2 times the number of rows of the trained feature map, corresponds to the entry for rows in the tiled U-Matrix.
% l	2 times the number of columns of the trained feature map, corresponds to the entry for columns in the tiled U-Matrix.
% hij	0 if its a place on the "island" and 1 if its a place in the "see" at position i in x-direction and j in y-direction.
% hij	1 if its a place on the "island" and 0 if its a place in the "see"
% at position i in x-direction and j in y-direction.
% Directory aendern & call savelrn

% (ImxFileName,Imx, ImxDirectory,Inverted)
%   1           2        3           4
% OUTPUT
% An IMX mask file. The function has no return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 4 ;   ImxDirectory = pwd;  end; % use current dir
if nargin < 4 ;   Inverted = 1;        end; % 1 means on island;

if Inverted==1;  Imx= (Imx==0); end; % inversion for compatibility

CurrentDirectory = pwd; % Save current Directory
cd(ImxDirectory);
    % open file
    fid = fopen(ImxFileName,'w');
    if fid == (-1)  error(['WriteIMX: could not open ',ImxFileName]);  end;
    fprintf(fid,'%%\t%d\n%%\t%d\n',size(Imx));           % n und d schreiben

    % daten Schreiben
    [n,d] = size(Imx);
    format ='%.0f'; 
    for i=1:(d-1)
         format =[format,'\t%.0f']; 
    end; % for i
    format =[format,'\n'];
    if n > 1E6;  % grosse datei
        Tacho = waitbar(0,['WriteIMX: /', num2str(n)]);
        for i=1:AnzCases
           fprintf(fid,format,Imx(i,:));
           if mod(i,1000)==0 ; waitbar(i/AnzCases,Tacho,['WriteIMX: ',num2str(i),' /', num2str(n)]); end;
        end;
        close(Tacho);% 
    else
        fprintf(fid,format,Imx'); % leider Spaltenweise deswegen transponieren
    end;
fclose(fid);
cd(CurrentDirectory);   % Restore current Directory

