function [hfile, densm] = srf_ToSphere(hfile, niter, mforce, sforce, opts)
% SRF::ToSphere  - perform to-sphere morphing
%
% FORMAT:       [srf, densm] = srf.ToSphere([niter, mforce, sforce]])
%
% Input fields:
%
%       niter       number of iterations, default [12000, 8000, 5000, 3000]
%       mforce      morphing force, default [0.5, 0.25, 0.1625, 0.125]
%       sforce      to-sphere force, default [0.0003, 0.0025, 0.01, 0.02]
%                   arrays must match in size if given
%
% Output fields:
%
%       srf         spherical surface
%       densm       density SMP
%
% Note: this method simply passes to SRF::Morph. It automatically set
%       area and distortion correction (to 3 - eps)

% Version:  v0.9d
% Build:    14061712
% Date:     Jun-17 2014, 12:23 PM EST
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
ngiven = false;
if nargin < 2 || ...
    isempty(niter) || ...
    numel(niter) > 8 || ...
   ~isa(niter, 'double') || ...
    any(isnan(niter(:)) | niter(:) < 0 | niter(:) > 1e5)
    try
        niter = xffconf.settings.Morphing.ToSphere.NrOfIterations;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        niter = [12000, 8000, 5000, 3000];
    end
else
    ngiven = true;
    niter = floor(niter(:)');
end
if nargin < 3 || ...
   ~isa(mforce, 'double') || ...
    numel(mforce) ~= numel(niter) || ...
    any(isnan(mforce(:)) | mforce(:) <= 0 | mforce(:) >= 1)
    if ngiven
        mforce = 0.5 * (niter:-1:1) ./ niter;
    else
        try
            mforce = xffconf.settings.Morphing.ToSphere.Force;
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            mforce = [0.5, 0.25, 0.1625, 0.125];
        end
    end
end
if nargin < 4 || ...
   ~isa(sforce, 'double') || ...
    numel(sforce) ~= numel(niter) || ...
    any(isnan(sforce(:)) | sforce(:) <= 0 | sforce(:) >= 1)
    if ngiven
        sforce = 0.02 * (2 ^ 0:(niter - 1)) ./ (2 ^ (niter - 1));
    else
        try
            sforce = xffconf.settings.Morphing.ToSphere.SphereForce;
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            sforce = [0.0003, 0.0025, 0.01, 0.02];
        end
    end
end
if nargin < 5 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
opts.areac = 1;
opts.distc = 3 - eps;
opts.distwsq = 1;
title = 'Morphing to sphere';

% get filename
sc = xffgetscont(hfile.L);
srffile = sc.F;
if numel(srffile) > 4 && ...
    strcmpi(srffile(end-3:end), '.srf')
    tfilename = [srffile(1:end-4) '_ToSphere.srf'];
else
    tfilename = '';
end
% iterate over steps
for nc = 1:numel(niter)
    opts.sphere = sforce(nc);
    opts.title = sprintf('%s, forces: %f/%f', title, mforce(nc), sforce(nc));
    if nc < numel(niter) || nargout < 2
        srf_Morph(hfile, niter(nc), mforce(nc), 'smooth', opts);
    else
    [hfile, densm] = srf_Morph(hfile, niter(end), mforce(end), 'smooth', opts);
    end
    if ~isempty(tfilename)
        try
            aft_SaveAs(hfile, tfilename);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
        end
    end
end

% center sphere and force to radius
sc = xffgetscont(hfile.L);
bc = sc.C;
sc.F = srffile;
c = bc.VertexCoordinate;
mnc = min(c);
mxc = max(c);
c = c - repmat((mnc + mxc) / 2, [size(c, 1), 1]);
cr = sqrt(sum(c .* c, 2));
mcr = mean(cr);
c = c .* repmat(mcr ./ cr, [1, 3]);
c = c + repmat(bc.MeshCenter, [size(c, 1), 1]);
sc.C.VertexCoordinate = c;
xffsetscont(hfile.L, sc);
srf_RecalcNormals(hfile);

% remove tempfile
if ~isempty(tfilename) && ...
    exist(tfilename, 'file') == 2
    try
        delete(tfilename);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end
