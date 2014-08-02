% FUNCTION ne_showpage: show a page of controls
function varargout = ne_showpage(varargin)

% Version:  v0.9d
% Build:    14071916
% Date:     Jul-19 2014, 4:12 PM EST
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

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% check input arguments (either page number or '+1', '-1')
if nargin < 3 || ...
   ((~isa(varargin{3}, 'double') || ...
     numel(varargin{3}) ~= 1) && ...
    (~ischar(varargin{3}) || ...
     ~any(strcmp(varargin{3}, {'+1', '-1'}))))
    return;
end

% get config and handles
cc = ne_gcfg.fcfg;
ch = ne_gcfg.h;

% what about crosshair display
if cc.chair
    sl = 'on';
else
    sl = 'off';
end

% show requested page
ch.MainFig.ShowPage(varargin{3}, 'norefresh');

% make sure the time-course plot is set invisible to begin with
ch.TCPlot.Visible = 'off';
ch.MainFig.SetGroupEnabled('TCPlot', 'off');

% then get current page (allowing for string call)
ne_gcfg.fcfg.page = ch.MainFig.ShowPage('cur');

% histogram visibility
hv = 'off';

% default slicing indicator and surface axes visibility
sl1 = 'off';
sl2 = 'off';
sra = 'off';

% pre-set label for VOI menu
ch.Menu.VOI.Label = 'VOI';

% for first page
cpage = ne_gcfg.fcfg.page;
if cpage == 1

    % update window
    ne_gcfg.fcfg.zoom = 0;
    ne_setslicepos;

    % take show flag for 3-slice crosshairs
    sl1 = sl;

    % histogram is visible
    hv = 'on';

% for second page
elseif cpage == 2

    % update window
    ne_setslicepos;

    % vice versa
    sl2 = sl;
    hv = 'on';

% for third page (surface view)
elseif cpage == 3

    % re-set VOI -> POI label
    ch.Menu.VOI.Label = 'POI';
    
    % make sure scenery value/listboxtop are valid
    ch.Scenery.ListboxTop = ...
        max(1, min(ch.Scenery.ListboxTop, size(ch.Scenery.UserData, 1)));

    % update window
    ne_setsurfpos(0, 0, 1);

    % surface axes and children on
    sra = 'on';

% for forth page (render view)
elseif cpage == 4

    % histogram visible
    hv = 'on';
end

% make the settings
set([ch.CorLineX, ch.CorLineY, ch.SagLineX, ch.SagLineY, ...
     ch.TraLineX, ch.TraLineY], 'Visible', sl1);
set([ch.ZoomLineX, ch.ZoomLineY], 'Visible', sl2);
set([get(ch.CorLineX, 'Parent'), get(ch.SagLineX, 'Parent'), ...
     get(ch.TraLineX, 'Parent'), get(ch.ZoomLineX, 'Parent')], 'Visible', 'off');
set(ch.Surface, 'Visible', sra);
src = get(ch.Surface, 'Children');
if ~isempty(src)
    set(src, 'Visible', 'off');
    if strcmp(sra, 'on')
        for sc = src(:)'
            if strcmpi(get(sc, 'Type'), 'light')
                set(sc, 'Visible', 'on');
            end
        end
        sri = ch.Scenery.Value;
        if ~isempty(sri)
            sri = ch.Scenery.UserData(sri, :);
            for sc = 1:size(sri, 1)
                try
                    srfh = handles(sri{sc, 4});
                    set(srfh.Surface, 'Visible', 'on');
                catch ne_eo;
                    ne_gcfg.c.lasterr = ne_eo;
                end
            end
        end
    end
end
set([ch.HistImage, ch.HistLine1, ch.HistLine2, ch.HistPlot], 'Visible', hv);
