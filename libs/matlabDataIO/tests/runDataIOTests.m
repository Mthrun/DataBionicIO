function ReportDirectory = runDataIOTests(Mode, ReportDirectory)
% runDataIOTests Run DataBionicIO package checks in MATLAB.
% ReportDirectory = runDataIOTests('modern') or runDataIOTests('legacy').
% An optional second argument sets a new report folder.
% Run modern tests on R2022a or later after buildDataIO or a CMake build.
% The files and test log remain in a new temporary folder. No user file is used.
% INPUT
% Mode  Optional modern or legacy interface selection.
% ReportDirectory  Optional new report folder; the default uses tempname.
%

% OUTPUT
% ReportDirectory contains the test log and generated test files.
% The function raises an error if a test group fails.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Root = fileparts(fileparts(mfilename('fullpath')));
OriginalPath = path;
RestorePath = onCleanup(@() path(OriginalPath)); %#ok<NASGU>
OriginalFolder = pwd;
RestoreFolder = onCleanup(@() cd(OriginalFolder)); %#ok<NASGU>
if nargin < 2, ReportDirectory = tempname; end
if ~ischar(ReportDirectory) || size(ReportDirectory,1) ~= 1 || isempty(ReportDirectory)
    error('DataIO:Tests','The report path must be a nonempty character row.');
end
if exist(ReportDirectory,'file') || exist(ReportDirectory,'dir')
    error('DataIO:Tests','The report path already exists: %s',ReportDirectory);
end
[Created, Message] = mkdir(ReportDirectory);
if ~Created, error('DataIO:Tests','Cannot create report folder: %s',Message); end
diary(fullfile(ReportDirectory,'results.txt'));
StopDiary = onCleanup(@() diary('off')); %#ok<NASGU>
addpath(Root);
if nargin < 1, Mode = setupDataIO(); else, setupDataIO(Mode); end
if strcmp(Mode, 'modern'), runCommonAPITests; runTextEncodingTests; end
fprintf('DataBionicIO MATLAB tests\nMATLAB: %s\nPlatform: %s\nMode: %s\nFolder: %s\n', ...
    version, computer, Mode, ReportDirectory);
if strcmp(Mode,'modern')
    Compiler = mex.getCompilerConfigurations('C++','Selected');
    if ~isempty(Compiler), fprintf('Compiler: %s %s\n',Compiler.Name,Compiler.Version); end
end
Samples = fullfile(Root,'tests','samples');
Tests = {@() legacySamples(Samples), @() nativeFormats(ReportDirectory), @() pathSelection(Root,Mode)};
Labels = {'old file samples','native BM and UMX','path selection'};
if strcmp(Mode,'modern')
    Tests = [Tests, {@() roundTrips(ReportDirectory), @() numbersAndKeys(ReportDirectory), ...
        @() damagedRows(ReportDirectory), @() dateTimes(ReportDirectory), @() sameKeys(), @() switches(Root)}];
    Labels = [Labels, {'current format round trips','precision and keys','short and long rows','UTC dates','key comparison','mode switch'}];
else
    Tests{end+1} = @() legacyGuards(ReportDirectory);
    Labels{end+1} = 'read-only guards';
end
Failed = 0;
for I=1:numel(Tests)
    try
        Tests{I}(); fprintf('PASS: %s\n',Labels{I});
    catch Problem
        Failed = Failed+1;
        fprintf('FAIL: %s\n%s\n',Labels{I},getReport(Problem,'extended','hyperlinks','off'));
    end
end
fprintf('%d of %d groups passed.\nReport: %s\n',numel(Tests)-Failed,numel(Tests),ReportDirectory);
if Failed, error('DataIO:Tests','%d test groups failed. Read results.txt.',Failed); end
end

function legacySamples(Samples)
% Check fixed legacy LRN, CLS, and NAMES samples.
%
% INPUT
% Samples  Package test-sample directory.
%
% OUTPUT
% No return value. Failed checks raise an error.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Folder = fullfile(Samples,'legacy','test');
[A,K,H] = ReadLRN('hexa',Folder);
assert(size(A,1)==60 && numel(K)==60 && size(H,1)==size(A,2));
[NK,Names,Rest] = ReadNAMES('hexa',Folder);
% The sample files contain the same keys in different row orders.
assert(isequal(sort(K),sort(NK)));
NameRow = find(NK == 1);
assert(strcmp(strtrim(Names(NameRow,:)),'AT') && strcmp(Rest{NameRow},'Alltel'));
[CK,C,~,~,Colors] = ReadCLS('hexa',Folder);
assert(isequal(sort(K),sort(CK)) && numel(C)==60 && isempty(Colors));
[~,ClassRows] = ismember(K,CK);
assert(isequal(A(:,end),C(ClassRows)));
ReadLRN('old',Folder);
ReadLRN('nan',Folder);
ReadLRN('save',Folder);
ReadCLS('save',Folder);
ReadLRN('TXTfile',fullfile(Samples,'legacy','ZZTestDataIO'));
ReadNAMES('save',Folder);
end

function nativeFormats(Folder)
% Check native BM and UMX file round trips.
%
% INPUT
% Folder  Test output directory.
%
% OUTPUT
% No return value. Failed checks raise an error.
% File tests create their fixtures in the supplied test directory.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Before = pwd;
A = [1 1 2; 2 2 3; 3 2 1];
WriteBM('native',A,Folder);
assert(isequal(ReadBM('native',Folder),A));
U = [1 2 3;4 5 6];
WriteUMX('native',U,Folder);
assert(isequal(ReadUMX('native',Folder),U));
assert(strcmp(pwd,Before));
end

function pathSelection(Root,Mode)
% Check that MATLAB selects functions from the requested package folders.
%
% INPUT
% Root  MATLAB package root.
% Mode  Expected modern or legacy interface.
%
% OUTPUT
% No return value. Failed checks raise an error.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

for Name = {'ReadLRN','WriteLRN','ReadNAMES','WriteCLS','ReadDates'}
    assert(strcmpi(which(Name{1}),fullfile(Root,Mode,[Name{1} '.m'])));
end
assert(strcmpi(which('ReadBM'),fullfile(Root,'native','ReadBM.m')));
end

function roundTrips(Folder)
% Check current-format LRN, CLS, and NAMES round trips.
%
% INPUT
% Folder  Test output directory.
%
% OUTPUT
% No return value. Failed checks raise an error.
% File tests create their fixtures in the supplied test directory.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Key = [-2^53;2^31;2^53];
A = [1 2 NaN;4.25 -5 6;7 8 9];
WriteLRN('roundtrip',A,{'A','B','C'},Key,[],Folder,'user comment',false,[],struct('SignificantDigits',15));
[B,K,H,Types,Comment] = ReadLRN('roundtrip',Folder);
assert(isequaln(A,B) && isequal(Key,K) && isequal(Types,[1 1 1]));
assert(isequal(cellstr(H),{'A';'B';'C'}) && strcmp(Comment,'user comment'));
assert(~isempty(strfind(fileread(fullfile(Folder,'roundtrip.lrn')),'version="2.0"')));
C = [1;NaN;3];
WriteCLS('roundtrip',C,Key,Folder,'classes');
[K,D,Comment,~,Colors] = ReadCLS('roundtrip',Folder);
assert(isequal(Key,K) && isequaln(C,D) && strcmp(Comment,'classes') && isempty(Colors));
[~,D] = ReadCLS('roundtrip',Folder,-99); assert(D(2)==-99);
Names = {'1.0.4';'';char([77 252 110 99 104 101 110])};
Rest = {'left','end';'','';'right','last'};
lastwarn('');
WriteNAMES('roundtrip',Names,Key,Rest,Folder,{'Version Currency','Second','Third'},'names');
[~,WarningID] = lastwarn; assert(strcmp(WarningID,'DataIO:FileWarning'));
[K,N,R,Comment,H,T] = ReadNAMES('roundtrip',Folder);
assert(isequal(Key,K) && strcmp(strtrim(N(1,:)),'1.0.4') && strcmp(strtrim(N(2,:)),'NA'));
assert(strcmp(strtrim(N(3,:)),Names{3}) && strcmp(T{2,2},'NA'));
assert(strcmp(strtrim(H(2,:)),'VersionCurrency') && strcmp(Comment,'names'));
WriteNAMES('joined',cellstr(N),K,R,Folder,H,Comment);
[~,~,~,~,~,T2] = ReadNAMES('joined',Folder); assert(isequal(T,T2));
% A reader must leave the folder unchanged.
Before = dir(Folder); ReadLRN('roundtrip',Folder); ReadNAMES('roundtrip',Folder);
After = dir(Folder); assert(isequal({Before.name},{After.name}) && isequal([Before.bytes],[After.bytes]));
end

function numbersAndKeys(Folder)
% Check numeric precision and the supported key range.
%
% INPUT
% Folder  Test output directory.
%
% OUTPUT
% No return value. Failed checks raise an error.
% File tests create their fixtures in the supplied test directory.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Exact = [0.1; 1+eps(1); -1.2345678901234567; 1e-100; 1e100];
Keys = (1:numel(Exact))';
WriteLRN('default6',Exact,{'A'},Keys,[],Folder);
WriteLRN('default7',Exact,{'A'},Keys,[],Folder,'precision test');
WriteLRN('default10',Exact,{'A'},Keys,[],Folder,[],[],[],[]);
for Name = {'default6','default7','default10'}
    assert(isequal(ReadLRN(Name{1},Folder),Exact));
end
WriteLRN('old_digits',1.23456,{'A'},1,[],Folder,1,false);
assert(isequal(ReadLRN('old_digits',Folder),1.2));
WriteLRN('precedence',1.23456,{'A'},1,[],Folder,[],false,0,struct('SignificantDigits',4,'DecimalDigits',0));
assert(isequal(ReadLRN('precedence',Folder),1.235));
WriteLRN('precedence',1.23456,{'A'},1,[],Folder,[],false,0,struct('DecimalDigits',2));
assert(isequal(ReadLRN('precedence',Folder),1.23));
for Scientific = [false true]
    WriteLRN('digits',[1;1.23456],{'A'},[1;2],[],Folder,[],Scientific,[],struct('SignificantDigits',4));
    assert(isequal(ReadLRN('digits',Folder),[1;1.235]));
    Text = fileread(fullfile(Folder,'digits.lrn'));
    assert(isempty(strfind(Text,'1.000')));
    if Scientific, assert(~isempty(strfind(Text,'e+00'))); end
end
WriteLRN('decimal',[1.6;12.4],{'A'},[1;2],[],Folder,[],false,[],struct('DecimalDigits',0));
assert(isequal(ReadLRN('decimal',Folder),[2;12]));
WriteLRN('protected',[1;2],{'A'},[1;2],[],Folder);
File = fullfile(Folder,'protected.lrn'); Before = fileread(File);
BadKeys = {[1;1], [1;1.5], [1;Inf], [1;NaN], [1;2^53+2], ...
    [uint64(1);bitshift(uint64(1),53)+uint64(1)], [int64(1);-bitshift(int64(1),53)-int64(1)]};
for I=1:numel(BadKeys)
    expectError(@() WriteLRN('protected',[1;2],{'A'},BadKeys{I},[],Folder),'DataIO:Core');
    assert(strcmp(Before,fileread(File)));
end
expectError(@() WriteLRN('protected',[1;2],{'A'},[1;2],[],Folder,[],[],[],struct('Overwrite',false)),'DataIO:Core');
lastwarn(''); WriteLRN('generated',[1;2],{'A'},[],[],Folder);
[~,ID] = lastwarn; assert(strcmp(ID,'DataIO:MissingKey'));
[~,K] = ReadLRN('generated',Folder); assert(isequal(K,[1;2]));
end

function damagedRows(Folder)
% Check recovery from short, long, and invalid data rows.
%
% INPUT
% Folder  Test output directory.
%
% OUTPUT
% No return value. Failed checks raise an error.
% File tests create their fixtures in the supplied test directory.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

File = fullfile(Folder,'short.lrn');
writeText(File,sprintf('#<?lrn version="2.0"?>\n%% 3\n%% 3\n%% 9\t1\t1\n%% Key\tA\tB\n1\t12oops\t3,4oops\n2\t7\n3\t8\t9\textra\n'));
lastwarn(''); [A,K] = ReadLRN(File);
assert(isequaln(A,[12 3;7 NaN;8 9]) && isequal(K,[1;2;3]));
[~,ID] = lastwarn; assert(strcmp(ID,'DataIO:FileWarning'));
File = fullfile(Folder,'short.names');
writeText(File,sprintf('#<?names version="2.0"?>\n%% 3\n%% 3\n%% Key\tNames\tExtra\n1\t\t\n2\tName\n3\tLast\tValue\tignored\n\n'));
[K,N,~,~,~,T] = ReadNAMES(File);
assert(numel(K)==3 && strcmp(strtrim(N(1,:)),'NA') && isequal(size(T),[3 1]) && strcmp(T{2},'NA'));
% Explicit 2.0 must not enter the old file parser.
writeText(fullfile(Folder,'wrong.names'),sprintf('#<?names version="2.0"?>\n%% 1\n1\tAlice\n'));
expectError(@() ReadNAMES('wrong',Folder),'DataIO:Core');
end

function dateTimes(Folder)
% Check DATES round trips and time metadata.
%
% INPUT
% Folder  Test output directory.
%
% OUTPUT
% No return value. Failed checks raise an error.
% File tests create their fixtures in the supplied test directory.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Time = {'2024-01-02 03:04:05.123';'NA';'2024-10-27 01:30:00.000'};
A = [1 2;NaN 4;5 6]; Key = [1;2;3];
WriteDates('times',Time,A,{'A','B'},Key,Folder,'dates');
[T,B,K,H,C,Zone] = ReadDates('times',Folder);
assert(isequal(T,Time) && isequaln(A,B) && isequal(K,Key));
assert(isequal(cellstr(H),{'A';'B'}) && strcmp(C,'dates') && strcmp(Zone,'UTC'));
WriteDates('onlytime',{'2024-01-01'},[],[],1,Folder);
[~,B] = ReadDates('onlytime',Folder); assert(isequal(size(B),[1 0]));
T = datetime(2024,10,27,[0;1],30,0,'TimeZone','UTC');
T.TimeZone = 'Europe/Berlin';
WriteDates('dst',T,zeros(2,0),[],[1;2],Folder,[],struct('Format',2));
Text = ReadDates('dst',Folder);
assert(isequal(Text,{'2024-10-27 00:30:00';'2024-10-27 01:30:00'}));
end

function switches(Root)
% Check changes between legacy and modern MATLAB interfaces.
%
% INPUT
% Root  MATLAB package root.
%
% OUTPUT
% No return value. Failed checks raise an error.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

setupDataIO('legacy'); pathSelection(Root,'legacy');
expectError(@() WriteLRN('unused',1),'DataIO:LegacyReadOnly');
setupDataIO('modern'); pathSelection(Root,'modern');
end

function legacyGuards(Folder)
% Check read-only guards and rejection of current-format files.
%
% INPUT
% Folder  Test output directory.
%
% OUTPUT
% No return value. Failed checks raise an error.
% File tests create their fixtures in the supplied test directory.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

expectError(@() WriteLRN('unused',1),'DataIO:LegacyReadOnly');
expectError(@() WriteNAMES('unused','x'),'DataIO:LegacyReadOnly');
expectError(@() WriteCLS('unused',1),'DataIO:LegacyReadOnly');
expectError(@() ReadDates('unused'),'DataIO:LegacyReadOnly');
File = fullfile(Folder,'current.lrn');
writeText(File,sprintf('#<?lrn version="2.0"?>\n%% 1\n%% 2\n%% 9\t1\n%% Key\tA\n1\t2\n'));
expectError(@() ReadLRN(File),'DataIO:Legacy');
end

function expectError(Call,Identifier)
% Check a callback for an expected error identifier.
%
% INPUT
% Call  Zero-argument function handle.
% Identifier  Expected MATLAB error identifier.
%
% OUTPUT
% No return value. Fails an assertion if the callback does not raise the expected error.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Failed = false;
try, Call(); catch Problem, Failed = strcmp(Problem.identifier,Identifier); end
assert(Failed,['Expected error: ' Identifier]);
end

function writeText(File,Text)
% Write a test fixture.
%
% INPUT
% File  Output file path.
% Text  Character data to write.
%
% OUTPUT
% No return value. Creates or replaces File and closes it after writing.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Fid = fopen(File,'wt'); assert(Fid>=0);
CloseFile = onCleanup(@() fclose(Fid)); %#ok<NASGU>
fprintf(Fid,'%s',Text);
end


function sameKeys()
% INPUT
% Fixed numeric sequences, including row and column orientations.
% OUTPUT
% No return value. Failed checks raise an error; no files are written.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Cases = {
    [], [], true;
    [], 1, false;
    [1 2 3], [1;2;3], true;
    [1 2 3], [1 3 2], false;
    [1 2], [1 2 3], false;
    [1 1], [1 1], true;
    [1.5 -0], [1.5 0], true;
    1, 1+eps(1), false;
    [-2^53 2^53], int64([-2^53 2^53]), true;
    [1 NaN], [1 NaN], false;
    [Inf -Inf], [Inf -Inf], true;
    [true false], [1 0], true;
    '1', 1, false;
    [1 2;3 4], [1 2;3 4], false;
    int64(2^53)+int64(1), 2^53, false;
    intmax('int64'), intmax('int64'), false;
    intmax('uint64'), intmax('uint64'), false
};
for I = 1:size(Cases,1)
    assert(isequal(TheSameKey(Cases{I,1},Cases{I,2}),Cases{I,3}));
end
Key = [3 1 2]; Before = Key;
assert(TheSameKey(Key,Key) && isequal(Key,Before));
end
