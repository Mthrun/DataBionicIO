function WriteCLS(FileName, Cls, OutDirectory, Key, Comment, Int4NaN, Overwrite, Verbose)
% WriteCLS Write CLS with the common DataBionicIO argument order.
% INPUT
% FileName, Cls, OutDirectory, Key, Comment, Int4NaN, Overwrite, Verbose.
% Empty optional arguments select the defaults documented in API.md.
% OUTPUT
% A format 2.0 file. No return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 3 || isempty(OutDirectory), OutDirectory = pwd; end
if nargin < 4 || isempty(Key), Key = []; end
if nargin < 5 || isempty(Comment), Comment = []; end
if nargin < 6 || isempty(Int4NaN), Int4NaN = NaN; end
if nargin < 7 || isempty(Overwrite), Overwrite = true; end
if nargin < 8 || isempty(Verbose), Verbose = true; end
Options = struct('Overwrite', Overwrite, 'Verbose', Verbose, 'NaNReplacement', Int4NaN);
feval('WriteCLS', FileName, Cls, Key, OutDirectory, Comment, 1, Options);
end
