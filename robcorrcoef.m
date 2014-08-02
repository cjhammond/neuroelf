function [r, p] = robcorrcoef(x, y, dim)
% robcorrcoef  - robust correlation coefficient using bisquare weighting
%
% FORMAT:       [r, p] = robcorrcoef(x [, y [, dim]])
%
% Input fields:
%
%       x           either Nx1 or NxM matrix
%       y           if given, must match x in size (needed when x is Nx1)
%       dim         dim to compute correlation across (default: last)
%
% Output fields:
%
%       r           correlation coefficient
%       p           probabilities (one-tailed)

% Version:  v0.9b
% Build:    11050712
% Date:     Apr-08 2011, 9:16 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2011, Jochen Weber
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
   ~isa(x, 'double') || ...
    isempty(x) || ...
    any(isinf(x(:)) | isnan(x(:)))
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid or missing argument.' ...
    );
end
xs = size(x);
if nargin < 2
    if numel(xs) > 2 || ...
        any(xs == 1)
        error( ...
            'neuroelf:BadArgument', ...
            'Can''t compute correlation for Nx1 vector or ND array alone.' ...
        );
    end
    xo = true;
    ncorrs = xs(2);
    r = ones(ncorrs, ncorrs);
    ncorrs = ncorrs * (ncorrs - 1);
    if nargout > 1
        p = r;
    end
    nvals = xs(1);
else
    if ~isa(y, 'double')
        error( ...
            'neuroelf:BadArgument', ...
            'Second argument must be of type double.' ...
        );
    end
    if nargin < 3 || ...
       ~isa(dim, 'double') || ...
        numel(dim) ~= 1 || ...
        isinf(dim) || ...
        isnan(dim) || ...
       ~any(dim == 1:numel(xs))
        dim = numel(xs);
        if xs(dim) == 1
            dim = dim - 1;
        end
    end
    if numel(y) == xs(dim) && ...
        numel(y) ~= numel(x)
        ys = osz(xs);
        ys(dim) = xs(dim);
        y = reshape(y, ys);
        ys = xs;
        ys(dim) = 1;
        y = repmat(y, ys);
    end
    ys = size(y);
    if ~isa(y, 'double') || ...
       ~isequal(xs, ys) || ...
        any(isinf(y(:)) | isnan(y(:)))
        error( ...
            'neuroelf:BadArgument', ...
            'Bad or mismatching second argument.' ...
        );
    end
    xo = false;
    ncorrs = prod(xs) / xs(dim);
    nvals = ys(dim);
    ys(dim) = 1;
end

% progress bar?
if ncorrs > 100
    try
        pbar = xprogress;
        xprogress(pbar, 'setposition', [80, 200, 640, 36]);
        xprogress(pbar, 'settitle', sprintf( ...
            'Fitting %d vectors with %d samples...', ncorrs, nvals));
        xprogress(pbar, 0, 'Performing robust fit...', 'visible', 0, ncorrs);
        vcs = ncorrs / 100;
        vcn = vcs;
        vcc = 0;
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        pbar = [];
        vcn = Inf;
    end
else
    pbar = [];
    vcn = Inf;
    vcc = 0;
end

% prepare design matrix
X = ones(nvals, 2);

% one array?
if xo

    % ztrans x
    x = ztrans(x);

    % loop over second dim *twice*
    for d1 = 1:xs(2)
        for d2 = 1:xs(2)

            % don't compute for equal d1, d2
            if d1 == d2
                continue;
            end

            % get y and put into X
            y = x(:, d2)';
            X(:, 1) = x(:, d1);

            % perform robust fit
            [b, w] = fitrobustbisquare_img(X, y);

            % compute t-stat
            t = robustt(X, y, b, w, [1, 0]);

            % convert to r (and p)
            r(d1, d2) = correlinvtstat(t, nvals);
            if nargout > 1
                p(d1, d2) = sdist('tcdf', -abs(t), nvals - 2);
            end

            % progress bar
            if ~isinf(vcn)
                vcc = vcc + 1;
                if vcc >= vcn
                    xprogress(pbar, vcc);
                    vcn = vcn + vcs;
                end
            end
        end
    end

% two arrays
else

    % ztrans x and y
    x = ztrans(x, dim);
    y = ztrans(y, dim);

    % reshape accordingly
    ns = [prod(xs(1:dim-1)), nvals, prod(xs(dim+1:end))];
    x = reshape(x, ns);
    y = reshape(y, ns);
    r = zeros(ns(1), ns(3));
    if nargout > 1
        p = ones(ns(1), ns(3));
    end

    % loop over size before and after dim
    for d1 = 1:ns(1)
        for d2 = 1:ns(3)

            % get y and put into X
            yv = y(d1, :, d2);
            if any(isnan(yv))
                vcc = vcc + 1;
                continue;
            end
            X(:, 1) = x(d1, :, d2)';
            if any(isnan(X(:, 1)))
                vcc = vcc + 1;
                continue;
            end

            % perform robust fit
            [b, w] = fitrobustbisquare_img(X, yv);

            % compute t-stat
            t = robustt(X, yv, b, w, [1, 0]);

            % convert to r (and p)
            r(d1, d2) = correlinvtstat(t, nvals);
            if nargout > 1
                p(d1, d2) = sdist('tcdf', -abs(t), nvals - 2);
            end

            % progress bar
            if ~isinf(vcn)
                vcc = vcc + 1;
                if vcc >= vcn
                    xprogress(pbar, vcc);
                    vcn = vcn + vcs;
                end
            end
        end
    end

    % reshape output(s)
    r = reshape(r, ys);
    if nargout > 1
        p = reshape(p, ys);
    end
end

% clear progress bar
if ~isempty(pbar)
    closebar(pbar);
end
