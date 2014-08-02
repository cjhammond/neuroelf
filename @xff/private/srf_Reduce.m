function hfile = srf_Reduce(hfile, rfac)
% SRF::Reduce  - reduce regular (icosahedron) SRF by factor 4
%
% FORMAT:       [srf = ] srf.Reduce([rfac]);
%
% Input fields:
%
%       rfac        optional face-reduction factor (default 0.25)
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

% check arguments
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'srf')
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
    numel(rfac) ~= 1 || ...
   ~isa(rfac, 'double') || ...
    isinf(rfac) || ...
    isnan(rfac) || ...
    rfac <= 0 || ...
   (rfac >= 1 && ...
    rfac < 20)
    rfac = 0.25;
end
bc = xffgetcont(hfile.L);
if rfac > bc.NrOfTriangles
    return;
elseif rfac < 1
    rfac = round(bc.NrOfTriangles * rfac);
end

% irregular reduction
pfac = log2((bc.NrOfVertices - 2) / 10) / 2;
ffac = log2(bc.NrOfTriangles / 20) / 2;
if rfac ~= (0.25 * bc.NrOfTriangles) || ...
    pfac ~= fix(pfac) || ...
    ffac ~= fix(ffac) || ...
    pfac ~= ffac || ...
    pfac < 1

    % try to use Matlab's reducepatch function
    try
        nfv = reducepatch(struct( ...
            'faces',    bc.TriangleVertex, ...
            'vertices', bc.VertexCoordinate), rfac);

        % set into
        bc.NrOfVertices = size(nfv.vertices, 1);
        bc.NrOfTriangles = size(nfv.faces, 1);
        bc.VertexCoordinate = nfv.vertices;
        bc.VertexNormal = zeros(bc.NrOfVertices, 3);
        bc.VertexColor = zeros(bc.NrOfVertices, 4);
        bc.Neighbors = mesh_trianglestoneighbors(bc.NrOfVertices, nfv.faces);
        bc.TriangleVertex = nfv.faces;
        bc.NrOfTriangleStrips = 0;
        bc.TriangleStripSequence = zeros(0, 1);
        bc.AutoLinkedSRF = '';
        xffsetcont(hfile.L, bc);
        srf_RecalcNormals(hfile);
        return;
    catch ne_eo;
        error( ...
            'xff:ReductionFailed', ...
            'Error reducing number of faces: %s.', ...
            ne_eo.message ...
        );
    end
end

% build new size
pnum = (2 ^ (pfac * 2 - 2)) * 10 + 2;
fnum = (2 ^ (pfac * 2 - 2)) * 20;

% set new options
bc.NrOfVertices = pnum;
bc.NrOfTriangles = fnum;
bc.VertexCoordinate(pnum+1:end, :) = [];
bc.VertexNormal(pnum+1:end, :) = [];
bc.VertexColor(pnum+1:end, :) = [];
bc.AutoLinkedSRF = '';

% building new connections
cnx = cell(pnum, 2);
ocn = bc.Neighbors(:, 2);
rfc = 0;
for c = 1:pnum
    oc = ocn{c};
    nc = [];
    ii = [];
    for vc = oc(:)'
        iv = intersect(oc, ocn{vc});
        for ic = iv(:)'
            ii = union(ii, intersect(ocn{vc}, ocn{ic}));
        end
        ii = setdiff(ocn{vc}, union(ii, iv));
        nc = [nc ii(:)'];
    end
    if any(nc > pnum)
        error( ...
            'xff:MathError', ...
            'Invalid point in new connection list entry.' ...
        );
    end
    cnx{c, 1} = length(nc);
    cnx{c, 2} = nc;
    rfc = rfc + length(nc);
end
bc.Neighbors = cnx;

% building new faces
cnx = cnx(:, 2);
nfs = zeros(rfc, 3);
rfc = 1;
for c = 1:pnum
    fcp = [cnx{c} cnx{c}(1)];
    for cc = 1:length(fcp)-1
        if all(fcp(cc:cc+1) > c)
            nfs(rfc, :) = [c fcp(cc:cc+1)];
        elseif fcp(cc) < fcp(cc+1)
            nfs(rfc, :) = [fcp(cc:cc+1) c];
        else
            nfs(rfc, :) = [fcp(cc+1) c fcp(cc)];
        end
        rfc = rfc + 1;
    end
end
bc.TriangleVertex = unique(nfs, 'rows');
if size(bc.TriangleVertex, 1) ~= fnum
    error( ...
        'xff:MathError', ...
        'Failure reconnecting vertices to faces.' ...
    );
end

% set back
xffsetcont(hfile.L, bc);

% recalc normals
srf_RecalcNormals(hfile);
