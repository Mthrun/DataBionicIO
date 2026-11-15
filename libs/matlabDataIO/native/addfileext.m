function filename = addfileext(filename, ext);
% filename = addfileext(filename, ext);
%
% add file extension if not already there
%
% INPUT
% filename              file name
% ext                   file extension
%
% OUTPUT
% filename              file name
%
% in $Source: /data/CVS/ag/dbt/DataIO/addfileext.m,v $
%
% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.2 $
%
% HISTORY
% $Log: addfileext.m,v $
% Revision 1.2  2005/04/13 09:22:09  fabian
% *** empty log message ***
%
% Revision 1.1  2004/12/03 10:10:48  fabian
% new IO: scientific notation, faster, sexier.
%
%
if ~strcmp(tail(filename,length(ext)),ext)
    filename = [filename,ext];
end

