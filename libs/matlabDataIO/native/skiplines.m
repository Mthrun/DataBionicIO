function [line,Comment] = skiplines(fid, skip);
% [line,Comment] = skiplines(fid, skip);
% skip empty lines and lines that start with certain characters
% discard newline character
% INPUT
% fid                   file id of open file
% skip                  character(s) that indicate lines to skip
%
% OUTPUT
% line                  first line which is not skipped, discarded newline character
% Comment               char array of all skipped comments, if non Comment = [];
%
% The old loop indexed empty lines and required contains. Check EOF and empty
% lines first, and use character comparison for MATLAB R2012 compatibility.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
line = fgetl(fid);
Comment = {};
while ischar(line) && (isempty(line) || any(skip == line(1)))
    if ~isempty(line), Comment{end+1} = line(2:end); end
    line = fgetl(fid);
end
Comment = char(Comment);

