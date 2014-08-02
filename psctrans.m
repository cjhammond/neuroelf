function [psctc, pscf] = psctrans(tc, dim, tp)
% psctrans  - perform PSC transformation on time course
%
% FORMAT:       [psctc, pscf] = psctrans(tc [, dim [, tp]])
%
% Input fields:
%
%       tc          time course data
%       dim         temporal dimension (default: first non-singleton)
%       tp          time points (indices of dim to use for normalization)
%
% Output fields:
%
%       psctc       PSC transformed time course
%       pscf        PSC transformation factor
%
% See also ztrans

% Version:  v0.9c
% Build:    13060316
% Date:     Dec-18 2012, 5:39 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2012, Jochen Weber
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
   ~isnumeric(tc) || ...
    numel(tc) < 2
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid time course data given.' ...
    );
end
% keep track of size
ts = size(tc);

% convert tc to double if necessary
if ~isa(tc, 'double')
    tc = tc(:);
    tc = double(tc);
end
if nargin < 2 || ...
   ~isa(dim, 'double') || ...
    numel(dim) ~= 1 || ...
    isinf(dim) || ...
    isnan(dim) || ...
    fix(dim) ~= dim || ...
    dim < 1 || ...
    dim > numel(ts) || ...
    ts(round(dim)) < 2
    if ts(1) ~= 1
        dim = 1;
    else
        dim = findfirst(ts ~= 1);
    end
end

% reshape
td = ts(dim);
if dim == 1 || ...
   (dim == 2 && ...
    numel(ts) == 2)
    tc = reshape(tc, ts(1), prod(ts(2:end)));
else
    if dim == numel(ts)
        tc = reshape(tc, prod(ts(1:dim-1)), ts(dim));
    else
        tc = reshape(tc, prod(ts(1:dim-1)), ts(dim), prod(ts(dim+1:end)));
    end
    dim = 2;
end

% prepare subsref argument
if dim == 1
    sref = struct('type', '()', 'subs', {{ones(1, td), ':'}});
elseif ndims(tc) == 2
    sref = struct('type', '()', 'subs', {{':', ones(1, td)}});
else
    sref = struct('type', '()', 'subs', {{':', ones(1, td), ':'}});
end

% for complete dim
if nargin < 3 || ...
   (~islogical(tp) || ...
     numel(tp) == td) && ...
   (~isa(tp, 'double') || ...
     numel(tp) ~= max(size(tp)) || ...
     any(isinf(tp) | isnan(tp) | tp < 1 | tp > td))

    % build PSC factor
    pscf = (100 * td) ./ sum(tc, dim);

% only select tp from dim
else

    % round for not logicals
    if ~islogical(tp)
        tp = round(tp);
        np = numel(tp);
    else
        np = sum(tp);
    end

    % build input subsref argument
    if dim == 1
        dref = struct('type', '()', 'subs', {{tp(:)', ':'}});
    elseif ndims(tc) == 2
        dref = struct('type', '()', 'subs', {{':', tp(:)'}});
    else
        dref = struct('type', '()', 'subs', {{':', tp(:)', ':'}});
    end

    % compute mean and PSC factor over given dim(tp) only
    pscf = (100 * np) ./ sum(subsref(tc, dref), dim);
end

% no illegal factors
pscf(isinf(pscf) | isnan(pscf)) = 0;

% multiplication
if ndims(tc) < 3

    % create sparse factor matrix
    pscff = sparse(1:numel(pscf), 1:numel(pscf), pscf(:)', ...
        numel(pscf), numel(pscf), numel(pscf));

    % first dim
    if dim == 1

        psctc = tc * pscff;

    % second dim
    else
        psctc = pscff * tc;
    end

    % work around Matlab "bug" for sparse 1x1 factors leading to sparse
    if issparse(psctc)
        psctc = full(psctc);
    end

% more complicated
else
    % build PSC (psctc = 100 * tc / mean(tc))
    psctc = tc .* subsref(pscf, sref);
end

% reshape
psctc = reshape(psctc, ts);
