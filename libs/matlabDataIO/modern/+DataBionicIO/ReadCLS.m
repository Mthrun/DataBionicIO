function [Key, Cls, UniqueClasses, Comments] = ReadCLS(FileName, InDirectory, Verbose, varargin)
% ReadCLS Read CLS through the common DataBionicIO interface.
% INPUT
% FileName  Input file name.
% InDirectory  Optional input directory; default pwd.
% Verbose  Optional information-message flag; default true.
% varargin  Optional Encoding name-value pair; normally unnecessary.
% OUTPUT
% Key, Cls, UniqueClasses, Comments in this fixed order.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if nargin < 2 || isempty(InDirectory), InDirectory = pwd; end
if nargin < 3 || isempty(Verbose), Verbose = true; end
Result = dataio_common('read_cls', struct('Path', fullfile(InDirectory, FileName), ...
    'Encoding', dataio_text_option(varargin, 'Encoding', '')), Verbose);
Key = Result.Key;
Cls = Result.Cls;
UniqueClasses = Result.UniqueClasses;
Comments = Result.Comment;
end
