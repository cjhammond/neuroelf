% FUNCTION ne_cm_setpredweight: set a given weight to selected predictors
function ne_cm_setpredweight(varargin)

% Version:  v0.9b
% Build:    11051315
% Date:     Apr-09 2011, 11:48 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2011, Jochen Weber
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
sel = ch.PredWeights.Value;
if isempty(sel) || ...
    nargin < 3
    return;
end
w = ch.PredWeights.String;
if ~iscell(w)
    w = cellstr(w);
end
for sc = sel(:)'
    if ~isempty(varargin{3})
        w{sc} = varargin{3};
    else
        selval = inputdlg({'Specify weight value for selected conditions:'}, ...
            'NeuroElf - user input', 1, {'  1'});
        if isempty(selval)
            return;
        end
        try
            selval = str2double(selval);
            if numel(selval) ~= 1|| ...
                isinf(selval) || ...
                isnan(selval)
                error('BAD_VALUE');
            end
        catch ne_eo;
            ne_gcfg.c.lasterr = ne_eo;
            return;
        end
        w{sc} = sprintf('%g', selval);
    end
end
ch.PredWeights.String = w;

% update config?
if ~isempty(cc.cons)

    % get weights and set in config
    ne_gcfg.fcfg.CM.cons{ch.Contrasts.Value, 2} = ne_cm_getweights;
    ne_gcfg.fcfg.CM.glm.RunTimeVars.Contrasts = ne_gcfg.fcfg.CM.cons;
    ne_cm_updateuis(0, 0, cc.glm);
end
