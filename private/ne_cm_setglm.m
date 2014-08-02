% FUNCTION ne_cm_setglm: change the current GLM
function ne_cm_setglm(varargin)

% Version:  v0.9d
% Build:    14060518
% Date:     Jun-05 2014, 6:34 PM EST
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
hFig = ne_gcfg.h.CM.CMFig;

% update RunTimeVars if required
if numel(hFig.UserData.lastglm) == 1 && ...
    isxff(hFig.UserData.lastglm, 'glm')
    ne_cm_updatertv(0, 0, hFig.UserData.lastglm, 1);
end

% reset content of entire UI!
ne_gcfg.fcfg.CM = struct( ...
    'cons',      {cell(0, 2)}, ...
    'covs',      {cell(0, 2)}, ...
    'glm',       [], ...
    'GLMs',      {ne_gcfg.fcfg.CM.GLMs}, ...
	'groups',    {cell(0, 2)}, ...
	'preds',     {cell(0, 1)}, ...
    'subsel',    {cell(0, 1)}, ...
    'usegroups', false, ...
    'vmp',       []);

% get shortcuts
cc = ne_gcfg.fcfg.CM;
ch = ne_gcfg.h.CM.h;
ch.StoreInCVMP.Enable = 'off';
ch.StoreInCVMP.Value = 0;
try

    % get currently selected GLM
    glm = cc.GLMs{ch.GLMs.Value};

    % disable groups by default
    cc.usegroups = false;
    ch.UseGroups.Value = 0;
    ch.Groups.String = {'<no groups specified>'};
    ch.Groups.Value = 1;
    hFig.SetGroupEnabled('Groups', 'off');

    % get list of subjects
    subjects = glm.Subjects;

    % make sure there is a valid Contrasts field
    if ~isfield(glm.RunTimeVars, 'Contrasts') || ...
       ~iscell(glm.RunTimeVars.Contrasts) || ...
        size(glm.RunTimeVars.Contrasts, 2) ~= 2
        glm.RunTimeVars.Contrasts = cell(0, 2);
    end

    % make sure there is a valid CovariatesData and CovariatesNames field
    if ~isfield(glm.RunTimeVars, 'CovariatesData') || ...
       ~isfield(glm.RunTimeVars, 'CovariatesNames') || ...
       ~isa(glm.RunTimeVars.CovariatesData, 'double') || ...
       ~iscell(glm.RunTimeVars.CovariatesNames) || ...
        size(glm.RunTimeVars.CovariatesData, 1) ~= numel(subjects) || ...
        size(glm.RunTimeVars.CovariatesData, 2) ~= numel(glm.RunTimeVars.CovariatesNames)
        glm.RunTimeVars.CovariatesData = zeros(numel(subjects), 0);
        glm.RunTimeVars.CovariatesNames = cell(1, 0);
    end

    % make sure there is a valid Groups field
    if ~isfield(glm.RunTimeVars, 'Groups') || ...
       ~iscell(glm.RunTimeVars.Groups) || ...
        size(glm.RunTimeVars.Groups, 2) ~= 2
        glm.RunTimeVars.Groups = cell(0, 2);
    end

    % make sure there is a valid SubSel field
    if ~isfield(glm.RunTimeVars, 'SubSel') || ...
       ~iscell(glm.RunTimeVars.SubSel) || ...
        size(glm.RunTimeVars.SubSel, 2) ~= 1
        glm.RunTimeVars.SubSel = glm.Subjects;
    end

    % make sure there is a valid UseGroups field
    if ~isfield(glm.RunTimeVars, 'UseGroups') || ...
       ~islogical(glm.RunTimeVars.UseGroups) || ...
        numel(glm.RunTimeVars.UseGroups) ~= 1
        glm.RunTimeVars.UseGroups = false;
    end

    % set subjects %% CHECK FOR RFX HERE %%
    cc.glm = glm;
    seppred = glm.SeparatePredictors;
    hFig.SetGroupEnabled('HasSubs', 'on');
    ch.SubjectsTxt.String = 'Subject selection:';
    if glm.ProjectTypeRFX > 0 || ...
        seppred == 2
        subjects = glm.Subjects;
    elseif seppred == 1
        ch.SubjectsTxt.String = 'Study selection:';
        subjects = glm.Study;
        subjects = {subjects(:).NameOfAnalyzedFile};
        for subjc = 1:numel(subjects)
            [subjp, subjects{subjc}] = fileparts(subjects{subjc});
        end
        subjects = subjects(:);
    else
        hFig.SetGroupEnabled('HasSubs', 'off');
        subjects = {'all'};
    end
    cc.nsubs = numel(subjects);
    ch.Subjects.ListboxTop = 1;
    ch.Subjects.Value = 1;
    ch.Subjects.String = subjects(:);
    ch.Subjects.Value = 1:numel(subjects);

    % set RFX controls enabled
    if glm.ProjectTypeRFX > 0 || ...
        glm.SeparatePredictors == 2
        hFig.SetGroupEnabled('RFXGLM', 'on');
        ch.RFXstats.Value = 1;
        if glm.ProjectTypeRFX > 0
            ch.RFXstats.Enable = 'off';
        elseif numel(subjects) < 3
            ch.RFXstats.Enable = 'off';
            ch.RFXstats.Value = 0;
        end
    else
        hFig.SetGroupEnabled('RFXGLM', 'off');
        ch.RFXstats.Value = 0;
    end

    % and get SubjectPredictors (without the mean predictor)
    preds = glm.SubjectPredictors;
    if glm.NrOfSubjectPredictors == numel(preds)
        preds(end) = [];
    end

    % set in config
    cc.preds = preds(:);
    cc.subsel = glm.RunTimeVars.SubSel;
    cc.usegroups = glm.RunTimeVars.UseGroups;

    % set predictors
    ch.Predictors.String = preds(:);
    ch.Predictors.Value = [];
    ch.Predictors.ListboxTop = 1;
    ch.PredWeights.String = repmat({'0'}, numel(preds), 1);
    ch.PredWeights.Value = [];
    ch.PredWeights.ListboxTop = 1;

    % re-set groups controls
    cc.groups = glm.RunTimeVars.Groups;
    if ~isempty(cc.groups) && ...
        cc.usegroups
        ch.UseGroups.Value = 1;
        ch.Subjects.Value = cc.groups{1, 2}(:);
        ch.Groups.String = cc.groups(:, 1);
        ch.Groups.Value = 1;
        hFig.SetGroupEnabled('Groups', 'on');
    else
        ch.Subjects.Value = lsqueeze(find(multimatch(glm.Subjects, cc.subsel) > 0));
    end
    ch.Subjects.ListboxTop = 1;

    % re-set covariates control
    cc.covs = glm.RunTimeVars.CovariatesNames(:);
    ch.Covs.Value = [];
    ch.Covs.String = cc.covs;
    for cvc = 1:size(cc.covs, 1)
        cc.covs{cvc, 2} = glm.RunTimeVars.CovariatesData(:, cvc);
    end

    % re-set contrast controls
    ch.Contrasts.Value = 1;
    ch.Contrasts.String = {'<as currently configured>'};
    ne_gcfg.h.CM.CMFig.SetGroupEnabled('HasCons', 'off');

    % fill contrast controls if required
    cc.cons = glm.RunTimeVars.Contrasts;
    if ~isempty(cc.cons)

        % set weights of first contrast
        ne_cm_setweights(cc.cons{1, 2});

        % if actual contrasts were configured
        if size(cc.cons, 1) > 1 || ...
           ~strcmpi(cc.cons{1}, 'interactive')

            % then update dropdown
            ch.Contrasts.String = cc.cons(:, 1);
            ch.Contrasts.Value = 1;
            ne_gcfg.h.CM.CMFig.SetGroupEnabled('HasCons', 'on');
        end
    end

    % disable beta-range setting (default!)
    ch.BRange.Value = 0;

    % update
    drawnow;
    ch.Subjects.ListboxTop = 1;
    drawnow;

    % set reference to last GLM
    hFig.UserData.lastglm = cc.glm;
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
    ne_cm_closeui;
    uiwait(warndlg('Error using the selected GLM; closing UI.', 'NeuroElf GUI - error', 'modal'));
    return;
end

% which VMPs are available to store data
glay = glm.Layout;
grtv = glm.RunTimeVars;
gtrf = grtv.TrfPlus;
broot = xff;
tvmp = broot.Documents('vmp');
if ~isfield(grtv, 'SubjectSPMsn') || ...
   ~isstruct(grtv.SubjectSPMsn) || ...
    numel(grtv.SubjectSPMsn) ~= 1 || ...
    isempty(fieldnames(grtv.SubjectSPMsn))
    for vmpc = numel(tvmp):-1:1
        vhnd = broot.Document(tvmp{vmpc});
        vlay = vhnd.Layout;
        if any(glay([1:3, 5:10]) ~= vlay([1:3, 5:10])) || ...
           ~isequal(vhnd.RunTimeVars.TrfPlus, gtrf)
            tvmp(vmpc) = [];
        end
    end
elseif glm.NrOfSubjects == 1 && ...
    numel(fieldnames(grtv.SubjectSPMsn)) == 1 && ...
    isfield(grtv, 'SubjectTrfPlus') && ...
    numel(grtv.SubjectTrfPlus) == 1 && ...
    isstruct(grtv.SubjectTrfPlus) && ...
    isequal(fieldnames(grtv.SubjectSPMsn), fieldnames(grtv.SubjectTrfPlus))
    ffxtsid = fieldnames(grtv.SubjectSPMsn);
    for vmpc = numel(tvmp):-1:1
        vhnd = broot.Document(tvmp{vmpc});
        vlay = vhnd.Layout;
        if any(glay([1:3, 5:10]) ~= vlay([1:3, 5:10])) || ...
           ~isfield(vhnd.RunTimeVars, 'SPMsn') || ...
           ~isstruct(vhnd.RunTimeVars.SPMsn) || ...
            numel(vhnd.RunTimeVars.SPMsn) ~= 1 || ...
           ~isequal(vhnd.RunTimeVars.SPMsn, grtv.SubjectSPMsn.(ffxtsid{1})) || ...
           ~isequal(vhnd.RunTimeVars.TrfPlus, gtrf * grtv.SubjectTrfPlus.(ffxtsid{1}))
            tvmp(vmpc) = [];
        end
    end
end

% any good
if ~isempty(tvmp)

    % compile name of VMPs
    vmpn = cell(numel(tvmp) + 1, 1);
    vmpn{1} = '<new.vmp>';
    for vmpc = numel(tvmp):-1:1
        if ischar(tvmp{vmpc})
            [vmppath, vmpfile, vmpfext] = fileparts(tvmp{vmpc});
            vmpn{vmpc + 1} = [vmpfile, vmpfext];
        else
            vmpn{vmpc + 1} = sprintf('<xff #%d>', tvmp{vmpc});
        end
        tvmp{vmpc + 1} = broot.Document(tvmp{vmpc});
    end
    tvmp{1} = [];
    ch.StoreInVMP.String = vmpn;
    ch.StoreInVMP.Value = 2;
end
cc.vmp = tvmp;
ne_gcfg.fcfg.CM = cc;
