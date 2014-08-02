function srf = vtk_ConvertToSRF(hfile)
% VTK::ConvertToSRF  - convert VTK object to BV SRF object
%
% FORMAT:       srf = vtk.ConvertToSRF;
%
% No input fields
%
% Output fields:
%
%       srf         converted object

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2013, 2014, Jochen Weber
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

% check arguments
if nargin ~= 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vtk')
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
c = bc.Coordinates;
t = bc.Triangles;
if isempty(c) || ...
    isempty(t) || ...
    max(t(:)) ~= size(c, 1)
    error( ...
        'xff:BadObject', ...
        'Invalid VTK object for SRF conversion.' ...
    );
end
nc = size(c, 1);

% create output object
srf = xff('new:srf');
srfc = xffgetcont(srf.L);

% make settings
srfc.NrOfVertices = nc;
srfc.NrOfTriangles = size(t, 1);
srfc.VertexCoordinate = [256 - c(:, 2), c(:, [3, 1])];
srfc.VertexNormal = zeros(nc, 3);
srfc.VertexColor = zeros(nc, 4);
srfc.TriangleVertex = t;
try
    srfc.Neighbors = mesh_trianglestoneighbors(nc, t);
catch ne_eo;
    neuroelf_lasserr(ne_eo);
    xffclear(srf.L);
    error( ...
        'xff:BadObject', ...
        'Invalid triangle configuration to derive neighbors list.' ...
    );
end
xffsetcont(srf.L, srfc);

% bless
bless(srf, 1);

% calculate normals
srf_RecalcNormals(srf);
