% FUNCTION ne_initwindow: initialize main window UI
function ne_initwindow(MainFig)

% Version:  v0.9d
% Build:    14072417
% Date:     Jul-24 2014, 5:41 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010 - 2014, Jochen Weber
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

% reject if not a valid figure
if ~isxfigure(MainFig);
    return;
end

% set root property
set(0, 'ShowHiddenHandles', 'off');

% get all named menu items and controls from main UI figure
tags = MainFig.TagStruct;

% create and populate NeuroElf's global configuration
disp(' - setting up core configuration...');
pause(0.001);
c = struct;

% atlas labels
c.atlas.tal = struct('labels', {tdlocal2(8, 'labels')});
c.atlas.tal.shorts = regexprep(lower(c.atlas.tal.labels), '\s+', '_');

% list of blocking callbacks used to reject double calls and keep the
% window open as long as needed
c.blockcb = {};
c.breakcb = {};

% keep track of mouse button down
c.btdown = [];
c.btdoup = false;
c.btdwnf = '';
c.btupact = {};

% create list of public callbacks
c.callbacks = struct;
flist = findfiles([neuroelf_path '/private'], 'ne_*.m', 'depth=1');
for cbc = 1:numel(flist)
    [fpath, fname] = fileparts(flist{cbc});
    try
        c.callbacks.(fname(4:end)) = eval(['@' fname]);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end
c.callbacks.slicevar = @cv_slicevar;
c.callbacks.statsvar = @cv_statsvar;
c.callbacks.varlist = @cv_varlist;

% echo calls to prompt
c.echo = false;

% extended map names
c.extmapnames = false;

% used for simple test if currently in a modal callback
c.incb = false;

% load configuration file
try
    c.ini = xini([neuroelf_path('config') '/neuroelf.ini'], 'convert');
    if ~isxini(c.ini)
        error( ...
            'neuroelf:ConfigError', ...
            'Error loading neuroelf.ini' ...
        );
    end
catch ne_eo;
    rethrow(ne_eo);
end

% last error caught
c.lasterr = [];

% last update
c.lastupd = -1;

% linked browsing
c.linked = false;

% get OS type and if it's Mac
c.ostype = ostype;
c.ostypemac = strcmpi(c.ostype.machine, 'mac');

% physio configuration
c.physio = struct( ...
    'filter', {{'*.acq', 'Acknowledge files (*.acq)'; ...
     '*.mat', 'MAT files (*.mat)'; ...
     '*.ntt;*.log;*.txt;*.csv', 'Numeric text files (*.ntt, *.log, *.txt, *.csv)'; ...
     '*.*',   'All files (*.*)'}});

% remote configuration
if isempty(c.ini.Remote.ScanFolder) || ...
    exist(c.ini.Remote.ScanFolder, 'dir') ~= 7
    c.ini.Remote.ScanFolder = neuroelf_path('cache');
end
c.remote = false;
c.remotecfg = struct( ...
    'cmdcount',  0, ...
    'cmdfiles',  {cell(0, 6)}, ...
    'commandid', zeros(0, 2), ...
    'commands',  {cell(0, 6)}, ...
    'gcwcount',  c.ini.Remote.GCWaitCount, ...
    'lastcmd',   -1, ...
    'lastscan',  -1, ...
    'logfile',   -1, ...
    'scanning',  false, ...
    'scanpath',  c.ini.Remote.ScanFolder, ...
    'scantimer', [], ...
    'session',   struct('S000000', struct), ...
    'stopping',  false, ...
    'stoptimer', false);

% resize and render preview in progress
c.resize = false;
c.rpreview = false;
c.satresize = false;

% sampled values
c.svals = [];

% initialize global storage structure
% .c       - core configuration
% .cc      - children config
% .fcfg    - figure configuration (reflecting controls, etc.)
% .h       - handles
% .lut     - main LUT object (for non-VMP StatsVar display)
% .poi     - POI object reflecting the cluster list
% .tio     - transimg objects for main window slice display
% .voi     - VOI object reflecting the cluster list
% .w       - workspace (variables in NeuroElf control)
% .wc      - workspace control (variables to be cleared upon exit)
ne_gcfg = struct( ...
    'c',      c, ...
    'cc',     struct, ...
    'fcfg',   struct, ...
    'h',      struct, ...
    'lut',    [], ...
    'poi',    [], ...
    'tio',    struct, ...
    'voi',    [], ...
    'w',      struct, ...
    'wc',     struct);

% begin with figure default configuration
disp(' - initializing UI configuration...');
pause(0.001);
fcfg = ne_gcfg.fcfg;

% children sub-configs
fcfg.CM = [];
fcfg.MDM = [];
fcfg.MKDA = [];
fcfg.RM = [];
fcfg.Render = [];
fcfg.VisMontage = [];

% alphasim thresholds
fcfg.asimthr = c.ini.Tools.alphasim.Thresholds;

% crosshair visible and color
fcfg.chair = c.ini.MainFig.Crosshairs;
fcfg.chcol = c.ini.MainFig.CrosshairColor;

% cluster connectivity setting
fcfg.clconn = 'edge';

% cluster limitation radius (in mm)
fcfg.clim = 6;

% cluster sorting
fcfg.clsort = c.ini.Statistics.Sorting;

% current position (in TAL coordinates and order)
fcfg.cpos = [0, 0, 0];

% cursor stepsize (depending on dataset)
fcfg.cstep = 1;

% current drawing "direction" (slice)
fcfg.ddir = [1, 2];

% order in which the 't' keypress toggles through
fcfg.dirorder = {'sag', 'cor', 'tra'};

% current DTI object
fcfg.dti = [];

% full figure size
fcfg.fullsize = MainFig.Position(3:4);
fcfg.fullsized = true;
fcfg.fullsizes = tags.TX_NeuroElf_SValues.Position(1:2) + [-10, 4];

% record current position of all controls
set(0, 'ShowHiddenHandles', 'on');
fcfg.fullsizex = get(MainFig.MLHandle, 'Children');
set(0, 'ShowHiddenHandles', 'off');
fctype = get(fcfg.fullsizex, 'Type');
fcfg.fullsizex(strcmpi(fctype, 'uimenu')) = [];
fcfg.fullsizex(:, 2:10) = 0;
fcpos = get(fcfg.fullsizex(:, 1), 'Position');
fcpos = cat(1, fcpos{:});
fcfg.fullsizex(:, 3:6) = fcpos;

% and compute small (swapped) size
fcfg.fullsizex(:, 7:10) = fcpos - ...
    repmat([fcfg.fullsizes, 0, 0], size(fcpos, 1), 1);

% central controls, shift a quarter up + a quarter right
fcfg.fullsizex( ...
    fcpos(:, 1) > (tags.FR_NeuroElf_vertdivide.Position(1) + 4) & ...
    fcpos(:, 1) < (tags.CB_NeuroElf_Interpolate.Position(1) + 2) & ...
    fcpos(:, 2) > (tags.RB_NeuroElf_LUTColor.Position(2) - 4) & ...
    fcpos(:, 2) < (tags.ED_NeuroElf_BVSX.Position(2) + 16), 2) = 10;

% surface-space stats controls
fcfg.fullsizex( ...
    fcpos(:, 1) > (tags.FR_NeuroElf_vertdivide.Position(1) + 4) & ...
    fcpos(:, 2) < (tags.CB_NeuroElf_SrfNegStat.Position(2) + 16), 2) = 13;

% top left and left-side buttons (shift up)
fcfg.fullsizex( ...
    fcpos(:, 1) < (tags.FR_NeuroElf_vertdivide.Position(1)) & ...
    fcpos(:, 2) > (tags.LB_NeuroElf_clusters.Position(2) - 2), 2) = 1;
fcfg.fullsizex( ...
    fcpos(:, 1) < (tags.BT_NeuroElf_slvartrf.Position(1) - 2) & ...
    fcpos(:, 2) > (tags.LB_NeuroElf_clusters.Position(2) - 2), 2) = 11;
fcfg.fullsizex( ...
    fcpos(:, 1) > (tags.FR_NeuroElf_vertdivide.Position(1)) & ...
    fcpos(:, 1) < (tags.BT_NeuroElf_draw0.Position(1) + 2) & ...
    fcpos(:, 2) > (tags.BT_NeuroElf_showv16.Position(2) - 1), 2) = 1;

% right-side buttons (shift right, up)
fcfg.fullsizex( ...
    fcpos(:, 1) > (tags.BT_NeuroElf_undock.Position(1) - 2) & ...
    fcpos(:, 2) > (tags.BT_NeuroElf_render.Position(2) - 2), 2) = 3;

% right-bottom button (shift right)
fcfg.fullsizex( ...
    fcpos(:, 1) > (tags.BT_NeuroElf_undock.Position(1) - 2) & ...
    fcpos(:, 2) < (tags.BT_NeuroElf_render.Position(2) - 2), 2) = 5;

% cluster table (text) and dividing frame (size up) 1
fcfg.fullsizex( ...
    fcfg.fullsizex(:, 1) == tags.ED_NeuroElf_clusters.MLHandle, 2) = 12;
fcfg.fullsizex( ...
    fcfg.fullsizex(:, 1) == tags.FR_NeuroElf_vertdivide.MLHandle, 2) = 2;

% axes (full slices, surface, render) resize +width +height
fcfg.fullsizex( ...
    fcfg.fullsizex(:, 1) == tags.IM_NeuroElf_Slice_Zoom.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.AX_NeuroElf_Slice_Zoom.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.IM_NeuroElf_Slice_Rend.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.AX_NeuroElf_Slice_Rend.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.AX_NeuroElf_Surface.MLHandle, 2) = 4;

% some controls (resize +width)
fcfg.fullsizex( ...
    fcfg.fullsizex(:, 1) == tags.LB_NeuroElf_Scenery.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.ED_NeuroElf_SrfViewPnt.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.TX_NeuroElf_SValues.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.AX_NeuroElf_TC_Plot.MLHandle, 2) = 6;

% left slice, shift half up, resize half (both)
fcfg.fullsizex( ...
    fcfg.fullsizex(:, 1) == tags.IM_NeuroElf_Slice_SAG.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.AX_NeuroElf_Slice_SAG.MLHandle, 2) = 7;

% right-top slice, shift hal
fcfg.fullsizex( ...
    fcfg.fullsizex(:, 1) == tags.IM_NeuroElf_Slice_COR.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.AX_NeuroElf_Slice_COR.MLHandle, 2) = 8;

% right-top slice, shift hal
fcfg.fullsizex( ...
    fcfg.fullsizex(:, 1) == tags.IM_NeuroElf_Slice_TRA.MLHandle | ...
    fcfg.fullsizex(:, 1) == tags.AX_NeuroElf_Slice_TRA.MLHandle, 2) = 9;

% gradient display
fcfg.gradient = false;
fcfg.gradientu = false;

% gray-scale LUT
fcfg.graylut = [];

% histogram position
fcfg.histpos = tags.AX_NeuroElf_Slice_Hist.Position;
fcfg.histpos(3:4) = fcfg.histpos(1:2) + fcfg.histpos(3:4);
fcfg.histset = 0;
fcfg.histval = [0, 1];

% interpolation method (for statistical vars, SliceVar always linear)
fcfg.imethod = c.ini.Statistics.InterpMethod;

% join stats mode (vs. overlaying/overriding of later maps)
fcfg.join = c.ini.Statistics.JoinMaps;
fcfg.joinmd2 = c.ini.Statistics.JoinMapsMaxDist;
fcfg.joinulay = 5;

% split into local maxima
fcfg.localmax = c.ini.Statistics.LocalMax;
fcfg.localmaxsrf = c.ini.Statistics.LocalMaxSrfNeigh;
fcfg.localmaxsz = c.ini.Statistics.LocalMaxSizes;

% keyboard modifiers pressed at present
fcfg.mods = {};

% mouse position
fcfg.mpos = struct( ...
    'cur',  [0, 0], ...
    'ddat', {{}}, ...
    'down', [-1, -1], ...
    'last', [0, 0], ...
    'mods', {{}});

% neurosynth terms
fcfg.nsynth = struct( ...
    'termm', {findfiles([neuroelf_path('nsynth') '/terms'], '*.nii.gz', 'depth=1', 'relative=')}, ...
    'terms', {deblank(splittocellc(asciiread([neuroelf_path('nsynth') '/terms.txt']), ','))});

% no update flag
fcfg.noupdate = true;

% voxel-space orientation
if isempty(c.ini.MainFig.Orientation) || ...
    lower(c.ini.MainFig.Orientation(1)) ~= 'n'
    fcfg.orient = 'r';
else
    fcfg.orient = 'n';
end

% currently displayed page (xfigure property of figure object)
fcfg.page = 1;

% paint color code, mode (and settings; VMRs only)
fcfg.paint = struct( ...
    'bbox',  [-128, -128, -128; 128, 128, 128], ...
    'code',   240, ...
    'mode',   1, ...
    'over',   [0, 32767], ...
    'rad',    0, ...
    'shap2',  [0, 0], ...
    'shap2w', 1, ...
    'shap3',  [0, 0, 0], ...
    'shap3w', 1, ...
    'shape',  's', ...
    'smooth', 0, ...
    'smootk', ones(1001, 1));

% PLP handle (current PLP object, reference only)
fcfg.plp = [];

% p-values range factor (so, for p<0.05 what's the upper threshold?)
fcfg.prange = 0.0002;

% progress counter for tasks
fcfg.progress = struct;

% renderer
fcfg.renderer = c.ini.MainFig.Renderer;

% sampling frames (normal/zoom)
fcfg.sframe = [128, 128, 128; -127.9999, -127.9999, -127.9999];
fcfg.sframez = [96, 80, 104; -95.9999, -111.9999, -87.9999];

% show V16 content
fcfg.showv16 = false;

% position of 3-slice images
fcfg.slicepos = [ ...
    tags.IM_NeuroElf_Slice_SAG.Position; ...
    tags.IM_NeuroElf_Slice_COR.Position; ...
    tags.IM_NeuroElf_Slice_TRA.Position];
fcfg.slicepos(:, 3:4) = fcfg.slicepos(:, 1:2) + fcfg.slicepos(:, 3:4);

% surface configuration
fcfg.srfcfg = struct( ...
    'anglex',  180, ...
    'angley',  0, ...
    'time',    0, ...
    'trans',   [0, 0, 0], ...
    'zoom',    1);

% sampling stepsize (default: 1mm)
fcfg.sstep = 1;
fcfg.sstepz = 0.75;

% statistics-on-anatomical alpha-reduction factor
fcfg.stalphared = 2;

% data extracts from stats
fcfg.stext = struct( ...
    'cons', {cell(0, 2)}, ...
    'data', [], ...
    'vois', {{}});

% transformation matrix (can be used to rotate display)
fcfg.strans = eye(4);
fcfg.strrot = [0, 0, 0];
fcfg.strscl = [1, 1, 1];
fcfg.strtra = [0, 0, 0];
fcfg.strzoom = false;

% position of surface axes
fcfg.surfpos = tags.AX_NeuroElf_Surface.Position;
fcfg.surfpos(:, 3:4) = fcfg.surfpos(:, 1:2) + fcfg.surfpos(:, 3:4);

% sampling zoom (MNI brain only)
fcfg.szoom = false;

% time-course plot visible
fcfg.tcplot = false;
fcfg.tcplotdata = [];

% position of time-course display
fcfg.tcpos = tags.AX_NeuroElf_TC_Plot.Position;
fcfg.tcpos(3:4) = fcfg.tcpos(1:2) + fcfg.tcpos(3:4);

% text position objects
fcfg.txtpos = [ ...
    tags.ED_NeuroElf_TALX.MLHandle, ...
    tags.ED_NeuroElf_TALY.MLHandle, ...
    tags.ED_NeuroElf_TALZ.MLHandle, ...
    tags.ED_NeuroElf_BVSX.MLHandle, ...
    tags.ED_NeuroElf_BVSY.MLHandle, ...
    tags.ED_NeuroElf_BVSZ.MLHandle];

% update GLM beta plots?
fcfg.updglmbp = true;

% which zoom view (0: 3 slices, 1...3: sag, cor, tra)
fcfg.zoom = 0;

% position of zoomed slices (times 3, for three "objects")
fcfg.zslicepos = tags.IM_NeuroElf_Slice_Zoom.Position;
fcfg.zslicepos(3:4) = fcfg.zslicepos(1:2) + fcfg.zslicepos(3:4);
fcfg.zslicepos = fcfg.zslicepos([1, 1, 1], :);

% initialiaze SliceVar and StatsVar to empty
fcfg.SliceUnder = struct('Filetype', 'NONE', 'RunTimeVars', struct('Trf', eye(4)));
fcfg.SliceVar = struct('Filetype', 'NONE', 'RunTimeVars', struct('Trf', eye(4)));
fcfg.StatsVar = struct('Filetype', 'NONE', 'RunTimeVars', struct('Trf', eye(4)));
fcfg.StatsVarIdx = [];

% display threshold, parameters and alpha
fcfg.StatsVarThr = [0, 1];
fcfg.StatsVarPar = {'t', 1, 1};
fcfg.StatsVarAlpha = 1;

% stats var references object
fcfg.StatsVarRefObj = [];

% and repeat for surface files
fcfg.SurfBackColor = [0, 0, 0];
fcfg.SurfBarSize = [256, 64];
fcfg.SurfVar = struct('Filetype', 'NONE');
fcfg.SurfStatsVar = struct('Filetype', 'NONE');
fcfg.SurfStatsVarIdx = [];
fcfg.SurfStatsVarThr = [0, 1];
fcfg.SurfStatsVarPar = {'t', 1, 1};
fcfg.SurfStatsVarAlpha = 1;
fcfg.SurfStatsVarRefObj = [];

% try to load standard LUT
try
    ne_gcfg.lut = bless(xff([neuroelf_path('lut') '/Standard_extended.olt']));
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
    ne_gcfg.lut = bless(xff('new:olt'));
end

% create layered image objects
disp(' - creating transimg objects...');
pause(0.001);
ne_gcfg.tio = struct( ...
    'imSag', transimg(256, 256), ...
    'imCor', transimg(256, 256), ...
    'imTra', transimg(256, 256), ...
    'imSlZ', transimg(512, 512), ...
    'imRnd', transimg(512, 512), ...
    'satSag', [], ...
    'satCor', [], ...
    'satTra', [], ...
    'satSlZ', [], ...
    'satRnd', []);

% and set handles of images into transimg object (to allow use of display)
sethandle(ne_gcfg.tio.imSag, get(tags.IM_NeuroElf_Slice_SAG.MLHandle, 'Children'));
sethandle(ne_gcfg.tio.imCor, get(tags.IM_NeuroElf_Slice_COR.MLHandle, 'Children'));
sethandle(ne_gcfg.tio.imTra, get(tags.IM_NeuroElf_Slice_TRA.MLHandle, 'Children'));
sethandle(ne_gcfg.tio.imSlZ, get(tags.IM_NeuroElf_Slice_Zoom.MLHandle, 'Children'));
sethandle(ne_gcfg.tio.imRnd, get(tags.IM_NeuroElf_Slice_Rend.MLHandle, 'Children'));

% create default (new) POI/VOI objects
ne_gcfg.poi = bless(xff('new:poi'));
ne_gcfg.voi = bless(xff('new:voi'));

% put important ones into internal structure with short names
disp(' - retrieving UI handle shorthands...');
pause(0.001);
ch = ne_gcfg.h;

% main figure (xfigure and MLHandle)
ch.MainFig = MainFig;
ch.MainFigMLH = MainFig.MLHandle;
ch.MainFigTags = tags;

% direct children (contrast manager and vismontage UIs)
ch.CM = [];
ch.MDM = [];
ch.MKDA = [];
ch.RM = [];
ch.Render = [];
ch.VisMontage = [];

% initialize Children
ch.Children = struct;

% specific DTI menu entries
ch.DTIPlotFibers = tags.UIM_NeuroElf_DTIPlotFib;
ch.DTITrackFibers = tags.UIM_NeuroElf_HDRDTIFibTrack;

% echo calls menu item
ch.EchoCalls = tags.UIM_NeuroElf_EchoCalls;

% linked browsing menu item
ch.LinkedBrowse = tags.UIM_NeuroElf_LinkedBrowse;
ch.LinkedBrowseBT = tags.BT_NeuroElf_togglelink;

% recent files menu(s)
rfnum = c.ini.RecentFiles.Number;
ch.RecentFiles = struct( ...
    'slc',   {cell(rfnum, 1)}, ...
    'stat',  {cell(rfnum, 1)}, ...
    'srf',   {cell(rfnum, 1)}, ...
    'srfst', {cell(rfnum, 1)});
rffs = {'slc', 'stat', 'srf', 'srfst'};
rfms = { ...
    tags.UIM_NeuroElf_recentslice.MLHandle, ...
    tags.UIM_NeuroElf_recentstats.MLHandle, ...
    tags.UIM_NeuroElf_recentsrf.MLHandle, ...
    tags.UIM_NeuroElf_recentsrfst.MLHandle};
for rfc = 1:rfnum
    for rff = 1:4
        ch.RecentFiles.(rffs{rff}){rfc} = uimenu( ...
            'Enable',   'on', ...
            'Callback', {@ne_openfile, ''}, ...
            'Label',    sprintf('%s_%04d', rffs{rff}, rfc), ...
            'Parent',   rfms{rff}, ...
            'Visible',  'off');
    end
end

% listener toggle
ch.Listener = tags.BT_NeuroElf_RListener;

% neurosynth menu
ch.NeuroSynth = tags.UIM_NeuroElf_neurosynth;

% SVC menu entries
ch.SVCEntries = [ ...
    tags.UIM_NeuroElf_VMPSVCVOI.MLHandle, ...
    tags.UIM_NeuroElf_VMPSVCMask.MLHandle, ...
    tags.UIM_NeuroElf_VMPSVCVMR.MLHandle, ...
    tags.UIM_NeuroElf_VMPSVCColin.MLHandle];

% slicing and statistics variable selection (dropdown)
ch.SliceVar = tags.DD_NeuroElf_varlist;
ch.SliceVar.UserData = cell(0, 4);
ch.StatsVar = tags.DD_NeuroElf_statlist;
ch.StatsVar.UserData = cell(0, 4);
ch.SurfVar = tags.DD_NeuroElf_varlistsrf;
ch.SurfVar.UserData = cell(0, 4);
ch.SurfStatsVar = tags.DD_NeuroElf_statlistsrf;
ch.SurfStatsVar.UserData = cell(0, 4);
ch.Scenery = tags.LB_NeuroElf_Scenery;
ch.Scenery.UserData = cell(0, 4);
ch.Scenery.Value = [];
ch.SceneryProps = tags.BT_NeuroElf_SceneProps;
ch.SceneryViewPoint = tags.ED_NeuroElf_SrfViewPnt;

% available maps from StatsVar
ch.StatsVarMaps = tags.LB_NeuroElf_statmaps;
ch.StatsVarMaps.Value = [];
ch.StatsVarRefs = tags.DD_NeuroElf_statsref;
ch.StatsVarRefs.UserData = {[]};
ch.StatsVarRefRegs = tags.BT_NeuroElf_statsrefreg;
ch.StatsVarRefNuis = tags.BT_NeuroElf_statsrefixx;
ch.SurfStatsVarMaps = tags.LB_NeuroElf_statmapssrf;
ch.SurfStatsVarMaps.Value = [];
ch.SurfStatsVarRefs = tags.DD_NeuroElf_statsrefsrf;
ch.SurfStatsVarRefs.UserData = {[]};

% projection button
ch.StatsVarProject = tags.BT_NeuroElf_statmproj;

% show V16 button
ch.VMRShowV16 = tags.BT_NeuroElf_showv16;

% list of clusters
ch.Clusters = tags.LB_NeuroElf_clusters;
ch.Clusters.Value = [];
ch.Clusters.String = {};
ch.ClustersSrf = tags.LB_NeuroElf_Srfclust;
ch.ClustersSrf.Value = [];
ch.ClustersSrf.String = {};

% cluster output table
ch.ClusterTable = tags.ED_NeuroElf_clusters;

% cluster zoom toggle button
ch.ClusterZoom = tags.BT_NeuroElf_clustzoom;

% progress bar
ch.Progress = tags.PB_NeuroElf_mainpbar;
ch.Progress.Visible = 'off';

% surface axes
ch.Surface = tags.AX_NeuroElf_Surface.MLHandle;
srf = ch.Surface;
srfcfg = c.ini.Surface;
srfbcl = (1 / 255) .* srfcfg.BackgroundColor(:)';
fcfg.SurfBackColor = srfbcl;
set(srf, 'Color', srfbcl);
set(srf, 'View', [90, 0]);
slim = [-128, 128];
set(srf, 'XLim', 4 * slim, 'YLim', slim, 'ZLim', slim);
set(srf, 'XTick', [], 'YTick', [], 'ZTick', []);
for lc = 1:numel(srfcfg.Lights)
    light('Parent', srf, 'Position', ...
        srfcfg.Lights{lc}, 'Color', (1 / 255) .* srfcfg.LightColors{lc});
end
set(srf, 'XColor', [0, 0, 0], 'YColor', [0, 0, 0], 'ZColor', [0, 0, 0]);
ssbp = c.ini.Statistics.ThreshBarPos;
meshsize = floor(512 .* (ssbp(1, [4, 3]) - ssbp(1, [2, 1])));
fcfg.SurfBarSize = meshsize;
[ssbv, ssbf] = mesh3d(meshsize, struct( ...
    'orient', 4, ...
    'xline', [0.5, round(256 * (ssbp(2) - 0.5))], ...
    'yline', [0.5, round(256 * (ssbp(1) - 0.5))], ...
    'zvalue', -256));
ch.SurfaceStatsBar = ...
    patch(ssbv(:, 1), ssbv(:, 2), ssbv(:, 3), zeros(size(ssbv, 1), 1), ...
    'FaceColor', 'none', 'EdgeColor', 'none', 'Parent', ch.Surface, 'Visible', 'off');
set(ch.SurfaceStatsBar, 'Faces', ssbf, 'FaceVertexCData', repmat(srfbcl, size(ssbf, 1), 1), ...
    'FaceColor', 'flat', 'Visible', 'off');

% add crosshair lines to images axes objects -> SAG
chax = tags.AX_NeuroElf_Slice_SAG.MLHandle;
set(chax, 'Units', 'pixels');
ch.SagLineX = line([0; 0.999], [0.5; 0.5], 'Color', fcfg.chcol, 'Parent', chax);
ch.SagLineY = line([0.5; 0.5], [0.001; 0.999], 'Color', fcfg.chcol, 'Parent', chax);
set(chax, 'Units', 'pixels', 'XTick', [], 'YTick', [], 'Visible', 'off');

% -> COR
chax = tags.AX_NeuroElf_Slice_COR.MLHandle;
set(chax, 'Units', 'pixels');
ch.CorLineX = line([0; 0.999], [0.5; 0.5], 'Color', fcfg.chcol, 'Parent', chax);
ch.CorLineY = line([0.5; 0.5], [0.001; 0.999], 'Color', fcfg.chcol, 'Parent', chax);
set(chax, 'Units', 'pixels', 'XTick', [], 'YTick', [], 'Visible', 'off');

% -> TRA
chax = tags.AX_NeuroElf_Slice_TRA.MLHandle;
set(chax, 'Units', 'pixels');
ch.TraLineX = line([0; 0.999], [0.5; 0.5], 'Color', fcfg.chcol, 'Parent', chax);
ch.TraLineY = line([0.5; 0.5], [0.001; 0.999], 'Color', fcfg.chcol, 'Parent', chax);
set(chax, 'Units', 'pixels', 'XTick', [], 'YTick', [], 'Visible', 'off');

% -> Zoom
chax = tags.AX_NeuroElf_Slice_Zoom.MLHandle;
set(chax, 'Units', 'pixels');
ch.ZoomLineX = line([0; 0.999], [0.5; 0.5], 'Color', fcfg.chcol, 'Parent', chax);
ch.ZoomLineY = line([0.5; 0.5], [0.001; 0.999], 'Color', fcfg.chcol, 'Parent', chax);
set(chax, 'Units', 'pixels', 'XTick', [], 'YTick', [], 'Visible', 'off');

% -> Render
chax = tags.AX_NeuroElf_Slice_Rend.MLHandle;
set(chax, 'Units', 'pixels');
set(chax, 'Units', 'pixels', 'XTick', [], 'YTick', [], 'Visible', 'off');

% -> Histogram
chax = tags.AX_NeuroElf_Slice_Hist.MLHandle;
set(chax, 'Units', 'pixels');
ch.HistImage = tags.IM_NeuroElf_Slice_Hist.Children;
ch.HistLine1 = line([0; 0.5], [0.002; 0.002], 'Color', [0.5, 0.5, 0.5], ...
    'LineWidth', 3, 'Parent', chax);
ch.HistLine2 = line([0.5; 1], [0.998; 0.998], 'Color', [0.5, 0.5, 0.5], ...
    'LineWidth', 3, 'Parent', chax);
ch.HistPlot = line(0.1 * ones(256, 1), (1/512:1/256:511/512)', ...
    'Color', [0.25, 1, 0.25], 'LineWidth', 2, 'Parent', chax);
set(ch.HistImage, 'CData', repmat(uint8(0:255)', [1, 16, 3]));
set(chax, 'Units', 'pixels', 'YDir', 'normal', 'XTick', [], 'YTick', [], ...
    'Visible', 'off');
tags.IM_NeuroElf_Slice_Hist.YDir = 'normal';

% current position
ch.Coord.TEdX = mlhandle(tags.ED_NeuroElf_TALX);
ch.Coord.TEdY = mlhandle(tags.ED_NeuroElf_TALY);
ch.Coord.TEdZ = mlhandle(tags.ED_NeuroElf_TALZ);
ch.Coord.VEdX = mlhandle(tags.ED_NeuroElf_BVSX);
ch.Coord.VEdY = mlhandle(tags.ED_NeuroElf_BVSY);
ch.Coord.VEdZ = mlhandle(tags.ED_NeuroElf_BVSZ);

% time-dim controls
ch.Coord.Temp = tags.ED_NeuroElf_TempPos;
ch.Coord.TempSlider = tags.SL_NeuroElf_TempPos;
ch.Coord.TempSlider.Max = 120;
ch.Coord.TempSlider.Value = 1;
ch.Coord.TempSlider.Min = 1;

% undo paint toggle button
ch.DrawUndo = tags.BT_NeuroElf_drawu;

% menu item fast access
ch.Menu.CloseFile = tags.UIM_NeuroElf_closefile;
ch.Menu.CloseFile.Visible = 'off';
ch.Menu.LimitVMR = tags.UIM_NeuroElf_VMRLimitVMR;
ch.Menu.SelectFile = tags.UIM_NeuroElf_selectfile;
ch.Menu.SelectFile.Visible = 'off';
ch.Menu.Stats = tags.UIM_NeuroElf_STATS;
ch.Menu.Stats.Visible = 'off';
ch.Menu.VOI = tags.UIM_NeuroElf_VOI;
ch.Menu.VOI.Visible = 'off';

% add some text properties
ch.Stats.LThresh = tags.ED_NeuroElf_LowerThresh;
ch.Stats.UThresh = tags.ED_NeuroElf_UpperThresh;
ch.Stats.PosTail = tags.CB_NeuroElf_PositivStat;
ch.Stats.NegTail = tags.CB_NeuroElf_NegativStat;
ch.Stats.PThresh = tags.DD_NeuroElf_StatSetP;
ch.Stats.PThresh.String = {'0.05'; '0.02'; '0.01'; '0.005'; '0.002'; ...
    '0.001'; '0.0005'; '0.0001'; '1e-5'; '1e-6'};
ch.Stats.kThresh = tags.ED_NeuroElf_kExtThresh.MLHandle;
ch.Stats.UsekThr = tags.CB_NeuroElf_kExtThresh;
ch.Stats.ICBM2TAL = tags.CB_NeuroElf_ICBM2TAL;
ch.Stats.TDClient = tags.CB_NeuroElf_TDClient;
ch.Stats.UseLUT = tags.RB_NeuroElf_LUTColor;
ch.Stats.UseRGB = tags.RB_NeuroElf_RGBColor;
ch.Stats.RGBLPos = tags.BT_NeuroElf_RGBLowPos;
ch.Stats.RGBUPos = tags.BT_NeuroElf_RGBUppPos;
ch.Stats.RGBLNeg = tags.BT_NeuroElf_RGBLowNeg;
ch.Stats.RGBUNeg = tags.BT_NeuroElf_RGBUppNeg;
ch.SrfStats.LThresh = tags.ED_NeuroElf_SrfLowerThr;
ch.SrfStats.UThresh = tags.ED_NeuroElf_SrfUpperThr;
ch.SrfStats.PosTail = tags.CB_NeuroElf_SrfPosStat;
ch.SrfStats.NegTail = tags.CB_NeuroElf_SrfNegStat;
ch.SrfStats.PThresh = tags.DD_NeuroElf_SrfStatSetP;
ch.SrfStats.PThresh.String = {'0.05'; '0.02'; '0.01'; '0.005'; '0.002'; ...
    '0.001'; '0.0005'; '0.0001'; '1e-5'; '1e-6'};
ch.SrfStats.PThreshTxt = tags.TX_NeuroElf_SrfSetP;
ch.SrfStats.ClusterTable = tags.BT_NeuroElf_SrfClusterT;
ch.SrfStats.kThresh = tags.ED_NeuroElf_SrfkExtThr.MLHandle;
ch.SrfStats.UsekThr = tags.CB_NeuroElf_SrfkExtThr;
ch.SrfStats.UseLUT = tags.RB_NeuroElf_SrfLUTColor;
ch.SrfStats.UseRGB = tags.RB_NeuroElf_SrfRGBColor;
ch.SrfStats.RGBLPos = tags.BT_NeuroElf_SrfRGBLPos;
ch.SrfStats.RGBUPos = tags.BT_NeuroElf_SrfRGBUPos;
ch.SrfStats.RGBLNeg = tags.BT_NeuroElf_SrfRGBLNeg;
ch.SrfStats.RGBUNeg = tags.BT_NeuroElf_SrfRGBUNeg;

% split local max
ch.SplitLocalMax = tags.CB_NeuroElf_SplitMaxima;
ch.SplitLocalMax.Value = double(fcfg.localmax);

% interpolation checkbox
ch.Interpolate = tags.CB_NeuroElf_Interpolate;

% label with currently sampled values
ch.SampledValues = tags.TX_NeuroElf_SValues;

% time-course plot (plot a flat line as default)
ch.TCPlot = tags.AX_NeuroElf_TC_Plot;
ch.TCPlotChild = plot(ch.TCPlot.MLHandle, (1:120)', zeros(120, 1));
set(ch.TCPlot.MLHandle, 'HandleVisibility', 'off');
ch.TCPlotChildren = [];

% minimize/maximize buttons
ch.Maximize = tags.BT_NeuroElf_maximize;
ch.Minimize = tags.BT_NeuroElf_minimize;

% for children ob objects (handles will be deleted upon exit)
ch.fChild = [];

% add a child to SelectFile list
uimenu(mlhandle(tags.UIM_NeuroElf_selectfile), 'Label', 'none', 'Enable', 'off');

% populate Colin-27 list
try
    mmh = mlhandle(tags.UIM_NeuroElf_opencolin);
    sep = 'off';
    c27p = neuroelf_path('colin');
    c27l = splittocell(asciiread( ...
        [neuroelf_path('config') '/colin27fileorder.txt']), char([10, 13]), 1, 1);
    c27sl = grep(c27l, '-x', '\.vmr$');
    if ~isempty(c27sl)
        mmhc = uimenu(mmh, 'Label', 'VMRs');
        for lc = 1:numel(c27sl)
            if strcmpi(c27sl{lc}, 'separator.vmr')
                sep = 'on';
                continue;
            elseif exist([c27p '/' c27sl{lc}], 'file') == 2
                uimenu(mmhc, 'Label', ['    ' strrep(c27sl{lc}, '.vmr', '')], ...
                    'Callback', {@ne_openfile, [c27p '/' c27sl{lc}]}, ...
                    'Separator', sep);
            elseif isempty(regexpi(c27sl{lc}, '^colin'))
                uimenu(mmhc, 'Label', strrep(c27sl{lc}, '.vmr', ''), ...
                    'Enable', 'off');
            end
            sep = 'off';
        end
        sep = 'off';
    end
    c27sl = grep(c27l, '-x', '\.srf$');
    if ~isempty(c27sl)
        mmhc = uimenu(mmh, 'Label', 'Surfaces');
        for lc = 1:numel(c27sl)
            if strcmpi(c27sl{lc}, 'separator.srf')
                sep = 'on';
                continue;
            elseif exist([c27p '/' c27sl{lc}], 'file') == 2
                uimenu(mmhc, 'Label', ['    ' strrep(c27sl{lc}, '.srf', '')], ...
                    'Callback', {@ne_openfile, [c27p '/' c27sl{lc}]}, ...
                    'Separator', sep);
            elseif isempty(regexpi(c27sl{lc}, '^colin'))
                uimenu(mmhc, 'Label', strrep(c27sl{lc}, '.srf', ''), ...
                    'Enable', 'off');
            end
            sep = 'off';
        end
    end
    c27sl = grep(c27l, '-x', '\.subcort$');
    if ~isempty(c27sl)
        mmhc = uimenu(mmh, 'Label', 'Sub-cortical surfaces');
        for lc = 1:numel(c27sl)
            if exist([c27p '/' strrep(c27sl{lc}, '.subcort', '.srf')], 'file') == 2
                uimenu(mmhc, 'Label', ['    ' strrep(c27sl{lc}, '.subcort', '')], ...
                    'Callback', {@ne_openfile, [c27p '/' strrep(c27sl{lc}, '.subcort', '.srf')]}, ...
                    'Separator', 'off');
            end
        end
        uimenu(mmhc, 'Label', 'Load all subcortical surfaces', 'Callback', ...
            {@ne_srf_tools, 'loadsubcort', 0}, 'Separator', 'on');
        if ~isempty(findfiles(c27p, 'colin_subcort_*ICBMnorm.srf'))
        uimenu(mmhc, 'Label', 'Load all subcortical ICBMnorm surfaces', 'Callback', ...
            {@ne_srf_tools, 'loadsubcort', 'ICBMnorm'}, 'Separator', 'off');
        end
    end
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
    tags.UIM_NeuroElf_opencolin.Visible = 'off';
end

% populate LUT list
try
    mmh = mlhandle(tags.UIM_NeuroElf_LUTList);
    luts = findfiles(neuroelf_path('lut'), '*.olt', 'depth=1');
    for lc = 1:numel(luts)
        [lutp, lutf] = fileparts(luts{lc});
        lutf = strrep(lutf, '_', ' ');
        uimenu(mmh, ...
            'Label', [upper(lutf(1)) lutf(2:end)], ...
            'Callback', {@ne_openfile, luts{lc}});
    end
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
    tags.UIM_NeuroElf_LUTList.Visible = 'off';
end

% normalization files
try
    spmsnt2i = [];
    spmsni2t = [];
    spmsnt2i = load(neuroelf_file('t', 'talairach_seg_sn.mat'));
    spmsni2t = load(neuroelf_file('t', 'talairach_seg_inv_sn.mat'));
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
end

% set callbacks
disp(' - configuring UI object callbacks...');
pause(0.001);

% file menu
tags.UIM_NeuroElf_FILE.Callback = @ne_selectfile;
tags.UIM_NeuroElf_openfile.Callback = @ne_openfile;
tags.UIM_NeuroElf_openstatsfile.Callback = @ne_openstatsfile;
tags.UIM_NeuroElf_recentslice.Callback = {@ne_recentfiles, 'slc', 'SliceVar'};
tags.UIM_NeuroElf_recentstats.Callback = {@ne_recentfiles, 'stat', 'StatsVar'};
tags.UIM_NeuroElf_recentsrf.Callback = {@ne_recentfiles, 'srf', 'SurfVar'};
tags.UIM_NeuroElf_recentsrfst.Callback = {@ne_recentfiles, 'srfst', 'SurfStatsVar'};
tags.UIM_NeuroElf_clonefile.Callback = {@ne_clonefile, 'SliceVar'};
tags.UIM_NeuroElf_closefile.Callback = {@ne_closefile, 'SliceVar'};
tags.UIM_NeuroElf_reloadfile.Callback = {@ne_reloadfile, 'ana'};
tags.UIM_NeuroElf_setunderlay.Callback = @ne_setunderlay;
tags.UIM_NeuroElf_clonestats.Callback = {@ne_clonefile, 'StatsVar'};
tags.UIM_NeuroElf_newvmr.Callback = {@ne_newfile, 'vmr'};
tags.UIM_NeuroElf_reloadstats.Callback = {@ne_reloadfile, 'stats'};
tags.UIM_NeuroElf_savefile.Callback = {@ne_savefile, 'SliceVar', 0};
tags.UIM_NeuroElf_savefileas.Callback = {@ne_savefile, 'SliceVar', 1};
tags.UIM_NeuroElf_savestat.Callback = {@ne_savefile, 'StatsVar', 0};
tags.UIM_NeuroElf_savestatas.Callback = {@ne_savefile, 'StatsVar', 1};
tags.UIM_NeuroElf_savetextas.Callback = @ne_savetextoutput;
tags.UIM_NeuroElf_savetcsdm.Callback = @ne_savetcsdm;
tags.UIM_NeuroElf_reloadscene.Callback = {@ne_srf_tools, 'loadscenery'};
tags.UIM_NeuroElf_importvmr.Callback = @ne_importvmr;
tags.UIM_NeuroElf_importvmp.Callback = @ne_importvmp;
tags.UIM_NeuroElf_importrfxglm.Callback = @ne_importrfxglm;
tags.UIM_NeuroElf_closeallfiles.Callback = @ne_unloadobjects;

% file -> options -> cluster table
tags.UIM_NeuroElf_CTableNewVOI.Callback = {@ne_setoption, 'ctableadd', false};
tags.UIM_NeuroElf_CTableAddToVOI.Callback = {@ne_setoption, 'ctableadd', true};
tags.UIM_NeuroElf_CTableExtManual.Callback = {@ne_setoption, 'extonselect', 'manual'};
tags.UIM_NeuroElf_CTableExtSingle.Callback = {@ne_setoption, 'extonselect', 'single'};
tags.UIM_NeuroElf_CTableExtMulti.Callback = {@ne_setoption, 'extonselect', 'multi'};
tags.UIM_NeuroElf_CTableExtWithSID.Callback = {@ne_setoption, 'extwithsids'};
tags.UIM_NeuroElf_CTableExtSepSpc.Callback = {@ne_setoption, 'extsepchars', [32, 32]};
tags.UIM_NeuroElf_CTableExtSepTab.Callback = {@ne_setoption, 'extsepchars', 9};
tags.UIM_NeuroElf_CTableExtSepCom.Callback = {@ne_setoption, 'extsepchars', 44};
tags.UIM_NeuroElf_CTableExtSepSmc.Callback = {@ne_setoption, 'extsepchars', 59};
tags.UIM_NeuroElf_CTablePeak.Callback = {@ne_setoption, 'ctablelupcrd', 'peak'};
tags.UIM_NeuroElf_CTableCenter.Callback = {@ne_setoption, 'ctablelupcrd', 'center'};
tags.UIM_NeuroElf_CTableCOG.Callback = {@ne_setoption, 'ctablelupcrd', 'cog'};
tags.UIM_NeuroElf_CTableSCSizes.Callback = {@ne_setoption, 'ctablescsizes'};
tags.UIM_NeuroElf_CTableSortMax.Callback = {@ne_setoption, 'ctablesort', 'maxstat'};
tags.UIM_NeuroElf_CTableSortMaxS.Callback = {@ne_setoption, 'ctablesort', 'maxstats'};
tags.UIM_NeuroElf_CTableSortSize.Callback = {@ne_setoption, 'ctablesort', 'size'};
tags.UIM_NeuroElf_CTableSortX.Callback = {@ne_setoption, 'ctablesort', 'x'};
tags.UIM_NeuroElf_CTableSortY.Callback = {@ne_setoption, 'ctablesort', 'y'};
tags.UIM_NeuroElf_CTableSortZ.Callback = {@ne_setoption, 'ctablesort', 'z'};

% file -> options -> drawing
tags.UIM_NeuroElf_DOnMouse.Callback = {@ne_setoption, 'drawon', 'Mouse'};
tags.UIM_NeuroElf_DOnCursor.Callback = {@ne_setoption, 'drawon', 'Cursor'};
tags.UIM_NeuroElf_DOnPosition.Callback = {@ne_setoption, 'drawon', 'Position'};
tags.UIM_NeuroElf_DOnSatellite.Callback = {@ne_setoption, 'drawon', 'Satellite'};
tags.UIM_NeuroElf_DOnLinked.Callback = {@ne_setoption, 'drawon', 'Linked'};

% file -> options -> remote listener
tags.UIM_NeuroElf_ListenerStart.Callback = {@ne_remote, 'listen'};
tags.UIM_NeuroElf_ListenerStop.Callback = {@ne_remote, 'unlisten'};

% file -> options -> neurological/radiological orientation
tags.UIM_NeuroElf_OrientNeuro.Callback = {@ne_setoption, 'orientation', 'n'};
tags.UIM_NeuroElf_OrientRadio.Callback = {@ne_setoption, 'orientation', 'r'};

% file -> options -> MKDA/PLP lookup
tags.UIM_NeuroElf_PLPLUCursor.Callback = {@ne_setoption, 'mkda', 'lookuponcursor'};
tags.UIM_NeuroElf_PLPLUCluster.Callback = {@ne_setoption, 'mkda', 'lookuponcluster'};

% file -> options -> renderer
tags.UIM_NeuroElf_RendOpenGL.Callback = {@ne_setoption, 'renderer', 'OpenGL'};
tags.UIM_NeuroElf_Rendzbuffer.Callback = {@ne_setoption, 'renderer', 'zbuffer'};

% file -> options -> spatial normalization
tags.UIM_NeuroElf_SPMsnloadslv.Callback = {@ne_setoption, 'spmsn', 'SliceVar'};
tags.UIM_NeuroElf_SPMsnli2tslv.Callback = {@ne_setoption, 'spmsn', 'SliceVar', spmsni2t};
tags.UIM_NeuroElf_SPMsnlt2islv.Callback = {@ne_setoption, 'spmsn', 'SliceVar', spmsnt2i};
tags.UIM_NeuroElf_SPMsnunldslv.Callback = {@ne_setoption, 'spmsn', 'SliceVar', 'null'};
tags.UIM_NeuroElf_SPMsnloadstv.Callback = {@ne_setoption, 'spmsn', 'StatsVar'};
tags.UIM_NeuroElf_SPMsnli2tstv.Callback = {@ne_setoption, 'spmsn', 'StatsVar', spmsni2t};
tags.UIM_NeuroElf_SPMsnlt2istv.Callback = {@ne_setoption, 'spmsn', 'StatsVar', spmsnt2i};
tags.UIM_NeuroElf_SPMsnunldstv.Callback = {@ne_setoption, 'spmsn', 'StatsVar', 'null'};

% file -> options -> surface options
tags.UIM_NeuroElf_SOBackColor.Callback = {@ne_setoption, 'surfbgcol'};
tags.UIM_NeuroElf_SORecoColors.Callback = {@ne_setoption, 'surfrecocol'};
tags.UIM_NeuroElf_SORecoOneSurf.Callback = {@ne_setoption, 'surfrecoonesurf'};
tags.UIM_NeuroElf_SOReco4TPS.Callback = {@ne_setoption, 'surfreco4tps'};
tags.UIM_NeuroElf_SOReuseXSMMapping.Callback = {@ne_setoption, 'surfreusexsm'};

% file -> options -> LUTs
tags.UIM_NeuroElf_GLUT_bw.Callback = {@ne_setoption, 'graylut', 'bw'};
tags.UIM_NeuroElf_GLUT_wb.Callback = {@ne_setoption, 'graylut', 'wb'};
tags.UIM_NeuroElf_GLUT_bwb.Callback = {@ne_setoption, 'graylut', 'bwb'};
tags.UIM_NeuroElf_GLUT_bwbwb.Callback = {@ne_setoption, 'graylut', 'bwbwb'};
tags.UIM_NeuroElf_GLUT_wbw.Callback = {@ne_setoption, 'graylut', 'wbw'};
tags.UIM_NeuroElf_GLUT_color.Callback = {@ne_setoption, 'graylut', 'color'};
tags.UIM_NeuroElf_LUTEdit.Callback = @ne_lut_edit;

% file -> options -> underlay
tags.UIM_NeuroElf_ULayBlendOLay.Callback = {@ne_setoption, 'joinulay', 6};
tags.UIM_NeuroElf_ULayBlendOLayF.Callback = {@ne_setoption, 'joinulay', 5};
tags.UIM_NeuroElf_ULayBlendOLayW.Callback = {@ne_setoption, 'joinulay', 4};
tags.UIM_NeuroElf_ULayBlendMix.Callback = {@ne_setoption, 'joinulay', 3};
tags.UIM_NeuroElf_ULayBlendULayW.Callback = {@ne_setoption, 'joinulay', 2};
tags.UIM_NeuroElf_ULayBlendULayF.Callback = {@ne_setoption, 'joinulay', 1};
tags.UIM_NeuroElf_ULayBlendULay.Callback = {@ne_setoption, 'joinulay', 0};

% file -> options -> remaining
tags.UIM_NeuroElf_VMRRes05.Callback = {@ne_setoption, 'newvmrres', 'res05'};
tags.UIM_NeuroElf_ExtMapNames.Callback = {@ne_setoption, 'extmapnames'};
tags.UIM_NeuroElf_LinkedBrowse.Callback = @ne_togglelinked;
tags.UIM_NeuroElf_ShowThreshBars.Callback = {@ne_setoption, 'showthreshbars'};
tags.UIM_NeuroElf_EchoCalls.Callback = {@ne_setoption, 'echocalls'};
tags.UIM_NeuroElf_CloseUI.Callback = @ne_closewindow;

% FMR menu
tags.UIM_NeuroElf_FMRTCMovie.Callback = @ne_tcmovie;
tags.UIM_NeuroElf_FMRExportNII.Callback = {@ne_exportnii, 'SliceVar'};

% VMR menu
tags.UIM_NeuroElf_VMRDBReco.Callback = @ne_vmr_dbreco;
tags.UIM_NeuroElf_VMRDBRecoSPH.Callback = {@ne_srf_tools, 'recosmsph'};
tags.UIM_NeuroElf_VMRCleanVMR.Callback = @ne_vmr_clean;
tags.UIM_NeuroElf_VMRInhomogen.Callback = @ne_vmr_ihc;
tags.UIM_NeuroElf_VMRPeelBrain.Callback = @ne_vmr_peelbrain;
tags.UIM_NeuroElf_VMRLimitVMR.Callback = @ne_vmr_limitvmr;
tags.UIM_NeuroElf_VMRHiResResc.Callback = @ne_vmr_hiresrescale;
tags.UIM_NeuroElf_VMRSmoothData.Callback = {@ne_setdrawmode, [], -6};
tags.UIM_NeuroElf_VMRExportNII.Callback = {@ne_exportnii, 'SliceVar'};
tags.UIM_NeuroElf_VMRExportRGB.Callback = @ne_vmr_exportrgb;

% VTC menu
tags.UIM_NeuroElf_VTCTCMovie.Callback = @ne_tcmovie;
tags.UIM_NeuroElf_VTCMeanStd.Callback = @ne_vtc_meanstdvmp;
tags.UIM_NeuroElf_VTCMaskWithVMR.Callback = {@ne_maskstatswithvmr, 'vtc'};
tags.UIM_NeuroElf_VTCExportNII.Callback = {@ne_exportnii, 'SliceVar'};

% GLM menu
tags.UIM_NeuroElf_GLMBetaPlot.Callback = @ne_glmplotbetas;
tags.UIM_NeuroElf_GLMGenerateMDM.Callback = @ne_glmgeneratemdm;
tags.UIM_NeuroElf_GLMMaskWithVMR.Callback = @ne_maskstatswithvmr;
tags.UIM_NeuroElf_GLMThreshMaps.Callback = @ne_vmp_threshmaps;
tags.UIM_NeuroElf_GLMExportNII.Callback = {@ne_exportnii, 'StatsVar'};
tags.UIM_NeuroElf_GLMSelXConds.Callback = {@ne_setoption, 'GLMXConds'};

% VMP menu
tags.UIM_NeuroElf_VMPApplyFDR.Callback = @ne_vmp_applyfdr;
tags.UIM_NeuroElf_VMPOPTRawThresh.Callback = {@ne_setoption, 'vmpusefdr', 'raw'};
tags.UIM_NeuroElf_VMPOPTFDRIndPos.Callback = {@ne_setoption, 'vmpusefdr', 'indpos'};
tags.UIM_NeuroElf_VMPOPTFDRNonPar.Callback = {@ne_setoption, 'vmpusefdr', 'nonpar'};
tags.UIM_NeuroElf_VMPSVCVOI.Callback = {@ne_vmp_applysvc, 'voi'};
tags.UIM_NeuroElf_VMPSVCMask.Callback = @ne_vmp_applysvc;
tags.UIM_NeuroElf_VMPSVCVMR.Callback = {@ne_vmp_applysvc, 'vmr'};
tags.UIM_NeuroElf_VMPSVCColin.Callback = {@ne_vmp_applysvc, [neuroelf_path('colin') '/colin_brain_ICBMnorm.vmr']};
tags.UIM_NeuroElf_VMPCombine.Callback = @ne_vmp_combine;
tags.UIM_NeuroElf_VMPCompFormula.Callback = @ne_setcstatmapformula;
tags.UIM_NeuroElf_VMPCreateMSK.Callback = @ne_vmp_createmsk;
tags.UIM_NeuroElf_VMPCreateSMP.Callback = @ne_vmp_createsmp;
tags.UIM_NeuroElf_VMPWriteAna.Callback = @ne_vmp_writeana;
tags.UIM_NeuroElf_VMPMaskWithVMR.Callback = @ne_maskstatswithvmr;
tags.UIM_NeuroElf_VMPMaskWithCls.Callback = @ne_maskstatswithcls;
tags.UIM_NeuroElf_VMPSmoothMaps.Callback = @ne_smoothstats;
tags.UIM_NeuroElf_VMPThreshMaps.Callback = @ne_vmp_threshmaps;
tags.UIM_NeuroElf_VMPExportNII.Callback = {@ne_exportnii, 'StatsVar'};
tags.UIM_NeuroElf_VMPBetaPlot.Callback = @ne_vmpplotbetas;

% SRF menu
tags.UIM_NeuroElf_SRFSave.Callback = @ne_srf_save;
tags.UIM_NeuroElf_SRFSaveAs.Callback = {@ne_srf_save, 'saveas'};
tags.UIM_NeuroElf_SRFClone.Callback = {@ne_srf_tools, 'clone'};
tags.UIM_NeuroElf_SRFClusterSRF.Callback = {@ne_srf_tools, 'clustersrf'};
tags.UIM_NeuroElf_SRFNewSphere.Callback = {@ne_srf_tools, 'createsphere'};
tags.UIM_NeuroElf_SRFReload.Callback = @ne_srf_reload;
tags.UIM_NeuroElf_SRFMorphToS.Callback = {@ne_srf_tools, 'findintensity'};
tags.UIM_NeuroElf_SRFMorphTo.Callback = {@ne_srf_tools, 'findintensity', [], 'nospherecheck'};
tags.UIM_NeuroElf_SRFGMorph.Callback = {@ne_srf_tools, 'morph'};
tags.UIM_NeuroElf_SRFSmooth.Callback = {@ne_srf_tools, 'smooth'};
tags.UIM_NeuroElf_SRFInflate.Callback = {@ne_srf_tools, 'inflate'};
tags.UIM_NeuroElf_SRFSphere.Callback = {@ne_srf_tools, 'tosphere'};
tags.UIM_NeuroElf_SRFMapToIco.Callback = {@ne_srf_tools, 'maptoico'};
tags.UIM_NeuroElf_SRFCurvSMP.Callback = {@ne_srf_tools, 'curvsmp'};
tags.UIM_NeuroElf_SRFDensSMP.Callback = {@ne_srf_tools, 'denssmp'};
tags.UIM_NeuroElf_SRFSetColors.Callback = {@ne_srf_tools, 'setcolors'};
tags.UIM_NeuroElf_SRFSetMorphT.Callback = {@ne_srf_tools, 'setmorphtarget'};
tags.UIM_NeuroElf_SRFPrintInfo.Callback = {@ne_srf_tools, 'srfinfo'};
tags.UIM_NeuroElf_SRFLeftView.Callback = {@ne_setsurfpos, '', {180, 0, [0, 0]}};
tags.UIM_NeuroElf_SRFRightView.Callback = {@ne_setsurfpos, '', {0, 0, [0, 0]}};
tags.UIM_NeuroElf_SRFFrontView.Callback = {@ne_setsurfpos, '', {90, 0, [0, 0]}};
tags.UIM_NeuroElf_SRFOcciView.Callback = {@ne_setsurfpos, '', {270, 0, [0, 0]}};
tags.UIM_NeuroElf_SRFSuperView.Callback = {@ne_setsurfpos, '', {270, 90, [0, 0]}};
tags.UIM_NeuroElf_SRFInferView.Callback = {@ne_setsurfpos, '', {90, -90, [0, 0]}};

% SMP menu
tags.UIM_NeuroElf_SMPSave.Callback = @ne_smp_save;
tags.UIM_NeuroElf_SMPSaveAs.Callback = {@ne_smp_save, 'saveas'};
tags.UIM_NeuroElf_SMPCombine.Callback = @ne_smp_combine;
tags.UIM_NeuroElf_SMPCompFormula.Callback = {@ne_srf_tools, 'smpformula'};
tags.UIM_NeuroElf_SMPSmooth.Callback = {@ne_srf_tools, 'smoothsmp'};

% HDR menu
tags.UIM_NeuroElf_HDRTCMovie.Callback = @ne_tcmovie;
tags.UIM_NeuroElf_HDRSegmentHead.Callback = @ne_hdr_segment;
tags.UIM_NeuroElf_HDRObliqueSlc.Callback = @ne_hdr_obliqueslices;
tags.UIM_NeuroElf_HDRDTI3p2pMC.Callback = {@ne_hdr_dti, 'motcorr'};
tags.UIM_NeuroElf_HDRDTIDTCalc.Callback = {@ne_hdr_dti, 'dtcalc'};
tags.UIM_NeuroElf_HDRDTIFlipBVX.Callback = {@ne_hdr_dti, 'flipbvecs', 'x'};
tags.UIM_NeuroElf_HDRDTIFlipBVY.Callback = {@ne_hdr_dti, 'flipbvecs', 'y'};
tags.UIM_NeuroElf_HDRDTIFlipBVZ.Callback = {@ne_hdr_dti, 'flipbvecs', 'z'};
tags.UIM_NeuroElf_HDRDTIFibTrack.Callback = {@ne_hdr_dti, 'trackfibers'};

% Stats menu (visible only in small state, content completely dynamic)
tags.UIM_NeuroElf_STATS.Callback = @ne_statsmenu;

% Analysis menu
tags.UIM_NeuroElf_runmdm.Callback = @ne_mdm_open;
tags.UIM_NeuroElf_contrasts.Callback = @ne_cm_open;
tags.UIM_NeuroElf_fcprepro.Callback = @ne_fcprepro;
tags.UIM_NeuroElf_rfxmediation.Callback = @ne_rm_open;
tags.UIM_NeuroElf_gsrp2p.Callback = {@ne_physio, 'gsr'};
tags.UIM_NeuroElf_hrv.Callback = {@ne_physio, 'ecg'};
tags.UIM_NeuroElf_MKDA.Callback = @ne_mkda;

% Drawing menu
tags.UIM_NeuroElf_DrawHistMark.Callback = @ne_draw_histmarked;
tags.UIM_NeuroElf_DrawLoadUBuff.Callback = @ne_draw_loadubuff;
tags.UIM_NeuroElf_DrawSmpULay.Callback = {@ne_setdrawmode, [], -2.5};

% Visualization menu
tags.UIM_NeuroElf_VisMontage.Callback = @ne_vismontage;
tags.UIM_NeuroElf_Render.Callback = @ne_render;
tags.UIM_NeuroElf_VOICondAvg.Callback = @ne_mdmvoicondavg;
tags.UIM_NeuroElf_VOICondAvgLoad.Callback = {@ne_mdmvoicondavg, 'reload'};
tags.UIM_NeuroElf_DTIPlotFib.Callback = {@ne_hdr_dti, 'plotfibers'};

% VOI menu (visible only in small state, content completely dynamic)
tags.UIM_NeuroElf_VOI.Callback = @ne_voimenu;

% Tools menus
tags.UIM_NeuroElf_SPM2PRT.Callback = @ne_spmmat2prt;
tags.UIM_NeuroElf_SPM2SDM.Callback = @ne_spmmat2sdm;
tags.UIM_NeuroElf_alphasim.Callback = @ne_alphasim;
tags.UIM_NeuroElf_averagenii.Callback = @ne_averagenii;
tags.UIM_NeuroElf_renamedicom.Callback = @ne_renamedicom;
tags.UIM_NeuroElf_spmx_prepro.Callback = @ne_spmxprepro;
tags.UIM_NeuroElf_fmriquality.Callback = @ne_fmriquality;
tags.UIM_NeuroElf_QCVTC.Callback = @ne_mdmqcvtc;
tags.UIM_NeuroElf_QCglobtc.Callback = @ne_mdmqcglobtc;
tags.UIM_NeuroElf_visspmrp.Callback = @ne_visspmrp;
tags.UIM_NeuroElf_about.Callback = @ne_about;

% slice and surface object selection
tags.DD_NeuroElf_varlist.Callback = @ne_setcvar;
tags.DD_NeuroElf_varlistsrf.Callback = @ne_setcsrf;
tags.BT_NeuroElf_slvartrf.Callback = {@ne_setvartrf, 'SliceVar'};
tags.BT_NeuroElf_surfvartrf.Callback = {@ne_setvartrf, 'SurfVar'};
tags.BT_NeuroElf_varclose.Callback = {@ne_closefile, 'SliceVar'};
tags.BT_NeuroElf_varclosesrf.Callback = {@ne_closefile, 'SurfVar'};
tags.DD_NeuroElf_statlist.Callback = @ne_setcstats;
tags.DD_NeuroElf_statlistsrf.Callback = @ne_setcsrfstats;
tags.DD_NeuroElf_statsref.Callback = ...
    {@ne_openreffile, 'StatsVarRefs', 'SliceVar'};
tags.DD_NeuroElf_statsrefsrf.Callback = ...
    {@ne_openreffile, 'SurfStatsVarRefs', 'SurfVar'};
tags.BT_NeuroElf_stvartrf.Callback = {@ne_setvartrf, 'StatsVar'};
tags.BT_NeuroElf_statclose.Callback = {@ne_closefile, 'StatsVar'};
tags.BT_NeuroElf_statclossrf.Callback = {@ne_closefile, 'SurfStatsVar'};
tags.BT_NeuroElf_statsrefreg.Callback = @ne_setslicepos;
tags.BT_NeuroElf_statsrefixx.Callback = @ne_setslicepos;
tags.LB_NeuroElf_statmaps.Callback = @ne_setcstatmap;
tags.LB_NeuroElf_statmapssrf.Callback = @ne_setcsrfstatmap;

% stats map buttons
tags.BT_NeuroElf_statmup.Callback = {@ne_movestatmap, -1};
tags.BT_NeuroElf_srfsmup.Callback = {@ne_movestatmap, -1, 'SurfStatsVar'};
tags.BT_NeuroElf_statmdown.Callback = {@ne_movestatmap, 1};
tags.BT_NeuroElf_srfsmdown.Callback = {@ne_movestatmap, 1, 'SurfStatsVar'};
tags.BT_NeuroElf_statprops.Callback = @ne_setcstatmapprops;
tags.BT_NeuroElf_srfsprops.Callback = {@ne_setcstatmapprops, 'SurfStatsVar'};
tags.BT_NeuroElf_statmdel.Callback = {@ne_movestatmap, 0};
tags.BT_NeuroElf_statmcsmp.Callback = {@ne_vmp_createsmp, 'StatsVar', 'cursel'};
tags.BT_NeuroElf_statbars.Callback = @ne_vmpplotbetas;
tags.BT_NeuroElf_srfsmdel.Callback = {@ne_movestatmap, 0, 'SurfStatsVar'};
tags.BT_NeuroElf_statmcfrm.Callback = @ne_setcstatmapformula;
tags.BT_NeuroElf_statmproj.Callback = @ne_setcstatmapproj;

% cluster list
tags.LB_NeuroElf_clusters.Callback = {@ne_setcluster, 'set'};
tags.BT_NeuroElf_clustmark.Callback = @ne_markclusters;
tags.BT_NeuroElf_clustsph.Callback = @ne_limitclusters;
tags.BT_NeuroElf_clustatl.Callback = @ne_addatlascluster;
tags.BT_NeuroElf_clustgoto.Callback = {@ne_setcluster, 'nearest'};
tags.BT_NeuroElf_clustzoom.Callback = {@ne_setcluster, 'set'};
tags.BT_NeuroElf_clustprop.Callback = {@ne_setcluster, 'prop'};
tags.BT_NeuroElf_clustmdel.Callback = @ne_delcluster;
tags.BT_NeuroElf_clustload.Callback = @ne_loadcluster;
tags.BT_NeuroElf_clustsave.Callback = @ne_savecluster;
tags.BT_NeuroElf_clustbet.Callback = @ne_extcluster;

% drawing tools
tags.BT_NeuroElf_draw0.Callback = {@ne_setdrawmode, 1};
tags.BT_NeuroElf_draw2d.Callback = {@ne_setdrawmode, 2};
tags.BT_NeuroElf_draw3d.Callback = {@ne_setdrawmode, 3};
tags.BT_NeuroElf_flood3.Callback = {@ne_setdrawmode, [], -3};
tags.BT_NeuroElf_expand3.Callback = {@ne_setdrawmode, [], -4};
tags.BT_NeuroElf_smoothana.Callback = {@ne_setdrawmode, [], -6};
tags.BT_NeuroElf_smoothseg.Callback = {@ne_setdrawmode, [], -5};
tags.BT_NeuroElf_drawu.Callback = {@ne_setdrawmode, -1};
tags.BT_NeuroElf_drawok.Callback = {@ne_setdrawmode, [], 1};
tags.BT_NeuroElf_drawback.Callback = {@ne_setdrawmode, [], -1};
tags.BT_NeuroElf_drawreld.Callback = {@ne_setdrawmode, [], -2};
tags.BT_NeuroElf_drawmask.Callback = {@ne_setdrawmode, [], 0};
tags.BT_NeuroElf_drawimask.Callback = {@ne_setdrawmode, [], 0.5};
tags.BT_NeuroElf_mark2roi.Callback = {@ne_addcluster, 'ana'};
tags.BT_NeuroElf_setulay.Callback = @ne_setunderlay;
tags.BT_NeuroElf_showv16.Callback = {@ne_setoption, 'showv16'};

% surface tools
tags.BT_NeuroElf_newsphere.Callback = {@ne_srf_tools, 'createsphere'};
tags.BT_NeuroElf_headmesh.Callback = {@ne_srf_tools, 'findintensity'};
tags.BT_NeuroElf_morphto.Callback = {@ne_srf_tools, 'findintensity', [], 'nospherecheck'};
tags.BT_NeuroElf_smoothsrf.Callback = {@ne_srf_tools, 'smooth'};
tags.BT_NeuroElf_inflatesrf.Callback = {@ne_srf_tools, 'inflate'};
tags.BT_NeuroElf_tospheresrf.Callback = {@ne_srf_tools, 'tosphere'};
tags.BT_NeuroElf_maptoico.Callback = {@ne_srf_tools, 'maptoico'};
tags.BT_NeuroElf_stopmorph.Callback = {@ne_srf_tools, 'cancelmorph'};
tags.BT_NeuroElf_srfundomrp.Callback = {@ne_srf_tools, 'undomorph'};
tags.BT_NeuroElf_srfreload.Callback = @ne_srf_reload;
tags.BT_NeuroElf_srfsave.Callback = @ne_srf_save;
tags.BT_NeuroElf_backprojsrf.Callback = {@ne_srf_tools, 'backproject'};
tags.BT_NeuroElf_smoothsmp.Callback = {@ne_srf_tools, 'smoothsmp'};
tags.BT_NeuroElf_srfmcfrm.Callback = {@ne_srf_tools, 'smpformula'};
tags.BT_NeuroElf_srfcolors.Callback = {@ne_srf_tools, 'setcolors'};
tags.BT_NeuroElf_srfinfo.Callback = {@ne_srf_tools, 'srfinfo'};

% view and UI configuration tools
tags.BT_NeuroElf_undock.Callback = @ne_undock;
tags.BT_NeuroElf_togglelink.Callback = @ne_togglelinked;
tags.BT_NeuroElf_viewsct.Callback = {@ne_setview, 1, 0};
tags.BT_NeuroElf_viewsag.Callback = {@ne_setview, 2, 1};
tags.BT_NeuroElf_viewcor.Callback = {@ne_setview, 2, 2};
tags.BT_NeuroElf_viewtra.Callback = {@ne_setview, 2, 3};
tags.BT_NeuroElf_viewtrf.Callback = {@ne_setview, 0, 0};
tags.BT_NeuroElf_viewsrf.Callback = {@ne_setview, 3, 0};
tags.BT_NeuroElf_render.Callback = @ne_render;
tags.BT_NeuroElf_minimize.Callback = {@ne_swapfullsize, 'swap'};
tags.BT_NeuroElf_maximize.Callback = {@ne_swapfullsize, 'swap'};
tags.BT_NeuroElf_setscalewin.Callback = {@ne_setoption, 'scalingwindow'};

% coordinate selection (text boxes)
tags.ED_NeuroElf_TALX.Callback = @ne_setwindowpos;
tags.ED_NeuroElf_TALX.KeyPressFcn = {@ne_keypress_uic, 0, @ne_setwindowpos};
tags.ED_NeuroElf_TALY.Callback = @ne_setwindowpos;
tags.ED_NeuroElf_TALY.KeyPressFcn = {@ne_keypress_uic, 0, @ne_setwindowpos};
tags.ED_NeuroElf_TALZ.Callback = @ne_setwindowpos;
tags.ED_NeuroElf_TALZ.KeyPressFcn = {@ne_keypress_uic, 0, @ne_setwindowpos};
tags.ED_NeuroElf_BVSX.Callback = @ne_setwindowpos;
tags.ED_NeuroElf_BVSX.KeyPressFcn = {@ne_keypress_uic, 0, @ne_setwindowpos};
tags.ED_NeuroElf_BVSY.Callback = @ne_setwindowpos;
tags.ED_NeuroElf_BVSY.KeyPressFcn = {@ne_keypress_uic, 0, @ne_setwindowpos};
tags.ED_NeuroElf_BVSZ.Callback = @ne_setwindowpos;
tags.ED_NeuroElf_BVSZ.KeyPressFcn = {@ne_keypress_uic, 0, @ne_setwindowpos};
tags.SL_NeuroElf_TempPos.Callback = @ne_setslicepos;

% stats configuration (thresholding, colors, etc.)
tags.ED_NeuroElf_LowerThresh.Callback = @ne_setstatthr;
tags.ED_NeuroElf_UpperThresh.Callback = @ne_setstatthr;
tags.DD_NeuroElf_StatSetP.Callback = @ne_setstatthrpval;
tags.CB_NeuroElf_PositivStat.Callback = @ne_setstatthrtails;
tags.CB_NeuroElf_NegativStat.Callback = @ne_setstatthrtails;
tags.ED_NeuroElf_kExtThresh.Callback = @ne_setstatthrccheck;
tags.CB_NeuroElf_kExtThresh.Callback = @ne_setstatthrccheck;
tags.BT_NeuroElf_alphasim.Callback = @ne_alphasim;
tags.BT_NeuroElf_ClusterTable.Callback = @ne_clustertable;
tags.CB_NeuroElf_SplitMaxima.Callback = @ne_setstatsplitc;
tags.CB_NeuroElf_Interpolate.Callback = @ne_setslicepos;
tags.RB_NeuroElf_LUTColor.Callback = {@ne_setstatthrcolor, 'LUT'};
tags.RB_NeuroElf_RGBColor.Callback = {@ne_setstatthrcolor, 'RGB'};
tags.BT_NeuroElf_RGBLowPos.Callback = {@ne_setrgbcolor, '+'};
tags.BT_NeuroElf_RGBUppPos.Callback = {@ne_setrgbcolor, '++'};
tags.BT_NeuroElf_RGBLowNeg.Callback = {@ne_setrgbcolor, '-'};
tags.BT_NeuroElf_RGBUppNeg.Callback = {@ne_setrgbcolor, '--'};
tags.ED_NeuroElf_SrfLowerThr.Callback = @ne_updatesmpprops;
tags.ED_NeuroElf_SrfUpperThr.Callback = @ne_updatesmpprops;
tags.ED_NeuroElf_SrfkExtThr.Callback = @ne_updatesmpprops;
tags.CB_NeuroElf_SrfkExtThr.Callback = @ne_updatesmpprops;
tags.CB_NeuroElf_SrfPosStat.Callback = @ne_updatesmpprops;
tags.CB_NeuroElf_SrfNegStat.Callback = @ne_updatesmpprops;
tags.DD_NeuroElf_SrfStatSetP.Callback = {@ne_updatesmpprops, 'pval'};
tags.BT_NeuroElf_SrfClusterT.Callback = {@ne_clustertable, 'smp'};
tags.RB_NeuroElf_SrfLUTColor.Callback = {@ne_setstatthrcolor, 'LUT', 'smp'};
tags.RB_NeuroElf_SrfRGBColor.Callback = {@ne_setstatthrcolor, 'RGB', 'smp'};
tags.BT_NeuroElf_SrfRGBLPos.Callback = {@ne_setrgbcolor, '+', 'smp'};
tags.BT_NeuroElf_SrfRGBUPos.Callback = {@ne_setrgbcolor, '++', 'smp'};
tags.BT_NeuroElf_SrfRGBLNeg.Callback = {@ne_setrgbcolor, '-', 'smp'};
tags.BT_NeuroElf_SrfRGBUNeg.Callback = {@ne_setrgbcolor, '--', 'smp'};

% scenery controls
tags.BT_NeuroElf_SceneOrtho.Callback = {@ne_setsceneproj, 'orthographic'};
tags.BT_NeuroElf_ScenePersp.Callback = {@ne_setsceneproj, 'perspective'};
tags.LB_NeuroElf_Scenery.Callback = {@ne_setsurfpos, 1};
tags.BT_NeuroElf_SceneProps.Callback = @ne_setsceneprops;
tags.BT_NeuroElf_SceneRemove.Callback = {@ne_srf_tools, 'closefiles'};
tags.BT_NeuroElf_SceneLoad.Callback = {@ne_srf_tools, 'loadscenery'};
tags.BT_NeuroElf_SceneSave.Callback = {@ne_srf_tools, 'savescenery'};

% remote button
tags.BT_NeuroElf_RListener.Callback = {@ne_remote, 'listen'};

% main UI Fcn callbacks
MainFig.CloseRequestFcn = @ne_closewindow;
MainFig.KeyPressFcn = @ne_keypress;
MainFig.KeyReleaseFcn = @ne_keyrelease;
MainFig.WindowButtonDownFcn = @ne_btdown;
MainFig.WindowButtonMotionFcn = @ne_btmove;
MainFig.WindowButtonUpFcn = @ne_btup;

% set initial groups en/disabled/visible state
disp(' - finalizing UI configuration...');
pause(0.001);

% disable OpenGL hardware support on Windows?
if strcmpi(fcfg.renderer, 'opengl')
    if ispc && ...
        ne_gcfg.c.ini.Surface.OpenGLHWAccelOnWindows ~= 1
        try
            opengl('software', true);
        catch ne_eo;
            ne_gcfg.c.lasterr = ne_eo;
            warning( ...
                'neuroelf:OpenGLError', ...
                'Error setting OpenGL to SoftwareAcceleration for PCs.' ...
            );
            fcfg.renderer = 'zbuffer';
        end
    end
end

% set group states
MainFig.SetGroupEnabled('SLoaded', 'off');
MainFig.SetGroupEnabled('SLdNVMP', 'off');
MainFig.SetGroupVisible('FMRMenu', 'off');
MainFig.SetGroupVisible('GLMMenu', 'off');
MainFig.SetGroupVisible('VMPMenu', 'off');
MainFig.SetGroupVisible('VMRMenu', 'off');
MainFig.SetGroupVisible('VTCMenu', 'off');
MainFig.SetGroupVisible('SRFMenu', 'off');
MainFig.SetGroupVisible('SMPMenu', 'off');
MainFig.SetGroupVisible('HDRMenu', 'off');
MainFig.SetGroupEnabled('SLdNSMP', 'off');

% set back to global structure
ne_gcfg.fcfg = fcfg;
ne_gcfg.h = ch;

% pre-set button colors
lutc = (1 / 255) * ne_gcfg.lut.Colors;
lutn = size(lutc, 1);
ch.Stats.RGBLPos.BackgroundColor = lutc(1, :);
ch.Stats.RGBUPos.BackgroundColor = lutc(0.5 * lutn, :);
ch.Stats.RGBLNeg.BackgroundColor = lutc(0.5 * lutn + 1, :);
ch.Stats.RGBUNeg.BackgroundColor = lutc(lutn, :);
ch.SrfStats.RGBLPos.BackgroundColor = lutc(1, :);
ch.SrfStats.RGBUPos.BackgroundColor = lutc(0.5 * lutn, :);
ch.SrfStats.RGBLNeg.BackgroundColor = lutc(0.5 * lutn + 1, :);
ch.SrfStats.RGBUNeg.BackgroundColor = lutc(lutn, :);

% set options
disp(' - intializing option settings...');
pause(0.001);
ne_setoption(0, 0, 'ctableadd', c.ini.Statistics.ClusterTableAdd);
ne_setoption(0, 0, 'ctablelupcrd', c.ini.Statistics.LookupCoord);
ne_setoption(0, 0, 'ctablescsizes', fcfg.localmaxsz);
ne_setoption(0, 0, 'ctablesort', fcfg.clsort);
ne_setoption(0, 0, 'drawon', 'Mouse', c.ini.Drawing.OnMouse);
ne_setoption(0, 0, 'drawon', 'Cursor', c.ini.Drawing.OnCursor);
ne_setoption(0, 0, 'drawon', 'Position', c.ini.Drawing.OnPosition);
ne_setoption(0, 0, 'drawon', 'Linked', c.ini.Drawing.OnLinked);
ne_setoption(0, 0, 'echocalls', c.ini.MainFig.EchoCalls);
ne_setoption(0, 0, 'extmapnames', c.ini.Statistics.ExtendedMapNames);
ne_setoption(0, 0, 'extonselect', c.ini.Statistics.ExtractOnSelect);
ne_setoption(0, 0, 'extsepchars', c.ini.Statistics.ExtractSepChars);
ne_setoption(0, 0, 'extwithsids', c.ini.Statistics.ExtractWithSubIDs);
ne_setoption(0, 0, 'joinmd2', c.ini.Statistics.JoinMapsMaxDist);
ne_setoption(0, 0, 'mkda', 'lookuponcursor', c.ini.MKDA.LookupOnCursor);
ne_setoption(0, 0, 'mkda', 'lookuponcluster', c.ini.MKDA.LookupOnCluster);
ne_setoption(0, 0, 'newvmrres', c.ini.MainFig.NewVMRRes);
ne_setoption(0, 0, 'orientation', fcfg.orient, [], false);
ne_setoption(0, 0, 'showthreshbars', c.ini.Statistics.ShowThreshBars, false);
ne_setoption(0, 0, 'surfrecoonesurf', c.ini.Surface.RecoOneSurfaceOnly);
ne_setoption(0, 0, 'surfreco4tps', c.ini.Surface.RecoTriPerVoxelFace == 4);
ne_setoption(0, 0, 'surfreusexsm', c.ini.Surface.RecoOneSurfaceOnly);
ne_setoption(0, 0, 'vmpusefdr', c.ini.Statistics.VMPUseFDR);

% load objects from xff class (includes setcvar, setcstats, etc.)
disp(' - populating available objects dropdowns...');
pause(0.001);
ne_loadobjects(1);

% fill neurosynth menu
ne_neurosynth(0, 0, 'menu');

% show the first page (3-slices view, includes call to setslicepos)
ne_gcfg.fcfg.noupdate = false;
ne_showpage(0, 0, 1);

% size adaptation
ss0 = get(0, 'ScreenSize');
lastsize = c.ini.MainFig.Size;
if ~c.ini.MainFig.FullSize || ...
    any(ss0(3:4) < [1024, 720])
    ne_swapfullsize(0, 0, 'swap');
elseif all(lastsize >= fcfg.fullsize) && ...
    any(lastsize > fcfg.fullsize)
    ne_swapfullsize(0, 0, lastsize);
end

% set to last known position
try
    lastpos = c.ini.MainFig.Position;
    if any(lastpos ~= -1)
        ch.MainFig.Position(1:2) = lastpos;
    end
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
end

% force buttons to correct colors
disp(' - making figure visible...');
pause(0.01);
drawnow;
try
    getframe(ch.MainFigMLH);
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
end

% set correct renderer and make figure visible
ch.Progress.HandleVisibility = 'off';
ch.MainFig.HandleVisibility = 'callback';
set(ch.MainFigMLH, 'Resize', 'on', 'ResizeFcn', @ne_swapfullsize);
ch.MainFig.Visible = 'on';
ne_setoption(0, 0, 'renderer', fcfg.renderer);
ch.Stats.RGBLPos.BackgroundColor = 1 - ch.Stats.RGBLPos.BackgroundColor;
ch.Stats.RGBUPos.BackgroundColor = 1 - ch.Stats.RGBUPos.BackgroundColor;
ch.Stats.RGBLNeg.BackgroundColor = 1 - ch.Stats.RGBLNeg.BackgroundColor;
ch.Stats.RGBUNeg.BackgroundColor = 1 - ch.Stats.RGBUNeg.BackgroundColor;
ch.SrfStats.RGBLPos.BackgroundColor = 1 - ch.SrfStats.RGBLPos.BackgroundColor;
ch.SrfStats.RGBUPos.BackgroundColor = 1 - ch.SrfStats.RGBUPos.BackgroundColor;
ch.SrfStats.RGBLNeg.BackgroundColor = 1 - ch.SrfStats.RGBLNeg.BackgroundColor;
ch.SrfStats.RGBUNeg.BackgroundColor = 1 - ch.SrfStats.RGBUNeg.BackgroundColor;
drawnow;
ch.Stats.RGBLPos.BackgroundColor = 1 - ch.Stats.RGBLPos.BackgroundColor;
ch.Stats.RGBUPos.BackgroundColor = 1 - ch.Stats.RGBUPos.BackgroundColor;
ch.Stats.RGBLNeg.BackgroundColor = 1 - ch.Stats.RGBLNeg.BackgroundColor;
ch.Stats.RGBUNeg.BackgroundColor = 1 - ch.Stats.RGBUNeg.BackgroundColor;
ch.SrfStats.RGBLPos.BackgroundColor = 1 - ch.SrfStats.RGBLPos.BackgroundColor;
ch.SrfStats.RGBUPos.BackgroundColor = 1 - ch.SrfStats.RGBUPos.BackgroundColor;
ch.SrfStats.RGBLNeg.BackgroundColor = 1 - ch.SrfStats.RGBLNeg.BackgroundColor;
ch.SrfStats.RGBUNeg.BackgroundColor = 1 - ch.SrfStats.RGBUNeg.BackgroundColor;
pause(0.01);

% start up remote
if c.ini.Remote.OnStartup
    disp(' - starting remote...');
    ne_remote(0, 0, 'listen');
end

% done
disp('Done.');
