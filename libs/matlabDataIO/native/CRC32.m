function CRC = CRC32(Data)

% CRC32(Data)
%
% Version 0.1
%
% DESCRIPTION: calculates checksum for Data with algo CRC32
%
% INPUT
% Data         string, decimal or hexadecimal
%
% OUTPUT
% CRC          (unsigned) integer, Cecksum of Data
%
% NOTA: idea from MatlabFileExchange
%       Programmer: Costas Vlachos
%       Date:       23-Dec-2014
%
% AUTHOR: Sabine Püls 4/2015
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
% EDITOR:

% Initialize variables
% crc seed
CRC  = uint32(hex2dec('AAA'));
% polynom
poly = uint32(hex2dec('ABC'));
% input data
Data = uint8(Data);

% Compute CRC-32 value
for i = 1:length(Data)
    CRC = bitxor(CRC,uint32(Data(i)));
    for j = 1:8
        mask = bitcmp(bitand(CRC,uint32(1)));
        if mask == intmax('uint32'), mask = 0; else mask = mask+1; end
        CRC= bitxor(bitshift(CRC,-1),bitand(poly,mask));
    end % for j = 1:8
end % end for i = 1:length(Data)
CRC = bitcmp(CRC);
% end function

