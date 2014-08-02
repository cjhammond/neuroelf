function neuroelf_setup
% neuroelf_setup  - NeuroElf post installation setup
%
% FORMAT:       neuroelf_setup
%
% No input/output fields.

% Version:  v0.9d
% Build:    14062017
% Date:     Jun-20 2014, 5:03 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010 - 2014, Jochen Weber
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in the
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of Columbia University nor the
%       names of its contributors may be used to endorse or promote products
%       derived from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% global variables
global ne_ui xffcont;

% close all files
fclose all;

% potentially remove older BVQXtools version from path first
if exist('BVQXfile', 'file') > 0
    bf = which('BVQXfile');
    if ~isempty(strfind(bf, '@BVQXfile'))
        while ~isempty(strfind(bf, '@BVQXfile'))
            bf = fileparts(bf);
        end
        try
            rmpath(bf);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
        rehash path;
    end
end

% get current pwd and switch..
opwd = pwd;
npwd = neuroelf_path;
cd(npwd);

try
    rs = get(0, 'ScreenSize');
    if all(rs(3:4) >= [640, 480])
        hFig = xfigure( ...
            [neuroelf_path('tfg') '/splash.tfg']);
        hPrg = hFig.TagStruct.LB_Progress;
        hBar = hFig.TagStruct.PB_Progress;
        imgh = hFig.TagStruct.IM_Splash.Children;
        imgh = imgh(strcmpi('image', get(imgh, 'Type')));
        imgt = neuroelf_splash(imgh);
        hFig.HandleVisibility = 'callback';
        hFig.Visible = 'on';
        drawnow;
        start(imgt);
    else
        hPrg = [];
        hBar = [];
    end
catch ne_eo;
    warning( ...
        'neuroelf:xfigureError', ...
        'Error with xfigure class: %s.', ...
        ne_eo.message ...
    );
    hPrg = [];
    hBar = [];
end

% print banner
nelftv = neuroelf_version;
nelftb = sprintf('%d', neuroelf_build);
banner = [ ...
    char(10), ...
    '==========================================================', char(10), ...
    char(10), ...
    'NeuroElf v' nelftv ', build ' nelftb ' (unified edition)', char(10), ...
    char(10), ...
    'Please direct any bug reports and/or feature requests directly to:', char(10), ...
    char(10), ...
    'Jochen Weber <jw2661@columbia.edu>', char(10), ...
    char(10), ...
    'Thanks must go to Chih-Jen Lin for allowing the re-use of the', char(10), ...
    'libSVM code repository :)', char(10), ...
    char(10), ...
    'Another thank-you is going to Aapo Hyvarinen for letting me integrate the', char(10), ...
    'FastICA algorithm into the toolbox!', char(10), ...
    char(10), ...
    'All original source code (which contains this license statement) is', char(10), ...
    char(10), ...
    '==========================================================', char(10), ...
    neuroelf_license, ...
    '==========================================================', char(10), ...
    char(10)];
instprog(hPrg, hBar, banner, 0.05);

% build libs (MEX)
mxt = lower(mexext);
mxs = strrep(mxt, 'mex', '');
try
    instprog(hPrg, hBar, ...
        ['Checking/compiling MEX files for current platform (' upper(mxs) ')...'], ...
         0.05, 'Checking MEX files...');
    neuroelf_makelibs(hPrg, hBar, [0.05, 0.5]);

% if an error occurred
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    disp(['There was some error compiling MEX files and NeuroElf does', char(10), ...
          'not come with pre-compiled files for your platform: ', upper(mxs)]);
end

% compiled files not available
try
    rehash path;
    rehash toolboxcache;
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end
if exist('flexinterpn', 'file') ~= 3

    % end of setup; delete figures
    try
        xfigure(xfigure, 'DeleteAllFigures');
    catch ne_eo;
       neuroelf_lasterr(ne_eo);
    end

    % then clear all and exit with error
    evalin('base', 'clear classes;', '');
    clear classes;
    error( ...
        'neuroelf:SetupError', ...
        'Crucial MEX files are missing. Setup cannot continue.' ...
    );
end

% check "helper classes"
try
    instprog(hPrg, hBar, 'Checking xini class...', 0.5, 'Checking classes...');
    v = xini;
    if ~isxini(v)
        error('CLASS_FAILURE');
    end
    try
        v = xini([neuroelf_path('config') '/neuroelf.ini'], 'convert');
        vc = xini([neuroelf_path('config') '/neuroelf_clean.ini'], 'convert');
        vs = vc.GetSections;
        for sc = 1:numel(vs)
            ss = vc.(vs{sc});
            sn = fieldnames(ss);
            for nc = 1:numel(sn)
                v.(vs{sc}).(sn{nc}) = vc.(vs{sc}).(sn{nc});
            end
        end
        v.Save;
        v.Release;
        vc.Release;
    catch ne_eo;
        rethrow(ne_eo);
    end
    try
        v = xini([neuroelf_path('config') '/xff.ini'], 'convert');
        if ~isempty(hPrg)
            vui = inputdlg({'Use the following folder as temporary disk space:'}, ...
                'NeuroElf - temp folder config', 1, {['  ' tempdir]});
        else
            vui = {input(sprintf( ...
                'Please enter the folder used for temporary disk space (%s): ', ...
                tempdir), 's')};
        end
        if iscell(vui) && ...
            numel(vui) == 1 && ...
           ~isempty(ddeblank(vui{1}))
            vui = ddeblank(vui{1});
            if ~isempty(vui) && ...
               ~strcmpi(vui, tempdir) && ...
                exist(vui, 'dir') == 7
                if vui(end) ~= '/' && ...
                    vui(end) ~= '\'
                    v(end+1) = filesep;
                end
                v.GZip.TempDir = vui;
                v.Save;
            end
        end
        v.Release;
    catch ne_eo;
        rethrow(ne_eo);
    end
catch ne_eo;
    warning( ...
        'neuroelf:xiniError', ...
        'Error with xini class: %s.', ...
        ne_eo.message ...
    );
end

% check xff and build cached formats info
try
    instprog(hPrg, hBar, '(Re-)Creating xff cached information...', 0.52);
    try
        cachefile = [neuroelf_path('cache') '/cache.mat'];
        if exist(cachefile, 'file') == 2
            delete(cachefile);
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
    if ~isempty(xffcont)
        xffcont(:) = [];
    end
    v = xff;
    x = sort(fieldnames(v.Extensions));
    nx = numel(x);
    if mod(nx, 8) > 0
        x(end+1:8 * ceil(nx / 8)) = {''};
    end
    x8 = cell(1, numel(x) / 8);
    for xc = 1:numel(x8)
        x8{xc} = sprintf('%5s ', x{(xc - 1) * 8 + 1:xc*8});
    end
    info = [char(10), ...
        sprintf('Current release supports %d xff filetypes:', nx), char(10), ...
    	char(10), ...
        upper(gluetostring(x8, char(10))), char(10)];
    xok = false(size(x));
    for xc = 1:numel(xok)
        try
            xobj = {[]};
            if ~isempty(x{xc})
                xobj{1} = xff(sprintf('new:%s', x{xc}));
                xobj{1}.ClearObject;
            end
            xok(xc) = true;
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            clearxffobjects(xobj);
        end
    end
    xok(strcmpi('root', x(:)')) = true;
    if sum(xok) < numel(xok)
        info = [info, char(10), ...
            sprintf('xff(''new:*'') failed on:%s.', ...
                sprintf(' %s', x{find(~xok)})), ...
            char([10, 10])];
    else
        info = [info, char(10), ...
            'xff(''new:*'') working for all object types.', char([10, 10])];
    end
    instprog(hPrg, hBar, info, 0.7);
catch ne_eo;
    warning( ...
        'neuroelf:xffError', ...
        'Error creating/loading cached info for xff class: %s.', ...
        ne_eo.message ...
    );
end

% create colin brain vmr from colin.img and mask
% see http://imaging.mrc-cbu.cam.ac.uk/imaging/MniTalairach for info
try

    % path
    cpath = [neuroelf_path('colin') filesep];

    % check if VMR already exists
    if exist([cpath 'colin.vmr'], 'file') ~= 2
        instprog(hPrg, hBar, 'Creating colin.vmr from colin.hdr/img...', 0.70, ...
            'Patching/creating required binary files');

        % create if necessary
        colin = importvmrfromanalyze([cpath 'colin.img'], 'lanczos3', [0.01, 0.99]);
        colin.SaveAs([cpath 'colin.vmr']);
    else

        % or load
        colin = xff([cpath 'colin.vmr']);
    end

    % clear colin
    colin.ClearObject;
    colin = [];
catch ne_eo;
    warning( ...
        'neuroelf:xffError', ...
        'Error creating colin_brain.vmr: %s.', ...
        ne_eo.message ...
    );
    colin = [];
end

% test tdlocal2 w/ files
try
    instprog(hPrg, hBar, 'Testing tdlocal2 (local TD database)...', ...
        0.9, 'Testing tdlocal2');
    tdlocal2(2, 0, 0, 0);
catch ne_eo;
    warning( ...
        'neuroelf:TDLocalError', ...
        'Error using tdlocal2: %s.', ...
        ne_eo.message ...
    );
end

% unload colin
if numel(colin) == 1 && ...
    isxff(colin, true)
    try
        colin.ClearObject;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end

% try to add path
try
    addpath(neuroelf_path);
    savepath;
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end

% stop splash
if isfield(ne_ui, 'splash') && ...
    isstruct(ne_ui.splash) && ...
    isfield(ne_ui.splash, 'timer')
    try
        for xc = 1:50
            pause(0.08);
            drawnow;
        end
        stop(ne_ui.splash.timer);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end

% clean up...
instprog(hPrg, hBar, 'Done.', 1, 'Cleaning up...');
pause(0.2);
if ~isempty(hPrg)
    disp(gluetostring(hPrg.String, char(10)));
end
try
    xfigure(xfigure, 'DeleteAllFigures');
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end

% switch back
try
    cd(opwd);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end

% rehash everything
evalin('base', 'rehash toolboxcache;', '');
evalin('base', 'rehash;', '');
evalin('base', 'clear xff;', '');


% sub function for progress
function instprog(hedt, hbar, txt, p, ptxt)
if ~isempty(hedt)
    if ~isempty(txt)
        str = hedt.String;
        if ischar(str) && ...
            size(str, 1) > 1
            str = cellstr(str);
        elseif ischar(str)
            str = splittocell(str, char(10));
        end
        str = [str(:); lsqueeze(splittocell(txt, char(10)))];
        hedt.String = str;
        hedt.ListboxTop = max(1, numel(str) - 15);
    end
    if nargin > 4
        hbar.Progress(p, ptxt);
    elseif nargin > 3
        hbar.Progress(p);
    end
    drawnow;
else
    disp(txt);
    pause(0.001);
end
