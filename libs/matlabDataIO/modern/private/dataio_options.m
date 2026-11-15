function Options = dataio_options(Options, Defaults)
% Use one optional struct. Reject unknown fields to catch spelling errors.
% INPUT
% Options  Optional scalar struct with supplied option values.
% Defaults  Scalar struct of supported fields and default values.
%

% OUTPUT
% Options contains validated values and defaults for unspecified fields.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if isempty(Options), Options = struct(); end
if ~isstruct(Options) || ~isscalar(Options)
    error('DataIO:Options', 'Options must be a scalar struct.');
end
Fields = fieldnames(Options);
for I = 1:numel(Fields)
    if ~isfield(Defaults, Fields{I})
        error('DataIO:Options', 'Unknown option: %s.', Fields{I});
    end
    Defaults.(Fields{I}) = Options.(Fields{I});
end
Options = Defaults;
Flags = {'Overwrite', 'Verbose', 'Scientific'};
for I = 1:numel(Flags)
    Name = Flags{I};
    if isfield(Options, Name)
        Value = Options.(Name);
        if ~(isnumeric(Value) || islogical(Value)) || ~isreal(Value) || ~isscalar(Value) || ~any(Value == [0 1])
            error('DataIO:Options', '%s must be true or false.', Name);
        end
        Options.(Name) = double(Value);
    end
end
end

