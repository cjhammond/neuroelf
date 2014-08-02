function hxs = hxsingle(inp)
% hxsingle  - transform a single from/into a readable string
%
% singles cannot be printed in their native "precision". hxsingle
% gives a more memory based representation so as to store the
% exact value of a number
%
% FORMAT:       hxstring = hxsingle(singles)
%         or    singles  = hxsingle(hxstring)
%
% Input fields:
%
%       singles     an array of type single (only real numbers)
%                   a non-linear array will be linearized (:)'
%       hxstring    a 1xN char representation prior created with
%                   this function
%
% Output fields:
%
%       hxstring    the resulting string from a call to hxsingle
%       singles     an 1xN single array, transformed back from a
%                   string representation
%
% See also any2ascii.

% Version:  v0.9a
% Build:    11050515
% Date:     May-17 2010, 10:48 AM EST
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

% persistent lookup values
persistent hxs_hxi hxs_hxr;
if isempty(hxs_hxr)
    tmpTest = sprintfbx(single(2));
    switch tmpTest, case {'00000040'}
        hxs_hxi = [7:-2:1;8:-2:2];
        hxs_hxi = hxs_hxi(:);
    case {'40000000'}
        hxs_hxi = 1:8;
        hxs_hxi = hxs_hxi(:);
    case {'00000004'}
        hxs_hxi = 8:-1:1;
        hxs_hxi = hxs_hxi(:);
    case {'04000000'}
        hxs_hxi = [2:2:8;1:2:7];
        hxs_hxi = hxs_hxi(:);
    otherwise
        error('Platform not supported!');
    end
    hxs_hxr = [ ...
                nan * ones(1, 48) ...
                  0   1   2   3   4   5   6   7   8   9 nan nan nan nan nan nan ...
                nan  10  11  12  13  14  15 nan nan nan nan nan nan nan nan nan ...
                nan * ones(1, 16) ...
                nan  10  11  12  13  14  15 nan nan nan nan nan nan nan nan nan ...
                nan * ones(1,144) ...
              ];
end

% enough arguments ?
if nargin < 1
    error( ...
        'neuroelf:TooFewArguments',...
        'Too few arguments. Try ''help %s''.',...
        mfilename ...
    );
end

inp = inp(:)';
if isa(inp, 'single')
    if isempty(inp)
        hxs = '';
        return;
    end
    inpi = isinf(inp) & inp < 0;
    inpx = isinf(inp) & inp > 0;
    inpn = isnan(inp);
    inp(inpi | inpx | inpn) = 0;
    hxs = sprintfbx(real(inp));
    ns  = numel(hxs) / 8;
    hxi = (hxs_hxi * ones(1, ns)) + (ones(8, 1) * (0:8:(ns-1) * 8));
    hxs = hxs(hxi(:)');
    inpi = find(inpi);
    inpx = find(inpx);
    inpn = find(inpn);
    inpix = (1:8)' * ones(1, numel(inpi)) + 8 * ones(8, 1) * (inpi(:)' - 1);
    inpxx = (1:8)' * ones(1, numel(inpx)) + 8 * ones(8, 1) * (inpx(:)' - 1);
    inpnx = (1:8)' * ones(1, numel(inpn)) + 8 * ones(8, 1) * (inpn(:)' - 1);
    hxs(inpix(:)') = repmat('ff800000', 1, numel(inpi));
    hxs(inpxx(:)') = repmat('7f800000', 1, numel(inpx));
    hxs(inpnx(:)') = repmat('ffc00000', 1, numel(inpn));
elseif ischar(inp)
    inp = inp(:)';
    ns  = floor(length(inp)/8);
    hxs = zeros(1,ns);
    for hxc = 1:ns
        ipp = lower(inp((hxc-1)*8+1:hxc*8));
        if strcmp(ipp, 'ffc00000')
            hxs(hxc) = NaN;
            continue;
        end
        ipi = hxs_hxr(min(double(ipp),255)+1);
        if any(isnan(ipi)) || ...
            all(ipi == 0)
            continue;
        end
        iex = 32*ipi(1)+2*ipi(2)+fix(ipi(3)/8);
        if iex > 255
            isg = -1;
            iex = iex - 256;
        else
            isg = 1;
        end
        imt = 1 + bitand(7,ipi(3))/8 + hex2dec(ipp(4:8))/2.^23;
        hxs(hxc) = isg * imt * 2.^(iex-127);
    end
    hxs = single(hxs);
else
    if isa(inp, 'double')
        error( ...
            'neuroelf:BadArgument',...
            'Bad input class. Use hxdouble(...) instead.' ...
        );
    else
        error( ...
            'neuroelf:BadArgument',...
            'Bad input class.' ...
        );
    end
end
