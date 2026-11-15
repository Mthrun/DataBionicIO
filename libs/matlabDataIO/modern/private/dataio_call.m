function Result = dataio_call(Command, Request, Verbose)
% Emit MATLAB warnings only after C++ objects and file streams leave scope.
% INPUT
% Command  MEX command name.
% Request  Scalar struct with fields required by Command.
% Verbose  True enables information messages; warnings remain active.
%

% OUTPUT
% Result is the MEX command result. Captured warnings are passed to MATLAB.
% A reported core failure raises DataIO:Core.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

[Result, Messages, Failure] = dataio_mex(Command, Request);
if ~isempty(Failure), error('DataIO:Core', '%s', Failure); end
Lines = regexp(Messages, '\r?\n', 'split');
for I = 1:numel(Lines)
    Line = Lines{I};
    if strncmpi(Line, 'WARNING:', 8)
        warning('DataIO:FileWarning', '%s', strtrim(Line(9:end)));
    elseif Verbose && ~isempty(Line)
        fprintf('%s\n', Line);
    end
end
end

