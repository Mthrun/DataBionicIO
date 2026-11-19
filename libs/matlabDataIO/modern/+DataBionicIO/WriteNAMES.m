function WriteNAMES(FileName, Names, Key, FurtherTexts, Header, OutDirectory, Comments, Overwrite, Verbose)
% WriteNAMES Write NAMES with the common DataBionicIO argument order.
% INPUT
% FileName, Names, Key, FurtherTexts, Header, OutDirectory, Comments, Overwrite, Verbose.
% Empty optional arguments select the defaults documented in API.md.
% OUTPUT
% A format 2.0 file. No return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 3 || isempty(Key), Key = []; end
if nargin < 4 || isempty(FurtherTexts), FurtherTexts = cell(numel(Names), 0); end
if nargin < 5 || isempty(Header), Header = []; end
if nargin < 6 || isempty(OutDirectory), OutDirectory = pwd; end
if nargin < 7 || isempty(Comments), Comments = []; end
if nargin < 8 || isempty(Overwrite), Overwrite = true; end
if nargin < 9 || isempty(Verbose), Verbose = true; end
if isempty(FurtherTexts), FurtherTexts = cell(0, 0); end
Options = struct('Overwrite', Overwrite, 'Verbose', Verbose);
feval('WriteNAMES', FileName, Names, Key, FurtherTexts, OutDirectory, Header, Comments, Options);
end
