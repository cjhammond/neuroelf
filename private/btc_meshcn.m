% FUNCTION [c, n] = btc_meshcn: compute coordinates and normals
function [c, n] = btc_meshcn(srf, cc, fac)

% Version:  v0.9d
% Build:    14062121
% Date:     Jun-21 2014, 9:36 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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

% global variable (for error handling)
global ne_gcfg;

% get surface content
srfsc = getscont(srf);
srfc = srfsc.C;
srfh = srfsc.H;

% get global angle and zoom
ang = (pi / 180) .* [cc.anglex, cc.angley];
cang = cos(ang);
sang = sin(ang);
zoom = cc.zoom;
midx = min(size(srfh.VertexMorphMeshes, 1), max(0, cc.time));

% compute global transformation matrices
atrf = [cang(2), 0, sang(2), 0; 0, 1, 0, 0; -sang(2), 0, cang(2), 0; 0, 0, 0, 1] * ...
       [cang(1), sang(1), 0, 0; -sang(1), cang(1), 0, 0; 0, 0, 1, 0; 0, 0, 0, 1];
ptrf = [1, 0, 0, cc.trans(1); 0, 1, 0, cc.trans(2); 0, 0, 1, cc.trans(3); 0, 0, 0, 1] * ...
    atrf * [zoom, 0, 0, 0; 0, zoom, 0, 0; 0, 0, zoom, 0; 0, 0, 0, 1];
atrf = atrf(1:3, 1:3)';

% compute TAL coordinates if necessary
if ~isfield(srfh, 'VertexCoordinateTal') || ...
   ~isequal(size(srfh.VertexCoordinateTal), size(srfc.VertexCoordinate)) || ...
    srfh.VertexMorphIndex ~= midx

    % what content
    szcrd = size(srfc.VertexCoordinate);
    if midx == 0 || ...
       ~isequal(size(srfh.VertexMorphMeshes{max(1, floor(midx)), 1}), szcrd) || ...
       ~isequal(size(srfh.VertexMorphMeshes{ceil(midx), 1}), szcrd)

        % get coordinates and center
        c = srfc.VertexCoordinate;
        mshc = srfc.MeshCenter;

        % remove center from coordinates and set to TAL notation
        if all(mshc == mshc(1))
            c = mshc(1) - c(:, [3, 1, 2]);
        else
            c = [mshc(3) - c(:, 3), mshc(1) - c(:, 1), mshc(2) - c(:, 2)];
        end

        % get normals (in TAL notation)
        n = srfc.VertexNormal(:, [3, 1, 2]);
        
    % full coordinates
    elseif midx == round(midx)
        
        % access those instead
        c = srfh.VertexMorphMeshes{midx, 1};
        mshc = srfh.VertexMorphMeshes{midx, 3};
        if all(mshc == mshc(1))
            c = mshc(1) - c(:, [3, 1, 2]);
        else
            c = [mshc(3) - c(:, 3), mshc(1) - c(:, 1), mshc(2) - c(:, 2)];
        end
        n = srfh.VertexMorphMeshes{midx, 2}(:, [3, 1, 2]);
        
    % morphing
    else
        
        % linear mix
        bidx = floor(midx);
        tmrp = midx - bidx;
        bmrp = 1 - tmrp;
        if bidx == 0
            c1 = srfc.VertexCoordinate;
            mshc1 = srfc.MeshCenter;
        else
            c1 = srfh.VertexMorphMeshes{bidx, 1};
            mshc1 = srfh.VertexMorphMeshes{bidx, 3};
        end
        c2 = srfh.VertexMorphMeshes{bidx+1, 1};
        mshc2 = srfh.VertexMorphMeshes{bidx+1, 3};
        if all(mshc1 == mshc1(1))
            c1 = mshc1(1) - c1(:, [3, 1, 2]);
        else
            c1 = [mshc1(3) - c1(:, 3), mshc1(1) - c1(:, 1), mshc1(2) - c1(:, 2)];
        end
        if all(mshc2 == mshc2(1))
            c2 = mshc2(1) - c2(:, [3, 1, 2]);
        else
            c2 = [mshc2(3) - c2(:, 3), mshc2(1) - c2(:, 1), mshc2(2) - c2(:, 2)];
        end
        c = (bmrp .* c1 + tmrp .* c2);

        % re-compute normals
        n = -mesh_normals(c, srfc.TriangleVertex);
    end
    
    % set in handles and keep track of last index
    srf.SetHandle('VertexCoordinateTal', c);
    srf.SetHandle('VertexNormalTal', n);
    srf.SetHandle('VertexMorphIndex', midx);
else
    c = srfh.VertexCoordinateTal;
    n = srfh.VertexNormalTal;
end

% compute surface specific transformation matrices
scc = srfh.SurfProps;
iptrf = scc{1};
cscc = cos(scc{2});
sscc = sin(scc{2});
ipzoom = scc{3};
if numel(ipzoom) == 1
    ipzoom = ipzoom([1, 1, 1]);
end
iatrf = [1, 0, 0, 0; 0, cscc(1), sscc(1), 0; 0, -sscc(1), cscc(1), 0; 0, 0, 0, 1] * ...
      [cscc(2), 0, sscc(2), 0; 0, 1, 0, 0; -sscc(2), 0, cscc(2), 0; 0, 0, 0, 1] * ...
      [cscc(3), sscc(3), 0, 0; -sscc(3), cscc(3), 0, 0; 0, 0, 1, 0; 0, 0, 0, 1];
iptrf = [1, 0, 0, iptrf(1); 0, 1, 0, iptrf(2); 0, 0, 1, iptrf(3); 0, 0, 0, 1] * ...
    iatrf * [ipzoom(1), 0, 0, 0; 0, ipzoom(2), 0, 0; 0, 0, ipzoom(3), 0; 0, 0, 0, 1];
iatrf = iatrf(1:3, 1:3)';
ctrf = (iptrf * ptrf)';
ntrf = atrf * iatrf;

% apply transformation
rtv = srfc.RunTimeVars;
if isfield(rtv, 'SPMsn') && ...
    numel(rtv.SPMsn) == 1 && ...
    isstruct(rtv.SPMsn)
    try
        s = rtv.SPMsn;
        c = applyspmsnc(c, ...
            s.Tr, s.VG(1).dim, inv(s.VG(1).mat), s.VF.mat * s.Affine);
    catch ne_eo;
        ne_gcfg.c.lasterr = ne_eo;
    end
end

% apply to coordinates and normals
if all(ctrf(4, 1:3) == 0)
    c = c * ctrf(1:3, 1:3);
else
    c = c * ctrf(1:3, 1:3) + repmat(ctrf(4, 1:3), size(c, 1), 1);
end
if fac
    n = n * ntrf;
else
    n = n * (-ntrf);
end
