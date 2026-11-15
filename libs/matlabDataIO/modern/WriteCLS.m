function WriteCLS(FileName, Cls, Key, Directory, Comment, ClassSizes, Options)
% WriteCLS Write class assignments as CLS format 2.0.
% WriteCLS(FileName,Cls,Key,Directory,Comment,ClassSizes,Options)
% INPUT: FileName is the output file name.
% Cls is a numeric vector or a two-column matrix [Key,Cls].
% OPTIONAL: Comment contains text for the file comment lines.
% Key defaults to 1:n with a warning. Directory defaults to pwd.
% The format 2.0 writer always adds class counts. ClassSizes=0 gives a warning.
% OPTIONS: Overwrite=true, Verbose=false, NaNReplacement=NaN.
% OUTPUT
% A CLS format 2.0 file. The function has no return value.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 3, Key = []; end
if nargin < 4, Directory = []; end
if nargin < 5, Comment = []; end
if nargin < 6, ClassSizes = 1; end
if nargin < 7, Options = []; end
if ~isvector(Cls) && size(Cls, 2) == 2
    Key = Cls(:, 1); Cls = Cls(:, 2);
end
Cls = dataio_numeric(Cls);
if ~isvector(Cls), error('DataIO:Class', 'Cls must be a vector or a two-column matrix.'); end
if isequal(ClassSizes, 0)
    warning('DataIO:ClassSizes', 'Format 2.0 always includes class counts. ClassSizes=0 is ignored.');
end
Options = dataio_options(Options, struct('Overwrite', true, 'Verbose', false, 'NaNReplacement', NaN));
Request = Options;
Request.Path = dataio_path(FileName, Directory);
Request.Cls = Cls(:);
Request.Key = dataio_keys(Key, numel(Cls));
Request.Comment = dataio_comment(Comment);
dataio_call('write_cls', Request, Options.Verbose);
end

