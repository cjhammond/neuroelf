function idata = smp_ApplyTSM(hfile, tsm, srf, mapsel)
% SMP::ApplyTSM  - apply TSM interpolation to map
%
% FORMAT:       idata = smp.ApplyTSM(tsm, srf [, mapsel]);
%
% Input fields:
%
%       tsm         TSM object with target<-source triangles/edge vectors
%       srf         SRF object source triangle information
%       mapsel      map selection (default: all)
%
% Output fields:
%
%       idata       interpolated map values

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
   ~xffisobject(hfile, true, 'smp') || ...
    numel(tsm) ~= 1 || ...
   ~xffisobject(tsm, true, 'tsm') || ...
    numel(srf) ~= 1 || ...
   ~xffisobject(srf, true, 'srf')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
tbc = xffgetcont(tsm.L);
sbc = xffgetcont(srf.L);
if bc.NrOfVertices ~= sbc.NrOfVertices || ...
    bc.NrOfVertices ~= tbc.NrOfSourceVertices
    error( ...
        'xff:BadArgument', ...
        'SMP, TSM, and SRF objects must match in NrOfVertices property.' ...
    );
end
if isempty(bc.Map)
    warning( ...
        'xff:BadArgument', ...
        'SMP does not contain any maps.' ...
    );
    idata = zeros(tbc.NrOfTargetVertices, 0);
    return;
end
if nargin < 4 || ...
   ~isa(mapsel, 'double') || ...
    isempty(mapsel) || ...
    any(isinf(mapsel(:)) | isnan(mapsel(:)))
    mapsel = 1:numel(bc.Map);
else
    mapsel = unique(min(max(round(mapsel(:)'), 1), numel(bc.Map)));
    if isempty(mapsel)
        warning( ...
            'xff:BadArgument', ...
            'Invalid map selection provided.' ...
        );
        idata = zeros(tbc.NrOfTargetVertices, 0);
        return;
    end
end

% prepare output
nmapsel = numel(mapsel);
idata = zeros(tbc.NrOfTargetVertices, nmapsel);

% get map values and neighbors
map = zeros(bc.NrOfVertices, nmapsel);
for mc = 1:nmapsel
    map(:, mc) = bc.Map(mapsel(mc)).SMPData(:);
end

% get source vertices and weighting
srv = sbc.TriangleVertex(tbc.SourceTriangleOfTarget, :);
srw23 = tbc.TriangleEdgeLengths;
srw1 = 1 - sum(srw23, 2);

% iterate
for mc = 1:nmapsel

    % compute
    idata(:, mc) = ...
        srw1 .* map(srv(:, 1), mc) + ...
        srw23(:, 1) .* map(srv(:, 2), mc) + ...
        srw23(:, 2) .* map(srv(:, 3), mc);

end
