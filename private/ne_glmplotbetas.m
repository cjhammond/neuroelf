% FUNCTION ne_glmplotbetas: initialize beta plotter for current GLM
function varargout = ne_glmplotbetas(varargin)

% Version:  v0.9d
% Build:    14071816
% Date:     Jul-18 2014, 4:51 PM EST
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
cc = ne_gcfg.fcfg;
cini = ne_gcfg.c.ini;

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% don't do anything if current var is no usable GLM
if nargin < 3 || ...
    numel(varargin{3}) ~= 1 || ...
   ~isxff(varargin{3}, 'glm')
    stvar = cc.StatsVar;
else
    stvar = varargin{3};
end
if numel(stvar) ~= 1 || ...
   ~isxff(stvar, 'glm') || ...
   (stvar.ProjectTypeRFX < 1 && ...
    stvar.SeparatePredictors ~= 2)
    if isxff(stvar, 'glm')
        uiwait(warndlg('Plotting betas only for RFX or SPSB GLMs.', ...
            'NeuroElf GUI - error', 'modal'));
    end
    return;
end

% don't plot twice!
gh = handles(stvar);
if ~isfield(gh, 'PlotFig') || ...
   ~iscell(gh.PlotFig)
    stvar.SetHandle('PlotFig', {});
    stvar.SetHandle('PlotHnd', {});
    gh = handles(stvar);
end
if ~isempty(gh.PlotFig) && ...
    isxfigure(gh.PlotFig{1}, true) && ...
   ~cini.BetaPlot.MultiInstance
    if nargout > 0
        varargout{1} = gh.PlotHnd{1}.Axes;
        if nargout > 1
            varargout{2} = gh.PlotFig{1}.Tag(1:8);
        end
    end
    return;
end

% try to load the plotting figure
try
    hFig = xfigure([neuroelf_path('tfg') '/ne_glmbetaplot.tfg']);
catch ne_eo;
    warning( ...
        'neuroelf:xfigureError', ...
        'Error loading plotting figure: %s.', ...
        ne_eo.message ...
    );
end
hTag = hFig.TagStruct;
tstr = hFig.Tag(1:8);

% tag shortcuts
hTag.Axes = hTag.(['AX_' tstr '_Plot']);
hTag.BackColor = hTag.(['BT_' tstr '_BGrC']);
hTag.ClonePlot = hTag.(['UIM_' tstr '_ClPlot']);
hTag.CondColors = hTag.(['BT_' tstr '_CndC']);
hTag.Conditions = hTag.(['LB_' tstr '_Cond']);
hTag.ContColors = hTag.(['BT_' tstr '_CtrC']);
hTag.Contrasts = hTag.(['LB_' tstr '_Cons']);
hTag.CopyData = hTag.(['UIM_' tstr '_CData']);
hTag.CopyPlot = hTag.(['UIM_' tstr '_CPlot']);
hTag.Covariates = hTag.(['LB_' tstr '_Covs']);
hTag.DoGroups = hTag.(['CB_' tstr '_UGrp']);
hTag.DoUpdate = hTag.(['CB_' tstr '_Up2d']);
hTag.EBars = hTag.(['CB_' tstr '_EBar']);
hTag.EBarColors = hTag.(['BT_' tstr '_BarC']);
hTag.Groups = hTag.(['LB_' tstr '_Grps']);
hTag.LegendBars = hTag.(['UIM_' tstr '_OptLB']);
hTag.LegendScat = hTag.(['UIM_' tstr '_OptLS']);
hTag.LegPosNE = hTag.(['UIM_' tstr '_OptLNE']);
hTag.LegPosNW = hTag.(['UIM_' tstr '_OptLNW']);
hTag.LegPosSE = hTag.(['UIM_' tstr '_OptLSE']);
hTag.LegPosSW = hTag.(['UIM_' tstr '_OptLSW']);
hTag.OptVis = hTag.(['CB_' tstr '_OVis']);
hTag.Options = hTag.(['UIM_' tstr '_Opt']);
hTag.PPts = hTag.(['CB_' tstr '_PPts']);
hTag.Radius = hTag.(['ED_' tstr '_SRad']);
hTag.RankTrans = hTag.(['UIM_' tstr '_OptRT']);
hTag.Remove0s = hTag.(['UIM_' tstr '_OptRZ']);
hTag.Robust = hTag.(['UIM_' tstr '_OptRS']);
hTag.SAxes = hTag.(['UIM_' tstr '_SAxes']);
hTag.SFigure = hTag.(['UIM_' tstr '_SFig']);
hTag.SFullAxes = hTag.(['UIM_' tstr '_SFlAx']);
hTag.ScConfEllipse = hTag.(['UIM_' tstr '_OptCE']);
hTag.ScFilledMarkers = hTag.(['UIM_' tstr '_OptMF']);
hTag.ScGroups = hTag.(['UIM_' tstr '_OptSG']);
hTag.ScLine = hTag.(['UIM_' tstr '_OptSL']);
hTag.ScMarkAsterisk = hTag.(['UIM_' tstr '_OptMa']);
hTag.ScMarkCircle = hTag.(['UIM_' tstr '_OptMo']);
hTag.ScMarkDiamond = hTag.(['UIM_' tstr '_OptMd']);
hTag.ScMarkPeriod = hTag.(['UIM_' tstr '_OptMp']);
hTag.ScMarkPlus = hTag.(['UIM_' tstr '_OptMc']);
hTag.ScMarkSquare = hTag.(['UIM_' tstr '_OptMs']);
hTag.ScMarkX = hTag.(['UIM_' tstr '_OptMx']);
hTag.ScQuadratic = hTag.(['UIM_' tstr '_OptSQ']);
hTag.ShowGenInfo = hTag.(['UIM_' tstr '_OptGI']);
hTag.StatsOut = hTag.(['UIM_' tstr '_OptSO']);
hTag.SubLabels = hTag.(['UIM_' tstr '_OptST']);
hTag.SubLines = hTag.(['UIM_' tstr '_OptSP']);
hTag.SubSel = hTag.(['UIM_' tstr '_OptSS']);
hTag.Type = hTag.(['DD_' tstr '_Type']);
hTag.XFrom = hTag.(['ED_' tstr '_AxX1']);
hTag.XTo = hTag.(['ED_' tstr '_AxX2']);
hTag.YFrom = hTag.(['ED_' tstr '_AxY1']);
hTag.YTo = hTag.(['ED_' tstr '_AxY2']);

% set update callbacks
hTag.BackColor.Callback = {@ne_glmplotbetasgui, tstr, 'BackColor'};
hTag.ClonePlot.Callback = {@ne_glmplotbetasgui, tstr, 'ClonePlot'};
hTag.CondColors.Callback = {@ne_glmplotbetasgui, tstr, 'CondColors'};
hTag.Conditions.Callback = {@ne_glmplotbetasgui, tstr, 'Conditions'};
hTag.ContColors.Callback = {@ne_glmplotbetasgui, tstr, 'ContColors'};
hTag.Contrasts.Callback = {@ne_glmplotbetasgui, tstr, 'Contrasts'};
hTag.CopyData.Callback = {@ne_glmplotbetasgui, tstr, 'CopyData'};
hTag.CopyPlot.Callback = {@ne_glmplotbetasgui, tstr, 'CopyPlot'};
hTag.Covariates.Callback = {@ne_glmplotbetasgui, tstr, 'Covariates'};
hTag.DoGroups.Callback = {@ne_glmplotbetasgui, tstr, 'DoGroups'};
hTag.DoUpdate.Callback = {@ne_glmplotbetasgui, tstr, 'DoUpdate'};
hTag.EBars.Callback = {@ne_glmplotbetasgui, tstr, 'EBars'};
hTag.EBarColors.Callback = {@ne_glmplotbetasgui, tstr, 'EBarColors'};
hTag.Groups.Callback = {@ne_glmplotbetasgui, tstr, 'Groups'};
hTag.LegendBars.Callback = {@ne_glmplotbetasgui, tstr, 'LegendBars'};
hTag.LegendScat.Callback = {@ne_glmplotbetasgui, tstr, 'LegendScat'};
hTag.LegPosNE.Callback = {@ne_glmplotbetasgui, tstr, 'LegendPos', 'NorthEast'};
hTag.LegPosNW.Callback = {@ne_glmplotbetasgui, tstr, 'LegendPos', 'NorthWest'};
hTag.LegPosSE.Callback = {@ne_glmplotbetasgui, tstr, 'LegendPos', 'SouthEast'};
hTag.LegPosSW.Callback = {@ne_glmplotbetasgui, tstr, 'LegendPos', 'SouthWest'};
hTag.OptVis.Callback = {@ne_glmplotbetasrsz, tstr, 'OptVis'};
hTag.Options.Callback = {@ne_glmplotbetasgui, tstr, 'Options'};
hTag.PPts.Callback = {@ne_glmplotbetasgui, tstr, 'PPts'};
hTag.Radius.Callback = {@ne_glmplotbetasgui, tstr, 'Radius'};
hTag.RankTrans.Callback = {@ne_glmplotbetasgui, tstr, 'RankTrans'};
hTag.Remove0s.Callback = {@ne_glmplotbetasgui, tstr, 'Remove0s'};
hTag.Robust.Callback = {@ne_glmplotbetasgui, tstr, 'Robust'};
hTag.SAxes.Callback = {@ne_screenshot, hTag.Axes.MLHandle};
hTag.SFigure.Callback = {@ne_screenshot, hFig.MLHandle};
hTag.SFullAxes.Callback = {@ne_glmplotbetasgui, tstr, 'SaveAxes'};
hTag.ScConfEllipse.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterConfEllipse'};
hTag.ScFilledMarkers.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterFilledMarkers'};
hTag.ScGroups.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterGroups'};
hTag.ScLine.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterLine'};
hTag.ScMarkAsterisk.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterMarker', '*'};
hTag.ScMarkCircle.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterMarker', 'o'};
hTag.ScMarkDiamond.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterMarker', 'd'};
hTag.ScMarkPeriod.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterMarker', '.'};
hTag.ScMarkPlus.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterMarker', '+'};
hTag.ScMarkSquare.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterMarker', 's'};
hTag.ScMarkX.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterMarker', 'x'};
hTag.ScQuadratic.Callback = {@ne_glmplotbetasgui, tstr, 'ScatterQuadratic'};
hTag.ShowGenInfo.Callback = {@ne_glmplotbetasgui, tstr, 'ShowGeneralInfo'};
hTag.StatsOut.Callback = {@ne_glmplotbetasgui, tstr, 'StatsOut'};
hTag.SubLabels.Callback = {@ne_glmplotbetasgui, tstr, 'SubLabels'};
hTag.SubLines.Callback = {@ne_glmplotbetasgui, tstr, 'SubLines'};
hTag.SubSel.Callback = {@ne_glmplotbetasgui, tstr, 'SubSel'};
hTag.Type.Callback = {@ne_glmplotbetasgui, tstr, 'Type'};
hTag.XFrom.Callback = {@ne_glmplotbetasgui, tstr, 'XRange'};
hTag.XTo.Callback = {@ne_glmplotbetasgui, tstr, 'XRange'};
hTag.YFrom.Callback = {@ne_glmplotbetasgui, tstr, 'YRange'};
hTag.YTo.Callback = {@ne_glmplotbetasgui, tstr, 'YRange'};

% make sure GLM has minimal options
if ~isfield(stvar.RunTimeVars, 'Contrasts') || ...
   ~iscell(stvar.RunTimeVars.Contrasts) || ...
    size(stvar.RunTimeVars.Contrasts, 2) ~= 2
    stvar.RunTimeVars.Contrasts = cell(0, 2);
end
if ~isfield(stvar.RunTimeVars, 'ContrastColors') || ...
    size(stvar.RunTimeVars.ContrastColors, 1) ~= size(stvar.RunTimeVars.Contrasts, 1)
    stvar.RunTimeVars.ContrastColors = ...
        floor(255.999 .* rand(size(stvar.RunTimeVars.Contrasts, 1), 3));
end
if ~isfield(stvar.RunTimeVars, 'CovariatesData') || ...
   ~isa(stvar.RunTimeVars.CovariatesData, 'double') || ...
    size(stvar.RunTimeVars.CovariatesData, 1) ~= stvar.NrOfSubjects || ...
   ~isfield(stvar.RunTimeVars, 'CovariatesNames') || ...
   ~iscell(stvar.RunTimeVars.CovariatesNames) || ...
    numel(stvar.RunTimeVars.CovariatesNames) ~= size(stvar.RunTimeVars.CovariatesData, 2)
    stvar.RunTimeVars.CovariatesData = zeros(stvar.NrOfSubjects, 0);
    stvar.RunTimeVars.CovariatesNames = cell(0, 1);
end
if ~isfield(stvar.RunTimeVars, 'Groups') || ...
   ~iscell(stvar.RunTimeVars.Groups) || ...
    size(stvar.RunTimeVars.Groups, 2) ~= 2
    stvar.RunTimeVars.Groups = cell(0, 2);
end

% get data from glm
[preds, predcols] = stvar.SubjectPredictors;
if stvar.ProjectTypeRFX > 0 && ...
    strcmpi(preds{end}, 'constant')
    preds(end) = [];
    predcols(end, :) = [];
end

% fill in figure options
hTag.DoUpdate.Value = double(cc.updglmbp);
hTag.Conditions.String = preds;
hTag.Conditions.Value = (1:numel(preds))';
rtv = stvar.RunTimeVars;
cons = eye(numel(preds));
if size(rtv.Contrasts, 1) > 1 || ...
   (size(rtv.Contrasts, 1) == 1 && ...
    ~strcmpi(rtv.Contrasts{1}, 'interactive'))
    hTag.Contrasts.String = rtv.Contrasts(:, 1);
    hFig.SetGroupEnabled('Cons', 'on');
else
    hFig.SetGroupEnabled('Cons', 'off');
end
hTag.Contrasts.Value = [];
if ~isempty(rtv.CovariatesNames)
    hTag.Covariates.String = rtv.CovariatesNames(:);
    hTag.Covariates.Value = 1;
    cv = rtv.CovariatesData(:, 1);
    hFig.SetGroupEnabled('Covs', 'on');
else
    hTag.Covariates.Value = [];
    cv = ones(stvar.NrOfSubjects, 1);
    hFig.SetGroupEnabled('Covs', 'off');
end
if ~isempty(rtv.Groups)
    hTag.DoGroups.Value = 1;
    hTag.Groups.String = rtv.Groups(:, 1);
    hTag.Groups.Value = (1:size(rtv.Groups, 1))';
    grpspecs = repmat({'o', [0, 0, 255], false(1, 4)}, size(rtv.Groups, 1), 1);
else
    hTag.DoGroups.Value = 0;
    hTag.Groups.Value = [];
    hFig.SetGroupEnabled('UGrp', 'off');
    grpspecs = cell(0, 3);
end

% create options
stsubs = stvar.Subjects;
plotopts = struct( ...
    'axcol',     [255, 255, 255], ...
    'axpos',     hTag.Axes.Position, ...
    'barcolors', predcols, ...
    'condcol',   predcols, ...
    'contcol',   rtv.ContrastColors, ...
    'contnames', {preds}, ...
    'contrasts', cons, ...
    'covariate', cv, ...
    'drawse',    true, ...
    'glm',       stvar, ...
    'glmbbox',   stvar.BoundingBox, ...
    'groups',    hTag.Groups.Value, ...
    'grpspecs',  {grpspecs}, ...
    'legbars',   false, ...
    'legpos',    'NorthWest', ...
    'legscat',   false, ...
    'linecolor', cini.BetaPlot.ErrorBarColor, ...
    'mods',      {{}}, ...
    'optvis',    true, ...
    'optvispos', hTag.OptVis.Position(1:2), ...
    'plotlines', false, ...
    'plotpts',   false, ...
    'quadratic', false, ...
    'radius',    0, ...
    'radvox',    [0, 0, 0], ...
    'ranktrans', false, ...
    'regress',   'none', ...
    'remove0s',  cini.BetaPlot.Remove0s, ...
    'robust',    false, ...
    'sattype',   'betaplot', ...
    'scellipse', false, ...
    'scfmarker', false, ...
    'scgroups',  false, ...
    'scline',    false, ...
    'scmarker',  'o', ...
    'scrange',   [-Inf, -Inf, Inf, Inf], ...
    'scrangea',  [-1, -1, 1, 1], ...
    'scstats',   true, ...
    'subids',    {stsubs}, ...
    'sublabels', false, ...
    'subsel',    (1:numel(stsubs))', ...
    'title',     cini.BetaPlot.ShowTitle, ...
    'titlestr',  '', ...
    'type',      'bar', ...
    'update',    cc.updglmbp, ...
    'xlabel',    '', ...
    'xrange',    [-Inf, Inf], ...
    'ylabel',    '');
hTag.EBars.Value = double(plotopts.drawse);
if plotopts.remove0s
    hTag.Remove0s.Checked = 'on';
else
    hTag.Remove0s.Checked = 'off';
end
if plotopts.title
    hTag.ShowGenInfo.Checked = 'on';
else
    hTag.ShowGenInfo.Checked = 'off';
end

% set handles
gh.PlotFig{end+1} = hFig;
stvar.SetHandle('PlotFig', gh.PlotFig);
gh.PlotHnd{end+1} = struct( ...
    'Axes',      hTag.Axes.MLHandle, ...
    'AxesLabel', [], ...
    'Bars',      [], ...
    'BarPos',    [], ...
    'LegObj',    [], ...
    'Legend',    [], ...
    'PlotLines', [], ...
    'PlotPts',   [], ...
    'Scatters',  [], ...
    'ScEllipse', [], ...
    'ScLines',   [], ...
    'SEVLines',  [], ...
    'SEULines',  [], ...
    'SELLines',  [], ...
    'SLabels',   [], ...
    'Text',      [], ...
    'Title',     []);
stvar.SetHandle('PlotHnd', gh.PlotHnd);

% set in children array
ne_gcfg.cc.(tstr) = struct( ...
    'Config',       plotopts, ...
    'Data',         struct( ...
        'Coords',   [0, 0, 0], ...
        'Means',    [], ...
        'Raw',      [], ...
        'r',        0, ...
        'rp',       1, ...
        'ScatterX', [], ...
        'ScatterY', [], ...
        'SE',       [], ...
        'Source',   '', ...
        'TrfPlus',  rtv.TrfPlus), ...
    'Satellite',    hFig, ...
    'SatelliteMLH', hFig.MLHandle, ...
    'Tags',         hTag);

% give the figure a more appropriate name
[glmp, glmf] = fileparts(stvar.FilenameOnDisk);
if isempty(glmf)
    sprintf('<GLM: xff #%d>', stvar.Filenumber);
end
hFig.Name = sprintf('NeuroElf - GLM beta plot - %s', glmf);

% make sure this figure is deleted appropriately
hFig.CloseRequestFcn = {@ne_glmplotbetasgui, tstr, 'close'};

% and set up the keypress/keyrelease functions
hFig.KeyPressFcn = {@ne_glmplotbetaskyp, tstr};
hFig.KeyReleaseFcn = {@ne_glmplotbetaskyr, tstr};

% and set a resize function
hFig.ResizeFcn = {@ne_glmplotbetasrsz, tstr};

% set renderer to avoid warnings
hFig.Renderer = 'zbuffer';

% initialize plot (step 1)
ne_glmplotbetasup(0, 0, stvar, '', tstr);

% set position and make visible
if any(ne_gcfg.c.ini.Children.BetaPlotPosition > 0)
    lastpos = hFig.Position;
    lastpos(1:2) = ne_gcfg.c.ini.Children.BetaPlotPosition;
    hFig.Position = lastpos;
end

% set axes hold on
set(hTag.Axes.MLHandle, 'FontSize', 12);
hold(hTag.Axes.MLHandle, 'on');

% init plot (step 2)
ne_glmplotbetasgui(0, 0, tstr, 'Init');

% show figure
hFig.HandleVisibility = 'callback';
hFig.Visible = 'on';

% return
if nargout > 0
    varargout{1} = hTag.Axes.MLHandle;
    if nargout > 1
        varargout{2} = tstr;
    end
end
