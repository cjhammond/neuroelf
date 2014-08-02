function hfile = mdm_VTCCondAverage(hfile, conds, opts)
% MDM::VTCCondAverage  - average condition timecourses
%
% FORMAT:       [mdm = ] mdm.VTCCondAverage(conds [, opts])
%
% Input fields:
%
%       conds       1xC cell array of condition names (or {'listdlg'})
%       opts        optional 1x1 struct with fields
%        .avgwin    length of averaging window in ms (default: 20000)
%        .basewin   baseline window in ms (default: -4000:2000:0)
%        .collapse  Cx2 or Cx3 cell array with PRT::Collapse arguments
%        .ffx       string, replace subject IDs with FFX ID (default: '')
%        .gpthresh  global-signal f-thresh for inclusion (default: 0.05)
%        .ithresh   intensity threshold for masking, default: auto-detect
%        .mask      mask object in which to compute the average (reused)
%        .naive     remove all condition regressors from models (false)
%        .remgsig   remove variance from global signal (default: false)
%        .remgsmod  use events to determine GS voxels (default: true)
%        .robtune   robust tuning parameter (default: 4.685)
%        .robust    perform 2-pass robust instead of OLS regression (false)
%        .rsngtrial regress out all but the trials being extracted (false)
%        .samptr    sampling TR in ms (default: 500)
%        .smooth    temporal smoothing in ms (after nuisance removal, 0)
%        .subsel    cell array with subject IDs to work on (default: all)
%        .trans     either of 'none', 'psc', 'z' (default: from MDM)
%        .vtcpath   folder to write subject VTCs into (default: source)
%
% Output fields:
%
%       vtc         extended VTC object(s) (RunTimeVars)
%
% Note: this call is only valid if all model files in the MDM are PRTs!
%
%       the baseline window (basewin) must be evenly spaced!
%
%       the intensity threshold is only used to create an implicit mask!
%
%       the 'st' stats time course type is t-scores (for each time point)
%
%       each subject will have one VTC generated, which is then
%       automatically saved, in the folder of the first VTCs filename

% Version:  v0.9d
% Build:    14062410g
% Date:     Jun-24 2014, 10:53 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2013, 2014, Jochen Weber
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

% argument check
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'mdm') || ...
   ~iscell(conds) || ...
    isempty(conds)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
bsc = xffgetscont(hfile.L);
[mdmpath, mdmfile] = fileparts(bsc.F);
if isempty(mdmfile)
    mdmfile = 'unsaved_MDM';
else
    mdmfile = [mdmfile '_MDM'];
end
if numel(conds) == 1 && ...
    ischar(conds{1}) && ...
    strcmpi(conds{1}(:)', 'listdlg') && ...
    size(bsc.C.XTC_RTC, 2) == 2 && ...
   ~isempty(regexpi(bsc.C.XTC_RTC{1, 2}, '\.prt$'))
    try
        prto = {[]};
        prto{1} = xff(bsc.C.XTC_RTC{1, 2});
        if ~xffisobject(prto{1}, true, 'prt')
            error( ...
                'xff:BadObject', ...
                'Condition selection requires PRT.' ...
            );
        end
        prtc = prt_ConditionNames(prto{1});
        clearxffobjects(prto);
        [prtci, selok] = listdlg('ListString', prtc, ...
            'SelectionMode', 'multiple', ...
            'ListSize', [max(420, 12 * size(char(prtc), 2)), 16 * numel(prtc)], ...
            'InitialValue', (1:numel(prtc))', ...
            'Name', ['Condition Selection for averaging from ' mdmfile '...']);
        if ~isequal(selok, 1)
            return;
        end
        conds = prtc(prtci);
    catch ne_eo;
        clearxffobjects(prto);
        rethrow(ne_eo);
    end
end
conds = conds(:);
dimc = numel(conds);
for cc = 1:dimc
    if ~ischar(conds{cc}) || ...
        isempty(conds{cc})
        error( ...
            'xff:BadArgument', ...
            'Invalid condition name (%d).', ...
            cc ...
        );
    end
    conds{cc} = conds{cc}(:)';
end
if numel(unique(conds)) ~= dimc
    error( ...
        'xff:BadArgument', ...
        'Duplicate condition names.' ...
    );
end
bc = bsc.C;
if ~strcmpi(bc.TypeOfFunctionalData, 'vtc') || ...
    size(bc.XTC_RTC, 2) ~= 2 || ...
    any(cellfun('isempty', regexpi(bc.XTC_RTC(:, 1), '\.vtc$')))
    error( ...
        'xff:BadArgument', ...
        'MDM must be VTC-based.' ...
    );
end
if any(cellfun('isempty', regexpi(bc.XTC_RTC(:, 2), '\.prt$')))
    error( ...
        'xff:BadArgument', ...
        'MDM must be PRT-based.' ...
    );
end
try
    hfile = mdm_CheckFiles(hfile, struct('autofind', true, 'silent', true));
catch ne_eo;
    rethrow(ne_eo);
end
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'avgwin') || ...
   ~isa(opts.avgwin, 'double') || ...
    numel(opts.avgwin) ~= 1 || ...
    isinf(opts.avgwin) || ...
    isnan(opts.avgwin) || ...
    opts.avgwin <= 0
    opts.avgwin = 20000;
end
if ~isfield(opts, 'basewin') || ...
   ~isa(opts.basewin, 'double') || ...
    isempty(opts.basewin) || ...
    any(isinf(opts.basewin(:)) | isnan(opts.basewin(:)))
    basewin = -4000:2000:0;
else
    basewin = opts.basewin(:)';
end
bwinmin = min(basewin);
bwinmax = max(basewin);
if bwinmax > bwinmin
    bwinstep = ceil((bwinmax - bwinmin) / (numel(basewin) - 1));
else
    bwinstep = 1;
end
if any(abs(basewin - (bwinmin:bwinstep:bwinmax)) > (0.01 * bwinstep))
    error( ...
        'xff:BadArgument', ...
        'Invalid baseline window spacing.' ...
    );
end
bwinmax = bwinmax + 0.1 * bwinstep;
basewin = bwinmin:bwinstep:bwinmax;
if ~isfield(opts, 'collapse') || ...
   ~iscell(opts.collapse) || ...
   ~any([2, 3] == size(opts.collapse, 2)) || ...
    ndims(opts.collapse) ~= 2
    opts.collapse = cell(0, 2);
end
if ~isfield(opts, 'condcols') || ...
   ~isa(opts.condcols, 'double') || ...
    size(opts.condcols, 1) ~= dimc || ...
    size(opts.condcols, 2) < 3 || ...
    any(isinf(opts.condcols(:)) | isnan(opts.condcols(:)) | opts.condcols(:) < 0 | opts.condcols(:) > 255)
    opts.condcols = zeros(dimc, 0);
else
    opts.condcols(:, 17:end) = [];
    if all(opts.condcols(:) <= 1)
        opts.condcols = round(255 .* opts.condcols);
    end
    opts.condcols = uint8(round(opts.condcols));
end
if ~isfield(opts, 'ffx') || ...
   ~ischar(opts.ffx) || ...
    isempty(opts.ffx)
    opts.ffx = '';
else
    opts.ffx = opts.ffx(:)';
    opts.ffx(opts.ffx == ' ' | opts.ffx == '_') = [];
    if isempty(opts.ffx)
        opts.ffx = 'groupffx';
    end
end
if ~isfield(opts, 'gpthresh') || ...
   ~isa(opts.gpthresh, 'double') || ...
    numel(opts.gpthresh) ~= 1 || ...
    isinf(opts.gpthresh) || ...
    isnan(opts.gpthresh) || ...
    opts.gpthresh <= 0 || ...
    opts.gpthresh >= 0.5
    opts.gpthresh = 0.05;
else
    opts.gpthresh = min(0.25, opts.gpthresh);
end
if ~isfield(opts, 'ithresh') || ...
   ~isa(opts.ithresh, 'double') || ...
    numel(opts.ithresh) ~= 1 || ...
    isinf(opts.ithresh) || ...
    isnan(opts.ithresh) || ...
    opts.ithresh < 0
    opts.ithresh = -1;
end
if ~isfield(opts, 'mask') || ...
   ~xffisobject(opts.mask, true, 'msk')
    if ~isfield(opts, 'mask') || ...
       ~islogical(opts.mask) || ...
        ndims(opts.mask) ~= 3
        opts.mask = [];
    end
else
    opts.mask = xffgetcont(opts.mask.L);
    opts.mask = (opts.mask.Mask(:, :, :) > 0);
end
if ~isfield(opts, 'naive') || ...
    numel(opts.naive) ~= 1 || ...
   ~islogical(opts.naive)
    opts.naive = false;
end
if ~isfield(opts, 'prtr') || ...
   ~isa(opts.prtr, 'double') || ...
    numel(opts.prtr) ~= 1 || ...
    isinf(opts.prtr) || ...
    isnan(opts.prtr) || ...
    opts.prtr <= 0
    opts.prtr = [];
end
if ~isfield(opts, 'remgsig') || ...
    numel(opts.remgsig) ~= 1 || ...
   ~islogical(opts.remgsig)
    opts.remgsig = false;
end
if ~isfield(opts, 'remgsmod') || ...
    numel(opts.remgsmod) ~= 1 || ...
   ~islogical(opts.remgsmod)
    opts.remgsmod = true;
end
if ~isfield(opts, 'robtune') || ...
   ~isa(opts.robtune, 'double') || ...
    numel(opts.robtune) ~= 1 || ...
    isinf(opts.robtune) || ...
    isnan(opts.robtune) || ...
    opts.robtune <= 0
    opts.robtune = 4.685;
end
if ~isfield(opts, 'robust') || ...
    numel(opts.robust) ~= 1 || ...
   ~islogical(opts.robust)
    opts.robust = false;
end
if ~isfield(opts, 'samptr') || ...
   ~isa(opts.samptr, 'double') || ...
    numel(opts.samptr) ~= 1 || ...
    isinf(opts.samptr) || ...
    isnan(opts.samptr) || ...
    opts.samptr <= 0
    samptr = 500;
else
    samptr = max(10, round(opts.samptr));
end
if ~isfield(opts, 'smooth') || ...
   ~isa(opts.smooth, 'double') || ...
    numel(opts.smooth) ~= 1 || ...
    isinf(opts.smooth) || ...
    isnan(opts.smooth) || ...
    opts.smooth < 0
    opts.smooth = 0;
else
    opts.smooth = min(10000, opts.smooth);
end
if ~isfield(opts, 'rsngtrial') || ...
   ~islogical(opts.rsngtrial) || ...
    numel(opts.rsngtrial) ~= 1
    opts.rsngtrial = false;
end
if ~isfield(opts, 'subsel') || ...
   ~iscell(opts.subsel) || ...
    isempty(opts.subsel)
    opts.subsel = mdm_Subjects(hfile);
else
    opts.subsel = opts.subsel(:);
    for sc = numel(opts.subsel):-1:1
        if ~ischar(opts.subsel{sc}) || ...
            isempty(opts.subsel{sc})
            opts.subsel(sc) = [];
        else
            opts.subsel{sc} = opts.subsel{sc}(:)';
        end
    end
    opts.subsel = unique(opts.subsel);
    try
        ssm = multimatch(opts.subsel, mdm_Subjects(hfile));
    catch ne_eo;
        rethrow(ne_eo);
    end
    if any(ssm < 1)
        error( ...
            'xff:BadArgument', ...
            'Invalid subject ID in selection.' ...
        );
    end
end
transv = 0;
if ~isfield(opts, 'trans') || ...
   ~ischar(opts.trans) || ...
    isempty(opts.trans) || ...
   ~any('npz' == lower(opts.trans(1)))
    opts.trans = 'n';
    if bc.PSCTransformation > 0
        opts.trans = 'p';
        transv = 3;
    end
    if bc.zTransformation > 0
        opts.trans = 'z';
        transv = 1;
    end
elseif lower(opts.trans(1)) == 'p'
    opts.trans = 'p';
    transv = 3;
elseif lower(opts.trans(1)) == 'z'
    opts.trans = 'z';
    transv = 1;
end
if ~isfield(opts, 'vtcpath') || ...
   ~ischar(opts.vtcpath) || ...
    isempty(opts.vtcpath) || ...
    exist(opts.vtcpath(:)', 'dir') ~= 7
    if isempty(opts.ffx)
        opts.vtcpath = '';
    else
        opts.vtcpath = pwd;
    end
else
    opts.vtcpath = opts.vtcpath(:)';
end

% keep track of output VTC files
ovtcs = opts.subsel;

% objects and subject IDs
vtcs = bc.XTC_RTC(:, 1);
prts = bc.XTC_RTC(:, 2);
subids = mdm_Subjects(hfile, true);
usevtc = (multimatch(subids, opts.subsel) > 0);
numvtcs = sum(usevtc);
if numvtcs < 1
    error( ...
        'xff:BadArgument', ...
        'Invalid arguments or options.' ...
    );
end
if ~all(usevtc)
    subids = subids(usevtc);
    vtcs = vtcs(usevtc);
    prts = prts(usevtc);
end

% FFX instead
osubids = subids;
osubid = '_NOTASUBJECT_';
if ~isempty(opts.ffx)
    opts.subsel = {opts.ffx};
    ovtcs = opts.subsel;
    subids = repmat({opts.ffx}, numel(subids), 1);
end

% generate condition string
condstr = conds;
for sc = 1:dimc
    condstr{sc} = makelabel(conds{sc});
end
condstr = sprintf('%s_', condstr{:});

% generate averaged filenames
ovexist = false(numel(ovtcs), 1);
for sc = 1:numel(ovtcs)
    usevtci = findfirst(strcmp(subids, opts.subsel{sc}));
    if isempty(opts.vtcpath)
        vtcfolder = fileparts(vtcs{usevtci});
    else
        vtcfolder = opts.vtcpath;
    end
    ovtcs{sc} = sprintf('%s/%s_%s_%sAVG.vtc', vtcfolder, ...
        opts.subsel{sc}, mdmfile, condstr);
    if exist(ovtcs{sc}, 'file') > 0
        ovexist(sc) = true;
    end
end

% nothing to do
if all(ovexist)
    return;
end

% some computations
avgwin = 0:samptr:opts.avgwin;
if avgwin(end) < opts.avgwin
    avgwin(end+1) = avgwin(end) + avgwin(2);
end
avgwinmin = avgwin(1);
avgwinmax = avgwin(end) + 0.1 * samptr;
dima = numel(avgwin);
if opts.robust
    dimtc = 3;
else
    dimtc = 2;
end
dimt = dima * dimtc * dimc;

% get onsets
try
    opts.store = true;
    onsets = mdm_ConditionOnsets(hfile, conds, opts);
    bsc = xffgetscont(hfile.L);
catch ne_eo;
    rethrow(ne_eo);
end

% get models
opts.asstruct = true;
try
    opts.sngtrial = false;
    sdms = mdm_SDMs(hfile, opts);

    % every condition must have at least one match
    cmatch = false(dimc, 1);
    for sc = 1:numel(sdms)
        cmatch = cmatch | (multimatch(conds, sdms{sc}.PredictorNames(:)) > 0);
        if all(cmatch)
            break;
        end
    end
    if ~all(cmatch)
        error( ...
            'xff:BadArgument', ...
            'Not all conditions covered.' ...
        );
    end

    % for single-trial regression
    if opts.rsngtrial

        % get those SDMs as well
        xffsetscont(hfile.L, bsc);
        opts.sngtrial = true;
        ssdms = mdm_SDMs(hfile, opts);
    end
catch ne_eo;
    rethrow(ne_eo);
end

% get colors
if size(opts.condcols, 2) == 3
    ccol = opts.condcols;
    dcol = uint8(round(0.333 .* double(ccol)));
    oo = ones(size(ccol, 1), 1);
    opts.condcols = [dcol, uint8(64 .* oo), ccol, uint8(255 .* oo), ...
            uint8(255 .* oo) - dcol, uint8(64 .* oo), uint8(255 .* oo) - ccol, uint8(255 .* oo)];
elseif size(opts.condcols, 2) == 6
    ccol1 = opts.condcols(:, 1:3);
    dcol1 = uint8(round(0.333 .* double(ccol1)));
    ccol2 = opts.condcols(:, 4:6);
    dcol2 = uint8(round(0.333 .* double(ccol2)));
    oo = ones(size(ccol1, 1), 1);
    opts.condcols = [dcol1, uint8(64 .* oo), ccol1, uint8(255 .* oo), ...
            dcol2, uint8(64 .* oo), ccol2, uint8(255 .* oo)];
elseif size(opts.condcols, 2) == 12
    oo = ones(size(opts.condcols, 1), 1);
    opts.condcols = [opts.condcols(:, 1:3), uint8(64 .* oo), opts.condcols(:, 4:6), uint8(255 .* oo), ...
        opts.condcols(:, 7:9), uint8(64 .* oo), opts.condcols(:, 10:12), uint8(255 .* oo)];
elseif size(opts.condcols,2 ) ~= 16
    prednames = sdms{1}.PredictorNames;
    predcols = sdms{1}.PredictorColors;
    opts.condcols(end, 16) = 0;
    for cc = 1:dimc
        predi = findfirst(strcmpi(prednames(:), conds{cc}));
        if isempty(predi)
            ccol = uint8(floor(255.9999 .* rand(1, 3)));
        else
            ccol = uint8(round(predcols(predi, :)));
        end
        dcol = uint8(round(0.333 .* double(ccol)));
        opts.condcols(cc, :) = [dcol, uint8(64), ccol, uint8(255), ...
            uint8(255) - dcol, uint8(64), uint8(255) - ccol, uint8(255)];
    end
end

% apply selection
if ~all(usevtc)
    onsets = onsets(usevtc, :);
    if ~isempty(sdms)
        sdms = sdms(usevtc);
    end
end
numstudy = numel(vtcs);

% load VTC objects (transio access)
vtco = vtcs;
onsrem = zeros(numstudy, dimc);
try
    for sc = 1:numstudy
        vtco{sc} = xff(vtcs{sc}, 't');
        if ~xffisobject(vtco{sc}, true, 'vtc')
            error( ...
                'xff:BadObject', ...
                'Not a valid VTC object (%s).', ...
                vtcs{sc} ...
            );
        end

        % for first VTC
        tvtcc = xffgetcont(vtco{sc}.L);
        tlay = aft_Layout(vtco{sc});
        tlnv = tlay(4);
        tlay(4) = [];
        if sc == 1

            % copy object (for output)
            vtc = bless(aft_CopyObject(vtco{sc}), 1);
            vtcc = xffgetcont(vtc.L);

            % store layout
            vlay = tlay;
            vsz = vlay(1:3);
            numvox = prod(vsz);

        % for others
        else

            % check layout
            if ~isequal(vlay, tlay)
                error( ...
                    'xff:BadObject', ...
                    'VTCs must match in dims and offsets (mismatch: %s).', ...
                    vtcs{sc} ...
                );
            end
        end

        % go over onsets
        lastonstime = tvtcc.TR * tlnv - 2500;
        for cc = 1:size(onsets, 2)
            if isempty(onsets{sc, cc})
                continue;
            end
            remons = find(onsets{sc, cc}(:, 1) >= lastonstime);
            if ~isempty(remons)
                onsets{sc, cc}(remons, :) = [];
                onsrem(sc, cc) = numel(remons);
            end
        end
    end
catch ne_eo;
    clearxffobjects(vtco);
    aft_ClearObject(vtc);
    rethrow(ne_eo);
end

% total number of onsets
nonsets = size(cat(1, onsets{:}), 1);
consets = 0;

% no or invalid mask given
if ~islogical(opts.mask) || ...
   ~isequal(size(opts.mask), vsz)

    % check for averaging mask in handles
    if isfield(bsc.C.RunTimeVars, 'VTCAveragingMask') && ...
        iscell(bsc.C.RunTimeVars.VTCAveragingMask) && ...
        numel(bsc.C.RunTimeVars.VTCAveragingMask) == 2 && ...
        isequal(bsc.C.RunTimeVars.VTCAveragingMask{1}, vtcs)

        % re-use
        opts.mask = bsc.C.RunTimeVars.VTCAveragingMask{2};

    % no mask yet
    else

        % initialize progress bar
        try
            pbar = xprogress;
            xprogress(pbar, 'setposition', [80, 200, 640, 36]);
            xprogress(pbar, 'settitle', 'Full-VTC averaging: mask generation...');
            xprogress(pbar, 0, sprintf('Averaging VTC 1/%d...', numel(vtcs)), 'visible', 0, numel(vtcs));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            pbar = [];
        end

        % create mask
        opts.mask = zeros(vsz);
        for rc = 1:numel(vtcs)
            vtccont = xffgetcont(vtco{rc}.L);
            if ~isempty(pbar)
                xprogress(pbar, rc - 1, sprintf('Averaging VTC %d/%d...', rc, numel(vtcs)));
            end
            opts.mask = opts.mask + squeeze(mean(vtccont.VTCData(:, :, :, :), 1));
        end
        opts.mask = (1 / numel(vtcs)) .* opts.mask;

        % auto-detect threshold
        if ~isempty(pbar)
            xprogress(pbar, rc, 'Augmenting mask...');
        end
        if opts.ithresh < 0
            ithreshm = double(ceil(max(opts.mask(:))));
            ithreshc = histcount(opts.mask, 0, ithreshm, ithreshm / 511.000001);
            ithreshc = flexinterpn(ithreshc(:), [Inf; 1; 1; numel(ithreshc)], smoothkern(5), 1);
            opts.ithresh = 0.25 * ithreshm * (findfirst(diff(ithreshc) > 0, -1) / 511);
        end

        % intersect with colin brain if available
        colinbrain = [neuroelf_path('colin') '/colin_brain.vmr'];
        colinbicbm = [neuroelf_path('colin') '/colin_brain_ICBMnorm.vmr'];
        colinbtaln = [neuroelf_path('colin') '/colin_brain_TALnorm.vmr'];
        if exist(colinbrain, 'file') > 0
            colin = {[]};
            try
                colin{1} = xff(colinbrain);
                sc = aft_SampleBVBox(colin{1}, aft_BoundingBox(vtc), 1) > 0;
                xffclear(colin{1}.L);
            catch ne_eo;
                clearxffobjects(colin);
                neuroelf_lasterr(ne_eo);
                sc = true(size(opts.mask));
            end
        else
            sc = true(size(opts.mask));
        end
        if exist(colinbicbm, 'file') > 0
            colin = {[]};
            try
                colin{1} = xff(colinbicbm);
                rc = aft_SampleBVBox(colin{1}, aft_BoundingBox(vtc), 1) > 0;
                xffclear(colin{1}.L);
            catch ne_eo;
                clearxffobjects(colin);
                neuroelf_lasterr(ne_eo);
                rc = true(size(opts.mask));
            end
        else
            rc = true(size(opts.mask));
        end
        if exist(colinbtaln, 'file') > 0
            colin = {[]};
            try
                colin{1} = xff(colinbtaln);
                cc = aft_SampleBVBox(colin{1}, aft_BoundingBox(vtc), 1) > 0;
                xffclear(colin{1}.L);
            catch ne_eo;
                clearxffobjects(colin);
                neuroelf_lasterr(ne_eo);
                cc = true(size(opts.mask));
            end
        else
            cc = true(size(opts.mask));
        end

        % intersect
        opts.mask = ((opts.mask >= opts.ithresh) & (sc | rc | cc)) | ...
            ((opts.mask >= (0.25 .* opts.ithresh)) & sc & rc & cc);

        % save
        bsc.C.RunTimeVars.AutoSave = true;
        bsc.C.RunTimeVars.VTCAveragingMask = {vtcs, opts.mask};
        xffsetscont(hfile.L, bsc);
        if ~isempty(bsc.F)
            try
                aft_SaveRunTimeVars(hfile);
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end

        % close bar
        if ~isempty(pbar)
            closebar(pbar);
        end
    end
end
mask = opts.mask;
smask = sum(mask(:));
osmask = ones(1, smask);

% initialize progress bar
try
    pbar = xprogress;
    xprogress(pbar, 'setposition', [80, 200, 640, 36]);
    xprogress(pbar, 'settitle', sprintf('Full-VTC averaging %d onsets...', nonsets));
    xprogress(pbar, 0, 'Preparation...', 'visible', 0, nonsets);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    pbar = [];
end

% get interpolation kernel
[tw, ipk] = flexinterpn_method([0; 1; 0], [Inf; 0; 1; 3], 'cubic');

% VTC settings
vtcc.NameOfSourceFMR = bsc.F;
vtcc.NrOfCurrentPRT = 1;
vtcc.DataType = 2;
vtcc.NrOfVolumes = dimt;
vtcc.TR = samptr;
vtcc.VTCData = single(zeros([0, vlay(1:3)]));
vtcc.VTCData(dimt, 1, 1, 1) = 0;
vtcc.RunTimeVars.AutoSave = true;
vtcc.RunTimeVars.AvgVTC = true;
vtcc.RunTimeVars.AvgGlobSigRemoved = opts.remgsig;
vtcc.RunTimeVars.AvgRobust = opts.robust;
vtcc.RunTimeVars.AvgRobustTune = opts.robtune;
vtcc.RunTimeVars.AvgSmooth = opts.smooth;
vtcc.RunTimeVars.AvgTransformationType = transv;
vtcc.RunTimeVars.AvgWindowFrom = 0;
vtcc.RunTimeVars.AvgWindowStep = avgwin(2);
vtcc.RunTimeVars.AvgWindowTo = avgwin(end);
vtcc.RunTimeVars.BaseWindowFrom = basewin(1);
vtcc.RunTimeVars.BaseWindowStep = bwinstep;
vtcc.RunTimeVars.BaseWindowTo = basewin(end);
vtcc.RunTimeVars.Map = repmat(struct( ...
    'Type', 30, 'LowerThreshold', 0, 'UpperThreshold', 0.5, ...
    'Name', '', 'RGBLowerThreshPos', [255, 0, 0], 'RGBUpperThreshPos', [255, 255, 0], ...
    'RGBLowerThreshNeg', [255, 0, 255], 'RGBUpperThreshNeg', [0, 0, 255], ...
    'UseRGBColor', 1, 'LUTName', '<default>', 'TransColorFactor', 1, ...
    'NrOfLags', 0, 'MinLag', 0, 'MaxLag', 0, 'CCOverlay', 0, ...
    'ClusterSize', 4, 'EnableClusterCheck', 0, 'UseValuesAboveThresh', 1, ...
    'DF1', 0, 'DF2', 0, 'ShowPositiveNegativeFlag', 3, ...
    'BonferroniValue', 0, 'NrOfFDRThresholds', 0, 'FDRThresholds', zeros(0, 3), ...
    'OverlayColors', []), 1, dimc);
vtcc.RunTimeVars.NrOfConditions = dimc;
vtcc.RunTimeVars.NrOfConditionOnsets = zeros(1, dimc);
vtcc.RunTimeVars.NrOfTCsPerCondition = dimtc;
vtcc.RunTimeVars.NrOfVolumesPerTC = dima;
vtcc.RunTimeVars.NrOfSourceVTCs = 1;
vtcc.RunTimeVars.NrOfSubjects = 1;
vtcc.RunTimeVars.ConditionColors = opts.condcols;
vtcc.RunTimeVars.ConditionNames = conds;
vtcc.RunTimeVars.ConditionOnsets = {};
if opts.robust
    vtcc.RunTimeVars.ConditionThresholds = repmat(reshape([0, 4, 0.5, 0.5, 8, 1], [1, 3, 2]), dimc, 1);
else
    vtcc.RunTimeVars.ConditionThresholds = repmat(reshape([0, 4, 0.5, 8], [1, 2, 2]), dimc, 1);
end
vtcc.RunTimeVars.SubjectNames = {};
vtcc.RunTimeVars.TCNames = {'mean', 'sd'};
if opts.robust
    vtcc.RunTimeVars.TCNames{3} = 'meanrobw';
end
vtcc.RunTimeVars.ScalingWindow = [-2, 2];
vtcc.RunTimeVars.ScalingWindowLim = [0.25, 1];
vtcc.RunTimeVars.SubMapVol = 1;

% iterate over subjects
for sc = 1:numel(opts.subsel)

    % set subject name
    vtcc.RunTimeVars.SubjectNames = opts.subsel(sc);

    % find VTCs
    usevtc = find(strcmp(subids, opts.subsel{sc}));
    vtcc.RunTimeVars.NrOfSourceVTCs = numel(usevtc);
    vtcc.RunTimeVars.SourcePRTs = prts(usevtc);
    vtcc.RunTimeVars.SourceVTCs = vtcs(usevtc);
    vtcc.RunTimeVars.ConditionOnsets = onsets(usevtc, :);

    % don't re-create (with the same filename!)
    if exist(ovtcs{sc}, 'file') > 0
        continue;
    end

    % reset data
    vtcc.VTCData(:) = 0;
    onscount = zeros(1, dimc);
    tcow = zeros(dima * dimtc * dimc, 1);

    % for all runs for this subject
    for rc = 1:numel(usevtc)

        % get data
        vtci = usevtc(rc);
        ons = onsets(vtci, :);
        if all(cellfun('isempty', ons))
            continue;
        end
        vtccont = xffgetcont(vtco{vtci}.L);
        if isempty(opts.prtr)
            vtctr = vtccont.TR;
        else
            vtctr = opts.prtr;
        end
        obwinstep = bwinstep / vtctr;
        awinstep = samptr / vtctr;
        if ~isempty(pbar)
            [vtcfolder, vtcshort] = fileparts(vtcs{vtci});
            xprogress(pbar, consets, sprintf('Reading data from %s...', vtcshort));
        end
        vtcdata = vtccont.VTCData(:, :, :, :);
        nvtctp = size(vtcdata, 1);
        sdmmatrix = sdms{vtci}.SDMMatrix;
        sdmconds = sdms{vtci}.PredictorNames(:);
        sdmconf1 = sdms{vtci}.FirstConfoundPredictor;

        % for single-trial designs, get some additional info
        if opts.rsngtrial
            ssdmmatrix = ssdms{vtci}.SDMMatrix;
            ssdmconds = ssdms{vtci}.PredictorNames(:);

            % new onset counters
            if ~strcmp(osubid, osubids{vtci})
                sonscount = zeros(1, dimc);
                osubid = osubids{vtci};
            end
        end

        % smoothing
        if opts.smooth > 0
            smk = smoothkern(opts.smooth / vtctr);
        else
            smk = 1;
        end

        % remove empty regressors
        removebets = all(sdmmatrix == 0);
        sdmmatrix(:, removebets) = [];
        sdmconds(removebets) = [];

        % reshape
        if ~isempty(pbar)
            xprogress(pbar, consets, sprintf('Masking data from %s...', vtcshort));
        end
        vtcdata = double(reshape(vtcdata, nvtctp, numvox));
        vtcdata = vtcdata(:, mask);
        vtccsz = size(vtcdata);

        % progress
        if ~isempty(pbar)
            xprogress(pbar, consets, sprintf('Regressing out nuisance from %s...', vtcshort));
        end

        % for robust computation
        if opts.robust

            % compute weights (first pass)
            if opts.naive
                [betas, iXX, cc] = ...
                    calcbetas(sdmmatrix(:, sdmconf1:end), vtcdata, 1);
            else
                [betas, iXX, cc] = calcbetas(sdmmatrix, vtcdata, 1);
            end
            w = vtcdata - cc;
            ws = opts.robtune .* max(std(w), sqrt(eps));
            w = repmat((1 ./ ws), nvtctp, 1) .* w;
            wo = (abs(w) < 1) .* (1 - w .^ 2) .^ 2;

            % compute global signal
            if opts.remgsig

                % full model
                if opts.remgsmod

                    % find regressors to drop (conditions)
                    gpidx = setdiff((1:size(sdmmatrix, 2))', multimatch(conds, sdmconds));

                    % compute F-stat
                    [gsigf, gdf1, gdf2] = modelcomp(sdmmatrix, sdmmatrix(:, gpidx), vtcdata, 1);

                    % compute threshold
                    gsfthresh = sdist('finv', opts.gpthresh, gdf1, gdf2, true);

                    % mask
                    gsig = sum(wo(:, gsigf <= gsfthresh) .* vtcdata(:, gsigf <= gsfthresh), 2) ./ ...
                        sum(wo(:, gsigf <= gsfthresh), 2);

                    % and add GS from mask
                    if ~any(isnan(gsig))
                        sdmmatrix = [sdmmatrix(:, 1:end-1), ztrans(gsig), sdmmatrix(:, end)];
                    end

                % only nuisance
                else

                    % compute F-stat of nuisance over mean-only
                    [gsigf, gdf1, gdf2] = ...
                        modelcomp(sdmmatrix(:, sdmconf1:end), sdmmatrix(:, end), vtcdata, 1);

                    % divide, then subtract (mask)
                    gsigf = min(2, gsigf ./ mean(gsigf));
                    gsigf(isinf(gsigf) | isnan(gsigf)) = 0;
                    gsigf = gsigf ./ (sum(gsigf) / numel(gsigf));

                    % add global signal
                    gsig = sum(wo .* vtcdata .* (ones(nvtctp, 1) * gsigf(:)'), 2) ./ ...
                        sum(wo, 2);
                    sdmmatrix = [sdmmatrix(:, 1:end-1), ztrans(gsig), sdmmatrix(:, end)];
                end
            end

            % then adapt data
            vtcdata = wo .* vtcdata + (1 - wo) .* cc;

            % then second pass
            if opts.naive
                [betas, iXX, cc] = calcbetas(sdmmatrix(:, sdmconf1:end), vtcdata, 1);
            else
                [betas, iXX, cc] = calcbetas(sdmmatrix, vtcdata, 1);
            end
            w = vtcdata - cc;
            ws = opts.robtune .* max(std(w), sqrt(eps));
            w = repmat((1 ./ ws), nvtctp, 1) .* w;
            w = (abs(w) < 1) .* (1 - w .^ 2) .^ 2;
            vtcdata = w .* vtcdata + (1 - w) .* cc;

        % remove global signal
        elseif opts.remgsig

            % run F-test
            if opts.remgsmod
                gpidx = setdiff((1:size(sdmmatrix, 2))', multimatch(conds, sdmconds));
                [gsigf, gdf1, gdf2] = modelcomp(sdmmatrix, sdmmatrix(:, gpidx), vtcdata, 1);
                gsfthresh = sdist('finv', opts.gpthresh, gdf1, gdf2, true);
                gsig = mean(vtcdata(:, gsigf <= gsfthresh), 2);
                if ~any(isnan(gsig))
                    sdmmatrix = [sdmmatrix(:, 1:end-1), ztrans(gsig), sdmmatrix(:, end)];
                end
            else
                [gsigf, gdf1, gdf2] = ...
                    modelcomp(sdmmatrix(:, sdmconf1:end), sdmmatrix(:, end), vtcdata, 1);
                gsfthresh = sdist('finv', opts.gpthresh, gdf1, gdf2, true);
                gsigf = max(0, (sqrt(gsigf) ./ sqrt(gsfthresh)) - 1);
                gsigf(isinf(gsigf) | isnan(gsigf)) = 0;
                if opts.robust
                    gsig = sum(wo .* vtcdata .* (ones(nvtctp, 1) * gsigf(:)'), 2) ./ ...
                        (sum(gsigf(:)) .* sum(wo, 2));
                else
                    gsig = sum(vtcdata .* (ones(nvtctp, 1) * gsigf(:)'), 2) ./ ...
                        (sum(gsigf(:)));
                end
                sdmmatrix = [sdmmatrix(:, 1:end-1), ztrans(gsig), sdmmatrix(:, end)];
            end
        end

        % transformation
        if transv == 1
            vtcdata = ztrans(vtcdata);
        elseif transv == 3
            vtcdata = psctrans(vtcdata);
        end

        % final (or first) pass
        betas = calcbetas(sdmmatrix, vtcdata, 1)';

        % for PSC trans
        if transv == 3
            vtcdata = repmat((100 ./ betas(end, :)), nvtctp, 1) .* vtcdata;
            if ~opts.rsngtrial
                betas = calcbetas(sdmmatrix, vtcdata, 1)';
            end
        end

        % regular weights (to account for sampling beyond data limits)
        tw = ones(nvtctp, 1);

        % iterate over conditions
        for cc = 1:dimc

            % no onsets, continue
            if isempty(ons{cc})
                continue;
            end
            o = 1 + ons{cc}(:, 1) ./ vtctr;
            no = size(o, 1);
            if no == 0
                continue;
            end

            % VTCData indices
            tci = 1 + dimtc * dima * (cc - 1);
            tce = tci + dima - 1;
            sci = tci + dima;
            sce = tce + dima;
            wci = sci + dima;
            wce = sce + dima;

            % which predictor
            pidx = find(strcmp(sdmconds, conds{cc}));
            if isempty(pidx)
                consets = consets + no;
                continue;
            end
            onscount(cc) = onscount(cc) + no;

            % process condition
            if ~isempty(pbar)
                xprogress(pbar, consets, sprintf('Processing condition %s...', conds{cc}));
            end

            % for condition-wide processing
            if ~opts.rsngtrial

                % remove residual variance
                usebets = 1:size(betas, 1);
                usebets([pidx, end]) = [];
                if opts.naive
                    vtccorr = vtcdata;
                else
                    vtccorr = vtcdata - sdmmatrix(:, usebets) * betas(usebets, :);
                end

                % smoothing
                if numel(smk) ~= 1
                    vtccorr = flexinterpn(vtccorr, [Inf, Inf; 1, 1; 1, 1; vtccsz], ...
                        {smk, [0; 1; 0]}, {1, 1});
                end
            end

            % for each onset
            for oc = 1:no

                % for single-trial processing
                if opts.rsngtrial && ...
                   ~opts.naive

                    % find trial number in single-design matrix
                    sonscount(cc) = sonscount(cc) + 1;
                    tidx = find(~cellfun('isempty', regexpi(ssdmconds, ...
                        sprintf('^%s_0*%d$', conds{cc}, sonscount(cc)))));
                    if isempty(tidx) && ...
                        no == 1
                        tidx = find(strcmpi(ssdmconds, conds{cc}));
                    end
                    if isempty(tidx)
                        if ~isempty(pbar)
                            closebar(pbar);
                        end
                        error( ...
                            'xff:InternalError', ...
                            'Error locating single-trial regressor for %s:%d.', ...
                            conds{cc}, oc ...
                        );
                    end

                    % first, take the original design matrix
                    rsdmmatrix = [sdmmatrix, zeros(size(sdmmatrix, 1), 1)];

                    % then remove influence of single trial
                    rsdmmatrix(:, pidx) = rsdmmatrix(:, pidx) - ssdmmatrix(:, tidx);

                    % and add this as additional regressor as last
                    rsdmmatrix(:, end) = ssdmmatrix(:, tidx);

                    % only one onset -> remove original regressor
                    if no == 1
                        rsdmmatrix(:, pidx) = [];
                    end

                    % still remove (almost) empty regressors
                    rsdmmatrixs = (sum(abs(rsdmmatrix), 1) < 1e-6);
                    if rsdmmatrixs(end)
                        continue;
                    end
                    rsdmmatrix(:, rsdmmatrixs) = [];

                    % then regress
                    betas = calcbetas(rsdmmatrix, vtcdata, 1)';
                    vtccorr = vtcdata - rsdmmatrix(:, 1:end-1) * betas(1:end-1, :);

                    % smoothing
                    if numel(smk) ~= 1
                        vtccorr = flexinterpn(vtccorr, ...
                            [Inf, Inf; 1, 1; 1, 1; vtccsz], ...
                            {smk, [0; 1; 0]}, {1, 1});
                    end

                % fully-naive
                elseif opts.naive

                    % just copy data
                    vtccorr = vtcdata;

                    % smoothing
                    if numel(smk) ~= 1
                        vtccorr = flexinterpn(vtccorr, ...
                            [Inf, Inf; 1, 1; 1, 1; vtccsz], ...
                            {smk, [0; 1; 0]}, {1, 1});
                    end
                end

                % sample baseline window
                obwinmin = o(oc) + bwinmin / vtctr;
                obwinmax = o(oc) + bwinmax / vtctr;
                basewin = [Inf, Inf; obwinmin, 1; obwinstep, 1; obwinmax, vtccsz(2)];
                obwin = meannoinfnan(flexinterpn(vtccorr, basewin, ipk{:}), 1, true);

                % sample onset window
                awinmin = o(oc) + avgwinmin / vtctr;
                awinmax = o(oc) + avgwinmax / vtctr;
                awin = [Inf, Inf; awinmin, 1; awinstep, 1; awinmax, vtccsz(2)];
                avgwin = flexinterpn(vtccorr, awin, ipk{:}) - ...
                    repmat(obwin, dima, 1);
                tcwin = max(0, flexinterpn(tw, awin(:, 1), ipk{:}));

                % add to VTCData
                if opts.robust
                    wdata = max(0, flexinterpn(wo, awin, ipk{:}));
                    vtcc.VTCData(tci:tce, mask) = vtcc.VTCData(tci:tce, mask) + wdata .* avgwin;
                    vtcc.VTCData(sci:sce, mask) = vtcc.VTCData(sci:sce, mask) + wdata .* avgwin .* avgwin;
                    vtcc.VTCData(wci:wce, mask) = vtcc.VTCData(wci:wce, mask) + wdata;
                    tcow(wci:wce) = 1;
                else
                    wdata = repmat(tcwin, 1, vtccsz(2));
                    vtcc.VTCData(tci:tce, mask) = vtcc.VTCData(tci:tce, mask) + wdata .* avgwin;
                    vtcc.VTCData(sci:sce, mask) = vtcc.VTCData(sci:sce, mask) + wdata .* avgwin .* avgwin;
                end

                % add normative weights
                tcow(tci:tce) = tcow(tci:tce) + tcwin;
                tcow(sci:sce) = tcow(sci:sce) + tcwin;

                % update counter
                if ~isempty(pbar)
                    consets = consets + 1;
                    xprogress(pbar, consets, sprintf( ...
                        'Added data from onset %d of %d (volumes %.2f++).', ...
                        consets, nonsets, o(oc)));
                end
            end % onsets

            % keep track of removed onsets for single-trial designs
            if opts.rsngtrial
                sonscount(cc) = sonscount(cc) + onsrem(vtci, cc);
            end

        end % conditions
    end % runs

    % store number of onsets as well as base weighting
    vtcc.RunTimeVars.NrOfConditionOnsets = onscount;
    vtcc.RunTimeVars.TCOnsetWeights = single(tcow);

    % compute required summary measures
    for cc = 1:dimc

        % indices (time course indices, SD/SE indices, weight indices)
        tci = 1 + dimtc * dima * (cc - 1);
        tce = tci + dima - 1;
        sci = tci + dima;
        sce = tce + dima;
        wci = sci + dima;
        wce = sce + dima;

        % for robust estimate
        if opts.robust

            % weighted mean
            wsum = vtcc.VTCData(tci:tce, mask);
            vtcc.VTCData(tci:tce, mask) = wsum ./ vtcc.VTCData(wci:wce, mask);

            % and STD
            vtcc.VTCData(sci:sce, mask) = sqrt(...
                (vtcc.VTCData(sci:sce, mask) - ...
                ((wsum .* wsum) ./ vtcc.VTCData(wci:wce, mask))) ./ ...
                max(0, (vtcc.VTCData(wci:wce, mask) - 1)));

            % divide weights
            vtcc.VTCData(wci:wce, mask) = ...
                (1 / onscount(cc)) .* vtcc.VTCData(wci:wce, mask);

        % non-robust
        else

            % compute mean
            wsum = vtcc.VTCData(tci:tce, mask);
            vtcc.VTCData(tci:tce, mask) = ((1 ./ tcow(tci:tce)) * osmask) .* wsum;

            % and STD
            vtcc.VTCData(sci:sce, mask) = ...
                sqrt(((1 ./ ((tcow(sci:sce) - 1))) * osmask) .* ...
                (vtcc.VTCData(sci:sce, mask) - ...
                (((1 ./ tcow(sci:sce)) * osmask) .* wsum .* wsum)));
        end

        % then adapt onset weights
        vtcc.RunTimeVars.TCOnsetWeights(tci:sce) = ...
            (1 / onscount(cc)) .* vtcc.RunTimeVars.TCOnsetWeights(tci:sce);

        % adapt Map field
        vtcc.RunTimeVars.Map(cc).Name = vtcc.RunTimeVars.ConditionNames{cc};
        vtcc.RunTimeVars.Map(cc).LowerThreshold = ...
            vtcc.RunTimeVars.ConditionThresholds(cc, 1, 1);
        vtcc.RunTimeVars.Map(cc).UpperThreshold = ...
            vtcc.RunTimeVars.ConditionThresholds(cc, 1, 2);
        vtcc.RunTimeVars.Map(cc).RGBLowerThreshPos = ...
            double(vtcc.RunTimeVars.ConditionColors(cc, 1:3));
        vtcc.RunTimeVars.Map(cc).RGBUpperThreshPos = ...
            double(vtcc.RunTimeVars.ConditionColors(cc, 5:7));
        vtcc.RunTimeVars.Map(cc).RGBLowerThreshNeg = ...
            double(vtcc.RunTimeVars.ConditionColors(cc, 9:11));
        vtcc.RunTimeVars.Map(cc).RGBUpperThreshNeg = ...
            double(vtcc.RunTimeVars.ConditionColors(cc, 13:15));
        vtcc.RunTimeVars.Map(cc).UseRGBColor = 1;
        vtcc.RunTimeVars.Map(cc).DF1 = onscount(cc) - 1;
    end

    % store VTC
    try
        if ~isempty(pbar)
            xprogress(pbar, consets, sprintf('Saving %s_%s_%sAVG.vtc...', ...
                 opts.subsel{sc}, mdmfile, condstr), 'visible');
        end
        vtcc.RunTimeVars.Discard = [];
        xffsetcont(vtc.L, vtcc);

        % update scaling window
        aft_SetScalingWindow(vtc, [-2, 2], true);

        % then save (+RunTimeVars)
        aft_SaveAs(vtc, ovtcs{sc});
        aft_SaveRunTimeVars(vtc);
    catch ne_eo;
        if ~isempty(pbar)
            closebar(pbar);
        end
        clearxffobjects(vtco);
        aft_ClearObject(vtc);
        rethrow(ne_eo);
    end
end

% close bar
if ~isempty(pbar)
    closebar(pbar);
end

% clear interim data
clearxffobjects(vtco);
xffclear(vtc.L);

% set in MDM file
bsc.C.RunTimeVars.AutoSave = true;
bsc.C.RunTimeVars.VTCCondAveraging = {conds, opts, ovtcs};
xffsetscont(hfile.L, bsc);
if ~isempty(bsc.F)
    try
        aft_SaveRunTimeVars(hfile);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end
