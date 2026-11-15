function Key = dataio_keys(Key, Count)
% Keep 64-bit integer input intact until the C++ range check.
% INPUT
% Key  Full real numeric key vector, or empty to generate keys.
% Count  Required number of keys.
%

% OUTPUT
% Key is a column vector with one key per row.
% Missing keys become 1:Count. Supplied 64-bit integer values retain their type.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if isempty(Key)
    warning('DataIO:MissingKey', 'Key was not supplied. Using 1:n. Supply Key to keep row identifiers stable.');
    Key = (1:Count)';
elseif ~isnumeric(Key) || ~isreal(Key) || issparse(Key) || ~isvector(Key)
    error('DataIO:Key', 'Key must be a full real numeric vector.');
elseif ~isa(Key, 'int64') && ~isa(Key, 'uint64')
    Key = double(Key);
end
Key = Key(:);
if numel(Key) ~= Count, error('DataIO:Key', 'Supply one Key for each row.'); end
end

