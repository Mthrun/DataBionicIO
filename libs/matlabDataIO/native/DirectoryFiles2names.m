function FileNames1 = DirectoryFiles2names(Directory,FilePattern,NamesFileName,Columns,AddPrefix,NamesDir,AddNrOfFiles,Write2File);
% DirectoryFiles2names(Directory,FilePattern,NamesFileName,Columns,AddPrefix,NamesDir,AddNrOfFiles);
% FileNames1 = DirectoryFiles2names(Directory,FilePattern,NamesFileName,Columns,AddPrefix,NamesDir,AddNrOfFiles);
% list the files in a Directory into a *.names file
%
% INPUT
% Directory     pfad des verzeichnisses
% 
% OPTIONAL
% NamesFileName ausgabedatei namen      default: NamesFileName = '01Files.names';
% FilePattern   fuer dir(FilePattern);  default: FilePattern   = '*.lrn'; 
% Columns       ein oder zweispaltig, bei letzerem wird jede 2.Datei in eine 2. Spalte eingetragen
%               default  Columns ==1
% AddPrefix     a Filename prefix is added as the last column
%               == 2 erste 2 buchstaben des Filenamens
% NamesDir      dahin wird die *.names geschriben; default: 
% AddNrOfFiles  ==1: the number of files is added to the NamesFileName, ; default AddNrOfFiles = 0;
% 
% OUTPUT 
% FileNames1   the names in the first column

% (Directory,FilePattern,NamesFileName,Columns,AddPrefix,NamesDir,AddNrOfFiles,Write2File);
%    1           2           3             4       5         6          7
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2 ; FilePattern   = '*.lrn';         end;
if nargin < 3 ; NamesFileName = '01Files.names'; end;
if nargin < 4 ; Columns       = 1;               end;
if nargin < 5 ; AddPrefix     = 1;               end;
if nargin < 6 ; NamesDir      = Directory;       end;
if nargin < 7 ; AddNrOfFiles  = 0;               end;
if nargin < 8 ; Write2File    = 0;               end;

CurrentDirectory = pwd;                      % Save current Directory

cd(Directory);                                 % ins Directory wechseln
files = dir(FilePattern);                      % nur diese Dateien
FileNames= char(files(:).name);                % array der Dateinamen
[AnzFiles dummy] = size(FileNames);            % sowiele Dateien gibts
FileNames1 = deblank(FileNames);               % 1. Spalte Dateinamen

if AddPrefix==1
   [AnzFiles dummy] = size(FileNames1); 
   FNprefix = ' ';
   for i=1:AnzFiles
    FN = deblank(FileNames1(i,:));
    Ind = strfind(FN,'_');
    if isempty(Ind); Ind =[5,7] ; end; % falls die namenskonvention nicht eingeh. wird
	i1 = Ind(1)+1; i2 = Ind(2)+1;
	Pref = [FN(5:6),FN(i1:i1+1),FN(i2:i2+2)];
    FNprefix = char(FNprefix,Pref);
   end;% for i=1:AnzFiles
   FNprefix =deblank(FNprefix(2:end,:));
end; % if AddPrefix==1

if AddPrefix==2
   [AnzFiles dummy] = size(FileNames1); 
   FNprefix = ' ';
   for i=1:AnzFiles
    FN = deblank(FileNames1(i,:));
    Ind = strfind(FN,' ');
	i1 = 1; i2 = Ind(1)+1;
	Pref = [FN(1:2),FN(i2:i2+2)];
    FNprefix = char(FNprefix,Pref);
  end;
   FNprefix =deblank(FNprefix(2:end,:));
end; % if AddPrefix==1


if Columns ==1
	FileNames1 = deblank(FileNames);           % 1. Spalte Dateinamen
	FileNames2 = deblank(FNprefix);            % 2. SpalteFNprefix
	
	else % aufteilen in 2 Spalten  
	FileInd1 = 1:2:AnzFiles;                       % index der 1. Spalte
	FileInd2 = 2:2:AnzFiles;                       % index der 2. Spalte
	FileNames1 = deblank(FileNames(FileInd1,:));   % 1. Spalte Dateinamen
	FileNames2 = deblank(FileNames(FileInd2,:));   % 2. Spalte Dateinamen
end; % if Columns ==1


FileKey = str2num(FileNames1(:,1:4));          % Key aus File1
% ausschreiben
% extenstion in den header
[pathstr,name,ext,versn] = fileparts(FilePattern);
ext = ext(2:end); % ohne '.'

if AddNrOfFiles ==1
	[dummy,FN] = fileparts(NamesFileName);
	[AnzFiles,dummy] = size(FileNames1);
	NamesFileName = [FN,'n',num2str(AnzFiles),'.names'];
end; % if AddNrOfFiles ==1;

if Write2File >0 
    if AddPrefix>0
        if Columns ==1
            DescriptionHeader = ['Key	',ext,'FileName1	',ext,'FileNamePrefix'];
            WriteNAMES(NamesFileName,FileNames1,FileKey,[ Tabs(AnzFiles),FNprefix], NamesDir,DescriptionHeader);
        else
            DescriptionHeader = ['Key	',ext,'FileName1	',ext,'FileName2',ext,'FileNamePrefix'];
            WriteNAMES(NamesFileName,FileNames1,FileKey,[FileNames2, Tabs(AnzFiles),FNprefix], NamesDir,DescriptionHeader);
        end;
     else
       DescriptionHeader = ['Key	',ext,'FileName1	',ext,'FileName2'];
       WriteNAMES(NamesFileName,FileNames1,FileKey,FileNames2, NamesDir,DescriptionHeader);
    end; % if AddPrefix==1
end; %if Write2File >0

cd(CurrentDirectory);                        % Restore current Directory

