function colors = loadrgb(filename);
% colors = loadrgb(filename);
%
% Load colors from *.rgb file.
%
% INPUT
% filename     filename of *.rgb file
%
% OUTPUT
% colors       colors in nx3 matrix
%
% in $Source: /data/CVS/ag/dbt/DataIO/loadrgb.m,v $
%
% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.1 $
%
% HISTORY
% $Log: loadrgb.m,v $
% Revision 1.1  2005/04/13 10:10:55  fabian
% *** empty log message ***
%
% Revision 1.2  2004/12/03 10:10:48  fabian
% new IO: scientific notation, faster, sexier.
%
%

% make sure extension is there
filename = addfileext(filename,'.rgb');

% load colors
fid = fopen(filename,'r');
if fid == (-1) error(['loadrgb: could not open file ', filename]); end;
colors = fscanf(fid,'%f\t%f\t%f\n');
colors = reshape(colors,3,length(colors)/3)';
fclose(fid);

