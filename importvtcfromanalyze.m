function vtc = importvtcfromanalyze(imgs, bbox, res, imeth, trans, opts)
% importvtcfromanalyze  - import a VTC from Analzye files
%
% FORMAT:       vtc = importvtcfromanalyze(imgs [, bb [, res [, im [, t [, o]]]]])
%
% Input fields:
%
%       imgs        cell array with HDR filenames for xff
%       bb          optional 2x3 bounding box (default: MNI covering box)
%                   must be given in BrainVoyager's axes order!!
%       res         optional resolution (default: 3)
%       imeth       interpolation 'cubic', 'lanczos3', {'linear'}, 'nearest'
%       t           4x4 transformation matrix (also stored in RunTimeVars)
%       o           additional options
%        .raw       store raw matrix and apply transformation
%        .snmat     spatial-normalization MAT content
%
% Output fields:
%
%       vtc         created VTC object
%
% Note: this function requires the MEX file flexinterpn.

% Version:  v0.9d
% Build:    14051909
% Date:     May-19 2014, 9:54 AM EST
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

% argument check
if nargin < 1 || ...
   ~iscell(imgs) || ...
    numel(imgs) < 1 || ...
    isempty(imgs{1}) || ...
   (~ischar(imgs{1}) && ...
    (numel(imgs{1}) ~= 1 || ...
     ~isxff(imgs{1}, {'hdr', 'head'})))
    error( ...
        'neuroelf:BadArgument', ...
        'Bad input argument.' ...
    );
end

% go on with loading images and sampling VTC data
imgs = imgs(:);
nimg = numel(imgs);
hclr = true(1, nimg);
himg = cell(1, nimg);
hrtv = repmat({struct}, 1, nimg);
htyp = himg;
vimg = zeros(20, nimg);
nvol = ones(1, nimg);
try
    pbar = xprogress;
    xprogress(pbar, 'setposition', [80, 200, 640, 36]);
    xprogress(pbar, 'settitle', 'Converting Analyze to VTC...');
    xprogress(pbar, 0, 'Checking HDRs...', 'visible', 0, 8 * nimg);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    pbar = [];
end

% disable unwindstack for now...
uws = xff(0, 'unwindstack');
xff(0, 'unwindstack', false);
rps = [];
try
    for ic = 1:nimg
        if isempty(imgs{ic}) || ...
           (~ischar(imgs{ic}) && ...
            (numel(imgs{ic}) ~= 1 || ...
             ~isxff(imgs{ic}, {'hdr', 'head'})))
            error('BAD_IMAGENAME');
        end
        if ischar(imgs{ic})
            imgs{ic} = strrep(strrep(imgs{ic}, '.img', '.hdr'), '.IMG', '.HDR');
            himg{ic} = xff(imgs{ic});
        else
            himg(ic) = imgs(ic);
            hclr(ic) = false;
            hrtv{ic} = himg{ic}.RunTimeVars;
        end
        if numel(himg{ic}) ~= 1 ||...
           ~isxff(himg{ic}, {'hdr', 'head'})
            error('BAD_IMAGECONT');
        end
        htyp{ic} = himg{ic}.Filetype;
        icf = himg{ic}.CoordinateFrame;
        vimg(:, ic) = [icf.Trf(:); icf.Dimensions(:)];
        if strcmpi(htyp{ic}, 'hdr')
            nvol(ic) = size(himg{ic}.VoxelData, 4);
        else
            nvol(ic) = numel(himg{ic}.Brick);
        end
        if ic == 1
            [hpath, hfile] = fileparts(himg{1}.FilenameOnDisk);
            frfile = '';
            if numel(hfile) > 2 && ...
               (hfile(1) == 'w' || ...
                strcmp(hfile(1:2), 'sw'))
                rfile = regexprep(hfile, '^s?wr?', '');
                if exist([hpath '/rp_' rfile '.txt'], 'file')
                    frfile = [hpath '/rp_' rfile '.txt'];
                elseif exist([hpath '/rp-' rfile '.txt'], 'file')
                    frfile = [hpath '/rp-' rfile '.txt'];
                end
            elseif numel(hfile) > 1 && ...
                hfile(1) == 'r'
                if exist([hpath '/rp_' hfile(2:end) '.txt'], 'file')
                    frfile = [hpath '/rp_' hfile(2:end) '.txt'];
                elseif exist([hpath '/rp-' hfile(2:end) '.txt'], 'file')
                    frfile = [hpath '/rp-' hfile(2:end) '.txt'];
                end
            end
            if ~isempty(frfile)
                try
                    rps = load(frfile);
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
        end
        if ~isempty(pbar)
            xprogress(pbar, ic);
        end
    end
    if any(any(diff(vimg, 1, 2)))
        warning( ...
            'neuroelf:BadArgument', ...
            'Spatial orientation/dimensions mismatch between images.' ...
        );
    end
catch ne_eo;
    clearxffobjects(himg(hclr));
    xff(0, 'unwindstack', uws);
    if ~isempty(pbar)
        closebar(pbar);
    end
    error( ...
        'neuroelf:BadArgument', ...
        'Error loading image %d (%s).', ...
        ic, ne_eo.message ...
    );
end

% checking other arguments
sfn = himg{1}.FilenameOnDisk;
if nargin < 2 || ...
   ~isa(bbox, 'double') || ...
   ~isequal(size(bbox), [2, 3]) || ...
    any(isnan(bbox(:)) | bbox(:) < 0 | bbox(:) > 255)
    bbox = [];
else
    bbox = round(bbox);
end
if nargin < 3 || ...
   ~isa(res, 'double') || ...
    numel(res) ~= 1 || ...
   ~any((1:15) == res)
    res = 3;
end
if nargin < 4 || ...
   ~ischar(imeth) || ...
   ~any(strcmpi(imeth(:)', {'cubic', 'lanczos3', 'linear', 'nearest'}))
    imeth = 'linear';
else
    imeth = lower(imeth(:)');
end
if nargin < 5 || ...
   ~isa(trans, 'double') || ...
   ~isequal(size(trans), [4, 4]) || ...
    any(isinf(trans(:)) | isnan(trans(:))) || ...
    any(trans(4, :) ~= [0, 0, 0, 1])
    trans = [];
end
if nargin < 6 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'raw') || ...
   ~islogical(opts.raw) || ...
    numel(opts.raw) ~= 1
    opts.raw = false;
end
if ~isfield(opts, 'snmat') || ...
    isempty(opts.snmat) || ...
   (~ischar(opts.snmat) && ...
    ~isstruct(opts.snmat))
    opts.snmat = [];
end
if ischar(opts.snmat)
    try
        opts.snmat = load(opts.snmat);
    catch ne_eo;
        clearxffobjects(himg(hclr));
        xff(0, 'unwindstack', uws);
        if ~isempty(pbar)
            closebar(pbar);
        end
        rethrow(ne_eo);
    end
end
if isstruct(opts.snmat)
    if numel(opts.snmat) ~= 1 || ...
       ~isfield(opts.snmat, 'VG') || ...
       ~isstruct(opts.snmat.VG) || ...
        isempty(opts.snmat.VG) || ...
       ~isfield(opts.snmat.VG, 'dim') || ...
       ~isfield(opts.snmat.VG, 'mat') || ...
       ~isfield(opts.snmat, 'VF') || ...
       ~isstruct(opts.snmat.VF) || ...
        numel(opts.snmat.VF) ~= 1 || ...
       ~isfield(opts.snmat.VF, 'dim') || ...
       ~isfield(opts.snmat.VF, 'mat') || ...
       ~isfield(opts.snmat, 'Tr') || ...
       ~isa(opts.snmat.Tr, 'double') || ...
        ndims(opts.snmat.Tr) ~= 4 || ...
        any(isinf(opts.snmat.Tr(:)) | isnan(opts.snmat.Tr(:))) || ...
       ~isfield(opts.snmat, 'Affine') || ...
       ~isa(opts.snmat.Affine, 'double') || ...
       ~isequal(size(opts.snmat.Affine), [4, 4]) || ...
        any(isinf(opts.snmat.Affine(:)) | isnan(opts.snmat.Affine(:))) || ...
        any(opts.snmat.Affine(4, :) ~= [0, 0, 0, 1])
        clearxffobjects(himg(hclr));
        xff(0, 'unwindstack', uws);
        if ~isempty(pbar)
            closebar(pbar);
        end
        error( ...
            'neuroelf:BadArgument', ...
            'SPM-based SN-mat structure not correctly specified.' ...
        );
    end
end

% get global setting to figure out DataType/FileVersion
global xffconf;
dtype = xffconf.settings.DataTypes.VTC;

% guess scaling
if dtype == 1
    if strcmpi(htyp{1}, 'hdr')
        if istransio(himg{1}.VoxelData)
            vdm = minmaxmean(himg{1}.VoxelData(:, :, :, :));
        else
            vdm = minmaxmean(himg{1}.VoxelData);
        end
    else
        vdm = minmaxmean(himg{1}.Brick(1).Data(:, :, :));
    end
    vdm = vdm(2);
    if vdm > 16384
        vdf = 16384 / double(vdm);
    else
        vdf = [];
    end
else
    vdf = [];
end

% create VTC
vtc = bless(xff('new:vtc'), 1);
vtc.DataType = dtype;
if dtype > 1
    vtc.FileVersion = 3;
end
vtc.NameOfSourceFMR = sfn;
vtc.Resolution = res;

% raw storage
if opts.raw

    % get first volume
    if strcmpi(htyp{1}, 'hdr')
        vtd = shiftdim(single(himg{1}.VoxelData(:, :, :, 1)), -1);
    else
        vtd = shiftdim(single(himg{1}.Brick(1).Data(:, :, :)), -1);
    end
    if dtype == 1
        vtd = uint16(round(vtd));
    end

    % create VTC data
    vtd(sum(nvol), 1, 1, 1) = 0;
    vts = size(vtd);
    vtf = cell(vts(1), 1);
    vtcf = zeros(4, 4, vts(1));

    % storing
    if ~isempty(pbar)
        xprogress(pbar, nimg, 'Importing images...');
    end
    icc = 1;
    dsc = [];
    for ic = 1:nimg
        himgf = himg{ic}.FilenameOnDisk;
        if isfield(hrtv{ic}, 'Discard')
            dsc = [dsc(:); hrtv{ic}.Discard(:) + sum(nvol(1:ic-1))];
        end
        for vc = 1:nvol(ic)
            try
                crdf = himg{ic}.CoordinateFrame(vc);
                vtcf(:, :, icc) = crdf.Trf;
                if strcmpi(htyp{ic}, 'hdr')
                    hy = shiftdim(single(himg{ic}.VoxelData(:, :, :, vc)), -1);
                else
                    hy = shiftdim(single(himg{ic}.Brick(vc).Data(:, :, :)), -1);
                end
                if ~isempty(vdf)
                    hy = vdf * hy;
                end
                hy(isinf(hy) | isnan(hy)) = 0;
                if ~isempty(pbar)
                    xprogress(pbar, nimg + 7 * ((ic - 1) + vc / nvol(ic)));
                end
                vtd(icc, :, :, :) = hy;
                if nvol(ic) > 1
                    vtf{icc} = sprintf('%s,%d', himgf, vc);
                else
                    vtf{icc} = himgf;
                end
                icc = icc + 1;
            catch ne_eo;
                clearxffobjects(himg(hclr));
                xff(0, 'unwindstack', uws);
                if ~isempty(pbar)
                    closebar(pbar);
                end
                vtc.ClearObject;
                error( ...
                    'neuroelf:InternalError', ...
                    'Error storing data of volume %d (%s).', ...
                    ic, ne_eo.message ...
                );
            end
        end
        if hclr(ic)
            himg{ic}.ClearObject;
        end
        himg{ic} = [];
    end

    % store simplified frame
    if all(all(abs(diff(vtcf, 1, 3)) <= sqrt(eps)))
        vtcf = vtcf(:, :, 1);
    elseif isstruct(opts.snmat)
        clearxffobjects(himg(hclr));
        xff(0, 'unwindstack', uws);
        if ~isempty(pbar)
            closebar(pbar);
        end
        vtc.ClearObject;
        error( ...
            'neuroelf:InvalidCombination', ...
            'SPM-based SN-mat requires unique spatial orientation.' ...
        );
    end

    % VTC settings
    xyzstart = max(0, 128 - (res / 2) .* vts(2:4));
    vtc.XStart = xyzstart(1);
    vtc.XEnd = xyzstart(1) + res * vts(2);
    vtc.YStart = xyzstart(2);
    vtc.YEnd = xyzstart(2) + res * vts(3);
    vtc.ZStart = xyzstart(3);
    vtc.ZEnd = xyzstart(3) + res * vts(4);

% re-sampling
else

    % try to sample first vol (check)
    try
        [vtd, obox] = himg{1}.SampleBVBox( ...
            struct('BBox', bbox, 'ResXYZ', res), 1, imeth, trans);
        if dtype == 1
            vtd = shiftdim(uint16(round(vtd)), -1);
        else
            vtd = shiftdim(single(vtd), -1);
        end
    catch ne_eo;
        clearxffobjects(himg(hclr));
        xff(0, 'unwindstack', uws);
        rethrow(ne_eo);
    end

    % create VTC data
    vtd(sum(nvol), 1, 1, 1) = 0;
    vts = size(vtd);
    vtf = cell(vts(1), 1);

    % sampling
    if ~isempty(pbar)
        xprogress(pbar, nimg, 'Sampling images...');
    end
    icc = 1;
    dsc = [];
    for ic = 1:nimg
        himgf = himg{ic}.FilenameOnDisk;
        if isfield(hrtv{ic}, 'Discard')
            dsc = [dsc(:); hrtv{ic}.Discard(:) + sum(nvol(1:ic-1))];
        end
        for vc = 1:nvol(ic)
            try
                hy = shiftdim(himg{ic}.SampleBVBox( ...
                    struct('BBox', bbox, 'ResXYZ', res), vc, imeth, trans), -1);
                if ~isempty(vdf)
                    hy = vdf * hy;
                end
                if ~isempty(pbar)
                    xprogress(pbar, nimg + 7 * ((ic - 1) + vc / nvol(ic)));
                end
                vtd(icc, :, :, :) = hy;
                if nvol(ic) > 1
                    vtf{icc} = sprintf('%s,%d', himgf, vc);
                else
                    vtf{icc} = himgf;
                end
                icc = icc + 1;
            catch ne_eo;
                clearxffobjects(himg(hclr));
                xff(0, 'unwindstack', uws);
                if ~isempty(pbar)
                    closebar(pbar);
                end
                vtc.ClearObject;
                error( ...
                    'neuroelf:InternalError', ...
                    'Error sampling data of volume %d (%s).', ...
                    ic, ne_eo.message ...
                );
            end
        end
        if hclr(ic)
            himg{ic}.ClearObject;
        end
        himg{ic} = [];
    end

    % VTC settings
    vtc.XStart = obox.BBox(1, 1);
    vtc.XEnd = obox.BBox(1, 1) + res * vts(2);
    vtc.YStart = obox.BBox(1, 2);
    vtc.YEnd = obox.BBox(1, 2) + res * vts(3);
    vtc.ZStart = obox.BBox(1, 3);
    vtc.ZEnd = obox.BBox(1, 3) + res * vts(4);
end

% store data
vtc.VTCData = vtd;
vtc.NrOfVolumes = size(vtc.VTCData, 1);

% auto-mask
mdata = lsqueeze(mean(vtc.VTCData));
mmask = mdata > (0.5 .* mean(mdata));

% additional masks
if all([44, 242, 38, 194, 44, 212] == ...
        [vtc.XStart, vtc.XEnd, vtc.YStart, vtc.YEnd, vtc.ZStart, vtc.ZEnd]) && ...
    any([2, 3] == res)
    mskfiles = findfiles(neuroelf_path('masks'), sprintf('*%dmm.msk', res));
    mskfiles = mskfiles(:);
    for mc = 1:size(mskfiles, 1)
        msko = xff(mskfiles{mc, 1});
        mskfiles{mc, 1} = find(msko.Mask(:));
        mskfiles{mc, 2} = ztrans(meannoinfnan(vtc.VTCData(:, mskfiles{mc, 1}), 2));
        msko.ClearObject;
    end
else
    mskfiles = {};
end

% add RunTimeVars
vtc.RunTimeVars.AutoSave = true;
vtc.RunTimeVars.DVARS = {find(mmask(:)), ...
    sqrt(mean(diff(psctrans(vtc.VTCData(:, mmask))) .^ 2, 2))};
vtc.RunTimeVars.Discard = dsc(:);
if ~isempty(mskfiles)
    vtc.RunTimeVars.GlobSigs = mskfiles;
end
if size(rps, 1) == vtc.NrOfVolumes
    vtc.RunTimeVars.MotionParameters = rps;
    vtc.RunTimeVars.MPFD = sum(abs(diff([rps(:, 1:3), 50 .* rps(:, 4:6)])), 2);
end
vtc.RunTimeVars.SourceFiles = vtf;
if isstruct(opts.snmat)
    vtc.RunTimeVars.SPMsn = opts.snmat;
end
if opts.raw
    vtcbb = vtc.BoundingBox;
    for d3c = 1:size(vtcf, 3)
        vtcf(:, :, d3c) = vtcf(:, :, d3c) * vtcbb.QuatT2B;
    end
    vtc.RunTimeVars.TrfPlus = vtcf;
end

% close bar
if ~isempty(pbar)
    closebar(pbar);
end

% reset unwindstack flag
xff(0, 'unwindstack', uws);
