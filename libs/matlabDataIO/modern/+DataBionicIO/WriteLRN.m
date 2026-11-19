function WriteLRN(FileName, Data, Header, Key, DataDefined, OutDirectory, Comments, SignificantDigits, DecimalDigits, Scientific, Overwrite, Verbose)
% WriteLRN Write LRN with the common DataBionicIO argument order.
% INPUT
% FileName, Data, Header, Key, DataDefined, OutDirectory, Comments, SignificantDigits, DecimalDigits, Scientific, Overwrite, Verbose.
% Empty optional arguments select the defaults documented in API.md.
% OUTPUT
% A format 2.0 file. No return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 3 || isempty(Header), Header = []; end
if nargin < 4 || isempty(Key), Key = []; end
if nargin < 5 || isempty(DataDefined), DataDefined = []; end
if nargin < 6 || isempty(OutDirectory), OutDirectory = pwd; end
if nargin < 7 || isempty(Comments), Comments = []; end
if nargin < 8 || isempty(SignificantDigits), SignificantDigits = []; end
if nargin < 9 || isempty(DecimalDigits), DecimalDigits = []; end
if nargin < 10 || isempty(Scientific), Scientific = false; end
if nargin < 11 || isempty(Overwrite), Overwrite = true; end
if nargin < 12 || isempty(Verbose), Verbose = true; end
Options = struct('Overwrite', Overwrite, 'Verbose', Verbose);
if ~isempty(SignificantDigits), Options.SignificantDigits = SignificantDigits; end
if ~isempty(DecimalDigits), Options.DecimalDigits = DecimalDigits; end
feval('WriteLRN', FileName, Data, Header, Key, DataDefined, OutDirectory, Comments, Scientific, [], Options);
end
