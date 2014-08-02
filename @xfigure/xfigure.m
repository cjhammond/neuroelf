function [varargout] = xfigure(varargin)
% xfigure (Object class)
%
% This class handles MATLAB's UI related stuff with an OO interface.
% Returned
% objects can have a subtype of either
%
%  -> ROOT            (the factory itself, corresponds to MATLAB handle 0)
%  -> Figure          (MATLAB figure objects)
%  -> UIControl       (MATLAB uicontrols objects)
%  -> UIMenu          (MATLAB uimenu objects)
%  -> UIContextMenu   (MATLAB uicontextmenu objects)
%
% The following constructors are available:
%
% xfigure
% xfigure(matlabhandle [, 'delete'])
% xfigure(objecttype, xfighandle)
% xfigure(filename [, options])
% xfigure(objecttag)
%
% For better object access, the struct notation
%
% uiobject.Property
%
% is implemented for both reading/writing.
%
% Note: due to a MATLAB restriction of a maximum length for variable
%       names (31 characters), Tags longer than 27 won't work.
%

% Version:  v0.9d
% Build:    14061514
% Date:     Jun-15 2014, 2:41 PM EST
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

%  INTERNAL INTERFACE SPEC  %
%
% internal object representation
%
% obj.ihnd          internal object handle for find(...) [s.b.]
% obj.mhnd          MATLAB object handle value for fast access
% obj.type          1x1 double value:
%                     0 -> ROOT object
%                     1 -> figure subtype object
%                     2 -> UIControl subtype object
%                     3 -> UIMenu subtype object
%                     4 -> UIContextMenu subtype object

% persistent storage variables
persistent ...
    xfigure_factory ...  % 1x1 struct array, factory settings and storage
    xfigures  ...        % 1xN struct array, xfigure objects
    xfig_ilup ...        % 1xN double array, handle lookup array
    xfig_mlup ...        % 1xN double array, MATLAB handle lookup array
    xfig_type;           % 1xN double array, xfigure object type array

% xfigure_factory   1x1 struct array
%       .I_ROOT         = handle of ROOT object for fast access
%       .dblclickint    = interval needed to be undermined for DblClick's
%       .figbgcolor     = standard background color for figures
%       .is_init        = set to 1 after initialization complete
%       .linkhandler    = how to deal with XLinks
%       .objtypes       = onetime fixed struct with valid xfigure subtypes
%       .oouictype      = UIControls with on/off feature
%       .progbarface    = minumum number of "rounded" bars' grades
%       .rp_init        = MATLAB root object properties at init time
%       .slideswidth    = fixed width in pixels for special slidebars
%       .tags           = lookup struct for tags (max 27 chars!)
%       .uictypes       = onetime fixed struct with valid type names
%       .units          = onetime fixed struct with valid units names
%
% xfigures          1xN struct array
%       .callbacks      = cell array for objects callbacks
%          {1}            Callback / CallbackClick
%          {2}            CallbackClReq
%          {3}            CallbackDblClick
%          {4}            CallbackDelete
%          {5}            CallbackKey
%          {6}            CallbackMDown
%          {7}            CallbackMMove
%          {8}            CallbackMUp
%          {9}            CallbackResize
%       .deletefcn      = original CallbackDelete value (replaced!)
%       .figprops       = struct with sub fields
%          .cpage       = currently shown page for figures [set to -2]
%          .egroups     = SetGroupEnabled groups (with lookup pointers
%                         UIControls: positive/UIMenus: negative doubles)
%          .lgroups     = groups of linked fields for load and update
%          .lilookup    = struct for lookups (max 31 chars!)
%          .linkcont    = FieldLinkCont xini object handles struct
%          .linkspec    = FieldLinkSpec xini object handles array
%          .llookup     = 1x1 struct array for lookups (max 31 chars!)
%          .pages       = list of available pages
%          .rgroups     = RadioGroupSetOne groups (with lookup pointers)
%          .rszuics     = cell array with affected UICs for CallbackResize
%          .sgroups     = SlideGroupXY groups (with lookup pointers)
%          .vgroups     = SetGroupVisible groups (with lookup pointers
%                         UIControls: positive/UIMenus: negative doubles)
%       .loadprops      = struct with input fields at creation time
%       .prevprops      = props stored after executing of last callback
%       .timeclick      = time index of last OnClick event (for DblClick)
%       .uicprops       = struct with extended properties

% internal methods
%
% [handle, type] = findmlparent(handle, type, typestruct)
% newhandle = handlenew(type, given)
% i_loadfield()
% updateok = i_updatefield(hObj, flnk, flt)
% mydelete(MLhandle)
% redrawfig(MLhandle)


% check for class initialization -> do if necessary
if isempty(xfigure_factory) || ...
   ~xfigure_factory.is_init

    % set init state, time and version number
    xfigure_factory.is_init = false;

    % double click internval
    xfigure_factory.dblclickint = 0.8 / 86400;

    % figure background color
    xfigure_factory.figbgcolor = [0.8, 0.8, 0.8];

    % font sizes
    xfigure_factory.fntsizes = struct( ...
        'xsmall', 8, ...
        'small',  9, ...
        'normal', 10, ...
        'large',  12, ...
        'xlarge', 16 ...
    );

    % default handle visibility
    xfigure_factory.hvisible = 'callback';

    % number of progress bar color shades
    xfigure_factory.progbarface = 32;

    % default slider width
    xfigure_factory.slideswidth = 20;

    % support "silent mode"
    xfigure_factory.suppsilent = true;

    % initialise "silent mode" flag
    xfigure_factory.issilent = false;

    % determine runtime features
    ghud = false;
    try
        % turn off property hiding
        if mainver > 6
            hud  = get(0, 'HideUndocumented');
            set(0, 'HideUndocumented', 'off');
            ghud = true;
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end

    % get all properties !
    rootprops = get(0);
    xfigure_factory.rp_init = rootprops;

    % if necessary, turn on hiding again
    if ghud
        set(0, 'HideUndocumented', hud);
    end

    % test objects to see if everything works
    try
        tfig = figure('Visible', 'off');
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        tfig = [];
    end

    % if we even can't open a figure
    if isempty(tfig)
        try
            eval('xfigure_factory(:)=[];');
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
        clear xfigure_factory xfigure;
        error( ...
            'xfigure:FiguresUnavailable', ...
            'Can''t create any figures with this setup.' ...
        );
    end

    % get valid papertype options and clean up object
    if mainver > 6
        xfigure_factory.figptypes = set(tfig, 'PaperType');
    else
        xfigure_factory.figptypes = {'usletter'};
    end

    % get fontsize factor
    set(tfig, 'Position', [100, 100, 440, 200], 'Visible', 'on');
    try
        tau = uicontrol(tfig, 'Style', 'text', 'Position', [0, 90, 440, 20], ...
            'String', char(48:90), 'FontSize', 10);
        ttxp = get(tau);
        xfigure_factory.fontfact = 165 / ttxp.Extent(3);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        xfigure_factory.fontfact = 0.5;
    end
    tax = axes('Parent', tfig, 'Position', [0, 0, 1, 1]);
    ttxt = text(0.1, 0.5, char(48:90), 'Parent', tax, 'FontSize', 10);
    ttxp = get(ttxt);
    xfigure_factory.fontfact = xfigure_factory.fontfact + 0.375 / ttxp.Extent(3);
    xfigure_factory.fontfactuse = true;
    delete(tfig);

    % property aliases
    xfigure_factory.objtypel = { ...
        'root', ...
        'figure', ...
        'uicontrol', ...
        'uimenu', ...
        'uicontextmenu'  ...
    };
    xfigure_factory.aliases = { ...
        struct, ...
        struct( ...
            'callbackclreq',  'CloseRequestFcn', ...
            'callbackdelete', 'DeleteFcn', ...
            'callbackresize', 'ResizeFcn', ...
            'contextmenu',    'uicontextmenu', ...
            'resizeable',     'Resize', ...
            'title',          'Name' ...
        ), struct( ...
            'caption',        'String', ...
            'color',          'BackgroundColor', ...
            'contextmenu',    'uicontextmenu', ...
            'enabled',        'Enable', ...
            'halign',         'HorizontalAlignment', ...
            'textcolor',      'ForegroundColor', ...
            'tooltip',        'TooltipString', ...
            'top',            'ListboxTop' ...
        ), struct( ...
            'caption',        'Label', ...
            'enabled',        'Enable', ...
            'string',         'Label' ...
        ), struct( ...
            'caption',        'Label', ...
            'enabled',        'Enable', ...
            'string',         'Label' ...
        ) ...
    };

    % type lookup
    xfigure_factory.objtypes = struct(      ...
        'r', 0,           'root',            0, ...
        'f', 1, 'fig', 1, 'figure',          1, ...
        'c', 2, 'uic', 2, 'uicontrol',       2, ...
        'm', 3, 'uim', 3, 'uimenu',          3, ...
        'x', 4, 'uix', 4, 'uicontextmenu',   4  ...
    );

    % type tag prepends and lookup order
    xfigure_factory.objtypet = {'FIG_', 'UIC_', 'UIM_', 'UIX_'};
    xfigure_factory.objtlup  = {'UIC_', 'FIG_', 'UIM_', 'UIX_'};

    % supported xfigure:UIControl types
    xfigure_factory.uictypes = struct( ...
        'blabel',      'BUILTIN',      ...
        'button',      'pushbutton',   ...
        'checkbox',    'checkbox',     ...
        'dropdown',    'popupmenu',    ...
        'edit',        'edit',         ...
        'frame',       'frame',        ...
        'label',       'text',         ...
        'listbox',     'listbox',      ...
        'multiedit',   'edit',         ...
        'popupmenu',   'popupmenu',    ...
        'pushbutton',  'pushbutton',   ...
        'radiobutton', 'radiobutton',  ...
        'slider',      'slider',       ...
        'text',        'text',         ...
        'toggle',      'togglebutton', ...
        'togglebutton','togglebutton', ...
        'xaxes',       'BUILTIN',      ...
        'ximage',      'BUILTIN',      ...
        'xlabel',      'BUILTIN',      ...
        'xlink',       'BUILTIN',      ...
        'xprogress',   'BUILTIN'       ...
    );

    % those with callbacks
    xfigure_factory.oouictypes = struct( ...
        'checkbox',    0, ...
        'edit',        0, ...
        'listbox',     0, ...
        'popupmenu',   0, ...
        'radiobutton', 1, ...
        'toggle',      0  ...
    ); % maybe add 'text' for blabels later ...

    % set valid types for context menu objects
    xfigure_factory.uixtypes = struct ( ...
        'figure',      xfigure_factory.objtypes.figure,    ...
        'uicontrol',   xfigure_factory.objtypes.uicontrol, ...
        'axes',        xfigure_factory.objtypes.uicontrol, ...
        'image',       xfigure_factory.objtypes.uicontrol, ...
        'line',        xfigure_factory.objtypes.uicontrol, ...
        'patch',       xfigure_factory.objtypes.uicontrol, ...
        'rectangle',   xfigure_factory.objtypes.uicontrol, ...
        'text',        xfigure_factory.objtypes.uicontrol  ...
    );

    % set types for extended handle lookup
    xfigure_factory.xobjtypes = struct ( ...
        'axes',        xfigure_factory.objtypes.uicontrol, ...
        'image',       xfigure_factory.objtypes.uicontrol, ...
        'line',        xfigure_factory.objtypes.uicontrol, ...
        'patch',       xfigure_factory.objtypes.uicontrol, ...
        'rectangle',   xfigure_factory.objtypes.uicontrol, ...
        'text',        xfigure_factory.objtypes.uicontrol  ...
    );

    % valid font unit names and option
    xfigure_factory.funits = struct( ...
        'centimeters', 0, ...
        'inches',      0, ...
        'normalized', -1, ...
        'pixels',      1, ...
        'points',      0  ...
    );

    % valid paper unit names and option
    xfigure_factory.punits = struct( ...
        'centimeters', 0, ...
        'inches',      1, ...
        'normalized', -1, ...
        'points',      0  ...
    );

    % valid unit names and option
    xfigure_factory.units = struct( ...
        'centimeters', 0, ...
        'characters',  0, ...
        'inches',      0, ...
        'normalized', -1, ...
        'pixels',      1, ...
        'points',      0  ...
    );

    % valid and default options for figures (for checkstruct)
    xfigure_factory.optfig = { ...
        'BackingStore',    'char',    {'on', 'off'}, 'off'; ...
        'CallbackClReq',   'char',    'expression',  'closereq;'; ...
        'CallbackClick',   'char',    'expression',  ''; ...
        'CallbackDelete',  'char',    'expression',  ''; ...
        'CallbackKey',     'char',    'expression',  ''; ...
        'CallbackMDown',   'char',    'expression',  ''; ...
        'CallbackMMove',   'char',    'expression',  ''; ...
        'CallbackMUp',     'char',    'expression',  ''; ...
        'CallbackResize',  'char',    'expression',  ''; ...
        'Color',           'double',  'noinfnan',    xfigure_factory.figbgcolor; ...
        'ContextMenu',     'char',    'label',       ''; ...
        'DoubleBuffer',    'char',    {'on', 'off'}, 'on'; ...
        'FieldLinkCont',   '',        '',            []; ...
        'FieldLinkSpec',   '',        '',            []; ...
        'Interrupts',      'char',    {'on', 'off'}, 'on'; ...
        'IntegerHandle',   'char',    {'on', 'off'}, 'off'; ...
        'MenuBar',         'char',    {'none', 'figure'}, 'none'; ...
        'MinSize',         'double',  'nonempty',    []; ...
        'Modal',           'char',    {'on', 'off'}, 'off'; ...
        'Page',            'double',  'noinfnan',    []; ...
        'PaperUnits',      'char',    fieldnames(xfigure_factory.punits), 'inches'; ...
        'PaperOrientation','char',    {'portrait', 'landscape', 'rotated'}, 'portrait'; ...
        'PaperPosition',   'double',  'noinfnan',    [0.25, 2.5, 8, 6]; ...
        'PaperSize',       'double',  'noinfnan',    [8.5, 11]; ...
        'PaperType',       'char',    xfigure_factory.figptypes, 'usletter'; ...
        'Position',        'double',  'nonempty',    [0, 0, 300, 200]; ...
        'PrintBW',         'char',    {'on', 'off'}, 'on'; ...
        'Resizeable',      'char',    {'on', 'off'}, 'off'; ...
        'Tag',             'char',    'label',       ''; ...
        'Title',           'char',    'deblank',     ''; ...
        'UserData',        '',        '',            []; ...
        'Units',           'char'     fieldnames(xfigure_factory.units), 'pixels'; ...
        'Visible',         'char',    {'on', 'off'}, 'on' ...
    };

    % valid and default options for uicontrols (for checkstruct)
    xfigure_factory.optuic = { ...
        'Callback',         'char',    'expression',  ''; ...
        'CallbackClick',    'char',    'expression',  ''; ...
        'CallbackDblClick', 'char',    'expression',  ''; ...
        'CallbackDelete',   'char',    'expression',  ''; ...
        'Caption',          '',        '',            ''; ...
        'ColorBG',          'double',  'noinfnan',    []; ...
        'ColorFG',          'double',  'noinfnan',    []; ...
        'ContextMenu',      'char',    'label',       ''; ...
        'EGroups',          'char',    'deblank',     ''; ...
        'Enabled',          'char',    {'on', 'off'}, 'on'; ...
        'FontItalic',       'char',    {'normal', 'italique', 'oblique'}, 'normal'; ...
        'FontName',         'char',    'nonempty',    'default'; ...
        'FontSize',         '',        '',            ...
            10 * xfigure_factory.fontfact; ...
        'FontUnits',        'char',    fieldnames(xfigure_factory.funits), 'points'; ...
        'FontWeight',       'char',    {'light', 'normal', 'demi', 'bold'}, 'normal'; ...
        'HAlign',           'char',    {'left', 'center', 'right'}, 'center'; ...
        'Interrupts',       'char',    {'on', 'off'}, 'on'; ...
        'MinMaxTop',        'double',  'noinfnan',    []; ...
        'Page',             'double',  'noinfnan',    []; ...
        'Position',         'double',  'nonempty',    [0, 0, 1, 1]; ...
        'RGroup',           'char',    'label',       ''; ...
        'ResizeSpec',       'cell',    '',            {}; ...
        'Rotation',         'double',  'noinfnan',    ''; ...
        'SGroups',          'char',    'label',       ''; ...
        'Selectable',       'char',    {'on', 'off'}, 'on'; ...
        'SliderStep',       'double',  'noinfnan',    []; ...
        'Tag',              'char',    'label',       ''; ...
        'ToolTip',          'char',    'deblank',     ''; ...
        'Type',             'char',    'label',       ''; ...
        'UserData',         '',        '',            []; ...
        'Units',            'char'     fieldnames(xfigure_factory.units), 'pixels'; ...
        'VAlign',           'char',    {'top', 'middle', 'bottom'}, 'bottom'; ...
        'VGroups',          'char',    'deblank',     ''; ...
        'Value',            'double',  '',            []; ...
        'Visible',          'char',    {'on', 'off'}, 'on' ...
    };

    % valid and default options for uimenus (for checkstruct)
    xfigure_factory.optuim = { ...
        'Accelerator',     'char',    'nonempty',    ''; ...
        'Callback',        'char',    'expression',  ''; ...
        'CallbackDelete',  'char',    'expression',  ''; ...
        'Caption',         'char',    'nonempty',    ''; ...
        'Checked',         'char',    {'on', 'off'}, 'off'; ...
        'Color',           'double',  'noinfnan',    []; ...
        'EGroups',         'char',    'deblank',     ''; ...
        'Enabled',         'char',    {'on', 'off'}, 'on'; ...
        'Interrupts',      'char',    {'on', 'off'}, 'on'; ...
        'Position',        'double',  'noinfnan',    []; ...
        'Separator',       'char',    {'on', 'off'}, 'off'; ...
        'Tag',             'char',    'label',       ''; ...
        'UserData',        '',        '',            []; ...
        'VGroups',         'char',    'deblank',     ''; ...
        'Visible',         'char',    {'on', 'off'}, 'on' ...
    };

    % valid and default options for uicontextmenus (for checkstruct)
    xfigure_factory.optuix = { ...
        'Callback',        'char',    'expression',  ''; ...
        'CallbackDelete',  'char',    'expression',  ''; ...
        'Interrupts',      'char',    {'on', 'off'}, 'on'; ...
        'Tag',             'char',    'label',       ''; ...
        'UserData',        '',        '',            []  ...
    };

    % display output fields: figure
    xfigure_factory.outfig = struct( ...
        'CallbackClReq',  'CloseRequestFcn', ...
        'CallbackKey',    'KeyPressFcn', ...
        'CallbackMDown',  'WindowButtonDownFcn', ...
        'CallbackMMove',  'WindowButtonMotionFcn', ...
        'CallbackMUp',    'WindowButtonUpFcn', ...
        'CallbackResize', 'ResizeFcn', ...
        'Color',          'Color', ...
        'ContextMenu',    'UIContextMenu', ...
        'NormalOrModal',  'WindowStyle', ...
        'Resizable',      'Resize', ...
        'Title',          'Name', ...
        'UserData',       'UserData', ...
        'Visible',        'Visible');

    % uicontrol
    xfigure_factory.outuic = struct( ...
        'Callback',       'Callback', ...
        'Caption',        'String', ...
        'ContextMenu',    'UIContextMenu', ...
        'Enabled',        'Enable', ...
        'Position',       'Position', ...
        'ToolTip',        'TooltipString', ...
        'Type',           'Style', ...
        'Units',          'Units', ...
        'UserData',       'UserData', ...
        'Value',          'Value', ...
        'Visible',        'Visible');

    % uimenu
    xfigure_factory.outuim = struct( ...
        'Accelerator',    'Accelerator', ...
        'Callback',       'Callback', ...
        'Caption',        'Label', ...
        'Checked',        'Checked', ...
        'Children',       'Children', ...
        'Enabled',        'Enable', ...
        'Separator',      'Separator', ...
        'UserData',       'UserData', ...
        'Visible',        'Visible');

    % uicontextmenu
    xfigure_factory.outuix = struct( ...
        'Callback',       'Callback', ...
        'Children',       'Children', ...
        'UserData',       'UserData', ...
        'Visible',        'Visible');

    % get maximum figure size for each units' name
    if mainver > 6
        unitnames = fieldnames(xfigure_factory.units);
        for ucount = 1:numel(unitnames)
            set(0, 'Units', unitnames{ucount});
            xfigure_factory.units.(unitnames{ucount}) = get(0, 'ScreenSize');
        end
        set(0, 'Units', xfigure_factory.rp_init.Units);
    else
        xfigure_factory.units.pixels = get(0, 'ScreenSize');
    end

    % try to findout what to do with XLinks
    if ispc

        % for Windows we use explorer.exe
        xfigure_factory.linkhandler = {'explorer ',' &'};
    else

        % on unix/linux systems we search for a suitable browser...
        [suczero, sucfound] = system('which mozilla');
        if suczero
            [suczero, sucfound] = system('which netscape');
        end
        if suczero
            [suczero, sucfound] = system('which konqueror');
        end
        if suczero
            sucfound = '';
        end

        % if nothing found, disable link handler
        if isempty(sucfound)
            xfigure_factory.linkhandler=cell(0);

        % otherwise set handler up
        else
            xfigure_factory.linkhandler={[deblank(sucfound) ' '],' &'};
        end
    end

    % class is init now
    xfigure_factory.is_init = true;

    % create ROOT object, type 1 (ROOT)
    I_ROOT = xfigure(0, 'makeobj', 1, 0, xfigure_factory.objtypes.root);
    xfigure_factory.I_ROOT  = I_ROOT;
    xfigure_factory.contextobject = I_ROOT;
    xfigure_factory.tags.I_ROOT = I_ROOT;

    % initialize global variables for figures and lookups
    rootobj = makeostruct(xfigure_factory.objtypes.root);
    rootobj.loadprops = rootprops;
    rootobj.prevprops = rootprops;
    xfigures  = rootobj;
    xfig_ilup = I_ROOT.ihnd;
    xfig_mlup = I_ROOT.mhnd;
    xfig_type = I_ROOT.type;
end

% no or empty first argument
if nargin < 1 || ...
    isempty(varargin{1})
    varargout{1} = xfigure_factory.tags.I_ROOT;
    return;
end

% initialize output arguments
if nargout > 0
    varargout = cell(1, nargout);
end

% for objects
if isa(varargin{1}, 'xfigure') && ...
    numel(varargin{1}) == 1
    hFigure = varargin{1};

% for numeric input
elseif isa(varargin{1}, 'double') && ...
    numel(varargin{1}) == 1 && ...
   ~isinf(varargin{1}) && ...
   ~isnan(varargin{1})

    % call to make an object
    if nargin == 5 && ...
        isequal(varargin{1}, 0) && ...
        isequal(varargin{2}, 'makeobj') && ...
        numel(varargin{3}) == 1 && ...
        isa(varargin{3}, 'double') && ...
        numel(varargin{4}) == 1 && ...
        isa(varargin{4}, 'double') && ...
        numel(varargin{5}) == 1 && ...
        isa(varargin{5}, 'double') && ...
        any(varargin{5} == (0:4))
        varargout{1} = class(struct( ...
            'ihnd', varargin{3}, ...
            'mhnd', varargin{4}, ...
            'type', varargin{5}), 'xfigure');
        return;
    end

    % internal handle lookup first
    myhnd = varargin{1};
    hFigure = [];
    ilup = find(xfig_ilup == myhnd);
    if ~isempty(ilup)

        % handle no longer exists
        if ~ishandle(xfig_mlup(ilup(1)))

            % remove from lookups and internal field
            xfig_ilup(ilup) = [];
            xfig_mlup(ilup) = [];
            xfig_type(ilup) = [];
            xfigures(ilup)  = [];
            varargout{1} = false;
            return;
        end

        % otherwise make object from it
        hFigure =  xfigure(0, 'makeobj', myhnd, xfig_mlup(ilup), xfig_type(ilup));
    end

    % MATLAB handle lookup
    if isempty(ilup)
        ilup = find(xfig_mlup == myhnd);
        if ~isempty(ilup)

            % handle no longer exists
            if ~ishandle(myhnd)

                % remove from lookups and internal field
                xfig_ilup(ilup) = [];
                xfig_mlup(ilup) = [];
                xfig_type(ilup) = [];
                xfigures(ilup)  = [];
                varargout{1} = false;
                return;
            end

            % otherwise make object from it
            hFigure = xfigure(0, 'makeobj', xfig_ilup(ilup), myhnd, xfig_type(ilup));
        end
    end

    % special case -> MATLAB handle, child of xfigure object
    if isempty(ilup) && ...
        ishandle(myhnd)

        % check type first
        myhtype = get(myhnd, 'Type');
        if isfield(xfigure_factory.xobjtypes, myhtype)

            % get UserData
            pv = get(myhnd, 'UserData');

            % if that is a xfigure
            if numel(pv) == 1 && ...
                isxfigure(pv, 1)
                hFigure = pv;

            % numeric ID of xfigure
            elseif isa(pv, 'double') && ...
                numel(pv) == 1 && ...
               ~isnan(pv) && ...
               ~isinf(pv)

                % try lookup of UserData value in internal handles
                ilup = find(xfig_ilup == pv);
                if ~isempty(ilup)
                    hFigure = xfigure(0, 'makeobj', ...
                        pv, xfig_mlup(ilup), xfig_type(ilup));
                end

                % or in MATLAB handles
                if isempty(ilup)
                    mlup = find(xfig_mlup == pv);
                    if ~isempty(mlup)
                        hFigure = xfigure(0, 'makeobj', ...
                            xfig_ilup(mlup), pv, xfig_type(mlup));
                    end
                end

                if isempty(ilup)
                    if nargin > 1 && ...
                        ischar(varargin{2}) && ...
                        strcmpi(varargin{2}(:)', 'delete')
                        try
                            set(pv, 'DeleteFcn', '');
                            delete(pv);
                            varargout{1} = false;
                            return;
                        catch ne_eo;
                            neuroelf_lasterr(ne_eo);
                        end
                        try
                            set(myhnd, 'DeleteFcn', '');
                            delete(myhnd);
                        catch ne_eo;
                            neuroelf_lasterr(ne_eo);
                        end
                        varargout{1} = false;
                        return;
                    end
                end
            end
        end
    end

    % error if lookup failed
    if isempty(hFigure)
        if nargin < 2 || ...
           ~ischar(varargin{2}) || ...
           ~any(strcmpi(varargin{2}(:)', {'delete', 'isvalid'}))
            error( ...
                'xfigure:LookupFailed', ...
                'Lookup of type double failed.' ...
            );
        end
        varargout{1} = false;
        return;
    end

    % second argument type char and == 'delete'
    if nargin > 1 && ...
        ischar(varargin{2}) && ...
        strcmpi(varargin{2}(:)', 'delete')

        % delete all objects found and return
        try
            xfigure(hFigure, 'delete');
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
        return;
    end

    % re-set varargin{1}
    varargin{1} = hFigure;

% char constructor
elseif ischar(varargin{1}) && ...
   ~isempty(varargin{1})

    % is it a file
    tchar = varargin{1}(:)';
    if exist(tchar, 'file') == 2

        % create figure from file then
        try
            myobj = xfigure(xfigure_factory.I_ROOT, ...
                'CreateFigureFromFile', tchar, varargin{2:nargin});
            if ~isxfigure(myobj, 1)
                error('FIGURE_NOT_CREATED');
            end
            varargout{1} = myobj;
            return;
        catch ne_eo;
            error( ...
                'xfigure:FigureCreationFailed', ...
                'Couldn''t create figure from TFG file (%s): %s.', ...
                tchar, ...
                ne_eo.message ...
            );
        end
    end

    % check if its yet a filename
    if any(tchar == filesep | tchar == '.') && ...
       ~isrealvarname(tchar)
        error( ...
            'xfigure:FileNotFound', ...
            'The figure file (%s) was not found or bad varname.', ...
            tchar ...
        );
    end

    % try object lookups in Tag table, iterate over lookup types
    hFigure = [];
    for olc = 1:numel(xfigure_factory.objtlup)
        tTag = [xfigure_factory.objtlup{olc} tchar];

        % is field in tag list
        if isfield(xfigure_factory.tags, tTag)

            % get reference
            hFigure = xfigure_factory.tags.(tTag);
            break;
        end
    end

    % error if lookup failed
    if numel(hFigure) ~= 1 || ...
      ~isxfigure(hFigure, 1)
        error( ...
            'xfigure:LookupFailed', ...
            'Error looking up xfigure object (%s).', ...
            tchar ...
        )
    end

    % set other field and re-set varargin{1}
    varargin{1} = hFigure;

% other input type
else
    error( ...
        'xfigure:BadArgument', ...
        'Invalid input argument class: %s.', ...
        class(varargin{1}) ...
    );
end

% if nothing else to do return
if nargin < 2
    varargout{1} = varargin{1};
    return;
end

% invalid action
if ~ischar(varargin{2}) || ...
    isempty(varargin{2})
    error( ...
        'xfigure:CallingConvention', ...
        'Calling convention misfit.' ...
    );
end

% object field shortcuts
hFigIHnd = hFigure.ihnd;
hFigMHnd = hFigure.mhnd;
hFigType = hFigure.type;

% remainder of arguments
action = lower(varargin{2}(:)');
if nargin > 2
    iStr = varargin{3};
else
    iStr = [];
end

% do initial lookups and fill more internal script vars
% * ihPos  = matrix position for input object
% * ihFPos = matrix position of parent figure
ihPos  = find(xfig_ilup == hFigIHnd);
ihFPos = [];
if isempty(ihPos)
    if strcmp(action, 'isvalid')
        varargout{1} = false;
        return;
    end
    error( ...
        'xfigure:LookupFailed', ...
        'Internal handle disappeared from array. Memory glitch?' ...
    );
end

% * iObj   = object properties as struct
% * iFObj  = object properties of parent figure
iObj       = xfigures(ihPos);
iFObj      = [];

% figure object
switch (hFigType), case {1}
    ihFPos = ihPos;
    iFObj  = iObj;
    mygcf  = hFigMHnd;

% non-root objects
case {2, 3, 4}

    % try to find parent figure
    mygcf  = findmlparent(hFigMHnd, 'figure', xfigure_factory.objtypes);
    ihFPos = find(xfig_mlup == mygcf);
    if isempty(ihFPos)
        error( ...
            'xfigure:LookupFailed', ...
            'Parent figure of xfigure object not in lookup matrix.' ...
        );
    end
    iFObj = xfigures(ihFPos);

% test for root otherwise
otherwise
    if hFigType
        error( ...
            'xfigure:BadObject', ...
            'Unknown object type %d.', ...
            hFigType ...
        );
    end
    mygcf = [];
end

% finally, also set mygcbf to mygcf
mygcbf = mygcf;


% ____ process the requested action ____


% switch over action
switch (action)


% retrieve a property from the MATLAB handle
case {'get'}

    % same as MATLAB get without named arguments...
    if nargin < 3
        try
            varargout{1} = get(hFigMHnd);
            return;
        catch ne_eo;
            error( ...
                'xfigure:MATLABGuiError', ...
                'Couldn''t retrieve properties (%s).', ...
                ne_eo.message ...
            );
        end
    end

    % try to retrieve single prop
    if ischar(iStr) && isrealvarname(deblank(iStr(:)'))

        % make sure to work with a deblanked string
        iStr = deblank(iStr(:)');

        % get object type(s)
        otype = lower(get(hFigMHnd, 'Type'));
        if strcmp(otype, 'axes')
            rtype = lower(iObj.loadprops.xtype);
        else
            rtype = otype;
        end

        % get better name for property first
        try
            if isfield(xfigure_factory.aliases{hFigType + 1}, lower(iStr))
                iStr = lower(xfigure_factory.aliases{hFigType + 1}.(lower(iStr)));
            else
                iStr = lower(iStr);
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            iStr = lower(iStr);
        end

        % handle different objects
        switch (otype)

            % for special objects
            case {'axes'}

                % progess
                switch (iStr)
                    case {'progress'}
                        if ~strcmp(rtype, 'xprogress')
                            error( ...
                                'xfigure:InvalidObjectType', ...
                                'Invalid uicontrol/%s object property: Progress.', ...
                                rtype ...
                            );
                        end
                        varargout{1} = iObj.uicprops.progress;

                    case {'visible'}
                        try
                            varargout{1} = get(iObj.uicprops.xchildren(1), 'Visible');
                        catch ne_eo;
                            error( ...
                                'xfigure:BadChild', ...
                                'Couldn''t get Visible property for axes child (%s).', ...
                                ne_eo.message ...
                            );
                        end

                    % otherwise
                    otherwise
                        try
                            varargout{1} = get(hFigMHnd, iStr);
                        catch ne_eo;
                            neuroelf_lasterr(ne_eo);
                            getsf = false;
                            for cc = iObj.uicprops.xchildren
                                try
                                    varargout{1} = get(cc, iStr);
                                    getsf = true;
                                    break;
                                catch ne_eo;
                                    neuroelf_lasterr(ne_eo);
                                end
                            end
                            if ~getsf
                                error( ...
                                    'xfigure:InvalidProperty', ...
                                    'Couldn''t get %s property from axes child.', ...
                                    iStr ...
                                );
                            end
                        end
                end

            % otherwise
            otherwise
                try
                    varargout{1} = get(hFigMHnd, iStr);

                     % invalid values ? (Matlab R2009b patch)
                     if strcmp(iStr, 'value')
                         switch (otype)
                             case {'dropdown'}
                                 varargout{1} = unique(max(1, varargout{1}));
                         end
                     end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    error( ...
                        'xfigure:InvalidProperty', ...
                        'Invalid %s property: %s.', ...
                        rtype, ...
                        iStr ...
                    );
                end
        end

    % try to retrieve multiple props
    elseif isstruct(iStr) && ...
        numel(iStr) == 1
        cout = iStr;
        cfields = fieldnames(cout);
        for fc = 1:numel(cfields)
            try
                cout.(cfields{fc}) = get(hFigMHnd, cfields{fc});
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                warning( ...
                    'xfigure:InvalidProperty', ...
                    'Invalid property (%s) for object of type %s.', ...
                    cfields{fc}, ...
                    get(hFigMHnd, 'Type') ...
                );
                cout = rmfield(cout, cfields{fc});
            end
        end
        varargout{1} = cout;

    % dumb request
    else
        error( ...
            'xfigure:BadArgument', ...
            'Wrong argument type/content for Get.' ...
        );
    end


% setting a property value (valid for ALL object types!)
case {'set'}

    % we need a valid char or struct argument
    if (~isstruct(iStr) || ...
        isempty(fieldnames(iStr)) || ...
        numel(iStr) ~= 1) && ...
       ~isvarname(iStr)
        error( ...
            'xfigure:BadArgument', ...
            'Bad/missing argument provided for Set.' ...
        );
    end

    % single property
    if isvarname(iStr)

        % we need a property content
        if nargin < 4
            error( ...
                'xfigure:BadArgument', ...
                'Missing property content for Set.' ...
            );
        end

        % get object type(s)
        otype = lower(get(hFigMHnd, 'Type'));
        if strcmp(otype, 'axes')
            rtype = lower(iObj.loadprops.xtype);
        else
            rtype = otype;
        end

        % get better name for property first
        try
            if isfield(xfigure_factory.aliases{hFigType + 1}, lower(iStr))
                iStr = lower(xfigure_factory.aliases{hFigType + 1}.(lower(iStr)));
            else
                iStr = lower(iStr);
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            iStr = lower(iStr);
        end

        % handle different objects
        switch (otype)
            case {'axes'}

                % successful
                setsf = false;

                % image CData
                switch iStr
                    case {'cdata'}
                        if ~strcmp(rtype, 'ximage')
                            error( ...
                                'xfigure:InvalidObjectType', ...
                                'Bad %s property: CData.', ...
                                rtype ...
                            );
                        end
                        try
                            set(iObj.uicprops.xchildren(1), 'CData', varargin{4});
                            setsf = true;
                            try
                                set(iObj.uicprops, 'XLim', [0.5, 0.5 + size(varargin{4}, 2)]);
                                set(iObj.uicprops, 'YLim', [0.5, 0.5 + size(varargin{4}, 1)]);
                            catch ne_eo;
                                neuroelf_lasterr(ne_eo);
                            end
                        catch ne_eo;
                            rethrow(ne_eo);
                        end

                    % enabled
                    case {'enable'}

                        % only do something on xlabels
                        if strcmp(rtype, 'xlabel')
                            ncolor = iObj.loadprops.xcolor;
                            try
                                if ~strcmpi(varargin{4}, 'on')
                                    bcolor = get(hFigMHnd, 'Color');
                                    if ~isnumeric(bcolor) || ...
                                        isempty(bcolor)
                                        bcolor = get(gcbf, 'Color');
                                    end
                                    if ~isnumeric(bcolor) || ...
                                        isempty(bcolor)
                                        bcolor = xfigure_factory.figbgcolor;
                                    end
                                    ncolor = (1.5 * bcolor + ncolor) * 0.4;
                                end
                                set(iObj.uicprops.xchildren(1), 'Color', ncolor);
                                setsf = true;
                            catch ne_eo;
                                neuroelf_lasterr(ne_eo);
                            end
                        end

                    % position
                    case {'position', 'units'}

                        try
                            set(hFigMHnd, 'Position', varargin{4});
                            setsf = true;
                            if strcmp(rtype, 'xprogress')
                                xfigure(hFigure, 'ProgressBar', NaN);
                            end
                        catch ne_eo;
                            neuroelf_lasterr(ne_eo);
                        end

                    % otherwise
                    otherwise

                        % first try on children
                        for cobj = iObj.uicprops.xchildren(:)'
                            try
                                set(cobj, iStr, varargin{4});
                                setsf = true;
                                if setsf
                                    break;
                                end
                            catch ne_eo;
                                neuroelf_lasterr(ne_eo);
                            end
                        end

                        % yet on axis
                        if ~setsf
                            try
                                set(hFigMHnd, iStr, varargin{4});
                                setsf = true;
                            catch ne_eo;
                                neuroelf_lasterr(ne_eo);
                            end
                        end
                end

                % error if not successful
                if ~setsf
                   error( ...
                       'xfigure:BadPropertyOrValue', ...
                       'Couldn''t set property %s on %s object type.', ...
                       iStr, ...
                       rtype ...
                   );
                end

            % other objects
            otherwise

                try
                    set(hFigMHnd, iStr, varargin{4});
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    warning( ...
                        'xfigure:BadPropertyOrValue', ...
                        'Couldn''t set property %s on %s object type.', ...
                        iStr, ...
                        rtype ...
                    );
                end
        end

    % struct
    else

        % simply iterate over fields...
        cfields = fieldnames(iStr);
        for fc = 1:numel(cfields)
            xfigure(hFigure, 'Set', cfields{fc}, iStr.(cfields{fc}));
        end
    end


% get default property of object
case {'value'}

    % switch over type
    switch (hFigType), case {xfigure_factory.objtypes.root}
        ovalue = 'Off';
        if strcmpi(get(0, 'Visible'), 'on') && ...
           ~all(get(0, 'Size') == 1)
            ovalue = 'On';
        end

    case {xfigure_factory.objtypes.figure}
        ovalue = get(hFigMHnd, 'Name');

    case {xfigure_factory.objtypes.uicontrol}

        % get object subtype
        otype = lower(get(hFigMHnd, 'Style'));

        % switch over subtype
        switch (otype), case {'edit', 'frame', 'pushbutton', 'text'}
            ovalue = get(hFigMHnd, 'String');

        otherwise
            ovalue = get(hFigMHnd, 'Value');

        end

    case {xfigure_factory.objtypes.uimenu}
        ovalue = get(hFigMHnd, 'Label');

    case {xfigure_factory.objtypes.uicontextmenu}
        ovalue = 'Off';
        if strcmpi(get(0, 'Visible'), 'on')
            ovalue = 'On';
        end

    otherwise
        error( ...
            'xfigure:InvalidObjType', ...
            'Invalid object type. No default value specified.' ...
        );
    end

    % set output value
    varargout{1} = ovalue;


% getting the Matlab handle of an object
case {'mlhandle'}
    varargout{1} = hFigure.mhnd;


% delete an object
case {'delete'}

    % anything but the root object
    if hFigType
        set(hFigMHnd, 'DeleteFcn', '');

        % execute original DeleteFcn
        if numel(iObj.callbacks) > 3 && ...
           ~isempty(iObj.callbacks{4})
            try
                evalin('base', iObj.callbacks{4});
            catch ne_eo;
                warning(ne_eo.message);
            end
        end

        % set to invisible first
        try
            set(hFigMHnd, 'Visible', 'off');
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

        % remove children first
        mchild = get(hFigMHnd, 'Children');
        if ~isempty(mchild)
            for cc = 1:numel(mchild)
                try
                    if ishandle(mchild(cc)) && ...
                       ~strcmpi(get(mchild(cc), 'BeingDeleted'), 'on')
                        delete(mchild(cc));
                    end
                catch ne_eo;
                    warning(ne_eo.message);
                end
            end
        end

        % Tag to remove
        if ~isempty(iObj.loadprops.Tag)
            ioTag = [xfigure_factory.objtypet{hFigType} iObj.loadprops.Tag];
            if isfield(xfigure_factory.tags, ioTag)
                xfigure_factory.tags = rmfield(xfigure_factory.tags, ioTag);
            end
        end

        % delete this (if not already in process)
        try
            if ~strcmpi(get(hFigMHnd, 'BeingDeleted'), 'on')
                delete(hFigMHnd);
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

        % lookup again (probably other objects were removed as well !)
        nihPos = find(xfig_mlup == hFigMHnd);
        if ~isempty(nihPos)
            xfig_ilup(nihPos) = [];
            xfig_mlup(nihPos) = [];
            xfig_type(nihPos) = [];
            xfigures(nihPos)  = [];
        end

    % it's the root objecct
    else

        % return on empty option
        if isempty(iStr)
            return;
        end

        % for numeric input
        if isnumeric(iStr)

            % try lookup and delete
            try
                myObj = xfigure(iStr);
                xfigure(myObj, 'Delete');
            catch ne_eo;
                rethrow(ne_eo);
            end

        % bad input
        else
            error( ...
                'xfigure:CallingConvention', ...
                'Invalid input type for Delete.');
        end
    end


% increase progress bar
case {'progress'}

    % only valid for uicontrol objects
    if hFigType ~= xfigure_factory.objtypes.uicontrol || ...
       ~strcmpi(iObj.loadprops.xtype, 'xprogress')
        error( ...
            'xfigure:InvalidObjectType', ...
            'Progress only valid for UIControl/XProgress objects.' ...
        );
    end

    % empty progress
    if nargin < 3 || ...
       ~isnumeric(iStr) || ...
        isempty(iStr)
        refresh(get(hFigMHnd, 'Parent'));
        varargout{1} = iObj.uicprops.progress;
        return;
    end

    % set width?
    if nargin > 3 && ...
        ischar(varargin{4}) && ...
        any(strcmpi(varargin{4}(:)', {'newwidth', 'newheight'}))
        if strcmpi(varargin{4}(:)', 'newwidth')
            xfigures(ihPos).loadprops.Position(3) = iStr;
            pbpos = get(hFigMHnd, 'Position');
            set(hFigMHnd, 'Position', [pbpos(1:2), iStr, pbpos(4)]);
        elseif strcmpi(varargin{4}(:)', 'newheigth')
            pbpos = get(hFigMHnd, 'Position');
            set(hFigMHnd, 'Position', [pbpos(1:3), iStr]);
            xfigures(ihPos).loadprops.Position(4) = iStr;
        end
        if nargin < 5
            xfigure(varargin{1}, 'progress', iObj.uicprops.progress);
        else
            xfigure(varargin{1}, 'progress', iObj.uicprops.progress, [], varargin{5:end});
        end
        return;
    end

    % get handle
    hPatch = iObj.uicprops.xchildren(2);

    % calculate progress position
    if isinf(iStr(1)) || ...
        isnan(iStr(1))
        PrgPos = iObj.uicprops.progress;
    else
        PrgPos = max(0, min(1, (iStr(1) - iObj.loadprops.MinMaxTop(1)) / ...
                 (iObj.loadprops.MinMaxTop(2) - iObj.loadprops.MinMaxTop(1))));
        xfigures(ihPos).uicprops.progress = PrgPos;
    end

    % round progress bars:
    % we must get the position from the main axes object and then
    % use this to calculate the image axes' position
    switch (lower(iObj.loadprops.ProgType))
        case {'round'}
            try
                hBarAx = get(iObj.uicprops.xchildren(1), 'Parent');
                set(hBarAx, 'Units', 'pixels');
                oPos = iObj.loadprops.Position;
                if strcmp(iObj.loadprops.ProgDir, 'y')
                    oPos(4) = oPos(4) * PrgPos + eps;
                else
                    oPos(3) = oPos(3) * PrgPos + eps;
                end
                set(hBarAx, 'Position', oPos);
            catch ne_eo;
                warning(ne_eo.message);
            end

        % flat progress bars:
        case {'flat'}
            try
                % horiz or vert progress bar
                if strcmp(iObj.loadprops.ProgDir, 'y')
                    set(hPatch, 'Position', [0, 0, 1, min(1, (PrgPos + eps))]);
                else
                    set(hPatch, 'Position', [0, 0, min(1, (PrgPos + eps)), 1]);
                end
            catch ne_eo;
                warning(ne_eo.message);
            end

        % otherwise, bail out
        otherwise
            error( ...
                'xfigure:InternalError', ...
                'Invalid ProgressBar type: %s.', ...
                iObj.loadprops.ProgType ...
            );
    end

    % labeling
    if nargin > 3 && ...
        ischar(varargin{4}) && numel(iObj.uicprops.xchildren) > 2
        try
            set(iObj.uicprops.xchildren(end), 'String', varargin{4}(:)');
        catch ne_eo;
            warning(ne_eo.message);
        end
    end
    if nargin < 5 || ...
       ~islogical(varargin{5}) || ...
        numel(varargin{5}) ~= 1 || ...
        varargin{5}
        drawnow;
    end


% adding a string (routed via mstring)
case {'addstring'}

    % only valid for dropdown or listbox uicontrols
    if hFigType ~= xfigure_factory.objtypes.uicontrol || ...
       ~any(strcmpi(iObj.prevprops.Style, {'popupmenu', 'listbox'}))
        error( ...
            'xfigure:InvalidObjectType', ...
            'AddString is only valid for DropDown or ListBox UIControls.' ...
        );
    end

    % only accept valid insertions
    if ~ischar(iStr) && ...
       ~iscell(iStr)
        error( ...
            'xfigure:BadArgument', ...
            'AddString requires a CHAR or CELL argument to add.' ...
        );
    end

    % positional argument given
    if nargin < 4
        if ischar(iStr)
            pos = ones(1, size(iStr, 1)) * Inf;
        else
            pos = ones(1, numel(iStr)) * Inf;
        end
    else
        pos = varargin{4}(:)';
    end

    % route through MString method
    try
        xfigure(hFigure, 'mstring', pos, iStr, 1);
    catch ne_eo;
        rethrow(ne_eo);
    end


% adding a uicontextmenu
case {'adduicontextmenu'}

    % only valid for figure and uipanel objects
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'Only figures can be parents of uicontextmenus.' ...
        );
    end

    % test iStr
    if ~isstruct(iStr)
        error( ...
            'xfigure:BadPropertyStruct', ...
            'Uicontextmenu properties must be of type struct.' ...
        );
    end

    % perform some checks on struct
    iStr = checkstruct(iStr, xfigure_factory.optuix);

    % get new OUID
    uuid = handlenew(xfigure_factory.objtypes.uicontextmenu, xfig_ilup);
    dfcn = sprintf('xfigure(%0.0f,''Delete'');', uuid);

    % use tag from iStr?
    if ~isempty(iStr.Tag) && ...
        numel(iStr.Tag) < 28 && ...
        isrealvarname(iStr.Tag(:)')
        utag = iStr.Tag(:)';
    else
        iStr.Tag = sprintf('UIX_%010.0f', uuid);
        utag = ['xfigure_' iStr.Tag];
    end

    % prepare struct for call
    oStr = struct( ...
        'Parent',        hFigMHnd, ...
        'Callback',      iStr.Callback, ...
        'DeleteFcn',     dfcn, ...
        'Interruptible', iStr.Interrupts, ...
        'Tag',           utag, ...
        'UserData',      iStr.UserData);

    % create object and fill/update fields as necessary
    hOut = uicontextmenu(oStr);
    cout = xfigure(0, 'makeobj', ...
        uuid, hOut, xfigure_factory.objtypes.uicontextmenu);
    try
        set(hFigMHnd, 'UIContextMenu', []);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end

    % complete object representation
    oObj = makeostruct(xfigure_factory.objtypes.uicontextmenu);
    oObj.callbacks = {'', '', '', iStr.CallbackDelete};
    oObj.loadprops = iStr;
    oObj.prevprops = get(hOut);
    xfig_ilup(end + 1) = uuid;
    xfig_mlup(end + 1) = hOut;
    xfig_type(end + 1) = cout.type;
    xfigures(end + 1)  = oObj;

    % finally, add to global tag lookup struct
    xfigure_factory.tags.(['UIX_' iStr.Tag]) = cout;

    % and return appropriate object
    varargout{1} = cout;


% adding a uicontrol object
case {'adduicontrol'}

    % only valid for figure and uipanel objects
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'Only figures can be parents of uicontrols.' ...
        );
    end

    % test iStr
    if ~isstruct(iStr)
        error( ...
            'xfigure:BadPropertyStruct', ...
            'Uicontrol properties must be of type struct.' ...
        );
    end

    % perform some checks on struct
    iStr = checkstruct(iStr, xfigure_factory.optuic);
    if isempty(iStr.Type) || ...
       ~isfield(xfigure_factory.uictypes, lower(iStr.Type)) || ...
       ~isnumeric(iStr.Position) || ...
        isempty(iStr.Position) || ...
        numel(iStr.Position) ~= 4
        error( ...
            'xfigure:BadPropertyStruct', ...
            'Bad uicontrol property struct supplied.' ...
        );
    end

    % get new OUID
    uuid = handlenew(xfigure_factory.objtypes.uicontrol, xfig_ilup);
    dfcn = sprintf('xfigure(%0.0f,''Delete'');', uuid);

    % use tag from iStr?
    if ~isempty(iStr.Tag) && ...
        numel(iStr.Tag) < 28 && ...
        isrealvarname(iStr.Tag(:)')
        utag = iStr.Tag(:)';
    else
        iStr.Tag = sprintf('UIC_%010.0f', uuid);
        utag = ['xfigure_' iStr.Tag];
    end

    % shortcuts to some important settings
    iCTyp = lower(iStr.Type);
    iCap  = iStr.Caption;
    iPar  = hFigMHnd;
    iPos  = iStr.Position;
    iVis  = iStr.Visible;

    % preset callbacks array
    iStr.Callbacks = cell(1, 4);
    if isempty(iStr.ContextMenu)
        cbclick = iStr.CallbackClick(:)';
    else
        cbclick = [ ...
            sprintf('xfigure(xfigure,''setcontext'',%0.0f));', uuid) ...
            iStr.CallbackClick(:)'];
    end

    % special type
    iRTyp = xfigure_factory.uictypes.(iCTyp);
    if strcmp(iRTyp, 'BUILTIN')
        iRSpec = true;
    else
        iRSpec = false;
    end

    % background color
    hasBGColor = true;
    if numel(iStr.ColorBG) == 1
        iStr.ColorBG(1:3) = iStr.ColorBG;
    elseif numel(iStr.ColorBG) ~= 3
        if ~any(strcmpi(iCTyp, {'label', 'radiobutton'}))
            hasBGColor   = false;
        end
        iStr.ColorBG = get(iPar, 'Color');
    end
    iCBG = max(0, min(1, iStr.ColorBG));

    % foreground color
    hasFGColor = true;
    if numel(iStr.ColorFG) == 1
        iStr.ColorFG(1:3) = iStr.ColorFG;
    elseif numel(iStr.ColorFG) ~= 3
        hasFGColor   = false;
        iStr.ColorFG = [0 0 0];
    end
    iCFG = max(0, min(1, iStr.ColorFG));

    % fontsize
    if ischar(iStr.FontSize) && ...
       ~isempty(iStr.FontSize) && ...
        isfield(xfigure_factory.fntsizes, iStr.FontSize(:)')
        iStr.FontSize = xfigure_factory.fntsizes.(iStr.FontSize(:)');
    elseif ~isnumeric(iStr.FontSize) || ...
        numel(iStr.FontSize) ~= 1
        if xfigure_factory.fontfactuse
            iStr.FontSize = 10 * xfigure_factory.fontfact;
        else
            iStr.FontSize = 10;
        end
    elseif xfigure_factory.fontfactuse
        iStr.FontSize = iStr.FontSize * xfigure_factory.fontfact;
    end

    % sliderstep
    if ~any(strcmp(iCTyp, {'slider', 'xprogress'})) || ...
        numel(iStr.SliderStep) < 2
        iStr.SliderStep = [];
    else
        iStr.SliderStep = iStr.SliderStep(1:2);
        if strcmp(iCTyp, 'slider')
            if isempty(iStr.Value)
                if ~isempty(iStr.MinMaxTop)
                    iStr.Value = iStr.MinMaxTop(1);
                else
                    iStr.Value = 1;
                end
            elseif ~isempty(iStr.MinMaxTop)
                iStr.Value = min(iStr.MinMaxTop(2), max(iStr.MinMaxTop(1), iStr.Value(1)));
            end
        end
    end

    % special type requested ?
    xchildren = [];
    if iRSpec

        % set default axes struct
        oStr = struct( ...
            'Parent',        iPar, ...
            'Units',         iStr.Units, ...
            'Position',      iPos, ...
            'ButtonDownFcn', cbclick, ...
            'Color',         'none', ...
            'DeleteFcn',     dfcn, ...
            'Tag',           utag, ...
            'UserData',      iStr.UserData, ...
            'Visible',       iVis);

        % what type
        switch iCTyp

        % axes
        case  {'xaxes'}

            % axes options are in caption
            if ischar(iCap) && ...
               ~isempty(iCap)
                [myaxopts, myonum] = splittocell(iCap, ',');

                % remove last if impair number
                if rem(myonum, 2)
                    myaxopts(end) = [];
                    myonum = myonum - 1;
                end

                % basic test on options
                for myon = 1:2:myonum

                    % option name in hyphens
                    if ~isempty(myaxopts{myon}) && ...
                        myaxopts{myon}(1) == '''' && ...
                        myaxopts{myon}(end) == ''''
                        myaxopts{myon} = myaxopts{myon}(2:end-1);
                    end

                    % option setting with value evaluation
                    try
                        oStr.(myaxopts{myon}) = eval(myaxopts{myon + 1});
                    catch ne_eo;
                        neuroelf_lasterr(ne_eo);
                        break;
                    end
                end
            end

            % create axes object
            hOut = axes(oStr);

        % images
        case  {'ximage'}
            % no useful argument
            if isempty(iCap)
                error( ...
                    'xfigure:BadImageContent', ...
                    'Images either need a filename or a binary content.' ...
                );
            end

            % filename
            if ischar(iCap)

                % try to read image
                try
                    imgpdata = imread(iCap(:)');
                    if isempty(imgpdata)
                        error('INVALID_IMAGE');
                    end
                catch ne_eo;
                    error( ...
                        'xfigure:BadImageFile', ...
                        'The file (%s) is not readable or corrupt (%s).', ...
                        iCap(:)', ne_eo.message ...
                    );
                end

            % binary image data
            elseif isnumeric(iCap)
                imgpdata = iCap;
                iStr.Caption = '';

                % only 2-D -> grayscale
                if ndims(imgpdata) < 3
                    imgpdata(:, :, 2:3) = imgpdata(:, :, [1, 1]);
                end

            % invalid content
            else
                error( ...
                    'xfigure:BadImageContent', ...
                    'Images either need a filename or a binary content.' ...
                );
            end

            % apply shading if requested (watermarks, etc.)
            if hasBGColor && ...
                hasFGColor
                imgpdata(:, :, 1) = ...
                    uint8(floor(double(imgpdata(:, :, 1)) * iCFG(1) + ...
                    255 * iCBG(1) * (1 - iCFG(1))));
                imgpdata(:, :, 2) = ...
                    uint8(floor(double(imgpdata(:, :, 2)) * iCFG(2) + ...
                    255 * iCBG(2) * (1 - iCFG(2))));
                imgpdata(:, :, 3) = ...
                    uint8(floor(double(imgpdata(:, :, 3)) * iCFG(3) + ...
                    255 * iCBG(3) * (1 - iCFG(3))));
            end

            % create axes object and image
            hOut = axes(oStr);
            xchildren = image(imgpdata, 'Parent', hOut);

            % MATLAB BUG !!! image() resets the axes' DeleteFcn !!!
            set(hOut, 'DeleteFcn', oStr.DeleteFcn);

            % reset axes visibility to off
            set(hOut, 'Visible', 'off');
            set(xchildren, 'Visible', iVis, 'UserData', uuid);

        % extended labels (with tex func :)
        case {'xlabel', 'xlink'}

            % replace empty labels with 'tex:' label
            if isempty(iCap)
                iCap = 'tex:';
            end

            % create axes object and text child
            hOut = axes(oStr);
            myct = struct('Parent', hOut);
            myct.Units           = 'normalized';
            myct.Position        = [0.0 0.0];
            myct.HorizontalAlign = iStr.HAlign;
            myct.VerticalAlign   = iStr.VAlign;
            myct.FontAngle       = iStr.FontItalic;
            myct.FontName        = iStr.FontName;
            myct.FontSize        = iStr.FontSize;
            myct.FontWeight      = iStr.FontWeight;
            myct.FontUnits       = 'points';
            if ~isempty(iStr.Rotation)
                myct.Rotation = iStr.Rotation(1);
            end
            myct.UserData        = uuid;

            % interpreter
            if numel(iCap) > 3 && ...
                strcmpi(iCap(1:4), 'tex:')
                myct.Interpreter = 'tex';
                iCap(1:4) = [];
            else
                myct.Interpreter = 'none';
            end

            % y - wise rotation
            if numel(iCap) > 1 && ...
                strcmpi(iCap(1:2), 'y:')
                myct.Rotation = 90;
                iCap(1:2) = [];
            end

            % special "align" treatment
            switch lower(iStr.HAlign)
                case {'center'}
                    myct.Position(1) = 0.5;
                case {'right'}
                    myct.Position(1) = 1.0;
            end
            switch lower(iStr.VAlign)
                case {'middle'}
                    myct.Position(2) = 0.5;
                case {'top'}
                    myct.Position(2) = 1.0;
            end

            % do we deal with a link ?
            LinkTarget = [];
            if strcmp(iCTyp, 'xlink')
                CapParts = splittocell(iCap, '|', 1);
                iCap = CapParts{1};
                if numel(CapParts) > 1
                    LinkTarget = CapParts{2};
                end
            end

            % finally, set Position
            xchildren = text(myct.Position(1), myct.Position(2), iCap, myct);
            set(hOut, 'Visible', 'off');
            set(xchildren, 'Visible', iVis);
            iStr.Caption = iCap;
            oStr.Label = myct;

            % set link handler
            if ~isempty(LinkTarget) && ...
               ~isempty(xfigure_factory.linkhandler)
                set(xchildren, 'ButtonDownFcn', ...
                    ['!' xfigure_factory.linkhandler{1} ...
                         deblank(LinkTarget) ...
                         xfigure_factory.linkhandler{2}]);
                try
                    set(xchildren, 'Color', 'red');
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end

            % keep note of children and color
            oStr.xcolor = get(xchildren, 'Color');

        % progress bars
        case {'xprogress'}

            % set correct empty caption
            if isempty (iCap)
                iCap = 'x: ';
            end

            % set progress bar range
            if numel(iStr.MinMaxTop) > 2 && ...
               ~any(isnan(iStr.MinMaxTop) || ...
                isinf(iStr.MinMaxTop))
                iStr.MinMaxTop = iStr.MinMaxTop(1:3);
            else
                iStr.MinMaxTop = [0, 1, 0];
            end

            % create axes object
            hOut = axes(oStr);
            set(hOut, 'Units', 'normalized');

            % the problem with images is that they do not have a position
            % property for the parent axes object, so we need TWO axes objects
            % so as to make this work "properly"...

            % with no sliderstep value make "flat" bar with rectangle
            if isempty(iStr.SliderStep) || ...
                iStr.SliderStep(1) ~= 1
                iStr.ProgType = 'flat';

                % make bar from filling rectangle and surrounding line
                xchildren = rectangle( ...
                    'Position',  [0, 0, eps, eps], ...
                    'FaceColor', iCFG, ...
                    'EdgeColor', iCFG, ...
                    'EraseMode', 'background', ...
                    'UserData',  uuid, ...
                    'Visible',   iVis);

            % make "round" progress bars with graded colour image
            else
                iStr.ProgType     = 'round';
                try
                    iStr.Value(end + 1) = 0;
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end

                % how many colors
                numlines = max(xfigure_factory.progbarface, iStr.SliderStep(2));
                numcols  = fix((numlines + 1) / 2);

                % put together bar image
                imgpdata(1, numlines, 3) = uint8(0);
                for colc = 1:numcols
                    colb = (numcols - colc) / numcols;
                    colf = colc / numcols;
                    ridx = [colc (1 + numlines - colc)];
                    imgpdata(1, ridx, 1) = ...
                        uint8(fix(255 * (colb * iCBG(1) + colf * iCFG(1)) + 0.5));
                    imgpdata(1, ridx, 2) = ...
                        uint8(fix(255 * (colb * iCBG(2) + colf * iCFG(2)) + 0.5));
                    imgpdata(1, ridx, 3) = ...
                        uint8(fix(255 * (colb * iCBG(3) + colf * iCFG(3)) + 0.5));
                end

                % if direction is Y-axes, reshape image to Yx1
                if numel(iCap) < 1 || lower(iCap(1)) ~= 'y'
                    imgpdata = reshape(imgpdata, [numlines, 1, 3]);
                end

                % add image to "first" axes
                xchildren = image(imgpdata, 'Parent', hOut);
                set(xchildren, 'Visible', iVis, 'UserData', uuid);
                set(hOut, 'Tag', ['PBX_' oStr.Tag], ...
                    'UserData', uuid, 'Visible', 'off');

                % create "second" axes object for outline and caption
                hOut = axes(oStr);
                set(hOut, 'Units', 'normalized');
            end
            xchildren = [xchildren, line( ...
                [0, 1, 1, 0, 0], [0, 0, 1, 1, 0], ...
                'Parent',    hOut, ...
                'EraseMode', 'none', ...
                'Color',     iCBG * 0.75, ...
                'UserData',  uuid, ...
                'Visible',   iVis)];

            % prepare Caption
            if numel(iCap) > 1 && ...
                iCap(2) == ':'
                ixCap = {iCap(1), iCap(3:end)};
            else
                ixCap = {'x', iCap};
            end
            myct = struct('Parent', hOut);
            myct.Units           = 'normalized';
            myct.Position        = [0.5 0.5];
            myct.HorizontalAlign = 'center';
            myct.VerticalAlign   = 'middle';
            myct.FontAngle       = iStr.FontItalic;
            myct.FontName        = iStr.FontName;
            myct.FontSize        = iStr.FontSize;
            myct.FontUnits       = 'points';
            myct.FontWeight      = iStr.FontWeight;
            myct.UserData        = uuid;
            myct.Visible         = iVis;
            if prod(iCFG) < 0.125 && ...
                all(iCFG < 0.25)
                itColor = [0.9325 0.9325 0.9325];
            else
                itColor = iCBG * 0.125;
            end
            myct.Color = itColor;

            % if tex interpreter is requested (prefix: "tex:") use it!
            if numel(ixCap{2}) > 3 && ...
                strcmpi(ixCap{2}(1:4), 'tex:')
                myct.Interpreter = 'tex';
                ixCap{2} = ixCap{2}(5:end);
            else
                myct.Interpreter = 'none';
            end

            % generate text object
            hTxt = text(myct.Position(1), myct.Position(2), ixCap{2}, myct);
            if ~isempty(ixCap{1}) && ...
                lower(ixCap{1}) =='y'
                set(hTxt, 'Rotation', 90);
                iStr.ProgDir = 'y';
            else
                iStr.ProgDir = 'x';
            end
            iStr.Caption = ixCap{2};

            % get size, set Units back to original units and init progress
            set(hOut, 'Units', iStr.Units, 'Visible', 'off');
            try
                oStr.progress = iStr.Value(end);
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                oStr.progress = 0;
            end
            xchildren(end + 1) = hTxt;

        end

        % keep a note on what type was used
        iStr.xtype = iCTyp;

    % "only" a MATLAB uicontrol type
    else

        % deal with radiobutton / radiogroup click events
        iStr.Callbacks{1} = iStr.Callback;
        if strcmp(iRTyp, 'radiobutton') && ...
           ~isempty(iStr.RGroup)
            iStr.Callback  = 'xfigure(gcbo,''rgroupclick'');';

        % otherwise standard behaviour
        else
            iStr.Callbacks = {iStr.Callback, '', iStr.CallbackDblClick};
            iStr.Callback  = 'xfigure(gcbo,''doubleclick'');';
        end

        % check MinMaxTop according to edit/multiedit type
        if strcmp(iCTyp, 'edit')
            iStr.MinMaxTop = [0 0 0];
        elseif strcmp(iCTyp, 'multiedit')
            iStr.MinMaxTop = [0 2 0];
        elseif numel(iStr.MinMaxTop) > 2
            iStr.MinMaxTop = iStr.MinMaxTop(1:3);
        else
            iStr.MinMaxTop = [0 1 1];
        end

        % start building struct for MATLAB uicontrol() call
        oStr = struct( ...
            'Parent',             iPar, ...
            'Units',              iStr.Units, ...
            'Position',           iPos, ...
            'ButtonDownFcn',      cbclick, ...
            'Callback',           iStr.Callback, ...
            'DeleteFcn',          dfcn, ...
            'Enable',             iStr.Enabled, ...
            'FontAngle',          iStr.FontItalic, ...
            'FontName',           iStr.FontName, ...
            'FontSize',           iStr.FontSize, ...
            'FontWeight',         iStr.FontWeight, ...
            'ForegroundColor',    iCFG, ...
            'HorizontalAlign',    iStr.HAlign, ...
            'Interruptible',      iStr.Interrupts, ...
            'ListboxTop',         iStr.MinMaxTop(3), ...
            'Max',                iStr.MinMaxTop(2), ...
            'Min',                iStr.MinMaxTop(1), ...
            'SelectionHighlight', iStr.Selectable, ...
            'Style',              iRTyp, ...
            'Tag',                utag, ...
            'TooltipString',      iStr.ToolTip, ...
            'UserData',           iStr.UserData, ...
            'Visible',            iVis ...
        );
        if ~isempty(iStr.Value)
            oStr.Value = iStr.Value;
        end

        % background color specified ?
        if hasBGColor
            oStr.BackgroundColor = iCBG;
        end

        % make images loadable for button and toggle UIControls
        if any(strcmp(iCTyp,{'button', 'toggle'})) && ...
           ~isempty(iStr.Caption)

            % caption = filename?
            if ischar(iStr.Caption) && ...
                any(iStr.Caption(:)' == '.') && ...
                exist(iStr.Caption(:)', 'file') == 2
                try
                    oStr.CData = double(imread(iStr.Caption(:)')) / 256;
                    iStr.ImageFile = iStr.Caption(:)';
                    iStr.Caption = '';
                catch ne_eo;
                    warning( ...
                        'xfigure:BadImageFile', ...
                        'Not a valid image file: %s (%s).', ...
                        iStr.Caption(:)', ne_eo.message ...
                    );
                end

            % binary caption = image
            elseif isnumeric(iStr.Caption) && ...
               ~isempty(iStr.Caption) && ...
                ndims(iStr.Caption) == 3
                oStr.CData = double(iStr.Caption);
                if any(oStr.CData(:) > 1)
                    oStr.CData = oStr.CData ./ 256;
                end
                iStr.ImageData = iStr.Caption;
                iStr.Caption = '';

            % otherwise copy caption
            else
                oStr.String = iStr.Caption;
            end

        % otherwise simply copy caption
        else
            oStr.String = iStr.Caption;
        end

        % set style and do your job
        hOut        = uicontrol(oStr);
        iStr.xtype  = '';
    end

    % update UIControl unique counter and make sure we're deleted correctly
    cout = xfigure(0, 'makeobj', ...
        uuid, hOut, xfigure_factory.objtypes.uicontrol);
    oStr.MLHandle = hOut;

    % uicontext menu
    if ~isempty(iStr.ContextMenu)
        uicm = findobj('Type', 'uicontextmenu', 'Tag', iStr.ContextMenu);
        if ~isempty(uicm)
            try
                set(hOut, 'UIContextMenu', uicm(1));
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end
    end

    % any Enable-groups ?
    iGroups = splittocellc(iStr.EGroups, ',; ', true, true);
    for iGroupC = numel(iGroups):-1:1
        iGroup = deblank(iGroups{iGroupC});
        if isrealvarname(iGroup)
            if isfield(xfigures(ihPos).figprops.egroups, iGroup)
                xfigures(ihPos).figprops.egroups.(iGroup)(end + 1) = uuid;
            else
                xfigures(ihPos).figprops.egroups.(iGroup) = uuid;
            end
        else
            iGroups(iGroupC) = [];
        end
    end
    iStr.EGroups = iGroups;

    % any RadioGroup ?
    iGroup = iStr.RGroup;
    if ~isempty(iGroup)
        if isfield(xfigures(ihPos).figprops.rgroups, iGroup)
            xfigures(ihPos).figprops.rgroups.(iGroup)(end + 1) = uuid;
        else
            xfigures(ihPos).figprops.rgroups.(iGroup) = uuid;
        end
    end

    % any SlideXY-group ?
    iGroup = iStr.SGroups;
    if ~isempty(iGroup)
        if isfield(xfigures(ihPos).figprops.sgroups, iGroup)
            xfigures(ihPos).figprops.sgroups.(iGroup)(end + 1) = uuid;
        else
            xfigures(ihPos).figprops.sgroups.(iGroup) = uuid;
        end
    end

    % a page named ?
    iPg  = unique(iStr.Page);
    myVG = deblank(iStr.VGroups);
    if ~isempty(iPg)

        % just add the Pages to the VGroups field

        % positive page number -> groups: pageno and anypage
        if iPg(1) > 0
            myVG = [myVG sprintf(',UICPage%d', iPg(:)')];
            myVG = [myVG ',UICPage_any'];

        % number = -1 -> groups: allpages
        elseif iPg(1) == -1
            myVG = [myVG ',UICPage_all'];
            iStr.Page = [];

        % number < -1 or number == 0 , same as no pages -> no groups
        else
            iStr.Page = [];
        end

        % set back iStr.VGroups for correct handling
        if ~isempty(myVG) && ...
            myVG(1) == ','
            myVG(1) = [];
        end

        % then add to figure's array
        xfigures(ihPos).figprops.pages = ...
            union(xfigures(ihPos).figprops.pages, iStr.Page);
    end

    % any Visible-groups (or pages)
    iGroups = splittocellc(myVG, ',; ', true, true);
    for iGroupC = numel(iGroups):-1:1
        iGroup = deblank(iGroups{iGroupC});
        if isrealvarname(iGroup)
            if isfield(xfigures(ihPos).figprops.vgroups, iGroup)
                xfigures(ihPos).figprops.vgroups.(iGroup)(end+1) = uuid;
            else
                xfigures(ihPos).figprops.vgroups.(iGroup) = uuid;
            end
        else
            iGroups(iGroupC) = [];
        end
    end
    iStr.VGroups = iGroups;

    % any valid resize spec
    if numel(iStr.ResizeSpec) ~= 2 || ...
       ~isrealvarname(iStr.ResizeSpec{1}) || ...
       ~isa(iStr.ResizeSpec{2}, 'double') || ...
        numel(iStr.ResizeSpec{2}) ~= 8
        iStr.ResizeSpec = {};
    else
        iStr.ResizeSpec = {iStr.ResizeSpec{1}(:)', iStr.ResizeSpec{2}(:)'};
    end

    % complete object represetation
    oObj = makeostruct(xfigure_factory.objtypes.uicontrol);
    oObj.callbacks = iStr.Callbacks;
    oObj.loadprops = iStr;
    oObj.prevprops = get(hOut);
    oObj.timeclick = {0, 0};
    if isfield(oStr, 'progress')
        oObj.uicprops(1).progress = oStr.progress;
    end
    oObj.uicprops(1).xchildren = xchildren;
    xfig_ilup(end + 1) = uuid;
    xfig_mlup(end + 1) = hOut;
    xfig_type(end + 1) = cout.type;
    xfigures(end + 1) = oObj;

    % set info to parent object...
    xfigures(ihPos).figprops.lilookup = -1;
    if ~isempty(iStr.ResizeSpec) && ...
       ~isempty(iStr.Tag)
        xfigures(ihPos).figprops.rszuics(end+1) = {cout};
    end

    % if progress bar has initial value issue command
    if iRSpec && ...
        strcmp(iCTyp, 'xprogress') && ...
       ~isempty(iStr.Value)
        xfigure(cout, 'Progress', iStr.Value(1));

    % if listbox and no line is to be selected
    elseif strcmp(iCTyp, 'listbox') && ...
       ~isempty(iStr.Value) && ...
        iStr.Value(1) == 0
        set(hOut, 'Value', []);
    end

    % add to global tag lookup struct
    xfigure_factory.tags.(['UIC_' iStr.Tag]) = cout;

    % set handle visibility
    set(hOut, 'HandleVisibility', xfigure_factory.hvisible);

    % return appropriate object
    varargout{1} = cout;


% adding a uimenu object
case {'adduimenu'}

    % only valid for figures or UIMenus
    if ~any([xfigure_factory.objtypes.figure, ...
             xfigure_factory.objtypes.uicontextmenu, ...
             xfigure_factory.objtypes.uimenu] == hFigType)
        error( ...
            'xfigure:InvalidObjectType', ...
            'Bad object type (%s) for AddUIMenu(...).', ...
            get(hFigMHnd, 'Type') ...
        );
    end

    % test iStr
    if ~isstruct(iStr)
        error( ...
            'xfigure:BadPropertyStruct', ...
            'Uimenu properties must be of type struct.' ...
        );
    end

    % perform some checks on struct
    iStr = checkstruct(iStr, xfigure_factory.optuim);
    if isempty(iStr.Caption)
        error( ...
            'xfigure:BadPropertyStruct', ...
            'Bad uimenu property struct supplied.' ...
        );
    end

    % get new OUID
    uuid = handlenew(xfigure_factory.objtypes.uimenu, xfig_ilup);
    dfcn = sprintf('xfigure(%0.0f,''Delete'');', uuid);

    % use tag from iStr?
    if ~isempty(iStr.Tag) && ...
        numel(iStr.Tag) < 28 && ...
        isrealvarname(iStr.Tag(:)')
        utag = iStr.Tag(:)';
    else
        iStr.Tag = sprintf('UIM_%010.0f', uuid);
        utag = ['xfigure_' iStr.Tag];
    end

    % accelerator
    if ~isempty(iStr.Accelerator)
        iStr.Accelerator = iStr.Accelerator(1);
    end

    % text color
    if numel(iStr.Color) == 1
        iStr.Color(1:3) = iStr.Color;
    elseif numel(iStr.Color) ~= 3
        iStr.Color = [0, 0, 0];
    end
    iCFG = max(0, min(1, iStr.Color));
    iPos  = iStr.Position;

    % any Enable-groups ?
    iGroups = splittocellc(iStr.EGroups, ',; ', true, true);
    for iGroupC = numel(iGroups):-1:1
        iGroup = deblank(iGroups{iGroupC});
        if isrealvarname(iGroup)
            if isfield(xfigures(ihFPos).figprops.egroups, iGroup)
                xfigures(ihFPos).figprops.egroups.(iGroup)(end + 1) = uuid;
            else
                xfigures(ihFPos).figprops.egroups.(iGroup) = uuid;
            end
        else
            iGroups(iGroupC) = [];
        end
    end
    iStr.EGroups = iGroups;

    % any Visible-groups (or pages)
    iGroups = splittocellc(iStr.VGroups, ',; ', true, true);
    for iGroupC = numel(iGroups):-1:1
        iGroup = deblank(iGroups{iGroupC});
        if isrealvarname(iGroup)
            if isfield(xfigures(ihFPos).figprops.vgroups, iGroup)
                xfigures(ihFPos).figprops.vgroups.(iGroup)(end + 1) = uuid;
            else
                xfigures(ihFPos).figprops.vgroups.(iGroup) = uuid;
            end
        else
            iGroups(iGroupC) = [];
        end
    end
    iStr.VGroups = iGroups;

    % prepare output structure
    oStr = struct( ...
        'Parent',          hFigMHnd, ...
        'Label',           iStr.Caption, ...
        'Accelerator',     iStr.Accelerator, ...
        'Callback',        iStr.Callback, ...
        'Checked',         iStr.Checked, ...
        'DeleteFcn',       dfcn, ...
        'Enable',          iStr.Enabled, ...
        'ForegroundColor', iCFG, ...
        'Separator',       iStr.Separator, ...
        'Tag',             utag, ...
        'UserData',        iStr.UserData, ...
        'Visible',         iStr.Visible);
    if ~isempty(iPos) && ...
       ~isnan(iPos(1)) && ...
       ~isinf(iPos(1))
        oStr.Position = fix(iPos(1));
    end

    % create object and fill/update fields as necessary
    hOut = uimenu(oStr);
    cout = xfigure(0, 'makeobj', ...
        uuid, hOut, xfigure_factory.objtypes.uimenu);

    % complete object representation
    oObj           = makeostruct(xfigure_factory.objtypes.uimenu);
    oObj.callbacks = {iStr.Callback, '', '', iStr.CallbackDelete};
    oObj.loadprops = iStr;
    oObj.prevprops = get(hOut);
    xfig_ilup(end + 1) = uuid;
    xfig_mlup(end + 1) = hOut;
    xfig_type(end + 1) = cout.type;
    xfigures(end + 1) = oObj;

    % finally, add to global tag lookup struct
    xfigure_factory.tags.(['UIM_' iStr.Tag]) = cout;

    % set handle visibility
    set(hOut, 'HandleVisibility', xfigure_factory.hvisible);

    % and return appropriate object
    varargout{1} = cout;


% bringing the selected window to the front
case {'bringtofront'}

    if hFigType
        try
            redrawfig(xfig_mlup(ihFPos));
            figure(xfig_mlup(ihFPos));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
    else
        error( ...
            'xfigure:InvalidObjectType', ...
            'BringToFront is not valid for the ROOT object.' ...
        );
    end


% creating a figure
case {'createfigure'}

    % only valid if parent is ROOT object
    if hFigType
        error( ...
            'xfigure:InvalidObjectType', ...
            'CreateFigure can only be used for the ROOT object.' ...
        );
    end

    % test iStr
    if ~isstruct(iStr)
        error( ...
            'xfigure:BadPropertyStruct', ...
            'Figure properties must be of type struct.' ...
        );
    end

    % perform some checks on struct but allow function handles
    icallbacks = {''};
    icallbacks(2:9) = icallbacks(1);
    if isfield(iStr, 'CallbackKey') && ...
        isa(iStr.CallbackKey, 'function_handle')
        icallbacks{5} = iStr.CallbackKey;
    end
    if isfield(iStr, 'CallbackMDown') && ...
        isa(iStr.CallbackMDown, 'function_handle')
        icallbacks{6} = iStr.CallbackMDown;
    end
    if isfield(iStr, 'CallbackMMove') && ...
        isa(iStr.CallbackMMove, 'function_handle')
        icallbacks{7} = iStr.CallbackMMove;
    end
    if isfield(iStr, 'CallbackMUp') && ...
        isa(iStr.CallbackMUp, 'function_handle')
        icallbacks{8} = iStr.CallbackMUp;
    end
    if isfield(iStr, 'CallbackResize') && ...
        isa(iStr.CallbackResize, 'function_handle')
        icallbacks{9} = iStr.CallbackResize;
    end
    iStr = checkstruct(iStr, xfigure_factory.optfig);
    if ~isempty(iStr.CallbackKey)
        icallbacks{5} = iStr.CallbackKey;
    end
    if ~isempty(iStr.CallbackMDown)
        icallbacks{6} = iStr.CallbackMDown;
    end
    if ~isempty(iStr.CallbackMMove)
        icallbacks{7} = iStr.CallbackMMove;
    end
    if ~isempty(iStr.CallbackMUp)
        icallbacks{8} = iStr.CallbackMUp;
    end
    if ~isempty(iStr.CallbackResize)
        icallbacks{9} = iStr.CallbackResize;
    end

    if numel(iStr.Position) ~= 4 || ...
       any(isnan(iStr.Position(:)) | isinf(iStr.Position(:)))
        error( ...
            'xfigure:BadPropertyStruct', ...
            'Bad figure property struct supplied.' ...
        );
    end

    % get new OUID
    uuid = handlenew(xfigure_factory.objtypes.figure, xfig_ilup);
    dfcn = sprintf('xfigure(%0.0f,''Delete'');', uuid);

    % use tag from iStr?
    if ~isempty(iStr.Tag) && ...
        numel(iStr.Tag) < 28 && ...
        isrealvarname(iStr.Tag(:)')
        utag = iStr.Tag(:)';
    else
        iStr.Tag = sprintf('FIG_%010.0f', uuid);
        utag = ['xfigure_' iStr.Tag];
    end

    % background color
    if numel(iStr.Color) == 1
        iCBG(1:3) = max(0, min(1, iStr.Color));
    elseif numel(iStr.Color) == 3
        iCBG = max(0, min(1, iStr.Color));
    else
        iCBG = [];
    end

    % close requestor
    if isempty(iStr.CallbackClReq)
        iStr.CallbackClReq = 'closereq;';
    end

    % context menu
    if ~isempty(iStr.ContextMenu)
        try
            uicm = findobj('Type', 'uicontextmenu', 'Tag', iStr.ContextMenu);
            if numel(uicm) ~= 1
                uicm = [];
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            uicm = [];
        end
        cbclick = [ ...
            sprintf('xfigure(xfigure,''setcontext'',%0.0f);', uuid) ...
            iStr.CallbackClick(:)'];
    else
        uicm = [];
        cbclick = iStr.CallbackClick(:)';
    end

    % set required options
    iPar = 0;
    iPos = iStr.Position;
    if all(iPos(1:2) == -1) && ...
        strcmpi(iStr.Units, 'pixels')
        iPos(1) = fix((xfigure_factory.units.pixels(3) - iPos(3)) / 2 + 0.5001);
        iPos(2) = fix((xfigure_factory.units.pixels(4) - iPos(4)) / 2 + 0.5001);
    end
    iPos(3:4) = max(0, iPos(3:4));
    if numel(iStr.MinSize) == 2 && ...
        all(iStr.MinSize > 0) && ...
       ~any(isnan(iStr.MinSize) | isinf(iStr.MinSize))
        iStr.MinSize = iStr.MinSize(:)';
    else
        iStr.MinSize = [];
    end

    % fill with those and other, fixed options
    oStr = struct( ...
        'Parent',                iPar, ...
        'Units',                 iStr.Units, ...
        'Position',              iPos, ...
        'BackingStore',          iStr.BackingStore, ...
        'ButtonDownFcn',         cbclick, ...
        'CloseRequestFcn',       iStr.CallbackClReq, ...
        'DeleteFcn',             dfcn, ...
        'DoubleBuffer',          iStr.DoubleBuffer, ...
        'IntegerHandle',         iStr.IntegerHandle, ...
        'Interruptible',         iStr.Interrupts, ...
        'InvertHardCopy',        iStr.PrintBW, ...
        'KeyPressFcn',           icallbacks{5}, ...
        'Menu',                  'none', ...
        'MenuBar',               iStr.MenuBar, ...
        'Name',                  iStr.Title, ...
        'NumberTitle',           'off', ...
        'PaperUnits',            iStr.PaperUnits, ...
        'PaperOrientation',      iStr.PaperOrientation, ...
        'PaperPosition',         iStr.PaperPosition, ...
        'PaperSize',             iStr.PaperSize, ...
        'PaperType',             iStr.PaperType, ...
        'Resize',                iStr.Resizeable, ...
        'ResizeFcn',             icallbacks{9}, ...
        'Tag',                   utag, ...
        'Toolbar',               'none', ...
        'UIContextMenu',         uicm, ...
        'UserData',              iStr.UserData, ...
        'Visible',               'off', ...
        'WindowButtonDownFcn',   icallbacks{6}, ...
        'WindowButtonMotionFcn', icallbacks{7}, ...
        'WindowButtonUpFcn',     icallbacks{8});
    if ~isempty(iCBG)
        oStr.Color = iCBG;
    end
    if ~strcmpi(iStr.Modal, 'on')
        oStr.WindowStyle = 'normal';
    else
        oStr.WindowStyle = 'modal';
    end

    % create figure and fill fields
    hOut = figure(oStr);
    cout = xfigure(0, 'makeobj', ...
        uuid, hOut, xfigure_factory.objtypes.figure);
    set(hOut, 'Position', iPos);

    % FieldLink requested
    if ~isempty(iStr.FieldLinkCont) && ...
       ~isempty(iStr.FieldLinkSpec)

        flcont = iStr.FieldLinkCont(:)';
        flspec = iStr.FieldLinkSpec(:)';

        % support for single content
        if ischar(flcont) && ...
           (exist(flcont, 'file') == 2 || ...
            strcmpi(flcont, '_auto'))
            if strcmpi(flcont, '_auto') && ...
                isfield(iStr, 'CFilename')
                [tgfpath, tgfname] = fileparts(iStr.CFilename);
                flcont = [tgfpath filesep tgfname '.ini'];
                if exist(flcont, 'file') ~= 2
                    warning( ...
                        'xfigure:FieldLinkFailed', ...
                        'Auto modus for FieldLinkCont failed.' ...
                    );
                    iStr.FieldLinkCont = [];
                    flcont = [];
                end
            end

            if ~isempty(flcont)
                flcont = xini(flcont, 'convert');
                flname = Filename(flcont);
                [trfpath{1:2}] = fileparts(flname);
                iStr.FieldLinkCont = struct(makelabel(trfpath{2}), flcont);
            end

        % input is already in struct format
        elseif isstruct(flcont)

            % make sure content is either a valid file or an xini object
            inis = fieldnames(flcont);
            for cc = numel(inis):-1:1
                if ischar(flcont.(inis{cc})) && ...
                    exist(flcont.(inis{cc}), 'file') == 2
                    iStr.FieldLinkCont.(inis{cc}) = ...
                        xini(flcont.(inis{cc}), 'convert');
                end
                if ~isxini(flcont.(inis{cc}), 1)
                    iStr.FieldLinkCont = rmfield(iStr.FieldLinkCont, inis{cc});
                end
            end

        % is it an xini handle ?
        elseif isxini(flcont, 1)
            [trfpath{1:2}] = fileparts(Filename(iStr.FieldLinkCont));
            iStr.FieldLinkCont = ...
                struct(makelabel(trfpath{2}), iStr.FieldLinkCont);

        % else set to empty array
        else
            iStr.FieldLinkCont = [];
        end

        % support for single specification file
        if ischar(flspec) && ...
           (exist(flspec, 'file') == 2 || ...
            strcmpi(flspec, '_auto'))
            if strcmpi(flspec, '_auto') && ...
                isfield(iStr, 'CFilename')
                [tgfpath, tgfname] = fileparts(iStr.CFilename);
                iStr.FieldLinkSpec = [tgfpath filesep tgfname '.fln'];
                if exist(iStr.FieldLinkSpec, 'file') ~= 2
                    warning( ...
                        'xfigure:FieldLinkFailed', ...
                        'Auto modus for FieldLinkSpec failed.' ...
                    );
                    iStr.FieldLinkSpec = {};
                end
            else
                iStr.FieldLinkSpec = {};
            end
            if ~isempty(iStr.FieldLinkSpec)
                iStr.FieldLinkSpec = ...
                    {xini(iStr.FieldLinkSpec, 'convert')};
            end

        % input is already in cell format
        elseif iscell(flspec)

            % make sure cell content is either a valid file or an xini object
            for cc = numel(flspec):-1:1
                if ischar(flspec{cc}) && ...
                    exist(flspec{cc},'file') == 2
                    iStr.FieldLinkSpec{cc} = ...
                        xini(iStr.FieldLinkSpec{cc}, 'convert');
                end
                if ~isxini(iStr.FieldLinkSpec{cc}, 1)
                    iStr.FieldLinkSpec(cc) = [];
                end
            end

        % even not ? then make an empty cell array
        else
            iStr.FieldLinkCont = [];
        end

        % check whether we still have content ?
        if isempty(iStr.FieldLinkCont) || ...
            isempty(iStr.FieldLinkSpec)
            iStr.FieldLinkCont = struct;
            iStr.FieldLinkSpec = {};
        end

        % find groups
        myLGroups = [];
        for cc = 1:numel(iStr.FieldLinkSpec)
            gnames = IniSections(iStr.FieldLinkSpec{cc});
            for gc=1:numel(gnames)
                fnames = IniSectionSettings(iStr.FieldLinkSpec{cc}, gnames{gc});
                myLGroups.(gnames{gc}) = {cc, fnames};
            end
        end
        iStr.FieldLinkGroups = myLGroups;

    % make sure fields are used well
    else
        iStr.FieldLinkCont   = struct;
        iStr.FieldLinkSpec   = {};
        iStr.FieldLinkGroups = [];
    end

    % fill additional internal object representation
    oObj           = makeostruct(xfigure_factory.objtypes.figure);
    oObj.callbacks = icallbacks;
    oObj.figprops(1).cpage = -2;
    oObj.figprops.egroups  = struct;
    oObj.figprops.lgroups  = iStr.FieldLinkGroups;
    oObj.figprops.lilookup = -1;
    oObj.figprops.linkcont = iStr.FieldLinkCont;
    oObj.figprops.linkspec = iStr.FieldLinkSpec;
    oObj.figprops.llookup  = 0;
    oObj.figprops.pages    = [];
    oObj.figprops.rgroups  = struct;
    oObj.figprops.rszuics  = {};
    oObj.figprops.sgroups  = struct;
    oObj.figprops.vgroups  = struct;
    oObj.loadprops = iStr;
    oObj.prevprops = get(hOut);
    xfig_ilup(end + 1) = uuid;
    xfig_mlup(end + 1) = hOut;
    xfig_type(end + 1) = cout.type;
    xfigures(end + 1) = oObj;

    % add to global tag lookup struct
    xfigure_factory.tags.(['FIG_' iStr.Tag]) = cout;

    % set correct visible state
    set(hOut, 'Visible', iStr.Visible);

    % return appropriate object
    varargout{1} = cout;


% creating a figure directly from file
case {'createfigurefromfile'}

    % only valid for the ROOT object
    if hFigType
        error( ...
            'xfigure:BadObjectType', ...
            'CreateFigureFromFile can only be used for the ROOT object.' ...
        );
    end

    % check filename
    if ~ischar(iStr) || ...
        exist(iStr(:)', 'file') ~= 2
        error( ...
            'xfigure:FileNotFound', ...
            'The specified figure file was not found.' ...
        );
    end
    tfgfile = iStr(:)';

    % input options
    if nargin < 4 || ...
       ~isstruct(varargin{4})
        figopts = struct;
        for vac = 4:nargin
            if ischar(varargin{vac}) && ...
                isrealvarname(varargin{vac})
                figopts.(varargin{vac}(:)') = true;
            end
        end
    else
        figopts = varargin{4};
    end

    % mat/figstruct file?
    if ~isfield(figopts, 'IsStruct') || ...
        isempty(figopts.IsStruct) || ...
       ~figopts.IsStruct(1)

        % read file and prepare options
        try
            fgstr = tfgparse(tfgfile);
        catch ne_eo;
            error( ...
                'xfigure:InvalidTFGFile', ...
                'The given file (%s) is no valid TFG file (%s).', ...
                tfgfile, ne_eo.message ...
            );
        end
    else
        try
            fgstr = load(iStr);
            if ~isfield(fgstr, 'TFG')
                error('INVALID_TFGMAT');
            end
            fgstr = fgstr.TFG;
            try
                if isfield(figopts, 'Evaluate') && ...
                    numel(figopts.Evaluate) == 1 && ...
                    islogical(figopts.Evaluate) && ...
                    figopts.Evaluate
                    fgstr = tfgparse(fgstr, struct('evaluate', true));
                end
            catch ne_eo;
                rethrow(ne_eo);
            end
        catch ne_eo;
            error( ...
                'xfigure:InvalidTFGMAT', ...
                'Error loading TFG struct file %s (%s).', ...
                tfgfile, ne_eo.message ...
            );
        end
    end
    if ~isstruct(fgstr) || ...
       ~isfield(fgstr, 'FIGURE') || ...
       ~isfield(fgstr, 'UICONTROLS') || ...
       ~isfield(fgstr, 'MENU') || ...
       ~isfield(fgstr, 'CONTEXTMENUS') || ...
       ~isstruct(fgstr.FIGURE) || ...
       ~isstruct(fgstr.UICONTROLS) || ...
       ~isstruct(fgstr.UIRESIZE) || ...
       ~isstruct(fgstr.MENU) || ...
       ~isstruct(fgstr.CONTEXTMENUS) || ...
        isempty(fgstr.FIGURE) || ...
       ~isfield(fgstr.FIGURE, 'Position') || ...
       ~isnumeric(fgstr.FIGURE.Position) || ...
        any(isnan(fgstr.FIGURE.Position)) || ...
        any(isinf(fgstr.FIGURE.Position)) || ...
        numel(fgstr.FIGURE.Position) ~= 4 || ...
       ~isfield(fgstr.UICONTROLS, 'Position') || ...
       ~isfield(fgstr.UICONTROLS, 'Type') || ...
       ~isfield(fgstr.UIRESIZE, 'Tag') || ...
       ~isfield(fgstr.UIRESIZE, 'Reference') || ...
       ~isfield(fgstr.UIRESIZE, 'RelPosition') || ...
       ~isfield(fgstr.MENU, 'Callback') || ...
       ~isfield(fgstr.MENU, 'Caption') || ...
       ~isfield(fgstr.MENU, 'Level') || ...
       ~isfield(fgstr.CONTEXTMENUS, 'IsCM') || ...
       ~isfield(fgstr.CONTEXTMENUS, 'Callback') || ...
       ~isfield(fgstr.CONTEXTMENUS, 'Caption') || ...
       ~isfield(fgstr.CONTEXTMENUS, 'Level') || ...
       ~isfield(fgstr.CONTEXTMENUS, 'Tag')
        error( ...
            'xfigure:BadTFGStruct', ...
            'Missing crucial information in TFG file (%s).', ...
            tfgfile ...
        );
    end

    % memorize visible flag, set to off during creation
    if isfield(fgstr.FIGURE,'Visible')
        nVisible = fgstr.FIGURE.Visible;
    else
        nVisible = 'on';
    end
    fgstr.FIGURE.Visible = 'off';

    % tell CreateFigure(...) what filename we've got
    fgstr.FIGURE.CFilename = tfgfile;

    % override FieldLink / FieldLinkIni / OnLoad from command line
    if isfield(figopts, 'FieldLinkCont')
        fgstr.FIGURE.FieldLinkCont = figopts.FieldLinkCont;
    end
    if isfield(figopts, 'FieldLinkSpec')
        fgstr.FIGURE.FieldLinkSpec = figopts.FieldLinkSpec;
    end
    if isfield(figopts, 'OnLoad')
        fgstr.FIGURE.OnLoad = figopts.OnLoad;
    end

    % create object and bark out on failure
    try
        cout = ...
            xfigure(xfigure_factory.I_ROOT, 'CreateFigure', fgstr.FIGURE);
        if ~isxfigure(cout, 1)
            error('INVALID_FIGURE_OBJECT');
        end
    catch ne_eo;
        error( ...
            'xfigure:CreateFigureFailed', ...
            'Figure creation failed: %s.', ...
            ne_eo.message ...
        );
    end

    % add all tags of figure to a struct if no UserData in figure
    if ~isfield(fgstr.FIGURE, 'UserData')
        UDTags = true;
        if isfield(fgstr.FIGURE, 'Tag') && ...
           isrealvarname(deblank(fgstr.FIGURE.Tag))
            UDTagStruct.(deblank(fgstr.FIGURE.Tag)) = cout;
        else
            UDTagStruct = struct;
        end
    else
        UDTags = false;
    end

    % process any uicontextmenus
    if size(fgstr.CONTEXTMENUS, 1)
        numCMenus = numel(fgstr.CONTEXTMENUS);
        lastCMenu = xfigure;

        % iterate over context menus
        for ncount = 1:numCMenus
            thisMenu = fgstr.CONTEXTMENUS(ncount);

            % uicontextmenu object
            if ~isempty(thisMenu.IsCM) && ...
                thisMenu.IsCM(1)
                try
                    lastCMenu(1:end) = [];
                    hCMenu = ...
                        xfigure(cout, 'AddUIContextMenu', thisMenu);
                    if ~isxfigure(hCMenu, 1)
                        error('INVALID_CONTEXTMENU');
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    warning( ...
                        'xfigure:BadPropertyStruct', ...
                        'Couldn''t add context menu to figure.' ...
                    );
                    continue;
                end
                lastCMenu(1) = hCMenu;

                % add tag to taglist (if OK)
                try
                    if UDTags && ...
                        isrealvarname(deblank(thisMenu.Tag))
                        UDTagStruct.(deblank(thisMenu.Tag)) = hCMenu;
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end

            elseif ~isempty(lastCMenu)
                % must have a Caption and no Comment
                if (isfield(thisMenu,'Comment') && ...
                   ~isempty(thisMenu.Comment)) || ...
                    isempty(thisMenu.Caption)
                    continue;
                end

                % handle UIMenu level
                hMCLevel = thisMenu.Level;
                if ischar(hMCLevel)
                    try
                        hMCLevel = str2double(hMCLevel);
                    catch ne_eo;
                        neuroelf_lasterr(ne_eo);
                        continue;
                    end
                elseif ~isnumeric(hMCLevel)
                    continue;
                end
                if isempty(hMCLevel) || ...
                    isnan(hMCLevel(1)) || ...
                    isinf(hMCLevel(1)) || ...
                    hMCLevel(1) < 1
                    continue;
                end
                hMCLevel = fix(hMCLevel(1));
                if hMCLevel > numel(lastCMenu)
                    continue;
                end

                % add UIMenu
                try
                    hMenuItem = ...
                        xfigure(lastCMenu(hMCLevel), 'AddUIMenu', thisMenu);
                    if ~isxfigure(hMenuItem, 1)
                        error('INVALID_MENUITEM');
                    end
                catch ne_eo;
                    warning( ...
                        'xfigure:BadPropertyStruct', ...
                        'Couldn''t add uimenu to context menu (%s).', ...
                        ne_eo.message ...
                    );
                    continue;
                end

                % set new parent menu level object for lower levels
                lastCMenu(hMCLevel + 1) = hMenuItem;

                % add tag to taglist (if OK)
                try
                    if UDTags && ...
                        isrealvarname(deblank(thisMenu.Tag))
                        UDTagStruct.(deblank(thisMenu.Tag)) = hMenuItem;
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
        end
    end

    % create resize info struct
    rszinfo = struct;
    rszused = false;
    for nrsz = 1:numel(fgstr.UIRESIZE)
        thisResz = fgstr.UIRESIZE(nrsz);
        if isvarname(thisResz.Tag) && ...
           (~isfield(thisResz, 'Comment') || ...
            isempty(thisResz.Comment))
            rszinfo.(thisResz.Tag) = thisResz;
        end
    end

    % add UIControls if any
    if size(fgstr.UICONTROLS, 1)
        numControls = numel(fgstr.UICONTROLS);

        % set relative Position to 0,0 -> 0,0
        lastCtrlPos = [0, 0, 0, 0];
        for ncount = 1:numControls
            thisCtrl = fgstr.UICONTROLS(ncount);

            % must have a Type and no Comment
            if numel(thisCtrl.Type) > 0 && ...
               (~isfield(thisCtrl,'Comment') || ...
                isempty(thisCtrl.Comment))
                try
                    % handle relative positioning
                    if all(thisCtrl.Position(3:4) == 0)
                        thisCtrl.Position = thisCtrl.Position + lastCtrlPos;
                    elseif any(thisCtrl.Position(3:4) < 0)
                        thisCtrl.Position(3:4) = abs(thisCtrl.Position(3:4));
                        if thisCtrl.Position(3) == 0
                            thisCtrl.Position(3) = lastCtrlPos(3);
                        elseif thisCtrl.Position(4) == 0
                            thisCtrl.Position(4) = lastCtrlPos(4);
                        end
                        thisCtrl.Position = ...
                            [thisCtrl.Position(1:2) + lastCtrlPos(1:2), ...
                             thisCtrl.Position(3:4)];
                    end

                    % add resize info if available
                    try
                        if isfield(thisCtrl, 'Tag') && ...
                           ~isempty(thisCtrl.Tag) && ...
                            isfield(rszinfo, thisCtrl.Tag)
                            thisCtrl.ResizeSpec = { ...
                                rszinfo.(thisCtrl.Tag).Reference,  ...
                                rszinfo.(thisCtrl.Tag).RelPosition ...
                            };
                            rszused = true;
                        end
                    catch ne_eo;
                        neuroelf_lasterr(ne_eo);
                    end

                    % add UIControl to figure
                    hControl = xfigure(cout, 'AddUIControl', thisCtrl);
                    if ~isxfigure(hControl, 1)
                        error('INVALID_UICONTROL');
                    end

                % if couldn't add control say so
                catch ne_eo;
                    warning( ...
                        'xfigure:BadPropertyStruct', ...
                        'Couldn''t add uicontrol to figure (%s).', ...
                        ne_eo.message ...
                    );
                    continue;
                end

                % remember last position
                lastCtrlPos = thisCtrl.Position;

                % add tag to taglist (if OK)
                try
                    if UDTags && ...
                        isrealvarname(deblank(thisCtrl.Tag))
                        UDTagStruct.(deblank(thisCtrl.Tag)) = hControl;
                    end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
        end
    end

    % add UIMenus if any
    if ~isempty(fgstr.MENU)
        numMenuLines = numel(fgstr.MENU);

        % setup parent objects array, parent for level 1 is figure !
        hMControl = cout;
        for mcount = 1:numMenuLines
            thisMenu = fgstr.MENU(mcount);

            % must have a Caption and no Comment
            if (isfield(thisMenu,'Comment') && ...
                ~isempty(thisMenu.Comment)) || ...
                isempty(thisMenu.Caption)
                continue;
            end

            % handle UIMenu level
            hMCLevel = thisMenu.Level;
            if ischar(hMCLevel)
                try
                    hMCLevel = str2double(hMCLevel);
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    continue;
                end
            elseif ~isnumeric(hMCLevel)
                continue;
            end
            if isempty(hMCLevel) || ...
                isnan(hMCLevel(1)) || ...
                isinf(hMCLevel(1)) || ...
                hMCLevel(1) < 1
                continue;
            end
            hMCLevel = fix(hMCLevel(1));
            if hMCLevel > numel(hMControl)
                continue;
            end

            % add UIMenu
            try
                hMenuItem = ...
                    xfigure(hMControl(hMCLevel), 'AddUIMenu', thisMenu);
                if ~isxfigure(hMenuItem, 1)
                    error('INVALID_MENUITEM');
                end
            catch ne_eo;
                warning( ...
                    'xfigure:BadPropertyStruct', ...
                    'Couldn''t add uimenu to figure (%s).', ...
                    ne_eo.message ...
                );
                continue;
            end

            % set new parent menu level object for lower levels
            hMControl(hMCLevel + 1) = hMenuItem;

            % add tag to taglist (if OK)
            try
                if UDTags && ...
                    isrealvarname(deblank(thisMenu.Tag))
                    UDTagStruct.(deblank(thisMenu.Tag)) = hMenuItem;
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end
    end

    % if no UserData given, fill with TagList
    if UDTags
        set(cout.mhnd, 'UserData', struct('xfigure_UDTagStruct', UDTagStruct));
    end

    % context menu requested in figure
    if isfield(fgstr.FIGURE, 'ContextMenu') && ...
       ~isempty(fgstr.FIGURE.ContextMenu) && ...
        ischar(fgstr.FIGURE.ContextMenu)
        if isfield(UDTagStruct, fgstr.FIGURE.ContextMenu(:)')
            try
                set(cout.hmnd, 'UIContextMenu', ...
                    UDTagStruct.(fgstr.FIGURE.ContextMenu(:)').mhnd);
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end
    end

    % is FieldLink feature enabled ?
    figmpos = xfigure(cout, 'matrixpos');
    if isstruct(xfigures(figmpos).figprops.lgroups)

        % should we initially load any field groups named in file
        if isfield(fgstr.FIGURE, 'LoadFields') && ...
            ischar(fgstr.FIGURE.LoadFields)
            lfg = fgstr.FIGURE.LoadFields(:)';
        else
            lfg = '';
        end

        % override with selection made on command line
        if isfield(figopts, 'LoadFields') && ...
            ischar(figopts.LoadFields)
            lfg = figopts.LoadFields(:)';
        end

        % lfg = 'on' ?
        if strcmpi(lfg, 'on')
            lfg = 'all_groups';
        end

        % are we supposed to load any field groups ?
        if ~isempty(lfg)
            try
                xfigure(cout, 'loadfields', lfg, false);
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end
    end

    % show any initial page from file ?
    if isfield(fgstr.FIGURE, 'Page')
        pgnum = fgstr.FIGURE.Page;
    else
        pgnum = 0;
    end

    % override with command line options
    if isfield(figopts, 'Page')
        pgnum = figopts.Page;
    end

    if ~isempty(pgnum) && ...
        isnumeric(pgnum) && ...
       ~isnan(pgnum(1)) && ...
       ~isinf(pgnum(1))
        pgnum = fix(pgnum(1));
    else
        pgnum = 0;
    end

    % if a page is requested then show it
    if pgnum > 0
        try
            xfigure(cout, 'showpage', pgnum);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
    end

    % enable resize if requested
    if rszused
        set(cout.mhnd, ...
            'Resize',    'on', ...
            'ResizeFcn', 'Resize(xfigure(gcf));' ...
        );
    end

    % OnLoad method in either figopts or file
    if isfield(fgstr.FIGURE,'OnLoad') && ...
        ischar(fgstr.FIGURE.OnLoad) && ...
       ~isempty(fgstr.FIGURE.OnLoad) && ...
        isempty(checksyntax(fgstr.FIGURE.OnLoad))
        try
            xfigurecallback(fgstr.FIGURE.OnLoad, cout.mhnd, cout.mhnd);
        catch ne_eo;
            warning( ...
                'xfigure:OnLoadError', ...
                'Error executing OnLoad figure property: %s.', ...
                ne_eo.message ...
            );
        end
    end

    % set memorized Visible flag
    if ~strcmpi(nVisible, 'off')
        set(cout.mhnd, 'Visible', 'on');
        figure(cout.mhnd);
        redrawfig(cout.mhnd);
    end

    % and return the appropriate object
    varargout{1} = cout;


% delete all figures
case {'deleteallfigures'}

    % we need all handles...
    shht = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');

    % find figures and delete them
    figs = findobj;

    % delete all but root
    set(figs(figs ~= 0), 'DeleteFcn', '');
    delete(findobj('type', 'figure'));

    % re-init arrays
    xfig_ilup(2:end) = [];
    xfig_mlup(2:end) = [];
    xfig_type(2:end) = [];
    xfigures(2:end)  = [];

    % set
    set(0, 'ShowHiddenHandles', shht);


% display information on object
case {'display'}

    % switch over type
    switch hFigType
        case {xfigure_factory.objtypes.root}
            lTyp = 'ROOT';
        case {xfigure_factory.objtypes.figure}
            lTyp = 'Figure';
        case {xfigure_factory.objtypes.uicontrol}
            lTyp = 'UIControl';
        case {xfigure_factory.objtypes.uimenu}
            lTyp = 'UIMenu';
        case {xfigure_factory.objtypes.uicontextmenu}
            lTyp = 'UIContextMenu';
        otherwise
            lTyp = 'UNKNOWN';
    end
    rqobj  = hFigMHnd;
    mentxt = '';

    % root object
    switch hFigType, case {xfigure_factory.objtypes.root}

        % prepare output string
        tgsc = '';

        % iterate over figures
        myfigures = find(xfig_type == xfigure_factory.objtypes.figure);
        for fc = 1:numel(myfigures)

            % get shortcut and test availability
            mylfigure = xfigures(myfigures(fc));
            if ~ishandle(xfig_mlup(myfigures(fc)))
                warning( ...
                    'xfigure:FigureDisappeared', ...
                    'Figure disappeared from class control.' ...
                )
                xfigure(xfig_ilup(myfigures(fc)), 'Delete');
                continue;
            end

            % get group names
            tt = ['  Groups of figure ''' mylfigure.loadprops.Title ...
                  ''' (figure no. ' num2str(fc) '):' char(10) char(10)];
            if isstruct(mylfigure.figprops.egroups)
                egs = fieldnames(mylfigure.figprops.egroups);
                egss = cell(1, numel(egs));
                for gc = 1:numel(egs)
                    egc  = mylfigure.figprops.egroups.(egs{gc});
                    luic = numel(intersect(egc, xfig_ilup .* ...
                           (xfig_type == ...
                            xfigure_factory.objtypes.uicontrol)));
                    luim = numel(intersect(egc, xfig_ilup .* ...
                           (xfig_type == ...
                            xfigure_factory.objtypes.uimenu)));
                    egss{gc} = sprintf('%40s: %d UIControls, %d UIMenus%s', ...
                                    egs{gc}, luic, luim, char(10));
                end
                ego = ['    EGroups:' char(10) char(10) gluetostring(egss, '')];
            else
                ego = '';
            end
            if isstruct(mylfigure.figprops.rgroups)
                rgs = fieldnames(mylfigure.figprops.rgroups);
                rgos = cell(1, numel(rgs));
                for gc = 1:numel(rgs)
                    rgc = mylfigure.figprops.rgroups.(rgs{gc});
                    rgos{gc} = sprintf('%40s: %d UIControls%s', ...
                                    rgs{gc}, numel(rgc), char(10));
                end
                rgo = ['    RGroups:' char(10) char(10) gluetostring(rgos, '')];
            else
                rgo = '';
            end
            if isstruct(mylfigure.figprops.sgroups)
                sgs = fieldnames(mylfigure.figprops.sgroups);
                sgos = cell(1, numel(sgs));
                for gc = 1:numel(sgs)
                    sgc = mylfigure.figprops.sgroups.(sgs{gc});
                    sgos{gc} = sprintf('%40s: %d UIControls%s', ...
                                    sgs{gc}, numel(sgc), char(10));
                end
                sgo = ['    SGroups:' char(10) char(10) gluetostring(sgos, '')];
            else
                sgo = '';
            end
            if isstruct(mylfigure.figprops.vgroups)
                vgs = fieldnames(mylfigure.figprops.vgroups);
                vgos = cell(1, numel(vgs));
                for gc = 1:numel(vgs)
                    vgc = mylfigure.figprops.vgroups.(vgs{gc});
                    vgos{gc} = sprintf('%40s: %d UIControls%s', ...
                                    vgs{gc}, numel(vgc), char(10));
                end
                vgo = ['    VGroups:' char(10) char(10) gluetostring(vgos, '')];
            else
                vgo = '';
            end

            % add figure output to list
            tgsc = sprintf('%s%s%s%s%s%s',tgsc, tt, ego, rgo, sgo, vgo);
        end

        % what tags are currently in use
        uto = ['  Tags for find used in xfigure base class:' char(10) char(10)];
        uts = fieldnames(xfigure_factory.tags);
        utss = cell(1, numel(uts));
        for utc = 1:numel(uts)
            utag = uts{utc};
            utt  = xfigure_factory.tags.(utag);
            uttt = utt.type + 1;
            if uttt > 0 && ...
                uttt < numel(xfigure_factory.objtypel)
                tlTyp = xfigure_factory.objtypel{uttt};
                if uttt > 1
                    utag = utag(5:end);
                end
            else
                tlTyp = 'xfigure_unknown_type';
            end
            utss{utc} = sprintf('%36s: tag of a subtype %s object%s', ...
                utag, tlTyp, char(10));
        end
        uto = [uto gluetostring(utss, '')];

        % format output with some other properties
        Props = sprintf([ ...
                    '    Figures         active:  %4.0f\n' ...
                    '    UIControls      active:  %4.0f\n' ...
                    '    UIMenus         active:  %4.0f\n' ...
                    '    UIContextMenus  active:  %4.0f\n' ...
                    '    xfigure Tags    active:  %4.0f\n' ...
                    '\n%s%s'], ...
                sum(xfig_type == xfigure_factory.objtypes.figure), ...
                sum(xfig_type == xfigure_factory.objtypes.uicontrol), ...
                sum(xfig_type == xfigure_factory.objtypes.uimenu), ...
                sum(xfig_type == xfigure_factory.objtypes.uicontextmenu), ...
                numel(fieldnames(xfigure_factory.tags)), ...
                tgsc, uto);

    % figures
    case {xfigure_factory.objtypes.figure}
        lProps = xfigure_factory.outfig;

    % uicontrols
    case {xfigure_factory.objtypes.uicontrol}
        lProps = xfigure_factory.outuic;
        if ~strcmpi(get(rqobj, 'Type'), 'uicontrol')
            rqobj  = get(rqobj, 'Children');
        end

    % uimenus
    case {xfigure_factory.objtypes.uimenu}
        lProps = xfigure_factory.outuim;
        mentxt = menutext(hFigMHnd);

    % uicontextmenus
    case {xfigure_factory.objtypes.uicontextmenu}
        lProps = xfigure_factory.outuix;
        mentxt = menutext(hFigMHnd);

    % otherwise raise an error
    otherwise
        error( ...
            'xfigure:InvalidObjectType', ...
            'Can''t display information for unknown object type.' ...
        );
    end

    % collection information for non-ROOT objects
    if hFigType
        fns    = fieldnames(lProps);
        Props  = sprintf([ ...
                 '%24s: %.8f\n', ...
                 '%24s: %.0f\n', ...
                 '%24s: %s\n\n'], ...
                 'MATLAB GUI handle', hFigMHnd, ...
                 'xfigure handle', hFigIHnd, ...
                 'Tag (OnLoad)', iObj.loadprops.Tag);
        for fnc = 1:numel(fns)
            pnow = [];
            for rqc = rqobj(:)'
                try
                    pnow = get(rqc, lProps.(fns{fnc}));
                    break;
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
            if (~ischar(pnow) || ...
                 numel(pnow) ~= numel(pnow)) && ...
                ~isempty(pnow)
                if any(strcmpi(class(pnow), ...
                    {'double', 'int16', 'int32', 'int64', 'int8', 'logical', ...
                     'single', 'uint16', 'uint32', 'uint64', 'uint8'})) && ...
                    numel(pnow) <= 8
                    pnow = any2ascii(pnow);
                elseif isa(pnow, 'function_handle')
                    pnow = sprintf('function handle: %s', func2str(pnow));
                else
                    psiz = sprintf('%.0fx', size(pnow));
                    pcls = class(pnow);
                    if isstruct(pnow)
                        pfld = sprintf(' with %.0f field(s)', numel(fieldnames(pnow)));
                    else
                        pfld = '';
                    end
                    pnow = sprintf('<%s %s%s>', psiz(1:end-1), pcls, pfld);
                end
            else
                pnow = pnow(:)';
            end
            if ~isempty(pnow)
                Props = sprintf('%s%24s: %s\n', Props, fns{fnc}, pnow);
            end
        end

        if ~isempty(mentxt)
            Props = [Props char(10) 'Menu tree:' char(10) mentxt];
        end
    end

    % display output to console
    disp(['xfigure object of type ' lTyp '. Properties:' char(10) Props]);


% run callback of UIControl subtype
case {'docallback'}
    if hFigType ~= xfigure_factory.objtypes.uicontrol
        warning( ...
            'xfigure:InvalidObjectType', ...
            'DoCallback is only valid for UIControls.' ...
        );
        return;
    end

    % get callback string and evaluate in base workspace
    cbstr = get(hFigMHnd, 'Callback');
    if ~isempty(cbstr)
        assignin('base', 'gcbf', mygcbf);
        assignin('base', 'gcbo', hFigMHnd);
        assignin('base', 'gcf',  mygcf);
        assignin('base', 'this',   hFigure);
        try
            evalin('base', cbstr);
            xfigures(ihPos).prevprops = get(hFigMHnd);
        catch ne_eo;
            warning( ...
                'xfigure:CallbackFailed', ...
                'Error executing UIControl callback: %s.', ...
                ne_eo.message ...
            );
        end
        evalin('base', 'clear gcbf gcbo gcf this;', '');
    end


% handling doubleclick events
case {'doubleclick'}
    if hFigType ~= xfigure_factory.objtypes.uicontrol
        warning( ...
            'xfigure:InvalidObjectType', ...
            'DoubleClick is only valid for UIControls.' ...
        );
        return;
    end

    % do nothing on empty callback list
    if isempty(iObj.callbacks)
        return;
    end

    % what callback should be processed
    docb = 1;
    if numel(iObj.callbacks) > 2 && ...
       ~isempty(iObj.callbacks{3})
        lastclick = iObj.timeclick;
        mynow     = now;
        drawnow;
        myvalue   = get(hFigMHnd, 'Value');
        xfigures(ihPos).timeclick = {mynow, myvalue};
        if ((mynow - lastclick{1}) <= (xfigure_factory.dblclickint) && ...
            isequal(myvalue, lastclick{2}))
            docb = 3;
        end
    end
    todocb = iObj.callbacks{docb};

    if ~isempty(todocb);
        assignin('base', 'gcbf', mygcbf);
        assignin('base', 'gcbo', hFigMHnd);
        assignin('base', 'gcf',  mygcf);
        assignin('base', 'this',   hFigure);
        try
            evalin('base', todocb);
            if docb == 1
                try
                    xfigures(ihPos).prevprops = get(hFigMHnd);
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
        catch ne_eo;
            warning( ...
                'xfigure:DoubleClickFailed', ...
                'Error executing UIControl callback #%.0f: %s.\n%s%s', ...
                docb, todocb, ...
                'Error message: ', ne_eo.message ...
            );
        end
        evalin('base', 'clear gcbf gcbo gcf this;', '');
    end


% finding (locating) an object with a tag
case {'find'}

    % we need valid input (Tag name)
    if ~isrealvarname(iStr)
        error( ...
            'xfigure:BadArgument', ...
            'FindObject requires a valid Tag argument.' ...
        );
    end

    if nargin == 3 || ...
       ~ischar(varargin{4})
        findtag = ['UIC_' iStr(:)'];
    else
        findtag = deblank(varargin{4}(:)');
        if isvarname(findtag)
            switch lower(iStr(:)')
            case {'c', 'uic', 'uicontrol'}
                findtag = ['UIC_' findtag];
            case {'f', 'fig', 'figure'}
                findtag = ['FIG_' findtag];
            case {'m', 'uim', 'uimenu'}
                findtag = ['UIM_' findtag];
            case {'x', 'uix', 'uicontextmenu'}
                findtag = ['UIX_' findtag];
            otherwise
                error( ...
                    'xfigure:BadArgument', ...
                    'Invalid search type: %s.', ...
                    iStr(:)' ...
                );
            end
        else
            error( ...
                'xfigure:BadArgument', ...
                'Invalid tag: %s.', ...
                varargin{4}(:)' ...
            );
        end
    end

    % try lookup
    try
        varargout{1} = xfigure_factory.tags.(findtag);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        warning( ...
            'xfigure:LookupFailed', ...
            'Lookup of Tag failed: %s.', ...
            findtag ...
        );
    end


% handling of context menu events
case {'getcontext'}

    % getting the current context menu object
    varargout{1} = xfigure_factory.contextobject;


% return logical button/checked state
case {'isactive'}
    if ~any([xfigure_factory.objtypes.uicontrol, ...
             xfigure_factory.objtypes.uimenu, ...
             xfigure_factory.objtypes.uicontextmenu] == hFigType)
         error( ...
             'xfigure:InvalidObject', ...
             'Call only valid for uicontrols, uimenus.' ...
         );
    end

    % preset output
    varargout{1} = false;
    try
        if hFigType == xfigure_factory.objtypes.uicontrol
            varargout{1} = isequal(get(hFigMHnd, 'Value'), get(hFigMHnd, 'Max'));
        else
            varargout{1} = strcmpi(get(hFigMHnd, 'Checked'), 'on');
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end


% return logical enabled state
case {'isenabled'}
    varargout{1} = true;
    try
        if ~strcmpi(get(hFigMHnd, 'Enable'), 'on')
            varargout{1} = false;
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end


% if we came til here, the object is valid
case {'isvalid'}
    varargout{1} = true;


% return logical visible state
case {'isvisible'}
    varargout{1} = true;
    try
        if ~strcmpi(get(hFigMHnd, 'Visible'), 'on')
            varargout{1} = false;
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end


% loading field contents from link
case {'loadfields'}

    % only valid for figures...
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'LoadFields is only valid for figures.' ...
        );
    end

    % group name(s)
    if nargin < 3 || ...
       ~ischar(iStr) || ...
        isempty(iStr)
        error( ...
            'xfigure:BadArgument', ...
            'LoadFields requires the fieldgroup(s) to be named.' ...
        );
    end

    % with callback
    if nargin < 4 || ...
       ~islogical(varargin{4}) || ...
        isempty(varargin{4}) || ...
        any(varargin{4})
        withcbs = true;
    else
        withcbs = false;
    end

    % link disabled
    if ~isstruct(iObj.lgroups)
        return;
    end

    % links not yet looked up
    if ~isstruct(iObj.lilookup)
        xfigure(hFigure, 'LookupFields');
        iObj = xfigures(ihPos);
    end

    % get shortcuts and group names from input
    lgroups  = iObj.figprops.lgroups;
    lilookup = iObj.figprops.lilookup;
    if strcmpi(iStr(:)', 'all_groups')
        fgnames = fieldnames(lgroups);
    else
        fgnames = splittocellc(deblank(iStr(:)'), ',; ', true, true);
    end

    % iterate over given group names
    for fgc = 1:numel(fgnames)

        % discard non-existing groups
        if ~isfield(lgroups, fgnames{fgc})
            continue;
        end

        % get group spec
        groupspec   = lgroups.(fgnames{fgc});
        uicfields   = groupspec{2};

        % iterate over uicontrols
        for fc = 1:numel(uicfields)

            % discard non-existing uicontrols
            if ~isfield(lilookup, uicfields{fc})
                continue;
            end

            % retrieve link information
            flink    = lilookup.(uicfields{fc});
            flinkuic = flink{3};

            % no longer available
            if ~isxfigure(flinkuic, 1)
                continue;
            end

            % perform load
            i_loadfield(flinkuic, flink{1:2}, withcbs);
        end
    end


% perform one-time field lookup
case {'lookupfields'}

    % only for figures...
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'LookupFields is only valid for figures.' ...
        );
    end

    % don't lookup twice !
    if isstruct(iObj.figprops.lilookup)
        return;
    end

    % make lilookup field an empty struct...
    xfigures(ihPos).figprops.lilookup = struct;

    % if the FieldLink feature isn't properly enabled return
    if ~isstruct(iObj.figprops.lgroups)
        return;
    end

    % go through all groups registered from FieldLinkSpec files
    groupname = fieldnames(iObj.figprops.lgroups);
    for gc = 1:numel(groupname)
        inispec = iObj.figprops.lgroups.(groupname{gc});
        specobj = iObj.figprops.linkspec{inispec{1}};

        % go through all UIC tag names in group
        specfield = inispec{2};
        for fc = 1:numel(specfield)
            speclab = deblank(specfield{fc});

            % unknown UIC Tag
            if ~isvarname(speclab) || ...
               ~isfield(xfigure_factory.tags,['UIC_' speclab])
                continue;
            end

            % get object and check whether it belongs to this figure
            uicobject = xfigure_factory.tags.(['UIC_' speclab]);
            if ~any(find(get(hFigMHnd, 'Children') == uicobject.mhnd))
                continue;
            end

            % get ini and test for availability
            try
                speccont = specobj.(groupname{gc}).(speclab);
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                speccont = {};
            end
            if ~iscell(speccont) || ...
                numel(speccont) < 2 || ...
               ~iscell(speccont{1}) || ...
               ~iscell(speccont{2})
                warning( ...
                    'xfigure:BadLinkSpec', ...
                    'Link spec too short for UIControl (%s).', ...
                    speclab ...
                );
                continue;
            end

            % try to resolve link
            speclink = speccont{1};
            if ~isfield(iObj.figprops.linkcont, speclink{1})
                continue;
            end
            inicont = iObj.figprops.linkcont.(speclink{1});
            try
                eval('inicont.(speclink{2}).(speclink{3});');
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                continue;
            end

            % combine link target and store it
            linktarget = {{inicont, speclink{2:3}}, speccont{2}, uicobject};
            xfigures(ihPos).figprops.lilookup.(speclab) = linktarget;
        end
    end


% for internal use
case {'matrixpos'}
    varargout{1} = ihPos;


% deleting part of a multi-lined UIControl's content
case {'mdelete'}

    % only valid for dropdown or listbox uicontrols
    if hFigType ~= xfigure_factory.objtypes.uicontrol || ...
       ~any(strcmpi(iObj.prevprops.Style, {'popupmenu', 'listbox'}))
        error( ...
            'xfigure:InvalidObjectType', ...
            'MDelete is only valid for DropDown or ListBox UIControls.' ...
        );
    end

    % require numeric requests
    if isempty(iStr) || ...
       ~isnumeric(iStr)
        error( ...
            'xfigure:BadArgument', ...
            'MDelete requires a numeric argument.' ...
        );
    end

    % get current content and make sure it's a cell array
    tstring = get(hFigMHnd, 'String');
    if ~iscell(tstring)
        tstring = cellstr(tstring);
        waschar = true;
    else
        waschar = false;
    end
    tsize = numel(tstring);
    iStr  = fix(iStr(:)');

    % no outofbounds, please
    iStr(iStr < 1 | iStr > tsize | isnan(iStr) | isinf(iStr)) = [];
    if isempty(iStr)
        return;
    end

    % delete requested items and set selection accordingly
    for cc = length(iStr):-1:1
        tstring(iStr(cc)) = [];
    end
    if strcmpi(iObj.prevprops.Style, 'listbox') && ...
       get(hFigMHnd, 'Max') > (get(hFigMHnd, 'Min') + 1)
        tvalue = intersect(get(hFigMHnd, 'Value'), (1:length(tstring)));
        if isempty(tvalue) && ...
            numel(tstring) > 0
            tvalue = length(tstring);
        end
    else
        if numel(tstring) > 0
            tvalue = max(1, min(length(tstring), iStr(1)));
        else
            tvalue = [];
        end
    end

    % convert and set string and value
    if waschar
        tstring = char(tstring);
    end
    set(hFigMHnd, 'String', tstring, 'Value', tvalue);


% moving a subselection up or down the list
case {'mmove'}

    % only valid for dropdown or listbox uicontrols
    if hFigType ~= xfigure_factory.objtypes.uicontrol || ...
       ~any(strcmpi(iObj.prevprops.Style, {'popupmenu', 'listbox'}))
        error( ...
            'xfigure:InvalidObjectType', ...
            'MMove is only valid for DropDown or ListBox UIControls.' ...
        );
    end

    % check input arguments
    if isempty(iStr) || ...
       ~isnumeric(iStr) || ...
        fix(iStr(1)) == 0
        error( ...
            'xfigure:BadArgument', ...
            'MMove requires a numeric argument.' ...
        );
    end

    % what to do
    if nargin > 3 && ...
        isnumeric(varargin{4}) && ...
       ~isempty(varargin{4})
        mindex  = sort(varargin{4});
        msource = false;
    else
        mindex  = sort(get(hFigMHnd, 'Value'));
        msource = true;
    end

    % get current content
    tstring = get(hFigMHnd, 'String');
    if ~iscell(tstring)
        tstring = cellstr(tstring);
        waschar = true;
    else
        waschar = false;
    end
    tlength = length(tstring);
    iStr    = fix(iStr(:)');

    % make sure selection is valid
    mindex(mindex < 1 | mindex > tlength | isnan(mindex) | isinf(mindex)) = [];
    if isempty(mindex)
        return;
    end
    mlength = length(mindex);

    % where to move selection
    moveto = iStr(1);

    % prepare target array and selection
    tgstring = {};
    tindex   = mindex + moveto;
    while any(tindex < 1)
        tindex = tindex + 1;
    end
    while any(tindex > tlength)
        tindex = tindex-1;
    end
    if all(tindex == mindex)
        return;
    end

    % what remains without moved strings
    rindex = setdiff(1:tlength, mindex(:)');
    oindex = setdiff(1:tlength, tindex(:)');
    rlength = length(rindex);

    % compile and convert new array, set value
    tgstring(oindex(1:rlength)) = tstring(rindex(1:rlength));
    tgstring(tindex(1:mlength)) = tstring(mindex(1:mlength));
    if waschar
        tgstring = char(tgstring);
    end
    set(hFigMHnd, 'String', tgstring);
    if msource
        set(hFigMHnd, 'Value', tindex);
    end


% looking up a multi-lined UIControl's list size
case {'msize'}

    % only valid for dropdown or listbox uicontrols
    if hFigType ~= xfigure_factory.objtypes.uicontrol || ...
       ~any(strcmpi(iObj.prevprops.Style, {'popupmenu', 'listbox'}))
        error( ...
            'xfigure:InvalidObjectType', ...
            'MSize is only valid for DropDown or ListBox UIControls.' ...
        );
    end

    % get correct length
    tstring = get(hFigMHnd, 'String');
    if iscell(tstring)
        varargout{1} = length(tstring);
    else
        varargout{1} = size(tstring, 1);
    end


% returning or setting a multi-lined UIControl's string property
case {'mstring'}

    % only valid for dropdown or listbox uicontrols
    if hFigType ~= xfigure_factory.objtypes.uicontrol || ...
       ~any(strcmpi(iObj.prevprops.Style, {'popupmenu', 'listbox'}))
        error( ...
            'xfigure:InvalidObjectType', ...
            'MString is only valid for DropDown or ListBox UIControls.' ...
        );
    end

    % which strings to insert where
    if nargin < 3 || ...
       ~isnumeric(iStr) || ...
        isempty(iStr) || ...
        any(isnan(iStr))
        if nargin < 3
            positions = get(hFigMHnd, 'Value');
        elseif ischar(iStr)
            positions = get(hFigMHnd, 'Value');
            if isempty(positions)
                positions = 1;
            end
        elseif iscell(iStr)
            positions = ones(1, numel(iStr)) * Inf;
        else
            error( ...
                'xfigure:BadArgument', ...
                'First argument to MString must either be pos or setstr.' ...
            );
        end
        if iscell(iStr)
            istring = iStr(:)';
        elseif ischar(iStr)
            istring = cellstr(iStr);
        else
            istring = {};
        end
    else
        positions = fix(iStr(:)');
        if nargin > 3 && ...
           (iscell(varargin{4}) || ...
            ischar(varargin{4}))
            istring = varargin{4};
            if iscell(istring)
                istring = istring(:)';
            else
                istring = cellstr(istring);
            end
        else
            istring = {};
        end
    end

    % get current string
    rstring = get(hFigMHnd, 'String');
    if ~iscell(rstring)
        if ~isempty(rstring)
            rstring = cellstr(rstring);
        else
            rstring = {};
        end
        waschar = true;
    else
        waschar = false;
    end
    rsize = numel(rstring);

    % no insertion
    if isempty(istring)
        positions(positions < 1 | positions > rsize) = [];
        varargout{1} = rstring(positions);
        if length(positions) == 1
            varargout{1} = varargout{1}{1};
        end

    % check for insertion
    else
        if (islogical(varargin{nargin}) || ...
            isnumeric(varargin{nargin})) && ...
           ~isempty(varargin{nargin}) && ...
            varargin{nargin}(1)
            doinsert = true;
            positions(positions > rsize) = rsize + 1;
        else
            doinsert = false;
            positions(positions < 1 | positions > rsize) = [];
        end
        isize = numel(istring);
        psize = numel(positions);

        if ~doinsert
            icount = 1;
            while icount <= isize && ...
                icount <= psize
                rstring(positions(icount)) = istring(icount);
                icount = icount + 1;
            end

        else
            icount = min(isize, psize);
            for icount = icount:-1:1
                if isempty(rstring)
                    rstring = istring(icount);
                else
                    tpos = positions(icount);
                    if tpos < 2
                        rstring = [istring(icount); rstring];
                    elseif tpos > length(rstring)
                        rstring = [rstring; istring(icount)];
                    else
                        rstring = [rstring(1:(tpos-1)); ...
                                   istring(icount); ...
                                   rstring(tpos:end)];
                    end
                end
            end
            tposition = max(min([positions, length(rstring)]), 1);
        end

        for cc = 1:length(rstring)
            if isempty(rstring{cc})
                rstring{cc} = '';
            end
        end

        % conversion
        if waschar
            rstring = char(rstring);
        end

        % set string and value
        if doinsert
            set(hFigMHnd, 'String', rstring, 'Value', tposition);
        else
            set(hFigMHnd, 'String', rstring);
        end
    end


% previous properties
case {'parentobj'}

    % for figures
    if hFigType == xfigure_factory.objtypes.figure
        varargout{1} = xfigure_factory.I_ROOT;
    else
        try
            pl = find(xfig_mlup == get(hFigMHnd, 'Parent'));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xfigure:ObjectDisappeared', ...
                'The matlab UI object is no longer available.' ...
            );
        end
        varargout{1} = ...
            xfigure(0, 'makeobj', xfig_ilup(pl), xfig_ilup(pl), xfig_ilup(pl));
    end


% previous properties
case {'prevprops'}

    % only valid for uicontrol objects
    if hFigType ~= xfigure_factory.objtypes.uicontrol
        warning( ...
            'xfigure:InvalidObjectType', ...
            'PrevProps only valid for UIControl objects.' ...
        );
    end
    varargout{1} = iObj.prevprops;


% what radio groups do we have ?
case {'radiogroups'}

    % only for figures
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'RadioGroups is only valid for figures.' ...
        );
    end

    % return radio groups
    varargout{1} = iObj.figprops.rgroups;


% update radiogroup
case {'radiogroupsetone'}

    % only valid for figures and uicontrols
    if ~any([xfigure_factory.objtypes.figure, ...
             xfigure_factory.objtypes.uicontrol] == hFigType)
        error( ...
            'xfigure:InvalidObjectType', ...
            'RadioGroupSetOne is only valid for UIControls and figures.' ...
        );
    end

    % for uicontrols, check Style property
    if hFigType == xfigure_factory.objtypes.uicontrol && ...
       ~strcmpi(get(hFigMHnd, 'Style'), 'radiobutton')
        error( ...
            'xfigure:InvalidObjectType', ...
            'RadioGroupSetOne is only vali for RadioButton UIControls.' ...
        );
    end

    % get correct radio group list
    if hFigType == xfigure_factory.objtypes.figure
        rgroups = iObj.figprops.rgroups;
    else
        rgroups = iFObj.figprops.rgroups;
    end

    % any radiogroups defined
    if isempty(fieldnames(rgroups))
        return;
    end

    % for uicontrols
    if hFigType == xfigure_factory.objtypes.uicontrol
        myrgroup = iObj.loadprops.RGroup;
        if isempty(myrgroup)
            return;
        end
        if ~isfield(rgroups, myrgroup)
            error( ...
                'xfigure:RadioGroupInvalid', ...
                'The RadioButtonGroup %s is not defined in this figure.', ...
                myrgroup ...
            );
        end

        controls = rgroups.(myrgroup);
        for ctc = 1:length(controls)
            ctp = find(xfig_ilup == controls(ctc));
            if ~isempty(ctp)
                cth = xfig_mlup(ctp);
                try
                    set(cth, 'Value', get(cth, 'Min'));
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
        end
        try
            set(hFigMHnd, 'Value', get(hFigMHnd, 'Max'));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % for figures
    else
        if nargin < 4 || ...
           ~isvarname(deblank(iStr(:)')) || ...
           ~isnumeric(varargin{4}) || ...
            isempty(varargin{4}) || ...
            isnan(varargin{4}(1)) || ...
            isinf(varargin{4}(1))
            error( ...
                'xfigure:BadArgument', ...
                'For figures RadioGroupSetOne requires a group and button ID.' ...
            );
        end
        dogroup = deblank(iStr(:)');

        if ~isfield(rgroups, dogroup)
            error( ...
                'xfigure:RadioGroupInvalid', ...
                'The RadioButtonGroup %s is not defined in this figure.', ...
                dogroup ...
            );
        end
        controls = rgroups.(dogroup);
        actbutton = fix(varargin{4}(1));
        if actbutton < 1 || ...
            actbutton > numel(controls)
            error( ...
                'xfigure:BadArgument', ...
                'The RadioButtonGroup doesn''t have a button #%s.', ...
                num2str(actbutton) ...
            );
        end

        for ctc = 1:numel(controls)
            ctp = find(xfig_ilup == controls(ctc));
            if ~isempty(ctp)
                cth = xfig_mlup(ctp);
                try
                   if ctc ~= actbutton
                       set(cth, 'Value', get(cth, 'Min'));
                   else
                       set(cth, 'Value', get(cth, 'Max'));
                   end
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
        end
    end


% redrawing of a figure (via figure or UIControl object)
case {'redraw', 'refresh'}

    % for figures
    if hFigType == xfigure_factory.objtypes.figure
        redrawfig(hFigMHnd);

    % for non root objects
    elseif hFigType
        redrawfig(iFObj.mlhandle);

    % give an error for the root object
    else
        error( ...
            'xfigure:InvalidObjectType', ...
            'Redraw is only valid for non-root objects.' ...
        );
    end


% handling CallbackResize events
case {'resize'}

    % for figures
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'Resize is only available for figures.' ...
        );
    end

    % build resize tree
    rszuics = iObj.figprops.rszuics;
    if isempty(rszuics)
        return;
    end
    rsztree = struct;
    for cc = length(rszuics):-1:1
        uobj = rszuics{cc};

        % find matrix position
        upos = find(xfig_ilup == uobj.ihnd);

        % remove no longer existant children
        if isempty(upos)
            xfigures(ihPos).figprops.rszuics(cc) = [];
            continue;
        end
        upos = upos(1);

        % get resize spec
        iprop = xfigures(upos).loadprops;
        rspec = iprop.ResizeSpec;
        utag  = iprop.Tag;
        uhnd  = xfigure(0, 'makeobj', ...
            xfig_ilup(upos), xfig_mlup(upos), xfig_type(upos));

        % try to lookup uicontrol
        try
            robj = xfigure(rspec{1});
            if ~isxfigure(robj, 1) || ...
               ~any([xfigure_factory.objtypes.figure, ...
                     xfigure_factory.objtypes.uicontrol] == robj.type)
                error('INVALID_RESIZE_SPEC');
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            continue;
        end

        % set this as reference
        rsztree.(utag) = [rspec(:); {robj}; {uhnd}];
    end

    % check tree for self references, build a relation tree and an ordered list
    rsdtree = struct;
    telems = fieldnames(rsztree);
    while ~isempty(telems)
        telem = telems{1};
        telems(1) = [];
        chain = {telem};
        celem = rsztree.(telem){1};
        while isfield(rsztree, celem)
            if any(strcmp(chain, celem))
                error( ...
                    'xfigure:ResizeChain', ...
                    'Invalid ResizeSpec given. No chaining may occur.' ...
                );
            end
            chain(end + 1) = {celem};
            telems(strcmp(telems, celem)) = [];
            celem = rsztree.(celem){1};
        end
        chain(end + 1) = {celem};
        gchain = gluetostring(chain(end:-1:1), '.');
        try
            eval(['rsdtree.' gchain '=struct;']);
        catch ne_eo;
            error( ...
                'xfigure:IllegalResizeChain', ...
                'Illegal tag(s) in resize chain found (%s).', ...
                ne_eo.message ...
            );
        end
    end
    chain = treeorder(rsdtree);
    if ~isempty(iObj.loadprops.Tag)
        rsztree.(iObj.loadprops.Tag) = {};
    end

    % get new size until it is fixed
    tsize = get(hFigMHnd, 'Position');
    pause(0.1);
    nsize = get(hFigMHnd, 'Position');
    while ~all(tsize == nsize)
        pause(0.05);
        tsize = nsize;
        nsize = get(hFigMHnd, 'Position');
    end
    if ~isempty(iFObj.loadprops.MinSize)
        nsize(3:4) = max(nsize(3:4), iFObj.loadprops.MinSize);
        if ~all(tsize == nsize)
            if nsize(4) > tsize(4)
                nsize(2) = nsize(2) - (nsize(4) - tsize(4));
            end
            set(hFigMHnd, 'Position', nsize);
        end
    end

    % now the position is fixed and we can start resizing
    for rc = 1:length(chain)
        rszelem = rsztree.(chain{rc});
        if length(rszelem) ~= 4
            continue;
        end
        rszrpos = rszelem{2};
        rszrobj = rszelem{3};
        rszrtyp = rszrobj.type;
        rsztobj = rszelem{4};
        switch (rszrtyp)
            case {xfigure_factory.objtypes.figure}
                rsize = nsize;
                rpoint = rszrpos(1:2) .* rsize(3:4) + rszrpos(5:6);
            case {xfigure_factory.objtypes.uicontrol}
                try
                    rsize = xfigure(rszrobj, 'Get', 'Position');
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    continue;
                end
                rpoint = rsize(1:2) + rszrpos(1:2) .* rsize(3:4) + rszrpos(5:6);
            otherwise
                warning( ...
                    'xfigure:BadRefObjectType', ...
                    'Controls can only be dependent on figures or controls.' ...
                );
                continue;
        end

        tgtpos = [rpoint, 0, 0];
        for pc = [3, 4]
            xpc = pc + 4;
            switch (rszrpos(pc)), case {0}
                tgtpos(pc) = rszrpos(xpc);
            case {1}
                tgtpos(pc) = rszrpos(xpc) + rsize(pc);
            case {2}
                tgtpos(pc) = rszrpos(xpc) * rsize(pc);
            case {3}
                tgtpos(pc) = rszrpos(xpc) * nsize(pc);
            otherwise
                warning( ...
                    'xfigure:BadRefPosType', ...
                    'Bad positioning type: %g.', ...
                    rszrpos(pc) ...
                );
                continue;
            end
        end
        try
            xfigure(rsztobj, 'Set', 'Position', tgtpos);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
    end


% handling radiobutton click events
case {'rgroupclick'}

    % only valid for uicontrols
    if hFigType ~= xfigure_factory.objtypes.uicontrol || ...
       ~strcmpi(get(hFigMHnd, 'Type'), 'uicontrol') || ...
       ~strcmpi(get(hFigMHnd, 'Style'), 'radiobutton')
        error( ...
            'xfigure:InvalidObjectType', ...
            'The RadioButtonClick event is only valid for RadioButtons.' ...
        );
    end

    % set all other buttons to off first !
    xfigure(hFigure, 'RadioGroupSetOne');

    % no further callback named -> return
    if isempty(iObj.callbacks) || ...
        isempty(iObj.callbacks{1})
        return;
    end

    % do callback
    xfigurecallback(iObj.callbacks{1}, ...
        xfig_mlup(ihFPos), xfig_mlup(ihPos), true);


% storing state of fields into xini object
case {'savefields'}

    % only valid for figures and uicontrols
    if ~any([xfigure_factory.objtypes.figure, ...
             xfigure_factory.objtypes.uicontrol] == hFigType)
        error( ...
            'xfigure:InvalidObjectType', ...
            'SaveFields is only valid for figures or UIControls.' ...
        );
    end

    % get correct object
    if hFigType == xfigure_factory.objtypes.figure
        rObj = iObj;
    else
        rObj = iFObj;
    end

    % any linked fields
    if ~isstruct(rObj.lilookup) || ...
        isempty(fieldnames(rObj.lilookup))
        return;
    end

    % update fields to xini first
    usuccess = true;
    if ischar(iStr) || ...
        iscell(iStr)
        usuccess = xfigure(rObj.handle, 'updatefields', iStr);
    end

    % then write the files back to disk
    contfiles = fieldnames(rObj.linkcont);
    for fc = 1:length(contfiles)
        ifile = rObj.linkcont.(contfiles{fc});
        try
            if exist(Filename(ifile), 'file') == 2
                WriteIniFile(ifile);
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            usuccess = false;
        end
    end

    % report result
    varargout{1} = usuccess;


% handling of context menu events
case {'setcontext'}

    if nargin < 3 || ...
        isempty(varargin{3}) || ...
       ~any(strcmpi(class(varargin{3}), {'xfigure', 'double'}))
        error( ...
            'xfigure:BadArgument', ...
            'Setting the context menu object requires more input.' ...
        );
    end
    hCMObj = varargin{3}(1);

    % possible GUI handle
    if isa(hCMObj, 'double')

        % is it a handle at all
        if ~ishandle(hCMObj)
            error( ...
                'xfigure:BadArgument', ...
                'Illegal GUI handle passed as reference.' ...
            );
        end

        % context menu property OK?
        try
            ttype = lower(get(hCMObj, 'Type'));
            if ~isfield(xfigure_factory.uixtypes, ttype)
                error('BAD_OBJECT_TYPE');
            end
            testcm = get(hCMObj, 'UIContextMenu');

            % only set if there is a context menu!
            if isempty(testcm)
                return;
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xfigure:BadArgument', ...
                'Illegal GUI handle passed as reference.' ...
            );
        end

        % try looking up object
        hlup = find(xfig_mlup == hCMObj);
        if isempty(hlup)
            error( ...
                'xfigure:LookupFailed', ...
                'Requested object is not under xfigure control.' ...
            );
        end

        % set object
        xfigure_factory.contextobject = xfigure(0, 'makeobj', ...
            xfig_ilup(hlup(1)), ...
            xfig_mlup(hlup(1)), ...
            xfig_type(hlup(1)));

    % xfigure object
    else

        % is this a valid handle
        if ~isxfigure(hCMObj, 1) || ...
           ~any([xfigure_factory.objtypes.figure, ...
                 xfigure_factory.objtypes.uicontrol] == hCMObj.type)
            error( ...
                'xfigure:BadArgument', ...
                'Illegal xfigure handle passed as reference.' ...
            );
        end

        % return on empty context menu
        try
            testcm = get(hCMObj.mhnd, 'UIContextMenu');
            if isempty(testcm)
                return;
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xfigure:BadArgument', ...
                'Illegal xfigure handle passed as reference.' ...
            );
        end

        % set object
        xfigure_factory.contextobject = hCMObj;
    end


% setting a group of uicontrols/uimenus to enabled/disabled
case {'setgroupenabled'}

    % only valid for figures
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'SetGroupEnabled is only valid for figures.' ...
        );
    end

    % check group spec
    if ~ischar(iStr) || ...
        isempty(iStr(:))
        error( ...
            'xfigure:InvalidObjectType', ...
            'SetGroupEnabled requires a valid group name.' ...
        );
    end
    dogroup = deblank(iStr(:)');
    enamode = 'on';

    % determine target mode
    if nargin > 3 && ...
       ~isempty(varargin{4})
        if (((isnumeric(varargin{4}) || ...
              islogical(varargin{4})) && ...
            ~varargin{4}(1)) || ...
            (ischar(varargin{4}) && ...
             strcmpi(varargin{4}, 'off')))
            enamode = 'off';
        elseif isnumeric(varargin{4}) && ...
           (ishandle(varargin{4}(1)) || ...
            ishandle(-varargin{4}(1)))
            if varargin{4} < 0
                isnegated = true;
                varargin{4} = -varargin{4}(1);
            else
                isnegated = false;
                varargin{4} =  varargin{4}(1);
            end
            try
                tHnd = xfigure(varargin{4});
                if isxfigure(tHnd, 1)
                    vls = subget(tHnd.mhnd, {'Value', 'Min', 'Max'});
                    if vls.Value ~= vls.Max && ...
                        isnegated
                        enamode = 'off';
                    end
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end
    end

    % all groups ?
    if strcmpi(dogroup, 'all_groups')
        gnames = fieldnames(iObj.egroups);
        for gc = 1:length(gnames)
            xfigure(hFigure, 'SetGroupEnabled', gnames{gc}, enamode);
        end
        return;
    elseif any(dogroup == ';' | dogroup == ',' | dogroup == ' ')
        gnames = splittocellc(dogroup, ';, ', true, true);
        for gc = 1:length(gnames)
            if isvarname(gnames{gc})
                xfigure(hFigure, 'SetGroupEnabled', gnames{gc}, enamode);
            end
        end
        return;
    elseif ~isvarname(deblank(dogroup))
        error( ...
            'xfigure:InvalidObjectType', ...
            'SetGroupEnabled requires a valid group name.' ...
        );
    end

    % single group
    if isfield(iObj.figprops.egroups, dogroup)
        hdls = iObj.figprops.egroups.(dogroup);
        for hc = 1:length(hdls)
            oHdln = find(xfig_ilup == hdls(hc));
            if ~isempty(oHdln)
                xfigure(xfig_ilup(oHdln(1)), ...
                    'Set', 'Enable', enamode);
            end
        end
    end

    % refresh graphics
    if ischar(varargin{nargin}) && ...
        strcmpi(varargin{nargin}, 'refresh')
        redrawfig(hFigMHnd);
    end


% setting a group of uicontrols/uimenus visible/invisible
case {'setgroupvisible'}

    % only valid for figures
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'SetGroupVisible is only valid for figures.' ...
        );
    end

    % check group spec
    if ~ischar(iStr) || ...
        isempty(iStr(:))
        error( ...
            'xfigure:InvalidObjectType', ...
            'SetGroupVisible requires a valid group name.' ...
        );
    end
    dogroup = deblank(iStr(:)');
    vismode = 'on';

    % determine target vis mode
    if nargin > 3 && ...
      ((isnumeric(varargin{4}) && ...
       ~varargin{4}(1)) || ...
       (ischar(varargin{4}) && ...
        strcmpi(varargin{4}, 'off')))
        vismode = 'off';
    end

    % all groups ?
    if strcmpi(dogroup, 'all_groups')
        gnames = fieldnames(iObj.figprops.vgroups);
        for gc = 1:length(gnames)
            xfigure(hFigure, 'SetGroupVisible', gnames{gc}, vismode);
        end
        return;
    elseif any(dogroup == ';' | dogroup == ',' | dogroup == ' ')
        gnames = splittocellc(dogroup, ';, ', true, true);
        for gc = 1:length(gnames)
            if isvarname(gnames{gc})
                xfigure(hFigure, 'SetGroupVisible', gnames{gc}, vismode);
            end
        end
        return;
    elseif ~isvarname(dogroup)
        error( ...
            'xfigure:InvalidObjectType', ...
            'SetGroupVisible requires a valid group name.' ...
        );
    end

    % single group
    if isfield(iObj.figprops.vgroups, dogroup)
        hdls = iObj.figprops.vgroups.(dogroup);
        for hc = 1:length(hdls)
            oHdln = find(xfig_ilup == hdls(hc));
            if ~isempty(oHdln)
                xfigure(xfig_ilup(oHdln(1)), ...
                           'Set', 'Visible', vismode);
            end
        end
    end

    % refresh graphics
    if ischar(varargin{nargin}) && ...
        strcmpi(varargin{nargin}, 'refresh')
        redrawfig(hFigMHnd);
    end


% show a certain page of uicontrols
case {'showpage'}

    % for figures
    if hFigType == xfigure_factory.objtypes.figure
        if ischar(iStr) && ...
           ~isempty(iStr) && ...
           ~isempty(iObj.figprops.pages)
            switch lower(iStr(:)')
                case {'cur'}
                    varargout{1} = iObj.figprops.cpage;
                    return;
                case {'max'}
                    varargout{1} = max(iObj.figprops.pages);
                    return;
                case {'min'}
                    varargout{1} = min(iObj.figprops.pages);
                    return;
            end

            try
                tpage = str2double(iStr);
                if isempty(tpage) || ...
                    isnan(tpage(1)) || ...
                    isinf(tpage(1))
                    error('INVALID_PAGE_NUMBER_STRING');
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                error( ...
                    'xfigure:BadArgument', ...
                    'Invalid page (string) requested.' ...
                );
            end
            if ~any(iStr(1) == '0123456789')
                tpage = max(iObj.figprops.cpage, 1) + tpage(1);
            end
            iStr = tpage(1);
        elseif ~isnumeric(iStr) || ...
            isempty(iStr) || ...
            isnan(iStr(1)) || ...
            isinf(iStr(1))
            error( ...
                'xfigure:BadArgument', ...
                'Invalid page (datatype/content) requested.' ...
            );
        end
        pgnum  = fix(max(1, min(max(iObj.figprops.pages), iStr(1))));
        xfigures(ihPos).figprops.cpage = pgnum;
        callhdl = hFigure;

    % for uicontrols
    elseif hFigType == xfigure_factory.objtypes.uicontrol
        pgnum  = get(hFigMHnd, 'Value');
        pgspec = iFObj.figprops.pages;
        if pgnum > length(pgspec)
            warning( ...
                'xfigure:BadShowPageControl', ...
                'Invalid page selected -> wrong dropdown?' ...
            );
            return;
        end
        if pgnum > 0
            pgnum = iFObj.figprops.pages(pgnum);
        end
        xfigures(ihFPos).figprops.cpage = pgnum;
        callhdl = xfig_ilup(ihFPos);

    % otherwise
    else
        error( ...
            'xfigure:InvalidObjectType', ...
            'ShowPage is only valid for figures and uicontrols.' ...
        );
    end

    % make calls to SetGroupVisible
    if nargin > 3 && ...
        ischar(varargin{4}) && ...
       ~strcmpi(varargin{4}, 'refresh')
        refreshwin = {};
    else
        refreshwin = {'refresh'};
    end
    xfigure(callhdl, 'SetGroupVisible', 'UICPage_any', 'off');
    xfigure(callhdl, 'SetGroupVisible', 'UICPage_all');
    xfigure(callhdl, 'SetGroupVisible', ...
        ['UICPage' num2str(pgnum)], 'on', refreshwin{:});


% slide a group of UIControls
case {'slidegroupxy'}

    % only valid for figures
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'SlideGroupXY is only valid for figures.' ...
        );
    end

    % check input spec
    if nargin < 4 || ...
       ~isvarname(deblank(iStr)) || ...
       ~isnumeric(varargin{4}) || ...
       (length(varargin{4}) < 2 && ...
        (nargin < 5 || ...
        ~isnumeric(varargin{5}) || ...
         isempty(varargin{5})))
        error( ...
            'xfigure:BadArgument', ...
            'SlideGroupXY needs a group and a X and Y slide parameter.' ...
        );
    end
    dogroup = deblank(iStr(:)');

    % what slide spec
    if length(varargin{4}) > 1
        slide = [varargin{4}(1) varargin{4}(2)];
    else
        slide = [varargin{4}(1) varargin{5}(1)];
    end

    % slide controls
    if isfield(iObj.figprops.sgroups, dogroup)
        hdls = iObj.figprops.sgroups.(dogroup);
        for hc = 1:numel(hdls)
            oHdln = find(xfig_ilup == hdls(hc));
            if ~isempty(oHdln)
                xfigure(xfig_ilup(oHdln), ...
                    'Set', 'Position', [slide(1:2) 0 0] + ...
                    xfigure(xfig_ilup(oHdln), ...
                        'Get', 'Position'));
            end
        end
    end

    % refresh ?
    if ischar(varargin{nargin}) && ...
        strcmpi(varargin{nargin}, 'refresh')
        redrawfig(hFigMHnd);
    end


% getting a figure's tagstruct list from UserData
case {'tagstruct'}

    % only valid for figures
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'TagStruct is only valid for figures.' ...
        );
    end

    % get (and set) struct
    udt = get(hFigMHnd, 'UserData');
    if isstruct(udt) && ...
       ~isempty(udt) && ...
        isfield(udt, 'xfigure_UDTagStruct')
        varargout{1} = udt.xfigure_UDTagStruct;
    else
        varargout{1} = struct;
    end


% return the struct of objtypes
case {'typestruct'}

    % error on non-root objects
    if hFigType
        error( ...
            'xfigure:InvalidObjectType', ...
            'TypeStruct is only valid for the ROOT object.' ...
        );
    end
    varargout{1} = xfigure_factory.objtypes;


% write a value to a linked xini
case {'updatefield'}

    % only valid for uicontrols
    if hFigType ~= xfigure_factory.objtypes.uicontrol
        error( ...
            'xfigure:InvalidObjectType', ...
            'UpdateField is only valid for UIControls.' ...
        );
    end

    % no link activated
    if ~isstruct(iFObj.figprops.lilookup) || ...
        isempty(fieldnames(iFObj.figprops.lilookup))
        error( ...
            'xfigure:NoFieldLinkSupport', ...
            'Parent figure has no FieldLink support enabled.' ...
        );
    end

    % no Tag -> return
    if isempty(iObj.figprops.loadprops.Tag)
        return;
    end

    % uicontrol is not linked
    if ~isfield(iFObj.figprops.lilookup, iObj.loadprops.Tag)
        warning( ...
            'xfigure:NoFieldLink', ...
            'UIControl with tag %s is not linked.', ...
            iObj.loadprops.Tag ...
        );
        return;
    end

    % update field
    varargout{1} = i_updatefield(hFigure, iFObj.figprops.lilookup.(iObj.loadprops.Tag){1:2});


% write all linked values to linked xini object
case {'updatefields'}

    % only valid for figures
    if hFigType ~= xfigure_factory.objtypes.figure
        error( ...
            'xfigure:InvalidObjectType', ...
            'UpdateFields is only valid for figures.' ...
        );
    end

    % check groups
    if ~ischar(iStr) || ...
        numel(deblank(iStr)) < 3
        error( ...
            'xfigure:BadArgument', ...
            'No valid group selection given.' ...
        );
    end
    iStr = iStr(:)';

    % group selection
    if strcmpi(iStr, 'all_groups')
        ugroups = fieldnames(iObj.figprops.lgroups);
    else
        ugroups = splittocellc(deblank(iStr), ',; ', true, true);
    end
    usuccess = true;

    % iterate over groups
    for gc = 1:length(ugroups)

        % only go on if group exists
        try
            gcontrols = iObj.figprops.lgroups.(ugroups{gc});
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            continue;
        end

        % iterate over controls
        gcontrols = gcontrols{2};
        for cc = 1:length(gcontrols)
            try
                glookup   = iObj.figprops.lilookup.(gcontrols{cc});
                cusuccess = xfigure(glookup{end}, 'UpdateField');
                if ~cusuccess
                    usuccess = false;
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                usuccess = false;
            end
        end
    end

    % successful ?
    varargout{1} = usuccess;


% no valid action requested
otherwise
    error( ...
        'xfigure:UnknownMethod', ...
        'Invalid method in call to ROOT object: %s.', ...
        action ...
    );
end



%%%% internal functions



function [mlh, ht] = findmlparent(mlh,t,xfp_type)
    if ~isnumeric(t)
        try
            t = xfp_type.(lower(t));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            mlh = [];
            ht  = 0;
            return;
        end
    end
    try
        mlh = get(mlh, 'Parent');
        ht  = xfp_type.(lower(get(mlh, 'Type')));
        while ht ~= 1 && ...
           ~any(t == ht)
            mlh = get(mlh, 'Parent');
            try
                ht = xfp_type.(lower(get(mlh, 'Type')));
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                mlh = [];
                ht  = 0;
                return;
            end
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        mlh = [];
        ht  = 0;
        return;
    end
    if ~any(t == 1) && ...
        ht == 1
        mlh = [];
        ht  = 0;
        return;
    end
% end of function findmlparent


function h = handlenew(t, c)
    h = floor(2 ^ 25 * (rand(1) + t));
    while any(c == h)
        h = floor(2 ^ 25 * (rand(1) + t));
    end
% end of function handlenew


function i_loadfield(hxfigure, flinkini, flinktype, withcbs)

    % get handle and callback
    try
        tmphnm = hxfigure.mhnd;
        tmpcbk = get(tmphnm, 'Callback');
        docbk  = false;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        return;
    end

    % and current value to set
    try
        tmpval = [];
        eval(['tmpval=flinkini{1}.' flinkini{2} '.' flinkini{3} ';']);
    catch ne_eo;
        disp(['xfigure::LoadField:*i_loadfield(...) -> couldn''t read ' ...
              flinkini{2} '.' flinkini{3} ' from ' ...
              strrep(Filename(flinkini{1}),'\','\\') ': ' ne_eo.message '.']);
        return;
    end

    % on/off switch
    switch lower(flinktype{1}), case {'b', 'bool', 'oo', 'onoff'}

        try
            % ini setting is true
            if all(tmpval)
                set(tmphnm, 'Value', get(tmphnm, 'Max'));
                docbk = true;

            % not true
            else
                set(tmphnm, 'Value', get(tmphnm, 'Min'));
                if ~strcmpi(get(tmphnm, 'Style'), 'radiobutton')
                    docbk = true;
                end
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % single line strings
    case {'c', 'char', 'chararray', 'string'}

        % reject bad input
        if ~ischar(tmpval) || ...
            numel(tmpval) ~= length(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Invalid datatype for <string> link.']);
            return;
        end

        % set value
        set(tmphnm, 'String', tmpval(:)');

    % indices
    case {'i', 'index'}

        % accept only numeric input
        if ~isnumeric(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Invalid datatype for <index> link.']);
            return;
        end

        % set value
        try
            set(tmphnm, 'Value', tmpval(:)');
            docbk = true;
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % stringlist
    case {'l', 'list', 'stringlist'}

        % make character lists
        if ischar(tmpval)
            if isempty(tmpval)
                tmpval = {''};
            elseif strcmpi(get(tmphnm, 'Style'), 'popupmenu') && ...
                length(tmpval) == numel(tmpval) && ...
                any(tmpval == '|')
                tmpval = splittocell(tmpval, '|');
            else
                tmpval = cellstr(tempval);
            end
        elseif iscell(tmpval) && ...
            isempty(tmpval) && ...
            strcmpi(get(tmphnm, 'Style'), 'popupmenu') && ...
            isempty(tmpval)
            tmpval = {''};
        end

        % reject non-cell fields
        if ~iscell(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Invalid datatype for <stringlist> link.']);
            return;
        end
        tmpval = tmpval(:);

        % default value ?
        if numel(flinktype) > 1 && ...
            isempty(tmpval) || ...
           (length(tmpval) == 1 && ...
            isempty(tmpval{1}))
            try
                tmpval = cellstr(flinktype{2});
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end

        % set value
        try
            set(tmphnm, 'String', tmpval);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % single number
    case {'n', 'num', 'numstr', 'numeric'}

        % reject bad input
        if ~isnumeric(tmpval) || ...
            numel(tmpval) ~= 1
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Invalid datatype or content for <numeric> link.']);
            return;
        end

        % set value
        try
            set(tmphnm, 'String', num2str(tmpval));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % numeric array (MxN matrices only)
    case {'na', 'numarray'}

        % reject bad input
        if ~isnumeric(tmpval) || ...
            ndims(tmpval) > 2 || ...
           (any(size(tmpval) == 0) && ...
            ~all(size(tmpval) == 0))
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Invalid datatype or content for <numarray> link.']);
            return;
        end

        % format value
        tempout = strrep(strrep(any2ascii(tmpval, 8), ',', ', '), ';', '; ');

        % set value
        try
            set(tmphnm, 'String', tempout(2:(end-1)));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % negated on/off
    case {'negb', 'negbool', 'negoo', 'negonoff'}

        try
            % ini setting is false
            if ~any(tmpval)
                set(tmphnm, 'Value', get(tmphnm, 'Max'));
                docbk = true;

            % not true
            else
                set(tmphnm, 'Value', get(tmphnm, 'Min'));
                if ~strcmpi('radiobutton', get(tmphnm, 'Style'))
                    docbk = true;
                end
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % set (on specific value to true)
    case {'s', 'set'}

        % reject bad link spec
        if length(flinktype) < 2
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Bad spec for <set> link.']);
            return;
        end

        try
            % ini setting matches
            if (numel(flinktype{2}) == numel(tmpval) || ...
                numel(flinktype{2}) == 1 || ...
                numel(tmpval) == 1) && ...
               all(flinktype{2} == tmpval(1))
                set(tmphnm, 'Value', get(tmphnm, 'Max'));
                docbk = true;

            % doesn't match
            else
                set(tmphnm, 'Value', get(tmphnm, 'Min'));
                if ~strcmpi(get(tmphnm, 'Style'), 'radiobutton')
                    docbk = true;
                end
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % sub-indexed on/off
    case {'sb', 'subbool', 'soo', 'subonoff'}

        % reject bad link spec
        if length(flinktype) < 2 || ...
           ~isnumeric(flinktype{2}) || ...
            isempty(flinktype{2}) || ...
            isnan(flinktype{2}(1)) || ...
            isinf(flinktype{2}(1)) || ...
            flinktype{2}(1) < 1 || ...
            flinktype{2}(1) > numel(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Bad spec for <subonoff> link.']);
            return;
        end

        try
            % ini setting true
            if tmpval(fix(flinktype{2}(1)))
                set(tmphnm, 'Value', get(tmphnm, 'Max'));
                docbk = true;

            % false
            else
                set(tmphnm, 'Value', get(tmphnm, 'Min'));
                if ~strcmpi(get(tmphnm, 'Style'), 'radiobutton')
                    docbk = true;
                end
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % sub-indexed indices
    case {'si', 'subindex'}

        % reject bad link spec
        if length(flinktype) < 2 || ...
           ~isnumeric(flinktype{2}) || ...
            isempty(flinktype{2}) || ...
            isnan(flinktype{2}(1)) || ...
            isinf(flinktype{2}(1)) || ...
            flinktype{2}(1) < 1 || ...
            flinktype{2}(1) > numel(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Bad spec for <subindex> link.']);
            return;
        end

        % reject bad input value
        if ~isnumeric(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Invalid datatype for <subindex> link.']);
            return;
        end

        % set value
        try
            set(tmphnm, 'Value', tmpval(fix(flinktype{2}(1))));
            docbk = true;
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % sub-indexed single number
    case {'sn', 'subnum', 'subnumstr', 'subnumeric'}

        % reject bad link spec
        if length(flinktype) < 2 || ...
           ~isnumeric(flinktype{2}) || ...
            isempty(flinktype{2}) || ...
            isnan(flinktype{2}(1)) || ...
            isinf(flinktype{2}(1)) || ...
            flinktype{2}(1) < 1 || ...
            flinktype{2}(1) > numel(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Bad spec for <subnumeric> link.']);
            return;
        end

        % reject bad input value
        if ~isnumeric(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Invalid datatype for <subnumeric> link.']);
            return;
        end

        % set value
        try
            set(tmphnm, 'String', num2str(tmpval(fix(flinktype{2}(1)))));
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end

    % sub-indexed set
    case {'ss', 'subset'}

        % reject bad link spec
        if length(flinktype) < 3 || ...
           ~isnumeric(flinktype{2}) || ...
            isempty(flinktype{2}) || ...
            isnan(flinktype{2}(1)) || ...
            isinf(flinktype{2}(1)) || ...
            flinktype{2}(1) < 1 || ...
            flinktype{2}(1) > numel(tmpval)
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Bad spec for <subnumeric> link.']);
            return;
        end

        % get correct value
        tmpval = tmpval(fix(flinktype{2}));
        if iscell(tmpval)
            try
                tmpval = [tmpval{:}];
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                return;
            end
        end

        try
            if flinktype{3} == tmpval(flinktype{2})
                set(tmphnm, 'Value', get(tmphnm, 'Max'));
                docbk = true;
            else
                set(tmphnm, 'Value', get(tmphnm, 'Min'));
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            try
                set(tmphnm, 'Value', get(tmphnm, 'Min'));
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end

    % unknown link type -> display warning
    otherwise
        disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
              'Unknown link type <' flinktype{1}(:)' '>.']);
    end

    % do callback ?
    if withcbs && ...
        docbk && ...
       ~isempty(tmpcbk)
        try
            xfigurecallback(tmpcbk, ...
                findmlparent(tmphnm, 'figure', struct( ...
                'r', 0,           'root',            0, ...
                'f', 1, 'fig', 1, 'figure',          1, ...
                'c', 2, 'uic', 2, 'uicontrol',       2, ...
                'm', 3, 'uim', 3, 'uimenu',          3, ...
                'x', 4, 'uix', 4, 'uicontextmenu',   4  ...
                )), tmphnm, true);
        catch ne_eo;
            disp(['xfigure::LoadField:*i_loadfield(...) -> ' ...
                  'Error executing Callback:' char(10) ...
                  'Callback: ' tmpcbk char(10) ...
                  'Lasterr:  ' ne_eo.message]);
        end
    end
% end of function i_loadfield


function usuccess = i_updatefield(hxfigure, fieldlink, flinktype)

    % suppose we didn't succeed
    usuccess = false;

    % get handles
    try
        fieldhnm = hxfigure.mhnd;
        fieldini = fieldlink{1};
        fieldfld = [fieldlink{2} '.' fieldlink{3}];
        fieldevl = ['fieldini.' fieldfld];
    catch ne_eo;
        disp(['xfigure::UpdateField:*i_updatefield(...) -> ' ...
              'Bad arguments, calling convention error (' ne_eo.message ').']);
        return;
    end

    % get current value (assume empty matrix for non-existant)
    try
        eval(['fieldval=' fieldevl ';']);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        fieldval = [];
        try
            eval([fieldevl '=[];']);
        catch ne_eo;
            disp(['xfigure::UpdateField:*i_updatefield(...) -> ' ...
                  'Illegal fieldname: ' fieldevl ' (' ne_eo.message ').']);
            return;
        end
    end

    % on/off switch
    switch lower(flinktype{1}), case {'b', 'bool', 'oo', 'onoff'}
        try
            bval = get(fieldhnm, 'Value');
            if all(bval == get(fieldhnm, 'Max'))
                bval = 1;
            else
                bval = 0;
            end
            eval([fieldevl '=bval;']);
            usuccess = true;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <onoff> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % single line strings
    case {'c', 'char', 'chararray', 'string'}
        try
            eval([fieldevl '=get(fieldhnm,''String'');']);
            usuccess = true;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <string> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % indices
    case {'i', 'index'}
        try
            eval([fieldevl '=get(fieldhnm,''Value'');']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <index> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % string list
    case {'l', 'list', 'stringlist'}
        try
            cstr = get(fieldhnm, 'String');
            if ischar(cstr)
                if isempty(cstr)
                    cstr = {};
                elseif strcmpi(get(fieldhnm, 'Style'), 'popupmenu') && ...
                    length(cstr) == numel(cstr) && ...
                    any(cstr == '|')
                    cstr = splittocell(cstr, '|');
                else
                    cstr = cellstr(cstr);
                end
            end
            eval([fieldevl '=cstr(:);']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <stringlist> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % single number (default: 0)
    case {'n', 'num', 'numstr', 'numeric'}
        try
            cstr = splittocellc(get(fieldhnm, 'String'), ' ,;', true, true);
            if ~isempty(cstr) && ...
                isempty(cstr{1})
                cstr(1) = [];
            end
            if isempty(cstr)
                tval = 0;
            else
                try
                    tval = str2double(cstr{1});
                    tval = tval(1);
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    tval = 0;
                end
            end
            eval([fieldevl '=tval;']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <numeric> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % numeric array (MxN matrices only)
    case {'na', 'numarray'}
        try
            cstr = get(fieldhnm, 'String');
            if ~ischar(cstr) || ...
                length(cstr) ~= numel(cstr) || ...
                any(cstr == '|')
                error('INVALID_NUMARRAY_STRING');
            end
            eval([fieldevl '=[' cstr '];']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <numarray> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % negated on/off switch
    case {'negb', 'negbool', 'negoo', 'negonoff'}
        try
            bval = get(fieldhnm, 'Value');
            if ~all(bval == get(fieldhnm, 'Max'))
                bval = 0;
            else
                bval = 1;
            end
            eval([fieldevl '=bval;']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <negonoff> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % set
    case {'s', 'set'}
        if length(flinktype) < 2
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Bad spec for <set> link.']);
            return;
        end
        try
            cval = get(fieldhnm, 'Value');
            if all(cval == get(fieldhnm, 'Max'))
                eval([fieldevl '=flinktype{2};']);
            end
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <set> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % sub-indexed on/off switch
    case {'sb', 'subbool', 'soo', 'subonoff'}

        % reject bad link spec
        if length(flinktype) < 2 || ...
           ~isnumeric(flinktype{2}) || ...
            isempty(flinktype{2}) || ...
           ~isnumeric(fieldval) || ...
            isnan(flinktype{2}(1)) || ...
            isinf(flinktype{2}(1)) || ...
            flinktype{2}(1) < 1
            disp(['xfigure::UpdateField:*i_updatefield(...) -> ' ...
                  'Bad spec for <subonoff> link.']);
            return;
        end

        try
            cval = get(fieldhnm, 'Value');
            if all(cval == get(fieldhnm, 'Max'))
                fieldval(fix(flinktype{2}(1))) = 1;
            else
                fieldval(fix(flinktype{2}(1))) = 0;
            end
            eval([fieldevl '=fieldval;']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <subonoff> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % sub-indexed indices
    case {'si', 'subindex'}

        % reject bad link spec
        if length(flinktype) < 2 || ...
           ~isnumeric(flinktype{2}) || ...
            isempty(flinktype{2}) || ...
           ~isnumeric(fieldval) || ...
            isnan(flinktype{2}(1)) || ...
            isinf(flinktype{2}(1)) || ...
            flinktype{2}(1) < 1
            disp(['xfigure::UpdateField:*i_updatefield(...) -> ' ...
                  'Bad spec for <subindex> link.']);
            return;
        end

        try
            cval = get(fieldhnm, 'Value');
            if numel(cval) ~= 1
                disp(['xfigure::UpdateField:*i_updatefield(...) -> ' ...
                      'Bad Value for <subindex> link field ' fieldfld '.']);
                return;
            end
            fieldval(fix(flinktype{2}(1))) = cval;
            eval([fieldevl '=fieldval;']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <subindex> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % sub-indexed number (default: 0)
    case {'sn','subnum','subnumstr','subnumeric'}

        % reject bad link spec
        if length(flinktype) < 2 || ...
           ~isnumeric(flinktype{2}) || ...
           isempty(flinktype{2}) || ...
          ~isnumeric(fieldval) || ...
           isnan(flinktype{2}(1)) || ...
           isinf(flinktype{2}(1)) || ...
           flinktype{2}(1) < 1
            disp(['xfigure::UpdateField:*i_updatefield(...) -> ' ...
                  'Bad spec for <subnumeric> link.']);
            return;
        end

        try
            cstr = splittocellc(get(fieldhnm, 'String'), ' ,;', true, true);
            if ~isempty(cstr) && ...
                isempty(cstr{1})
                cstr(1) = [];
            end
            if isempty(cstr)
                tval = 0;
            else
                try
                    tval = str2double(cstr{1});
                    tval = tval(1);
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                    tval = 0;
                end
            end
            fieldval(fix(flinktype{2}(1))) = tval;
            eval([fieldevl '=fieldval;']);
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <subnumeric> field ' fieldfld ' (' ne_eo.message ').']);
        end

    % sub-indexed set
    case {'ss','subset'}

        % reject bad link spec
        if length(flinktype) < 3 || ...
           ~isnumeric(flinktype{2}) || ...
            isempty(flinktype{2}) || ...
           ~isnumeric(fieldval) || ...
            isnan(flinktype{2}(1)) || ...
            isinf(flinktype{2}(1)) || ...
            flinktype{2}(1) < 1
            disp(['xfigure::UpdateField:*i_updatefield(...) -> ' ...
                  'Bad spec for <subset> link.']);
            return;
        end

        try
            cval = get(fieldhnm, 'Value');
            if all(cval == get(fieldhnm, 'Max'));
                fieldval(fix(flinktype{2}(1))) = flinktype{3};
                eval([fieldevl '=fieldval;']);
            end
            usuccess = 1;
        catch ne_eo;
            disp(['xfigure::UpdateField*:i_updatefield(...) -> ' ...
                  'Couldn''t set <subset> field ' fieldfld ' (' ne_eo.message ').']);
        end
    end
% end of function i_updatefield


function madeobj = makeobj(h, r, t)
    madeobj = class(struct( ...
              'ihnd', h, ...
              'mhnd', r, ...
              'type', t), ...
        'xfigure');
% end of function makeobj

function os = makeostruct(itype)
    os = cell2struct(cell(1, 1, 8), ...
        {'callbacks', 'deletefcn', 'figtype', 'figprops', ...
         'loadprops', 'prevprops', 'timeclick', 'uicprops'}, 3);
    os.callbacks = cell(1, 4);
    if itype == 1
        os.figprops = cell2struct(cell(1, 1, 12), ...
            {'cpage', 'egroups', 'lgroups', ...
             'lilookup', 'linkcont', 'linkspec', 'llookup', ...
             'pages', 'rgroups', 'rszuics', 'sgroups', 'vgroups'}, 3);
    end
% end of function os = makeostruct(itype)

function menutxt = menutext(h,ind)
    menutxt = '';
    if nargin < 2 || ...
        isempty(ind)
        ind = '';
    end
    if ~ishandle(h)
        return;
    end
    t = lower(get(h, 'Type'));
    if ~any(strcmp(t, {'uicontextmenu', 'uimenu'}))
        return;
    end
    try
        c = get(h, 'Children');
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        c = [];
    end
    if strcmp(t, 'uimenu')
        try
            mp = subget(h, {'Label', 'Separator', 'Callback', 'Enable'});
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            mp = struct('Label', '', 'Separator', 'off', 'Callback', '');
        end
        if strcmpi(mp.Separator, 'on')
            menutxt = [menutxt ind '------------' char(10)];
        end
        if ~isempty(mp.Callback)
            if ischar(mp.Callback)
                mp.Callback = [' -> [' mp.Callback ']'];
            elseif iscell(mp.Callback)
                if numel(mp.Callback) > 1
                    try
                        cbargs = any2ascii(mp.Callback(2:end));
                        cbargs = cbargs(2:end-1);
                    catch ne_eo;
                        neuroelf_lasterr(ne_eo);
                        cbargs = '';
                    end
                else
                    cbargs = '';
                end

                if ischar(mp.Callback{1})
                    mp.Callback = [' -> [' mp.Callback{1} '(' cbargs ')]'];
                elseif isa(mp.Callback{1}, 'function_handle')
                    mp.Callback = [' -> [@' func2str(mp.Callback{1}) '(' cbargs ')]'];
                else
                    mp.Callback = ' (#! bad Callback cell array !)';
                end
            elseif isa(mp.Callback, 'function_handle')
                mp.Callback = [' -> [@' func2str(mp.Callback) ']'];
            else
                mp.Callback = ' (#! bad Callback property !)';
            end
        else
            mp.Callback = '<no callback>';
        end
        if ~isempty(mp.Label)
            if strcmpi(mp.Enable, 'on')
                menutxt = [menutxt ind mp.Label mp.Callback char(10)];
            else
                menutxt = [menutxt ind mp.Label '(disabled/gray) ' mp.Callback char(10)];
            end
        end
        ind = [ind '  '];
    end
    for cc = length(c):-1:1
        menutxt = [menutxt menutext(c(cc), ind)];
    end
% end of function menutxt


function redrawfig(mlh)
    if ~ispc
        try
            tcol = get(mlh, 'Color');
            set(mlh, 'Color', (tcol * 0.99 + [0.002, 0.002, 0.002]), ...
                'Color', tcol);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
    end
    drawnow;
% end of function redrawfig
