% FUNCTION ne_cm_balancepredweights: try to auto-balance contrast so sum:=0
function ne_cm_balancepredweights(varargin)

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

% global variable
global ne_gcfg;
cc = ne_gcfg.fcfg.CM;
ch = ne_gcfg.h.CM.h;
w = ch.PredWeights.String;
if ~iscell(w)
    w = cellstr(w);
end
nw = eval(['[' gluetostringc(w, ';') ']']);
if sum(nw) == 0 || ...
    all(nw >= 0)
    return;
end
if any(nw ~= fix(nw))
    errordlg('Contrast weights must all be integer for auto-balancing.', ...
        'NeuroElf - error message', 'modal');
    return;
end
ppos = (nw > 0);
npos = (nw < 0);
spos = sum(nw(ppos));
sneg = -sum(nw(npos));
divi = gcd(spos, sneg);
nw(ppos) = (sneg / divi) .* nw(ppos);
nw(npos) = (spos / divi) .* nw(npos);
ppos = ppos | npos;
num = abs(nw(ppos));
sgn = sign(nw(ppos));
for divt = [2, 3, 5, 7, 11]
    if all(num / divt == round(num / divt))
        num = num / divt;
    end
end
nw(ppos) = sgn .* num;
for wc = 1:numel(w);
    w{wc} = sprintf('%d', nw(wc));
end
ch.PredWeights.String = w(:);

% update config?
if ~isempty(cc.cons)

    % get weights and set in config
    ne_gcfg.fcfg.CM.cons{ch.Contrasts.Value, 2} = ne_cm_getweights;
    ne_gcfg.fcfg.CM.glm.RunTimeVars.Contrasts = ne_gcfg.fcfg.CM.cons;
    ne_cm_updateuis(0, 0, cc.glm);
end
