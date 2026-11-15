function Comment = dataio_comment(Comment)
% Join comment rows without converting empty lines to missing text.
% INPUT
% Comment  Empty input, a character row, or text rows to join with newlines.
%

% OUTPUT
% Comment is one character row, with newline separators between input rows.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if isempty(Comment), Comment = ''; return; end
if ischar(Comment) && isrow(Comment), return; end
if ischar(Comment) || isstring(Comment), Comment = cellstr(Comment); end
if ~iscellstr(Comment), error('DataIO:Comment', 'Comment must contain text.'); end
Comment = strjoin(Comment(:)', sprintf('\n'));
end

