function hfile = srf_RecoToSphere(hfile, settings)
% SRF::RecoToSphere  - perform all steps to get RECO mesh to sphere
%
% FORMAT:       srf = srf.RecoToSphere([settings])
%
% Input fields:
%
%       settings    optional settings
%        .distciter number of final distortion iterations (default: 0)
%        .force     boolean flag, don't heed filename
%        .smpsmooth curvature smoothing steps (default: [5, 20, 100])
%
% Output fields:
%
%       srf         altered object
%       densm       density map
%
% Note: this method calls srf.Smooth, srf.Inflate and srf.ToSphere

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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

% global settings from config
global xffconf;

% argument check
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'srf')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~isstruct(settings) || ...
    numel(settings) ~= 1
    settings = struct;
end
if ~isfield(settings, 'distciter') || ...
    numel(settings.distciter) ~= 1 || ...
   ~isa(settings.distciter, 'double') || ...
    isinf(settings.distciter) || ...
    isnan(settings.distciter)
    try
        settings.distciter = ...
            xffconf.settings.Morphing.ToSphere.DistCIterations;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        settings.distciter = 10000;
    end
else
    settings.distciter = floor(min(50000, max(0, settings.distciter)));
end
if ~isfield(settings, 'force') || ...
    numel(settings.force) ~= 1 || ...
   ~islogical(settings.force)
    settings.force = false;
end
if ~isfield(settings, 'smpsmooth') || ...
   ~isa(settings.smpsmooth, 'double') || ...
    numel(settings.smpsmooth) ~= 3 || ...
    any(isinf(settings.smpsmooth) | isnan(settings.smpsmooth) | ...
        settings.smpsmooth < 1 | settings.smpsmooth > 250)
    try
        settings.smpsmooth = ...
            xffconf.settings.Morphing.Curvature.SmoothingSteps;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        settings.smpsmooth = [5, 20, 100];
    end
end

% get super content
sc = xffgetscont(hfile.L);

% check filename
if (numel(sc.F) < 9 || ...
    ~strcmpi(sc.F(end-8:end), '_reco.srf')) && ...
   ~settings.force
    error( ...
        'xff:InvalidFilename', ...
        'Filename is not *_RECO.srf. Processing not forced.' ...
    );
end
[sf{1:3}] = fileparts(sc.F);

% perform smoothing
[hfile, d1] = srf_Smooth(hfile);
aft_SaveAs(hfile, [sf{1} '/' sf{2} 'SM.srf']);
aft_SaveAs(d1, [sf{1} '/' sf{2} 'SM_DENSITY.smp']);
xffclear(d1.L);

% create curvature maps
csmp = srf_CurvatureMap(hfile);
for sc = 1:numel(settings.smpsmooth)
    smp_Smooth(csmp, hfile, settings.smpsmooth(sc), 1);
end
aft_SaveAs(csmp, [sf{1} '/' sf{2} 'SM_CURVATURE.smp']);
xffclear(csmp.L);

% perform inflation
[hfile, d2] = srf_Inflate(hfile);
aft_SaveAs(hfile, [sf{1} '/' sf{2} 'SM_INFL.srf']);
aft_SaveAs(d2, [sf{1} '/' sf{2} 'SM_INFL_DENSITY.smp']);
xffclear(d2.L);

% perform to-sphere morphing
[hfile, d3] = srf_ToSphere(hfile);
aft_SaveAs(hfile, [sf{1} '/' sf{2} 'SM_INFL_SPHERE.srf']);
aft_SaveAs(d3, [sf{1} '/' sf{2} 'SM_INFL_SPHERE_DENSITY.smp']);
xffclear(d3.L);

% perform optional DC
if settings.distciter > 0
    [hfile, d4] = srf_ToSphere(hfile, settings.distciter, 0.2, 0.002);
    aft_SaveAs(hfile, [sf{1} '/' sf{2} 'SM_INFL_SPHERE_DC.srf']);
    aft_SaveAs(d4, [sf{1} '/' sf{2} 'SM_INFL_SPHERE_DC_DENSITY.smp']);
    xffclear(d4.L);
end
