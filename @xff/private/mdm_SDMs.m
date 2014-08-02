function [sdms, stlist, sdmtr, tfiles, bfs, prtcs] = mdm_SDMs(hfile, opts)
% MDM::SDMs  - create SDMs from an MDM file
%
% FORMAT:       [sdms, preds, sdmtr, tfiles, bfs, prtcs] = mdm.SDMs([options])
%
% Input fields:
%
%       options     optional 1x1 struct with fields
%        .asstruct  return structs instead of objects (default: false)
%        .globsigd  also add diff of global signals as nuisance regressors
%        .globsigo  orthogonalize global signals (default: true)
%        .globsigs  add global signals as confound, one of
%                   0 - none
%                   1 - entire dataset (above threshold/within mask)
%                   2 - two (one per hemisphere, split at BV Z=128)
%                   3 or more, perform PCA of time courses and first N
%                   xff object(s), extract average time course from masks
%        .motpars   motion parameters (Sx1 cell array with sdm/txt files)
%        .motparsd  also add diff of motion parameters (default: false)
%        .motparsq  also add squared motion parameters (default: false)
%        .ndcreg    if set > 0, perform deconvolution (only with PRTs!)
%        .orthconf  orthogonalize confounds (and motion parameters, true)
%        .pbar      progress bar object (to show progress, default: [])
%        .pbrange   progress range (default 0 .. 1)
%        .pnames    provide names for parametric regressors (PRT only)
%        .ppicond   list of regressors (or differences) to interact
%        .ppirob    perform robust regression on VOI timecourse and remove
%                   outliers from timecourse/model (threshold, default: 0)
%        .ppitfilt  temporally filter PPI VOI timecourse (default: true)
%        .ppivoi    VOI object used to extract time-course from
%        .ppivoiidx intra-VOI-object index (default: 1)
%        .prtr      1x1 or Sx1 TR (in ms) for PRT::CreateSDM
%        .prtpnorm  normalize parameters of PRT.Conds (true)
%        .remodisis remodel ISIs using PRT::RemodelISIs function ({})
%        .restcond  remove rest condition (rest cond. name, default: '')
%        .savesdms  token, if not empty, save on-the-fly SDMs (e.g. '.sdm')
%        .shuflab   PRT labels (conditions names) to shuffle
%        .shuflabm  minimum number of onsets per label (1x1 or 1xL)
%        .sngtrial  single-trial SDMs
%        .sngtskip  condition list to skip during single-trial conversion
%        .tfilter   add filter regressors to SDMs (cut-off in secs)
%        .tfilttype temporal filter type (one of {'dct'}, 'fourier', 'poly')
%        .xconfound just as motpars, but without restriction on number
%
% Output fields:
%
%       sdms        1xS cell array with (new) SDM objects (or structs)
%       preds       list of predictor names
%       sdmtr       TR assumed for use with each SDM
%       tfiles      time-course file objects (transio access)
%       bfs         basis function set (if PRTs are used, empty otherwise)
%       prtcs       PRT contents (prior to PRT::CreateSDM calls)
%
% Note: all additional fields for the call to PRT::CreateSDM are supported!

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:08 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2011, 2014, Jochen Weber
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

% global access to xffcont for RTC/SDM format description
global xffcont;

% argument check
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'mdm')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'asstruct') || ...
   ~islogical(opts.asstruct) || ...
    numel(opts.asstruct) ~= 1
    opts.asstruct = false;
end
if ~isfield(opts, 'pbar') || ...
    numel(opts.pbar) ~= 1 || ...
   (~isa(opts.pbar, 'xfigure') && ...
    ~isa(opts.pbar, 'xprogress'))
    pb = [];
else
    pb = opts.pbar;
end

if ~isfield(opts, 'pbrange') || ...
   ~isa(opts.pbrange, 'double') || ...
    numel(opts.pbrange) ~= 2 || ...
    any(isinf(opts.pbrange) | isnan(opts.pbrange) | opts.pbrange < 0)
    pbr = [0, 1];
else
    pbr = sort(opts.pbrange(:))';
end
pbm = pbr(1);
pbd = eps + pbr(2) - pbm;

% get object content (including format and handles)
sc = xffgetscont(hfile.L);
bc = sc.C;
hc = sc.H;
bfs = [];

% check list of files
cfs = struct('autofind', true, 'silent', true);
try
    if ~isfield(hc, 'FilesChecked') || ...
       ~islogical(hc.FilesChecked) || ...
       ~hc.FilesChecked
        if ~isempty(pb)
            pb.Progress(pbm, 'Checking file locations...');
        end
        hfile = mdm_CheckFiles(hfile, cfs);
        sc = xffgetscont(hfile.L);
        bc = sc.C;
        hc = sc.H;
    end
catch ne_eo;
    rethrow(ne_eo);
end

% get list of design files and of time course files and prepare output
rfobjs = bc.XTC_RTC;
numstudy = size(rfobjs, 1);
rfiles = rfobjs(:, end);
tfiles = rfobjs(:, end-1);
sdms = cell(size(rfiles));

% check options
if ~isfield(opts, 'collapse') || ...
   ~iscell(opts.collapse) || ...
   ~any([2, 3] == size(opts.collapse, 2)) || ...
    ndims(opts.collapse) ~= 2 || ...
    isempty(opts.collapse)
    collapse = cell(0, 2);
else
    collapse = opts.collapse;
end
if ~isfield(opts, 'globsigd') || ...
   ~islogical(opts.globsigd) || ...
    numel(opts.globsigd) ~= 1
    opts.globsigd = false;
end
if ~isfield(opts, 'globsigo') || ...
   ~islogical(opts.globsigo) || ...
    numel(opts.globsigo) ~= 1
    opts.globsigo = true;
end
if ~isfield(opts, 'globsigs') || ...
   ((~isa(opts.globsigs, 'double') || ...
     numel(opts.globsigs) ~= 1 || ...
     isinf(opts.globsigs) || ...
     isnan(opts.globsigs) || ...
     opts.globsigs < 0) && ...
    (~iscell(opts.globsigs) || ...
     isempty(opts.globsigs) || ...
     ~xffisobject(opts.globsigs{1}, true, {'hdr', 'msk', 'vmr', 'voi'})) && ...
    (~xffisobject(opts.globsigs, true, {'hdr', 'msk', 'vmr', 'voi'})))
    opts.globsigs = 0;
elseif isa(opts.globsigs, 'double')
    opts.globsigs = floor(opts.globsigs);
elseif xffisobject(opts.globsigs, true)
    opts.globsigs = {opts.globsigs};
else
    opts.globsigs = opts.globsigs(:)';
end
if isfield(opts, 'motpars') && ...
    islogical(opts.motpars) && ...
    numel(opts.motpars) == 1 && ...
    opts.motpars
    if isfield(bc.RunTimeVars, 'MotionParameters') && ...
        iscell(bc.RunTimeVars.MotionParameters) && ...
        numel(bc.RunTimeVars.MotionParameters) == size(bc.XTC_RTC, 1)
        opts.motpars = bc.RunTimeVars.MotionParameters;
    else
        opts.motpars = repmat({'RTV'}, size(bc.XTC_RTC, 1), 1);
    end
end
if ~isfield(opts, 'motpars') || ...
   ~iscell(opts.motpars) || ...
    numel(opts.motpars) ~= size(bc.XTC_RTC, 1)
    opts.motpars = cell(size(bc.XTC_RTC, 1), 1);
else
    opts.motpars = opts.motpars(:);
end
if ~isfield(opts, 'motparsd') || ...
   ~islogical(opts.motparsd) || ...
    numel(opts.motparsd) ~= 1
    opts.motparsd = false;
end
if ~isfield(opts, 'motparsq') || ...
   ~islogical(opts.motparsq) || ...
    numel(opts.motparsq) ~= 1
    opts.motparsq = false;
end
if ~isfield(opts, 'ndcreg') || ...
   ~isa(opts.ndcreg, 'double') || ...
    numel(opts.ndcreg) ~= 1 || ...
    isinf(opts.ndcreg) || ...
    isnan(opts.ndcreg) || ...
    opts.ndcreg < 0 || ...
    opts.ndcreg > 120
    opts.ndcreg = 0;
else
    opts.ndcreg = floor(opts.ndcreg);
end
if opts.ndcreg > 0
    sdmtype = 'fir';
else
    sdmtype = 'hrf';
end
if isfield(hc, 'NrOfVolumes') && ...
    numel(hc.NrOfVolumes) == numstudy
    opts.nvol = hc.NrOfVolumes(:);
else
    opts.nvol = [];
end
if ~isfield(opts, 'orthconf') || ...
   ~islogical(opts.orthconf) || ...
    numel(opts.orthconf) ~= 1
    opts.orthconf = true;
end
if ~isfield(opts, 'pnames') || ...
   ~iscell(opts.pnames) || ...
    isempty(opts.pnames) || ...
   ~all(cellfun(@ischar, opts.pnames(:))) || ...
    any(cellfun('isempty', opts.pnames(:)))
    opts.pnames = {};
else
    opts.pnames = opts.pnames(:)';
end
if ~isfield(opts, 'ppicond') || ...
   (~iscell(opts.ppicond)) && ...
    (~ischar(opts.ppicond) || ...
     isempty(opts.ppicond))
    opts.ppicond = {};
    opts.ppirob = false;
    opts.ppivoi = [];
elseif ischar(opts.ppicond)
    opts.ppicond = {opts.ppicond(:)'};
else
    for pcc = numel(opts.ppicond):-1:1
        if ~ischar(opts.ppicond{pcc}) || ...
            isempty(opts.ppicond{pcc})
            error( ...
                'xff:BadArgument', ...
                'Invalid ppicond list.' ...
            );
        end
    end
end
if ~isfield(opts, 'ppirob') || ...
   ~islogical(opts.ppirob) || ...
    numel(opts.ppirob) ~= 1
    opts.ppirob = false;
end
if ~isfield(opts, 'ppitfilt') || ...
   ~islogical(opts.ppitfilt) || ...
    numel(opts.ppitfilt) ~= 1
    opts.ppitfilt = true;
end
if ~isfield(opts, 'ppivoi') || ...
    numel(opts.ppivoi) ~= 1 || ...
   (~xffisobject(opts.ppivoi, true, 'poi') && ...
    ~xffisobject(opts.ppivoi, true, 'voi'))
    opts.ppivoi = [];
end
if ~isfield(opts, 'ppivoiidx') || ...
    numel(opts.ppivoiidx) ~= 1 || ...
   ~isa(opts.ppivoiidx, 'double') || ...
    isinf(opts.ppivoiidx) || ...
    isnan(opts.ppivoiidx) || ...
    opts.ppivoiidx < 1
    opts.ppivoiidx = 1;
else
    opts.ppivoiidx = floor(opts.ppivoiidx);
end
if ~isa(opts.globsigs, 'double') || ...
    opts.globsigs ~= 0 || ...
   (~isempty(opts.ppicond) && ...
    ~isempty(opts.ppivoi)) || ...
    nargout > 3
    try
        tiosz = xff(0, 'transiosize');
        xff(0, 'transiosize', 1e5);
        for stc = 1:numstudy
            if ~isempty(pb)
                pb.Progress(pbm, sprintf('Accessing XTC %d...', stc));
            end
            tfiles{stc} = xff(tfiles{stc});
            if ~xffisobject(tfiles{stc}, true, {'hdr', 'mtc', 'vtc'})
                error( ...
                    'xff:BadArgument', ...
                    'PPI/global signals currently only supported for VTCs.' ...
                );
            end
            tfilec = xffgetcont(tfiles{stc}.L);
            if ischar(opts.motpars{stc}) && ...
                strcmpi(opts.motpars{stc}, 'rtv')
                opts.motpars{stc} = [];
                if isfield(tfilec.RunTimeVars, 'MotionParameters') && ...
                   ~isempty(tfilec.RunTimeVars.MotionParameters) && ...
                    size(tfilec.RunTimeVars.MotionParameters, 2) == 6
                    opts.motpars{stc} = tfilec.RunTimeVars.MotionParameters;
                end
            end
            if nargout > 3
                tfiles{stc} = bless(tfiles{stc}, 1);
            end
        end
    catch ne_eo;
        xff(0, 'transiosize', tiosz);
        clearxffobjects(tfiles);
        rethrow(ne_eo);
    end
    xff(0, 'transiosize', tiosz);
end
if ~isfield(opts, 'prtr') || ...
   ~isa(opts.prtr, 'double') || ...
   ~any([1, numstudy] == numel(opts.prtr)) || ...
    any(isinf(opts.prtr(:)) | isnan(opts.prtr(:)) | opts.prtr(:) <= 0)
    if isfield(hc, 'TR') && ...
        numel(hc.TR) == numstudy
        opts.prtr = hc.TR(:);
    else
        opts.prtr = [];
    end
else
    opts.prtr = opts.prtr(:);
    if numel(opts.prtr) == 1
        opts.prtr = opts.prtr .* ones(numstudy, 1);
    end
end
if ~isfield(opts, 'prtpnorm') || ...
   ~islogical(opts.prtpnorm) || ...
    numel(opts.prtpnorm) ~= 1
    opts.prtpnorm = true;
end
if ~isfield(opts, 'remodisis') || ...
   ~iscell(opts.remodisis)
    opts.remodisis = {};
end
if ~isfield(opts, 'restcond') || ...
   (~ischar(opts.restcond) && ...
    ~iscell(opts.restcond)) || ...
    isempty(opts.restcond)
    opts.restcond = {};
elseif ischar(opts.restcond)
    opts.restcond = {lower(opts.restcond(:)')};
else
    for rcc = numel(opts.restcond):-1:1
        if ~ischar(opts.restcond{rcc}) || ...
            isempty(opts.restcond{rcc})
            opts.restcond(rcc) = [];
        else
            opts.restcond{rcc} = lower(opts.restcond{rcc}(:)');
        end
    end
end
if ~isfield(opts, 'savesdms') || ...
   ~ischar(opts.savesdms) || ...
    isempty(regexpi(opts.savesdms(:)', '\.sdm$'))
    opts.savesdms = '';
end
if ~isfield(opts, 'shuflab') || ...
   ~iscell(opts.shuflab)
    opts.shuflab = {};
else
    opts.shuflab = opts.shuflab(:)';
    for lc = numel(opts.shuflab):-1:1
        if ~ischar(opts.shuflab{lc}) || ...
            isempty(opts.shuflab{lc}) || ...
           (lc > 1 && ...
            any(strcmpi(opts.shuflab{lc}, opts.shuflab(1:lc-1))))
            opts.shuflab(lc) = [];
        else
            opts.shuftlab{lc} = opts.shuflab{lc}(:)';
        end
    end
end
if ~isfield(opts, 'shuflabm') || ...
   ~isa(opts.shuflabm, 'double') || ...
    any(isinf(opts.shuflabm(:)) | isnan(opts.shuflabm(:))) || ...
   ~any([1, numel(opts.shuflab)] == numel(opts.shuflabm))
    opts.shuflabm = 1;
end
if ~isfield(opts, 'sngtrial') || ...
   ~islogical(opts.sngtrial) || ...
    numel(opts.sngtrial) ~= 1
    opts.sngtrial = false;
elseif opts.sngtrial
    if opts.ndcreg > 0
        warning( ...
            'xff:InvalidOption', ...
            'Single-Trial SDMs cannot be combined with FIR modeling.' ...
        );
        opts.ndcreg = 0;
        sdmtype = 'hrf';
    end
end
if ~isfield(opts, 'sngtskip') || ...
   ~iscell(opts.sngtskip)
    opts.sngtskip = {};
else
    opts.sngtskip = opts.sngtskip(:)';
end
if ~isfield(opts, 'tfilter') || ...
   ~isa(opts.tfilter, 'double') || ...
    numel(opts.tfilter) ~= 1 || ...
    isnan(opts.tfilter) || ...
    opts.tfilter < 60
    opts.tfilter = Inf;
end
if ~isfield(opts, 'tfilttype') || ...
   ~ischar(opts.tfilttype) || ...
    isempty(opts.tfilttype) || ...
   ~any(strcmpi(opts.tfilttype(:)', {'dct', 'fourier', 'poly'}))
    opts.tfilttype = 'dct';
else
    opts.tfilttype = lower(opts.tfilttype(:)');
end
if ~isfield(opts, 'xconfound') || ...
   ~iscell(opts.xconfound)
    opts.xconfound = {};
else
    opts.xconfound = opts.xconfound(:);
end

% no valid NrOfVolumes/TR given -> read info from files
if isempty(opts.nvol) || ...
    isempty(opts.prtr)
    try
        opts.nvol = zeros(numstudy, 1);
        if isempty(opts.prtr)
            opts.prtr = zeros(numstudy, 1);
        end
        for stc = 1:numel(opts.prtr)
            if ischar(tfiles{stc})
                if ~isempty(pb)
                    pb.Progress(pbm, sprintf('Accessing XTC %d...', stc));
                end
                trstr = xff(tfiles{stc}, 'h');
            else
                trstr = xffgetcont(tfiles{stc}.L);
            end
            if isfield(trstr, 'NrOfVolumes')
                opts.nvol(stc) = trstr.NrOfVolumes;
            elseif isfield(trstr, 'NrOfTimePoints')
                opts.nvol(stc) = trstr.NrOfTimePoints;
            else
                opts.nvol(stc) = trstr.ImgDim.Dim(5);
            end
            if opts.prtr(stc) == 0
                if isfield(trstr, 'TR')
                    opts.prtr(stc) = trstr.TR;
                end
            end
        end
    catch ne_eo;
        rethrow(ne_eo);
    end
end

% make sure motpars and xconfound are correctly sized
if numel(opts.motpars) ~= numstudy
    opts.motpars = cell(numstudy, 1);
end
if numel(opts.xconfound) ~= numstudy
    opts.xconfound = cell(numstudy, 1);
end
mpnb = {'trX',  'trY',  'trZ',  'rotX',  'rotY',  'rotZ' };
mpnd = {'trXd', 'trYd', 'trZd', 'rotXd', 'rotYd', 'rotZd'};
mpn2 = {'trX2', 'trY2', 'trZ2', 'rotX2', 'rotY2', 'rotZ2'};

% load objects (PRTs and/or SDMs)
try
    for stc = 1:numstudy
        if ~isempty(pb)
            pb.Progress(pbm, sprintf('Reading design for study %d...', stc));
        end
        sdms{stc} = bless(xff(rfiles{stc}), 1);
        if ~xffisobject(sdms{stc}, true, {'prt', 'sdm'})
            error( ...
                'xff:BadArgument', ...
                'Invalid design file ''%s'' for study %d.', ...
                rfiles{stc}, stc ...
            );
        end
    end
catch ne_eo;
    clearxffobjects(tfiles);
    clearxffobjects(sdms);
    rethrow(ne_eo);
end

% for single-trial GLMs
if opts.sngtrial

    % check that all files ARE PRTs, otherwise, error and end
    for stc = 1:numstudy
        if ~xffisobject(sdms{stc}, true, 'prt')
            clearxffobjects(tfiles);
            clearxffobjects(sdms);
            error( ...
                'xff:BadArgument', ...
                'Single-trial SDMs only possible with all-PRTs in XTC_RTC.' ...
            );
        end
        if ~isempty(opts.remodisis)
            prt_RemodelISIs(sdms{stc}, opts.remodisis);
        end
        if ~isempty(collapse)
            for coc = 1:size(collapse, 1)
                prt_Collapse(sdms{stc}, collapse{coc, :});
            end
        end
    end

    % convert and get list
    try
        stlist = singletrialprts(sdms, mdm_Subjects(hfile, true), opts.sngtskip);
    catch ne_eo;
        clearxffobjects(tfiles);
        clearxffobjects(sdms);
        rethrow(ne_eo);
    end

% regular mode
else

    % if required, create list
    stlist = cell(0, 1);
    for stc = 1:numstudy
        desobj = xffgetscont(sdms{stc}.L);
        if strcmpi(desobj.S.Extensions{1}, 'prt')
            if ~isempty(opts.remodisis)
                prt_RemodelISIs(sdms{stc}, opts.remodisis);
            end
            if ~isempty(collapse)
                for coc = 1:size(collapse, 1)
                    prt_Collapse(sdms{stc}, collapse{coc, :});
                end
            end
            desobj = xffgetscont(sdms{stc}.L);
            condlist = cat(1, desobj.C.Cond.ConditionName);
        else
            if desobj.C.FirstConfoundPredictor > 0
                condlist = ...
                    desobj.C.PredictorNames(1:desobj.C.FirstConfoundPredictor-1);
                condlist = condlist(:);
            else
                condlist = desobj.C.PredictorNames(:);
            end
        end
        condlist(multimatch(condlist, opts.restcond) > 0) = [];
        if isempty(stlist)
            stlist = condlist;
        else
            for clc = numel(condlist):-1:1
                if any(strcmp(condlist{clc}, stlist))
                    condlist(clc) = [];
                end
            end
            if ~isempty(condlist)
                stlist = cat(1, stlist, condlist);
            end
        end
    end

    % make sure constant is not in the list!
    stlist(strcmpi('constant', stlist)) = [];
end

% lookup coordinates for global time course masks
if iscell(opts.globsigs)

    % number of components
    if numel(opts.globsigs) > 1 && ...
        isa(opts.globsigs{end}, 'double') && ...
        numel(opts.globsigs{end}) == 1 && ...
       ~isinf(opts.globsigs{end}) && ...
       ~isnan(opts.globsigs{end}) && ...
        opts.globsigs{end} >= 1
        ngs = round(opts.globsigs{end});
        opts.globsigs(end) = [];
    else
        ngs = 1;
    end

    % only valid for VTC files
    if ~xffisobject(tfiles{1}, true, 'vtc')
        clearxffobjects(tfiles);
        clearxffobjects(sdms);
        error( ...
            'xff:BadArgument', ...
            'Mask-based global signals only valid for VTCs.' ...
        );
    end

    % for each object, find coordinates
    for oc = 1:numel(opts.globsigs)

        % get object's content
        gss = xffgetscont(opts.globsigs{oc}.L);
        gso = gss.C;
        xtcsc = xffgetscont(tfiles{1}.L);
        if ~isempty(pb)
            gsf = gss.F;
            if isempty(gsf)
                gsf = sprintf('global signal object %d', oc);
            end
            pb.Progress(pbm, sprintf('Getting voxel indices for %s...', gsf));
        end

        % for VMRs
        if xffisobject(opts.globsigs{oc}, true, 'vmr')

            % find voxels > 0
            [gv1, gv2, gv3] = ind2sub(size(gso.VMRData), ...
                find(gso.VMRData(:, :, :) > 0));
            if gso.OffsetX ~= 0
                gv1 = gv1 + gso.OffsetX;
            end
            if gso.OffsetY ~= 0
                gv2 = gv2 + gso.OffsetY;
            end
            if gso.OffsetZ ~= 0
                gv3 = gv3 + gso.OffsetZ;
            end

        % for VOIs
        elseif xffisobject(opts.globsigs{oc}, true, 'voi')

            % recompute into VTC voxels
            gv1 = unique(cat(1, gso.VOI.Voxels), 'rows');
            gv3 = 128 - gv1(:, 1);
            gv2 = 128 - gv1(:, 3);
            gv1 = 128 - gv1(:, 2);

        % for MSKs
        elseif xffisobject(opts.globsigs{oc}, true, 'msk')

            % ensure compatibility
            if ~isequal(gso.Resolution, xtcsc.C.Resolution) || ...
               ~isequal(gso.XStart, xtcsc.C.XStart) || ...
               ~isequal(gso.YStart, xtcsc.C.YStart) || ...
               ~isequal(gso.ZStart, xtcsc.C.ZStart) || ...
               ~isequal(gso.XEnd, xtcsc.C.XEnd) || ...
               ~isequal(gso.YEnd, xtcsc.C.YEnd) || ...
               ~isequal(gso.ZEnd, xtcsc.C.ZEnd)
                clearxffobjects(tfiles);
                clearxffobjects(sdms);
                error( ...
                    'xff:BadArgument', ...
                    'Global signal MSK and VTC spatial mismatch.' ...
                );
            end

            % find voxels
            opts.globsigs{oc} = find(gso.Mask(:));
            continue;

        % for HDR/NIIs
        else

            % find voxels > 0
            [gv1, gv2, gv3] = ind2sub(size(gso.VoxelData), ...
                find(gso.VoxelData(:, :, :, 1) > 0));

            % get transformation matrix
            vtrf = hdr_CoordinateFrame(opts.globsigs{oc});
            vtrf = vtrf.Trf;

            % compute voxel coordinates in BV space
            gv1 = [gv1, gv2, gv3, ones(numel(gv1), 1)] * vtrf';
            gv1(:, 4) = [];
            gv3 = 128 - gv1(:, 1);
            gv2 = 128 - gv1(:, 3);
            gv1 = 128 - gv1(:, 2);
        end

        % get offset, size, and resolution
        voff = [xtcsc.C.XStart, xtcsc.C.YStart, xtcsc.C.ZStart];
        vsiz = size(xtcsc.C.VTCData);
        vsiz(1) = [];
        vres = xtcsc.C.Resolution;

        % compute coordinates to extract data from
        gv1 = unique(round(1 + (1 / vres) .* ([gv1, gv2, gv3] - ...
            repmat(voff, [numel(gv1), 1]))), 'rows');
        gv1(any(gv1 < 1, 2) | gv1(:, 1) > vsiz(1) | ...
            gv1(:, 2) > vsiz(2) | gv1(:, 3) > vsiz(3), :) = [];
        opts.globsigs{oc} = ...
            sub2ind(vsiz, gv1(:, 1), gv1(:, 2), gv1(:, 3));
    end
end

% get RTC/SDM format for access of motion parameter/confound files
sdmtff = xffcont(1).C.Formats.tff(xffcont(1).C.Extensions.sdm{2});

% copy of options for SDM::CreatePRT
psdmopts = opts;

% onsets, parameters
if nargout > 5
    prtcs = cell(numstudy, 1);
end

% work on each study
ppitc = [];
ppitf = {};
try
    for fc = 1:numstudy

        % progress bar
        if ~isempty(pb)
            pb.Progress(pbm + pbd * (fc / numstudy), ...
                sprintf('Processing design for study %d...', fc));
        end

        % set TR
        sttr = opts.prtr(fc);
        if sttr == 0 || ...
            opts.nvol(fc) == 0
            tch = xff(tfiles{fc}, 'h');
        end
        if sttr == 0
            sttr = tch.TR;
        end
        if opts.nvol(fc) == 0
            if isfield(tch, 'NrOfVolumes')
                opts.nvol(fc) = tch.NrOfVolumes;
            elseif isfield(tch, 'NrOfTimePoints')
                opts.nvol(fc) = tch.NrOfTimePoints;
            elseif isfield(tch, 'NIIFileType')
                opts.nvol(fc) = tch.ImgDim.Dim(5);
            elseif isfield(tch, 'Brick')
                opts.nvol(fc) = numel(tch.Brick);
            end
        end

        % extract PPI VOI timecourse
        if ~isempty(opts.ppivoi)
            if size(rfobjs, 2) > 2
                ppitc = mtc_POITimeCourse(tfiles{fc}, opts.ppivoi);
            else
                ppitc = aft_VOITimeCourse(tfiles{fc}, opts.ppivoi);
            end
            stnumtp = size(ppitc, 1);

            % select time course
            if opts.ppivoiidx > size(ppitc, 2)
                ppitc = ppitc(:, 1);
            else
                ppitc = ppitc(:, opts.ppivoiidx);
            end

            % normalize (PSC!)
            ppitc = psctrans(ppitc);
            ppitc = ppitc - mean(ppitc);

            % invalid TC?
            if any(isinf(ppitc) | isnan(ppitc))

                % don't use for this study!
                ppitc = [];
                ppitf = {};

            % otherwise
            else

                % apply correct filter settings
                if ~isinf(opts.tfilter) && ...
                    opts.ppitfilt
                    if opts.tfilttype(1) == 'd'
                        ppitf = {'tempdct', 1000 * opts.tfilter};
                    elseif opts.tfilttype(1) == 'f'
                        ppitf = {'tempsc', floor(0.001 * sttr * stnumtp / opts.tfilter)};
                    else
                        ppitf = {'temppoly', 2 + floor(0.002 * sttr * stnumtp / opts.tfilter)};
                    end
                end
            end
        end

        % create SDM from PRT if necessary
        prtsc = '';
        sdmsc = xffgetscont(sdms{fc}.L);
        if strcmpi(sdmsc.S.Extensions{1}, 'prt')
            try
                prt = sdms{fc};
                prtsc = sdmsc.F;
                prtc = prt_ConditionNames(prt);
                if ~isempty(opts.restcond)
                    rcond = false(1, numel(prtc));
                    for rcc = 1:numel(prtc)
                        rcond(rcc) = any(strcmpi(prtc{rcc}, opts.restcond));
                    end
                    rcond = find(rcond);
                else
                    rcond = [];
                end
                psdmopts.nvol = opts.nvol(fc);
                psdmopts.pnorm = opts.prtpnorm;
                psdmopts.ppitc = ppitc;
                psdmopts.ppitf = ppitf;
                psdmopts.prtr = sttr;
                psdmopts.rcond = rcond;
                psdmopts.type = sdmtype;

                % shuffle condition labels
                if ~isempty(opts.shuflab)

                    % create copied PRT with shuffled labels
                    sprt = prt_ShuffleLabels(prt, opts.shuflab, opts.shuflabm);

                    % copy content to original PRT
                    xffsetcont(prt.L, xffgetcont(sprt.L));

                    % remove new PRT
                    aft_ClearObject(sprt);
                end

                % add parameter names to PRT
                if sdmsc.C.ParametricWeights > 0 && ...
                    numel(opts.pnames) >= sdmsc.C.ParametricWeights
                    sdmsc = xffgetscont(prt.L);
                    sdmsc.C.RunTimeVars.ParameterNames = ...
                        opts.pnames(1:sdmsc.C.ParametricWeights);
                    xffsetcont(prt.L, sdmsc.C);
                end

                % store PRT content
                if nargout > 5
                    prtcs{fc} = xffgetcont(prt.L);
                end

                % create SDM from PRT
                [sdms{fc}, bfs] = prt_CreateSDM(prt, psdmopts);
                bless(sdms{fc}, 1);
                aft_ClearObject(prt);
                sdmsc = xffgetscont(sdms{fc}.L);
            catch ne_eo;
                error( ...
                    'xff:InternalError', ...
                    'Error converting PRT to SDM: %s.', ...
                    ne_eo.message ...
                );
            end
        elseif ~strcmpi(sdmsc.S.Extensions{1}, 'sdm')
            error( ...
                'xff:BadArgument', ...
                'PRT or SDM needed to run study %d.', ...
                fc ...
            );
        end
        stnumtp = size(sdmsc.C.SDMMatrix, 1);

        % add filters
        fltmx = [];
        if ~isinf(opts.tfilter)
            if opts.tfilttype(1) == 'd'
                stfilt = floor(0.002 * sttr * stnumtp / opts.tfilter);
            elseif opts.tfilttype(1) == 'f'
                stfilt = floor(0.001 * sttr * stnumtp / opts.tfilter);
            else
                stfilt = 2 + floor(0.002 * sttr * stnumtp / opts.tfilter);
            end
            if stfilt > 0
                ffreg = size(sdmsc.C.SDMMatrix, 2) + 1;
                sdm_AddFilters(sdms{fc}, struct( ...
                    'ftype',  opts.tfilttype, ...
                    'number', stfilt));
                sdmsc = xffgetscont(sdms{fc}.L);
                if opts.orthconf
                    fltmx = sdmsc.C.SDMMatrix(:, ffreg:end);
                    fltiv = pinv(fltmx' * fltmx) * fltmx';
                end
            end
        end

        % add motion parameters
        if ~isempty(opts.motpars{fc})
            mp = [];
            if ischar(opts.motpars{fc}) && ...
                numel(opts.motpars{fc}) > 5 && ...
                any(strcmpi(opts.motpars{fc}(end-3:end), {'.rtc', '.sdm'}))
                try
                    mpsdm = tffio(opts.motpars{fc}(:)', sdmtff);
                    mp = mpsdm.SDMMatrix;
                    if ~isequal(size(mp), [stnumtp, 6]) || ...
                        any(isinf(mp(:)) | isnan(mp(:)))
                        mp = [];
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    mp = [];
                end
            elseif ischar(opts.motpars{fc}) && ...
                numel(opts.motpars{fc}) > 5 && ...
                strcmpi(opts.motpars{fc}(end-3:end), '.txt')
                try
                    mp = load(opts.motpars{fc}(:)');
                    if ~isequal(size(mp), [stnumtp, 6]) || ...
                        any(isinf(mp(:)) | isnan(mp(:)))
                        mp = [];
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    mp = [];
                end
            elseif isnumeric(opts.motpars{fc}) && ...
                isequal(size(opts.motpars{fc}), [stnumtp, 6])
                mp = double(opts.motpars{fc});
            end
            if ~isempty(mp)
                if opts.motparsd
                    dmp = [2 .* mp(1, :) - mp(2, :); mp; 2 .* mp(end - 1, :) - mp(end, :)];
                    dmp = 0.5 .* (diff(dmp(1:end-1, :)) + diff(dmp(2:end, :)));
                end
                if opts.motparsd && ...
                    opts.motparsq
                    mp = [ztrans(mp), ztrans(dmp), ztrans(mp .* mp)];
                    mpn = [mpnb, mpnd, mpn2];
                    mpc = floor(255.999 * rand(18, 3));
                elseif opts.motparsd
                    mp = [ztrans(mp), ztrans(dmp)];
                    mpn = [mpnb, mpnd];
                    mpc = floor(255.999 * rand(12, 3));
                elseif opts.motparsq
                    mp = [ztrans(mp), ztrans(mp .* mp)];
                    mpn = [mpnb, mpn2];
                    mpc = floor(255.999 * rand(12, 3));
                else
                    mp = ztrans(mp);
                    mpc = floor(255.999 * rand(6, 3));
                    mpn = mpnb;
                end
                if opts.orthconf
                    if ~isempty(fltmx)
                        mp = mp - fltmx * (fltiv * mp);
                    end
                    mp = orthvecs(mp);
                end
                sdmsc.C.NrOfPredictors = sdmsc.C.NrOfPredictors + size(mp, 2);
                sdmsc.C.PredictorNames = [sdmsc.C.PredictorNames(:)', mpn];
                sdmsc.C.PredictorColors = [sdmsc.C.PredictorColors; mpc];
                sdmsc.C.SDMMatrix = [sdmsc.C.SDMMatrix, mp];
                xffsetcont(sdms{fc}.L, sdmsc.C);
            end
        end

        % add additional confounds
        if ~isempty(opts.xconfound{fc})
            xc = [];
            if ischar(opts.xconfound{fc}) && ...
                numel(opts.xconfound{fc}) > 5 && ...
                any(strcmpi(opts.xconfound{fc}(end-3:end), {'.rtc', '.sdm'}))
                try
                    xcsdm = tffio(opts.xconfound{fc}(:)', sdmtff);
                    xc = xcsdm.SDMMatrix;
                    if ndims(xc) > 2 || ...
                        size(xc, 1) ~= stnumtp
                        xc = [];
                    else
                        xc(:, any(isinf(xc) | isnan(xc))) = [];
                        xc(:, sum(abs(diff(xc))) == 0) = [];
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    xc = [];
                end
            elseif ischar(opts.xconfound{fc}) && ...
                numel(opts.xconfound{fc}) > 5 && ...
                strcmpi(opts.xconfound{fc}(end-3:end), '.txt')
                try
                    xc = load(opts.xconfound{fc}(:)');
                    if ndims(xc) > 2 || ...
                        size(xc, 1) ~= stnumtp || ...
                        any(isinf(xc(:)) | isnan(xc(:)))
                        xc = [];
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    xc = [];
                end
            end
            if ~isempty(xc)
                mp = ztrans(mp);
                xcc = floor(255.999 * rand(size(xc, 2), 3));
                xcn = cell(1, size(xc, 2));
                for xcnc = 1:numel(xcn)
                    xcn{xcnc} = sprintf('xc%03d', xcnc);
                end
                if opts.orthconf
                    if ~isempty(fltmx)
                        xc = xc - fltmx * (fltiv * xc);
                    end
                    xc = orthvecs(xc);
                end
                sdmsc.C.NrOfPredictors = sdmsc.C.NrOfPredictors + size(xc, 2);
                sdmsc.C.PredictorNames = [sdmsc.C.PredictorNames(:)', xcn];
                sdmsc.C.PredictorColors = [sdmsc.C.PredictorColors; xcc];
                sdmsc.C.SDMMatrix = [sdmsc.C.SDMMatrix, xc];
                xffsetcont(sdms{fc}.L, sdmsc.C);
            end
        end

        % add global signals
        glsigs = [];
        if iscell(opts.globsigs)
            glsigup = false(1, numel(opts.globsigs));
            xtcsc = xffgetscont(tfiles{fc}.L);
            glsigs = zeros(stnumtp, numel(opts.globsigs) * ngs);
            for oc = 1:numel(opts.globsigs)
                switch lower(xtcsc.S.Extensions{1})
                    case {'fmr', 'mtc'}
                        error( ...
                            'xff:BadArgument', ...
                            'Mask-based extraction of FMR not supported.' ...
                        );
                    case {'vtc'}
                        glsiguse = 0;
                        if isfield(xtcsc.C.RunTimeVars, 'GlobSigs')
                            for occ = 1:size(xtcsc.C.RunTimeVars.GlobSigs, 1)
                                if isequal(xtcsc.C.RunTimeVars.GlobSigs{occ, 1}, opts.globsigs{oc})
                                    glsiguse = occ;
                                    break;
                                end
                            end
                        else
                            xtcsc.C.RunTimeVars.GlobSigs = cell(0, 2);
                        end
                        if glsiguse > 0
                            glsiglist = xtcsc.C.RunTimeVars.GlobSigs{glsiguse, 2};
                        else
                            glsigup(oc) = true;
                            if numel(opts.globsigs{oc}) > 1000
                                glsiglist = xtcsc.C.VTCData(:, :, :, :);
                                glsiglist = glsiglist(:, opts.globsigs{oc});
                            else
                                glsiglist = xtcsc.C.VTCData(:, opts.globsigs{oc});
                            end
                        end
                end
                if ngs == 1
                    glsigs(:, oc) = meannoinfnan(glsiglist, 2);
                    if glsigup(oc)
                        xtcsc.C.RunTimeVars.GlobSigs(end+1, :) = ...
                            {opts.globsigs{oc}, glsigs(:, oc)};
                    end
                else
                    glsiglist(:, any(isinf(glsiglist) | isnan(glsiglist), 1) | ...
                        all(diff(glsiglist, 1, 1) == 0)) = [];
                    glsigs(:, (oc*ngs):-1:(1+(oc-1)*ngs)) = ztrans(ne_fastica(double( ...
                        glsiglist - ones(size(glsiglist, 1), 1) * mean(glsiglist, 1)), ...
                        struct('step', 'pca', 'eign', ngs)));
                    if glsigup(oc)
                        xtcsc.C.RunTimeVars.GlobSigs(end+1, :) = ...
                            {opts.globsigs{oc}, glsigs(:, (oc*ngs):-1:(1+(oc-1)*ngs))};
                    end
                end
            end
            if any(glsigup)
                xffsetscont(tfiles{fc}.L, xtcsc);
                try
                    aft_SaveRunTimeVars(tfiles{fc});
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
            glsigs(:, varc(glsigs) < sqrt(eps)) = [];
        elseif opts.globsigs > 0
            xtcsc = xffgetscont(tfiles{fc}.L);
            switch lower(xtcsc.S.Extensions{1})
                case {'fmr'}
                    if xtcsc.C.DataStorageFormat == 1
                        globd = xtcsc.C.Slice(1).STCData(:, :, :, :);
                        globd(1, 1, 1, numel(xtcsc.C.Slice)) = ...
                            globd(1, 1, 1, 1);
                        for slc = 2:size(globd, 4)
                            globd(:, :, :, slc) = ...
                                xtcsc.C.Slice(slc).STCData(:, :, :);
                        end
                    else
                        globd = xtcsc.C.Slice(1).STCData(:, :, :, :);
                    end
                    globd = permute(globd, [3, 2, 4, 1]);
                    globd = globd(:, :);
                case {'mtc'}
                    globd = xtcsc.C.MTCData(:, :);
                case {'vtc'}
                    globd = xtcsc.C.VTCData(:, :, :, :);
                    globd = globd(:, :);
            end
            switch opts.globsigs

                % one global signal: mean
                case {1}

                    glsigs = mean(globd, 2);

                % two global signals: left/right (for MTC: just one)
                case {2}
                    if strcmpi(xtcsc.S.Extensions{1}, 'mtc')
                        glsigs = mean(globd, 2);
                    else
                        glsigs = [mean(globd(:, 1:floor(0.5 * size(globd, 2))), 2), ...
                            mean(globd(:, ceil(1 + 0.5 * size(globd, 2)):end), 2)];
                    end

                % more than 2
                otherwise

                    % perform PCA
                    glsigs = ne_fastica(double(globd), struct('step', 'pca'));

                    % take last N
                    glsigs = glsigs(:, end:-1:max(1,size(glsigs,2)+1-opts.globsigs));
            end
        end

        % global signals exist
        if ~isempty(glsigs)

            % also add derivatives
            if opts.globsigd
                dglsigs = [2 .* glsigs(1, :) - glsigs(2, :); glsigs; 2 .* glsigs(end - 1, :) - glsigs(end, :)];
                glsigs = [glsigs, 0.5 .* (diff(dglsigs(1:end-1, :)) + diff(dglsigs(2:end, :)))];
            end

            % transform
            glsigs = glsigs - (ones(size(glsigs, 1), 1) * mean(glsigs));

            % orthogonalize
            if opts.globsigo
                glsigs = orthvecs(glsigs);
            end

            % melt-down to correlations of < 0.7
            if size(glsigs, 2) > 1
                glcorr = corrcoef(glsigs);
                glcorr(1:(size(glcorr, 1)+1):end) = 0;
                [glchi1, glchi2] = ...
                    ind2sub(size(glcorr), find(abs(glcorr(:)) > sqrt(0.5)));
                while ~isempty(glchi2)
                    if glcorr(glchi1(1), glchi2(1)) > 0
                        glsigs(:, glchi1(1)) = 0.5 .* ...
                            (glsigs(:, glchi1(1)) + glsigs(:, glchi2(1)));
                    else
                        glsigs(:, glchi1(1)) = 0.5 .* ...
                            (glsigs(:, glchi1(1)) - glsigs(:, glchi2(1)));
                    end
                    glsigs(:, glchi1(2)) = [];
                    glcorr = corrcoef(glsigs);
                    glcorr(1:(size(glcorr, 1)+1):end) = 0;
                    [glchi1, glchi2] = ...
                        ind2sub(size(glcorr), find(abs(glcorr(:)) > sqrt(0.5)));
                end
            end

            % add to SDMs
            xcn = cell(1, size(glsigs, 2));
            for xcnc = 1:numel(xcn)
                xcn{xcnc} = sprintf('gs%d', xcnc);
            end
            sdmsc.C.NrOfPredictors = sdmsc.C.NrOfPredictors + numel(xcn);
            sdmsc.C.PredictorColors = ...
                [sdmsc.C.PredictorColors; floor(255.999 .* rand(numel(xcn), 3))];
            sdmsc.C.PredictorNames = [sdmsc.C.PredictorNames, xcn];
            sdmsc.C.SDMMatrix = [sdmsc.C.SDMMatrix, glsigs];
            xffsetcont(sdms{fc}.L, sdmsc.C);
        end

        % make sure the matrix has exactly one mean confound
        confounds = find(all(sdmsc.C.SDMMatrix == ...
            (ones(size(sdmsc.C.SDMMatrix, 1), 1) * sdmsc.C.SDMMatrix(1, :))) & ...
            sdmsc.C.SDMMatrix(1, :) ~= 0);

        % confound(s) found
        if ~isempty(confounds)

            % make sure all of them are confounds
            if any(confounds < sdmsc.C.FirstConfoundPredictor)
                error( ...
                    'xff:BadArgument', ...
                    'SDM %d has mean/constant predictor before confounds.', ...
                    fc ...
                );
            end

            % remove from design
            sdmsc.C.NrOfPredictors = sdmsc.C.NrOfPredictors - numel(confounds);
            sdmsc.C.PredictorColors(confounds, :) = [];
            sdmsc.C.PredictorNames(confounds) = [];
            sdmsc.C.SDMMatrix(:, confounds) = [];
        end

        % then add *at the end* of the matrix/names
        sdmsc.C.IncludesConstant = 1;
        sdmsc.C.PredictorColors(end+1, :) = [255, 255, 255];
        sdmsc.C.PredictorNames{end+1} = 'Constant';
        sdmsc.C.SDMMatrix(:, end+1) = 1;
        sdmsc.C.NrOfPredictors = size(sdmsc.C.SDMMatrix, 2);

        % remove all empty confound regressors
        emptyregs = find(all(sdmsc.C.SDMMatrix == 0));
        emptyregs(emptyregs < sdmsc.C.FirstConfoundPredictor) = [];
        if ~isempty(emptyregs)
            sdmsc.C.NrOfPredictors = sdmsc.C.NrOfPredictors - numel(emptyregs);
            sdmsc.C.PredictorColors(emptyregs, :) = [];
            sdmsc.C.PredictorNames(emptyregs) = [];
            sdmsc.C.SDMMatrix(:, emptyregs) = [];
        end
        xffsetcont(sdms{fc}.L, sdmsc.C);

        % save SDM?
        if ~isempty(opts.savesdms) && ...
           ~isempty(prtsc) && ...
            ischar(prtsc)
            try
                aft_SaveAs(sdms{fc}, [prtsc(1:end-4) opts.savesdms]);
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end
    end

    % get structures?
    if opts.asstruct
        sdmstr = sdms;
        for fc = 1:numstudy
            sdmstr{fc} = xffgetcont(sdms{fc}.L);
        end
    end

    % return as structs
    if opts.asstruct
        clearxffobjects(sdms(:));
        sdms = sdmstr;
    end

    % return tr?
    if nargout > 2
        sdmtr = opts.prtr;
    end

% deal with errors
catch ne_eo;
    clearxffobjects(tfiles);
    clearxffobjects(sdms(:));
    rethrow(ne_eo);
end
