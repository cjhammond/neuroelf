function [x, w] = custom_pwelch(x, opts)
% custom_pwelch  - compute Welch's periodogram power spectrum
%
% FORMAT:       p = custom_pwelch(X [, opts])
%
% Input fields:
%
%       X           signal
%       opts        optional settings
%        .detrend   either of 'linear', {'mean'}, or none
%        .nfft      number of FFT frequencies, default min(256, numel(x))
%        .overlap   overlap (if [0 .. 1] percentage, otherwise length)
%        .twosided  compute two-sided FFT (default: false)
%        .units     units ({'squared'} or 'dB')
%        .window    window length in samples, default: floor(numel(x)/4.5)
%
% Output fields:
%
%       p           averaged periodogram
%       w           frequencies (in radiens)

% Version:  v0.9c
% Build:    11112314
% Date:     Nov-20 2011, 11:24 PM EST
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

% argument check
if nargin < 1 || ...
   ~isnumeric(x) || ...
    isempty(x) || ...
    any(isinf(x(:)) | isnan(x(:))) || ...
    numel(x) < 4
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid or missing argument.' ...
    );
end
xsz = size(x);
x = squeeze(double(x));
xnsz = size(x);
xnp = xnsz(1);
x = reshape(x, xnp, prod(xnsz(2:end)));
if nargin < 2 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'detrend') || ...
   ~ischar(opts.detrend) || ...
   ~any(strcmpi(opts.detrend(:)', {'l', 'linear', 'm', 'mean', 'n', 'none'}))
    opts.detrend = 'm';
else
    opts.detrend = lower(opts.detrend(1));
end
switch (opts.detrend)
    case {'l'}
        trend = 1;
    case {'m'}
        trend = 0;
    case {'n'}
        trend = -1;
end
if ~isfield(opts, 'nfft') || ...
   ~isa(opts.nfft, 'double') || ...
    numel(opts.nfft) ~= 1 || ...
    isinf(opts.nfft) || ...
    isnan(opts.nfft) || ...
    opts.nfft < 2 || ...
    opts.nfft ~= fix(opts.nfft)
    nfft = min(256, xnp);
else
    nfft = opts.nfft;
end
if ~isfield(opts, 'overlap') || ...
   ~isa(opts.overlap, 'double') || ...
    numel(opts.overlap) ~= 1 || ...
    isinf(opts.overlap) || ...
    isnan(opts.overlap) || ...
    opts.overlap < 0 || ...
    opts.overlap >= xnp
    opts.overlap = [];
end
if ~isfield(opts, 'twosided') || ...
   ~islogical(opts.twosided) || ...
    numel(opts.twosided) ~= 1
    opts.twosided = false;
end
if ~isfield(opts, 'units') || ...
   ~ischar(opts.units) || ...
   ~any(strcmpi(opts.units(:)', {'d', 'db', 's', 'sq', 'squared'}))
    opts.units = 's';
else
    opts.units = lower(opts.units(1));
end
if opts.units == 'd'
    usedB = true;
else
    usedB = false;
end
if ~isfield(opts, 'window') || ...
   ~isa(opts.window, 'double') || ...
    isempty(opts.window)
    opts.window = floor(xnp / 4.5);
end
if numel(opts.window) == 1
    if isinf(opts.window) || ...
        isnan(opts.window) || ...
        opts.window <= 0 || ...
       (opts.window >= 1 && ...
        opts.window ~= fix(opts.window))
        opts.window = nfft;
    end
    if opts.window <= 1
        opts.window = round(opts.window .* nfft);
    end
    opts.window = min(xnp, opts.window);
    w2 = opts.window / 2;
    if w2 == fix(w2)
        window = .5 * (1 - cos(2 * pi * (1:w2)' / (opts.window + 1)));
        window = [window; window(end:-1:1)];
    else
        window = .5 * (1 - cos(2 * pi * (0.5:(w2+0.5))' / (opts.window + 1)));
        window = [window; window(end-1:-1:1)];
    end
else
    window = opts.window(:);
end
if isempty(opts.overlap)
    overlap = round(numel(window) / 2);
elseif opts.overlap < 1
    overlap = min(round(numel(window) * opts.overlap), xnp - 1);
else
    overlap = opts.overlap;
end

% compute number of window onsets
winsize = numel(window);
mxpos = xnp - winsize + 1;
if (winsize > nfft)
    nfft = winsize;
end
no = max(1, round(mxpos / max(1, (winsize - overlap))));

% compute step size for desired overlay
step = max(1, (xnp - winsize) / no);
o = round(0:step:mxpos-0.5);
no = numel(o);

% get start positions
pos = (1:winsize)' * ones(1, no) + round(ones(winsize, 1) * o);
if pos(end) > xnp
    pos(:, end) = pos(:, end) - (pos(end) - xnp);
end
if size(pos, 2) > 1
    x = indexarray(x, reshape(pos, [winsize, 1, size(pos, 2)]), 1:size(x, 2));
else
    x = x(pos, :);
end
asz = size(x);
x = reshape(x, asz(1), prod(asz(2:end)));

% detrend appropriately
if trend > 0
    xt = ztrans((1:winsize)');
    xt(:, 2) = 1;
    ixx = [1 / (winsize - 1), 0; 0, 1 / winsize];
    b = ixx * xt' * x;
    x = x - xt * b;
elseif trend == 0
    x = x - ones(winsize, 1) * ((1 / winsize) * sum(x, 1));
end

% multiply with window
x = x .* window(:, ones(1, size(x, 2)));

% fft
x = fft(x, nfft, 1);
x = abs(x);

% reshape back
x = reshape(x, [size(x, 1), asz(2:end)]);

% averaging
if no > 1
    x = (1 / no) .* sum(x .^ 2, 3);
end

% normalization
x = (1 / norm(window) .^ 2) .* x;

% in dB?
if usedB
    x = 10 .* log10(x);
end

% extract the positive frequency components
if ~opts.twosided
    x = x(1:ceil((nfft + 1) / 2), :);
end

% reshape output
xsz(findfirst(xsz > 1)) = size(x, 1);
x = reshape(x, xsz);

% compute frequencies
if nargout > 1
    w = ((2 * pi) / nfft) .* (0:(size(x, 1) - 1))';
    w(end) = pi;
end
