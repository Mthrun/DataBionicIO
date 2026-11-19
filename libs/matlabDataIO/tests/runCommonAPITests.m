function runCommonAPITests
% Run common API positional calls and Chicago DTS round trips.
% INPUT
% A selected modern DataBionicIO package with its MEX module.
% OUTPUT
% Assertion failures or successful completion; temporary files are removed.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Directory = tempname; mkdir(Directory);
Cleanup = onCleanup(@() rmdir(Directory, 's')); %#ok<NASGU>
Key = [11;22];
DataBionicIO.WriteLRN('matrix', [7 1.5;8 2.5], {'Unused','Value'}, Key, [0 1], Directory, 'LRN', [], [], false, false, false);
[K,D,H,T,C] = DataBionicIO.ReadLRN('matrix', Directory, false);
assert(isequal(K,Key) && isequal(D,[7 1.5;8 2.5]) && isequal(T(:)',[9 0 1]));
assert(isequal(H(:),{'Unused';'Value'}) && strcmp(C,'LRN'));
DataBionicIO.WriteCLS('classes', [2;3], Directory, Key, 'CLS', [], false, false);
[K,Cls,Unique,Comments] = DataBionicIO.ReadCLS('classes', Directory, false);
assert(isequal(K,Key) && isequal(Cls,[2;3]) && isequal(Unique,[2;3]) && strcmp(Comments,'CLS'));
DataBionicIO.WriteNAMES('names', {'A';'B'}, Key, {'x';'y'}, {'Group'}, Directory, 'NAMES', false, false);
[K,Names,Texts,Header,Comments] = DataBionicIO.ReadNAMES('names', Directory, false);
assert(isequal(K,Key) && isequal(Names,{'A';'B'}) && isequal(Texts,{'x';'y'}));
assert(isequal(Header,{'Group'}) && strcmp(Comments,'NAMES'));
Time = datetime({'2026-01-15 18:00:00';'2026-07-15 17:00:00';'2026-11-01 06:30:00';'2026-11-01 07:30:00'}, ...
    'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
TSdata = table(Time, (1:4)', 'VariableNames', {'Time','Value'});
DataBionicIO.WriteDates('times', TSdata, (1:4)', Directory, 'DTS', 'America/Chicago', 2, false, false);
[K,Times,Data,Header,Comments,Timezone,DST] = DataBionicIO.ReadDates('times',Directory,false);
assert(isequal(K,(1:4)') && isequal(Data,(1:4)') && strcmp(Comments,'DTS'));
assert(strcmp(Timezone,'America/Chicago') && isequal(DST,{'CST';'CDT';'CDT';'CST'}));
assert(isequal(Times,{'2026-01-15 12:00:00';'2026-07-15 12:00:00';'2026-11-01 01:30:00';'2026-11-01 01:30:00'}));
assert(isequal(Header,{'Value'}));
% Text plus DST must keep both occurrences of the repeated local time.
TSdata = table(Times, Data, DST, 'VariableNames', {'Time','Value','DST'});
DataBionicIO.WriteDates('copy',TSdata,(1:4)',Directory,[],Timezone,2,false,false);
[~,Again,~,~,~,ZoneAgain,DSTAgain] = DataBionicIO.ReadDates('copy',Directory,false);
assert(isequal(Again,Times) && strcmp(ZoneAgain,Timezone) && isequal(DSTAgain,DST));
DataBionicIO.WriteNAMES('empty', {'A';'B'}, Key, [], [], Directory, [], false, false);
[~,~,Texts,Header,Comments] = DataBionicIO.ReadNAMES('empty',Directory,false);
assert(isequal(size(Texts),[2 0]) && isempty(Header) && isempty(Comments));
DataBionicIO.WriteDates('only-time', Time(1), 1, Directory, [], [], [], false, false);
[~,~,Data,Header,Comments] = DataBionicIO.ReadDates('only-time',Directory,false);
assert(isequal(size(Data),[1 0]) && isempty(Header) && isempty(Comments));
fprintf('Common MATLAB API and Chicago DST passed.\n');
end
