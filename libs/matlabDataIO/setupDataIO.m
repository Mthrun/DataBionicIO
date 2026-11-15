function Mode = setupDataIO(Mode)
% setupDataIO Select one public implementation for this MATLAB session.
% setupDataIO uses C++ on R2022a or later. Older releases use legacy readers.
% setupDataIO('legacy') selects only the old LRN, CLS, and NAMES readers.
% Extra native formats remain available in either mode. No path is saved.
% Run this function from the package root. Do not use addpath(genpath(...)).
% INPUT
% Mode  Optional character row: modern or legacy. The default depends on the MATLAB release.
%

% OUTPUT
% Mode is the selected modern or legacy interface.
% The MATLAB path includes the selected interface and native format functions.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Root = fileparts(mfilename('fullpath'));
if nargin < 1
    if verLessThan('matlab', '9.12'), Mode = 'legacy'; else, Mode = 'modern'; end
end
if ~ischar(Mode) || ~any(strcmp(Mode, {'modern','legacy'}))
    error('DataIO:Setup', 'Mode must be modern or legacy.');
end
if isempty(strfind(computer('arch'), '64'))
    error('DataIO:Setup', 'DataIO requires 64-bit MATLAB.');
end
if strcmp(Mode, 'modern')
    if verLessThan('matlab', '9.12'), error('DataIO:Setup', 'The C++ package requires R2022a or later.'); end
    if exist(fullfile(Root, 'bin', ['dataio_mex.' mexext]), 'file') ~= 3
        error('DataIO:Setup', 'No MEX file for this platform. Run buildDataIO or obtain a tested binary package.');
    end
end
OldPath = path;
% Remove this package's previous selection. Leave unrelated dbt folders intact.
Folders = {'modern','legacy','native','bin'};
for I = 1:numel(Folders)
    Folder = fullfile(Root, Folders{I});
    if any(strcmp(regexp(path, pathsep, 'split'), Folder)), rmpath(Folder); end
end
addpath(fullfile(Root, 'native'), '-begin');
addpath(fullfile(Root, Mode), '-begin');
if strcmp(Mode, 'modern'), addpath(fullfile(Root, 'bin'), '-begin'); end
Names = {'ReadLRN','WriteLRN','ReadCLS','WriteCLS','ReadNAMES','WriteNAMES','ReadDates','WriteDates'};
try
    for I = 1:numel(Names)
        Expected = fullfile(Root, Mode, [Names{I} '.m']);
        if ~strcmpi(which(Names{I}), Expected)
            error('DataIO:PathConflict', '%s is hidden by another file. Leave that current folder or remove its DataIO path first.', Names{I});
        end
    end
    if strcmp(Mode, 'modern')
        % Loading the gateway now catches a wrong architecture or missing runtime.
        [Info, ~, Failure] = dataio_mex('version', struct());
        if ~isempty(Failure) || ~isfield(Info,'API') || Info.API ~= 1
            error('DataIO:Setup', 'Unexpected DataIO gateway. Check the MATLAB path.');
        end
    end
catch Problem
    path(OldPath);
    rethrow(Problem);
end
fprintf('DataIO: %s mode selected.\n', Mode);
end

