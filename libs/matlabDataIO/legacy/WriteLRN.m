function varargout = WriteLRN(varargin)
% WriteLRN Requires the current C++ package. Legacy mode provides only readers.
% INPUT
% varargin  Accepted call arguments; this guard does not inspect them.
%

% OUTPUT
% No return value. The function raises DataIO:LegacyReadOnly.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

error('DataIO:LegacyReadOnly', 'WriteLRN requires the C++ package on MATLAB R2022a or later.');
end

