function stats = vmp_VoxelStats(hfile, mapno, coords, ctype)
% VMP::VoxelStats  - retrieve voxel statistics from map
%
% FORMAT:       stats = vmp.VoxelStats(mapno, coords [, ctype])
%
% Input fields:
%
%       mapno       map number (in range [1..M])
%       coords      Nx3 coordinate list
%       ctype       coordinate system type, one of
%                   'BVInt', {'BVSys'}, 'Tal'
%                   where BVInt is the internal BV coordinate system
%                   BVTal is the same, but uses Tal axes order
%                   Tal is just (127 - BVTal)
%
% Output fields:
%
%       stats       extracted statistics from Map
%
% See also bvcoordconv

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
   ~xffisobject(hfile, true, 'vmp') || ...
   ~isa(mapno, 'double') || ...
    isempty(mapno) || ...
    any(isinf(mapno(:)) | isnan(mapno(:)) | mapno(:) < 1 ) || ...
   ~isa(coords, 'double') || ...
    isempty(coords) || ...
    size(coords, 2) ~= 3 || ...
    any(isinf(coords(:)) | isnan(coords(:)) | coords(:) < -128 | coords(:) > 256)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
if any(mapno(:) > bc.NrOfMaps)
    error( ...
        'xff:BadArgument', ...
        'Map number out of bounds.' ...
    );
end
mapno = round(mapno(:)');
if nargin < 4 || ...
   ~ischar(ctype) || ...
   ~any(strcmpi(ctype(:)', {'bvint', 'bvsys', 'tal'}))
    if any(coords(:) < 0) || ...
       all(coords(:) < 64)
        ctype = 'tal';
    else
        ctype = 'bvsys';
    end
else
    ctype = lower(ctype(:)');
end

% convert coords to internal space
bb = aft_BoundingBox(hfile);
switch (ctype)
    case {'bvint'}
        coords = bvcoordconv(coords, 'bvi2bvx', bb);
    case {'bvsys'}
        coords = bvcoordconv(coords, 'bvs2bvx', bb);
    case {'tal'}
        coords = bvcoordconv(coords, 'tal2bvx', bb);
end

% get data
stats = zeros(numel(coords), numel(mapno));
gc = ~isnan(coords);
for mc = 1:numel(mapno)
    stats(gc, mc) = bc.Map(mapno(mc)).VMPData(coords(gc));
end
