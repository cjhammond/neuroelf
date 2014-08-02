function nhfile = mtc_ApplyTSM(hfile, tsm, tri)
% MTC::ApplyTSM  - resample MTC with TSM mapping
%
% FORMAT:       newmtc = mtc.ApplyTSM(tsm, tri)
%
% Input fields:
%
%       tsm         Triangular-Sphere-Mapping (TSM) object
%       tri         triangle vertices (SRF .TriangleVertex field)
%
% Output fields:
%
%       newmtc      MTC with resampled timecourses

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
if nargin < 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'mtc') || ...
    numel(tsm) ~= 1 || ...
   ~xffisobject(tsm, true, 'tsm') || ...
   ~isa(tri, 'double') || ...
    size(tri, 2) ~= 3 || ...
    any(isinf(tri(:)) | isnan(tri(:)) | tri(:) < 1 | tri(:) ~= fix(tri(:)))
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
tsmc = xffgetcont(tsm.L);
if size(bc.MTCData, 2) ~= tsmc.NrOfSourceVertices
    error( ...
        'xff:BadArgument', ...
        'NrOfVertices must match with NrOfSourceVertices in TSM object.' ...
    );
end
if size(tri, 1) ~= tsmc.NrOfSourceTriangles
    error( ...
        'xff:BadArgument', ...
        'tri must match in size with NrOfSourceTriangles in TSM object.' ...
    );
end

% copy object
nhfile = aft_CopyObject(hfile);
nbc = xffgetcont(nhfile.L);
nbc.NrOfVertices = numel(tsmc.SourceTriangleOfTarget);

% compute weights
w = limitrangec(tsmc.TriangleEdgeLengths', 0, 1, 0);
w = limitrangec([1 - sum(w, 1); w], 0, 1, 0);
w = (ones(3, 1) * (1 ./ sum(w, 1))) .* w;
w(any(isinf(w) | isnan(w), 1), :) = 1 / 3;

% get vertices of triangles
tv = tri(tsmc.SourceTriangleOfTarget, :);

% compute weighted sum
ntp = ones(1, size(bc.MTCData, 1));
nmtc = w(ntp, :) .* double(bc.MTCData(:, tv(:, 1)));
nmtc = nmtc + w(2 .* ntp, :) .* double(bc.MTCData(:, tv(:, 2)));
nmtc = nmtc + w(3 .* ntp, :) .* double(bc.MTCData(:, tv(:, 2)));
nmtc = single(nmtc);
nbc.MTCData = nmtc;
xffsetcont(nhfile.L, nbc);
