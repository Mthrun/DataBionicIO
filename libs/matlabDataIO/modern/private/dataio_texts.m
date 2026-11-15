function Value = dataio_texts(Value, MissingText)
% Convert MATLAB text to a cell array. Empty text is a missing field.
% Header labels keep empty text so that the core can reject an empty label.
% INPUT
% Value  Character matrix, string array, or cell array of character rows.
% MissingText  Optional logical flag; true converts empty or missing cells to NA.
%

% OUTPUT
% Value is a cell array of character rows.
% MissingText controls conversion of empty or missing text to NA.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 2, MissingText = true; end
if isempty(Value)
    Value = cell(0, 1);
elseif ischar(Value)
    Value = cellstr(Value); % Remove padding from old character matrices.
elseif isstring(Value)
    if MissingText, Value(ismissing(Value)) = "NA";
    else, Value(ismissing(Value)) = ""; end
    Value = cellstr(Value);
elseif ~iscell(Value)
    error('DataIO:Text', 'Use a character matrix, a string array, or a cell array of character rows.');
end
if ndims(Value) > 2 || ~all(cellfun(@(x) ischar(x) && (isrow(x) || isempty(x)), Value(:)))
    error('DataIO:Text', 'Each text cell must contain one character row.');
end
if MissingText, Value(cellfun(@isempty, Value)) = {'NA'}; end
end

