% FUNCTION ne_about: bring up about dialog
function varargout = ne_about(varargin)

% Version:  v0.9d
% Build:    14060710
% Date:     Jun-07 2014, 10:13 AM EST
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

% global access to splash
global ne_ui;
global ne_gcfg;

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% bring this up
if ne_gcfg.c.echo
    ne_echo('neuroelf_gui(''about'')');
end

% allow for problems
try

    % load dialog
    abt = xfigure([neuroelf_path('tfg') '/splash.tfg']);
    abt.Name = 'NeuroElf GUI - about';

    % get tags and make some settings
    tags = abt.TagStruct;
    tags.PB_Progress.Visible = 'off';
    tags.LB_Progress.Max = 2;
    tags.LB_Progress.FontSize = 9;
    tags.LB_Progress.FontWeight = 'bold';
    tags.LB_Progress.String = splittocell(help('neuroelf_gui'), char(10));
    tags.LB_Progress.Value = [];

    % start splash
    imgh = tags.IM_Splash.Children;
    imgh = imgh(strcmpi('image', get(imgh, 'Type')));
    imgt = neuroelf_splash(imgh);

    % make sure this cannot be interrupted
    abt.WindowStyle = 'modal';
    abt.HandleVisibility = 'callback';
    abt.Visible = 'on';
    start(imgt);
    drawnow;

    % only allow dialog to be closed after enough iterations
    while ne_ui.splash.iter <= 170
        pause(0.02);
        drawnow;
    end

    % try to stop timer anyway
    try
        stop(imgt);
    catch ne_eo;
        ne_gcfg.c.lasterr = ne_eo;
    end

    % allow closing of dialog
    abt.CloseRequestFcn = 'closereq';
    tags.BT_About_OK.Visible = 'on';
    tags.BT_About_OK.Callback = 'delete(gcf);';

    % and wait until done
    uiwait(abt.MLHandle);

% in case of error
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;

    % give more simple dialog
    abt = helpdlg(sprintf( ...
        ['NeuroElf: a Matlab GUI for visualizing fMRI analysis\n' ...
         'files (BrainVoyager QX, SPM, and AFNI), part of the\n' ...
         'NeuroElf package.\n\n' ...
         'Please visit http://neuroelf.net/ for more info.']), ...
         'NeuroElf GUI - about');
    set(abt, 'WindowStyle', 'modal');
    uiwait(abt);
end
