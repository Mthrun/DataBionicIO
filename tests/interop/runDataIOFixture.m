function runDataIOFixture(RequestFile, ResultFile)
% INPUT
% RequestFile  JSON cases with absolute file paths. Select the built package first.
% ResultFile  JSON output path.
% OUTPUT
% Native public-API observations and diagnostics. Requested files are written.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Requests = jsondecode(fileread(RequestFile));
Results = cell(numel(Requests),1);
for I = 1:numel(Requests)
    if iscell(Requests), Q = Requests{I}; else, Q = Requests(I); end
    lastwarn('');
    BeforeDirectory = pwd;
    Captured = evalc('Result = observe(Q);');
    [Message, ID] = lastwarn;
    Result.diagnostics = {Message}; Result.warning_id = ID; Result.stdout = Captured;
    Result.working_directory_unchanged = strcmp(pwd,BeforeDirectory);
    Results{I} = Result;
end
File = fopen(ResultFile,'w','n','UTF-8');
if File < 0, error('DataIO:Tests','Cannot open result file.'); end
Close = onCleanup(@() fclose(File)); %#ok<NASGU>
fprintf(File,'%s\n',jsonencode(Results));
end

function Out = observe(Q)
% INPUT
% Q  One public-API request.
% OUTPUT
% Observed values or the native error identifier and message.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Out = struct('id',Q.id,'ok',true);
try
    if strcmp(Q.operation,'helper')
        A = numbers(Q.a); B = numbers(Q.other); BeforeA = A; BeforeB = B;
        Out.value = TheSameKey(A,B);
        Out.immutable = isequaln(A,BeforeA) && isequaln(B,BeforeB);
        Out.native_type = class(Out.value); return
    end
    [Directory,Name,Extension] = fileparts(Q.path); Name = [Name Extension];
    Options = struct('Verbose',get(Q,'verbose',false));
    if strcmp(Q.operation,'legacy')
        Original = path; Restore = onCleanup(@() path(Original)); %#ok<NASGU>
        setupDataIO('legacy'); feval(Q.entry_point,Name); return
    end
    if strcmp(Q.operation,'write')
        Options.Overwrite = get(Q,'overwrite',true);
        Extra = get(Q,'options',struct()); Fields = fieldnames(Extra);
        for J=1:numel(Fields), Options.(Fields{J})=Extra.(Fields{J}); end
        Key = numbers(Q.keys); Comment = get(Q,'comment','');
        switch Q.format
            case 'lrn'
                A = inputData(Q); Header = Q.header;
                Variant = get(Q,'matlab_variant','normal');
                if strcmp(Variant,'six')
                    WriteLRN(Name,A,Header,Key,[],Directory);
                elseif strcmp(Variant,'seven')
                    WriteLRN(Name,A,Header,Key,[],Directory,Comment);
                elseif strcmp(Variant,'ten')
                    WriteLRN(Name,A,Header,Key,[],Directory,[],[],[],[]);
                else
                    WriteLRN(Name,A,Header,Key,[],Directory,Comment,[],get(Q,'old_digits',[]),Options);
                end
            case 'cls'
                WriteCLS(Name,numbers(Q.classes),Key,Directory,Comment,1,Options);
            case 'names'
                Names = textcells(Q.names); Further = Q.further_texts;
                if isempty(Further) || all(cellfun(@isempty,Further(:))) && get(Q,'extra_columns',1)==0
                    Further = cell(numel(Names),0);
                else, Further = textcells(Further); end
                WriteNAMES(Name,Names,Key,Further,Directory,Q.header,Comment,Options);
            case 'dts'
                Options.Format = get(Q,'time_format',3);
                Time = textcells(Q.times);
                if isfield(Q,'native_epoch_ms')
                    Time = datetime(numbers(Q.native_epoch_ms)/1000,'ConvertFrom','posixtime','TimeZone',Q.timezone);
                end
                WriteDates(Name,Time,inputData(Q),Q.header,Key,Directory,Comment,Options);
            otherwise, error('DataIO:Tests','Unknown format.');
        end
        return
    end
    switch Q.format
        case 'lrn'
            [A,K,H,T,C] = ReadLRN(Name,Directory,Options);
            Out.data = hexrows(A); Out.shape = num2cell(size(A));
            Out.header = charrows(H); Out.types = num2cell(T(:)');
        case 'cls'
            [K,A,C] = ReadCLS(Name,Directory,Options);
            Out.classes = hexvector(A);
        case 'names'
            [K,N,~,C,H,F] = ReadNAMES(Name,Directory,Options);
            Out.names = charrows(N); Out.header = charrows(H);
            Out.names_shape = num2cell(size(N));
            Out.further_texts = cell(size(F,1),1);
            for J=1:size(F,1), Out.further_texts{J}=F(J,:); end
        case 'dts'
            [T,A,K,H,C,Z,D] = ReadDates(Name,Directory,Options);
            Out.times = T; Out.data = hexrows(A); Out.shape = num2cell(size(A));
            Out.header = charrows(H); Out.timezone = Z; Out.dst = D;
            Out.native_time_type = class(T);
        otherwise, error('DataIO:Tests','Unknown format.');
    end
    Out.keys = arrayfun(@(X) sprintf('%.0f',X),K(:)','UniformOutput',false);
    Out.keys(isnan(K)) = {'NA'}; Out.comment = C;
catch Problem
    Out.ok=false; Out.error=Problem.message; Out.error_type=Problem.identifier;
end
end

function X = get(Q,Name,Default)
% INPUT
% Q, Name, Default  Request, field name, and fallback value.
% OUTPUT
% Field value, or Default when the field is absent.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if isfield(Q,Name), X=Q.(Name); else, X=Default; end
end

function X = numbers(X)
% INPUT
% X  Decimal strings or numeric input from JSON.
% OUTPUT
% Double values with the original matrix shape.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if iscell(X), X=cellfun(@number,X); else, X=double(X); end
end

function X = number(X)
% INPUT
% X  One decimal string, numeric value, or JSON null.
% OUTPUT
% One double value. JSON null becomes NaN.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if isnumeric(X)
    if isempty(X), X=NaN; else, X=double(X); end
else, X=str2double(X); end
end

function A = inputData(Q)
% INPUT
% Q  Request with numeric rows and optional binary64 hexadecimal rows.
% OUTPUT
% Matrix containing the specified binary64 input values.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if ~isfield(Q,'data_bits'), A=numbers(Q.data); return; end
Bits=Q.data_bits; A=zeros(size(Bits));
for I=1:numel(Bits)
    if strcmp(Bits{I},'NaN'), A(I)=NaN; else, A(I)=hex2num(Bits{I}); end
end
end

function X = textcells(X)
% INPUT
% X  Text cells with optional JSON null values.
% OUTPUT
% Text cells with null values represented by the file token NA.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
if ischar(X), X={X}; end
for I=1:numel(X), if isnumeric(X{I}) && isempty(X{I}), X{I}='NA'; end, end
end

function Rows = charrows(A)
% INPUT
% A  Native character matrix.
% OUTPUT
% Complete character rows, including all padding and original spaces.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Rows=cell(size(A,1),1);
for I=1:size(A,1), Rows{I}=A(I,:); end
end

function V = hexvector(A)
% INPUT
% A  Numeric vector.
% OUTPUT
% Binary64 hexadecimal values. All NaN payloads use the token NaN.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
V=cellstr(num2hex(A(:))); V(isnan(A))={'NaN'};
end

function Rows = hexrows(A)
% INPUT
% A  Numeric matrix.
% OUTPUT
% Binary64 hexadecimal values in records-by-columns order.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
Rows=cell(size(A,1),1);
for I=1:size(A,1), Rows{I}=hexvector(A(I,:)); end
end
