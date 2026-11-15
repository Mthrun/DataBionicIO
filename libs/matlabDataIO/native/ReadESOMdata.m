function [UMatrix,IsToroid,BestMatches,Pmatrix,UsternMatrix,MapMask,Wts,Key,Data,Header,Cls] =  ReadESOMdata(UmxFileName,UMXDirectory,UsternFileName,LrnFileName,LrnDirectory,ClsFileName,CLSDirectory,...
                                                                                                 ImxFileName,ImxDirectory,UsternDirectory);
% Read an ESOM result bundle and optional data files.
% INPUT
% UmxFileName  UMX file name; its base name also selects the BM and WTS files.
% UMXDirectory  Directory containing the UMX, BM, and WTS files.
% OPTIONAL
% UsternFileName  Optional U-matrix file; empty input omits it.
% LrnFileName  Optional LRN file; empty input omits it.
% LrnDirectory  LRN directory; the default is UMXDirectory.
% ClsFileName  Optional CLS file; empty input omits it.
% CLSDirectory  CLS directory; the default is UMXDirectory.
% ImxFileName  Optional mask file; empty input omits it.
% ImxDirectory  Mask directory; the default is UMXDirectory.
% UsternDirectory  Optional U-matrix directory; the default is UMXDirectory.
% OUTPUT
% UMatrix, BestMatches, and Wts contain the UMX, BM, and WTS data.
% IsToroid contains the topology value from ReadWTS. Pmatrix remains empty.
% UsternMatrix contains the optional U-matrix, or is empty if it cannot be read.
% MapMask contains the optional mask, or 1 when no mask is supplied.
% Key, Data, and Header contain the optional LRN result, or are empty.
% Cls contains the optional CLS labels, or is empty.

% AUTHOR: ALU, 2025
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.


% (UmxFileName,UMXDirectory,UsternFileName,LrnFileName,LrnDirectory,ClsFileName,CLSDirectory,ImxFileName,ImxDirectory,UsternDirectory);
%      1          2           3             4           5             6            7               8            9             10

if ((nargin() < 3)|length(UsternFileName)<2);   UsternFileName  = [] ;                  end; %  not given
if ((nargin() < 4)|length(LrnFileName)<2);      LrnFileName  = [];  LrnDirectory=[];    end; % % *.lrn nicht angefordert
if ((nargin() < 5)|length(LrnDirectory)<2);     LrnDirectory = UMXDirectory ;           end; % % liegt im gleichen dir
if ((nargin() < 6)|length(ClsFileName)<2);      ClsFileName  = [] ;                     end; % % keine cls
if ((nargin() < 7)|length(CLSDirectory)<2);     CLSDirectory = UMXDirectory ;           end; %  liegt im gleichen dir
if ((nargin() < 8)|length(ImxFileName)<2);      ImxFileName  = [] ;                     end; %  not given
if ((nargin() < 9)|length(ImxDirectory)<2);     ImxDirectory = UMXDirectory ;           end; %  liegt im gleichen dir
if ((nargin() <10)|length(UsternDirectory)<2);  UsternDirectory = UMXDirectory ;        end; %  liegt im gleichen dir

ImxFileName 
ImxDirectory

% Alle Ausgaben initialisieren
 UMatrix               = []; 
 IsToroid              =  1; %
 BestMatches           = []; 
 Pmatrix               = []; 
 UsternMatrix          = []; 
 MapMask               =  1;   %  no Insel, no masking
 Wts                   = []; 
 Key                   = []; 
 Data                  = []; 
 Heaader               = []; 
 Cls                   = []; 

% die zu Umx gehoerenden Dateien ( voraussetzung ist kanonisce
% Namen der zu UmxFileName gehoerenden Dateien
[dummy,UMXfilePrefix] = fileparts(UmxFileName);
BestMatchFileName   = [UMXfilePrefix, '.bm'];
BestMatchDirectory  = UMXDirectory ;
WtsFileName         = [UMXfilePrefix,'.wts'];
WtsDirectory        = UMXDirectory ;
% if length(ImxFileName) >0;    ImxFileName         = [UMXfilePrefix,'.imx']; end;
% if length(UsternFileName) >0; UsternFileName      = [UMXfilePrefix,'_ustar.wts']; end;

% Umx lesen 	
UMatrix = ReadUMX(UmxFileName,UMXDirectory);
[Zeilen,Spalten] = size(UMatrix);
% wts lesen
[Wts, Lines,Columns, IsToroid] = ReadWTS(WtsFileName,WtsDirectory); % 
% SizeOfMatrix =[Lines,Columns]
% Best matches lesen
BestMatches = ReadBM(BestMatchFileName,BestMatchDirectory);
BMKey = BestMatches(:,1);

% ggf Ustern lesen
if length(UsternFileName)>0
    try
       UsternMatrix = ReadUMX(UsternFileName,UsternDirectory); % versuchs mal
    catch
        UsternMatrix          = [];             % hat nicht geklappt
    end
    % KeyOKBM = TheSameKey(BMKey,Key) %%%
else
     UsternMatrix          = []; 
end; % Ustern lesen

% OPtional
%% Lrn und  Cls lesen
if length(LrnFileName)>0
    [Data,Key,Header] = ReadLRN(LrnFileName,LrnDirectory);
    KeyOKBM = TheSameKey(BMKey,Key)
else
    Data= []; Key= []; Header= []; ;
end; % Lrn lesen

if length(ClsFileName) >0
	[ClsKey,Cls]   = ReadCLS(ClsFileName,CLSDirectory);
	% keys ueberpruefen
	KeyOKCls = TheSameKey(ClsKey,Key)
else
   Cls = [];
end;

% imx lesen und MapMask besetzen
if length(ImxFileName) >0
    MapMask = ReadIMX(ImxFileName,ImxDirectory);
	% keys ueberpruefen
% The mask is read in the order stored in the IMX file.
else
   MapMask=1;   %  no Insel, no masking
end;  
 

