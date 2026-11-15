function files = listfiles(paths,includesubdirs,dirfilters)
% returns all files in the given paths optional including subdirs
%
% files = listfiles
% files = listfiles(paths)
% files = listfiles(paths,dirfilters)
% files = listfiles(paths,includesubdirs)
% files = listfiles(paths,includesubdirs,dirfilters)
%
% collects all files defined by the paths-variable. paths may be a
% string, that enlists directories & files separated by the semicolon.
%
% FILES
% the paths can contain enlisted files
% i.e.: paths='....;C:\test\mymat.m;....'
% a file followed by a boolean is handled as a file
% i.e.: paths = '...;C:\test\mymat.m;1;...'
%    => paths = '...;C:\test\mymat.m;...'
%
% DIRFILTERS
% an enlisted dir can be defined by a dirfilter, that is used to
% enlist only files of the defined type,
% i.e.: paths = '....;C:\test\*.m;...';
% if the enlisted dir is not follwed by a dirfilter, the dirfilters
% of the input-param dirfilters are used.
% i.e.: paths = '...;C:\test;...', dirfilters = {'*.m','*.r'}
%    => paths = '...;C:\test\*.m;C:\test\*.r;...'
%
% INCLUDESUBDIRS
% an enlisted dir can be followed by an boolean, defining, that the
% subdirs should be included in enlisting.
% i.e.: paths = '....;C:\test\*.*;1;...'
%    => paths = '....;C:\test\subdir(1)\*.*;...;C:\test\subdir(n);...'
% if the enlisted dir is not followed by a boolean, the includesubdir
% is defined by the includesubdirs input-param.
% i.e.: paths = '....;C:\test\*.m;....', includesubdirs=0
%    => paths = '....;C:\test\*.m;0;....'
%
% INPUT
% [paths] = cd              stringlist  a list of strings, that follow the paths-definition
% [includesubdirs] = 0      boolean     for dirs in paths not followed by boolean
% [dirfilters] = '*.*';     stringlist  list of dirfilters for dirs in paths without dirfilter
%                                       
% OUTPUT
% files                     cellstr     list of fullfilenames extracted from paths
%
% NOTICE
% unknown or not validate dirs/files are ignored.
%
% EXAMPLE
% to-do
%
% @author: Ingo Löhken
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.
files = {};

d_dirfilters     = '*.*';
d_includesubdirs = 0;
d_paths          = cd;

%try
    % il: verify num of i/o-params
    error(nargchk(0,3,nargin));
    error(nargoutchk(0,1,nargout));
            
    % il: default input-params
    if(nargin==0)
        paths          = d_paths;
        includesubdirs = d_includesubdirs;
        dirfilters     = d_dirfilters;
    elseif(nargin==1)
        includesubdirs = d_includesubdirs;
        dirfilters     = d_dirfilters;
    elseif(nargin==2)
        dirfilters = d_dirfilters;
    end
    
    if(isempty(paths)) return; end
    
    % il: default computing format
    %dirfilters = strlist2cellstr(dirfilters);      
    
    % il: parse the paths to an processing list
    %[searchpath,isdir,dirfilter,includesubdir] = paths2list(paths);
     
    % il: enlist the files recursiv
    %for k=1:length(searchpath)
    %    if(isempty(dirfilter{k}))
    %        dirfilter{k} = dirfilters;
    %    else
    %        dirfilter{k} = strlist2cellstr(dirfilter{k});
    %    end
    %    
    %    if(isnan(includesubdir(k)))
    %        includesubdir(k) = includesubdirs;
    %    end
    %    
    %    files = [files,enlist(searchpath{k},isdir(k),dirfilter{k},includesubdir(k))];
    %end
    
    files = [files,enlist(paths,1,{dirfilters},includesubdirs)];
    
    files = unique(files);
%catch
%    error([mfilename,': ',lasterr]);
%end



function files = enlist(searchpath,isdir,dirfilters,includesubdirs)
% Resolve one file or a directory search.
%
% INPUT
% searchpath  File or directory path.
% isdir  True when searchpath is a directory.
% dirfilters  Cell array of file patterns.
% includesubdirs  True enables recursive directory search.
%
% OUTPUT
% files is a cell array of matching paths, or the supplied file path.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.


files={};

if(isdir)
    for k=1:length(dirfilters)
        if(~includesubdirs)
            files = [files,files_dir(searchpath,dirfilters{k})];
        else
            files = [files,files_dirs(searchpath,dirfilters{k})];
        end
    end                            
else
    files = cellstr(searchpath);
end
    


function files=files_dirs(searchdir,dirfilter)
% List matching files recursively.
%
% INPUT
% searchdir  Nonempty directory path.
% dirfilter  File pattern passed to dir.
%
% OUTPUT
% files is a cell array of matching files in searchdir and its subdirectories.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.


files={};

try 
    if(searchdir(length(searchdir))~=filesep)
        searchdir=[searchdir,filesep];
    end
    
    files      = files_dir(searchdir,dirfilter);
    % found_dirs = dir([searchdir,'*.']);
    if(ispc) 
        found_dirs = dir([searchdir,'*.']);
    elseif(isunix)
        found_dirs = dir(searchdir);
    end
    
    for i=1:size(found_dirs)
        found_dir = found_dirs(i).name;
        
        if(found_dirs(i).isdir && ~strcmp(found_dir,'.') && ~strcmp(found_dir,'..'))
            files=[files,files_dirs([searchdir,found_dir],dirfilter)];
        end
    end
catch
    error([mfilename,': ',lasterr]);
end



function files=files_dir(searchdir,dirfilter)
% List matching files in one directory.
%
% INPUT
% searchdir  Nonempty directory path.
% dirfilter  File pattern passed to dir.
%
% OUTPUT
% files is a cell array of matching non-directory paths.
% SPDX-License-Identifier: AGPL-3.0-only
% Additional permission: see MATLAB-EXCEPTION.txt.


files={};

try
    if(searchdir(length(searchdir))~=filesep)
        searchdir=[searchdir,filesep];
    end
    
    found_files = dir([searchdir,dirfilter]);
    
    for i=1:size(found_files)
        if(~found_files(i).isdir) files =[files,cellstr([searchdir,found_files(i).name])]; end
    end
catch
    error([mfilename,': ',lasterr]);
end

