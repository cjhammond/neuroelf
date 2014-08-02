% FUNCTION ne_cm_roicovs: extract covariate(s) from selected ROI(s)
function ne_cm_roicovs(varargin)

% Version:  v0.9b
% Build:    11051315
% Date:     Sep-16 2010, 4:47 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, Jochen Weber
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

% get glm
glm = cc.glm;

% get VOI and VOI selection
if glm.ProjectType == 1
    voi = ne_gcfg.voi;
    voif = 'VOI';
elseif glm.ProjectType == 2
    voi = ne_gcfg.poi;
    voif = 'POI';
else
    return;
end
if ~isxff(voi, lower(voif))
    return;
end
vois = ne_gcfg.h.Clusters.Value;
if isempty(vois) || ...
    any(vois > numel(voi.(voif)))
    return;
end

% check contrast selection
csel = ch.Contrasts.Value;
if csel > size(glm.RunTimeVars.Contrasts, 1)
    cname = 'interactive';
    csel = ne_cm_getweights;
else
    cname = glm.RunTimeVars.Contrasts{csel, 1};
    csel = glm.RunTimeVars.Contrasts{csel, 2};
end

% check contrast weights
if ~any(numel(csel) == ([0, -1] + glm.NrOfSubjectPredictors)) || ...
    any(isinf(csel) | isnan(csel)) || ...
    sum(abs(csel)) == 0 || ...
   (~all(sign(csel) >= 0) && ...
    ~all(sign(csel) <= 0) && ...
    sum(csel) ~= 0)
    uiwait(warndlg('Invalid contrast weights specified.', 'NeuroElf - info'));
    return;
end

% extract contrast from VOI(s)
voib = squeeze(glm.VOIBetas(voi, struct('vl', vois)));
nvoi = numel(vois);
voic = zeros([size(voib, 1), 1, nvoi]);
for cwc = 1:numel(csel)
    if csel(cwc) ~= 0
        voic = voic + csel(cwc) .* voib(:, cwc, :);
    end
end
voic = squeeze(voic);

% otherwise add to list
cvc = size(cc.covs, 1);
cc.covs(cvc+1:cvc+nvoi, 1) = {''};
for ncvc = 1:nvoi
    vvoi = voi.(voif)(vois(ncvc));
    vname = vvoi.Name;
    if ~isempty(regexpi(vname, '_[LR]H_'))
        vname = regexprep(vname, '^Cluster\d+_(.*)_([LR]H_.*$)', ...
            sprintf('$2$1_%dvx', size(vvoi.Voxels, 1)));
    else
        vname = regexprep(sprintf('%s_%dvx', vname, size(vvoi.Voxels, 1)), ...
            '^Cluster\d+_', 'C_');
    end
    cc.covs{cvc + ncvc, 1} = sprintf('VOI(%s, %s)', vname, cname);
    cc.covs{cvc + ncvc, 2} = voic(:, ncvc);
end

% then set in handle
ch.Covs.String = cc.covs(:, 1);

% and update global array
ne_gcfg.fcfg.CM = cc;

% update in GLM
ne_cm_updatertv;
