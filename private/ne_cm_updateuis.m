% FUNCTION ne_cm_updateuis: update UIs for this GLM
function ne_cm_updateuis(varargin)

% Version:  v0.9d
% Build:    14071814
% Date:     Jul-18 2014, 2:58 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2011, 2014, Jochen Weber
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

% test input
if nargin < 3 || ...
    numel(varargin{3}) ~= 1 || ...
   ~isxff(varargin{3}, 'glm')
    return;
end
stvar = varargin{3};
sthnd = handles(stvar);
strtv = stvar.RunTimeVars;

% make sure GLM has minimal options
if ~isfield(strtv, 'Contrasts') || ...
   ~iscell(strtv.Contrasts) || ...
    size(strtv.Contrasts, 2) ~= 2
    stvar.RunTimeVars.Contrasts = cell(0, 2);
end
if ~isfield(strtv, 'ContrastColors') || ...
    size(strtv.ContrastColors, 2) ~= 3 || ...
    size(strtv.ContrastColors, 1) ~= size(stvar.RunTimeVars.Contrasts, 1)
    stvar.RunTimeVars.ContrastColors = ...
        floor(255.999 .* rand(size(stvar.RunTimeVars.Contrasts, 1), 3));
end
if ~isfield(strtv, 'CovariatesData') || ...
   ~isa(strtv.CovariatesData, 'double') || ...
    size(strtv.CovariatesData, 1) ~= stvar.NrOfSubjects || ...
   ~isfield(strtv, 'CovariatesNames') || ...
   ~iscell(strtv.CovariatesNames) || ...
    numel(strtv.CovariatesNames) ~= size(strtv.CovariatesData, 2)
    stvar.RunTimeVars.CovariatesData = zeros(stvar.NrOfSubjects, 0);
    stvar.RunTimeVars.CovariatesNames = cell(0, 1);
end
if ~isfield(strtv, 'Groups') || ...
   ~iscell(strtv.Groups) || ...
    size(strtv.Groups, 2) ~= 2
    stvar.RunTimeVars.Groups = cell(0, 2);
end
if ~isfield(strtv, 'SubSel') || ...
   ~iscell(strtv.SubSel) || ...
    size(strtv.SubSel, 2) ~= 1
    stvar.RunTimeVars.SubSel = stvar.Subjects;
end
if ~isfield(strtv, 'UseGroups') || ...
   ~islogical(strtv.UseGroups) || ...
    numel(strtv.UseGroups) ~= 1
    stvar.RunTimeVars.UseGroups = false;
end

% what to update
if isfield(sthnd, 'PlotFig') && ...
    iscell(sthnd.PlotFig) && ...
   ~isempty(sthnd.PlotFig)
    for fc = 1:numel(sthnd.PlotFig)
        if numel(sthnd.PlotFig{fc}) == 1 && ...
            isxfigure(sthnd.PlotFig{fc}, true) && ...
            isfield(ne_gcfg.cc, sthnd.PlotFig{fc}.Tag(1:8))
            try
                ne_cm_updatebp(stvar, ...
                    sthnd.PlotFig{fc}.Tag(1:8), sthnd.PlotFig{fc}, ...
                    ne_gcfg.cc.(sthnd.PlotFig{fc}.Tag(1:8)).Tags);
            catch ne_eo;
                ne_gcfg.c.lasterr = ne_eo;
            end
        end
    end
end


% sub-functions


% update beta plotter
function ne_cm_updatebp(stvar, tstr, hFig, hTag)

% get config
global ne_gcfg;

% get old strings
ocondstr = hTag.Conditions.String;
if ~iscell(ocondstr)
    ocondstr = cellstr(ocondstr);
end
ocontstr = hTag.Contrasts.String;
if ~iscell(ocontstr)
    ocontstr = cellstr(ocontstr);
end
ogrpstr = hTag.Groups.String;
if ~iscell(ogrpstr)
    ogrpstr = cellstr(ogrpstr);
end

% get data from glm
[preds, predcols] = stvar.SubjectPredictors;

% fill in figure options
plotopts = ne_gcfg.cc.(tstr).Config;
rtv = stvar.RunTimeVars;
ocontcol = plotopts.contcol;
contm = multimatch(rtv.Contrasts(:, 1), ocontstr);
stvar.RunTimeVars.ContrastColors(contm > 0, :) = ocontcol(contm(contm > 0), :);
plotopts.contcol = stvar.RunTimeVars.ContrastColors;
cons = eye(stvar.NrOfSubjectPredictors);
if numel(ocondstr) ~= numel(preds) || ...
    numel(ocontstr) ~= size(rtv.Contrasts, 1)
    hTag.Conditions.ListboxTop = 1;
    hTag.Conditions.Value = 1;
    hTag.Conditions.String = preds;
    hTag.Conditions.Value = (1:(numel(preds) - 1))';
    hTag.Contrasts.ListboxTop = 1;
    hTag.Contrasts.Value = [];
    cons(end, :) = [];
    concols = predcols(1:end-1, :);
else
    selcond = hTag.Conditions.Value;
    selcont = hTag.Contrasts.Value;
    if ~isempty(selcond)
        cons = cons(selcond, :);
        concols = predcols(selcond, :);
    elseif ~isempty(selcont)
        cons = cat(2, rtv.Contrasts{selcont, 2})';
        concols = plotopts.contcol(selcont, :);
    else
        hTag.Conditions.Value = (1:(numel(preds) - 1))';
        cons(end, :) = [];
        concols = predcols(1:end-1, :);
    end
end
if size(rtv.Contrasts, 1) > 1 || ...
   (size(rtv.Contrasts, 1) == 1 && ...
    ~strcmpi(rtv.Contrasts{1}, 'interactive'))
    hTag.Contrasts.String = rtv.Contrasts(:, 1);
    hFig.SetGroupEnabled('Cons', 'on');
else
    hFig.SetGroupEnabled('Cons', 'off');
end
if ~isempty(rtv.CovariatesNames)
    ocovstr = hTag.Covariates.String;
    rtv.CovariatesNames = rtv.CovariatesNames(:);
    if ~iscell(ocovstr)
        ocovstr = cellstr(ocovstr);
    end
    ocovstr = ocovstr(:);
    ocovval = hTag.Covariates.Value;
    if numel(ocovstr) ~= numel(rtv.CovariatesNames) || ...
       (~isempty(ocovval) && ...
        ~all(strcmp(ocovstr(ocovval), rtv.CovariatesNames(ocovval))))
        hTag.Covariates.ListboxTop = 1;
        hTag.Covariates.Value = 1;
    end
    hTag.Covariates.String = rtv.CovariatesNames;
    cv = rtv.CovariatesData(:, 1);
    hFig.SetGroupEnabled('Covs', 'on');
else
    hTag.Covariates.Value = [];
    cv = ones(stvar.NrOfSubjects, 1);
    hFig.SetGroupEnabled('Covs', 'off');
end
if ~isempty(rtv.Groups)
    hTag.Groups.String = rtv.Groups(:, 1);
    hTag.Groups.Value = (1:size(rtv.Groups, 1))';
    grpspecs = repmat({'o', [0, 0, 255], false(1, 4)}, size(rtv.Groups, 1), 1);
    hFig.SetGroupEnabled('UGrp', 'on');
else
    hTag.DoGroups.Value = 0;
    hTag.Groups.Value = [];
    hFig.SetGroupEnabled('UGrp', 'off');
    grpspecs = cell(0, 3);
end

% update options
plotopts.barcolors = concols;
plotopts.condcol = predcols;
plotopts.contrasts = cons;
plotopts.covariate = cv;
plotopts.groups = (1:size(rtv.Groups, 1))';
ogrpspecs = plotopts.grpspecs;
grpm = multimatch(rtv.Groups(:, 1), ogrpstr);
grpspecs(grpm > 0, :) = ogrpspecs(grpm(grpm > 0), :);
plotopts.grpspecs = grpspecs;
ne_gcfg.cc.(tstr).Config = plotopts;

% initialize plot
ne_glmplotbetasgui(0, 0, tstr, 'Init');
