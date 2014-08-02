function varargout = persubjectglms(mdm, opts)
% persubjectglms  - compute one GLM per subject
%
% FORMAT:       [glm1, glm2] = persubjectglms(mdm [, opts])
%
% Input fields:
%
%       mdm         MDM object (or filename) with at least 3 subjects
%       opts        optional settings
%        .cmbffx    combine outputs to one FFX GLM (default: true)
%        .cmbrfx    combine outputs to one RFX GLM (default: false)
%        .loadglms  load existing per-subject GLMs (default: false)
%        .outpatt   outfile pattern, default: '%M_%S_FFX.glm'
%        .subsel    subject selection (cell array with IDs)
%
% Output fields:
%
%       glm1, glm2  combined GLMs (order is FFX first if both are used)
%
% Note: additionally all fields to MDM::ComputeGLM are supported in opts.

% Version:  v0.9d
% Build:    14061709
% Date:     Jun-17 2014, 9:51 AM EST
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

% argument check
if nargin < 1 || ...
    isempty(mdm) || ...
   (~ischar(mdm) && ...
    (numel(mdm) ~= 1 || ...
     ~isxff(mdm, 'mdm')))
    error( ...
        'neuroelf:BadArgument', ...
        'Bad or missing argument.' ...
    );
end
if ischar(mdm)
    mdmf = mdm(:)';
    mdm = [];
else
    mdmf = '';
end
if nargin < 2 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if isfield(opts, 'cmbrfx') && ...
   ~isfield(opts, 'cmbffx') && ...
    islogical(opts.cmbrfx) && ...
    numel(opts.cmbrfx) == 1 && ...
    opts.cmbrfx
    opts.cmbffx = false;
end
if ~isfield(opts, 'cmbffx') || ...
   ~islogical(opts.cmbffx) || ...
    numel(opts.cmbffx) ~= 1
    opts.cmbffx = true;
end
if ~isfield(opts, 'cmbrfx') || ...
   ~islogical(opts.cmbrfx) || ...
    numel(opts.cmbrfx) ~= 1
    opts.cmbrfx = false;
end
if ~isfield(opts, 'loadglms') || ...
   ~islogical(opts.loadglms) || ...
    numel(opts.loadglms) ~= 1
    opts.loadglms = false;
end
if ~isfield(opts, 'outpatt') || ...
   ~ischar(opts.outpatt)
    opts.outpatt = '%M_%S_FFX.glm';
elseif numel(opts.outpatt) < 6 || ...
    isempty(strfind(opts.outpatt(:)', '%S')) || ...
   ~strcmpi(lsqueeze(opts.outpatt(end-3:end))', '.glm') || ...
    sum(opts.outpatt(:)' == '%') > 2
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid output filename pattern.' ...
    );
end
opts.outpatt = opts.outpatt(:)';
if ~isfield(opts, 'subsel') || ...
   ~iscell(opts.subsel) || ...
    isempty(opts.subsel) || ...
   ~ischar(opts.subsel{1}) || ...
    isempty(opts.subsel{1})
    opts.subsel = [];
end

% load MDM
if ~isempty(mdmf)
    try
        mdm = xff(mdmf);
        if ~isxff(mdm, 'mdm')
            error( ...
                'neuroelf:BadArgument', ...
                'Not an MDM file: %s.', ...
                mdmf ...
            );
        end
    catch ne_eo;
        if isxff(mdm)
            mdm.ClearObject;
        end
        rethrow(ne_eo);
    end
end
mdmc = getcont(mdm);

% patch pattern again
if ~isempty(strfind(opts.outpatt, '%M'))
    [mdmfp, mdmfn] = fileparts(mdm.FilenameOnDisk);
    if isempty(mdmfn)
        mdmfn = 'UNSAVED';
    elseif ~isempty(mdmfp)
        mdmfn = strrep(strrep([mdmfp '/' mdmfn], '\', '/'), '//', '/');
    end
    opts.outpatt = strrep(opts.outpatt, '%M', mdmfn);
    if sum(opts.outpatt == '%') ~= 1
        if ~isempty(mdmf)
            mdm.ClearObject;
        else
            setcont(mdm, mdmc);
        end
        error( ...
            'neuroelf:BadArgument', ...
            'Invalid output filename pattern.' ...
        );
    end
end

% subject selection
fsids = mdm.Subjects(true);
if ~isempty(opts.subsel)
    ksubs = (multimatch(fsids, opts.subsel(:)) > 0);
    if isfield(opts, 'motpars') && ...
        iscell(opts.motpars) && ...
        numel(opts.motpars) == size(mdm.XTC_RTC, 1)
        mdm.RunTimeVars.MotionParameters = lsqueeze(opts.motpars(ksubs));
        opts.motpars = true;
    elseif isfield(mdm.RunTimeVars, 'MotionParameters') && ...
        iscell(mdm.RunTimeVars.MotionParameters) && ...
        numel(mdm.RunTimeVars.MotionParameters) == size(mdm.XTC_RTC, 1)
        mdm.RunTimeVars.MotionParameters = ...
            lsqueeze(mdm.RunTimeVars.MotionParameters(ksubs));
    end
    mdm.XTC_RTC = mdm.XTC_RTC(ksubs, :);
    fsids = mdm.Subjects(true);
elseif isfield(opts, 'motpars') && ...
    iscell(opts.motpars) && ...
    numel(opts.motpars) == size(mdm.XTC_RTC, 1)
    mdm.RunTimeVars.MotionParameters = opts.motpars(:);
    opts.motpars = true;
end

% find subject IDs
sids = mdm.Subjects;
if numel(sids) < 3
    if ~isempty(mdmf)
        mdm.ClearObject;
    else
        setcont(mdm, mdmc);
    end
    error( ...
        'neuroelf:BadArgument', ...
        'MDM requires at least 3 subjects.' ...
    );
end

% settings
mdm.RFX_GLM = 0;
mdm.SeparatePredictors = 2;
mdm.NrOfStudies = size(mdm.XTC_RTC, 1);
nstudy = mdm.NrOfStudies;

% iterate over subjects
glms = cell(numel(sids), 1);
for sc = 1:numel(sids)

    % load only
    if opts.loadglms
        glms{sc} = strrep(opts.outpatt, '%S', sids{sc});
        if exist(glms{sc}, 'file') ~= 2
            if ~isempty(mdmf)
                mdm.ClearObject;
            else
                setcont(mdm, mdmc);
            end
            error( ...
                'neuroelf:BadArgument', ...
                'Cannot load GLM for subject %s.', ...
                sids{sc} ...
            );
        end
        continue;
    end

    % make a copy
    smdm = mdm.CopyObject;

    % match ID to list
    sidx = find(strcmpi(fsids, sids{sc}));

    % keep those entries
    smdm.XTC_RTC = mdm.XTC_RTC(sidx, :);
    if isfield(mdm.RunTimeVars, 'MotionParameters') && ...
        numel(mdm.RunTimeVars.MotionParameters) == nstudy
        smdm.RunTimeVars.MotionParameters = mdm.RunTimeVars.MotionParameters(sidx);
    end

    % compute and save GLM
    try
        glm = [];
        glm = smdm.ComputeGLM(opts);
        glm.SaveAs(strrep(opts.outpatt, '%S', sids{sc}));
        glm.SaveRunTimeVars;
        glms{sc} = glm.FilenameOnDisk;
        glm.ClearObject;
        smdm.ClearObject;
    catch ne_eo;
        if isxff(glm)
            glm.ClearObject;
        end
        smdm.ClearObject;
        if ~isempty(mdmf)
            mdm.ClearObject;
        else
            setcont(mdm, mdmc);
        end
        rethrow(ne_eo);
    end
end

% combine GLMs
if opts.cmbffx || ...
    opts.cmbrfx

    % load GLMs (with transio)
    for sc = 1:numel(glms)
        try
            glms{sc} = xff(glms{sc}, 't');
            if ~isxff(glms{sc}, 'glm') || ...
                glms{sc}.ProjectTypeRFX > 0
                error( ...
                    'neuroelf:BadGLMFile', ...
                    'Bad GLM file for subject %s.', ...
                    sids{sc} ...
                );
            end
            if opts.cmbffx && ...
                isfield(glms{sc}, 'SubjectSPMsn') && ...
                isstruct(glms{sc}.SubjectSPMsn) && ...
                numel(glms{sc}.SubjectSPMsn) == 1 && ...
               ~isempty(fieldnames(glms{sc}.SubjectSPMsn))
                error( ...
                    'neuroelf:BadCombination', ...
                    'Subject-GLMs with SPM-normalization cannot be FFX-combined.' ...
                );
            end
        catch ne_eo;
            clearxffobjects(glms);
            if ~isempty(mdmf)
                mdm.ClearObject;
            else
                setcont(mdm, mdmc);
            end
            rethrow(ne_eo);
        end
    end
end

% RFX
nss = numel(glms);
if opts.cmbrfx

    % try/catch
    try

        % make a copy of the first GLM
        rfx = bless(glms{1}.CopyObject, 1);

        % collect some data
        nrtp = 0;
        nrct = 0;
        nrcf = 0;
        msk = zeros(size(glms{1}.GLMData.MCorrSS));
        sts = cell(1, nss);
        prs = glms{1}.Predictor;
        pns = lsqueeze({prs(1:(glms{1}.NrOfPredictors - glms{1}.NrOfConfounds)).Name2});
        pns = regexprep(pns, '^Subject\s+(\w+)\:\s*', '');
        pnc = zeros(12, 0);
        for sc = 1:nss
            nrtp = nrtp + glms{sc}.NrOfTimePoints;
            nrct = nrct + glms{sc}.NrOfConfounds;
            nrcf = nrcf + numel(glms{sc}.NrOfConfoundsPerStudy);
            sts{sc} = glms{sc}.Study;
            prs = glms{sc}.Predictor;
            pnn = lsqueeze({prs(1:(glms{sc}.NrOfPredictors - glms{sc}.NrOfConfounds)).Name2});
            pnn = regexprep(pnn, '^Subject\s+(\w+)\:\s*', '');
            pns = uunion(pns, pnn);
            if size(pnc, 2) < numel(pns)
                for pc = (size(pnc, 2)+1):numel(pns)
                    pnc(:, pc) = prs(findfirst(strcmp(pnn, pns{pc}))).RGB(:);
                end
            end
            msk = msk + double(glms{sc}.GLMData.MCorrSS > 0);
        end
        sts = catstruct(sts{:});
        msk = (msk >= (0.75 * nss));
        ntp = (numel(pns) + 1) * nss;
        rfxspmsn = struct;
        rfxtrfpl = struct;

        % restructure
        rfx.ProjectTypeRFX = 1;
        rfx.NrOfSubjects = nss;
        rfx.NrOfSubjectPredictors = numel(pns) + 1;
        rfx.NrOfTimePoints = nrtp;
        rfx.NrOfPredictors = ntp;
        rfx.NrOfConfounds = nrct;
        rfx.NrOfStudies = numel(sts);
        rfx.NrOfStudiesWithConfounds = nrcf;
        rfx.NrOfConfoundsPerStudy = zeros(1, nrcf);
        rfx.SeparatePredictors = 2;
        rfx.NrOfVoxelsForBonfCorrection = sum(msk(:));
        rfx.CortexBasedStatisticsMaskFile = '';
        rfx.Study = sts;
        rfxPredictor = rfx.Predictor;
        rfxPredictor(ntp).Name1 = '';
        rfxPredictor = rfxPredictor(:);
        rfx.DesignMatrix = [];
        rfx.iXX = [];
        rfxGLMData.MultipleRegressionR = [];
        rfxGLMData.MCorrSS = [];
        rfxGLMData.BetaMaps = [];
        rfxGLMData.XY = [];
        rfxGLMData.TimeCourseMean = [];
        rfxGLMData.RFXGlobalMap = single(msk);
        rfxGLMData.Subject = repmat(struct('BetaMaps', ...
            repmat(single(0), [size(msk), numel(pns) + 1])), 1, nss);
        rfx.RunTimeVars.MotionParameters = cell(0, 1);

        % generate predictor array
        preds = emptystruct({'Name1', 'Name2', 'RGB'}, [numel(pns), 1]);
        for pc = 1:numel(pns)
            preds(pc).RGB = reshape(pnc(:, pc), 4, 3);
        end

        % iterate over subjects
        ts = 1;
        tp = 1;
        for sc = 1:nss

            % get subject ID
            ssts = glms{sc}.Study;
            sid = ssts(1).NameOfAnalyzedFile;
            [sidf, sid] = fileparts(sid);
            sid = regexprep(sid, '^([^_]+)_.*$', '$1');
            tsid = makelabel(sid);

            % RunTimeVars
            rtv = glms{sc}.RunTimeVars;

            % subject-related fields
            if isfield(rtv, 'MotionParameters') && ...
                iscell(rtv.MotionParameters) && ...
                numel(rtv.MotionParameters) == glms{sc}.NrOfStudies
                rfx.RunTimeVars.MotionParameters = [ ...
                    rfx.RunTimeVars.MotionParameters(:); rtv.MotionParameters(:)];
            end
            if isfield(rtv, 'SubjectSPMsn') && ...
                isstruct(rtv.SubjectSPMsn) && ...
                numel(rtv.SubjectSPMsn) == 1 && ...
                isfield(rtv.SubjectSPMsn, tsid)
                rfxspmsn.(tsid) = rtv.SubjectSPMsn.(tsid);
            end
            if isfield(rtv, 'SubjectTrfPlus') && ...
                isstruct(rtv.SubjectTrfPlus) && ...
                numel(rtv.SubjectTrfPlus) == 1 && ...
                isfield(rtv.SubjectTrfPlus, tsid)
                rfxtrfpl.(tsid) = rtv.SubjectTrfPlus.(tsid);
            end

            % fill in header fields
            nst = numel(ssts);
            rfx.NrOfConfoundsPerStudy(ts:ts+nst-1) = glms{sc}.NrOfConfoundsPerStudy;
            prs = glms{sc}.Predictor;
            pnn = lsqueeze({prs([1:(glms{sc}.NrOfPredictors - glms{sc}.NrOfConfounds), end]).Name2});
            pnn = regexprep(pnn, '^Subject\s+(\w+)\:\s*', '');
            pni = multimatch(pns, pnn);
            rfxPredictor(tp:tp+numel(pns)-1) = preds;
            for pc = 1:numel(pns)
                rfxPredictor(tp).Name1 = sprintf('Predictor: %d', tp);
                rfxPredictor(tp).Name2 = sprintf('Subject %s: %s', sid, pns{pc});

                % also fill in beta map?
                if pni(pc) > 0
                    rfxGLMData.Subject(sc).BetaMaps(:, :, :, pc) = ...
                        glms{sc}.GLMData.BetaMaps(:, :, :, pni(pc));
                end

                % increase counter
                tp = tp + 1;
            end

            % add constant predictor info
            rfxPredictor(ntp+sc-nss) = glms{sc}.Predictor(end);
            rfxPredictor(ntp+sc-nss).Name1 = sprintf('Predictor: %d', ntp+sc-nss);
            rfxPredictor(ntp+sc-nss).Name2 = sprintf('Subject %s: Constant', sid);

            % combine constant maps
            cprs = ~cellfun('isempty', regexpi(lsqueeze({prs.Name2}), '\s+constant$'));
            cmaps = glms{sc}.GLMData.BetaMaps(:, :, :, cprs);
            for stc = 1:numel(ssts)
                cmaps(:, :, :, stc) = ssts(stc).NrOfTimePoints .* cmaps(:, :, :, stc);
            end
            rfxGLMData.Subject(sc).BetaMaps(:, :, :, end) = ...
                (1 / sum(cat(1, ssts.NrOfTimePoints))) .* sum(cmaps, 4);

            % increase counter
            ts = ts + nst;
        end

        % store output
        rfx.Predictor = rfxPredictor;
        rfx.GLMData = rfxGLMData;
        if numel(rfx.RunTimeVars.MotionParameters) ~= numel(rfx.Study)
            rfx.RunTimeVars.MotionParameters = cell(0, 1);
        end
        if ~isempty(fieldnames(rfxspmsn))
            rfx.RunTimeVars.SubjectSPMsn = rfxspmsn;
        end
        if ~isempty(fieldnames(rfxtrfpl))
            rfx.RunTimeVars.SubjectTrfPlus = rfxtrfpl;
        end

        % clear temp data
        rfxGLMData(:) = [];

    % handle errors
    catch ne_eo;
        if ~isempty(mdmf)
            mdm.ClearObject;
        else
            setcont(mdm, mdmc);
        end
        clearxffobjects(glms);
        rfx.ClearObject;
        rethrow(ne_eo);
    end

    % where in output?
    if opts.cmbffx
        varargout{1} = [];
        varargout{2} = rfx;
    else
        varargout{1} = rfx;
    end
end

% FFX combination
if opts.cmbffx

    % try/catch
    try

        % always combine two at a time
        while numel(glms) > 1

            % iterate from the end
            for sc = numel(glms):-2:2

                % combine two GLMs
                nglm = glms{sc-1}.JoinFFX(glms{sc});

                % drop two old GLMs
                clearxffobjects(glms(sc-1:sc));

                % replace first one
                glms{sc-1} = nglm;

                % and remove second from list
                glms(sc) = [];
            end
        end

    % handle errors
    catch ne_eo;
        if ~isempty(mdmf)
            mdm.ClearObject;
        else
            setcont(mdm, mdmc);
        end
        clearxffobjects(glms);
        rethrow(ne_eo);
    end

    % set in output
    varargout{1} = bless(glms{1}.CopyObject, 1);
end

% clean up
if ~isempty(mdmf)
    mdm.ClearObject;
else
    setcont(mdm, mdmc);
end
clearxffobjects(glms);
