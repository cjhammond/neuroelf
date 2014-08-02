function hfile = srf_AddMarkers(hfile, crd, opts)
% SRF::AddMarkers  - add arbitrary markers at coordinates
%
% FORMAT:       [srf] = srf.AddMarkers(crd [, opts]);
%
% Input fields:
%
%       crd         Cx3 coordinates
%       opts        struct with optional fields
%        .color     1x3 or Cx3 RGB color, otherwise red
%        .shape     one of 'cube' or {'sphere'}
%        .size      1x1 or Cx1 doulbe, default 3 units
%        .tal2bvc   flag, apply TAL to BV transform (default: true)
%
% Output fields:
%
%       srf         altered object

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

% load unit sphere
global xffconf;
if ~isfield(xffconf.loadedobjs, 'srf_AddSurfacePoints')
    try
        ufn = [neuroelf_path('srf') '/unitcube.srf'];
        [usrf, usrfl] = xff(ufn);
        if ~xffisobject(usrf, true, 'srf')
            error('BAD_SURFACE');
        end
        cubebc = xffgetcont(usrf.L);
        xffconf.loadedobjs.srf_AddSurfacePoints = struct;
        xffconf.loadedobjs.srf_AddSurfacePoints.unitcube = cubebc;
        if usrfl
            xffclear(usrf.L);
        end
        ufn = [neuroelf_path('srf') '/unitsphere320.srf'];
        [usrf, usrfl] = xff(ufn);
        if ~xffisobject(usrf, true, 'srf')
            error('BAD_SURFACE');
        end
        sphrbc = xffgetcont(usrf.L);
        xffconf.loadedobjs.srf_AddSurfacePoints.unitsphere = sphrbc;
        if usrfl
            xffclear(usrf.L);
        end
        ufn = [neuroelf_path('srf') '/unittridown.srf'];
        [usrf, usrfl] = xff(ufn);
        if ~xffisobject(usrf, true, 'srf')
            error('BAD_SURFACE');
        end
        tridbc = xffgetcont(usrf.L);
        xffconf.loadedobjs.srf_AddSurfacePoints.unittridown = tridbc;
        if usrfl
            xffclear(usrf.L);
        end
        ufn = [neuroelf_path('srf') '/unittriup.srf'];
        [usrf, usrfl] = xff(ufn);
        if ~xffisobject(usrf, true, 'srf')
            error('BAD_SURFACE');
        end
        triubc = xffgetcont(usrf.L);
        xffconf.loadedobjs.srf_AddSurfacePoints.unittriup = triubc;
        if usrfl
            xffclear(usrf.L);
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        error( ...
            'xff:FileNotFound', ...
            'Required unit sphere surface not found: ''%s''.', ...
            ufn ...
        );
    end
else
    try
        cubebc = xffconf.loadedobjs.srf_AddSurfacePoints.unitcube;
        sphrbc = xffconf.loadedobjs.srf_AddSurfacePoints.unitsphere;
        tridbc = xffconf.loadedobjs.srf_AddSurfacePoints.unittridown;
        triubc = xffconf.loadedobjs.srf_AddSurfacePoints.unittriup;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        xffconf.loadedobjs = rmfield(xffconf.loadedobjs, 'srf_AddSurfacePoints');
        error( ...
            'xff:InternalError', ...
            'Unit cube/sphere surfaces removed from global config.' ...
        );
    end
end

% check arguments
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'srf') || ...
   ~isa(crd, 'double') || ...
    size(crd, 2) ~= 3 || ...
    any(isinf(crd(:)) | isnan(crd(:)) | crd(:) < -128 | crd(:) > 256)
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
srfbc = xffgetcont(hfile.L);
ncrd = size(crd, 1);
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'color') || ...
   ~isa(opts.color, 'double') || ...
    size(opts.color, 2) ~= 3 || ...
   ~any(size(opts.color, 1) == [1, ncrd]) || ...
    any(isinf(opts.color(:)) | isnan(opts.color(:)) | opts.color(:) < 0)
    opts.color = [255, 0, 0];
else
    opts.color = min(255, opts.color(:, 1:3, 1));
    if all(opts.color(:) <= 1)
        opts.color = opts.color * 255;
    end
    opts.color = round(opts.color);
end
if size(opts.color, 1) == 1
    opts.color = repmat(opts.color, [ncrd, 1]);
end
if ~isfield(opts, 'shape') || ...
   ~ischar(opts.shape) || ...
   ~any(strcmpi(opts.shape(:)', {'cube', 'sphere', 'tridown', 'triup'}))
    opts.shape = 'sphere';
else
    opts.shape = lower(opts.shape(:)');
end
if ~isfield(opts, 'size') || ...
   ~isa(opts.size, 'double') || ...
    numel(opts.size) ~= length(opts.size) || ...
   ~any(numel(opts.size) == [1, ncrd]) || ...
    any(isinf(opts.size) | isnan(opts.size) | opts.size <= 0)
    opts.size = 3;
else
    opts.size = opts.size(:);
    opts.size(opts.size > 16) = 16;
end
if numel(opts.size) == 1
    opts.size = repmat(opts.size, [ncrd, 1]);
end
if ~isfield(opts, 'tal2bvc') || ...
   ~islogical(opts.tal2bvc) || ...
    numel(opts.tal2bvc) ~= 1
    opts.tal2bvc = true;
end
if opts.tal2bvc
    crd = bvcoordconv(crd, 'tal2bvc', aft_BoundingBox(hfile));
end

% select shape
switch (opts.shape)
    case {'cube'}
        usrfbc = cubebc;
    case {'sphere'}
        usrfbc = sphrbc;
    case {'tridown'}
        usrfbc = tridbc;
    case {'triup'}
        usrfbc = triubc;
end

% set to RGB color mode and make copy of unit sphere coordinates
usrfbc.VertexColor(:, 1) = NaN;
usrfc = usrfbc.VertexCoordinate;
nvert = size(usrfc, 1);
usrfc = usrfc - repmat(usrfbc.MeshCenter, [nvert, 1]);

% make new srf
nsrf = xff('new:srf');
nsrfbc = xffgetcont(nsrf.L);
nsrfbc.NrOfVertices = 0;
nsrfbc.NrOfTriangles = 0;
nsrfbc.MeshCenter = srfbc.MeshCenter;
nsrfbc.VertexCoordinate = zeros(0, 3);
nsrfbc.VertexNormal = zeros(0, 3);
nsrfbc.VertexColor = zeros(0, 4);
nsrfbc.Neighbors = cell(0, 2);
nsrfbc.TriangleVertex = zeros(0, 3);
nsrfbc.NrOfTriangleStrips = 0;
nsrfbc.TriangleStripSequence = zeros(0, 1);

% get coordinate table of fiducials
fidt = [crd, opts.size, opts.color];

% first add all spheres to new srf
for sc = 1:ncrd
    fid = fidt(sc, :);
    fidc = repmat(fid(1:3), [nvert, 1]);
    usrfbc.VertexCoordinate = fid(4) * usrfc + fidc;
    usrfbc.VertexColor(:, 2:4) = repmat(round(fid(5:7)), [nvert, 1]);
    cnv = size(nsrfbc.VertexCoordinate, 1);
    nsrfbc.VertexCoordinate = ...
        [nsrfbc.VertexCoordinate; usrfbc.VertexCoordinate];
    nsrfbc.VertexNormal = ...
        [nsrfbc.VertexNormal; usrfbc.VertexNormal];
    nsrfbc.VertexColor = ...
        [nsrfbc.VertexColor; usrfbc.VertexColor];
    nnei = ...
        [nsrfbc.Neighbors; usrfbc.Neighbors];
    nsrfbc.TriangleVertex = ...
        [nsrfbc.TriangleVertex; (usrfbc.TriangleVertex + cnv)];
    for vc = (cnv+1):size(nnei, 1)
        nnei{vc, 2} = nnei{vc, 2} + cnv;
    end
    nsrfbc.Neighbors = nnei;
end

% make nsrf settings
nsrfbc.NrOfVertices = size(nsrfbc.VertexNormal, 1);
nsrfbc.NrOfTriangles = size(nsrfbc.TriangleVertex, 1);
xffsetcont(nsrf.L, nsrfbc);

% add spheres to srf
nfile = srf_Combine(hfile, nsrf, struct('type', 'wholebrain'));
xffsetcont(hfile.L, xffgetcont(nfile.L));
xffclear(nfile.L);
