% FUNCTION ne_cm_compute: compute contrasts
function ne_cm_compute(varargin)

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:03 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2014, Jochen Weber
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

% global variable
global ne_gcfg;
cc = ne_gcfg.fcfg.CM;
ch = ne_gcfg.h.CM.h;
cp = ne_gcfg.h.Progress;

% get correct GLM
glm = cc.glm;
glmisrfx = (glm.ProjectTypeRFX > 0);

% get options -> covariates
covs = cc.covs(ch.Covs.Value, :);

% -> OLS/robust?
ols = (ch.OLSOnly.Value > 0 || ch.OLSRobust.Value > 0);
rob = (ch.Robust.Value > 0  || ch.OLSRobust.Value > 0);
rtr = (ch.RankTrans.Value > 0);

% -> global mean?
covgm = (ch.AddGlobalMean.Value > 0);
allrs = (ch.AllRegressors.Value > 0) && ...
    strcmpi(ch.AllRegressors.Enable, 'on');

% -> RFX stats?
rfx = (ch.RFXstats.Value > 0);
if ~rfx
    covs = [];
    ols = true;
    rob = false;
    rtr = false;
    covgm = false;
    allrs = false;
    ffxtype = glm.SeparatePredictors;
    glmp = glm.Predictor;
    glmp = {glmp(:).Name2};
    glmp = glmp(:);
    glmsp = glm.SubjectPredictors;
    subsel = ch.Subjects.Value(:)';
    subjects = glm.Subjects;
end

% and contrasts
cons = cc.cons;
if isempty(cons)
    cons = {'interactive', ne_cm_getweights};
end

% only one contrast
if nargin > 2 && ...
    isa(varargin{3}, 'double') && ...
    numel(varargin{3}) == 1 && ...
    varargin{3} == 1
    cons = cons(ch.Contrasts.Value, :);

% make selection
elseif size(cons, 1) > 1
    coni = listdlg( ...
        'ListString', cons(:, 1), ...
        'SelectionMode', 'multiple', ...
        'ListSize', [min(640, max(320, 10 * size(char(cons(:, 1)), 2))), 360], ...
        'InitialValue', (1:size(cons, 1)), ...
        'Name', 'NeuroElf - user input', ...
        'PromptString', 'Please select contrasts to run...');
    if isempty(coni)
        return;
    end
    cons = cons(coni, :);
end

% one of many VMP-selection
vmpbbox = [];
if ~isempty(cc.vmp)
    cc.vmp = cc.vmp(ch.StoreInVMP.Value);
    if ~isempty(cc.vmp) && ...
       ~isempty(cc.vmp{1}) && ...
        isxff(cc.vmp{1}, 'vmp')
        vmpbbox = cc.vmp{1}.BoundingBox;
    end
end

% general options
imeths = {'linear', 'cubic', 'lanczos3'};
opts = struct( ...
    'allrs',  allrs, ...
    'bbox',   vmpbbox, ...
    'brange', [-Inf, Inf], ...
    'cnames', {cons(1, 1)}, ...
    'const',  true, ...
    'groups', [], ...
    'imeth',  imeths{ch.InterpMethod.Value}, ...
    'meanr',  covgm, ...
    'rank',   rtr, ...
    'rnames', {{}}, ...
    'robust', rob, ...
    'smk',    0, ...
    'subsel', ch.Subjects.Value(:)');
if ch.SmoothData.Value > 0
    try
        opts.smk = str2double(ch.SmoothDataKernel.String(:)');
    catch ne_eo;
        ne_gcfg.c.lasterr = ne_eo;
    end
    if ch.BRange.Value > 0
        try
            opts.brange = [str2double(ch.BRangeMin.String(:)'), ...
                str2double(ch.BRangeMax.String(:)')];
            if any(isnan(opts.brange)) || ...
                opts.brange(1) >= opts.brange(2)
                opts.brange = [-Inf, Inf];
            end
        catch ne_eo;
            ne_gcfg.c.lasterr = ne_eo;
        end
    end
end

% use groups?
if cc.usegroups
    for gc = 1:size(cc.groups, 1)
        if numel(cc.groups{gc, 2}) < 3
            uiwait(warndlg(sprintf('Too few subjects in group %d.', gc), ...
                'NeuroElf - error', 'modal'));
            return;
        end
    end
else
    if rfx && ...
        numel(opts.subsel) < 3
        uiwait(warndlg('Too few subjects selected.', 'NeuroElf - error', 'modal'));
        return;
    end
end
rgroups = {[]};
if cc.usegroups && ...
    ch.GroupCmp.Value > 0
    opts.groups = cc.groups;
elseif cc.usegroups && ...
   ~isempty(cc.groups)
    rgroups = cc.groups;
end

% initialize progress in main fig
numcalc = 0;
if ~allrs
    numcovs = numel(covs);
else
    numcovs = 1;
end
ngroups = size(rgroups, 1);
numcalcs = max(1, numcovs) * size(cons, 1) * ngroups;
ne_gcfg.h.CM.CMFig.Visible = 'off';
drawnow;
ne_cm_updatertv(0, 0, glm, true);
cp.Progress(0, sprintf('Computing map %d of %d...', numcalc + 1, numcalcs));
cp.Visible = 'on';

% iterate over groups selection
for gc = 1:ngroups

    % adapt subject selection?
    if ischar(rgroups{gc, 1})
        opts.subsel = rgroups{gc, 2}(:)';
    end

    % iterate over contrasts
    for cnc = 1:size(cons, 1)

        % get contrast vector
        conc = cons{cnc, 2}(:)';
        opts.cnames = cons(cnc, 1);
        opts.names = cons(cnc, 1);

        % empty covariates
        if isempty(covs)

            % compute contrast
            cp.Progress(numcalc / numcalcs, ...
                sprintf('Computing map %d of %d...', numcalc + 1, numcalcs));
            opts.robust = rob;

            % RFX
            if rfx
                if ne_gcfg.c.echo
                    ne_echo('glm', 'RFX_tMap', conc, opts);
                end
                pmap = glm.RFX_tMap(conc, opts);
                if ~glmisrfx
                    for mc = 1:size(pmap.Map)
                        pmap.Map(mc).Name = [pmap.Map(mc).Name ' (RFX)'];
                    end
                end

            % for FFX
            else

                % initialize cvals
                cvals = zeros(1, numel(glmp));
                cvon = find(conc ~= 0);
                cvon = cvon(:)';

                % depending on type of
                switch (ffxtype)

                    % no separation
                    case {0}

                        % simply set the first few values
                        cvals(1:numel(conc)) = conc;

                    % by study separation
                    case {1}

                        % iterate over selected studies
                        for stuc = 1:numel(subsel)

                            % get indices of studies that match
                            studi = find(~cellfun('isempty', regexpi(glmp, ...
                                sprintf('^study\\s+%d:', subsel(stuc)))));

                            % within those
                            for cvc = cvon
                                cvoni = studi(findfirst(~cellfun('isempty', regexpi( ...
                                    glmp(studi), glmsp{cvc}))));
                                if ~isempty(cvoni)
                                    cvals(cvoni) = conc(cvc);
                                end
                            end

                            % check
                            if sum(cvals(studi) ~= 0) ~= numel(cvon)

                                % re-set to 0 if contrast is not fully defined
                                cvals(studi) = 0;
                            end
                        end

                    % by subject separation
                    case {2}

                        % iterate over selected subjects
                        for stuc = 1:numel(subsel)

                            % get indices of studies that match
                            subi = find(~cellfun('isempty', regexpi(glmp, ...
                                sprintf('^subject\\s+%s:', subjects{subsel(stuc)}))));

                            % within those
                            for cvc = cvon
                                cvoni = subi(findfirst(~cellfun('isempty', regexpi( ...
                                    glmp(subi), glmsp{cvc}))));
                                if ~isempty(cvoni)
                                    cvals(cvoni) = conc(cvc);
                                end
                            end

                            % check
                            if sum(cvals(subi) ~= 0) ~= numel(cvon)

                                % re-set to 0 if contrast is not fully defined
                                cvals(subi) = 0;
                            end
                        end
                end

                % then compute FFX map
                if ne_gcfg.c.echo
                    ne_echo('glm', 'FFX_tMap', cvals, opts);
                end
                pmap = glm.FFX_tMap(cvals, opts);
                switch (ffxtype)
                    case {0}
                        pmap.Map.Name = [pmap.Map.Name ' (Overall-FFX)'];
                    case {1}
                        pmap.Map.Name = [pmap.Map.Name ' (SepSubjects-FFX)'];
                    case {2}
                        pmap.Map.Name = [pmap.Map.Name ' (SepStudies-FFX)'];
                end
            end

            % both OLS and robust (only available via RFX!)
            if ols && rob
                opts.robust = false;
                if ne_gcfg.c.echo
                    ne_echo('glm', 'RFX_tMap', conc, opts);
                end
                pmapo = glm.RFX_tMap(conc, opts);
                pmap.Map = catstruct(pmapo.Map(:), pmap.Map(:))';
                pmapo.ClearObject;
                pmap.NrOfMaps = numel(pmap.Map);
            end

            % move on
            numcalc = numcalc + 1;
            cp.Progress(numcalc / numcalcs, ...
                sprintf('Computed map %d of %d...', numcalc, numcalcs));

        % with covariates
        else

            % re-set names
            opts.names = {};

            % iterate over covariates
            if ~allrs
                for cvc = 1:size(covs, 1)

                    % compute rMap(s)
                    cp.Progress(numcalc / numcalcs, ...
                        sprintf('Computing map %d of %d...', numcalc + 1, numcalcs));
                    opts.rnames = covs(cvc, 1);
                    if ne_gcfg.c.echo
                        ne_echo('glm', 'RFX_rMap', conc, covs{cvc, 2}(:), opts);
                    end
                    ppmap = glm.RFX_rMap(conc, covs{cvc, 2}(:), opts);

                    % this one of add
                    if cvc == 1
                        pmap = ppmap;
                    else
                        pmap.Map(end+1:end+numel(ppmap.Map)) = ppmap.Map;
                        ppmap.ClearObject;
                    end

                    % move on
                    numcalc = numcalc + 1;
                    cp.Progress(numcalc / numcalcs, ...
                        sprintf('Computed map %d of %d...', numcalc, numcalcs));
                end
            else

                % compute rMap(s)
                cp.Progress(numcalc / numcalcs, ...
                    sprintf('Computing regression %d of %d...', numcalc + 1, numcalcs));
                opts.rnames = covs(:, 1);
                if ne_gcfg.c.echo
                    ne_echo('glm', 'RFX_rMap', conc, cat(2, covs{:, 2}), opts);
                end
                pmap = glm.RFX_rMap(conc, cat(2, covs{:, 2}), opts);

                % move on
                numcalc = numcalc + 1;
                cp.Progress(numcalc / numcalcs, ...
                    sprintf('Computed regression %d of %d...', numcalc, numcalcs));
            end
        end

        % rename separate group maps
        if size(rgroups, 1) > 1
            for tmc = 1:numel(pmap.Map)
                pmap.Map(tmc).Name = sprintf('%s (%s)', ...
                    pmap.Map(tmc).Name, rgroups{gc, 1});
            end
        end

        % first contrast
        if gc == 1 && ...
            cnc == 1
            tmap = pmap;
        else
            tmap.Map = catstruct(tmap.Map(:), pmap.Map(:))';
            pmap.ClearObject;
        end
    end
end

% remove OLS maps
if ~ols
    for mc = numel(tmap.Map):-1:1
        if isempty(strfind(tmap.Map(mc).Name, 'robust'))
            tmap.Map(mc) = [];
        end
    end
end

% new VMP requested/necessary
if isempty(cc.vmp) || ...
    isempty(cc.vmp{1}) || ...
   ~isxff(cc.vmp{1}, 'vmp')

    % bless, so we keep this
    cc.vmp = bless(tmap);
    tmapi = 1;
    created = true;

% existing VMP
else
    cc.vmp = cc.vmp{1};
    tmapi = numel(cc.vmp.Map) + 1;
    cc.vmp.Map = catstruct(cc.vmp.Map(:), tmap.Map(:))';
    tmap.ClearObject;
    created = false;
end

% make sure the colors in new maps are set
cc.vmp.SetColors(tmapi:numel(cc.vmp.Map), 'xauto');

% set SourceGLM handle in VMP object
cc.vmp.SetHandle('SourceGLM', glm);

% and set RTV saving to auto
cc.vmp.RunTimeVars.AutoSave = true;

% show/update correct VMP
ne_openfile(0, 0, cc.vmp, created);

% and then show the first of the newly created maps
ne_gcfg.fcfg.StatsVarIdx = tmapi;
ne_gcfg.h.StatsVarMaps.Value = tmapi;
ne_setcstatmap;

% finally bring up UI again
cp.Visible = 'off';
ne_gcfg.h.CM.CMFig.Visible = 'on';

% and re-set current GLM (to re-load VMPs etc.)
ne_cm_setglm;
