function runMatlabCI
% runMatlabCI Build DataBionicIO and run MATLAB package and exchange tests.
% Logs and test files are in build/ci/matlab below the source root.
% INPUT
% None. The source location and GitHub environment variables supply the context.
% DATAIO_INTEROP_DIR selects an existing R/Python exchange-file directory.
%

% OUTPUT
% Build logs, environment information, test reports, and stage status files.
% The function raises an error if the MEX build or any selected test fails.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Project = fileparts(fileparts(fileparts(mfilename('fullpath'))));
Reports = fullfile(Project,'build','ci','matlab');
if exist(Reports,'dir')
    error('DataIO:CI','The report folder already exists: %s',Reports);
end
[Created, Message] = mkdir(Reports);
if ~Created, error('DataIO:CI','Cannot create report folder: %s',Message); end

OriginalFolder = pwd;
OriginalPath = path;
RestoreFolder = onCleanup(@() cd(OriginalFolder)); %#ok<NASGU>
RestorePath = onCleanup(@() path(OriginalPath)); %#ok<NASGU>
Summary = fopen(fullfile(Reports,'summary.tsv'),'wt');
if Summary < 0, error('DataIO:CI','Cannot open summary.tsv.'); end
CloseSummary = onCleanup(@() fclose(Summary)); %#ok<NASGU>
fprintf(Summary,'stage\tresult\n');

diary(fullfile(Reports,'build.txt'));
StopDiary = onCleanup(@() diary('off')); %#ok<NASGU>
try
    restoredefaultpath;
    addpath(fullfile(Project,'libs','matlabDataIO'));
    cd(Project);
    mex('-setup','C++');
    Compiler = mex.getCompilerConfigurations('C++','Selected');
    if isempty(Compiler), error('DataIO:CI','No C++ compiler is selected.'); end
    Environment = sprintf(['MATLAB: %s\nPlatform: %s\nMEX extension: %s\n' ...
        'Compiler: %s\nCompiler version: %s\nCommit: %s\nRun: %s\nAttempt: %s\n'], ...
        version, computer, mexext, Compiler.Name, Compiler.Version, ...
        getenv('GITHUB_SHA'), getenv('GITHUB_RUN_ID'), getenv('GITHUB_RUN_ATTEMPT'));
    writeReport(fullfile(Reports,'environment.txt'),Environment);
    BuildInfo = struct('release',['R' version('-release')], ...
        'version',version,'architecture',computer('arch'),'mex_extension',mexext, ...
        'compiler',Compiler.Name,'compiler_version',Compiler.Version, ...
        'commit',getenv('GITHUB_SHA'),'run',getenv('GITHUB_RUN_ID'), ...
        'attempt',getenv('GITHUB_RUN_ATTEMPT'));
    BuildInfo.source_url = [getenv('GITHUB_SERVER_URL') '/' getenv('GITHUB_REPOSITORY') ...
        '/tree/' BuildInfo.commit];
    writeReport(fullfile(Reports,'build.json'),jsonencode(BuildInfo));
    fprintf('%s',Environment);
    Package = buildDataIO(fullfile(Project,'build','ci','package'));
    fprintf(Summary,'build\tPASS\n');
catch Problem
    fprintf(Summary,'build\tFAIL\n');
    writeReport(fullfile(Reports,'build-error.txt'),getReport(Problem,'extended','hyperlinks','off'));
    rethrow(Problem);
end
diary('off');

cd(Package);
addpath(Package);
addpath(fullfile(Package,'tests'));
Failed = 0;
for Modes = {'modern','legacy'}
    Mode = Modes{1};
    try
        runDataIOTests(Mode,fullfile(Reports,Mode));
        fprintf(Summary,'%s\tPASS\n',Mode);
    catch Problem
        Failed = Failed+1;
        fprintf(Summary,'%s\tFAIL\n',Mode);
        writeReport(fullfile(Reports,[Mode '-error.txt']),getReport(Problem,'extended','hyperlinks','off'));
        fprintf('%s\n',getReport(Problem,'extended','hyperlinks','off'));
    end
end
if Failed
    error('DataIO:CI','%d MATLAB test modes failed. See the workflow reports.',Failed);
end
Exchange = getenv('DATAIO_INTEROP_DIR');
if ~isempty(Exchange)
    diary(fullfile(Reports,'interop.txt'));
    try
        addpath(fullfile(Project,'tests','interop'));
        runDataIOInterop(Exchange);
        fprintf(Summary,'interop\tPASS\n');
    catch Problem
        fprintf(Summary,'interop\tFAIL\n');
        writeReport(fullfile(Reports,'interop-error.txt'),getReport(Problem,'extended','hyperlinks','off'));
        rethrow(Problem);
    end
    diary('off');
end
fprintf('DataBionicIO MATLAB build and both test modes passed.\n');
end

function writeReport(File,Text)
% Write a CI report file.
%
% INPUT
% File  Output report path.
% Text  Report text.
%
% OUTPUT
% No return value. Creates or replaces File and adds a final newline.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Fid = fopen(File,'wt');
if Fid < 0, error('DataIO:CI','Cannot open report: %s',File); end
CloseFile = onCleanup(@() fclose(Fid)); %#ok<NASGU>
fprintf(Fid,'%s\n',Text);
end

