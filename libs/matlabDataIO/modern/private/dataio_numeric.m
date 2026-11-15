function Value = dataio_numeric(Value)
% Keep the matrix shape. Reject storage that the C++ gateway cannot read.
% INPUT
% Value  Full real numeric matrix to convert to double.
%

% OUTPUT
% Value is a full real double matrix with the input shape.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if ~isnumeric(Value) || ~isreal(Value) || issparse(Value) || ~ismatrix(Value)
    error('DataIO:Numeric', 'Use a full real numeric matrix.');
end
Value = double(Value);
end

