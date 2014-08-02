function hfile = voi_AddSphericalVOI(hfile, c, r)
% VOI::AddSphericalVOI  - add a spherically shaped VOI to the object
%
% FORMAT:       [voi = ] voi.AddSphericalVOI(c, r);
%
% Input fields:
%
%       c           1x3 coordinate (center)
%       r           1x1 radius (must be > 0 and < 128)
%
% Output fields:
%
%       voi         VOI with added VOI (integer coordinates only!)

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
if nargin ~= 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'voi') || ...
   ~isa(c, 'double') || ...
    numel(c) ~= 3 || ...
    any(isinf(c) | isnan(c) | c < -128 | c > 256) || ...
   ~isa(r, 'double') || ...
    numel(r) ~= 1 || ...
    isinf(r) || ...
    isnan(r) || ...
    r < 0 || ...
    r > 128
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);

% coordinate valid in current system
if (strcmpi(bc.ReferenceSpace, 'tal') && ...
    any(c > 128)) || ...
   (~strcmpi(bc.ReferenceSpace, 'tal') && ...
    any(c < 0))
    error( ...
        'xff:BadArgument', ...
        'Invalid coordinate given (wrong coordinate system).' ...
    );
end
if strcmpi(bc.ReferenceSpace, 'tal')
    bb = [-128, 128];
else
    bb = [0, 256];
end

% create grid
rc = round(c);
cr = ceil(r + 0.5);
[xg, yg, zg] = ndgrid( ...
    rc(1)-cr:rc(1)+cr, rc(2)-cr:rc(2)+cr, rc(3)-cr:rc(3)+cr);

% fill with grid
xg = [xg(:), yg(:), zg(:)];

% remove voxels beyond bounding box
xg(any(xg < bb(1), 2) | any(xg > bb(2), 2), :) = [];

% compute distance
yg = sqrt(sum((xg - c(ones(1, size(xg, 1)), :)) .^ 2, 2));

% sort by distance
[yg, ygi] = sort(yg);
xg = xg(ygi, :);

% remove further away stuff
xg(yg > r, :) = [];

% create VOI structure
voi = struct( ...
    'Name', sprintf('Sphere_%.1f_%.1f_%.1f_-_r%.1f', c(1), c(2), c(3), r), ...
    'Color', floor(255.99 * rand(1, 3)), ...
    'NrOfVoxels', size(xg, 1), ...
    'Voxels', xg);

% set back
if numel(fieldnames(voi)) == numel(fieldnames(bc.VOI)) && ...
    all(strcmp(fieldnames(voi), fieldnames(bc.VOI)))
    bc.VOI(end + 1) = voi;
else
    bc.VOI = joinstructs(bc.VOI(:), voi);
end
bc.NrOfVOIs = numel(bc.VOI);
xffsetcont(hfile.L, bc);
