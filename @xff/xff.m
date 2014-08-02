function [varargout] = xff(varargin)
% xff (Object Class)
%
% This class allows users to read and write diverse fileformats, as
% well as altering their contents in memory through a struct-like
% access.
%
% vmr = xff('new:vmr');   % create a BrainVoyager QX compatible VMR
% vmr = xff('colin.vmr'); % load 'colin.vmr' VMR object from disk
% vmr = xff('*.vmr' [, titleornumber]);  % show file selector
%
% To force a file format (e.g. for generic extensions without the
% required magic tokens in the file), the format can be passed as the
% second argument, e.g.:
%
% tdata = xff(datafile, 'ntt');
%
% The storage is made in one global variable, xffcont, to keep only
% one copy of elements (full call-by-reference implementation), as of
% version v0.7b.
%
% To clear the storage, it is thus required to call one of the clearing
% methods:
%
% object.ClearObject;
% clearxffobjects({object, ...});
%
% Properties in the objects are then accessible like struct fields:
%
% dimx = vmr.DimX;
%
% Methods are equally accessible and, if available, overload properties.
% Some methods work for all (several) object / file types:
%
% bbox = vmr.BoundingBox;
% unused.ClearObject;
% copied = vmr.CopyObject;
% filename = vmr.FilenameOnDisk;
% filetype = vmr.Filetype;
% firstvolume = vtc.GetVolume(1);
% vmr.ReloadFromDisk;
% vmr.Save;
% vmr.SaveAs(newfilename);
% vmr.SaveAs('*.vmr' [, title]);
%
% Alternatively, you can use the functional form:
%
% Call(vmr, 'MethodName' [, arguments]);
%
% To obtain help on object methods issue the call
%
% object.Help    - or -
% object.Help('Method')
%
% Additionally, certain commands / functions can be executed via
%
% xff(0, command [, arguments]);
%
% where the following commands are supported
%
% xff(0, 'clearallobjects')
%     clear the object storage (like clear in Matlab for objects WS)
%
% xff(0, 'clearobj', h)
%     clear the objects with internal handle(s) h
%
% xff(0, 'config', globalsettingname [, globalsettingvalue]]);
% xff(0, 'config' [, type [, settingname [, settingvalue]]]);
%     e.g.
% xff(0, 'config', 'vmr', 'autov16', false|true);
%     make global class configuration (on types)
%
% xff(0, 'copyobject', h)
%     make a copy of object with internal handle h
%
% xff(0, 'extensions')
%     return supported extensions (struct with cell array fields)
%
% xff(0, 'formats')
%     return file formats (struct with fields bff, tff, extensions, magic)
%
% xff(0, 'isobject', var)
%     implementation of xffisobject function
%
% xff(0, 'magic')
%     return just the file magic array (1xN struct)
%
% xff(0, 'makeobject', obj_struct)
%     return the classified object (struct -> class constructor)
%
% xff(0, 'methods')
%     return a struct with 1x1 struct field for each file type and
%     sub fields for each method supported by this type
%
% xff(0, 'newcont', type)
%     return the resulting struct of NewFileCode of Xff files
%
% xff(0, 'object', h)
%     return the occording object with handle h (implements a check)
%
% xff(0, 'transiosize');
%     retrieve current transio size setting for all BFF (struct)
% xff(0, 'transiosize', tiostruct);
%     sets transiosize (see last transiosize command below)
% xff(0, 'transiosize', 'vtc');
%     retrieve current transio size setting for one BFF (see next command)
% xff(0, 'transiosize', 'vtc', 1048576 [, boolean:updatecache]);
%     this sets the minimum number of bytes before , instead of loading
%     the data in a property field, creating a @transio object
%
% xff(0, 'unwindstack');
%     perform garbage collection (remove objects with unmatching dbstack)
%
% xff(0, 'updatecache');
%     updates the cache.mat file (with current transiosize settings)
%
% xff(0, 'updatedisable' [, type]);
% xff(0, 'updateenable' [, type]);
% xff(0, 'updatestate' [, type [, truefalse]]);
% xff(0, 'updatestate' [, truefalsestruct]]);
%     disable/enable automatic object updating (on type field)
%     for "undatestate" call can work on a 1x1 struct with type fields
%
% Note: the default constructor (xff without arguments) produces
%       the so-called ROOT xff object with content fields
%       Extensions, Formats, Magic, Methods
%       containing the supported features of the class

% Version:  v0.9d
% Build:    14072415
% Date:     Jul-24 2014, 3:25 PM EST
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

% declare global and persistent variables
global xffclup xffconf xffcont;
persistent xffsngl;

% check for Class initialization -> do it if necessary
if isempty(xffsngl) || ...
   ~isstruct(xffsngl) || ...
   ~xffsngl.is_initialized || ...
    isempty(xffcont)

    % initialize global storage
    %
    % the storage of all objects is handled in a global variable,
    % xffcont, as of version 0.7a40
    %
    % this variable is a struct with fields
    %  .C   - object's content
    %  .F   - associated filename
    %  .H   - handles of other objects, etc.
    %  .L   - lookup value (referential integrity check)
    %  .S   - fileformat specification
    %  .U   - unwind stack information
    %
    % references will be looked up by object's internal L field
    % vs. the content of global variable xffclup
    xffcont = emptystruct({'C', 'F', 'H', 'L', 'S', 'U'}, [1, 1]);

    % configuration override on cache creation
    ovrcfg = struct;

    % hdr.assumeflipped is used when the HDR is read to determine the
    % convention state if the file itself does not contain this
    ovrcfg.hdr = struct;
    ovrcfg.hdr.assumeflipped = true;

    % vmr.autov16 decides whether V16 files are automatically loaded/saved
    ovrcfg.vmr = struct;
    ovrcfg.vmr.autov16 = true;

    % initialize persistent struct
    xffsngl = struct;
    xffsngl.is_initialized = false;
    xffsngl.mlversion = version;
    xffsngl.mmversion = mainver;
    xffsngl.version = 'v0.9d;14061710;20140617101107';

    % try to use cached info
    xffsngl.use_info_cache = true;

    % on initialization, also init global struct
    xffconf = struct;

    % set last object
    xffconf.last = [0, -1];

    % loaded objects of private functions
    xffconf.loadedobjs = struct;

    % open sliceable files in (a valid) GUI
    xffconf.loadingui = false;

    % load gzip-ed files
    xffconf.loadgziped = true;

    % reloadsame controls whether the same file (name) should be
    % opened again on xff(filename) calls or a handle to the
    % already open object should be returned instead
    xffconf.reloadsame = true;

    % settings are loaded from $config/xff.ini and control
    % some of the functions (please check the contents of this file
    % every now and then)
    try
        bsi = xini([neuroelf_path('config') '/xff.ini'], 'convert');
        xffconf.settings = bsi.GetComplete;
        bsi.Release;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        xffconf.settings = [];
    end

    % override empty or non-existing GZip.TempDir
    if isempty(xffconf.settings.GZip.TempDir) || ...
        exist(xffconf.settings.GZip.TempDir, 'dir') ~= 7
        xffconf.settings.GZip.TempDir = tempdir;
    end

    % type later contains one field (1x1 struct) per filetype
    xffconf.type = struct;

    % unwindstack controls the "pseudo scope" of objects
    % if set to true, xff will remove objects from the global
    % storage, once the function that created the object has
    % been completely run
    xffconf.unwindstack = true;

    % update later contains one field (1x1 logical) per filetype
    % if this field is set to true and a method with filename
    % OBJ_Update(obj, F, S, V) exists, the method is called after
    % calls to subsasgn(obj, S, V)
    xffconf.update = struct;

    % try cache
    usecache = xffsngl.use_info_cache;
    if usecache
        cachefile = [neuroelf_path('cache') '/cache.mat'];
        if exist(cachefile, 'file') == 2
            try
                cachemat = load(cachefile);
                cache = cachemat.cache;
                if isfield(cache, 'file_formats') && ...
                    isfield(cache, 'ff_methods') && ...
                    isfield(cache, 'xffconfig') && ...
                    isfield(cache, 'version') && ...
                    strcmp(cache.version, xffsngl.version)
                    xffsngl.file_formats = cache.file_formats;
                    xffsngl.ff_methods = cache.ff_methods;
                    xffconf.loadgziped = cache.xffconfig.loadgziped;
                    xffconf.reloadsame = cache.xffconfig.reloadsame;
                    xffconf.type = cache.xffconfig.type;
                    xffconf.update = cache.xffconfig.update;
                else
                    usecache = false;
                end
                xffsngl.cachefile = cachefile;
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                usecache = false;
            end
        else
            usecache = false;
        end
    end

    % otherwise (or failed)
    if ~usecache

        % get file formats
        xffsngl.file_formats = ...
            xffformats(neuroelf_path('formats'));

        % override configs
        orf = fieldnames(ovrcfg);
        for orfc = 1:numel(orf)
            orc = ovrcfg.(orf{orfc});
            orcf = fieldnames(orc);
            for orcfc = 1:numel(orcf)
                xffconf.type.(orf{orfc}).(orcf{orcfc}) = ...
                    orc.(orcf{orcfc});
            end
        end

        % get file format specific methods
        xffsngl.ff_methods = ...
            xffmethods(xffsngl.file_formats.extensions);

        % save ?
        if xffsngl.use_info_cache
            cache = struct;
            cache.version = xffsngl.version;
            cache.file_formats = xffsngl.file_formats;
            cache.ff_methods = xffsngl.ff_methods;
            cache.xffconfig.loadgziped = xffconf.loadgziped;
            cache.xffconfig.reloadsame = xffconf.reloadsame;
            cache.xffconfig.type = xffconf.type;
            cache.xffconfig.update = xffconf.update;
            if xffsngl.mmversion < 5
                save('-v6', cachefile, 'cache');
            elseif xffsngl.mmversion < 7
                save(cachefile, 'cache');
            else
                save(cachefile, 'cache', '-v6');
            end
        end
    end

    % get extension and magic list
    xffsngl.bff = xffsngl.file_formats.bff;
    xffsngl.tff = xffsngl.file_formats.tff;
    xffsngl.ext = xffsngl.file_formats.extensions;
    xffsngl.mag = xffsngl.file_formats.magic;

    % say we are initialized
    xffsngl.is_initialized = true;

    % fill main object
    xffclup = -1;
    xffcont(1) = struct( ...
        'C', struct( ...
            'Extensions', xff(0, 'extensions'), ...
            'Formats',    xff(0, 'formats'), ...
            'Magic',      xff(0, 'magic'), ...
            'Methods',    xff(0, 'methods')), ...
    	'F', '<ROOT>', ...
        'H', struct('xff', 0, 'CleanUp', {{}}, 'ShownInGUI', false, 'SourceObject', -1), ...
        'L', -1, ...
    	'S', struct( ...
            'DefaultProperty', {{'Document'}}, ...
            'Extensions',      {{'ROOT'}}, ...
            'FFTYPE',          'ROOT'), ...
        'U', {{ }} );
    xffcont(1).U(:) = [];

    % override transio from settings
    tiotypes = xffconf.settings.Behavior.TransIOTypes;
    for orfc = 1:numel(tiotypes)
        xff(0, 'transiosize', tiotypes{orfc}, 4096);
    end
end

% single char argument or char + double
if ...
    nargin > 0 && ...
    nargin < 3 && ...
    ischar(varargin{1}) && ...
   ~isempty(varargin{1}) && ...
    numel(varargin{1}) < 256 && ...
   (nargin < 2 || ...
    (isa(varargin{2}, 'double') && ...
     numel(varargin{2}) == 1) || ...
    (ischar(varargin{2}) && ...
     ~isempty(varargin{2})))

    % linearize filename
    filename = varargin{1}(:)';

    % unique ID
    if numel(filename) == 24 && ...
        nargin == 1 && ...
       ~isempty(regexpi(filename, '^[0-9a-f]+$')) && ...
        numel(xffcont) > 1

        % try to locate ID
        xids = cell(numel(xffcont), 1);
        xids{1} = 'ROOTROOTROOTROOTROOTROOT';
        for oc = 2:numel(xids)
            try
                xids{oc} = xffcont(oc).C.RunTimeVars.xffID;
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                xids{oc} = 'NOTFOUNDNOTFOUNDNOTFOUND';
            end
        end
        xids(~cellfun(@ischar, xids)) = {'INVALID!INVALID!INVALID!'};
        xidi = findfirst(strcmpi(xids, filename));

        % found?
        if ~isempty(xidi)

            % return object
            varargout{1} = xff(0, 'makeobject', struct('L', xffcont(xidi).L));
            varargout{2} = false;
            return;
        end
    end

    % get filename components
    [fnparts{1:3}] = fileparts(filename);

    % support gzip-ed data
    isgziped = '';
    if xffconf.loadgziped && ...
        strcmpi(fnparts{3}, '.gz') && ...
        ~any(fnparts{2} == '*' | fnparts{2} == ':')
        isgziped = fnparts{3};
        filename(end-2:end) = [];
        [fnparts{1:3}] = fileparts(filename);
    end

    % available file extensions
    ext = xffsngl.ext;
    exn = fieldnames(ext);

    % check for "*.???"
    if ~isempty(fnparts{2}) && ...
        any(fnparts{2} == '*')

        % force use of extension for ?ff function
        extf = fnparts{3}(fnparts{3} ~= '.');

        % allow special case for img
        if any(strcmpi(extf, {'hdr', 'img', 'nii'})) && ...
           ~isempty(fnparts{1}) && ...
            numel(fnparts{2}) > 1

            % try to find images
            try
                [imgfp, imgfn, imgfe] = fileparts(filename);
                if isempty(imgfp)
                    error( ...
                        'xff:BadArgument', ...
                        'Multi HDR/IMG lookup requires full path.' ...
                    );
                end
                imgfs = findfiles(imgfp, [imgfn, imgfe], 'depth=1');
                if ~isempty(imgfs)
                    varargout{1} = xff(imgfs);
                    if iscell(varargout{1}) && ...
                        numel(varargout{1}) == 1
                        varargout{1} = varargout{1}{1};
                    end
                    varargout{2} = true(numel(varargout{1}), 1);
                    return;
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
         end

        % how many files
        if nargin < 2 || ...
           ~isa(varargin{2}, 'double') || ...
            isnan(varargin{2}) || ...
            varargin{2} < 1
            numreq = 1;
        else
            numreq = floor(varargin{2});
        end
        if nargin > 1 && ...
            ischar(varargin{2})
            dtitle = varargin(2);
        else
            dtitle = cell(0, 1);
        end

        filename = xffrequestfile(numreq, filename, ext, ...
            xffsngl.file_formats, dtitle{:});

        % any filename(s) returned
        if isempty(filename)
            varargout(1:nargout) = cell(1, nargout);
            return;
        elseif ischar(filename)
            filename = {filename};
        end
        nfiles = numel(filename);

        % create output object
        oo = xff(0, 'makeobject', struct('L', -1));
        ol = true(1, nfiles);
        if nfiles > 1
            oo(2:nfiles) = oo(1);
        end

        % try loading objects
        for oc = 1:nfiles
            try
                if xffconf.reloadsame
                    oo(oc) = xff(filename{oc}, extf);
                else
                    if ispc
                        namelup = findfirst(strcmpi(filename{oc}, {xffcont(:).F}));
                    else
                        namelup = findfirst(strcmp(filename{oc}, {xffcont(:).F}));
                    end
                    if ~isempty(namelup)
                        oo(oc) = xff(0, 'makeobject', ...
                            struct('L', xffclup(namelup)));
                        ol(oc) = false;
                    else
                        oo(oc) = xff(filename{oc}, extf);
                    end
                end
            catch ne_eo;
                error( ...
                    'xff:FileReadError', ...
                    'Error reading file ''%s'': %s.', ...
                    filename{oc}, ne_eo.message ...
                );
            end
        end

        % return objects
        varargout{1} = oo;
        varargout{2} = ol;
        return;

    % patch extension only with "new:???"
    elseif numel(filename) < 5 && ...
       (exist(filename, 'file') ~= 2 || ...
        exist([filename '.m'], 'file') == 2)
        filename = ['new:' filename];
    end

    % checking for 'new:???'
    if numel(filename) > 5 && ...
        strcmpi(filename(1:4), 'new:') && ...
       ~any(filename == '\' | filename == '/' | filename == '.') && ...
        isfield(ext, lower(filename(5:end)))

        % get spec
        fftype = lower(filename(5:end));
        ffspec = ext.(fftype);
        xfft = ffspec{1}(end-2:end);
        spec = xffsngl.file_formats.(xfft)(ffspec{2});

        % no "new" code is available
        if isempty(spec.NewFileCode)
            error( ...
                'xff:IncompleteSpec', ...
                'For %s type files, no NewFileCode is available.', ...
                fftype ...
            );
        end;

        % make new object's lookup value
        nlup = rand(1, 1);
        while any(xffclup == nlup)
            nlup = rand(1, 1);
        end

        % get new object's content
        try
            bc = xff(0, 'newcont', fftype);
            if xffconf.unwindstack
                mst = mystack;
            else
                mst = {};
            end

            % add field for per-object transformation where useful
            if ~isfield(bc, 'RunTimeVars') || ...
               ~isstruct(bc.RunTimeVars)
                bc.RunTimeVars = struct;
            end
            if ~isfield(bc.RunTimeVars, 'xffID') || ...
               ~ischar(bc.RunTimeVars.xffID) || ...
                numel(bc.RunTimeVars.xffID) ~= 24
                xffid = tempname;
                xffid = strrep(xffid, '_', '');
                xffid = xffid(max(1, numel(xffid) - 23):end);
                if numel(xffid) == 24
                    bc.RunTimeVars.xffID = xffid;
                else
                    xffid = hxdouble(randn(1, 2));
                    bc.RunTimeVars.xffID = xffid([4:15, 20:31]);
                end
            end
            if any(strcmp(fftype, ...
                   {'ava', 'cmp', 'dmr', 'fmr', 'glm', 'hdr', 'head', ...
                    'nlf', 'srf', 'vmp', 'vmr', 'vtc'})) && ...
               ~isfield(bc.RunTimeVars, 'TrfPlus')
                bc.RunTimeVars.TrfPlus = eye(4);
            end

            % add to global storage
            xffcont(end + 1) = struct( ...
                'C', bc, ...
                'F', '', ...
                'H', struct('xff', nlup, 'CleanUp', {{}}, 'ShownInGUI', false, 'SourceObject', -1), ...
                'L', nlup, ...
                'S', spec, ...
                'U', {mst});
            xffclup(end + 1) = nlup;
        catch ne_eo;
            error( ...
                'xff:EvaluationError', ...
                'Couldn''t evaluate NewFileCode snippet for type %s: %s.', ...
                fftype, ne_eo.message ...
            );
        end

        % build object
        varargout{1} = xff(0, 'makeobject', struct('L', nlup));
        varargout{2} = true;
        return;
    end

    % make absolute!
    [isabs{1:2}] = isabsolute(filename);
    filename = isabs{2};

    % get file name parts
    [fx{1:3}] = fileparts(filename);
    fx = regexprep(fx{3}, ',\d+$', '');
    if ~isempty(fx) && ...
        fx(1) == '.'
        fx(1) = [];
    end

    % what other extension to use
    if ~any(strcmpi(fx, exn)) && ...
        nargin > 1 && ...
        ischar(varargin{2}) && ...
        numel(varargin{2}) <= 5 && ...
        any(strcmpi(varargin{2}(:)', exn))
        fx = lower(varargin{2}(:)');
    end

    % any extension based match
    exf = strcmpi(fx, exn);
    if any(exf)

        % get match and matching extension field name
        exf = find(exf);
        exn = exn{exf(1)};

        % look up in extensions
        if isfield(ext, exn)
            ffspec = ext.(exn);
            xfft = ffspec{1}(end-2:end);
            ff = xffsngl.file_formats.(xfft)(ffspec{2});

        % or error !
        else
            error( ...
                'xff:BadExtension', ...
                'Extension given, but not in BFF/TFF list: %s.', ...
                exn ...
            );
        end

        % match found
        exf = true;
    else

        % no match found
        exf = false;
    end

    % not yet identified, try magic
    if ~exf

        % not supported with gzipped files
        if ~isempty(isgziped)
            error( ...
                'xff:NoMagicWithGzip', ...
                'Magic token detection not supported with gziped files.' ...
            );
        end
        maf = false;
        try
            detmag = xffdetectmagic(filename, xffsngl.mag);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            detmag = '';
        end
        if ~isempty(detmag)

            % either bff
            if isfield(ext, detmag)
                ffspec = ext.(detmag);
                xfft = ffspec{1}(end-2:end);
                ff = xffsngl.file_formats.(xfft)(ffspec{2});

            % or error !
            else
                error( ...
                    'xff:BadExtension', ...
                    'Magic found, but type not in BFF/TFF list: %s.', ...
                    detmag ...
                );
            end
            maf = true;
        end
    end

    if ~exf && ~maf
        error( ...
            'xff:BadFileContent', ...
            'Unknown file type. Cannot read ''%s''.', ...
            filename ...
        );
    end
    fft = lower(ff.Extensions{1});

    % reload same ?
    if nargin < 2 || ...
        ischar(varargin{2})
        rls = xffconf.reloadsame;
    else
        rls = (varargin{2} ~= 0);
    end
    if ~rls
        if ispc
            namelup = findfirst(strcmpi(filename, {xffcont(:).F}));
        else
            namelup = findfirst(strcmp(filename, {xffcont(:).F}));
        end
        if ~isempty(namelup)
            varargout{1} = xff(0, 'makeobject', ...
                struct('L', xffclup(namelup)));
            varargout{2} = false;
            return;
        end
    end

    % header only
    fullf = true;
    if nargin > 1 && ...
        ischar(varargin{2}) && ...
        numel(varargin{2}) == 1
        if varargin{2} == 'h'
            fullf = false;
            fullfa = '-fh';
        elseif varargin{2} == 't' && ...
            strcmpi(ff.FFTYPE, 'bff')
            ff.TransIOSize = 1024;
        elseif varargin{2} == 'T' && ...
            strcmpi(ff.FFTYPE, 'bff')
            ff.TransIOSize = 1;
        elseif varargin{2} == 'v'
            fullf = false;
            fullfa = '-v';
        elseif varargin{2} == 'c'
            fullf = false;
            fullfa = '';
        end
    end

    % uncompress if needed
    if ~isempty(isgziped)
        ofname = filename;
        try
            tdir = xffconf.settings.GZip.TempDir;
            gunzip([filename isgziped], tdir);
            filename = [tempname(tdir) fnparts{3}];
            if movefile([tdir '/' fnparts{2} fnparts{3}], filename) ~= 1
                error( ...
                    'xff:MoveFileError', ...
                    'Error renaming xff temporary file.' ...
                );
            end
        catch ne_eo;
            rethrow(ne_eo);
        end
    end

    % read file
    try
        switch lower(ff.FFTYPE)

            % for binary files
            case {'bff'}

                % allow sub-volumes
                subvolm = regexpi(filename, ',\s*\d+\s*$');
                if ~isempty(subvolm)
                    if ~any(strcmp(fft, {'hdr', 'head'}))
                        error( ...
                            'xff:BadArgument', ...
                            'Sub-volume selection only for HDR/NII/HEAD files.' ...
                        );
                    end
                    subvol = str2double(filename(subvolm+1:end));
                    filename = deblank(filename(1:subvolm-1));
                else
                    subvol = [];
                end

                % full
                if fullf
                    ffcont = bffio(filename, ff);

                % or header
                else
                    varargout{1} = bffio(filename, ff, fullfa);
                    varargout{2} = true;
                    return;
                end

                % sub-volume access
                if ~isempty(subvol)
                    try
                        switch (lower(ff.Extensions{1}))
                            case {'hdr'}
                                if isfield(ffcont.RunTimeVars, 'Mat44') && ...
                                    size(ffcont.RunTimeVars.Mat44, 3) == size(ffcont.VoxelData, 4)
                                    ffcont.RunTimeVars.Mat44 = ffcont.RunTimeVars.Mat44(:, :, subvol);
                                end
                                ffcont.ImgDim.Dim(5) = 1;
                                ffcont.VoxelData = ffcont.VoxelData(:, :, :, subvol);
                            case {'head'}
                                ffcont.NrOfVolumes = 1;
                                ffcont.Brick = ffcont.Brick(subvol);
                        end
                    catch ne_eo;
                        error( ...
                            'xff:BadArgument', ...
                            'Couldn''t access subvolume %d in file %s: %s.', ...
                            subvol, filename, ne_eo.message ...
                        );
                    end
                    filename = sprintf('%s,%d', filename, subvol);
                end

            % for text-based files
            case {'tff'}

                % full file
                if fullf
                    ffcont = tffio(filename, ff);

                % or header
                else
                    varargout{1} = bffio(filename, ff, fullfa);
                    varargout{2} = true;
                    return;
                end
            otherwise
                error( ...
                    'xff:BadFFTYPE', ...
                    'FF type %s not supported yet.', ...
                    ff.FFTYPE ...
                );
        end

        % try to also read RunTimeVars
        if isempty(isgziped)
            [filenp, filenn, filene] = fileparts(filename);
        else
            [filenp, filenn, filene] = fileparts(ofname);
        end
        try
            filenm = fopen([filenp '/' filenn '.rtv']);
            if filenm > 0
                fclose(filenm);
                if mainver > 5
                    filenr = load([filenp '/' filenn '.rtv'], '-mat');
                else
                    filenr = load('-mat', [filenp '/' filenn '.rtv']);
                end
                if isfield(filenr, 'RunTimeVars') && ...
                    isstruct(filenr.RunTimeVars) && ...
                    numel(filenr.RunTimeVars) == 1 && ...
                    isfield(filenr.RunTimeVars, filene(2:end))
                    ffcont.RunTimeVars = filenr.RunTimeVars.(filene(2:end));
                    rtvf = fieldnames(ffcont.RunTimeVars);
                    for rtvfc = 1:numel(rtvf)
                        if isfield(ffcont, rtvf{rtvfc}) && ...
                            isstruct(ffcont.RunTimeVars.(rtvf{rtvfc})) && ...
                            isstruct(ffcont.(rtvf{rtvfc})) && ...
                            numel(ffcont.RunTimeVars.(rtvf{rtvfc})) == numel(ffcont.(rtvf{rtvfc}))
                            for rtvfcc = 1:numel(ffcont.(rtvf{rtvfc}))
                                ffcont.(rtvf{rtvfc})(rtvfcc).RunTimeVars = ...
                                    ffcont.RunTimeVars.(rtvf{rtvfc})(rtvfcc);
                            end
                            ffcont.RunTimeVars = rmfield(ffcont.RunTimeVars, rtvf{rtvfc});
                        end
                    end
                end
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

        % add field for per-object transformation where useful
        if ~isfield(ffcont, 'RunTimeVars') || ...
           ~isstruct(ffcont.RunTimeVars)
            ffcont.RunTimeVars = struct;
        end
        if ~isfield(ffcont.RunTimeVars, 'xffID') || ...
           ~ischar(ffcont.RunTimeVars.xffID) || ...
            numel(ffcont.RunTimeVars.xffID) ~= 24
            xffid = tempname;
            xffid = strrep(xffid, '_', '');
            xffid = xffid(max(1, numel(xffid) - 23):end);
            if numel(xffid) == 24
                ffcont.RunTimeVars.xffID = xffid;
            else
                xffid = hxdouble(randn(1, 2));
                ffcont.RunTimeVars.xffID = xffid([4:15, 20:31]);
            end
        end
        if any(strcmp(fft, ...
               {'ava', 'cmp', 'dmr', 'fmr', 'glm', 'hdr', 'head', ...
                'nlf', 'srf', 'vmp', 'vmr', 'vtc'})) && ...
           ~isfield(ffcont.RunTimeVars, 'TrfPlus')
            ffcont.RunTimeVars.TrfPlus = eye(4);
        end

        % complete object specs
        if ispc
            filename = strrep(filename, '\', '/');
        end
        nlup = rand(1, 1);
        while any(xffclup == nlup)
            nlup = rand(1, 1);
        end
        if xffconf.unwindstack
            mst = mystack;
        else
            mst = {};
        end
        xffcont(end + 1) = struct( ...
            'C', ffcont, ...
            'F', filename, ...
            'H', struct('xff', nlup, 'CleanUp', {{}}, 'ShownInGUI', false, 'SourceObject', -1), ...
            'L', nlup, ...
            'S', ff, ...
            'U', {mst});
        xffclup(end + 1) = nlup;
        varargout{1} = xff(0, 'makeobject', struct('L', nlup));
        varargout{2} = true;

        % came from gziped file
        if ~isempty(isgziped)
            xffcont(end).H.GZIPext = isgziped;
            xffcont(end).H.GZIPfile = ofname;
        end

        % bring up in GUI
        if xffconf.loadingui && ...
            any(strcmpi(ff.Extensions{1}, {'dmr', 'fmr', 'glm', 'vmp', 'vmr'})) && ...
            numel(findobj('Tag', 'NeuroElf_MainFig')) == 1
            aft_Browse(bless(varargout{1}));
        end
        return;
    catch ne_eo;
        error( ...
            'xff:XFFioFailed', ...
            'Error calling *ffio(...): ''%s''.', ...
            ne_eo.message ...
        );
    end

% elseif ... other input argument combinations
elseif ...
    nargin == 2 && ...
    ischar(varargin{1}) && ...
   ~isempty(varargin{1}) && ...
    numel(varargin{2}) == 1 && ...
    xffisobject(varargin{2}, true)

    % try writing file
    try
        olup = (xffclup == varargin{2}.L);
        ostr = xffcont(olup);

        % don't allow volume marker
        if ~isempty(regexpi(varargin{1}(:)', ',\s*\d+\s*$'))
            error( ...
                'xff:BadArgument', ...
                'Saving of sub-volumes not permitted.' ...
            );
        end

        switch lower(ostr.S.FFTYPE)
            case {'bff'}
                xffcont(olup).C = bffio(varargin{1}, ostr.S, ostr.C);
            case {'tff'}
                [xffcont(olup).C, xffcont(olup).F] = ...
                    tffio(varargin{1}, ostr.S, ostr.C);
            otherwise
                error( ...
                    'xff:BadFFTYPE', ...
                    'FF type %s not supported yet.', ...
                    ostr.S.FFTYPE ...
                );
        end
    catch ne_eo;
        error( ...
            'xff:xFFioFailed', ...
            'Error calling ?ffio(...): ''%s''.', ...
            ne_eo.message ...
        );
    end

% special cases for internal call
elseif nargin > 1 && ...
    isa(varargin{1}, 'double') && ...
    numel(varargin{1}) == 1 && ...
    varargin{1} == 0 && ...
    ischar(varargin{2})

    % what special case
    switch (lower(varargin{2}(:)'))

        % unwind stack
        case {'unwindstack'}

            % allow to change setting
            if nargin > 2 && ...
                islogical(varargin{3}) && ...
                numel(varargin{3}) == 1
                xffconf.unwindstack = varargin{3};
            end

            % doesn't work if not enabled
            if ~xffconf.unwindstack
                varargout{1} = false;
                return;
            end

            % get current stack
            cst = mystack;

            % iterate over all objects
            uobjs = false(1, numel(xffcont));
            ost = {xffcont(:).U};
            for uc = 2:numel(uobjs)

                % continue if stack is empty
                if isempty(ost{uc})
                    continue;
                end

                % compare last entries
                if numel(cst) < numel(ost{uc}) || ...
                    any(~strcmp(ost{uc}, cst(end+1-numel(ost{uc}):end)))
                    uobjs(uc) = true;
                end
            end

            % clear objects
            if any(uobjs)
                xffclear(xffclup(uobjs), false);
            end

            % return flag
            varargout{1} = xffconf.unwindstack;

        % check object validity
        case {'isobject'}

            % class check first
            if ~isa(varargin{3}, 'xff')
                varargout{1} = false;
            else
                varargout{1} = xffisobject(varargin{3:end});
            end

        % create object from struct
        case {'makeobject'}

            % check integrity
            if nargin > 2 && ...
                isstruct(varargin{3}) && ...
                numel(fieldnames(varargin{3})) == 1 && ...
                all(strcmp(fieldnames(varargin{3}), {'L'}))

                % create object
                try
                    varargout{1} = class(varargin{3}, 'xff');
                catch ne_eo;
                    error( ...
                        'xff:BadStructForClass', ...
                        'Bad struct given, cannot create object: %s.', ...
                        ne_eo.message ...
                    );
                end

            % allow different call for any2ascii
            elseif nargin > 2 && ...
                isstruct(varargin{3}) && ...
                numel(varargin{3}) == 1 && ...
                numel(fieldnames(varargin{3})) == 1
                mobjtype = fieldnames(varargin{3});
                mobjtype = mobjtype{1};
                if ~isfield(xffsngl.ext, lower(mobjtype)) || ...
                   ~isstruct(varargin{3}.(mobjtype)) || ...
                    numel(varargin{3}.(mobjtype)) ~= 1
                    error( ...
                        'xff:BadStructForClass', ...
                        'Bad object type or struct given, cannot create object.' ...
                    );
                end
                oldcont = varargin{3}.(mobjtype);
                newcont = xff(0, 'newcont', lower(mobjtype));
                if numel(fieldnames(newcont)) ~= numel(fieldnames(oldcont)) || ...
                    ~all(strcmp(fieldnames(newcont), fieldnames(oldcont)))
                    error( ...
                        'xff:BadStructForClass', ...
                        'Bad object type or struct given, cannot create object.' ...
                    );
                end

                % create new object
                nlup = rand(1, 1);
                while any(xffclup == nlup)
                    nlup = rand(1, 1);
                end
                if xffconf.unwindstack
                    mst = mystack;
                else
                    mst = {};
                end
                spec = xffsngl.file_formats.( ...
                    xffsngl.ext.(lower(mobjtype)){1}(end-2:end))(...
                    xffsngl.ext.(lower(mobjtype)){2});

                % add to global storage
                xffcont(end + 1) = struct( ...
                    'C', oldcont, ...
                    'F', '', ...
                    'H', struct('xff', nlup, 'CleanUp', {{}}, 'ShownInGUI', false, 'SourceObject', -1), ...
                    'L', nlup, ...
                    'S', spec, ...
                    'U', {mst});
                xffclup(end + 1) = nlup;
                varargout{1} = xff(0, 'makeobject', struct('L', nlup));
                varargout{2} = true;
            else
                error( ...
                    'xff:BadStructForClass', ...
                    'Bad struct given, cannot create object.' ...
                );
            end

        % evaluate NewFileCode
        case {'newcont'}
            if nargin < 3 || ...
               ~ischar(varargin{3}) || ...
                isempty(varargin{3}) || ...
               ~isfield(xffsngl.ext, lower(varargin{3}(:)'))
                error( ...
                    'xff:BadArgument', ...
                    'Unknown filetype.' ...
                );
            end
            fftype = lower(varargin{3});
            ffspec = xffsngl.ext.(fftype);
            xfft = ffspec{1}(end-2:end);
            spec = xffsngl.file_formats.(xfft)(ffspec{2});
            bffcont = struct;
            newcode = spec.NewFileCode;
            if lower(spec.FFTYPE(1)) == 't'
                newcode = strrep(newcode, 'tffcont', 'bffcont');
            end
            try
                eval(newcode);
                if ~isfield(bffcont, 'RunTimeVars') || ...
                   ~isstruct(bffcont.RunTimeVars) || ...
                    numel(bffcont.RunTimeVars) ~= 1
                    bffcont.RunTimeVars = struct;
                end
                if ~isfield(bffcont.RunTimeVars, 'xffID') || ...
                   ~ischar(bffcont.RunTimeVars.xffID) || ...
                    numel(bffcont.RunTimeVars.xffID) ~= 24
                    xffid = tempname;
                    xffid = strrep(xffid, '_', '');
                    xffid = xffid(max(1, numel(xffid) - 23):end);
                    if numel(xffid) == 24
                        bffcont.RunTimeVars.xffID = xffid;
                    else
                        xffid = hxdouble(randn(1, 2));
                        bffcont.RunTimeVars.xffID = xffid([4:15, 20:31]);
                    end
                end
                varargout{1} = bffcont;
                return;
            catch ne_eo;
                error( ...
                    'xff:EvaluationError', ...
                    'Couldn''t evaluate NewFileCode snippet for type %s: %s.', ...
                    fftype, ne_eo.message ...
                );
            end

        % remove one object from the array
        case {'clearobj'}
            if nargin > 2 && ...
                isa(varargin{3}, 'double') && ...
                all(varargin{3}(:) >= 0 & varargin{3}(:) <= 1)

                % remove
                xffclear(varargin{3}(:)');
            end

        % copy object
        case {'copyobject'}
            if nargin > 2 && ...
                isa(varargin{3}, 'double') && ...
                numel(varargin{3}) == 1 && ...
                ~isnan(varargin{3}) && ...
                varargin{3} < 1 && ...
                any(xffclup == varargin{3})
                olup = find(xffclup == varargin{3});
                nlup = rand(1, 1);
                while any(xffclup == nlup)
                    nlup = rand(1, 1);
                end
                xffclup(end + 1) = nlup;
                xffcont(end + 1) = xffcont(olup(1));
                xffcont(end).F = '';
                xffid = tempname;
                xffid = strrep(xffid, '_', '');
                xffid = xffid(max(1, numel(xffid) - 23):end);
                if numel(xffid) == 24
                    xffcont(end).C.RunTimeVars.xffID = xffid;
                else
                    xffid = hxdouble(randn(1, 2));
                    xffcont(end).C.RunTimeVars.xffID = xffid([4:15, 20:31]);
                end
                if xffisobject(xffcont(end).H.SourceObject, true)
                    sobj = xffcont(end).H.SourceObject;
                else
                    sobj = xff(0, 'makeobject', struct('L', varargin{3}));
                end
                xffcont(end).H = struct( ...
                    'xff', nlup, 'CleanUp', {{}}, 'ShownInGUI', false, ...
                    'SourceObject', sobj);
                xffcont(end).L = nlup;
                if xffconf.unwindstack
                    xffcont(end).U = mystack;
                end
                varargout{1} = xff(0, 'makeobject', struct('L', nlup));
                varargout{2} = true;
            else
                error( ...
                    'xff:BadArgument', ...
                    'Bad argument or invalid object lookup.' ...
                );
            end

        % class (types) configuration
        case {'config'}
            if nargin < 3 || ...
               ~ischar(varargin{3}) || ...
              (~isfield(xffconf.type, varargin{3}(:)') && ...
               ~isfield(xffconf, varargin{3}(:)'))
                error( ...
                    'xff:BadArgument', ...
                    'Bad or missing argument in config call.' ...
                );
            end

            % global configuration
            if isfield(xffconf, varargin{3}(:)')

                % set
                if nargin > 3
                    xffconf.(varargin{3}(:)') = varargin{4};
                else
                    varargout{1} = xffconf.(varargin{3}(:)');
                end

            % type configuration
            else

                % get current config
                curcfg = xffconf.type.(varargin{3}(:)');

                % sub indexing
                if nargin > 3 && ...
                    ischar(varargin{4}) && ...
                   ~isempty(varargin{4}) && ...
                    isfield(curcfg, varargin{4}(:)')

                    % set
                    if nargin > 4
                        xffconf.type.(varargin{3}(:)').(varargin{4}(:)') = varargin{5};

                    % get
                    else
                        varargout{1} = curcfg.(varargin{4}(:)');
                    end

                % entire type config
                else
                    varargout{1} = curcfg;
                end
            end

        % transio size settings
        case {'transiosize'}

            % make per type setting
            if nargin > 3 && ...
                ischar(varargin{3}) && ...
                strcmp(makelabel(varargin{3}(:)'), varargin{3}(:)') && ...
                isfield(xffsngl.ext, varargin{3}(:)') && ...
               ~isempty(strfind(xffsngl.ext.(varargin{3}(:)'){1}, '.bff')) && ...
                isa(varargin{4}, 'double') && ...
                numel(varargin{4}) == 1 && ...
                ~isnan(varargin{4}) && ...
                varargin{4} > 4095

                % use a fixed size
                tsz = fix(varargin{4});
                fpos = xffsngl.ext.(varargin{3}(:)'){2};
                xffsngl.bff(fpos).TransIOSize = tsz;
                xffsngl.file_formats.bff(fpos).TransIOSize = tsz;

                % store cache
                if nargin > 4 && ...
                    isa(varargin{5}, 'logical') && ...
                    numel(varargin{5}) == 1 && ...
                    varargin{5}
                    xff(0, 'updatecache');
                end

            % get per type setting
            elseif nargin > 2 && ...
                ischar(varargin{3}) && ...
                strcmp(makelabel(varargin{3}(:)'), varargin{3}(:)') && ...
                isfield(xffsngl.ext, varargin{3}(:)') && ...
               ~isempty(strfind(xffsngl.ext.(varargin{3}(:)'){1}, '.bff'))
                fpos = xffsngl.ext.(varargin{3}(:)'){2};
                varargout{1} = xffsngl.bff(fpos).TransIOSize;

            % set entire list of types
            elseif nargin > 2 && ...
                isstruct(varargin{3}) && ...
                numel(varargin{3}) == 1 && ...
                numel(fieldnames(varargin{3})) == numel(xffsngl.bff)

                % get struct and check fieldnames against extensions
                tsz = varargin{3};
                tszf = fieldnames(tsz);
                for sc = 1:numel(xffsngl.bff)
                    if ~strcmp(tszf{sc}, xffsngl.bff(sc).Extensions{1}) || ...
                       ~isa(tsz.(tszf{sc}), 'double') || ...
                        numel(tsz.(tszf{sc})) ~= 1 || ...
                        isnan(tsz.(tszf{sc}))
                        error( ...
                            'xff:BadArgument', ...
                            'Invalid transiosize structure.' ...
                        );
                    end
                end

                % make setting
                for sc = 1:numel(xffsngl.bff)
                    xffsngl.bff(sc).TransIOSize = tsz.(tszf{sc});
                    xffsngl.file_formats.bff(sc).TransIOSize = tsz.(tszf{sc});
                end

                % store in cache
                if nargin > 3 && ...
                    isa(varargin{4}, 'logical') && ...
                    numel(varargin{4}) == 1 && ...
                    varargin{4}
                    xff(0, 'updatecache');
                end

            % set for all types
            elseif nargin > 2 && ...
                isa(varargin{3}, 'double') && ...
                numel(varargin{3}) == 1 && ...
                ~isnan(varargin{3}) && ...
                varargin{3} > 4095
                tsz = fix(varargin{3});

                % iterate over formats
                for sc = 1:numel(xffsngl.bff)
                    xffsngl.bff(sc).TransIOSize = tsz;
                    xffsngl.file_formats.bff(sc).TransIOSize = tsz;
                end

                % store in cache
                if nargin > 3 && ...
                    isa(varargin{4}, 'logical') && ...
                    numel(varargin{4}) == 1 && ...
                    varargin{4}
                    xff(0, 'updatecache');
                end

            % get entire list of types
            elseif nargin == 2
                tsz = struct;
                for sc = 1:numel(xffsngl.bff)
                    tsz.(xffsngl.bff(sc).Extensions{1}) = ...
                        xffsngl.bff(sc).TransIOSize;
                end
                varargout{1} = tsz;
            end

        % list of supported extensions / types
        case {'extensions'}
            varargout{1} = xffsngl.ext;

        % format specifications
        case {'formats'}
            varargout{1} = xffsngl.file_formats;

        % format specifications
        case {'help'}
            varargout{1} = root_Help(xff);

        % magic detection tokens
        case {'magic'}
            varargout{1} = xffsngl.mag;

        % list of methods per type
        case {'methods'}
            varargout{1} = xffsngl.ff_methods;

        % get object from lookup
        case {'object'}
            if nargin < 2 || ...
               ((~isa(varargin{3}, 'double') || ...
                  numel(varargin{3}) ~= 1 || ...
                 ~any(xffclup == varargin{3})) && ...
                (~ischar(varargin{3}) || ...
                 ~any(strcmpi(varargin{3}, {xffcont(2:end).F}))))
                error( ...
                    'xff:LookupError', ...
                    'Object with given tag does not exist.' ...
                );
            end
            objL = varargin{3};
            if ischar(objL)
                objL = xffclup(1 + findfirst( ...
                    strcmpi(varargin{3}, {xffcont(2:end).F})));
            end
            varargout{1} = xff(0, 'makeobject', struct('L', objL));
            varargout{2} = false;

        % list of objects (copy of global struct)
        case {'objects'}
            varargout{1} = xffcont;

        % clear storage completely
        case {'clearallobjects'}

            % simply remake internal arrays
            xffsngl(1) = [];
            xff;

        % update cache
        case {'updatecache'}

            % only works if cachefile set and enabled
            if isfield(xffsngl, 'cachefile') && ...
                xffsngl.use_info_cache

                % compile cache
                cache = struct;
                cache.version = xffsngl.version;
                cache.file_formats = xffsngl.file_formats;
                cache.ff_methods = xffsngl.ff_methods;
                cache.xffconfig.type = xffconf.type;
                cache.xffconfig.update = xffconf.update;

                % save according to version
                if xffsngl.mmversion < 7
                    save(xffsngl.cachefile, 'cache');
                else
                    save(xffsngl.cachefile, 'cache', '-v6');
                end
            end

        % disable obj_Update calls
        case {'updatedisable'}

            % for one type
            if nargin > 2 && ...
               ischar(varargin{3}) && ...
               isfield(xffconf.update, lower(varargin{3}(:)'))
                xffconf.update.(lower(varargin{3}(:)')) = false;

            % for all types
            elseif nargin == 2
                ftn = fieldnames(xffconf.update);
                for ftc = 1:numel(ftn)
                    xffconf.update.(ftn{ftc}) = false;
                end
            end

        % enable obj_Update calls
        case {'updateenable'}

            % for one type
            if nargin > 2 && ...
                ischar(varargin{3}) && ...
                isfield(xffconf.update, lower(varargin{3}(:)'))
                xffconf.update.(lower(varargin{3}(:)')) = true;

            % for all types
            elseif nargin == 2
                ftn = fieldnames(xffconf.update);
                for ftc = 1:numel(ftn)
                    xffconf.update.(ftn{ftc}) = true;
                end
            end

        % state of update flag
        case {'updatestate'}

            % for one type
            if nargin > 2 && ...
                ischar(varargin{3}) && ...
                isfield(xffconf.update, lower(varargin{3}(:)'))

                % set flag
                if nargin > 3 && ...
                    islogical(varargin{4}) && ...
                   ~isempty(varargin{4})
                    xffconf.update.(lower(varargin{3}(:)')) = varargin{4}(1);

                % get flag
                else
                    varargout{1} = xffconf.update.(lower(varargin{3}(:)'));
                end


            % for all types
            else

                % set flags
                if nargin > 2 && ...
                    isstruct(varargin{3}) && ...
                    numel(varargin{3}) == 1 && ...
                    numel(fieldnames(varargin{3})) == numel(fieldnames(xffconf.update)) && ...
                    all(strcmp(fieldnames(varargin{3}), fieldnames(xffconf.update)))

                    % check struct
                    sf = fieldnames(varargin{3});
                    for sfc = 1:numel(sf)
                        if ~islogical(varargin{3}.(sf{sfc})) || ...
                            numel(varargin{3}.(sf{sfc})) ~= 1
                            error( ...
                                'xff:BadArgument', ...
                                'Invalid updatestate argument.' ...
                            );
                        end
                    end

                    % set struct
                    xffconf.update = varargin{3};

                % get flags
                else

                    % pass out update struct
                    varargout{1} = xffconf.update;
                end
            end

        % bail out on study commands
        otherwise
            error( ...
                'xff:BadSpecialArgument', ...
                'Invalid special argument given.' ...
            );
    end

% just a lookup value
elseif nargin == 1 && ...
    isa(varargin{1}, 'double') && ...
    numel(varargin{1}) == 1

    % make sure it's given as "not loaded"
    if nargout > 1
        varargout{2} = false;
    end

    % return object
    if any(xffclup == varargin{1})

        % looked up
        varargout{1} = xff(0, 'makeobject', struct('L', varargin{1}));

    % or
    elseif varargin{1} >=1 && ...
        varargin{1} < numel(xffclup)

        % numbered entry
        varargout{1} = xff(0, 'makeobject', ...
            struct('L', xffclup(floor(varargin{1}) + 1)));

    % if not found
    else
        error( ...
            'xff:BadLookup', ...
            'Invalid lookup for handle syntax.' ...
        );
    end

% list of filenames
elseif nargin > 0 && ...
    iscell(varargin{1}) && ...
   ~isempty(varargin{1})

    % try to load objects
    varargout{1} = cell(size(varargin{1}));
    for cc = 1:numel(varargin{1})
        if ischar(varargin{1}{cc}) && ...
           ~isempty(varargin{1}{cc})
            try

                % also allow .img instead of .hdr
                filename = regexprep(varargin{1}{cc}, ...
                    '\.img(\s*\,\s*\d+\s*)?$', '.hdr$1', 'preservecase');
                if nargin > 1
                    varargout{1}{cc} = xff(filename, varargin{2:end});
                else
                    varargout{1}{cc} = xff(filename);
                end

                % special case for hdr files
                if cc == 1 && ...
                    numel(varargin{1}) > 1 && ...
                    numel(varargout{1}{1}) == 1 && ...
                    xffisobject(varargout{1}{1}, true, 'hdr') && ...
                   ~any(cellfun('isempty', regexpi(varargin{1}(:), ...
                        '\.(hdr|img|nii)(\s*\,\s*\d+\s*)?$')))

                    % get content
                    hdrc = xffgetcont(varargout{1}{1}.L);

                    % empty voxeldata
                    if isempty(hdrc.VoxelData) || ...
                       ~istransio(hdrc.VoxelData) || ...
                        ndims(hdrc.VoxelData) ~= 3

                        % then go on...
                        continue;
                    end

                    % get transio (as struct)
                    hdrt = struct(hdrc.VoxelData);
                    if hdrt.LittleND
                        endtype = 'ieee-le';
                    else
                        endtype = 'ieee-be';
                    end

                    % get values
                    filenames = regexprep(varargin{1}(:), ...
                        '\.hdr(\s*\,\s*\d+\s*)?$', '.img$1', 'preservecase')';

                    % get offset and size
                    hdrbo = hdrc.ImgDim.VoxOffset;
                    hdro = hdrbo + zeros(1, numel(filenames));
                    hdro(1) = hdrt.IOOffset;
                    hdrsz = [hdrt.DataDims, numel(hdro)];
                    hdrby = prod(hdrt.DataDims) * hdrt.TypeSize;

                    % remove volume identifiers
                    hasvol = cellfun('isempty', regexpi(filenames, '\.(img|nii)$'));
                    hasvol(1) = false;
                    if any(hasvol)
                        for scc = 2:numel(hdro)
                            if hasvol(scc)
                                hdro(scc) = hdrbo + (str2double(regexprep(filenames{scc}, ...
                                    '^.*\,\s*(\d+)\s*$', '$1')) - 1) * hdrby;
                            end
                        end
                    end

                    % update object
                    hdrc.ImgDim.Dim = ...
                        [numel(hdrsz), hdrsz, ones(1, 7 - numel(hdrsz))];
                    hdrc.ImgDim.PixSpacing(numel(hdrsz) + 1) = 1;
                    try
                        hdrc.VoxelData = transio(filenames, ...
                            endtype, hdrt.DataType, hdro, hdrsz);
                    catch ne_eo;
                        neuroelf_lasterr(ne_eo);
                        continue;
                    end
                    hdrc.VoxelDataCT = cell(1, numel(hdro));
                    hdrc.RunTimeVars.Map = ...
                        hdrc.RunTimeVars.Map(ones(1, numel(hdro)));

                    % try to read headers
                    filenames = regexprep(filenames, '\s*\,\s*\d+\s*$', '');
                    filenames = regexprep(filenames, '\.img$', '.hdr', 'preservecase');
                    hfid = 0;
                    hcnt = uint8(0);
                    hcnt(numel(hdro), 256) = 0;
                    for scc = 1:numel(hdro)
                        try
                            hfid = fopen(filenames{scc}, 'r', hdrc.Endian);
                            if hfid < 1
                                continue;
                            end
                            hcnt(scc, :) = fread(hfid, [256, 1], '*uint8')';
                            fclose(hfid);
                            hfid = 0;
                        catch ne_eo;
                            if hfid > 0
                                fclose(hfid);
                            end
                            neuroelf_lasterr(ne_eo);
                        end
                    end

                    % check crucial settings (must match)
                    if any(any(diff(hcnt(:, [41:48, 71:74, 77:120, 253:256])) ~= 0))
                        continue;
                    end

                    % then set descriptions
                    hdesc = deblank(cellstr(char(hcnt(:, 149:228))));
                    [hdrc.RunTimeVars.Map(:).Name] = deal(hdesc{:});

                    % and parse Mat44 information if necessary
                    cfr = hdrc.ImgDim.PixSpacing(2:4);
                    dimf = hdrc.ImgDim.Dim(2:4);
                    dimh = 0.5 + 0.5 * dimf;
                    mat44 = repmat(eye(4), [1, 1, prod(hdrc.ImgDim.Dim(5:8))]);
                    mat4t = 1;
                    mat4f = regexprep(filename, '\.(hdr|nii)$', '.mat', 'preservecase');
                    q = emptystruct({'QSFormCode', ...
                        'QuaternionBCDXYZ', 'AffineTransXYZ'}, [1, 1]);
                    for scc = 1:numel(hdro)

                        % mat file available
                        try
                            hfid = fopen(mat4f{scc}, 'r');
                            if hfid > 0
                                fclose(hfid);
                                hmatcnt = load(mat4f{scc});
                                if isfield(hmatcnt, 'mat')
                                    mfilec = hmatcnt.mat;
                                elseif isfield(hmatcnt, 'M')
                                    mfilec = hmatcnt.M;
                                else
                                    mfilec = [];
                                end
                                if ~isempty(mfilec)
                                    mat44(:, :, mat4t:mat4t+size(mfilec, 3)-1) = mfilec;
                                    mat4t = mat4t + size(mfilec, 3);
                                    continue;
                                end
                            end
                        catch ne_eo;
                            neuroelf_lasterr(ne_eo);
                        end

                        % read in NIFTI part of header
                        if hdrc.NIIFileType > 0
                            hfid = fopen(filenames{scc}, 'r', hdrc.Endian);
                            fseek(hfid, 252, -1);
                            q.QSFormCode = fread(hfid, [2, 1], 'int16=>double');
                            q.QuaternionBCDXYZ = fread(hfid, [6, 1], 'single=>double');
                            q.AffineTransXYZ = fread(hfid, [12, 1], 'single=>double');
                            fclose(hfid);

                            % first check SFormCode
                            if q.QSFormCode(2) > 0

                                % use AffineTransX/Y/Z
                                mfilec = [reshape(q.AffineTransXYZ, 4, 3)'; ...
                                    0, 0, 0, 1];
                                mfilec(1:3, 4) = mfilec(1:3, 4) - mfilec(1:3, 1:3) * [1; 1; 1];

                            % next check QFormCode
                            elseif q.QSFormCode(1) > 0

                                % use that information instead
                                mfilec = spmtrf(q.QuaternionBCDXYZ(4:6)') * ...
                                    spmq2m(q.QuaternionBCDXYZ(1:3)') * ...
                                    spmtrf([0,0,0], [0,0,0], hdrc.ImgDim.PixSpacing(2:4));
                                mfilec(1:3, 4) = mfilec(1:3, 4) - mfilec(1:3, 1:3) * [1; 1; 1];

                            % old-school stuff
                            else
                                mfilec = [ ...
                                    cfr(1), 0 ,   0   , -cfr(1) * dimh(1); ...
                                      0 , cfr(2), 0   , -cfr(2) * dimh(2); ...
                                      0 ,   0 , cfr(3), -cfr(3) * dimh(3); ...
                                      0 ,   0 ,   0   ,    1];

                                % support default flip
                                if (hdrc.ImgDim.PixSpacing(1) < 0 || ...
                                    (hdrc.ImgDim.PixSpacing(1) == 0 && ...
                                     hdrc.DataHist.Orientation == 0 && ...
                                     xffconf.type.hdr.assumeflipped))

                                    % perform x-flip to get to TAL
                                    mfilec(1, :) = -mfilec(1, :);
                                end
                            end

                        % really old-school stuff
                        else

                            % an originator is given (SPM2)
                            if ~all(hdrc.DataHist.OriginSPM(1:3) == 0)

                                % use this information
                                dho = hdrc.DataHist.OriginSPM(1:3);
                                if all(hdrc.DataHist.OriginSPM(1:3) < 0)
                                    dho = dimf + dho;
                                end

                                % then create a transformation matrix
                                mfilec = [ ...
                                    cfr(1), 0   , 0   , -cfr(1) * dho(1); ...
                                      0 , cfr(2), 0   , -cfr(2) * dho(2); ...
                                      0 ,   0 , cfr(3), -cfr(3) * dho(3); ...
                                      0 ,   0   , 0   ,    1];

                            % for older images
                            else

                                % depending on orientation flag
                                switch (double(hcnt(scc, 253)))
                                    case {1}
                                        mfilec = [ ...
                                            cfr(1), 0 ,   0   , -cfr(1) * dimh(1); ...
                                              0 ,   0 , cfr(3), -cfr(3) * dimh(3); ...
                                              0 , cfr(2), 0   , -cfr(2) * dimh(2); ...
                                              0 ,   0 ,   0   ,    1];
                                    case {2}
                                        mfilec = [ ...
                                              0 , cfr(2), 0   , -cfr(2) * dimh(2); ...
                                              0 ,   0 , cfr(3), -cfr(3) * dimh(3); ...
                                            cfr(1), 0 ,   0   , -cfr(1) * dimh(1); ...
                                              0 ,   0 ,   0   ,    1];
                                    case {3}
                                        mfilec = [ ...
                                            cfr(1), 0 ,   0   , -cfr(1) * dimh(1); ...
                                              0 ,-cfr(2), 0   ,  cfr(2) * dimh(2); ...
                                              0 ,   0 , cfr(3), -cfr(3) * dimh(3); ...
                                              0 ,   0 ,   0   ,    1];
                                    case {4}
                                        mfilec = [ ...
                                            cfr(1), 0 ,   0   , -cfr(1) * dimh(1); ...
                                              0 ,   0 ,-cfr(3),  cfr(3) * dimh(3); ...
                                              0 , cfr(2), 0   , -cfr(2) * dimh(2); ...
                                              0 ,   0 ,   0   ,    1];
                                    case {5}
                                        mfilec = [ ...
                                              0 , cfr(2), 0   , -cfr(2) * dimh(2); ...
                                              0 ,   0 ,-cfr(3),  cfr(3) * dimh(3); ...
                                            cfr(1), 0 ,   0   , -cfr(1) * dimh(1); ...
                                              0 ,   0 ,   0   ,    1];
                                    otherwise
                                        mfilec = [ ...
                                            cfr(1), 0 ,   0   , -cfr(1) * dimh(1); ...
                                              0 , cfr(2), 0   , -cfr(2) * dimh(2); ...
                                              0 ,   0 , cfr(3), -cfr(3) * dimh(3); ...
                                              0 ,   0 ,   0   ,    1];
                                end
                            end

                            % support default flip
                            if (hdrc.ImgDim.PixSpacing(1) < 0 || ...
                                (hdrc.ImgDim.PixSpacing(1) == 0 && ...
                                 hdrc.DataHist.Orientation == 0 && ...
                                 xffconf.type.hdr.assumeflipped))

                                % perform x-flip to get to TAL
                                mfilec(1, :) = -mfilec(1, :);
                            end
                        end

                        % add to Mat44
                        mat44(:, :, mat4t:mat4t+size(mfilec, 3)-1) = mfilec;
                        mat4t = mat4t + size(mfilec, 3);
                    end

                    % and finally store in RTV
                    hdrc.RunTimeVars.Mat44 = mat44;

                    % set back
                    xffsetcont(varargout{1}{1}.L, hdrc);

                    % replace output
                    varargout{1} = varargout{1}{1};

                    % and leave loop
                    break;
                end
            catch ne_eo;
                clearxffobjects(varargout{1});
                rethrow(ne_eo);
            end
        end
    end

% make case for NULL arguments (return ROOT if needed)
elseif nargin == 0
    if nargout > 0
        varargout = cell(1, nargout);
    end
    varargout{1} = xff(0, 'makeobject', struct('L', -1));

% else
else
    if nargin == 1 && ...
        ischar(varargin{1})
        error( ...
            'xff:BadArgument', ...
            'File not found.' ...
        );
    else
        error( ...
            'xff:BadArgument', ...
            'Bad argument combination or file not writable.' ...
        );
    end

% end of argument test if
end



% internal function for stack unwinding
function mst = mystack

    % persistent config
    persistent msc;
    if isempty(msc)
        mlv = version;
        msc = (str2double(mlv(1)) < 7);
    end

    % which version
    if msc
        mst = dbstack;
        mst = {mst.name};
    else
        mst = dbstack('-completenames');
        mst = {mst.file};
    end

    % remove xff from stack
    mst(1:2) = [];
    rst = true(1, numel(mst));
    for rc = 1:numel(rst)
        if ~isempty(strfind(mst{rc}, '@xff'))
            rst(rc) = false;
        end
    end
    mst = mst(rst);
% end of function mst = mystack
