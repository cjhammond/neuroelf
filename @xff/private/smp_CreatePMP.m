function pmp = smp_CreatePMP(hfile, srf, mapsel, res)
% SMP::CreatePMP  - create sPherical MaP from SMP
%
% FORMAT:       pmp = smp.CreatePMP(srf [, mapsel [, res]]);
%
% Input fields:
%
%       srf         SRF object for coordinate information
%       mapsel      map selection (default: all)
%       res         1x2 vector with PMP resolution (default: [360, 180])
%
% Output fields:
%
%       pmp         PMP sampled SMP

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2010, 2014, Jochen Weber
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
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'smp') || ...
    numel(srf) ~= 1 || ...
   ~xffisobject(srf, true, 'srf')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
sbc = xffgetcont(srf.L);
if bc.NrOfVertices ~= sbc.NrOfVertices
    error( ...
        'xff:BadArgument', ...
        'SMP and SRF objects must match in NrOfVertices property.' ...
    );
end
if nargin < 3 || ...
   ~isa(mapsel, 'double') || ...
    isempty(mapsel) || ...
    any(isinf(mapsel(:)) | isnan(mapsel(:)))
    mapsel = 1:numel(bc.Map);
else
    mapsel = unique(min(max(round(mapsel(:)'), 1), numel(bc.Map)));
    mapsel(mapsel < 1) = [];
end
if nargin < 4 || ...
   ~isa(res, 'double') || ...
   ~isequal(size(res), [1, 2]) || ...
    any(isinf(res) | isnan(res) | res < 90 | res > 1440)
    res = [360, 180];
else
    res = round(res);
end

% prepare output
pmp = bless(xff('new:pmp'), 1);
pmpc = xffgetcont(pmp.L);
pmpc.ThetaResolution = res(1);
pmpc.PhiResolution = res(2);
if res(1) ~= 360 || ...
    res(2) ~= 180
    pmpc.FileVersion = 257;
end

% check for good input or return empty container
nmapsel = numel(mapsel);
if isempty(bc.Map) || ...
    nmapsel == 0
    warning( ...
        'xff:BadArgument', ...
        'Invalid map selection or empty SMP provided.' ...
    );
    xffsetcont(pmp.L, pmpc);
    return;
end

% get coordinates, triangles and reference list
crd = normvecs(sbc.VertexCoordinate - ...
    repmat(sbc.MeshCenter, [size(sbc.VertexCoordinate, 1), 1]));
tri = sbc.TriangleVertex;
[tn1, tn2, tn3] = mesh_trianglestoneighbors(size(crd, 1), tri);

% create PMP coordinate
[pmpy, pmpx] = ndgrid(0:2*pi/res(1):2*pi-1/res(1), 0:pi/res(2):pi-1/res(2));
pmpcrd = spherecoordsinv([ones(numel(pmpy), 1), pmpx(:), pmpy(:)]);

% map coordinates
[pmpt, pmpvl] = mesh_trimapmesh(pmpcrd, crd, tri, tn3);
pmpvx = 1 - sum(pmpvl, 2);

% prepare smp data
tri = tri(pmpt, :);

% get map values and neighbors
pmpc.Map(nmapsel).PMPData = [];
for mc = 1:nmapsel
    mapd = bc.Map(mapsel(mc)).SMPData;
    pmpc.Map(mc).PMPData = reshape( ...
        pmpvx .* mapd(tri(:, 1)) + ...
        pmpvl(:, 1) .* mapd(tri(:, 2)) + ...
        pmpvl(:, 2) .* mapd(tri(:, 3)), res);
end

% set in structure
pmpc.NrOfMaps = numel(pmpc.Map);
xffsetcont(pmp.L, pmpc);
