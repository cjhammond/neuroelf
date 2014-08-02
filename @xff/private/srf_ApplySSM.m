function nsph = srf_ApplySSM(hfile, ssm, sphere, smiter)
% SRF::ApplySSM  - apply SSM file on vertex coordinates
%
% FORMAT:       sph = srf.ApplySSM(ssm, sphere [, smiter])
%
% Input fields:
%
%       srf         folded mesh (e.g. RECOSM mesh)
%       ssm         SSM mapping to sphere mesh
%       sphere      sphere mesh SRF used for mapping
%       smiter      number of smoothing steps (default = 20, force 0.03)
%
% Output fields:
%
%       sph         SPH mesh with NrOfVertices of sphere, folded as srf

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

% check arguments
if nargin < 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'srf') || ...
    numel(ssm) ~= 1 || ...
   ~xffisobject(ssm, true, 'ssm') || ...
    numel(sphere) ~= 1 || ...
   ~xffisobject(sphere, true, 'srf')
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
if nargin < 4 || ...
    numel(smiter) ~= 1 || ...
   ~isa(smiter, 'double') || ...
    isinf(smiter) || ...
    isnan(smiter) || ...
    smiter < 0 || ...
    smiter > 3000
    smiter = 20;
else
    smiter = round(smiter);
end

% get contents
fldc = xffgetcont(hfile.L);
ssmc = xffgetcont(ssm.L);
sphc = xffgetcont(sphere.L);

% check numbers
if numel(ssmc.SourceOfTarget) ~= size(sphc.VertexCoordinate, 1)
    error( ...
        'xff:BadArgument', ...
        'SSM and Sphere mesh must match.' ...
    );
end
ssmc = ssmc.SourceOfTarget;

% create new SRF from folded mesh
nsph = bless(aft_CopyObject(hfile), 1);
nspc = xffgetcont(nsph.L);

% neighbors and coords
crd = nspc.VertexCoordinate(ssmc, :);
nei = sphc.Neighbors;
tri = sphc.TriangleVertex;

% perform smoothing
opts = struct( ...
    'type',  'smooth', ...
    'force', 0.03, ...
    'niter', smiter, ...
    'areac', 0);
crd = mesh_morph(crd, nei, tri, opts);

% make settings
nspc.ExtendedNeighbors = sphc.ExtendedNeighbors;
nspc.NrOfVertices = sphc.NrOfVertices;
nspc.NrOfTriangles = size(tri, 1);
nspc.VertexCoordinate = crd;
nspc.VertexNormal = nspc.VertexNormal(ssmc, :);
nspc.VertexColor = nspc.VertexColor(ssmc, :);
nspc.Neighbors = nei;
nspc.TriangleVertex = tri;
nspc.NrOfTriangleStrips = sphc.NrOfTriangleStrips;
nspc.TriangleStripSequence = sphc.TriangleStripSequence;
nspc.AutoLinkedSRF = '<none>';

% set back in global memory array
xffsetcont(nsph.L, nspc);
