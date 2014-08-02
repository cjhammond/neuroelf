function [varargout] = neuroelf_gui(varargin)
% neuroelf_gui  - the NeuroElf graphical user interface (GUI)
%
% FORMAT:       neuroelf_gui
%
% FORMAT:       [out, ...] = neuroelf_gui(action, [ arguments])
%
% Input fields:
%
%       action      string representing an action to perform
%       arguments   additional arguments provided to action function
%
% Output fields:
%
%       out, ...    any output provided by action function
%
% Note: if called with arguments, neuroelf_gui tries to resolve a function
%       with the location NEUROELF_FOLDER/private/ne_ACTION.m
%
% For help on available sub-functions, please use
%
% neuroelf_gui('help') and neuroelf_gui('help', 'action')
%
% Matlab toolbox developed, written and maintained by Jochen Weber
% with the help and inspiration of
%
% - Hester Breman, Brain Innovation, B.V.
% - Federico Demartino, Brain Innovation, B.V. and University of Maastricht
% - Bryan Denny, Columbia University
% - Fabrizio Esposito, Brain Innovation, B.V.
% - Elia Formisano, University of Maastricht
% - Rainer Goebel, Brain Innovation, B.V. and University of Maastricht
% - Armin Heinecke, Brain Innovation, B.V.
% - Hedy Kober, Yale University
% - Pim Pullens, Brain Innovation, B.V.
% - Alard Roebroeck, University of Maastricht
% - Ajay Satpute, Columbia University
% - Jen Silvers, Columbia University
% - Tor Wager, University of Colorado, Boulder
%
% additional thanks go to the SCAN Unit of Columbia University to allow
% me to continue working on this toolbox
%
%
% Menu commands:
%
% - File
%   - Open               load any BV supported document, anatomical and
%                        statistical projects will be added to the list of
%                        objects
%   - Recently loaded    list with recently loaded objects (in four
%     objects            different categories: slicing, stats, surface,
%                        and surface stats)
%   - Save/as            saves the currently selected slicing/stats object
%                        (with Save as... asking for the new filename)
%
%   - Options
%     - Stats colors     load a different LUT (for the display of non-VMP
%                        statistical maps, as well as to set the .LUTName
%                        field of the currently selected VMP.Map)
%
%   - Exit               close the GUI
%
% - Analysis
%   - Beta plot          for GLMs, bring up additional window that plots
%                        beta weights of a GLM at the cursor position
%   - Contrast manager   compute t-statistic maps
%
% - Visualization
%   - Create montage     create series of slices through the currently
%                        selected slicing object (incl. stats maps/options)
%   - Create surface     take a snapshot from the surface window (axes),
%     snapshot           also incl. the stats maps/options
%
% - Tools
%   - SPM -> BV conversion
%     - Import VMR       converts one anatomical image (img/nii) into a VMR
%     - Import stats     converts one or several spmT/spmF images into a
%     VMP
%     - Import SPM.mats  converts a list of 1st-level SPM.mat files (after
%                        estimation) into a random-effects GLM file
%     - SPM.mat -> PRT   extract onsets from an SPM.mat file and create one
%                        or several PRT(s)
%     - SPM.mat -> SDM   extract the design matrices of the runs and create
%                        the corresponding SDM files
%
%   - alphasim           run a MC-simulation on random maps (smoothed) to
%                        determine the cluster threshold for several
%                        uncorrected thresholds
%   - fmriquality        assess the quality of an fMRI run
%   - renamedicom        flexibly rename several DICOM files (supports
%                        subdirectories)
%   - SPM preprocessing  configure (and run) the preprocessing on several
%                        subjects' datasets
%   - tdclient           manually lookup coordinates to labels, cubes, etc.
%
% - Help
%   - About              bring up this dialog
%
%
%
% Interactive commands (clicks and edits):
%
% - selecting the anatomical project (which for now includes VTCs)
%   shows the slicing of that object; for functional datafiles (VTCs
%   and FMRs), the time course at the cursor is also displayed
%
% - selecting a single available map enables the threshold controls
%
% - if multiple maps are selected (COMMAND + click), several maps
%   are being overlaid (with maps occuring later in the list having
%   precendence over previous maps); in which case the thresholding
%   controls are disabled
%
% - the up and down buttons re-order the maps in the VMP/HEAD file
%
% - the trashcan button removes the selection maps from the VMP/SMP/HEAD
%
% - the properties button allows to change some settings of a singular
%   selected map (in a VMP/SMP/HEAD container)
%
% - the ellipse-button propagates the selection within an RFX-GLM
%
% - clicks (and also cursor up/down presses) in the clusters listbox
%   set the cursor to the first (peak) voxel of that cluster
%
% - using the sphere button, clusters can be restricted to a spheroid
%
% - the AND (^) and OR (v) buttons allow to intersect/union clusters
%
% - the lens buttons zooms the slicing view to the peak of a cluster
%
% - the folder and disk buttons allow loading and saving of the VOI/clusters
%
% - clicking the table-button next to the cluster list extracts betas
%   from the selected clusters (a GLM must be selected)
%
% - the cross-hair button disables the drawing mode
%
% - the pen (or 3D pen) enables (2D/3D) drawing
%
% - the reverse pen button restores the original content (like a rubber)
%
% - the tick-mark button accepts all changes (and copies to the
%   intermediate buffer)
%
% - the revert button reverts changes (to the intermediate buffer state)
%
% - the reload (double revert) button reloads the content from disk
%
% - the green masking button reloads only voxels marked in the currently
%   configured drawing color
%
% - clicks into either of the three panels set the cursor to that
%   position
%
% - the position can also be manually set with the voxel edit boxes
%
% - the slider and edit box for the temporal position will select a
%   specific volume (for VTC and FMR objects), just as a click into the
%   time course display
%
% - thresholds can either be set with the edit boxes or the dropdown,
%   which takes the number of tails into account
%
% - the positive/negative checkboxes toggle the corresponding stats tail
%
% - the interpolation checkbox toggles interpolation of stats maps
%
% - the clustering button will create the list of clusters of the map
%   that is currently displayed (only for single maps); this will take
%   the MNI and TDc (Talairach Daemon database) settings into account
%
% - the LUT and RGB radio buttons allow to switch between LUT and RGB
%   coloring schemes for VMP maps
%
% - clicking on one of the RGB color buttons will bring up a colorpicker
%   which allows to set the colors through the GUI
%
% - the slicing view can be altered with selecting the combined or a
%   singular view button (right of slicing view)
%
% - the translation/rotation/scaling of the dataset (for display) can be
%   altered with the view properties button
%
% - the surface view is available via the scenery button
%
% - a click into a displayed timecourse also sets the volume number and
%   updates the display (which allows interactive volume browsing)
%
% - in the scenery listbox, all selected SRFs will be shown concurrently
%
% - if only one SRF is selected, the display properties can be set manually

% TODOs:
%
% - have separate contrast UI for multi-subject/single-subject GLM
% - compute MDM -> GLM (option: for each subject: create GLM/VMP)
% - beta extraction from anatomical ROIs (ROI/mask images/Marsbar MAT)
% - import/create VOI from MSK/MAT/HDR/NII file
% - link PRTs to VTCs
% - create SDMs from PRTs

% Version:  v0.9d
% Build:    14072417
% Date:     Jul-24 2014, 5:21 PM EST
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

% global variable (used by all functions and also some xff methods)
global ne_gcfg;

% pre-set output
varargout = cell(1, nargout);

% check if figure is loaded
if numel(ne_gcfg) ~= 1 || ...
   ~isstruct(ne_gcfg) || ...
   ~isfield(ne_gcfg, 'h') || ...
   ~isfield(ne_gcfg.h, 'MainFig') || ...
   ~isxfigure(ne_gcfg.h.MainFig, true)

    % delete prior objects with same Tag and (re-) create and main fig
    try
        delete(findobj('Tag', 'NeuroElf_MainFig'));
        ne_gcfg(:) = [];
        disp('Opening NeuroElf GUI');
        disp(' - creating figure and controls...');
        pause(0.001);
        fMainFig = xfigure([neuroelf_path('tfg') '/neuroelf.tfg']);
        ne_initwindow(fMainFig);
    catch ne_eo;
        error( ...
            'neuroelf:NoGUI', ...
            'Error creating main figure: %s.', ...
            ne_eo.message ...
        );
    end
end

% check if already in callback
if ne_gcfg.c.incb
    return;
end

% external and UI calls (for controls that don't allow @ne_XXX Callbacks)
if nargin > 0 && ...
    ischar(varargin{1}) && ...
   ~isempty(varargin{1}) && ...
    isfield(ne_gcfg.c.callbacks, lower(varargin{1}(:)'))

    % pass on call
    try
        if nargout > 0
            [varargout{1:nargout}] = ...
                feval(ne_gcfg.c.callbacks.(lower(varargin{1}(:)')), ...
                0, 0, varargin{2:end});
        else
            feval(ne_gcfg.c.callbacks.(lower(varargin{1}(:)')), ...
                0, 0, varargin{2:end});
        end
    catch ne_eo;
        rethrow(ne_eo);
    end

% no arguments
elseif nargin == 0
    ne_showpage(0, 0, 1);
end
