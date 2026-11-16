function KeyOK = TheSameKey(KeyA, KeyB)
% Compare numeric vectors by length, value, and position through the C++ core.
% INPUT
% KeyA, KeyB  Real numeric or logical row or column vectors.
% OUTPUT
% KeyOK is one logical scalar. Missing or unsupported inputs give false.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% Two empty vectors compare equal. NaN never compares equal, including to NaN.
% No sorting, uniqueness check, or input changes occur. No tolerance is used.
% Integer values must convert to double without loss.

KeyOK = false;
Values = {KeyA, KeyB};
for I = 1:2
    Value = Values{I};
    if ~(isnumeric(Value) || islogical(Value)) || ~isreal(Value) || ...
            issparse(Value) || ndims(Value) ~= 2 || ...
            ~(isvector(Value) || isempty(Value))
        return;
    end
    Converted = double(Value);
    if isa(Value,'int64') && (any(Converted(:) >= 2^63) || ...
            any(int64(Converted(:)) ~= Value(:)))
        return;
    end
    if isa(Value,'uint64') && (any(Converted(:) >= 2^64) || ...
            any(uint64(Converted(:)) ~= Value(:)))
        return;
    end
    Values{I} = Converted;
end
Result = dataio_call('the_same_key',struct('KeyA',Values{1},'KeyB',Values{2}),false);
KeyOK = Result.Same;
end
