function Path = dataio_path(FileName, Directory)
% Resolve the file name without changing the current directory.
% INPUT
% FileName  Nonempty file name as a character row or scalar string.
% Directory  Directory path, or empty to use pwd.
%

% OUTPUT
% Path is an absolute file path. The current directory does not change.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if isstring(FileName) && isscalar(FileName), FileName = char(FileName); end
if isstring(Directory) && isscalar(Directory), Directory = char(Directory); end
if ~ischar(FileName) || ~isrow(FileName) || isempty(FileName)
    error('DataIO:Path', 'FileName must contain one file name.');
end
if isempty(Directory), Directory = pwd; end
if ~ischar(Directory) || ~isrow(Directory), error('DataIO:Path', 'Directory must contain one path.'); end
IsAbsolute = FileName(1) == '/' || FileName(1) == '\' || ...
    (numel(FileName) >= 3 && FileName(2) == ':' && any(FileName(3) == ['/','\']));
if IsAbsolute
    Path = FileName;
else
    Path = fullfile(Directory, FileName);
end
% The core DATES reader needs a parent directory, also for relative input.
IsAbsolute = Path(1) == '/' || Path(1) == '\' || (numel(Path) >= 2 && Path(2) == ':');
if ~IsAbsolute, Path = fullfile(pwd, Path); end
end

