function [Key,Names,RowRest,Comment,Header,FurtherTexts] = ReadNAMES(FileName,Directory)
% ReadNAMES Read old NAMES files without a compiler. No temporary file is used.
% INPUT
% FileName  Input file name.
% Directory  Optional input directory; empty or absent uses pwd.
%

% OUTPUT
% Key is a double column vector. Names, Comment, and Header are character matrices.
% FurtherTexts contains additional text cells with records in rows.
% RowRest joins the additional fields of each row with tabs.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.

if nargin < 2, Directory = []; end
Result = dataio_legacy_read(FileName,Directory,'names');
Key = Result.Key; Names = Result.Names; Comment = Result.Comment;
Header = char(Result.Header); FurtherTexts = Result.Rest;
RowRest = cell(numel(Key),1);
for I=1:numel(Key)
    RowRest{I} = '';
    for J=1:size(FurtherTexts,2)
        if J>1, RowRest{I} = [RowRest{I},sprintf('\t')]; end
        RowRest{I} = [RowRest{I},FurtherTexts{I,J}];
    end
end
end

