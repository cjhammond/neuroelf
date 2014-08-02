function timr = neuroelf_splash(ihandle)
% neuroelf_splash  - NeuroElf splash display on an image handle
%
% FORMAT:       tmr = neuroelf_splash(ihandle)
%
% Input fields:
%
%       ihandle     image handle on which the splash is displayed
%
% Output fields:
%
%       tmr         timer object to be started

% Version:  v0.9c
% Build:    11050712
% Date:     Apr-18 2011, 12:10 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2011, Jochen Weber
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
global ne_ui;

% test input
if nargin < 1 || ...
   ~isa(ihandle, 'double') || ...
    numel(ihandle) ~= 1 || ...
    isinf(ihandle) || ...
    isnan(ihandle) || ...
   ~ishandle(ihandle) || ...
   ~strcmpi(get(ihandle, 'Type'), 'image')

    % don't bail out, simply don't do anything
    return;
end

% unset any previous information
if isfield(ne_ui, 'splash') && ...
    isstruct(ne_ui.splash) && ...
    numel(ne_ui.splash) == 1

    % lingering transimg
    try
        delete(ne_ui.splash.timg);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end

% setup stuff
ne_ui.splash = struct( ...
    'alpha',   {cell(1, 8)}, ...
    'curve',   [], ...
    'ihandle', ihandle, ...
    'iter',    0, ...
    'timer',   timer, ...
    'timg',    transimg(624, 224, [1, 1, 1]));

% get handles
talp = ne_ui.splash.alpha;
timg = ne_ui.splash.timg;
timr = ne_ui.splash.timer;

% error handling
try

    % splash images path
    sp = neuroelf_path('splash');

    % load background
    im = imread([sp '/curve.jpg']);
    ne_ui.splash.curve = rgb2hsv(im);
    addlayer(timg, im, 1);
    talp{1} = single(1);

    % load and add objects for the right-hand side
    im = imread([sp '/slice.jpg']);
    ima = single(min(1, 0.01 .* (765 - sum(single(im), 3))));
    addlayer(timg, im, ima);
    talp{2} = ima;
    im = imread([sp '/surf.jpg']);
    addlayer(timg, im, 0);
    talp{3} = single(min(1, 0.01 .* (765 - sum(single(im), 3))));
    im = imread([sp '/render.jpg']);
    addlayer(timg, im, 0);
    talp{4} = single(min(1, 0.01 .* (765 - sum(single(im), 3))));

    % load main text, add white middle-layer, then other texts
    [im, imm, ima] = imread([sp '/text1.png']);
    addlayer(timg, im, ima);
    talp{5} = single((1 / 255) .* double(ima));
    im = imread([sp '/text2.jpg']);
    addlayer(timg, im, 0);
    talp{6} = single(sqrt(0.5));
    im = imread([sp '/text3.jpg']);
    addlayer(timg, im, 0);
    talp{7} = single(sqrt(0.5));

    % set alpha information back
    ne_ui.splash.alpha = talp;

    % set handle and render
    sethandle(timg, ihandle);
    render(timg)
    drawnow;

    % make settings to timer object
    set(timr, ...
        'ExecutionMode', 'fixedSpacing', ...
        'Period',        0.08, ...
        'StopFcn',       @nesp_cleanup, ...
        'TimerFcn',      @nesp_splash);

catch ne_eo;
    neuroelf_lasterr(ne_eo);

    % try to delete transimg
    try
        delete(timg);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end

    % return empty!
    timr = [];
end

% sub functions
function nesp_cleanup(varargin)
global ne_ui;
if ~isfield(ne_ui, 'splash') || ...
   ~isstruct(ne_ui.splash) || ...
    numel(ne_ui.splash) ~= 1
    return;
end
sp = ne_ui.splash;

% try to set final state
try
    setlayeralpha(sp.timg, 2, 0);
    setlayeralpha(sp.timg, 3, 0);
    setlayeralpha(sp.timg, 4, ne_ui.splash.alpha{4});
    setlayeralpha(sp.timg, 5, 0);
    setlayeralpha(sp.timg, 6, 0);
    setlayeralpha(sp.timg, 7, ne_ui.splash.alpha{7});

    % re-render
    render(sp.timg)
    drawnow;
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end
try
    delete(ne_ui.splash.timg);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end

% clean up struct
ne_ui.splash = [];

function nesp_splash(varargin)
global ne_ui;
if ~isfield(ne_ui, 'splash') || ...
   ~isstruct(ne_ui.splash) || ...
    numel(ne_ui.splash) ~= 1
    try
        stop(varargin{1});
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
    return;
end
sp = ne_ui.splash;
alp = sp.alpha;

% progress along data
sp.iter = sp.iter + 1;
imod = mod(sp.iter, 60);
if imod == 0
    imod = 60;
end
sc = 0.1 * (imod - 50);

% set back
ne_ui.splash = sp;

% for 1 - 50 and 61 - 110
if imod <= 50

    % recompute hue of curve
    curve = sp.curve;
    curve(:, :, 1) = curve(:, :, 1) + 0.02 .* imod;
    curve(:, :, 1) = curve(:, :, 1) - floor(curve(:, :, 1));
    setlayerpixel(sp.timg, 1, hsvconv(curve));

% for 51 - 60
elseif sp.iter < 70

    % set white-layer visibility as a fraction of 2/3
    setlayeralpha(sp.timg, 6, 2 * sc / 3);

    % switch text and image
    if sc < 1
        setlayeralpha(sp.timg, 2, (1 - sc) .* alp{2});
        setlayeralpha(sp.timg, 5, (1 - sc) .* alp{5});
    else
        setlayeralpha(sp.timg, 2, 0);
        setlayeralpha(sp.timg, 5, 0);
    end
    setlayeralpha(sp.timg, 3, sc .* alp{3});
    setlayeralpha(sp.timg, 6, sc .* alp{6});

% for 111 - 120
elseif sp.iter < 130

    % switch text and image
    if sc < 1
        setlayeralpha(sp.timg, 3, (1 - sc) .* alp{3});
        setlayeralpha(sp.timg, 6, (1 - sc) .* alp{6});
    else
        setlayeralpha(sp.timg, 3, 0);
        setlayeralpha(sp.timg, 6, 0);
    end
    setlayeralpha(sp.timg, 4, sc .* alp{4});
    setlayeralpha(sp.timg, 7, sc .* alp{7});
end

% re-render
render(sp.timg)
drawnow;

% cleanup?
if sp.iter >= 360
    stop(sp.timer);
    return;
end
