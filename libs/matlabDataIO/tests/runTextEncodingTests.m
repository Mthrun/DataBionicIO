function runTextEncodingTests(Directory)
% INPUT
% Directory  Optional fixture directory; the default uses the packaged fixtures.
% OUTPUT
% Assertions for the common MATLAB encoding and field-replacement interface.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 1
    Directory = fullfile(fileparts(mfilename('fullpath')), 'encoding', 'fixtures');
    if ~isfolder(Directory)
        Directory = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..', 'tests', 'encoding', 'fixtures');
    end
end
Work = tempname;
mkdir(Work);
Cleanup = onCleanup(@() rmdir(Work, 's')); %#ok<NASGU>
copyfile(fullfile(Directory, '*'), Work);
Directory = Work;
Readers = {@DataBionicIO.ReadLRN, @DataBionicIO.ReadCLS, ...
    @DataBionicIO.ReadNAMES, @DataBionicIO.ReadDates};
Extensions = {'lrn', 'cls', 'names', 'dts'};
Encodings = {'utf-8-sig', 'utf-16', 'utf-32', 'utf-16-be', 'utf-32-be', 'cp1252', 'latin1'};
for F = 1:numel(Readers)
    for E = 1:numel(Encodings)
        Options = {};
        if strcmp(Encodings{E}, 'cp1252'), Options = {'Encoding', 'Windows-1252'}; end
        if strcmp(Encodings{E}, 'latin1'), Options = {'Encoding', 'ISO-8859-1'}; end
        lastwarn('');
        Key = Readers{F}([Encodings{E}, '.', Extensions{F}], Directory, false, Options{:});
        assert(isequal(Key(:), 17));
        Message = lastwarn;
        if E == 1, assert(isempty(Message));
        else, assert(contains(Message, 'Converted input from')); end
    end
end
Names = {sprintf('Sample\tA'); sprintf('A\r\nB'); ['N', char(0), 'Z']; ' café '; 'é'};
Texts = repmat({sprintf('X\nY')}, numel(Names), 1);
Saved = Texts;
for Replacement = {'_', '[sep]'}
    lastwarn('');
    DataBionicIO.WriteNAMES('matlab.names', Names, (1:numel(Names))', Texts, ...
        {'Names', 'Description'}, Directory, '', true, false, 'TextReplacement', Replacement{1});
    assert(strcmp(lastwarn, ['Replaced 9 forbidden text characters in 8 fields with "', Replacement{1}, '".']));
    [~, Result] = DataBionicIO.ReadNAMES('matlab.names', Directory, false);
    Expected = Names;
    for C = [9, 10, 13, 0]
        Expected = cellfun(@(S) strrep(S, char(C), Replacement{1}), Expected, 'UniformOutput', false);
    end
    assert(isequal(Result(:), Expected(:)) && isequal(Texts, Saved));
end
disp('MATLAB encoding and replacement checks passed.');
end
