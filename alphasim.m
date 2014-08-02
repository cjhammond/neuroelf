function [varargout] = alphasim(ddim, opts)
% alphasim  - simulate noise data to estimate cluster threshold
%
% FORMAT:       [at = ] alphasim(ddim [, opts])
%
% Input fields:
%
%       ddim        data dimension (1x3 integer values)
%       opts        optional settings
%        .clconn    connectivity of clusters, ('face', {'edge'}, 'vertex')
%        .conj      conjunction simulation (1x1 double, number of maps)
%        .fftconv   boolean flag, use FFT convolution (default: true)
%        .fwhm      FWHM kernel sizes (default: [2, 2, 2])
%        .mask      boolean mask (size must be == ddim!, default: none)
%        .niter     number of iterations, default: 1000
%        .pbar      either xprogress or xfigure:XProgress object
%        .regmaps   regression maps (e.g. betas, contrasts)
%        .regmodel  regression model (all-1s column will be complemented)
%        .regmodsc  simple regression, conjunction of multiple regressors
%        .regrank   rank-transform data before useing regression
%        .srf       optional surface (perform surface-based simulation)
%        .srfsmp    surface sampling (from, step, to, along normals,
%                   default: [-3, 1, 1])
%        .srftrf    transformation required to sample surface coordinates
%                   derived from bvcoordconv
%        .stype     1x1 or 1x2 statistics type, default: [1, 2], meaning
%                   that one tail of a two-tailed statistic is taken
%                   a single 1 is one tail of a one-tailed statistic (F)
%                   a single 2 is both tails of a two-tailed statistic (t)
%        .tdf       simulate actual t-stats (for 2-tailed stats only)
%        .thr       applied (raw) threshold(s), default: p<0.001
%        .zshift    shift normal distribution by this Z value (default: 0)
%
% Output fields:
%
%       at          optional output table
%
% Note: other than AFNI's AlphaSim, the data is considered to be
%       iso-voxel for the default kernel, but that can be altered
%       accordingly by changing the kernel!
%
%       to simulate specific regression results, both options, .regmaps
%       .regmodel must be set; if only .regmaps is given, random numbers
%       (using randn) will be generated instead of permuting the predictor

% Version:  v0.9d
% Build:    14072317
% Date:     Jul-23 2014, 5:49 PM EST
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
   ~isa(ddim, 'double') || ...
    numel(ddim) ~= 3 || ...
    any(isinf(ddim) | isnan(ddim) | ddim < 1 | ddim > 256)
    error( ...
        'neuroelf:BadArgument', ...
        'Missing or invalid ddim argument.' ...
    );
else
    ddim = round(ddim);
end
if nargin < 2 || ...
    isempty(opts)
    opts = struct;
elseif ~isstruct(opts) || ...
    numel(opts) ~= 1
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts argument.' ...
    );
end
if ~isfield(opts, 'clconn')
    opts.clconn = 'edge';
elseif ~ischar(opts.clconn) || ...
   ~any(strcmpi(opts.clconn(:)', {'edge', 'face', 'vertex'}))
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.clconn field.' ...
    );
else
    opts.clconn = lower(opts.clconn(:)');
end
switch (opts.clconn(1))
    case {'e'}
        clconn = 2;
    case {'f'}
        clconn = 1;
    otherwise
        clconn = 3;
end
if ~isfield(opts, 'conj')
    nconj = 1;
elseif ~isa(opts.conj, 'double') || ...
    numel(opts.conj) ~= 1 || ...
    isinf(opts.conj) || ...
    isnan(opts.conj) || ...
    opts.conj < 1 || ...
    opts.conj > 5
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.conj field.' ...
    );
else
    nconj = floor(opts.conj);
end
if ~isfield(opts, 'fftconv')
    opts.fftconv = true;
elseif ~islogical(opts.fftconv) || ...
    numel(opts.fftconv) ~= 1
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.fftconv field.' ...
    );
end
fftconv = opts.fftconv;
if ~isfield(opts, 'fwhm')
    opts.fwhm = [2, 2, 2];
elseif ~isa(opts.fwhm, 'double') || ...
    numel(opts.fwhm) ~= 3 || ...
    any(isinf(opts.fwhm) | isnan(opts.fwhm) | opts.fwhm <= 0 | opts.fwhm(:)' > ddim)
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.fwhm field.' ...
    );
else
    opts.fwhm = opts.fwhm(:)';
end
kcell = { ...
    smoothkern(opts.fwhm(1), 0), ...
    smoothkern(opts.fwhm(2), 0), ...
    smoothkern(opts.fwhm(3), 0)};
kern = {zeros(numel(kcell{1}), numel(kcell{2}), numel(kcell{3}))};
kern = kern(1, [1, 1, 1]);
kern{1}(:, (numel(kcell{2}) + 1) / 2, (numel(kcell{3}) + 1) / 2) = kcell{1};
kern{2}((numel(kcell{1}) + 1) / 2, :, (numel(kcell{3}) + 1) / 2) = kcell{2};
kern{3}((numel(kcell{2}) + 1) / 2, (numel(kcell{2}) + 1) / 2, :) = kcell{3};
if ~isfield(opts, 'mask')
    opts.mask = ([] > 0);
elseif ~islogical(opts.mask) || ...
   ~isequal(size(opts.mask), ddim)
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.mask field.' ...
    );
end
mask = opts.mask;
if ~isempty(mask)
    summask = sum(mask(:));
    if summask == 0
        error( ...
            'neuroelf:BadArgument', ...
            'Invalid opts.mask field.' ...
        );
    end
    msktxt = sprintf(' in %d-voxel mask', summask);
else
    msktxt = '';
end
if ~isfield(opts, 'zshift')
    zshift = 0;
elseif ~isa(opts.zshift, 'double') || ...
    numel(opts.zshift) ~= 1 || ...
    isinf(opts.zshift) || ...
    isnan(opts.zshift)
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.zshift field.' ...
    );
else
    zshift = opts.zshift;
end
if ~isfield(opts, 'niter')
    niter = 1000;
elseif ~isa(opts.niter, 'double') || ...
    numel(opts.niter) ~= 1 || ...
    isinf(opts.niter) || ...
    isnan(opts.niter) || ...
    opts.niter < 1 || ...
    opts.niter > 1e6
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.niter field.' ...
    );
else
    niter = round(opts.niter);
end
if ~isfield(opts, 'pbar') || ...
    numel(opts.pbar) ~= 1 || ...
   ~any(strcmpi(class(opts.pbar), {'xfigure', 'xprogress'}))
    opts.pbar = [];
end
if ~isfield(opts, 'regmaps') || ...
   ~isnumeric(opts.regmaps) || ...
    ndims(opts.regmaps) ~= 4 || ...
    size(opts.regmaps, 4) < 3 || ...
    isempty(opts.regmaps)
    opts.regmaps = [];
    regnsub = 0;
else
    opts.ddim = size(opts.regmaps);
    regnsub = opts.ddim(4);
    regnsfc = sqrt((regnsub - 1) / (regnsub - 2));
    opts.ddim(4) = [];
    opts.regmaps = reshape(opts.regmaps, prod(opts.ddim), regnsub)';
end
if ~isfield(opts, 'regmodel') || ...
   ~isa(opts.regmodel, 'double') || ...
    size(opts.regmodel, 1) ~= regnsub || ...
    any(isinf(opts.regmodel(:)) | isnan(opts.regmodel(:))) || ...
    any(varc(opts.regmodel, 1) == 0)
    opts.regmodel = [];
else
    opts.regmodel = ztrans(opts.regmodel);
end
if ~isfield(opts, 'regmodsc') || ...
   ~islogical(opts.regmodsc) || ...
    numel(opts.regmodsc) ~= 1
    opts.regmodsc = false;
end
if ~isfield(opts, 'regrank') || ...
   ~islogical(opts.regrank) || ...
    numel(opts.regrank) ~= 1
    opts.regrank = false;
end
if ~isempty(opts.regmodel) && ...
    opts.regrank
    opts.regmodel = ztrans(ranktrans(opts.regmodel, 1));
end
if ~isfield(opts, 'srf') || ...
    numel(opts.srf) ~= 1 || ...
   ~isxff(opts.srf, 'srf')
    opts.srf = [];
end
if ~isfield(opts, 'srfsmp') || ...
   ~isa(opts.srfsmp, 'double') || ...
    numel(opts.srfsmp) ~= 3 || ...
    any(isinf(opts.srfsmp) | isnan(opts.srfsmp) | abs(opts.srfsmp) > 12) || ...
    opts.srfsmp(1) > opts.srfsmp(3) || ...
    isempty(opts.srfsmp(1):opts.srfsmp(2):opts.srfsmp(3))
    opts.srfsmp = -3:1;
else
    opts.srfsmp = opts.srfsmp(1):opts.srfsmp(2):opts.srfsmp(3);
    while numel(opts.srfsmp) > 12
        opts.srfsmp = opts.srfsmp(1:2:end);
    end
end
if ~isempty(opts.srf) && ...
   (~isfield(opts, 'srftrf') || ...
    ~isa(opts.srftrf, 'double') || ...
    ~isequal(size(opts.srftrf), [4, 4]) || ...
     any(isinf(opts.srftrf(:)) | isnan(opts.srftrf(:))) || ...
     any(opts.srftrf(4, 1:3) ~= 0))
    opts.srf = [];
end
if ~isempty(opts.srf)
    tri = opts.srf.TriangleVertex;
    crd = opts.srf.VertexCoordinate;
    try
        [nei, bn, trb] = mesh_trianglestoneighbors(size(crd, 1), tri);
        if ~isempty(bn)
            warning( ...
                'neuroelf:BadSurface', ...
                'Cluster sizes potentially flawed. %d bad neighborhoods!', ...
                numel(bn) ...
            );
        end
        if isempty(nei{end}) || ...
            isempty(trb{end})
            error('BAD_SURFACE');
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        error( ...
            'neuroelf:BadSurface', ...
            'Invalid surface, neighborhood references invalid.' ...
        );
    end
    nei = nei(:, 2);
    nrm = opts.srf.VertexNormal;
    tsa = sqrt(sum((crd(tri(:, 1), :) - crd(tri(:, 2), :)) .^ 2, 2));
    tsb = sqrt(sum((crd(tri(:, 1), :) - crd(tri(:, 3), :)) .^ 2, 2));
    tsc = sqrt(sum((crd(tri(:, 2), :) - crd(tri(:, 3), :)) .^ 2, 2));
    tss = 0.5 * (tsa + tsb + tsc);
    tra = sqrt(tss .* (tss - tsa) .* (tss - tsb) .* (tss - tsc));
    smp = opts.srfsmp;
    if numel(smp) == 1
        opts.srf = crd + smp .* nrm;
    else
        nrm = [lsqueeze(nrm(:, 1) * smp), ...
               lsqueeze(nrm(:, 2) * smp), ...
               lsqueeze(nrm(:, 3) * smp)];
        opts.srf = repmat(crd, numel(smp), 1) + nrm;
    end
    opts.srfsmp = [size(crd, 1), numel(smp)];
    opts.srf(:, 4) = 1;
    opts.srf = opts.srf * opts.srftrf';
    opts.srf(:, 4) = [];
end
srf = opts.srf;
if ~isfield(opts, 'stype') || ...
   ~isa(opts.stype, 'double') || ...
   ~any(numel(opts.stype) == [1, 2]) || ...
    any(isinf(opts.stype) | isnan(opts.stype)) || ...
    any(opts.stype ~= 1 & opts.stype ~= 2)
    opts.stype = [1, 2];
elseif numel(opts.stype) == 1
    opts.stype = opts.stype .* ones(1, 2);
else
    opts.stype = opts.stype(:)';
end
opts.stype(1) = min(opts.stype);
if all(opts.stype == 1)
    stypes = ' (1-tailed statistic)';
elseif opts.stype(1) == 1
    stypes = ' (1 tail of a 2-tailed statistic)';
else
    stypes = ' (2 tails of a 2-tailed statistic)';
end
if ~isfield(opts, 'tdf') || ...
   ~isa(opts.tdf, 'double') || ...
    numel(opts.tdf) ~= 1 || ...
    isinf(opts.tdf) || ...
    isnan(opts.tdf) || ...
    opts.tdf < 1
    opts.tdf = 1;
elseif regnsub ~= 0
    opts.tdf = regnsub;
else
    opts.tdf = min(240, round(opts.tdf));
end
if ~isfield(opts, 'thr')
    thr = 0.001;
elseif ~isa(opts.thr, 'double') || ...
    isempty(opts.thr) || ...
    numel(opts.thr) > 100 || ...
    any(isinf(opts.thr(:)) | isnan(opts.thr(:)) | opts.thr(:) <= 0 | opts.thr(:) > 0.5)
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid opts.thr field.' ...
    );
else
    thr = opts.thr(:)';
end
nthr = numel(thr);

% tails
onet = (opts.stype(2) == 1);
botht = all(opts.stype == 2);

% for simulated datamaps
if regnsub == 0

    % one-tailed statistic
    if onet
        if opts.tdf == 1
            zthr = sdist('norminv', 0.5 .* thr, 0, 1);
        else
            zthr = sdist('tinv', 0.5 .* thr, opts.tdf - 1);
        end
        zthr = zthr .* zthr;

    % two-tailed with both tails
    elseif botht
        if opts.tdf == 1
            zthr = -sdist('norminv', 0.5 .* thr, 0, 1);
        else
            zthr = -sdist('tinv', 0.5 .* thr, opts.tdf - 1);
        end

    % one of a two-tailed
    else
        if opts.tdf == 1
            zthr = -sdist('norminv', thr, 0, 1);
        else
            zthr = -sdist('tinv', thr, opts.tdf - 1);
        end
    end

% for actual data
else

    % both tails
    if botht
        zthr = -sdist('tinv', 0.5 .* thr, regnsub - 2);

    % one of a two-tailed
    else
        zthr = -sdist('tinv', thr, regnsub - 2);
    end
end
scc = 0;

% create counting arrays
cc = zeros(nthr, 1000);
fc = zeros(nthr, niter);

% compute scaling factor
kern = smoothkern(opts.fwhm, 0, false, 'linear');
scf = sum(abs(kern(:))) / sqrt(sum(kern(:) .* kern(:)));

% prepare convolution FFT kernel if required
if isempty(opts.regmaps) && ...
    fftconv
    kdim = size(kern);
    rsd = 1 + round(0.5 .* (kdim - ddim));
    if kdim(1) >= ddim(1)
        kern = kern(rsd(1):rsd(1)+2*(floor(0.5*(ddim(1)-1))), :, :);
    end
    if kdim(2) >= ddim(2)
        kern = kern(:, rsd(2):rsd(2)+2*(floor(0.5*(ddim(2)-1))), :);
    end
    if kdim(3) >= ddim(3)
        kern = kern(:, :, rsd(3):rsd(3)+2*(floor(0.5*(ddim(3)-1))));
    end
    kdim = size(kern);
    kdimh = floor(kdim ./ 2);
    fftkern = zeros(ddim);
    ddh = round((ddim + 1) / 2);
    fftkern(ddh(1)-kdimh(1):ddh(1)+kdimh(1), ...
            ddh(2)-kdimh(2):ddh(2)+kdimh(2), ...
            ddh(3)-kdimh(3):ddh(3)+kdimh(3)) = kern;
    fftkern = fftn(fftkern);
end

% extend mask
if ~isempty(mask) && ...
    nconj > 1
    mask = mask(:, :, :, ones(1, nconj));
end

% test xprogress
if niter >= 50
    if isempty(opts.pbar)
        try
            pbar = xprogress;
            xprogress(pbar, 'setposition', [80, 200, 640, 36]);
            xprogress(pbar, 'settitle', 'Running alphasim...');
            xprogress(pbar, 0, sprintf('0/%d iterations, %d thresholds%s...', ...
                niter, nthr, msktxt), 'visible', 0, 1);
            pbarn = '';
            pst = niter / 100;
            psn = pst;
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            pbar = [];
            psn = Inf;
        end
    else
        pst = ceil(niter / 200);
        psn = pst;
        pbar = opts.pbar;
        pbar.Progress(0, sprintf('alphasim: 0/%d iterations, %d thresholds%s...', niter, nthr, msktxt));
        pbarn = 'alphasim: ';
    end
else
    pbar = [];
    psn = Inf;
end

% extend ddim
ddim(4) = nconj;
ddim(5) = opts.tdf;
nconjdf = nconj * opts.tdf;

% run loop
for n = 1:niter

    % simulated data
    if regnsub == 0

        % create data
        r = randn(ddim);

        % voxel-space convolution
        if ~fftconv
            for nc = 1:nconjdf
                r(:, :, :, nc) = conv3d(conv3d(conv3d(r(:, :, :, nc), ...
                    kern{1}), kern{2}), kern{3});
            end

        % frequency-space convolution
        else
            for nc = 1:nconjdf
                rf = fftn(r(:, :, :, nc));
                rf = rf .* fftkern;
                r(:, :, :, nc) = fftshift(ifftn(rf));
            end
        end

        % re-scale to unity variance again
        if opts.tdf == 1
            for nc = 1:nconj
                scc = scc + 1;

                % re-scale map
                r(:, :, :, nc) = scf .* r(:, :, :,nc);
            end

        % or compute test statistic
        else
            r = sqrt(opts.tdf) .* mean(r, 5) ./ std(r, [], 5);
            if nconj > 1
                r = conjval(r, 4);
            end
        end

        % one-tailed statistic
        if onet

            % square maps
            r = r .* r;
        end

        % shift towards requested end
        if zshift ~= 0
            r = r + zshift;
        end

        % mask
        if ~isempty(mask)
            r = r .* mask;
        end

        % conjunction of different signed tails?
        if nconj > 1 && ...
           ~onet

            % get sign of main map
            rs = sign(r(:, :, :, 1));
        end

        % iterate over other maps
        for nc = 2:nconj

            % for one-tailed
            if onet

                % simple minimum
                r(:, :, :, 1) = min(r(:, :, :, 1), r(:, :, :, nc));

            % otherwise
            else

                % absolute minimum where direction is the same
                r(:, :, :, 1) = rs .* (rs == sign(r(:, :, :, nc))) .* ...
                     abs(min(r(:, :, :, 1), r(:, :, :, nc)));
            end
        end

        % make sure we end up with one map
        if nconj > 1
            r = r(:, :, :, 1);
        end

        % do for each threshold
        for tc = 1:nthr

            % for volume-based output
            if isempty(srf)

                % both tails
                if botht

                    % compute cluster frequency for both tails!
                    cf = [lsqueeze(clustercoordsc(r >= zthr(tc), clconn)); ...
                        lsqueeze(clustercoordsc(r <= -zthr(tc), clconn))];
                else

                    % just for positive tail
                    cf = clustercoordsc(r >= zthr(tc), clconn);
                end

            % for surface-based output
            else

                % sample volume at coordinates
                smp = (1 / opts.srfsmp(2)) .* sum(reshape(limitrangec( ...
                    flexinterpn_method(r, srf, 'linear'), -1e10, 1e10, 0), ...
                    opts.srfsmp), 2);

                % then cluster surface maps
                if botht
                    cf = [lsqueeze(ceil(clustermeshmapbin(smp >= zthr(tc), ...
                            nei, crd, tra, trb, 0, 1))); ...
                          lsqueeze(ceil(clustermeshmapbin(smp <= -zthr(tc), ...
                            nei, crd, tra, trb, 0, 1)))];
                else
                    cf = ceil(clustermeshmapbin(smp >= zthr(tc), ...
                        nei, crd, tra, trb, 0, 1));
                end
            end

            % largest cluster
            if ~isempty(cf)
                mc = max(cf);
            else
                mc = 0;
            end

            % extend array if necessary
            if mc > size(cc, 2)
                cc(1, mc + ceil(size(cc, 2) / 12)) = 0;
            end

            % put into frequency arrays
            fc(tc, n) = mc;
            for nc = 1:numel(cf)
                cc(tc, cf(nc)) = cc(tc, cf(nc)) + 1;
            end
        end

    % actual data supplied
    else

        % generate new model
        if isempty(opts.regmodel)
            newmod = ztrans(randn(regnsub, 1));
        else
            [rdt, neword] = sort(rand(regnsub, 1));
            newmod = opts.regmodel(neword, :);
        end

        % perform regression and compute t-stats (the fast way)
        if opts.regmodsc && size(newmod, 2) > 1
            for tc = 1:size(newmod, 2)
                newmodx = newmod(:, tc);
                newmodx(:, 2) = 1;
                newi = invnd(newmodx' * newmodx);
                newb = newi * newmodx' * opts.regmaps;
                newe = regnsfc .* sqrt(varc(opts.regmaps - newmodx * newb));
                newt = reshape(newb(1, :) ./ (sqrt(newi(1)) .* newe), opts.ddim);
                newt(isinf(newt(:)) | isnan(newt(:))) = 0;
                if tc == 1
                    newtc = newt;
                else
                    newtc = conjval(newtc, newt);
                end
            end
            newt = newtc;
        else
            newmod(:, 2) = 1;
            newi = invnd(newmod' * newmod);
            newb = newi * newmod' * opts.regmaps;
            newe = regnsfc .* sqrt(varc(opts.regmaps - newmod * newb));
            newt = reshape(newb(1, :) ./ (sqrt(newi(1)) .* newe), opts.ddim);
            newt(isinf(newt(:)) | isnan(newt(:))) = 0;
        end

        % do for each threshold
        for tc = 1:nthr

            % for volume-based output
            if isempty(srf)

                % both tails
                if botht

                    % compute and combine both tails' clusters
                    cf = [lsqueeze(clustercoordsc(newt >= zthr(tc), clconn)); ...
                        lsqueeze(clustercoordsc(newt <= -zthr(tc), clconn))];

                % only positive tail
                else

                    % cluster frequency
                    cf = clustercoordsc(newt >= zthr(tc), clconn);
                end

            % for surface-based output
            else

                % sample volume at coordinates
                smp = (1 / opts.srfsmp(2)) .* sum(reshape(limitrangec( ...
                    flexinterpn_method(newt, srf, 'linear'), -1e10, 1e10, 0), ...
                    opts.srfsmp), 2);

                % both tails
                if botht
                    cf = [lsqueeze(ceil(clustermeshmapbin(smp >= zthr(tc), ...
                            nei, crd, tra, trb, 0, 1))); ...
                          lsqueeze(ceil(clustermeshmapbin(smp <= -zthr(tc), ...
                            nei, crd, tra, trb, 0, 1)))];

                % just positive tail
                else
                    cf = ceil(clustermeshmapbin(smp >= zthr(tc), ...
                        nei, crd, tra, trb, 0, 1));
                end
            end

            % largest cluster
            if ~isempty(cf)
                mc = max(cf);
            else
                mc = 0;
            end

            % extend array if necessary
            if mc > size(cc, 2)
                cc(1, mc + ceil(size(cc, 2) / 12)) = 0;
            end

            % put into frequency arrays
            fc(tc, n) = mc;
            for nc = 1:numel(cf)
                cc(tc, cf(nc)) = cc(tc, cf(nc)) + 1;
            end
        end
    end

    % update progress bar
    if n >= psn && ...
       ~isempty(pbar)
        pbar.Progress(n / niter, sprintf(...
            '%s%d/%d iterations, %d thresholds%s...', pbarn, n, niter, nthr, msktxt));
        pbar.Visible = 'on';
        psn = psn + pst;
    end
end

% close progress bar
if ~isempty(pbar) && ...
    isempty(opts.pbar)
    closebar(pbar);
end

% get size and data
mf = max(1, max(fc, [], 2));
cc = cc(:, 1:max(mf));

% prepare output
tout = cell(nthr, 1);
for tc = 1:nthr
    hf = hist(fc(tc, :), 1:mf(tc));
    hfs = cumsum(hf(:));
    hx = cc(tc, 1:mf(tc)) .* (1:mf(tc));
    hxs = [0; hx(:)];
    hxs(end) = [];
    ht = sum(hx);
    sc = sum(cc(tc, 1:mf(tc)));
    ccx = cc(tc, :)';
    tout{tc} = [(1:mf(tc))', ccx(1:mf(tc)), cumsum(ccx(1:mf(tc))) ./ sc, ...
        thr(tc) .* (sum(hx) - cumsum(hxs(:))) ./ ht, hf(1:mf(tc))', ...
        1 - ([0; hfs(1:mf(tc)-1)]) ./ niter];
end

% output variable or table
if nargout < 1
    for tc = 1:nthr
        disp(' ');
        disp(sprintf('Uncorrected threshold: p < %f%s', thr(tc), stypes));
        disp('------------------------------------------------------------');
        disp(' Cl Size  Frequency  CumProbCl  p / Voxel  MaxFreq   Alpha ');
        stout = tout{tc};
        stout(stout(:, 2) == 0, :) = [];
        if isempty(srf)
            disp(sprintf(' %7d  %9d  %9.7f  %9.7f  %8d  %7.5f\n', lsqueeze(stout')));
        else
            disp(sprintf('%5dmm2  %9d  %9.7f  %9.7f  %8d  %7.5f\n', lsqueeze(stout')));
        end
    end
else
    if nthr == 1
        varargout{1} = tout{1};
    else
        varargout{1} = tout;
    end
    if nargout > 1
        varargout{2} = scf;
    end
end
