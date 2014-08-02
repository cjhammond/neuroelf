function hfile = srf_SetCoordsTriangles(hfile, c, t, opts)
% SRF::SetCoordsTriangles  - set coordinates and triangles
%
% FORMAT:       [srf] = srf.Transform(c, t [, opts])
%
% Input fields:
%
%       c           Cx3 coordinates
%       t           Tx3 triangle vertices (1-based)
%       opts        settings
%        .color     either Cx3 RGB or Cx4 BV style
%        .neigh     neighbors list (default: attempt tri->nei)
%        .normals   manually computed normal vector (Cx3, default: recalc)
%        .swaplr    swap triangle orientation (default: false)
%        .tal       coordinates are tal-based (default: false)
%        .trf       4x4 transformation matrix to apply (before from-tal!)
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

% argument check
if nargin < 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'srf') || ...
   ~isa(c, 'double') || ...
    ndims(c) ~= 2 || ...
    size(c, 2) ~= 3 || ...
    any(isinf(c(:)) | isnan(c(:))) || ...
   (~isa(t, 'double') && ...
    ~isa(t, 'int32') && ...
    ~isa(t, 'uint32')) || ...
    ndims(t) ~= 2 || ...
    size(t, 2) ~= 3 || ...
    any(isinf(t(:)) | isnan(t(:)) | t(:) < 1 | t(:) > size(c, 1) | t(:) ~= fix(t(:)))
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
nc = size(c, 1);
if nargin < 4 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'color') || ...
   (~isa(opts.color, 'uint8') && ...
    ~isa(opts.color, 'double')) || ...
    ndims(opts.color) ~= 2 || ...
    size(opts.color, 1) ~= nc || ...
   ~any(size(opts.color, 2) == [3, 4])
    opts.color = zeros(nc, 4);
else
    if isa(opts.color, 'uint8')
        opts.color = double(opts.color);
    end
    if size(opts.color, 2) == 3
        if all(opts.color(:) <= 1)
            opts.color = 255 .* opts.color;
        end
        opts.color = [nan .* ones(nc, 1), opts.color];
    end
    opts.color(:, 2:4) = round(min(255, max(0, opts.color)));
end
if ~isfield(opts, 'neigh') || ...
   ~iscell(opts.neigh) || ...
   ~isequal(size(opts.neigh), [nc, 2])
    opts.neigh = {};
end
if ~isfield(opts, 'normals') || ...
   ~isa(opts.normals, 'double') || ...
   ~isequal(size(opts.normals), size(c)) || ...
    any(isinf(opts.normals(:)) | isnan(opts.normals(:)))
    opts.normals = [];
end
if ~isfield(opts, 'swaplr') || ...
   ~islogical(opts.swaplr) || ...
    numel(opts.swaplr) ~= 1
    opts.swaplr = false;
end
if ~isfield(opts, 'tal') || ...
   ~islogical(opts.tal) || ...
    numel(opts.tal) ~= 1
    opts.tal = false;
end
if ~isfield(opts, 'trf') || ...
   ~isa(opts.trf, 'double') || ...
   ~isequal(size(opts.trf), [4, 4]) || ...
    any(isinf(opts.trf(:)) | isnan(opts.trf(:))) || ...
    any(opts.trf(4, :) ~= [0, 0, 0, 1])
    opts.trf = [];
end
bc = xffgetcont(hfile.L);

% apply transformation if necessary
if ~isempty(opts.trf)
    c(:, 4) = 1;
    c = c * opts.trf';
    c(:, 4) = [];

    % also to normals ?
    if ~isempty(opts.normals)
        opts.normals = opts.normals * opts.trf(1:3, 1:3)';
    end
end

% normalize normals
if ~isempty(opts.normals)
    opts.normals = ...
        repmat(1 ./ sqrt(sum(opts.normals .^ 2, 2)), 1, 3) .* opts.normals;
end

% swap L/R
if opts.swaplr
    t = t(:, [1, 3, 2]);

    % also with neighbors ?
    if ~isempty(opts.neigh)
        for cc = 1:nc
            opts.neigh{cc, 2} = opts.neigh{cc, 2}(end:-1:1);
        end
    end
end

% tal-transform
if opts.tal
    c = ones(nc, 1) * bc.MeshCenter - c(:, [2, 3, 1]);
end

% neighbors
if isempty(opts.neigh)
    try
        [opts.neigh, bn] = mesh_trianglestoneighbors(nc, t);
        for cc = 1:numel(bn)
            opts.neigh{bn(cc), 2} = bn{cc};
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        n = cell(nc, 2);
        tn = [t; t(:, [2, 3, 1]); t(:, [3, 1, 2])];
        tn = sortrows(tn);
        nn = tn(1);
        nlist = tn(1, 2:3);
        for cc = 2:size(tn, 1)
            if tn(cc, 1) > nn
                nlist = unique(nlist);
                n(nn, :) = {numel(nlist), nlist};
                nn = tn(cc, 1);
                nlist = tn(cc, 2:3);
            else
                nlist(end+1:end+2) = tn(cc, 2:3);
            end
        end
        nlist = unique(nlist);
        n(nn, :) = {numel(nlist), nlist};
        opts.neigh = n;
    end
end

% set in content
bc.NrOfVertices = nc;
bc.NrOfTriangles = size(t, 1);
bc.VertexCoordinate = c;
bc.VertexNormal = opts.normals;
bc.VertexColor = opts.color;
bc.Neighbors = opts.neigh;
bc.TriangleVertex = t;

% put back in hfile
xffsetcont(hfile.L, bc);

% recalc normals
if isempty(opts.normals)
    srf_RecalcNormals(hfile);
end
