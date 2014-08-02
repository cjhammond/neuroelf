function m = mtimesnd(f1, f2, flag)
% mtimesnd  - higher-dimensional mtimes
%
% FORMAT:       m = mtimesnd(f1, f2 [,flag])
%
% Input fields:
%
%       f1, f2      factors with size AxMx... and MxBx... where additional
%                   dimensions must match
%       flag        determines whether or not to permute first two dims:
%                   - 0: do not permute either f1 or f2 (default)
%                   - 1: permute dims 1 and 2 in f1 but not in f2
%                   - 2: permute dims 1 and 2 in f2 but not in f1
%                   - 3: permute dims 1 and 2 in both f1 and f2
%
% Output fields:
%
%       m           multiplied version, size AxBx...
%
% Note: this is the M-file implementation of transmul.c!

% Version:  v0.9b
% Build:    12121112
% Date:     Aug-26 2010, 1:53 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, Jochen Weber
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
   (~isa(f1, 'double') && ...
    ~isa(f1, 'single')) || ...
   (~isa(f2, 'double') && ...
    ~isa(f2, 'single'))
    error( ...
        'neuroelf:BadArgument', ...
        'Bad or missing argument.' ...
    );
end
s1 = size(f1);
s2 = size(f2);

% check dims
if numel(s1) ~= numel(s2) || ...
    any(s1(3:end) ~= s2(3:end))
    error( ...
        'neuroelf:BadArgument', ...
        'Arguments must match in size.' ...
    );
end

% permute ?
if nargin > 2 && ...
    isnumeric(flag) && ...
    numel(flag) == 1 && ...
   ~isinf(flag) && ...
   ~isnan(flag) && ...
    flag >= 0 && ...
    flag <= 3
    flag = floor(real(double(flag)));
else
    flag = 0;
end

% flag?
switch (flag)
    case {1}
        f1 = permute(f1, [2, 1, 3:numel(s1)]);
        s1 = size(f1);
    case {2}
        f2 = permute(f2, [2, 1, 3:numel(s2)]);
        s2 = size(f2);
    case {3}
        f1 = permute(f1, [2, 1, 3:numel(s1)]);
        s1 = size(f1);
        f2 = permute(f2, [2, 1, 3:numel(s2)]);
        s2 = size(f2);
end

% check inner dim
if size(f1, 2) ~= size(f2, 1)
    error( ...
        'neuroelf:BadArgument', ...
        'Inner 2D matrix dimensions mismatch.' ...
    );
end

% determine output size
os = [s1(1), s2(2), s1(3:end)];
osx = prod(os(3:end));
ost = [1, 1, osx];

% determine output class
if isa(f1, 'single') && ...
    isa(f2, 'single')
    m = single(0);
    m(prod(os)) = 0;
    m = reshape(m, os);
else
    m = zeros(os);
end

% reshape if necessary
if numel(s1) > 3
    f1 = reshape(f1, [s1(1:2), osx]);
    f2 = reshape(f2, [s2(1:2), osx]);
    m  = reshape(m,  [os(1:2), osx]);
end

% iterate as necessary
if (s1(1) * s2(2)) < osx
    for c1 = 1:s1(1)
        for c2 = 1:s2(2)

            % perform multiplication and sum
            m(c1, c2, :) = m(c1, c2, :) + reshape(sum( ...
                reshape(f1(c1, :, :), s1(2), osx) .* ...
                reshape(f2(:, c2, :), s1(2), osx), 1), ost);
        end
    end
else
    for c1 = 1:osx
        m(:, :, c1) = f1(:, :, c1) * f2(:, :, c1);
    end
end
if numel(os) > 3
    m = reshape(m, os);
end
