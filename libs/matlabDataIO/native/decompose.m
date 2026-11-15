function [keyCols,dataCols,dataNames] = decompose(data, names, defines);
% Decompose data matrix into keys columns and data columns
%
% INPUT
% data       data matrix
% names      column names
% defines    column data type definition
%
% OUTPUT
% keyCols    all key columns, i.e. columns where defines = 9
% dataCols   all data columns, i.e. columns where defines = 1
% dataNames  names for data columns
%
% in $Source: /data/CVS/ag/dbt/DataIO/decompose.m,v $
%
% $Author: fabian $
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% $Revision: 1.2 $
%
% HISTORY
% $Log: decompose.m,v $
% Revision 1.2  2005/04/13 09:22:09  fabian
% *** empty log message ***
%
% Revision 1.1  2004/12/03 10:10:48  fabian
% new IO: scientific notation, faster, sexier.
%
keyCols   = data(:,defines==9);
dataNames = names(defines==1,:);
dataCols  = data(:,defines==1);

