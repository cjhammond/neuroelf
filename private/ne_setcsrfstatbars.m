% PUBLIC FUNCTION ne_setcsrfstatbars: set current Surfaces stats color bars
function varargout = ne_setcsrfstatbars(varargin)

% Version:  v0.9d
% Build:    14071116
% Date:     Jul-11 2014, 4:39 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2014, Jochen Weber
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
if nargin < 3 || ...
   ~ischar(varargin{3}) || ...
    isempty(varargin{3}) || ...
   ~isfield(ne_gcfg.cc, varargin{3}(:)')
    cc = ne_gcfg.fcfg;
    ch = ne_gcfg.h;
    scn = mlhandle(ch.Scenery);
    sci = get(scn, 'Value');
    scu = get(scn, 'UserData');
else
    ch = ne_gcfg.cc.(varargin{3}(:)');
    cc = ch.Config;
    scn = ch.Scenery;
    sci = scn.Value;
    scu = scn.UserData;
end

% don't show stats bars?
if ~ne_gcfg.c.ini.Statistics.ShowThreshBars || ...
    isempty(scu) || ...
    isempty(sci) || ...
    cc.page ~= 3
    set(ch.SurfaceStatsBar, 'Visible', 'off');
    return;
end

% start with scenery
sbars = cell(1, numel(sci));
for uc = 1:numel(sci)
    f = scu{sci(uc), 4};
    try
        fh = handles(f);
        sbars{uc} = fh.SurfStatsBars;
    catch ne_eo;
        ne_gcfg.c.lasterr = ne_eo;
    end
end
sbarsz = cc.SurfBarSize;
sbars = cat(2, sbars{:});
sbarv = cat(2, sbars{:});
sbarw = size(sbarv, 2);
if sbarw == 0
    vflag = get(ch.SurfaceStatsBar, 'Visible');
    if ~strcmpi(vflag, 'off')
        set(ch.SurfaceStatsBar, 'Visible', 'off');
    end
    return;
end
sbarf = (sbarsz(2) +1 - sbarw) / sbarw;
blanks = 1;
if sbarf < 1
    blanks = 0;
    sbarf = floor(sbarsz(2) / sbarw);
    if sbarf < 1
        return;
    end
end
sbari = floor(1:(sbarf+blanks):(sbarsz(2)+0.9));
sbari(end+1) = sbarsz(2) + 1;
sbari = sbari(:)';

% create image first
barimage = repmat(reshape(cc.SurfBackColor, [1, 1, 3]), sbarsz);
for bc = 1:sbarw
    sbarf = sbari(bc+1)-(sbari(bc) + blanks);
    if sbarf > 1
        barimage(:, sbari(bc):sbari(bc)+sbarf-1, :) = repmat(sbarv(:, bc, :), 1, sbarf);
    else
        barimage(:, sbari(bc), :) = sbarv(:, bc, :);
    end
end

% output image?
if nargout > 0
    varargout{1} = barimage;
end

% prepare for display
barimage = reshape(barimage, [1, prod(sbarsz), 3]);
barimage = reshape(cat(1, barimage, barimage), [2 * prod(sbarsz), 3]);

% set group enabled?
if sbarw > 0
    set(ch.SurfaceStatsBar, 'FaceVertexCData', barimage, 'Visible', 'on');
else
    set(ch.SurfaceStatsBar, 'Visible', 'off');
end
