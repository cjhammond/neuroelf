% PUBLIC FUNCTION ne_setcstatmap: set current StatsVarIdx map
function varargout = ne_setcstatmap(varargin)

% Version:  v0.9d
% Build:    14070711
% Date:     Jul-07 2014, 11:15 AM EST
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

% clear index (in case we fail)
ne_gcfg.fcfg.StatsVarIdx = [];

% get handles
cc = ne_gcfg.fcfg;
ch = ne_gcfg.h;
stvar = cc.StatsVar;

% disable SVC menu
set(ch.SVCEntries, 'Enable', 'off');

% and if we're supposed to be disabled
if strcmpi(ch.StatsVar.Enable, 'off') || ...
   ~isxff(ne_gcfg.fcfg.StatsVar, true)

    % then set other controls also disabled and return
    ch.MainFig.SetGroupEnabled('SLoaded', 'off');
    ch.MainFig.SetGroupEnabled('SLdNVMP', 'off');

    % update render UI
    if isstruct(ne_gcfg.fcfg.Render) && ...
        isfield(ne_gcfg.fcfg.Render, 'hFig') && ...
        isxfigure(ne_gcfg.fcfg.Render.hFig, true)
        ne_gcfg.fcfg.Render.stvar = struct('FileType', 'NONE');
        ne_gcfg.fcfg.Render.stvix = [];
        ne_gcfg.fcfg.Render.stvixo = [];
        ne_gcfg.fcfg.Render.hFig.SetGroupEnabled('StVar', 'off');
        ne_gcfg.fcfg.Render.hFig.SetGroupEnabled('StVMP', 'off');
        ne_gcfg.fcfg.Render.hTag.ED_render_stvarfile.String = '<none>';
    end
    return;
end

% otherwise begin with default "loaded" configuration
ch.MainFig.SetGroupEnabled('SLoaded', 'on');
ch.MainFig.SetGroupEnabled('SLdNVMP', 'off');
ch.MainFig.SetGroupEnabled('SngVMP', 'off');

% input
stvix = [];
if nargin > 2 && ...
    isa(varargin{3}, 'double') && ...
   ~any(isinf(varargin{3}(:)) | isnan(varargin{3}(:)) | varargin{3}(:) < 1)
    stvix = round(varargin{3}(:));
end

% get index of dropdown
if isempty(stvix)
    stvix = ch.StatsVarMaps.Value;
end

% and set to configuration
stvarmnames = stvar.MapNames;
stvix(stvix < 1 | stvix > numel(stvarmnames)) = [];
cc.StatsVar.RunTimeVars.MapSelection = {stvarmnames(stvix), stvix(:)};
ne_gcfg.fcfg.StatsVarIdx = stvix;
ch.StatsVarMaps.Value = stvix;

% if multiple are selected
if numel(stvix) ~= 1

    % then we won't update any controls...
    ne_setslicepos;
    return;
end

% we definitely have one map only!
ch.MainFig.SetGroupEnabled('SngVMP', 'on');
ch.MainFig.SetGroupEnabled('SLdNVMP', 'off');

% otherwise, assume the threshold to be 0 ... 1
ne_gcfg.fcfg.StatsVarThr = [0, 1];

% re-read the configuration
cc = ne_gcfg.fcfg;
sttyp = lower(stvar.Filetype);

% also enable SVC?
if strcmp(sttyp, 'vmp') && ...
    isfield(stvar.Map(stvix), 'RunTimeVars') && ...
    numel(stvar.Map(stvix).RunTimeVars) == 1 && ...
    isstruct(stvar.Map(stvix).RunTimeVars) && ...
    isfield(stvar.Map(stvix).RunTimeVars, 'FWHMResEst') && ...
   ~isempty(stvar.Map(stvix).RunTimeVars.FWHMResEst) && ...
    isfield(stvar.Map(stvix).RunTimeVars, 'FWHMResImg') && ...
    isequal(size(stvar.Map(stvix).VMPData), size(stvar.Map(stvix).RunTimeVars.FWHMResImg))
    set(ch.SVCEntries, 'Enable', 'on');
end

% update figure title
ch.MainFig.Name = sprintf('NeuroElf GUI - %s - %s', ...
    ch.SliceVar.String{ch.SliceVar.Value}, ...
    ch.StatsVarMaps.String{ch.StatsVarMaps.Value});

% suppose we cannot sample values
mvals = [];

% as default, we use LUT coloring scheme
ch.Stats.UseLUT.RadioGroupSetOne;

% the rest depends on filetype
switch (sttyp)

    % for VMPs
    case {'ava', 'cmp', 'glm', 'hdr', 'head', 'vmp', 'vtc'}

        % do we need clustering ?
        if strcmp(sttyp, 'vmp') && ...
            isempty(stvar.Map(stvix).VMPDataCT) && ...
            stvar.Map(stvix).EnableClusterCheck > 0
            stvar.ClusterTable(stvix, []);
        end

        % get Map shortcut handle
        stmap = stvar.Map(stvix);

        % if invalid
        if isempty(stmap.LowerThreshold) || ...
            isempty(stmap.UpperThreshold)

            % slice data (forces thresolds)
            ntio = transimg(16, 16);
            stvar.SliceToTransimg([0, 0, 0], ntio, struct( ...
                'frame', [-8, -8, -8; 7.99, 7.99, 7.99], 'dir', 'sag', ...
                'mapvol', stvix, 'type', 'rgb'));

            % then delete transimg
            delete(ntio);

            % and re-get map
            stmap = stvar.Map(stvix);
        end

        % and make sure to update the enabled flags
        ch.MainFig.SetGroupEnabled('SLdNVMP', 'on');

        % set the thresholds in the figure config
        ne_gcfg.fcfg.StatsVarkThr = stmap.ClusterSize;
        ne_gcfg.fcfg.StatsVarThr = [stmap.LowerThreshold, stmap.UpperThreshold];
        ch.Stats.PosTail.Value = double(mod(stmap.ShowPositiveNegativeFlag, 2) > 0);
        ch.Stats.NegTail.Value = double(stmap.ShowPositiveNegativeFlag > 1);

        % and also set the parameters of the stats
        switch (stmap.Type)
            case {1}
                ne_gcfg.fcfg.StatsVarPar = {'t', stmap.DF1, 0};
            case {4}
                ne_gcfg.fcfg.StatsVarPar = {'F', stmap.DF1, stmap.DF2};
            case {2}
                ne_gcfg.fcfg.StatsVarPar = {'r', stmap.DF1, 0};
            case {9}
                ne_gcfg.fcfg.StatsVarPar = {'m', stmap.DF1, 0};
            case {30}
                ne_gcfg.fcfg.StatsVarPar = {'a', stmap.DF1, 0};
            otherwise
                ne_gcfg.fcfg.StatsVarPar{1} = '!';
        end

        % update controls on figure -> cluster threshold (size and status)
        set(ch.Stats.kThresh, 'String', sprintf('%d', ...
            max(1, floor(stmap.ClusterSize))));
        ch.Stats.UsekThr.Value = double(stmap.EnableClusterCheck ~= 0);

        % LUT/RGB choice
        if stmap.UseRGBColor ~= 0
            ch.Stats.UseRGB.RadioGroupSetOne;
        end

        % colors (buttons for colorpicker)
        bcolor = min(255, max(0, stmap.RGBLowerThreshPos(:)));
        ch.Stats.RGBLPos.BackgroundColor = (1 / 255) .* bcolor';
        bcolor = min(255, max(0, stmap.RGBUpperThreshPos(:)));
        ch.Stats.RGBUPos.BackgroundColor = (1 / 255) .* bcolor';
        bcolor = min(255, max(0, stmap.RGBLowerThreshNeg(:)));
        ch.Stats.RGBLNeg.BackgroundColor = (1 / 255) .* bcolor';
        bcolor = min(255, max(0, stmap.RGBUpperThreshNeg(:)));
        ch.Stats.RGBUNeg.BackgroundColor = (1 / 255) .* bcolor';

    % for AVA files, etc.
    otherwise

        % get thresholds for current map
        try
            thr = stvar.RunTimeVars.Thresholds;
        catch ne_eo;
            ne_gcfg.c.lasterr = ne_eo;
            thr = nan(1, 5);
        end
        thrl = min(size(thr, 1), stvix);
        thrv = thr(thrl, :);

        % if invalid
        if any(isnan(thrv))

            % slice data (forces thresolds)
            ntio = transimg(16, 16);
            stvar.SliceToTransimg([0, 0, 0], ntio, struct( ...
                'frame', [-8, -8, -8; 7.99, 7.99, 7.99], 'dir', 'sag', ...
                'mapvol', stvix, 'type', 'rgb'));

            % then reget thr
            thrv = stvar.RunTimeVars.Thresholds(stvix, :);
            delete(ntio);
        end

        % and then set in arrays
        ne_gcfg.fcfg.StatsVarThr = thrv(1:2);
end

% for single map, give useful alpha
if numel(stvix) == 1 && ...
    abs(cc.StatsVarAlpha) < 0.4
    ne_gcfg.fcfg.StatsVarAlpha = sign(cc.StatsVarAlpha);
end

% re-read configuration (after changes from VMP)
cc = ne_gcfg.fcfg;

% but if not GLM
if ~strcmpi(stvar.Filetype, 'glm') || ...
    stvar.ProjectTypeRFX == 0
    ch.StatsVarProject.Enable = 'off';
else
    ch.StatsVarProject.Enable = 'on';
end

% make sure threshold values are useful
if any(isinf(cc.StatsVarThr) | isnan(cc.StatsVarThr))
    ne_gcfg.fcfg.StatsVarThr = [0.5, 1];
end

% and possibly check the values of the map we actually have
if ~isempty(mvals)

    % get absolute values
    mvals = abs(mvals(:));

    % then winsorize
    mvals = winsorize(limitrangec(mvals, -1e6, 1e6, 0));

    % and remove zeros
    mvals(mvals == 0) = [];

    % get min, max, and mean
    upp = minmaxmean(mvals, 5);

    % compute thresholds as mean + 0.25 * std ... mean + std
    seps = sqrt(eps);
    ne_gcfg.fcfg.StatsVarThr = [ ...
        max(seps, upp(3) + 0.25 * sqrt(upp(6)) - upp(2) * seps), ...
        upp(3) + 3 * sqrt(upp(6)) + eps * upp(2)];

    % then re-read config
    cc = ne_gcfg.fcfg;
end

% set thresholds to text controls
ch.Stats.LThresh.String = sprintf('%.4f', cc.StatsVarThr(1));
ch.Stats.UThresh.String = sprintf('%.4f', cc.StatsVarThr(2));

% if alpha is < 0 (scaled blending), adapt alpha for more than 2 maps
if cc.StatsVarAlpha < 0 && ...
    numel(cc.StatsVarIdx) > 2
    ne_gcfg.fcfg.StatsVarAlpha = -2 / numel(cc.StatsVarIdx);
end

% update render page
if isstruct(ne_gcfg.fcfg.Render) && ...
    isfield(ne_gcfg.fcfg.Render, 'hFig') && ...
    isxfigure(ne_gcfg.fcfg.Render.hFig, true)

    % get name
    stvarfile = stvar.FilenameOnDisk(2);
    if isempty(stvarfile)
        stvarfile = sprintf('<untitled.%d>', lower(stvar.Filetype));
    elseif numel(stvarfile) > 51
        stvarfile = [stvarfile(1:24) '...' stvarfile(end-23:end)];
    end
    hRendFig = ne_gcfg.fcfg.Render.hFig;
    hRendFig.SetGroupEnabled('StVMP', 'off');
    hRendFig.SetGroupEnabled('StVar', 'on');
    if isxff(stvar, {'cmp', 'hdr', 'head', 'vmp'})
        hRendFig.SetGroupEnabled('StVMP', 'on');
    end
    ne_gcfg.fcfg.Render.hTag.ED_render_stvarfile.String = ['  ' stvarfile];

    % update maps' TransColorFactor
    tcf = ne_gcfg.fcfg.StatsVarAlpha;
    for mc = 1:numel(cc.StatsVarIdx)
        stvar.Map(cc.StatsVarIdx(mc)).TransColorFactor = tcf;
    end

    % make settings
    ne_gcfg.fcfg.Render.stvar = stvar;
    ne_gcfg.fcfg.Render.stvix = cc.StatsVarIdx;
    ne_gcfg.fcfg.Render.stvixo = cc.StatsVarIdx;

    % update UI
    if ne_gcfg.fcfg.page == 4
        ne_render_setview;
        return;
    end
end

% udpate screen
ne_setslicepos;
