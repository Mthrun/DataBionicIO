function d = defines(count);
% Make typical defines vector [9,1,1...]
%
% INPUT
% count   number of columns
%
%
% in $Source: /data/CVS/ag/dbt/DataIO/defines.m,v $
%
% OUTPUT
% d is a row vector of ones with its first element set to 9.

% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.2 $
%
% HISTORY
% $Log: defines.m,v $
% Revision 1.2  2005/04/13 09:22:09  fabian
% *** empty log message ***
%
% Revision 1.1  2004/12/03 10:10:48  fabian
% new IO: scientific notation, faster, sexier.
%
d = ones(1,count);
d(1) = 9;

