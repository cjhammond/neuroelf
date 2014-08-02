function md = madistd(data, ss)
% madist  - Mahalanobis distance of single data argument
%
% FORMAT:       md = madistd(data [, ss])
%
% Input fields:
%
%       data        RxC data
%       ss          number of sub-samples, and sub-samplings
%                   (default: ceil([0.5 * R, 100 * sqrt(C / R)]))
%
% Output fields:
%
%       md          Mahalonibis distance (of each row to sample mean/var)

% Version:  v0.9d
% Build:    14052009
% Date:     May-20 2014, 9:43 AM EST
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

% argument check
if nargin ~= 1 || ...
   ~isnumeric(data) || ...
    ndims(data) > 2 || ...
    any(isinf(data(:)) | isnan(data(:))) || ...
   ~isreal(data)
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid argument supplied.' ...
    );
end

% make sure data is double
data = double(data);

% get number of rows
sd = size(data, 1);

% compute mean
m = (1 / sd) .* sum(data, 1);

% remove mean from data
data = data - m(ones(sd, 1), :);

% simple case
if  size(data, 2) < sd

    % Q/R-de-compose data (matrix)
    [Q, R] = qr(data,0);

    % compute Mahalanobis distance
    ri = R' \ data';
    md = sum(ri .* ri, 1)' * (sd - 1);

% sub-sampling
else

    % subsampling not given
    sc = size(data, 2);
    if nargin < 2 || ...
       ~isa(ss, 'double') || ...
        numel(ss) ~= 2 || ...
        any(isinf(ss) | isnan(ss) | ss < 3 | ss ~= round(ss)) || ...
        ss(1) >= sd || ...
        ss(2) > sc
        ss = ceil([0.5 * sd, 100 * sqrt(sc / sd)]);
    end

    % create md array
    md = zeros(sd, ss(2));
    sd1 = sd - 1;

    % iterate
    for c = 1:ss(2)

        % sample
        si = randperm(sc);
        sdata = data(:, si(1:ss(1)));

        % compute
        [Q, R] = qr(sdata, 0);
        ri = R' \ sdata';
        md(:, c) = sd1 .* sum(ri .* ri, 1)';
    end

    % median
    md = median(md, 2);
end
