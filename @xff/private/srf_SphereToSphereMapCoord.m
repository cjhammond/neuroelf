function ssm = srf_SphereToSphereMapCoord(hfile, hfile2)
% SRF::SphereToSphereMapCoord  - coordinate-based Sphere-To-Sphere mapping
%
% FORMAT:       ssm = srf.SphereToSphereMapCoord(srf2)
%
% Input fields:
%
%       srf         target sphere
%       srf2        source sphere
%
% Output fields:
%
%       ssm         SSM file with mapping target <- sphere

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
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'srf') || ...
    numel(hfile2) ~= 1 || ...
   ~xffisobject(hfile2, true, 'srf')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get contents
bc1 = xffgetcont(hfile.L);
bc2 = xffgetcont(hfile2.L);

% compute a few things first
c1 = bc1.VertexCoordinate;
c2 = bc2.VertexCoordinate;
nc1 = size(c1, 1);
nc2 = size(c2, 1);
c1(:, 1) = c1(:, 1) - (min(c1(:, 1)) + max(c1(:, 1))) / 2;
c1(:, 2) = c1(:, 2) - (min(c1(:, 2)) + max(c1(:, 2))) / 2;
c1(:, 3) = c1(:, 3) - (min(c1(:, 3)) + max(c1(:, 3))) / 2;
c2(:, 1) = c2(:, 1) - (min(c2(:, 1)) + max(c2(:, 1))) / 2;
c2(:, 2) = c2(:, 2) - (min(c2(:, 2)) + max(c2(:, 2))) / 2;
c2(:, 3) = c2(:, 3) - (min(c2(:, 3)) + max(c2(:, 3))) / 2;
r1 = sqrt(sum(c1 .* c1, 2));
r2 = sqrt(sum(c2 .* c2, 2));
sp1 = spherecoords(c1);
sp2 = spherecoords(c2);

% put the data into quad areas, first estimate a good area size
qs = [180, 120, 90, 60, 48, 36, 30, 24, 20, 16, 12, 10, 8, 6, 4, 2];
qs = qs(findfirst(floor(nc2 ./ (qs .* qs)) >= 9));

% if even 2 is too much (only 4!)
if isempty(qs)
    error( ...
        'xff:BadArgument', ...
        'Too few vertices for matching algorithm.' ...
    );
end

% get some interim numbers
qsh = qs / 2;
qss = qs * qs;
qsm = qs - 1;
qssm = qss - qs;

% and now put the data in there
q1 = 1 + min(qssm, qs * floor(qsh + qsh * cos(sp1(:, 2)))) + ...
    min(qsm, qsh + floor(qsh * sp1(:, 3) / pi));
q2 = 1 + min(qssm, qs * floor(qsh + qsh * cos(sp2(:, 2)))) + ...
    min(qsm, qsh + floor(qsh * sp2(:, 3) / pi));
[q2s, q2i] = sort(q2);
q2d = [find([1, diff(q2s(:)')]), numel(q2) + 1];
if numel(q2d) ~= (qss + 1)
    if qs > 2
        warning( ...
            'xff:Internal', ...
            'Vertices are highly unevenly spread, matching slowed down.' ...
        );
        qs = qs / 2;
        qsh = qs / 2;
        qss = qs * qs;
        qsm = qs - 1;
        qssm = qss - qs;

        % and now put the data in there
        q1 = 1 + min(qssm, qs * floor(qsh + qsh * cos(sp1(:, 2)))) + ...
            min(qsm, qsh + floor(qsh * sp1(:, 3) / pi));
        q2 = 1 + min(qssm, qs * floor(qsh + qsh * cos(sp2(:, 2)))) + ...
            min(qsm, qsh + floor(qsh * sp2(:, 3) / pi));
        [q2s, q2i] = sort(q2);
        q2d = [find([1, diff(q2s(:)')]), numel(q2) + 1];
    end
    if numel(q2d) ~= (qss + 1)
        error( ...
            'xff:BadArgument', ...
            'Emtpy patch(es) in spherical surface, distribution too uneven.' ...
        );
    end
end
q2c = cell(1, qss);
for qc = 1:qss
    q2c{qc} = q2i(q2d(qc):q2d(qc+1)-1);
end

% check spherical shape
if (mean(r1) / std(r1)) < 60 || ...
   (mean(r2) / std(r2)) < 60
    error( ...
        'xff:BadArgument', ...
        'Shapes not spherical enough for matching.' ...
    );
end

% make spherical with r = 1
c1 = c1 ./ r1(:,[1, 1, 1]);
c2 = c2 ./ r2(:,[1, 1, 1]);

% get neighbors list
tf = nc1;
t2 = bc2.TriangleVertex;
n2 = mesh_trianglestoneighbors(nc2, t2);
n2 = n2(:, 2);

% init found array
mf = zeros(tf, 1);

% iterate until all vertices mapped
for m1 = 1:tf

    % get coordinate of target vertex
    cm1 = c1(m1, :);

    % get the vertices in the same quad area
    m2x = q2c{q1(m1)};

    % compute distance
    dst = sqrt(sum((cm1(ones(1, numel(m2x)), :) - c2(m2x, :)) .^ 2, 2));

    % use the one with the shortest distance
    [mval, mpos] = min(dst);
    m2 = m2x(mpos);

    % iterate until match for next vertex found
    while true

        % compute distance between m1 and m2 incl. neighbors
        m2x = cat(2, n2{n2{m2}});
        dst = sqrt(sum((cm1(ones(1, numel(m2x)), :) - c2(m2x, :)) .^ 2, 2));

        % find shortest distance
        [mval, mpos] = min(dst);

        % break if at candidate
        if m2x(mpos) == m2
            break;
        end

        % otherwise set to shortest element
        m2 = m2x(mpos);
    end

    mf(m1) = m2;
end

% create SSM object
ssm = bless(xff('new:ssm'), 1);
ssc = xffgetcont(ssm.L);
ssc.NrOfTargetVertices = nc1;
ssc.NrOfSourceVertices = nc2;
ssc.SourceOfTarget = mf;
xffsetcont(ssm.L, ssc);
