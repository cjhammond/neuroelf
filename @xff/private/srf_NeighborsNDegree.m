function [neis, neimtx] = srf_NeighborsNDegree(hfile, nd, opts)
% SRF::NeighborsNDegree  - retrieve neighbors up to a degree
%
% FORMAT:       [nei, neimtx] = srf.NeighborsNDegree(nd [, opts])
%
% Input fields:
%
%       nd          1x1 degree to which neighbors are retrieved
%       opts        optional settings
%        .maxdist   maximum distance (in mm, default: Inf)
%        .notself   do not include vertex index itself (default: false)
%
% Output fields:
%
%       nei         cell array with list of neighbors
%       neimtx      matrix version (for faster access)
%
% Note: this function requires GUI being available (figure/uicontrol).

% Version:  v0.9d
% Build:    14061113
% Date:     Jun-11 2014, 1:56 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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

% argument check
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'srf')
    error( ...
        'xff:BadArgument', ...
        'Invalid object for SRF::NeighborsNDegree' ...
    );
end
bc = xffgetcont(hfile.L);
if nargin < 2 || ...
   ~isa(nd, 'double') || ...
    numel(nd) ~= 1 || ...
    isinf(nd) || ...
    isnan(nd) || ...
    nd < 1
    nd = 1;
else
    nd = min(round(nd), 20);
end
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'maxdist') || ...
   ~isa(opts.maxdist, 'double') || ...
    numel(opts.maxdist) ~= 1 || ...
    isnan(opts.maxdist) || ...
    opts.maxdist <= 0
    opts.maxdist = Inf;
end
if ~isfield(opts, 'notself') || ...
   ~islogical(opts.notself) || ...
    numel(opts.notself) ~= 1
    opts.notself = false;
end

oneis = bc.Neighbors;
neis = oneis;
nnei = size(neis, 1);

% iterate
ond = nd;
if nd > 1
    while nd > 1
        for nc = 1:nnei
            neis{nc, 2} = cat(2, oneis{neis{nc, 2}, 2});
        end
        nd = nd - 1;
    end
elseif ~opts.notself
    for nc = 1:nnei
        neis(nc, :) = {neis{nc, 1} + 1, [nc, neis{nc, 2}]};
    end
end

% unique
if ond > 1
    if opts.notself
        for nc = 1:nnei
            neis{nc, 2} = unique(neis{nc, 2});
            neis{nc, 2}(neis{nc, 2} == nc) = [];
            neis{nc, 1} = numel(neis{nc, 2});
        end
    else
        for nc = 1:nnei
            neis{nc, 2} = unique([nc, neis{nc, 2}]);
            neis{nc, 1} = numel(neis{nc, 2});
        end
    end
end

% neighbor-to-neighbor matrix
if nargout > 1

    % total number of neighbors
    tnei = sum(cat(1, neis{:, 1}));
    sj = cat(2, neis{:, 2});
    si = zeros(tnei, 1);
    ss = ones(tnei, 1);
    ti = 1;
    for nc = 1:nnei
        si(ti:ti+neis{nc, 1}-1) = nc;
        ti = ti + neis{nc, 1};
    end
    neimtx = sparse(si, sj, ss, nnei, nnei, tnei);
end
