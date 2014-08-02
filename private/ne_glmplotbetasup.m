% FUNCTION ne_glmplotbetasup: update beta plot for one GLM
function ne_glmplotbetasup(varargin)

% Version:  v0.9d
% Build:    14071815
% Date:     Jul-18 2014, 3:21 PM EST
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

% global variable
global ne_gcfg;

% persistent storage of cached data
persistent ne_gpdata;
if ~isstruct(ne_gpdata)
    ne_gpdata = struct;
end

% check arguments
if nargin < 3 || ...
    numel(varargin{3}) ~= 1 || ...
   ~isxff(varargin{3}, 'glm')
    return;
end
glm = varargin{3};
glmh = handles(glm);
if ~isfield(glmh, 'PlotFig') || ...
   ~iscell(glmh.PlotFig) || ...
    isempty(glmh.PlotFig) || ...
    numel(glmh.PlotFig{1}) ~= 1 || ...
   ~isxfigure(glmh.PlotFig{1}, true)
    glm.SetHandle('PlotFig', {});
    glm.SetHandle('PlotHnd', {});
    return;
end
pfi = 1;
if nargin > 4 && ...
    ischar(varargin{5}) && ...
    numel(varargin{5}) == 8
    for fc = 1:numel(glmh.PlotFig)
        if numel(glmh.PlotFig{fc}) == 1 && ...
            isxfigure(glmh.PlotFig{fc}, true) && ...
            strcmpi(varargin{5}(:)', glmh.PlotFig{fc}.Tag(1:8))
            pfi = fc;
            break;
        end
    end
end
rtv = glm.RunTimeVars;
gid = ['GLM_' rtv.xffID];
if ~isfield(ne_gpdata, gid)
    ne_gpdata.(gid) = struct('bv', [], 'cons', [], 'coord', zeros(0, 3), 'coordx', zeros(0, 1));
end
giddata = ne_gpdata.(gid);

% get config
tstr = glmh.PlotFig{pfi}.Tag(1:8);
cc = ne_gcfg.cc.(tstr);
tags = cc.Tags;
cc = cc.Config;
rob = cc.robust;
if cc.scfmarker && ...
    any(lower(cc.scmarker) == 'dos')
    filled = {'filled'};
else
    filled = {};
end
cdata = struct( ...
    'Groups',   {cell(0, 2)}, ...
    'Means',    [], ...
    'Raw',      [], ...
    'r',        0, ...
    'rp',       1, ...
    'ScatterX', {{}}, ...
    'ScatterY', {{}}, ...
    'SE',       [], ...
    'Subsel',   [], ...
    'TrfPlus',  rtv.TrfPlus);

% sample data
cons = cc.contrasts;
if nargin > 3 && ...
    ischar(varargin{4}) && ...
    strcmp(varargin{4}(:)', 'fromdata')
    coord = ne_gcfg.cc.(tstr).Data.Coords;
elseif nargin < 4 || ...
   ~isa(varargin{4}, 'double') || ...
    ndims(varargin{4}) ~= 2 || ...
    size(varargin{4}, 2) ~= 3 || ...
    any(isinf(varargin{4}(:)) | isnan(varargin{4}(:)))
    coord = ne_gcfg.fcfg.cpos;
    radvox = cc.radvox;
    if size(radvox, 1) > 1
        coord = coord(ones(size(radvox, 1), 1), :) + radvox;
    end
else
    coord = varargin{4};
end
cdata.Coords = coord;
if ~isequal(rtv.TrfPlus, eye(4))
   coord(:, 4) = 1;
   coord = coord * inv(rtv.TrfPlus)';
   coord(:, 4) = [];
end
if isequal(cons, giddata.cons) && ...
    isequal(coord, giddata.coord)
    coordx = giddata.coordx;
    newcoords = false;
else
    giddata.cons = cons;
    giddata.coord = coord;
    coordx = bvcoordconv(coord, 'tal2bvx', cc.glmbbox);
    coordx(isinf(coordx) | isnan(coordx)) = [];
    giddata.coordx = coordx;
    newcoords = true;
end

% empty cons
if isempty(cons)

    % override type
    cc.type = 'none';

% for scatters
elseif strcmp(cc.type, 'scatter')

    % only one contrast!
    cons = cons(1, :);
    cc.contnames = cc.contnames(1);
end

% build contrast/s
if newcoords
    glmdata = glm.GLMData;
    if glm.ProjectTypeRFX > 0
        if ~isfield(rtv, 'SubjectSPMsn') || ...
           ~isstruct(rtv.SubjectSPMsn) || ...
            isempty(fieldnames(rtv.SubjectSPMsn))
            bv = zeros(max(1, numel(coordx)), numel(glmdata.Subject), ...
                size(glmdata.Subject(1).BetaMaps, ndims(glmdata.Subject(1).BetaMaps)), ...
                size(cons, 1));
            so = numel(glmdata.RFXGlobalMap);
            glmdata = {glmdata.Subject.BetaMaps};
            if ~isempty(coordx)
                for conc = 1:size(cons, 1)
                    for mc = find(cons(conc, :) ~= 0)
                        for sc = 1:size(bv, 2)
                            bv(:, sc, mc, conc) = cons(conc, mc) .* ...
                                glmdata{sc}((mc - 1) * so + coordx);
                        end
                    end
                end
            end
        else
            bv = NaN .* zeros(max(1, numel(coordx)), numel(glmdata.Subject), ...
                size(glmdata.Subject(1).BetaMaps, ndims(glmdata.Subject(1).BetaMaps)), ...
                size(cons, 1));
            so = numel(glmdata.RFXGlobalMap);
            glmdata = {glmdata.Subject.BetaMaps};
            [bvmean, bvraw, coordx] = glm.VOIBetas(coord);
            coordn = zeros(size(coordx));
            for mc = 1:numel(coordx)
                coordx{mc} = unique(coordx{mc}(coordx{mc} > 0));
                coordn(mc) = numel(coordx{mc});
            end
            for conc = 1:size(cons, 1)
                for mc = find(cons(conc, :) ~= 0)
                    for sc = 1:size(bv, 2)
                        if ~isempty(coordx{sc})
                            bv(1:coordn(sc), sc, mc, conc) = cons(conc, mc) .* ...
                                glmdata{sc}((mc - 1) * so + coordx{sc});
                        end
                    end
                end
            end
        end
    else
        subids = glm.Subjects;
        preds = glm.Predictor;
        preds = {preds(:).Name2};
        preds = preds(:);
        subpreds = glm.SubjectPredictors;
        bv = zeros(max(1, numel(coordx)), numel(subids), numel(subpreds), size(cons, 1));
        so = numel(glmdata.MCorrSS);
        glmdata = glmdata.BetaMaps;
        if ~isempty(coordx)
            bv(:) = NaN;
            for conc = 1:size(cons, 1)
                for mc = find(cons(conc, :) ~= 0)
                    for sc = 1:numel(subids)
                        try
                            bv(:, sc, mc, conc) = cons(conc, mc) .* glmdata( ...
                                (findfirst(~cellfun('isempty', regexpi(preds, sprintf( ...
                                '^subject\\s+%s\\s*:\\s*%s', subids{sc}, subpreds{mc}) ...
                                ))) - 1) * so + coordx);
                        catch ne_eo;
                            ne_gcfg.c.lasterr = ne_eo;
                        end
                    end
                end
            end
        end
    end
    giddata.bv = bv;
    ne_gpdata.(gid) = giddata;
else
    bv = giddata.bv;
end
if cc.remove0s
    bvg = (~isinf(bv) & ~isnan(bv) & (bv ~= 0));
else
    bvg = (~isinf(bv) & ~isnan(bv));
end
bv(~bvg) = 0;
bv = sum(bv, 1) ./ sum(bvg, 1);
bv(isinf(bv) | isnan(bv)) = 0;
bv = permute(sum(bv, 3), [2, 4, 1, 3]);
cdata.Raw = bv;

% get subject selection
subsel = cc.subsel;

% and remove subjects that are all zero!
subsel = intersect(subsel, find(any(any(bv ~= 0, 2), 3)));
numsubs = numel(subsel);

% and remove NaN values from scattered covariate
if strcmp(cc.type, 'scatter')
    subsel(isinf(cc.covariate(subsel, 1)) | isnan(cc.covariate(subsel, 1))) = [];
    if cc.remove0s
        subsel(cc.covariate(subsel, 1) == 0) = [];
    end
end

% prepare weights (anyway)
bvw = ones(size(bv));

% group data
ccg = cc.groups;
grpspecs = cc.grpspecs;

% no groups defined?
if isempty(cc.groups) || ...
    isempty(rtv.Groups)

    % replace with a one-group setting
    ccg = 1;
    rtv.Groups = {'Selected subjects', subsel(:)};
    grpspecs = cell(0, 3);
end

% first create data array
bvm = zeros(numel(ccg), size(bv, 2));

% and copy for SE
bvs = bvm;
gmn = false(size(bv, 1), 1);

% then iterate over groups
for gc = 1:numel(ccg)

    % get the subjects we need (heeding the subject selection!)
    gm = intersect(subsel(:), lsqueeze(rtv.Groups{ccg(gc), 2}));
    rtv.Groups{ccg(gc), 2} = gm(:);
    gmn(gm) = true;

    % data to do
    if ~isempty(gm)

        % type of computation
        if rob && ...
            numel(gm) > 2
            [bvm(gc, :), bvw(gm, :)] = robustmean(bv(gm, :), 1);
        else
            bvm(gc, :) = mean(bv(gm, :), 1);
        end

        % compute SE
        try

            % as factor, for robust
            if rob

                % use an estimate of the number of available samples
                bvs(gc, :) = std(bvw(gm, :) .* bv(gm, :) + ...
                    (1 - bvw(gm, :)) .* bvm(gc .* ones(1, numel(gm)), :), ...
                    [], 1) ./ sqrt(sum(bvw(gm, :)));

            % and for OLS
            else

                % simply use SQRT(N)
                bvs(gc, :) = std(bv(gm, :), [], 1) ./ sqrt(numel(gm));
            end
        catch ne_eo;
            ne_gcfg.c.lasterr = ne_eo;
        end
    end
end
subsel(~gmn(subsel)) = [];

% get subject IDs
subids = cc.subids;

% store data
cdata.Groups = rtv.Groups;
cdata.Means = bvm;
cdata.SE = bvs;
cdata.Subsel = subsel;
cdata.SubIDs = subids;
if cc.plotpts
    bvs = 1.96 .* bvs;
end

% get background and line color (used throughout)
bcol = min(1, max(0, cc.axcol ./ 255));
lcol = min(1, max(0, cc.linecolor ./ 255));

% compute SQRT(EPS) for safety of sizes
seps = sqrt(eps);

% and also get handles and axes shorthand
ph = glmh.PlotHnd{pfi};
ax = ph.Axes;
af = get(ax, 'Parent');

% get axes position
axpos = get(ax, 'Position');
axpos = axpos(3:4);

% plot type
switch cc.type

    % bar plots
    case {'bar'}

        % compute range
        if cc.plotpts
            barrange = minmaxmean(bv);
        else
            barrange = minmaxmean(bvm);
        end
        barrange = barrange(2) - barrange(1) + seps;

        % get number of bars (per group)
        nbg = size(bvm, 2);

        % number of groups
        onlyone = false;

        % if only one
        if size(bvm, 1) == 1

            % keep track
            onlyone = true;

            % but extend the arrays (so that the plotting works!!)
            bvm(2, :) = 0;
            bvs(2, :) = 0;
        end

        % we need to create new plot handles
        if isempty(ph.Bars) || ...
           ~ishandle(ph.Bars(1))

            % make sure the XLim's are auto
            set(ax, 'XLimMode', 'auto');

            % create the bar plot
            bh = bar(ax, bvm);

            % and keep track of the handle
            ph.Bars = bh;

            % update XLim (bug fix for ML2012b)
            xlimfixed = get(ax, 'XLim');
            xlimfixed(2) = ceil(xlimfixed(2)) - (xlimfixed(1) - floor(xlimfixed(1)));
            set(ax, 'XLim', xlimfixed);

        % handle exists
        else

            % update bar heights
            for rc = 1:size(bvm, 2)
                set(ph.Bars(rc), 'YData', bvm(:, rc)');
            end
        end

        % and ensure that the color is correct
        for rc = 1:size(bvm, 2)
            set(get(ph.Bars(rc), 'Children'), ...
                'CData', reshape(cc.barcolors(rc, :) ./ 255, [1, 1, 3]));
        end

        % make sure bar positions are known
        if isempty(ph.BarPos)

            % use an estimate for where Matlab places the bar centers
            bps = [0.5, 0.575, 2/3, 0.725, 0.775, 0.8];
            bpi = bps(min(6, size(bvm, 2)));
            barpos = (1:size(bvm, 1))' * ones(1, nbg) + ...
                ones(size(bvm, 1), 1) * ((-bpi / 2 + bpi / (2 * nbg)):bpi / nbg:bpi / 2);
            ph.BarPos = barpos;
        end
        barpos = ph.BarPos;

        % draw standard error bars
        if cc.drawse

            % compute upper and lower values
            bmu = bvm + bvs;
            bml = bvm - bvs;

            % update range?
            if ~cc.plotpts
                barrange = minmaxmean(cat(3, bmu, bml));
                barrange = barrange(2) - barrange(1) + seps;
            end

            % and compute left/right extension of error indicators
            barpol = barpos - 0.125 * 0.8 / nbg;
            barpor = barpos + 0.125 * 0.8 / nbg;

            % no error lines plotted yet?
            if isempty(ph.SEVLines) || ...
               ~ishandle(ph.SEVLines(1))

                % create empty arrays for handles
                vln = zeros(size(barpos));
                uln = vln;
                lln = vln;

                % and then plot error lines and top/bottom indicators
                for lc = 1:numel(barpos)
                    vln(lc) = line([barpos(lc), barpos(lc)], [bml(lc), bmu(lc)], 'Parent', ax);
                    uln(lc) = line([barpol(lc), barpor(lc)], [bmu(lc), bmu(lc)], 'Parent', ax);
                    lln(lc) = line([barpol(lc), barpor(lc)], [bml(lc), bml(lc)], 'Parent', ax);
                end

                % set colors
                set(vln, 'Color', lcol);
                set(uln, 'Color', lcol);
                set(lln, 'Color', lcol);

                % and store handles
                ph.SEVLines = vln;
                ph.SEULines = uln;
                ph.SELLines = lln;

            % for existing handles
            else

                % get shorthands
                vln = ph.SEVLines;
                uln = ph.SEULines;
                lln = ph.SELLines;

                % and update positions
                for lc = 1:numel(barpos)
                    set(vln(lc), 'XData', [barpos(lc), barpos(lc)], 'YData', [bml(lc), bmu(lc)]);
                    set(uln(lc), 'XData', [barpol(lc), barpor(lc)], 'YData', [bmu(lc), bmu(lc)]);
                    set(lln(lc), 'XData', [barpol(lc), barpor(lc)], 'YData', [bml(lc), bml(lc)]);
                end
            end
        end

        % definitely delete plot lines!
        if ~isempty(ph.PlotLines)
            try
                delete(ph.PlotLines);
            catch ne_eo;
                ne_gcfg.c.lasterr = ne_eo;
            end
        end

        % plot points also
        if cc.plotpts

            % no handles exist
            if isempty(ph.PlotPts) || ...
               ~ishandle(ph.PlotPts(1))

                % scatter a single point to create a handle
                ph.PlotPts = scatter(ax, [1; 1], [0; 0], [], lcol, cc.scmarker, filled{:});
            end

            % one group only (around the single group of bars)
            if onlyone

                % positions are easy to do
                spi = repmat(subsel(:), size(barpos, 2), 1);
                spx = lsqueeze(ones(numel(subsel), 1) * barpos(1, :))';
                spy = lsqueeze(bv(subsel, :))';

                % and compute weights equally simple
                wf = 0.5 .* (1 - lsqueeze(bvw(subsel, :)));

                % and color from weights
                scol = wf * bcol + (1 - wf) * lcol;

            % for several groups
            else

                % create arrays that contain the scatter positions/colors
                spx = zeros(1, numel(subsel) * size(barpos, 2));
                spy = spx;
                spi = spx;
                scol = zeros(numel(subsel) * size(barpos, 2), 3);

                % set index to 1
                sp1 = 1;

                % then iterate over groups
                for gc = 1:numel(ccg)

                    % and get the group indices (within the selection)
                    gci = intersect(rtv.Groups{ccg(gc), 2}(:), subsel);

                    % and compute the number of scatters for this group
                    spn = sp1 + numel(gci) * size(barpos, 2) - 1;

                    % then put the data into the array (using the correct
                    % bar position!!)
                    spi(sp1:spn) = repmat(gci, size(barpos, 2), 1);
                    spx(sp1:spn) = lsqueeze(ones(numel(gci), 1) * barpos(gc, :))';
                    spy(sp1:spn) = lsqueeze(bv(gci, :))';

                    % and also compute the weights and colors
                    wf = 0.5 .* (1 - lsqueeze(bvw(gci, :)));
                    scol(sp1:spn, :) = wf * bcol + (1 - wf) * lcol;

                    % then advance the index counter
                    sp1 = spn + 1;
                end

                % and finally ensure nothing went wrong
                spx = spx(1:spn);
                spy = spy(1:spn);
            end

            % set the X/Y positions and colors
            set(ph.PlotPts, 'XData', spx, 'YData', spy, 'CData', scol);

            % create handles for labels
            if cc.sublabels && ...
               (isempty(ph.SLabels) || ...
                ~ishandle(ph.SLabels(1)))

                % safe-delete remaining labels first
                slh = ph.SLabels;
                for sc = 1:numel(slh)
                    if ishandle(slh(sc))
                        delete(slh(sc));
                    end
                end

                % if plotlines are requested
                if cc.plotlines

                    % one handle per subject
                    nsh = numel(subsel);

                % otherwise
                else

                    % as many handles as points (subjects * bars)
                    nsh = numel(subsel) * size(bv, 2);
                end

                % create handles
                slh = zeros(nsh, 1);
                set(0, 'CurrentFigure', af);
                set(af, 'CurrentAxes', ax);
                for sc = 1:nsh
                    slh(sc) = text(1, 0, ' ');
                end

                % and store handles
                ph.SLabels = slh;
            end

            % and plot per-subject trend lines (for sevaral bars only)
            if cc.plotlines && ...
                size(bv, 2) > 1

                % generate array for lines
                plh = zeros(numel(subsel), 1);

                % no sub-groups
                if onlyone

                    % iterate over subjects
                    for gc = 1:numel(subsel)

                        % plot lines
                        plh(gc) = plot(ax, barpos(1, :), bv(subsel(gc), :));
                    end
                else
                    % for each group
                    plhc = 1;
                    for gc = 1:numel(ccg)

                        % get the subject indices within group/selection
                        gci = intersect(rtv.Groups{ccg(gc), 2}(:), subsel);

                        % for each subject
                        for plc = 1:numel(gci)

                            % plot a line
                            plh(plhc) = plot(ax, barpos(gc, :), bv(gci(plc), :));
                            plhc = plhc + 1;
                        end
                    end
                end

                % set color
                set(plh, 'Color', lcol);
                ph.PlotLines = plh;

                % also label subjects
                if cc.sublabels

                    % add fraction of size, depending on number of bars
                    posadd = 0.3 / nbg;

                    % for each first occurrence of a subject
                    for sc = 1:numel(subsel)
                        sci = findfirst(spi == subsel(sc));

                        % set X/Y/Text
                        set(ph.SLabels(sc), 'String', subids{subsel(sc)}, ...
                            'Position', [spx(sci) - posadd, spy(sci)]);
                    end
                    set(ph.SLabels(1:sc), 'HorizontalAlignment', 'right');
                end

            % still label subjects
            elseif cc.sublabels

                % add fraction of range
                posadd = 12 * barrange / axpos(2);

                % for each point
                for sc = 1:numel(spi)
                    set(ph.SLabels(sc), 'String', subids{spi(sc)}, ...
                        'Position', [spx(sc), spy(sc) + posadd]);
                end
                set(ph.SLabels(1:sc), 'HorizontalAlignment', 'center');
            end

        % we don't plot points (or lines)
        else

            % delete handles if not yet done
            if ~isempty(ph.PlotPts)
                try
                    delete(ph.PlotPts);
                catch ne_eo;
                    ne_gcfg.c.lasterr = ne_eo;
                end
            end

            % and set arrays to empty
            ph.PlotLines = [];
            ph.PlotPts = [];
        end

        % legend
        if cc.legbars

            % create legend
            if numel(ph.Legend) ~= 1 || ...
               ~ishandle(ph.Legend)
                cc.contnames = strrep(cc.contnames, '_', ' ');
                [ph.Legend, ph.LegObj] = legend(ax, cc.contnames{:}, ...
                    'Location', cc.legpos);
            end

            % set colors
            nlo = 0.5 * numel(ph.LegObj);
            for rc = 1:size(bv, 2)
                lo = get(ph.LegObj(nlo + rc), 'Children');
                set(lo, 'CData', reshape(cc.barcolors(rc, :) ./ 255, [1, 1, 3]));
            end
        end

        % set group labels (if any)
        set(ax, 'XTick', 1:numel(ccg), 'XTickLabel', rtv.Groups(ccg, 1));

        % correct Matlab bug with width of bar graph!
        if onlyone
            set(ax, 'XLim', [0.5, 1.5]);
        end

        % scatter
    case {'scatter'}

        % put data together for scattering
        if ~cc.scgroups || ...
            isempty(grpspecs) || ...
            isempty(ccg)
            ccg = 1;
            grpspecs = {cc.scmarker, cc.linecolor, ...
                [cc.scstats, cc.scline, cc.quadratic, cc.scellipse]};
            rtv.Groups = {'Selected subjects', subsel(:)};

            % rank-transform
            if cc.ranktrans
                nsubsel = 1:numel(cc.covariate);
                bv(subsel, 1) = ranktrans(bv(subsel, 1), 1);
                bv(subsel, 1) = bv(subsel, 1) - mean(bv(subsel, 1));
                cc.covariate(subsel) = ranktrans(cc.covariate(subsel), 1);
                cc.covariate(subsel) = cc.covariate(subsel) - ...
                    mean(cc.covariate(subsel));
                nsubsel(subsel) = [];
                if ~isempty(nsubsel)
                    bv(nsubsel, 1) = 0;
                    cc.covariate(nsubsel) = 0;
                end
            end

        % per-group rank-transform
        elseif cc.ranktrans

            % iterate over groups
            nsubsel = 1:numel(cc.covariate);
            for gc = numel(ccg)

                % transform only selected subjects
                subsel = rtv.Groups{ccg(gc), 2};
                nsubsel(subsel) = [];
                if numel(subsel) > 1
                    bv(subsel, 1) = ranktrans(bv(subsel, 1), 1);
                    bv(subsel, 1) = bv(subsel, 1) - mean(bv(subsel, 1));
                    cc.covariate(subsel) = ranktrans(cc.covariate(subsel), 1);
                    cc.covariate(subsel) = cc.covariate(subsel) - ...
                        mean(cc.covariate(subsel));
                elseif ~isempty(subsel)
                    bv(subsel, 1) = 0;
                    cc.covariate(subsel) = 0;
                end
            end
            if ~isempty(nsubsel)
                bv(nsubsel, 1) = 0;
                cc.covariate(nsubsel) = 0;
            end
        end

        % get range we need to plot
        bvmmm = minmaxmean(bv(:, 1), 1);
        scmmm = minmaxmean(cc.covariate, 1);

        % get automatic range (also used to construct line)
        % add fix so that minimal range is not just 2 * seps
        scrange = cc.scrange;
        scrangea = [scmmm(1) + 0.15 * (scmmm(1) - scmmm(2)) - seps, ...
            bvmmm(1) + 0.15 * (bvmmm(1) - bvmmm(2)) - seps, ...
            scmmm(2) + 0.15 * (scmmm(2) - scmmm(1)) + seps, ...
            bvmmm(2) + 0.15 * (bvmmm(2) - bvmmm(1)) + seps];

        % compute position additive
        dposx = scrangea(3) - scrangea(1);
        dposy = scrangea(4) - scrangea(2);

        % set auto range
        ne_gcfg.cc.(tstr).Config.scrangea = scrangea;

        % and import into range
        if any(isinf(scrange))
            scrange(isinf(scrange)) = scrangea(isinf(scrange));
        end

        % for each group
        obv = bv;
        subi = 0;
        subt = numel(cat(1, rtv.Groups{ccg, 2}));
        set(0, 'CurrentFigure', af);
        set(af, 'CurrentAxes', ax);
        for gc = 1:numel(ccg)

            % potentially create handles
            scsym = grpspecs{ccg(gc), 1};
            lcol = grpspecs{ccg(gc), 2} ./ 255;
            if numel(ph.Scatters) ~= numel(ccg) || ...
               ~ishandle(ph.Scatters(gc))
                ph.Scatters(gc) = ...
                    scatter(ax, scmmm(3), bvmmm(3), [], lcol, scsym, filled{:});
            end
            if grpspecs{ccg(gc), 3}(1) && ...
               (numel(ph.Text) ~= numel(ccg) || ...
                ~ishandle(ph.Text(gc)))
                ph.Text(gc) = text(scmmm(3), bvmmm(3), ' ');
            end
            if grpspecs{ccg(gc), 3}(2) && ...
               (numel(ph.ScLines) ~= numel(ccg) || ...
                ~ishandle(ph.ScLines(gc)))
                ph.ScLines(gc) = plot(ax, scmmm(1:2), bvmmm(1:2), 'Color', lcol);
            end
            if grpspecs{ccg(gc), 3}(4) && ...
               (numel(ph.ScEllipse) ~= numel(ccg) || ...
                ~ishandle(ph.ScEllipse(gc)))
                ph.ScEllipse(gc) = plot(ax, scmmm(1:2), bvmmm(1:2), 'Color', lcol);
            end
            if cc.sublabels && ...
               (numel(ph.SLabels) ~= subt || ...
                ~ishandle(ph.SLabels(subt)))
                slh = ph.SLabels;
                for sc = 1:numel(slh)
                    if ishandle(slh(sc))
                        delete(slh(sc));
                    end
                end
                slh = zeros(subt, 1);
                for sgc = 1:numel(ccg)
                    ssubsel = rtv.Groups{ccg(sgc), 2};
                    for slc = 1:numel(ssubsel)
                        subi = subi + 1;
                        slh(subi) = text(scmmm(3), bvmmm(3), subids{ssubsel(slc)});
                    end
                end
                ph.SLabels = slh;

                % fix Matlab bug !!
                set(slh, 'Parent', ax);
                subi = 0;
            end

            % get subsel
            subsel = rtv.Groups{ccg(gc), 2};

            % no one in group
            if isempty(subsel)

                % unset data
                set(ph.Scatters(gc), 'XData', [], 'YData', [], 'CData', zeros(0, 3));

                % don't do anything else
                continue;
            end

            % limit to first one (and subject selection)
            bv = obv(subsel, 1);
            cv = cc.covariate(subsel);
            cdata.ScatterX{ccg(gc)} = cv(:);
            cdata.ScatterY{ccg(gc)} = bv(:);

            % compute mean
            scn = numel(bv);
            mcv = meannoinfnan(cv);

            % quadratic regression
            if grpspecs{ccg(gc), 3}(3)

                % create orthogonzalied design matrix with
                % - mean removed and
                % - squared of mean removed with its own mean removed and
                % - a column of 1's
                sX = [cv - mcv, zeros(scn, 1), ones(scn, 1)];
                qcv = sX(:, 1) .* sX(:, 1);
                mqcv = mean(qcv);
                sX(:, 2) = qcv - mqcv;

            % simple regression
            else
                sX = [cv - mcv, ones(scn, 1)];
            end

            % robust regression
            if rob

                % get betas, residuals, weights
                [regb, regr, sw] = fitrobustbisquare(sX, bv);

                % and compute sum of square of residual
                regsse = sum(sw .* sw .* regr .* regr);

            % for OLS
            else

                % use pinv
                regb = pinv(sX' * sX) * sX' * bv;

                % and set weights to 1
                sw = ones(scn, 1);
            end

            % if stats printout is requested
            if grpspecs{ccg(gc), 3}(1)

                % get sum of weights as an estimate for DF portion
                sws = sum(sw);

                % and compute df1/df2
                df1 = numel(regb) - 1;
                df2 = sws - numel(regb);

                % if stats seem useful at all
                if sws >= 2

                    % for robust stats
                    if rob

                        % get robust F value
                        regf = robustF(sX, bv, regb, sw, [ones(1, numel(regb) - 1), 0]);

                        % and compute R squared in reverse using this
                        R2 = correlinvtstat(-sdist('tinv', 0.5 * ...
                            sdist('fcdf', regf, df1, df2, true), df2), sws) .^ 2;

                        % and then compute the SS of the regression this way
                        regssr = regf * regsse * df1 / df2;

                    % for OLS regression
                    else

                        % compute the predicted values
                        regp = sX * regb;

                        % and then the residual
                        resb = bv - regp;

                        % the SS or error and SS or regression
                        regsse = sum(resb .* resb);
                        regssr = sum((regp - mean(regp)) .^ 2);

                        % the total SS
                        regsst = regsse + regssr;

                        % and then the adjusted R squared
                        R2 = max(0, 1 - ((scn - 1) / df2) * (1 - regssr / regsst));
                    end

                    % compute probability
                    regprob = sdist('fcdf', ...
                        df2 * regssr / (df1 * regsse), df1, df2, true);
                % stats useless?
                else

                    % set R2 to 0 and regprob to 1
                    R2 = 0;
                    regprob = 1;
                end
            end

            % compute colors from weights (up to half transparent)
            wf = 0.5 * (1 - sw(:));
            scol = wf * bcol + (1 - wf) * lcol;

            % update scatter
            set(ph.Scatters(gc), 'XData', cv(:), 'YData', bv, 'CData', scol);

            % text display position depending on output of regression line
            if regb(1) > 0 && ...
                numel(ccg) == 1
                py = 0.025 + (0.08 * gc);
            else
                py = 1.025 - (0.08 * gc);
            end

            % actual stats output
            if grpspecs{ccg(gc), 3}(1)

                % compute X/Y position
                py = scrange(2) + py * (scrange(4) - scrange(2));

                % create printed string
                if numel(ccg) > 1
                    px = scrange(1) + 0.025 * (scrange(3) - scrange(1));
                    R2s = sprintf('%s: adj. R2 = %.3f\np = %.4f', ...
                        rtv.Groups{ccg(gc), 1}, R2, min(1, regprob));
                else
                    px = scrange(1) + 0.8 * (scrange(3) - scrange(1));
                    R2s = sprintf('adj. R2 = %.3f\np = %.4f', R2, min(1, regprob));
                end

                % update values
                set(ph.Text(gc), 'String', R2s, 'Position', [px, py, 0]);
            end

            % also plot a line of fit
            if grpspecs{ccg(gc), 3}(2)

                % quadratic line
                if grpspecs{ccg(gc), 3}(3)

                    % create a relatively smooth X range
                    lx = (scrangea(1):((scrangea(3) - scrangea(1)) / axpos(1)):scrangea(3))';

                    % and compute fitted response for range
                    ly = [lx - mcv, (lx - mcv) .^ 2 - mqcv, ones(numel(lx), 1)] * regb;

                    % set X/Y data
                    set(ph.ScLines(gc), 'XData', lx, 'YData', ly);

                % linear fit
                else

                    % get end points of line
                    ly1 = regb(2) + (scrangea(1) - mcv) * regb(1);
                    ly2 = regb(2) + (scrangea(3) - mcv) * regb(1);

                    % set X/Y data
                    set(ph.ScLines(gc), 'XData', scrangea([1, 3]), 'YData', [ly1, ly2]);
                end
            end

            % also plot a confidence ellipse
            if grpspecs{ccg(gc), 3}(4)

                % for robust regression
                if rob

                    % compute the ellipse from the mix between actual and
                    % predicted data (depending on weight, slightly liberal)
                    [scex, scey] = cellipse(cv, ...
                        sw .* bv + (1 - sw) .* (sX * regb));

                % for OLS
                else

                    % straight compute ellipse
                    [scex, scey] = cellipse(cv, bv);
                end

                % update X/Y data
                set(ph.ScEllipse(gc), 'XData', scex, 'YData', scey);
            end

            % add subject labels (texts)
            if cc.sublabels

                % for each handle/subject
                slh = ph.SLabels;
                for slc = 1:numel(subsel)

                    % update position
                    subi = subi + 1;
                    set(slh(subi), 'Position', ...
                        [cv(slc) + (8 / axpos(1)) * dposx, ...
                         bv(slc) + (8 / axpos(2)) * dposy]);
                end
            end
        end

        % legend
        if cc.legscat

            % create legend
            if numel(ph.Legend) ~= 1 || ...
               ~ishandle(ph.Legend)
                contnames = repmat(strrep(cc.contnames(1), '_', ' '), ...
                    numel(ph.Scatters), 1);
                if numel(ccg) > 1
                    for rc = 1:numel(ccg)
                        contnames{rc} = ...
                            [contnames{rc} ' (' rtv.Groups{ccg(rc), 1} ')'];
                    end
                end
                [ph.Legend, ph.LegObj] = legend(ax, ph.Scatters, ...
                    contnames{:}, 'Location', cc.legpos);
            end

            % set colors
            nlo = 0.5 * numel(ph.LegObj);
            for rc = 1:numel(ph.Scatters)
                lo = get(ph.LegObj(nlo + rc), 'Children');
                set(lo, 'CData', reshape(grpspecs{ccg(gc), 2} ./ 255, [1, 1, 3]));
            end
        end

        % update axes limits to requested range
        if scrange(3) - scrange(1) < 0.001
            scrange([1, 3]) = 0.5 * sum(scrange([1, 3])) + [-0.0005, 0.0005];
        end
        if scrange(4) - scrange(2) < 0.001
            scrange([2, 4]) = 0.5 * sum(scrange([2, 4])) + [-0.0005, 0.0005];
        end
        set(ax, 'XLim', scrange([1, 3]), 'YLim', scrange([2, 4]));
end

% update title and labels
if cc.title
    if isnumeric(coordx)
        coordxyz = bvcoordconv(coordx, 'bvx2tal', cc.glmbbox);
    else
        coordxyz = coord;
    end
    if size(coordxyz, 1) > 1
        coordxyz = mean(coordxyz, 1);
        if isnumeric(coordx)
            titlepart = sprintf('%d voxels around', numel(coordx));
        else
            numvox = cellfun(@numel, coordx);
            titlepart = sprintf('~%d voxels around', median(numvox));
        end
    else
        titlepart = 'single voxel at';
    end
    titlesubs = sprintf('%d subjects', numsubs);
    if cc.robust
        titlerob = ' (robust)';
    else
        titlerob = '';
    end
    titlepart = sprintf(', %s [%s, %s, %s], %s%s', titlepart, ...
        ddeblank(sprintf('%.3g', coordxyz(1))), ...
        ddeblank(sprintf('%.3g', coordxyz(2))), ...
        ddeblank(sprintf('%.3g', coordxyz(3))), titlesubs, titlerob);
    if isempty(ph.Title) || ...
       ~ishandle(ph.Title)
        ph.Title = title(ax, [cc.titlestr, titlepart]);
    else
        set(ph.Title, 'String', [cc.titlestr, titlepart]);
    end
    if isempty(ph.AxesLabel) || ...
       ~ishandle(ph.AxesLabel(1))
        ph.AxesLabel = [xlabel(ax, cc.xlabel), ylabel(ax, cc.ylabel)];
    else
        set(ph.AxesLabel(1), 'String', cc.xlabel);
        set(ph.AxesLabel(2), 'String', cc.ylabel);
    end
end

% fix background color
set(ax, 'Color', (1 / 255) .* cc.axcol);

% update handles
glmh = handles(glm);
glmh.PlotHnd{pfi} = ph;
glm.SetHandle('PlotHnd', glmh.PlotHnd);

% update X-range ?
if ~any(isinf(cc.xrange))
    set(ax, 'XLim', cc.xrange);
end

% update range text boxes
axp = get(ax);
tags.XFrom.String = sprintf('%.2f', axp.XLim(1));
tags.XTo.String = sprintf('%.2f', axp.XLim(2));
tags.YFrom.String = sprintf('%.2f', axp.YLim(1));
tags.YTo.String = sprintf('%.2f', axp.YLim(2));

% update data
ne_gcfg.cc.(tstr).Data = cdata;
