% FUNCTION ne_cm_usegroups: change "use groups" setting
function ne_cm_usegroups(varargin)

% Version:  v0.9b
% Build:    10081109
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

% get shortcuts
cc = ne_gcfg.fcfg.CM;
ch = ne_gcfg.h.CM.h;
hFig = ne_gcfg.h.CM.CMFig;

% what's the current settings
if ~cc.usegroups

    % do groups need initialization?
    if isempty(cc.groups)

        % get subjects selection
        selsubs = ch.Subjects.Value;
        allsubs = ch.Subjects.String;
        if ~iscell(allsubs)
            allsubs = cellstr(allsubs);
        end

        % put into configuration
        cc.groups = { ...
            'Group 1', selsubs; ...
            'Group 2', setdiff(1:numel(allsubs), selsubs)};

        % and store back
        ne_gcfg.fcfg.CM.groups = cc.groups;
    end

    % fill in control
    ch.Groups.String = cc.groups(:, 1);
    ch.Groups.Value = 1;

    % keep track of setting
    ne_gcfg.fcfg.CM.usegroups = true;
    ch.UseGroups.Value = 1;
    hFig.SetGroupEnabled('Groups', 'on');

    % and update list
    ne_cm_selgroup;

% groups are being disabled
else

    % collect all subjects from groups
    allsubs = ch.Subjects.String;
    if ~iscell(allsubs)
        allsubs = cellstr(allsubs);
    end
    selsubs = false(1, numel(allsubs));
    for gc = 1:size(cc.groups, 1)
        selsubs(cc.groups{gc, 2}) = true;
    end
    allsubs = 1:numel(allsubs);
    selsubs = allsubs(selsubs);

    % disable feature
    ne_gcfg.fcfg.CM.usegroups = false;
    ch.UseGroups.Value = 0;
    ch.Groups.String = {'<no groups specified>'};
    ch.Groups.Value = 1;

    % then set (collected) selected subjects
    ch.Subjects.Value = selsubs(:);
    ch.Subjects.ListboxTop = 1;
    hFig.SetGroupEnabled('Groups', 'off');
end

% update in GLM
ne_cm_updatertv;
