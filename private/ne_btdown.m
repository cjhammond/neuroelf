% FUNCTION ne_btdown: react on click event (down)
function ne_btdown(varargin)

% Version:  v0.9d
% Build:    14062710
% Date:     Jun-27 2014, 10:29 AM EST
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
ch = ne_gcfg.h;

% only if nothing is waiting
if ne_gcfg.c.incb
    return;
end
ne_gcfg.c.incb = true;

% take note that the button is pressed!
ne_gcfg.c.btdown = gcbf;
ne_gcfg.c.btdoup = false;

% for main window
if ne_gcfg.c.btdown == ne_gcfg.h.MainFigMLH

    % record where and what modifiers at the time
    ne_gcfg.fcfg.mpos.down = ne_gcfg.h.MainFig.CurrentPoint;
    ne_gcfg.fcfg.mpos.mods = ne_gcfg.fcfg.mods;

    % update StatsVar (to allow command line changes of VMPs to be added)
    cc = ne_gcfg.fcfg;
    if isxff(cc.StatsVar, true)
        stvmaps = ch.StatsVarMaps.String;
        if ischar(stvmaps)
            stvmaps = cellstr(stvmaps);
        end
        if numel(cc.StatsVar.Map) ~= numel(stvmaps)
            ne_setcstats;
        end
    end

    % update?
    tcplot = strcmpi(get(ch.TCPlot.MLHandle, 'Visible'), 'on');
    if cc.page < 3
        fPos = [cc.slicepos; cc.zslicepos(1, :); cc.tcpos; cc.histpos];
        nPos = ne_gcfg.h.MainFig.CurrentPoint;
        if cc.page == 1 && ...
            any(all(nPos([1, 1, 1], :) >= (fPos(1:3, 1:2) - 1), 2) & all(nPos([1, 1, 1], :) <= (fPos(1:3, 3:4) + 1), 2))
            ne_setslicepos(0, 0, [], 'OnMouse');
        elseif cc.page == 2 && ...
            all(nPos >= (fPos(4, 1:2) - 1)) && ...
            all(nPos <= (fPos(4, 3:4) + 1))
            ne_setslicepos(0, 0, [], 'OnMouse');
        elseif tcplot && ...
            isempty(cc.mods) && ...
            all(nPos >= (fPos(5, 1:2) - 1)) && ...
            all(nPos <= (fPos(5, 3:4) + 1))
            ne_setslicepos;
        elseif all(nPos >= (fPos(6, 1:2) - 1)) && ...
            all(nPos <= (fPos(6, 3:4) + 1)) && ...
            isempty(cc.mods)
            ne_setslicepos;
        else
            ne_gcfg.c.btdown = -1;
        end
    elseif cc.page == 4
        fPos = [cc.zslicepos(1, :); cc.tcpos; cc.histpos];
        nPos = ne_gcfg.h.MainFig.CurrentPoint;
        if all(nPos >= (fPos(1, 1:2) - 1)) && ...
            all(nPos <= (fPos(1, 3:4) + 1))
            ne_render_setview(0, 0, [], 'preview');
        elseif tcplot && ...
            isempty(cc.mods) && ...
            all(nPos >= (fPos(2, 1:2) - 1)) && ...
            all(nPos <= (fPos(2, 3:4) + 1))
            ne_render_setview(0, 0, [], 'preview');
        elseif all(nPos >= (fPos(3, 1:2) - 1)) && ...
            all(nPos <= (fPos(3, 3:4) + 1)) && ...
            isempty(cc.mods)
            ne_render_setview;
        else
            ne_gcfg.c.btdown = -1;
        end
    elseif cc.page ~= 3
        ne_gcfg.c.btdown = -1;
    end

% or look for satellites
else
    try
        sats = fieldnames(ne_gcfg.cc);
        for sc = 1:numel(sats)
            if ne_gcfg.c.btdown == ne_gcfg.cc.(sats{sc}).SatelliteMLH
                ne_gcfg.cc.(sats{sc}).Config.mpos.down = ...
                    ne_gcfg.cc.(sats{sc}).Satellite.CurrentPoint;
                ne_gcfg.cc.(sats{sc}).Config.mpos.mods = ne_gcfg.fcfg.mods;
                switch (ne_gcfg.cc.(sats{sc}).Config.sattype)
                    case {'slice'}
                        ne_setsatslicepos(0, 0, ...
                            ne_gcfg.cc.(sats{sc}).Config.sattag);
                    case {'surf'}
                        ne_setsurfpos(0, 0, ne_gcfg.cc.(sats{sc}).Config.sattag);
                    case {'render'}
                        ne_render_setview(0, 0, ne_gcfg.cc.(sats{sc}).Config.sattag, 'preview');
                end
                break;
            end
        end
    catch ne_eo;
        ne_gcfg.c.lasterr = ne_eo;
    end
end

% unblock
ne_gcfg.c.incb = false;
