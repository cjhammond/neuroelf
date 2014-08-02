% FUNCTION ne_cm_addcon: add a contrast
function ne_cm_addcon(varargin)

% Version:  v0.9b
% Build:    11051315
% Date:     Aug-11 2010, 9:00 AM EST
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

%global variable
global ne_gcfg;
cc = ne_gcfg.fcfg.CM;
ch = ne_gcfg.h.CM.h;

% request new contrast name
newcon = inputdlg({'Please enter the contrast''s name:'}, ...
    'NeuroElf GUI - input', 1, {'contrast'});
if isequal(newcon, 0) || ...
    isempty(newcon)
    return;
end
if iscell(newcon)
    newcon = newcon{1};
end

% put into list of contrasts
cc.cons{end + 1, 1} = newcon;

% already contrasts configured
if size(cc.cons, 1) > 1

    % set new weights to 0
    cc.cons{end, 2} = zeros(numel(cc.preds), 1);

% no contrasts yet
else

    % get current weights
    cc.cons{end, 2} = ne_cm_getweights;
end

% set weights
ne_cm_setweights(cc.cons{end, 2});

% then update dropdown
ch.Contrasts.String = cc.cons(:, 1);
ch.Contrasts.Value = size(cc.cons, 1);
ne_gcfg.h.CM.CMFig.SetGroupEnabled('HasCons', 'on');

% and current GLM
cc.glm.RunTimeVars.Contrasts = cc.cons;
ne_cm_updateuis(0, 0, cc.glm);

% and config
ne_gcfg.fcfg.CM = cc;
