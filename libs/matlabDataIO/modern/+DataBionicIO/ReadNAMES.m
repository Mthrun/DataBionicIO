function [Key, Names, FurtherTexts, Header, Comments] = ReadNAMES(FileName, InDirectory, Verbose)
% ReadNAMES Read NAMES through the common DataBionicIO interface.
% INPUT
% FileName  Input file name.
% InDirectory  Optional input directory; default pwd.
% Verbose  Optional information-message flag; default true.
% OUTPUT
% Key, Names, FurtherTexts, Header, Comments in this fixed order.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2 || isempty(InDirectory), InDirectory = pwd; end
if nargin < 3 || isempty(Verbose), Verbose = true; end
Result = dataio_common('read_names', struct('Path', fullfile(InDirectory, FileName)), Verbose);
Result.Header = Result.Header(3:end);
Key = Result.Key;
Names = Result.Names;
FurtherTexts = Result.FurtherTexts;
Header = Result.Header;
Comments = Result.Comment;
end
