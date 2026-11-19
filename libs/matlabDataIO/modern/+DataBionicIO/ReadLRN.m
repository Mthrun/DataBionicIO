function [Key, Data, Header, DataDefined, Comments] = ReadLRN(FileName, InDirectory, Verbose)
% ReadLRN Read LRN through the common DataBionicIO interface.
% INPUT
% FileName  Input file name.
% InDirectory  Optional input directory; default pwd.
% Verbose  Optional information-message flag; default true.
% OUTPUT
% Key, Data, Header, DataDefined, Comments in this fixed order.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2 || isempty(InDirectory), InDirectory = pwd; end
if nargin < 3 || isempty(Verbose), Verbose = true; end
Result = dataio_common('read_lrn', struct('Path', fullfile(InDirectory, FileName)), Verbose);
Key = Result.Key;
Data = Result.Data;
Header = Result.Header;
DataDefined = Result.DataDefined;
Comments = Result.Comment;
end
