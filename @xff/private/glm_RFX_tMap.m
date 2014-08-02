function map = glm_RFX_tMap(hfile, c, mapopts)
% GLM::RFX_tMap  - calculate a t contrast map
%
% FORMAT:       map = glm.RFX_tMap([c, mapopts])
%
% Input fields:
%
%       c           CxN contrast vector (default: full model and main eff)
%       mapopts     structure with optional fields
%        .bbox      bounding box for VMP if necessary (default: full MNI)
%        .brange    acceptible beta-value range (default: [-Inf, Inf])
%        .covs      SxC covariates
%        .estfwhm   estimate smoothness and store in Map.RunTimeVars (true)
%        .groups    Gx2 cell array with group names and subject IDs
%        .imeth     interpolation method if necessary (default: 'cubic')
%        .interp    mesh-based interpolation (default: true)
%        .meanr     add mean regressor of (p>0.25)-voxels of first pass
%        .meanrmsk  mask additionally applied to mean-regressor source
%        .names     map names for contrasts, if not given: list of weights
%        .robust    use robust regression for estimation (default: false)
%        .smk       smoothing kernel for data (prior to regression, 0)
%        .srf       SRF object (required for multi-study MTC-based stats)
%        .subsel    subject selection (numeric list)
%
% Output fields:
%
%       map         MAP/VMP/SMP object with C maps

% Version:  v0.9d
% Build:    14071411
% Date:     Jul-14 2014, 11:20 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2010, 2011, 2012, 2014, Jochen Weber
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
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'glm')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
sbc = xffgetscont(hfile.L);
bc = sbc.C;
bcrtv = bc.RunTimeVars;
glmfile = sbc.F;
glmid = bcrtv.xffID;
if isempty(glmfile)
    glmfile = glmid;
end
if bc.ProjectTypeRFX == 0 && ...
    bc.SeparatePredictors ~= 2
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
isrfx = (bc.ProjectTypeRFX > 0);
ffxspred = glm_SubjectPredictors(hfile);
if isrfx
    numsubs = bc.NrOfSubjects;
    numspred = bc.NrOfSubjectPredictors;
else
    ffxpred = bc.Predictor;
    ffxpred = {ffxpred(:).Name2};
    ffxpred = ffxpred(:);
    ffxsubs = glm_Subjects(hfile);
    numsubs = numel(ffxsubs);
    numspred = numel(ffxspred) + 1;
end
if nargin < 2 || ...
   ~isa(c, 'double') || ...
    isempty(c) || ...
    size(c, 1) > numspred || ...
    any(isinf(c(:)) | isnan(c(:)))
    c = [[eye(numspred - 1);zeros(1, numspred - 1)], [ones(numspred - 1, 1); 0]];
elseif numel(c) == size(c, 2)
    if numel(c) > numspred
        c((numspred + 1):end) = [];
    end
    c = real(c');
else
    c = real(c);
end
nummaps = size(c, 2);
if size(c, 1) < numspred
    c = [c; zeros(numspred - size(c, 1), size(c, 2))];
end
if nargin < 3 || ...
   ~isstruct(mapopts) || ...
    numel(mapopts) ~= 1
    mapopts = struct;
end
ipo = true;
if ~isfield(mapopts, 'bbox') || ...
   ~isa(mapopts.bbox, 'double') || ...
   ~isequal(size(mapopts.bbox), [2, 3]) || ...
    any(isinf(mapopts.bbox(:)) | isnan(mapopts.bbox(:)) | ...
        mapopts.bbox(:) < 0 | mapopts.bbox(:) > 256 | mapopts.bbox(:) ~= fix(mapopts.bbox(:))) || ...
    any(diff(mapopts.bbox) < 0)
    mapopts.bbox = [44, 38, 44; 242, 194, 212];
end
if ~isfield(mapopts, 'brange') || ...
   ~isa(mapopts.brange, 'double') || ...
    numel(mapopts.brange) ~= 2 || ...
    any(isnan(mapopts.brange)) || ...
    mapopts.brange(1) >= mapopts.brange(2)
    mapopts.brange = [-Inf, Inf];
else
    brangedop = false(3, 3, 3);
    brangedop([5, 11, 13, 14, 15, 17, 23]) = true;
end
brange = mapopts.brange;
if ~isfield(mapopts, 'covs') || ...
   ~isa(mapopts.covs, 'double') || ...
    ndims(mapopts.covs) ~= 2 || ...
    size(mapopts.covs, 1) ~= numsubs
    mapopts.covs = zeros(numsubs, 0);
end
if ~isfield(mapopts, 'estfwhm') || ...
   ~islogical(mapopts.estfwhm) || ...
    numel(mapopts.estfwhm) ~= 1
    mapopts.estfwhm = true;
end
if ~isfield(mapopts, 'groups') || ...
   ~iscell(mapopts.groups) || ...
    size(mapopts.groups, 2) ~= 2
    ngrp = 0;
    if ~isfield(mapopts, 'subsel') || ...
       ~isa(mapopts.subsel, 'double') || ...
        isempty(mapopts.subsel) || ...
        any(isinf(mapopts.subsel(:)) | isnan(mapopts.subsel(:)))
        ga = ones(numsubs, 1);
    else
        mapopts.subsel = mapopts.subsel(:)';
        mapopts.subsel(mapopts.subsel < 1 | mapopts.subsel > numsubs) = [];
        ga = zeros(numsubs, 1);
        ga(unique(round(mapopts.subsel))) = 1;
    end
    mapopts.groups = [];
    gamx = 1;
    nval = sum(ga) - 1;
else
    ga = zeros(numsubs, 1);
    for gc = 1:size(mapopts.groups, 1)
        if ~ischar(mapopts.groups{gc, 1}) || ...
            isempty(mapopts.groups{gc, 1}) || ...
            isempty(mapopts.groups{gc, 2}) || ...
            any(isinf(mapopts.groups{gc, 2}(:)) | isnan(mapopts.groups{gc, 2}(:))) || ...
            any(mapopts.groups{gc, 2}(:) < 1 | mapopts.groups{gc, 2}(:) > numsubs) || ...
            any(ga(round(mapopts.groups{gc, 2}(:))) > 0)
            error( ...
                'xff:BadArgument', ...
                'Invalid group assignment.' ...
            );
        end
        mapopts.groups{gc, 2} = unique(round(mapopts.groups{gc, 2}(:)));
        ga(mapopts.groups{gc, 2}) = gc;
    end
    ngrp = size(mapopts.groups, 1);
    nval = sum(ga > 0) - ngrp;
    if nval < 3
        error( ...
            'xff:BadArgument', ...
            'Too few subjects for grouping.' ...
        );
    end
    gas = ga(ga > 0);
    gag = tril(ones(ngrp));
    gag(1:(ngrp + 1):end) = 0;
    gamx = sum(gag(:));
    gag(gag > 0) = 1:gamx;
end
gax = find(ga > 0);
numcovs = size(mapopts.covs, 2);
if numcovs > 0
    if ngrp < 2
        mapopts.covs = mapopts.covs(gax, :);
        mapopts.covs = ztrans(mapopts.covs);
    else
        for gc = 1:ngrp
            mapopts.covs(ga == gc, :) = ztrans(mapopts.covs(ga == gc, :));
        end
        mapopts.covs = mapopts.covs(gax, :);
    end
else
    mapopts.covs = zeros(numel(gax), 0);
end
numsubs = numel(gax);
if ~isfield(mapopts, 'imeth') || ...
   ~ischar(mapopts.imeth) || ...
    isempty(mapopts.imeth) || ...
    isempty(regexpi(mapopts.imeth(:)', '^(cubic|lanczos\d|linear|nearest)$'))
    mapopts.imeth = 'cubic';
else
    mapopts.imeth = lower(mapopts.imeth(:)');
end
if isfield(mapopts, 'interp') && ...
   ~isempty(mapopts.interp) && ...
   (isnumeric(mapopts.interp) || islogical(mapopts.interp))
    ipo = ipo && mapopts.interp(1);
end
if ~isfield(mapopts, 'meanr') || ...
   ~islogical(mapopts.meanr) || ...
    numel(mapopts.meanr) ~= 1
    mapopts.meanr = false;
end
if ~isfield(mapopts, 'meanrmsk') || ...
   ~islogical(mapopts.meanrmsk)
    mapopts.meanrmsk = [];
end
if ~isfield(mapopts, 'names') || ...
   ~iscell(mapopts.names) || ...
    numel(mapopts.names) ~= nummaps
    mapopts.names = {};
else
    for mc = 1:nummaps
        if ~ischar(mapopts.names{mc}) || ...
            isempty(mapopts.names{mc})
            mapopts.names = {};
            break;
        end
        mapopts.names{mc} = mapopts.names{mc}(:)';
    end
end
if isempty(mapopts.names)
    mapopts.names = cell(nummaps, 1);
    for mc = 1:nummaps
        mapopts.names{mc} = sprintf('%d ', c(1:end-1, mc)');
        mapopts.names{mc}(end) = [];
    end
end
if ~isfield(mapopts, 'robust') || ...
    numel(mapopts.robust) ~= 1 || ...
   ~islogical(mapopts.robust)
    mapopts.robust = false;
end
if mapopts.robust
    tmapr = ' (robust)';
else
    tmapr = '';
end
if ~isfield(mapopts, 'smk') || ...
    numel(mapopts.smk) ~= 1 || ...
   ~isa(mapopts.smk, 'double') || ...
    isinf(mapopts.smk) || ...
    isnan(mapopts.smk) || ...
    mapopts.smk <= (0.5 * bc.Resolution)
    mapopts.smk = 0;
else
    mapopts.smk = min(mapopts.smk, 8 * bc.Resolution);
end
nmf = 1 + 3 * double(mapopts.meanr);

% generate map according to type
switch (bc.ProjectType)

    % currently unsupported types
    case {0}
        error( ...
            'xff:NotYetSupported', ...
            'FMR->MAP generation not yet supported.' ...
        );

    % VTCs
    case {1}
        map = xff('new:vmp');
        mapc = xffgetcont(map.L);
        mapc.Resolution = bc.Resolution;
        if ~isfield(bcrtv, 'SubjectSPMsn') || ...
           ~isstruct(bcrtv.SubjectSPMsn) || ...
            isempty(fieldnames(bcrtv.SubjectSPMsn))
            if isrfx
                szmap = size(bc.GLMData.RFXGlobalMap);
            else
                szmap = size(bc.GLMData.MCorrSS);
            end
            mapc.XStart = bc.XStart;
            mapc.XEnd = bc.XEnd;
            mapc.YStart = bc.YStart;
            mapc.YEnd = bc.YEnd;
            mapc.ZStart = bc.ZStart;
            mapc.ZEnd = bc.ZEnd;
            copymaps = true;
        else
            mapopts.bbox(2, :) = mapopts.bbox(1, :) + mapc.Resolution .* ...
                ceil((mapopts.bbox(2, :) - mapopts.bbox(1, :)) ./ mapc.Resolution - 0.01);
            mapc.XStart = mapopts.bbox(1, 1);
            mapc.XEnd = mapopts.bbox(2, 1);
            mapc.YStart = mapopts.bbox(1, 2);
            mapc.YEnd = mapopts.bbox(2, 2);
            mapc.ZStart = mapopts.bbox(1, 3);
            mapc.ZEnd = mapopts.bbox(2, 3);
            szmap = round((mapopts.bbox(2, :) - mapopts.bbox(1, :)) ./ mapc.Resolution);
            copymaps = false;
            sbbox = struct('BBox', mapopts.bbox, 'ResXYZ', mapc.Resolution);
        end
        mapc.RunTimeVars.TrfPlus = bcrtv.TrfPlus;
        mapc.Map.Type = 1;
        mapc.Map.LowerThreshold = -sdist('tinv', 0.005, nval);
        mapc.Map.UpperThreshold = -sdist('tinv', 0.0001, nval);
        mapc.Map.Name = 'Contrast:';
        mapc.Map.NrOfLags = [];
        mapc.Map.MinLag = [];
        mapc.Map.MaxLag = [];
        mapc.Map.CCOverlay = [];
        mapc.Map.ClusterSize = 25;
        mapc.Map.EnableClusterCheck = 0;
        mapc.Map.DF1 = nval;
        mapc.Map.DF2 = 0;
        mapc.Map.BonferroniValue = bc.NrOfVoxelsForBonfCorrection;
        mapc.Map.VMPData = single(zeros(szmap));
        mapc.Map(1:(nummaps*gamx*nmf)) = mapc.Map(1);
        mapc.RunTimeVars.AutoSave = true;

        % iterate over contrasts
        occ = 1;
        for cc = 1:size(c, 2)

            % get contrast
            conc = c(:, cc);
            coni = find(conc ~= 0);

            % initialize temp map
            tmpmp = zeros([szmap, numsubs]);

            % allow for subjects with missing data (FFX)
            keepsubs = true(numsubs, 1);
            gaxk = gax;

            % fill contrast
            for pc = coni(:)'
                for sc = 1:numsubs
                    if isrfx
                        if copymaps
                            tmpmpp = bc.GLMData.Subject(gax(sc)).BetaMaps(:, :, :, pc);
                        else
                            tmpmpp = aft_SampleBVBox(hfile, sbbox, ...
                                (gax(sc) - 1) * numspred + pc, mapopts.imeth);
                        end
                    else
                        keepsubi = findfirst(~cellfun('isempty', regexpi(ffxpred, ...
                            sprintf('^subject\\s+%s:\\s*%s', ...
                            ffxsubs{gax(sc)}, ffxspred{pc}))));
                        if ~isempty(keepsubi)
                            tmpmpp = bc.GLMData.BetaMaps(:, :, :, keepsubi);
                        else
                            keepsubs(sc) = false;
                            continue;
                        end
                    end
                    if ~isinf(brange(1))
                        if ~isinf(brange(2))
                            tmpmpp(dilate3d(tmpmpp < (2 .* brange(1)) | tmpmpp > (2 .* brange(2)), brangedop) | tmpmpp < brange(1) | tmpmpp > brange(2)) = NaN;
                        else
                            tmpmpp(dilate3d(tmpmpp < (2 .* brange(1)), brangedop) | tmpmpp < brange(1)) = NaN;
                        end
                    elseif ~isinf(brange(2))
                        tmpmpp(dilate3d(tmpmpp > (2 .* brange(2)), brangedop) | tmpmpp > brange(2)) = NaN;
                    end
                    tmpmp(:, :, :, sc) = tmpmp(:, :, :, sc) + conc(pc) .* tmpmpp;
                end
            end

            % remove bad subjects from list
            keepsubs = keepsubs & ~lsqueeze(all(all(all(isnan(tmpmp), 3), 2), 1));
            if ~all(keepsubs)
                tmpmp(:, :, :, ~keepsubs) = [];
                gaxk(~keepsubs) = [];
            end
            goodsubs = sum(keepsubs);
            if ngrp < 1
                nval = numel(gaxk) - 1;
            else
                nval = numel(gaxk) - ngrp;
            end
            if nval < 1
                continue;
            end
            mapc.Map(occ).DF1 = nval;

            % smooth data
            if mapopts.smk > 0
                ptc = (isinf(tmpmp) | isnan(tmpmp) | tmpmp == 0);
                tmpmp = smoothdata3(tmpmp, mapopts.smk / mapc.Resolution);
                tmpmp(ptc) = 0;
            end

            % set additional data
            artv = struct( ...
                'SourceGLM',   glmfile, ...
                'SourceGLMID', glmid, ...
                'Contrast',    conc, ...
                'Covariates',  mapopts.covs, ...
                'Groups',      {mapopts.groups}, ...
                'MeanRem',     mapopts.meanr, ...
                'MeanRemRes',  [], ...
                'RFXGLM',      isrfx, ...
                'Robust',      mapopts.robust, ...
                'SubPreds',    {ffxspred}, ...
                'SubSel',      gaxk);

            % generate 2nd-level single beta-t-maps
            if ngrp < 1
                if ~mapopts.robust
                    if numcovs == 0
                        mmap = mean(tmpmp, 4);
                        tmap = sqrt(goodsubs) * (mmap ./ std(tmpmp, 0, 4));
                        if mapopts.estfwhm
                            ptc = repmat(mmap, [1, 1, 1, size(tmpmp, 4)]);
                        end
                    else
                        x = [ones(goodsubs, 1), mapopts.covs(keepsubs, :)];
                        [bmaps, ixx, ptc, se] = calcbetas(x, tmpmp, 4);
                        tmap = glmtstat([1, zeros(1, numcovs)], bmaps, ixx, se);
                    end
                    if mapopts.estfwhm
                        [artv.FWHMResEst, artv.FWHMResImg] = ...
                            resestsmooth(tmpmp - ptc, bc.Resolution);
                    end
                else
                    x = [ones(goodsubs, 1), mapopts.covs(keepsubs, :)];
                    [bmaps, wmaps] = fitrobustbisquare_img(x, tmpmp);
                    tmap = robustt(x, tmpmp, bmaps, wmaps, [1, zeros(1, numcovs)]);
                    if mapopts.estfwhm
                        ptc = zeros(size(tmpmp));
                        for bmc = 1:size(x, 2)
                            ptc = ptc + repmat(bmaps(:, :, :, bmc), [1, 1, 1, size(x, 1)]) .* ...
                                repmat(reshape(x(:, bmc), [1, 1, 1, size(x, 1)]), szmap);
                        end
                        ptc = wmaps .* ptc + (1 - wmaps) .* tmpmp;
                        [artv.FWHMResEst, artv.FWHMResImg] = ...
                            resestsmooth(tmpmp - ptc, bc.Resolution);
                    end
                end
                tmap(isinf(tmap) | isnan(tmap)) = 0;

                % set name and map data
                mapc.Map(occ).Name = sprintf('%s%s', mapopts.names{cc}, tmapr);
                mapc.Map(occ).VMPData = single(tmap);
                mapc.Map(occ).RunTimeVars = artv;
                occ = occ + 1;

                % create additional map without residual
                if mapopts.meanr

                    % compute std==1-scaled data
                    resmp = tmpmp;
                    bmaps = 1 ./ sqrt(varc(tmpmp, 4));
                    bmaps(isinf(bmaps) | isnan(bmaps) | bmaps > 1) = 1;
                    for sc = 1:goodsubs
                        resmp(:, :, :, sc) = resmp(:, :, :, sc) .* bmaps;
                    end
                    resmp(isinf(resmp) | isnan(resmp)) = 0;

                    % average according to tmap
                    tmin = -sdist('tinv', 0.25, nval);
                    tmax = -sdist('tinv', 0.05, nval);
                    wmp = limitrangec(tmax - (1 / (tmax - tmin)) .* tmap, 0.25, 1, 0);
                    wmp = wmp .* wmp;
                    if isequal(size(wmp), size(mapopts.meanrmsk))
                        wmp = wmp .* mapopts.meanrmsk;
                    end
                    wmp(tmap == 0) = 0;
                    for sc = 1:goodsubs
                        resmp(:, :, :, sc) = resmp(:, :, :, sc) .* wmp;
                    end
                    resmp = lsqueeze(sum(sum(sum(resmp, 1), 2), 3)) ./ sum(wmp(:));

                    % non-robust remodeling
                    x = [ones(goodsubs, 1), ztrans(resmp)];
                    if ~mapopts.robust

                        % use calcbetas and glmtstat
                        [bmaps, ixx, ptc, se] = calcbetas(x, tmpmp, 4);
                        tmap = glmtstat([1, 0], bmaps, ixx, se);
                        if mapopts.estfwhm
                            [artv.FWHMResEst, artv.FWHMResImg] = ...
                                resestsmooth(tmpmp - ptc, bc.Resolution);
                        end

                    % robust remodeling
                    else
                        [bmaps, wmaps] = fitrobustbisquare_img(x, tmpmp);
                        tmap = robustt(x, tmpmp, bmaps, wmaps, [1, 0]);
                        if mapopts.estfwhm
                            ptc = zeros(size(tmpmp));
                            for bmc = 1:size(x, 2)
                                ptc = ptc + repmat(bmaps(:, :, :, bmc), [1, 1, 1, size(x, 1)]) .* ...
                                    repmat(reshape(x(:, bmc), [1, 1, 1, size(x, 1)]), szmap);
                            end
                            ptc = wmaps .* ptc + (1 - wmaps) .* tmpmp;
                            [artv.FWHMResEst, artv.FWHMResImg] = ...
                                resestsmooth(tmpmp - ptc, bc.Resolution);
                        end
                    end
                    tmap(isinf(tmap) | isnan(tmap)) = 0;

                    % set name and map data
                    mapc.Map(occ).Name = sprintf('%s%s (without average res.)', ...
                        mapopts.names{cc}, tmapr);
                    mapc.Map(occ).VMPData = single(tmap);
                    mapc.Map(occ).DF1 = nval - 1;
                    mapc.Map(occ).LowerThreshold = -sdist('tinv', 0.005, nval - 1);
                    mapc.Map(occ).UpperThreshold = -sdist('tinv', 0.0001, nval - 1);
                    mapc.Map(occ).RunTimeVars = artv;
                    occ = occ + 1;

                    % compute contrast for actual average residual
                    if ~mapopts.robust
                        tmap = glmtstat([0, 1], bmaps, ixx, se);
                    else
                        tmap = robustt(x, tmpmp, bmaps, wmaps, [0, 1]);
                    end
                    tmap(isinf(tmap) | isnan(tmap)) = 0;

                    % set name and map data
                    mapc.Map(occ).Name = sprintf('%s%s (corr. average res.)', ...
                        mapopts.names{cc}, tmapr);
                    mapc.Map(occ).VMPData = single(tmap);
                    mapc.Map(occ).DF1 = nval - 1;
                    mapc.Map(occ).LowerThreshold = -sdist('tinv', 0.005, nval - 1);
                    mapc.Map(occ).UpperThreshold = -sdist('tinv', 0.0001, nval - 1);
                    mapc.Map(occ).RunTimeVars = artv;
                    occ = occ + 1;

                    % compute contrast vs. correlation with residual map
                    if ~mapopts.robust
                        tmap = conjval(glmtstat([1, 0.5], bmaps, ixx, se), ...
                            glmtstat([1, -0.5], bmaps, ixx, se));
                    else
                        tmap = conjval(robustt(x, tmpmp, bmaps, wmaps, [1, 0.5]), ...
                            robustt(x, tmpmp, bmaps, wmaps, [1, -0.5]));
                    end
                    tmap(isinf(tmap) | isnan(tmap)) = 0;

                    % set name and map data
                    mapc.Map(occ).Name = sprintf('%s%s (w/o+xmsk average res.)', ...
                        mapopts.names{cc}, tmapr);
                    mapc.Map(occ).VMPData = single(tmap);
                    mapc.Map(occ).DF1 = nval - 1;
                    mapc.Map(occ).LowerThreshold = -sdist('tinv', 0.005, nval - 1);
                    mapc.Map(occ).UpperThreshold = -sdist('tinv', 0.0001, nval - 1);
                    mapc.Map(occ).RunTimeVars = artv;
                    occ = occ + 1;
                end

            % for multiple groups
            else

                % create additional map without residual
                if mapopts.meanr

                    % compute std==1-scaled data
                    resmp = tmpmp;
                    bmaps = 1 ./ sqrt(varc(tmpmp, 4));
                    bmaps(isinf(bmaps) | isnan(bmaps) | bmaps > 1) = 1;
                    for sc = 1:goodsubs
                        resmp(:, :, :, sc) = resmp(:, :, :, sc) .* bmaps;
                    end
                    resmp(isinf(resmp) | isnan(resmp)) = 0;
                end

                if ~mapopts.robust
                    for gc1 = 1:ngrp
                        ga1 = find(ga(gaxk) == gc1);
                        m1 = (1 / numel(ga1)) .* sum(tmpmp(:, :, :, ga1), 4);
                        s1 = (1 / numel(ga1)) .* var(tmpmp(:, :, :, ga1), [], 4);
                        for gc2 = (gc1 + 1):ngrp
                            ga2 = find(ga(gaxk) == gc2);
                            m2 = (1 / numel(ga2)) .* sum(tmpmp(:, :, :, ga2), 4);
                            s2 = (1 / numel(ga2)) .* var(tmpmp(:, :, :, ga2), [], 4);
                            t12 = (m1 - m2) ./ sqrt(s1 + s2);
                            df12 = ((s1 + s2) .^ 2) ./ ...
                                ((1 / (numel(ga1) - 1)) .* s1 .* s1 + ...
                                 (1 / (numel(ga2) - 1)) .* s2 .* s2);
                            badv = find(isinf(t12) | isnan(t12) | isnan(df12) | df12 < 1);
                            t12(badv) = 0;
                            df12(badv) = 1;
                            rdf12 = sum(ga == gc1 | ga == gc2) - 2;
                            mapc.Map(occ).Name = sprintf('%s (%s > %s)', ...
                                mapopts.names{cc}, mapopts.groups{gc1, 1}, ...
                                mapopts.groups{gc2, 1});
                            mapc.Map(occ).VMPData = single(...
                                sdist('tinv', sdist('tcdf', t12, df12), rdf12));
                            mapc.Map(occ).DF1 = rdf12;
                            mapc.Map(occ).RunTimeVars = artv;
                            mapc.Map(occ).RunTimeVars.SubSel(ga(gaxk) ~= gc1 & ga(gaxk) ~= gc2) = [];
                            if mapopts.estfwhm
                                gresmp = tmpmp;
                                gresmp(:, :, :, ga1) = gresmp(:, :, :, ga1) - ...
                                    m1(:, :, :, ones(1, numel(ga1)));
                                gresmp(:, :, :, ga2) = gresmp(:, :, :, ga2) - ...
                                    m2(:, :, :, ones(1, numel(ga2)));
                                [mapc.Map(occ).RunTimeVars.FWHMResEst, ...
                                 mapc.Map(occ).RunTimeVars.FWHMResImg] = ...
                                    resestsmooth(gresmp(:, :, :, [ga1(:)', ga2(:)']), bc.Resolution);
                            end
                            occ = occ + 1;

                            % remove residual and re-create maps as well
                            if mapopts.meanr
                                tmin = -sdist('tinv', 0.25, rdf12);
                                tmax = -sdist('tinv', 0.05, rdf12);
                                wmp = limitrangec(tmax - (1 / (tmax - tmin)) .* ...
                                    double(mapc.Map(occ-1).VMPData), 0.25, 1, 0);
                                wmp = wmp .* wmp;
                                if isequal(size(wmp), size(mapopts.meanrmsk))
                                    wmp = wmp .* mapopts.meanrmsk;
                                end
                                wmp(mapc.Map(occ-1).VMPData == 0) = 0;
                                gresmp = resmp;
                                for sc = [ga1(:)', ga2(:)']
                                    gresmp(:, :, :, sc) = gresmp(:, :, :, sc) .* wmp;
                                end
                                gresmp = lsqueeze(sum(sum(sum(gresmp, 1), 2), 3)) ./ sum(wmp(:));
                                x = zeros(numel(ga1) + numel(ga2), 4);
                                x(1:numel(ga1), 1:2) = ...
                                    [ones(numel(ga1), 1), ztrans(gresmp(ga1))];
                                x(numel(ga1)+1:end, 3:4) = ...
                                    [ones(numel(ga2), 1), ztrans(gresmp(ga2))];
                                bmaps = calcbetas(x, tmpmp(:, :, :, [ga1(:)', ga2(:)']), 4);
                                bmaps(:, :, :, [1, 3]) = 0;
                                gresmp = tmpmp(:, :, :, [ga1(:)', ga2(:)']) - ...
                                    reshape((reshape(bmaps, numel(df12), 4) * x'), ...
                                    [size(df12), size(x, 1)]);
                                m1rm = (1 / numel(ga1)) .* sum(gresmp(:, :, :, 1:numel(ga1)), 4);
                                s1rm = (1 / numel(ga1)) .* var(gresmp(:, :, :, 1:numel(ga1)), [], 4);
                                m2rm = (1 / numel(ga2)) .* sum(gresmp(:, :, :, numel(ga1)+1:end), 4);
                                s2rm = (1 / numel(ga2)) .* var(gresmp(:, :, :, numel(ga1)+1:end), [], 4);
                                t12 = (m1rm - m2rm) ./ sqrt(s1rm + s2rm);
                                df12 = ((s1rm + s2rm) .^ 2) ./ ...
                                    ((1 / (numel(ga1) - 1)) .* s1rm .* s1rm + ...
                                     (1 / (numel(ga2) - 1)) .* s2rm .* s2rm);
                                badv = find(isinf(t12) | isnan(t12) | isnan(df12) | df12 < 1);
                                t12(badv) = 0;
                                df12(badv) = 1;
                                rdf12 = sum(ga == gc1 | ga == gc2) - 4;
                                mapc.Map(occ).Name = sprintf('%s (%s > %s, without average res.)', ...
                                    mapopts.names{cc}, mapopts.groups{gc1, 1}, ...
                                    mapopts.groups{gc2, 1});
                                mapc.Map(occ).VMPData = single(...
                                    sdist('tinv', sdist('tcdf', t12, df12), rdf12));
                                mapc.Map(occ).DF1 = rdf12;
                                mapc.Map(occ).RunTimeVars = artv;
                                mapc.Map(occ).RunTimeVars.SubSel(ga(gaxk) ~= gc1 & ga(gaxk) ~= gc2) = [];
                                if mapopts.estfwhm
                                    gresmp(:, :, :, 1:numel(ga1)) = gresmp(:, :, :, 1:numel(ga1)) - ...
                                        m1rm(:, :, :, ones(1, numel(ga1)));
                                    gresmp(:, :, :, numel(ga1)+1:end) = gresmp(:, :, :, numel(ga1)+1:end) - ...
                                        m2rm(:, :, :, ones(1, numel(ga2)));
                                    [mapc.Map(occ).RunTimeVars.FWHMResEst, ...
                                     mapc.Map(occ).RunTimeVars.FWHMResImg] = ...
                                        resestsmooth(gresmp, bc.Resolution);
                                end
                                occ = occ + 1;
                            end
                        end
                    end
                else
                    [tmap, wmaps, noot, bmaps] = ...
                        robustnsamplet_img(tmpmp, ga(gaxk), struct('wvols', true));
                    if mapopts.estfwhm
                        ptc = zeros(size(tmpmp));
                        for bmc = 1:size(bmaps, 4)
                            ptc(:, :, :, ga(gaxk) == bmc) = ...
                                repmat(bmaps(:, :, :, bmc), [1, 1, 1, sum(ga(gaxk) == bmc)]);
                        end
                        ptc = wmaps .* ptc + (1 - wmaps) .* tmpmp;
                    end
                    for gmc = 1:gamx
                        [g2, g1] = find(gag == gmc);
                        mapc.Map(occ).Name = sprintf('%s%s (%s > %s)', ...
                            mapopts.names{cc}, tmapr, mapopts.groups{g1, 1}, ...
                            mapopts.groups{g2, 1});
                        mapc.Map(occ).VMPData = single(tmap(:, :, :, gmc));
                        mapc.Map(occ).DF1 = sum(ga == g1 | ga == g2) - 2;
                        mapc.Map(occ).RunTimeVars = artv;
                        mapc.Map(occ).RunTimeVars.SubSel(ga(gaxk) ~= g1 & ga(gaxk) ~= g2) = [];
                        if mapopts.estfwhm
                            [mapc.Map(occ).RunTimeVars.FWHMResEst, ...
                             mapc.Map(occ).RunTimeVars.FWHMResImg] = ...
                             resestsmooth(tmpmp - ptc, bc.Resolution);
                        end
                        occ = occ + 1;
                        if mapopts.meanr
                            occ = occ + 1;
                        end
                    end
                    if mapopts.meanr
                        occ = occ - 2 * gamx(end);
                        wmp = ones(size(mapc.Map(occ).VMPData));
                        for gmc = 1:gamx
                            [g2, g1] = find(gag == gmc);
                            rdf12 = sum(ga == g1 | ga == g2) - 4;
                            tmin = -sdist('tinv', 0.25, rdf12);
                            tmax = -sdist('tinv', 0.05, rdf12);
                            wmp = min(wmp, limitrangec(tmax - (1 / (tmax - tmin)) .* ...
                                double(mapc.Map(occ + 2 * gmc - 2).VMPData), 0.25, 1, 0));
                            wmp(mapc.Map(occ + 2 * gmc - 2).VMPData == 0) = 0;
                        end
                        wmp = wmp .* wmp;
                        if isequal(size(wmp), size(mapopts.meanrmsk))
                            wmp = wmp .* mapopts.meanrmsk;
                        end
                        gresmp = resmp;
                        for sc = 1:goodsubs
                            gresmp(:, :, :, sc) = gresmp(:, :, :, sc) .* wmp;
                        end
                        gresmp = lsqueeze(sum(sum(sum(gresmp, 1), 2), 3)) ./ sum(wmp(:));
                        x = zeros(size(gresmp, 4), 2 * ngrp);
                        gs = zeros(1, ngrp);
                        for gmc = 1:ngrp
                            gs(gmc) = sum(ga(gaxk) == gmc);
                            x(ga(gaxk) == gmc, 2*gmc-1:2*gmc) = ...
                                [ones(gs(gmc), 1), ztrans(gresmp(ga == gmc))];
                        end
                        [bmaps, wmaps] = fitrobustbisquare_img(x, tmpmp);
                        if mapopts.estfwhm
                            ptc = zeros(size(tmpmp));
                            for bmc = 1:size(x, 2)
                                ptc = ptc + repmat(bmaps(:, :, :, bmc), [1, 1, 1, size(x, 1)]) .* ...
                                    repmat(reshape(x(:, bmc), [1, 1, 1, size(x, 1)]), szmap);
                            end
                            ptc = wmaps .* ptc + (1 - wmaps) .* tmpmp;
                        end
                        wmaps = sqrt(wmaps);
                        rmaps = tmpmp - reshape((reshape(bmaps, numel(wmp), size(bmaps, 4)) * x'), ...
                            [size(wmp), size(tmpmp, 4)]);
                        for g1c = 1:ngrp
                            g1w = wmaps(:, :, :, ga(gaxk) == g1c);
                            g1ws = sum(g1w .* g1w, 4);
                            g1w = g1w .* repmat((gs(g1c) ./ g1ws), [1, 1, 1, size(g1w, 4)]);
                            g1r = rmaps(:, :, :, ga(gaxk) == g1c) .* g1w;
                            g1rv = varc(g1r, 4, true) .* (gs(g1c) ./ (g1ws .* g1ws));
                            for g2c = (g1c+1):ngrp
                                g2w = wmaps(:, :, :, ga(gaxk) == g2c);
                                g2ws = sum(g2w .* g2w, 4);
                                g2w = g2w .* repmat((gs(g2c) ./ g2ws), [1, 1, 1, size(g2w, 4)]);
                                g2r = rmaps(:, :, :, ga(gaxk) == g2c) .* g2w;
                                g2rv = varc(g2r, 4, true) .* (gs(g2c) ./ (g2ws .* g2ws));
                                tstat = (bmaps(:, :, :, 2*g1c-1) - bmaps(:, :, :, 2*g2c-1)) ./ sqrt(g1rv + g2rv);
                                dfstat = ((g1rv + g2rv) .^ 2) ./ ...
                                    (g1rv .* g1rv ./ (g1ws - 1) + g2rv .* g2rv ./ (g2ws - 1));
                                rdf12 = sum(ga == g1c | ga == g2c) - 4;
                                badv = (isinf(tstat) | isnan(tstat) | isnan(dfstat) | dfstat < 1);
                                if any(badv(:))
                                    tstat(badv) = 0;
                                    dfstat(badv) = 1;
                                end
                                occ = occ + 1;
                                mapc.Map(occ).Name = ...
                                    sprintf('%s (%s > %s, robust, without average res.)', ...
                                    mapopts.names{cc}, ...
                                    mapopts.groups{g1c, 1}, ...
                                    mapopts.groups{g2c, 1});
                                mapc.Map(occ).VMPData = single(...
                                    sdist('tinv', sdist('tcdf', tstat, dfstat), rdf12));
                                mapc.Map(occ).DF1 = rdf12;
                                mapc.Map(occ).RunTimeVars = artv;
                                mapc.Map(occ).RunTimeVars.SubSel(ga(gaxk) ~= g1c & ga(gaxk) ~= g2c) = [];
                                if mapopts.estfwhm
                                    [mapc.Map(occ).RunTimeVars.FWHMResEst, ...
                                        mapc.Map(occ).RunTimeVars.FWHMResImg] = ...
                                        resestsmooth(tmpmp(:, :, :, ga(gaxk) == g1c | ga(gaxk) == g2c) - ...
                                        ptc(:, :, :, ga(gaxk) == g1c | ga(gaxk) == g2c), bc.Resolution);
                                end
                                occ = occ + 1;
                            end
                        end
                    end
                end
            end
        end
        if occ <= numel(mapc.Map)
            mapc.Map(occ:end) = [];
        end

    % MTCs
    case {2}

        % SRF required
        numvert = bc.NrOfVertices;
        if ipo
            if ~isfield(mapopts, 'srf') || ...
                numel(mapopts.srf) ~= 1 || ...
               ~xffisobject(mapopts.srf, true, 'srf')
                error( ...
                    'xff:BadArgument', ...
                    'Missing or bad SRF reference in map options.' ...
                );
            end
            srfs = xffgetscont(mapopts.srf.L);
            srfc = srfs.C;
            if size(srfc.Neighbors, 1) ~= numvert
                error( ...
                    'xff:BadArgument', ...
                    'Number of vertices mismatch.' ...
                );
            end
            nei = srfc.Neighbors(:, 2);
            nnei = numel(nei);
            neil = zeros(nnei, 12);
            neis = zeros(nnei, 12);
            for nc = 1:nnei
                neis(nc) = numel(nei{nc});
                neil(nc, 1:neis(nc)) = nei{nc};
            end
            neii = (neil > 0);
        end

        map = xff('new:smp');
        mapc = xffgetcont(map.L);
        mapc.FileVersion = 4;
        mapc.NrOfVertices = numvert;
        if ipo
            mapc.NameOfOriginalSRF = srfs.F;
        end
        mapc.Map.Type = 1;
        mapc.Map.NrOfLags = [];
        mapc.Map.MinLag = [];
        mapc.Map.MaxLag = [];
        mapc.Map.CCOverlay = [];
        mapc.Map.ClusterSize = 25;
        mapc.Map.EnableClusterCheck = 0;
        mapc.Map.DF1 = nval;
        mapc.Map.DF2 = 0;
        mapc.Map.BonferroniValue = bc.NrOfVoxelsForBonfCorrection;
        mapc.Map.Name = 'Contrast:';
        mapc.Map.SMPData = single(zeros(numvert, 1));
        mapc.Map(1:nummaps) = mapc.Map(1);

        % iterate over contrasts
        for cc = 1:size(c, 2)

            % get contrast
            conc = c(:, cc);
            coni = find(conc ~= 0);

            % initialize temp map
            tmpmp = zeros(numvert, numsubs);
            for pc = coni(:)'
                for sc = 1:numsubs
                    tmpmp(:, sc) = tmpmp(:, sc) + conc(pc) * ...
                        bc.GLMData.Subject(sc).BetaMaps(:, pc);
                end
            end

            % generate 2nd-level single beta-t-maps
            if ~mapopts.robust
                tmap = sqrt(numsubs) * (mean(tmpmp, 2) ./ std(tmpmp, 0, 2));
            else
                [bmaps, wmaps] = fitrobustbisquare_img(ones(numsubs, 1), tmpmp);
                tmap = robustt(ones(numsubs, 1), tmpmp, bmaps, wmaps, 1);
            end
            tmap(isinf(tmap) | isnan(tmap)) = 0;

            % interpolate ?
            if ipo
                rmap = zeros(numvert, 1);
                for nc = 1:size(neii, 2)
                    rmap(neii(:, nc)) = rmap(neii(:, nc)) + ...
                        tmap(neil(neii(:, nc), nc));
                end
                tmap = rmap ./ sum(neii, 2);
            end

            % set name and map data
            mapc.Map(cc).Name = sprintf('%s%s', mapopts.names{cc}, tmapr);
            mapc.Map(cc).SMPData = tmap;
        end

     % unknown types
    otherwise
        error( ...
            'xff:UnknownOption', ...
            'Unknown GLM ProjectType: %d', ...
            bc.ProjectType ...
        );
end

% put back
mapc.NrOfMaps = numel(mapc.Map);
xffsetcont(map.L, mapc);
