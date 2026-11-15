function Package = buildDataIO(OutputDirectory)
% buildDataIO Build a DataBionicIO MATLAB package from this source checkout.
% Package = buildDataIO(OutputDirectory)
% Requires 64-bit MATLAB R2022a or later and a supported C++20 compiler.
% Run mex -setup C++ first. Only the builder needs a compiler.
% The default output is build/matlab/<platform>/DataBionicIO in the source checkout.
% The source files and the current MATLAB path are not changed.
% INPUT
% OutputDirectory  Optional parent directory for a new DataBionicIO folder.
%

% OUTPUT
% Package is the path to the built MATLAB package, including its MEX file.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

Source = fileparts(mfilename('fullpath'));
Project = fileparts(fileparts(Source));
Core = fullfile(Project, 'libs', 'cDataIO');
if verLessThan('matlab','9.12') || isempty(strfind(computer('arch'),'64'))
    error('DataIO:Build', 'Build with 64-bit MATLAB R2022a or later.');
end
if ~exist(fullfile(Core,'src','read_lrn.cpp'),'file')
    error('DataIO:Build', 'Build from the full source checkout, not from a binary package.');
end
if nargin < 1, OutputDirectory = fullfile(Project,'build','matlab',computer('arch')); end
Package = fullfile(OutputDirectory, 'DataBionicIO');
if exist(Package,'dir'), error('DataIO:Build', 'Output exists. Select a new output folder: %s', Package); end
mkdir(Package);
mkdir(fullfile(Package,'bin'));
SourceFiles = dir(fullfile(Core,'src','*.cpp'));
Args = {'-R2017b','-largeArrayDims','-DDATAIO_STATIC', ['-I' fullfile(Core,'include')], ...
    '-outdir', fullfile(Package,'bin'), '-output', 'dataio_mex', fullfile(Source,'src','dataio_mex.cpp')};
for I = 1:numel(SourceFiles), Args{end+1} = fullfile(Core,'src',SourceFiles(I).name); end
Compiler = mex.getCompilerConfigurations('C++', 'Selected');
if isempty(Compiler), error('DataIO:Build', 'Select a compiler with mex -setup C++ first.'); end
if ispc
    if isempty(strfind(Compiler.Manufacturer, 'Microsoft'))
        error('DataIO:Build', 'Use a MATLAB-supported Microsoft C++ compiler on Windows.');
    end
    Args{end+1} = 'COMPFLAGS=$COMPFLAGS /std:c++20 /utf-8';
else
    Args{end+1} = 'CXXFLAGS=$CXXFLAGS -std=c++20';
end
mex(Args{:});
for Name = {'modern','native','legacy','archive','tests'}
    copyfile(fullfile(Source,Name{1}), fullfile(Package,Name{1}));
end
for Name = {'setupDataIO.m','README.md','ORIGIN.txt'}
    copyfile(fullfile(Source,Name{1}), fullfile(Package,Name{1}));
end
for Name = {'LICENSE','LICENSING.md','MATLAB-EXCEPTION.txt', ...
        'COMMERCIAL-LICENSE.txt','NOTICE.txt','THIRD-PARTY-NOTICES.txt','LICENSES'}
    copyfile(fullfile(Project,Name{1}),fullfile(Package,Name{1}));
end
fprintf('Package created at %s\nRun setupDataIO and tests/runDataIOTests in this package before distribution.\n', Package);
end

