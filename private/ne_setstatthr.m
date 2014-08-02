% FUNCTION ne_setstatthr: set stats threshold from text control
function varargout = ne_setstatthr(varargin)

% Version:  v0.9c
% Build:    13040517
% Date:     Apr-29 2011, 8:11 PM EST
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

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% get current config
cc = ne_gcfg.fcfg;
ch = ne_gcfg.h;

% current VMP and index
stvar = cc.StatsVar;
stvix = cc.StatsVarIdx;

% get controls content
lowt = ch.Stats.LThresh.String;
uppt = ch.Stats.UThresh.String;

% allow for errors
try

    % convert to doubles, and test validity (overriding bad numbers)
    lowt = str2double(lowt);
    if any(isnan(lowt)) || ...
        any(isinf(lowt)) || ...
        isempty(lowt)
        lowt = cc.StatsVarThr(1);
    end
    uppt = str2double(uppt);
    if any(isnan(uppt)) || ...
        any(isinf(uppt)) || ...
        isempty(uppt)
        uppt = cc.StatsVarThr(2);
    end
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
    lowt = cc.StatsVarThr(1);
    uppt = cc.StatsVarThr(2);
end

% check thresholds
if lowt < 0
    lowt = -lowt;
elseif lowt == 0
    lowt = 1e-9;
end
if uppt < lowt
    uppt = lowt + 1;
elseif uppt == lowt
    uppt = min(2 * lowt, lowt + 0.001);
end

% then set into figure configuration
ne_gcfg.fcfg.StatsVarThr = [lowt, uppt];

% and into text controls
ch.Stats.LThresh.String = sprintf('%.4f', lowt);
ch.Stats.UThresh.String = sprintf('%.4f', uppt);

% if only one map of a VMP is selected
if numel(stvar) == 1 && ...
    isxff(stvar, {'ava', 'cmp', 'glm', 'hdr', 'head', 'vmp', 'vtc'}) && ...
    numel(stvix) == 1

    % get current thresholds (to test for equality)
    oldt = [stvar.Map(stvix).LowerThreshold, stvar.Map(stvix).UpperThreshold];

    % then set new thresholds
    stvar.Map(stvix).LowerThreshold = lowt;
    stvar.Map(stvix).UpperThreshold = uppt;

    % compare with new values
    newt = [stvar.Map(stvix).LowerThreshold, stvar.Map(stvix).UpperThreshold];

    % if different and clustering is requested
    sttyp = lower(stvar.Filetype);
    if any(oldt ~= newt) && ...
        stvar.Map(stvix).EnableClusterCheck && ...
        ~any(strcmp(sttyp, {'ava', 'glm'}))
        switch (sttyp)
            case {'cmp'}
                stvar.Map(stvix).CMPDataCT = [];
            case {'hdr'}
                stvar.VoxelDataCT{stvix} = [];
            case {'head'}
                stvar.Brick(stvix).DataCT = [];
            case {'vmp'}
                stvar.Map(stvix).VMPDataCT = [];
        end

        % then re-cluster using @VMP::ClusterTable (without other outputs)
        stvar.ClusterTable(stvix, []);
    end
end

% and update window (either way)
ne_setslicepos;
