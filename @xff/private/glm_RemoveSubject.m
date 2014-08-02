function [hfile] = glm_RemoveSubject(hfile, sid)
% GLM::RemoveSubject  - remove subject(s) from GLM
%
% FORMAT:       [glm = ] glm.RemoveSubject(sid);
%
% Input fields:
%
%       sid         either single subject (char) or list of subjects (cell)
%
% Output fields:
%
%       hfile       altered GLM object

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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

% check arguments
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'glm') || ...
   ((~ischar(sid) || ...
     isempty(sid) || ...
     numel(sid) ~= size(sid, 2)) && ...
    (~iscell(sid) || ...
     isempty(sid) || ...
     ~ischar(sid{1}) || ...
     isempty(sid{1})))
    error( ...
        'xff:BadArgument', ...
        'Bad object or argument in call.' ...
    );
end

% get list of subject IDs
try
    sl = glm_Subjects(hfile);
catch ne_eo;
    rethrow(ne_eo);
end

% prepare array for subjects to keep
ks = true(numel(sl), 1);

% get content
bc = xffgetcont(hfile.L);

% get predictor names (to match against subject ids)
pl = {bc.Predictor(:).Name2};

% and prepare keep-predictor array
kp = true(1, numel(pl));

% same for analyzed file
tl = {bc.Study(:).NameOfAnalyzedFile};
kt = true(1, numel(tl));

% make sure subject ID is a cell array
if ~iscell(sid)
    sid = {sid};
end

% linearize and check each against lists
sid = sid(:);
tpm = 0;
for sc = 1:numel(sid)
    if ~ischar(sid{sc}) || ...
        isempty(sid{sc}) || ...
       ~any(strcmpi(sid{sc}, sl))
        continue;
    end
    for pc = 1:numel(pl)
        if ~isempty(strfind(pl{pc}, [sid{sc} ':'])) && ...
            kp(pc)
            kp(pc) = false;
        end
    end
    for tc = 1:numel(tl)
        [tlp, tlf] = fileparts(tl{tc});
        if ~isempty(strfind(tlf, [sid{sc} '_'])) && ...
            kt(tc)
            kt(tc) = false;
            tpm = tpm + bc.Study(tc).NrOfTimePoints;
        end
    end
    ks = ks & (~strcmp(sl, sid{sc}));
end

% keep only matching studies
bc.Study = bc.Study(kt);
if bc.FileVersion < 4
    kp(end+1-numel(ks):end) = ks;
end

% and predictors
bc.Predictor = bc.Predictor(kp);
ncs = 0;

% re-enumerate predictors
for pc = 1:numel(bc.Predictor)
    bc.Predictor(pc).Name1 = sprintf('Predictor: %d', pc);
    if ~isempty(strfind(lower(bc.Predictor(pc).Name2), 'constant'))
        ncs = ncs + 1;
    end
end

% depending on RFX status
if bc.ProjectTypeRFX

    % for RFX's also check possibly available covariate data!
    if isfield(bc.RunTimeVars, 'CovariatesData') && ...
        size(bc.RunTimeVars.CovariatesData, 1) == numel(bc.GLMData.Subject)

        % keep according entries
        bc.RunTimeVars.CovariatesData = bc.RunTimeVars.CovariatesData(ks, :);
    end

    % and groups
    if isfield(bc.RunTimeVars, 'Groups') && ...
       ~isempty(bc.RunTimeVars.Groups)
        kss = zeros(1, numel(ks));
        kss(ks) = 1:sum(ks);
        for gc = 1:size(bc.RunTimeVars.Groups, 1)
            if ~isempty(bc.RunTimeVars.Groups{gc, 2})
                bc.RunTimeVars.Groups{gc, 2} = ...
                    kss(bc.RunTimeVars.Groups{gc, 2}(ks(bc.RunTimeVars.Groups{gc, 2})));
            end
        end
    end

    % and maps
    if isfield(bc.RunTimeVars, 'Map') && ...
        numel(bc.RunTimeVars.Map) == numel(kp)
        bc.RunTimeVars.Map( ...
            lsqueeze(repmat(~ks(:)', bc.NrOfSubjectPredictors, 1))) = [];
    else
        bc.RunTimeVars.Map = repmat(struct( ...
        'Type', 15, 'LowerThreshold', 1, 'UpperThreshold', 5, 'Name', '', ...
        'RGBLowerThreshPos', [255, 0, 0], 'RGBUpperThreshPos', [255, 255, 0], ...
        'RGBLowerThreshNeg', [255, 0, 255], 'RGBUpperThreshNeg', [0, 0, 255], ...
        'UseRGBColor', 0, 'LUTName', '<default>', 'TransColorFactor', 1, ...
        'NrOfLags', 0, 'MinLag', 0, 'MaxLag', 0, 'CCOverlay', 0, ...
        'ClusterSize', 4, 'EnableClusterCheck', 0, 'UseValuesAboveThresh', 1, ...
        'DF1', 0, 'DF2', 0, 'ShowPositiveNegativeFlag', 3, ...
        'BonferroniValue', 0, 'NrOfFDRThresholds', 0, 'FDRThresholds', zeros(0, 3), ...
        'OverlayColors', []), 1, sum(kp));
    end

    % then remove from GLMData.Subject
    bc.GLMData.Subject = bc.GLMData.Subject(ks);
    bc.NrOfSubjects = numel(bc.GLMData.Subject);

% for non RFX projects
else
    bc.GLMData.BetaMaps(:, :, :, ~kp) = [];
end

% patch other fields
bc.NrOfTimePoints = bc.NrOfTimePoints - tpm;
bc.NrOfPredictors = numel(bc.Predictor);
bc.NrOfConfounds = ncs;
bc.NrOfStudies = numel(bc.Study);
bc.NrOfStudiesWithConfounds = bc.NrOfStudiesWithConfounds - sum(~kt);
bc.NrOfConfoundsPerStudy = bc.NrOfConfoundsPerStudy(kt);

% set content
xffsetcont(hfile.L, bc);
