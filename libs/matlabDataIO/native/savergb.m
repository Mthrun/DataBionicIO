function savergb(filename, colors);
% savergb(filename, colors);
%
% Save colors to *.rgb file
%
% INPUT
% filename     filename of *.rgb file
% colors       colors in nx3 matrix
%
% in $Source: /data/CVS/ag/dbt/DataIO/savergb.m,v $
%
% OUTPUT
% No return value. Writes an RGB file with one color triplet per line.

% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.2 $
%
% HISTORY
% $Log: savergb.m,v $
% Revision 1.2  2005/04/18 10:07:39  fabian
% io fixes: better error messages and optional better readable lrn
%
% Revision 1.1  2005/04/13 10:10:55  fabian
% *** empty log message ***
%
% Revision 1.2  2004/12/03 10:10:48  fabian
% new IO: scientific notation, faster, sexier.
%
%

% parameter check
if nargin < 2
  error('savergb: all 2 input parameters needed!');
end

% make sure extension is there
filename = addfileext(filename,'.rgb');

% integers or floats
int = max(max(colors-floor(colors)))==0;

% save colors
fid = fopen(filename,'w');
if fid == (-1) error(['savergb: could not open file ', filename]); end;
if int == 1
    fprintf(fid,'%d\t%d\t%d\n',reshape(colors',prod(size(colors)),1));
else
    fprintf(fid,'%f\t%f\t%f\n',reshape(colors',prod(size(colors)),1));
end
fclose(fid);

