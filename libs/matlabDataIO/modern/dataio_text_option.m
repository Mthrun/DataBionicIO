function Value = dataio_text_option(Arguments, Name, Default)
% INPUT
% Arguments  Optional name-value pair from varargin.
% Name  Exact supported option name. Default is used when Arguments is empty.
% OUTPUT
% One character row. Unknown, duplicate, or unnamed options cause an error.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Value = Default;
if isempty(Arguments), return; end
if numel(Arguments) ~= 2 || ...
        ~((ischar(Arguments{1}) && isrow(Arguments{1})) || ...
          (isstring(Arguments{1}) && isscalar(Arguments{1}))) || ...
        ~strcmp(Arguments{1}, Name)
    error('DataIO:Options', 'Use only the exact name-value option %s.', Name);
end
Value = Arguments{2};
if isstring(Value) && isscalar(Value) && ~ismissing(Value), Value = char(Value); end
if ~ischar(Value) || ~(isrow(Value) || isempty(Value))
    error('DataIO:Options', '%s must be one character row or string scalar.', Name);
end
end
