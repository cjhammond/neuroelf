function hxf = hxdouble(inp)
% hxdouble  - transform a double from/into a readable string
%
% doubles cannot be printed in their native "precision". hxdouble
% gives a more memory based representation so as to store the
% exact value of a number
%
% FORMAT:       hxstring = hxdouble(doubles)
%         or    doubles  = hxdouble(hxstring)
%
% Input fields:
%
%       doubles     an array of type double (only real numbers)
%                   a non-linear array will be linearized (:)'
%       hxstring    a 1xN char representation prior created with
%                   this function
%
% Output fields:
%
%       hxstring    the resulting string from a call to hxdouble
%       doubles     an 1xN double array, transformed back from a
%                   string representation
%
% See also any2ascii.

% Version:  v0.9c
% Build:    11050515
% Date:     May-05 2011, 3:31 PM EST
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

% persistent lookup values
persistent hxd_hxi hxd_hxr;
if isempty(hxd_hxi)
    tmpTest = sprintfbx(2);
    switch tmpTest, case {'0000000000000040'}
        hxd_hxi = [15:-2:1;16:-2:2];
        hxd_hxi = hxd_hxi(:);
    case {'4000000000000000'}
        hxd_hxi = 1:16;
        hxd_hxi = hxd_hxi(:);
    case {'0000000000000004'}
        hxd_hxi = 16:-1:1;
        hxd_hxi = hxd_hxi(:);
    case {'0400000000000000'}
        hxd_hxi = [2:2:16;1:2:15];
        hxd_hxi = hxd_hxi(:);
    otherwise
        error('Platform not supported!');
    end
    hxd_hxr = [ ...
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
if isa(inp, 'double')
    inpi = isinf(inp) & inp < 0;
    inpx = isinf(inp) & inp > 0;
    inpn = isnan(inp);
    inp(inpi | inpx | inpn) = 0;
    hxf = sprintfbx(real(inp));
    ns  = numel(hxf) / 16;
    hxi = (hxd_hxi * ones(1, ns)) + (ones(16, 1) * (0:16:(ns-1) * 16));
    hxf = hxf(hxi(:)');
    inpi = find(inpi);
    inpx = find(inpx);
    inpn = find(inpn);
    inpix = (1:16)' * ones(1, numel(inpi)) + 16 * ones(16, 1) * (inpi(:)' - 1);
    inpxx = (1:16)' * ones(1, numel(inpx)) + 16 * ones(16, 1) * (inpx(:)' - 1);
    inpnx = (1:16)' * ones(1, numel(inpn)) + 16 * ones(16, 1) * (inpn(:)' - 1);
    hxf(inpix(:)') = repmat('fff0000000000000', 1, numel(inpi));
    hxf(inpxx(:)') = repmat('7ff0000000000000', 1, numel(inpx));
    hxf(inpnx(:)') = repmat('fff8000000000000', 1, numel(inpn));
elseif ischar(inp)
    ns  = floor(numel(inp) / 16);
    hxf = nan * ones(1, ns);
    for hxc = 1:ns
        ipp = lower(inp((hxc-1)*16+1:hxc*16));
        if strcmp(ipp, 'fff8000000000000')
            continue;
        end
        ipd = min(double(ipp), 255) + 1;
        ipi = hxd_hxr(ipd);
        if any(isnan(ipi))
            continue;
        elseif all(ipi == 0)
            hxf(hxc) = 0;
            continue;
        end
        iex = 256*ipi(1)+16*ipi(2)+ipi(3);
        if iex > 2047
            isg = -1;
            iex = iex - 2048;
        else
            isg = 1;
        end
        imt = 0;
        for mtc = 4:16
            imt = imt*16+ipi(mtc);
        end
        if iex > 64
            hxf(hxc) = 2.^(iex-1023) + (2.^(iex-1075)).*imt;
        elseif iex > 0
            hxf(hxc) = 2.^(iex-1023) + (imt ./ (2.^63)) ./ (2.^1011);
        else
            hxf(hxc) = (imt ./ (2.^63)) ./ (2.^1011);
        end
        hxf(hxc) = hxf(hxc) * isg;
    end
else
    error( ...
        'neuroelf:BadArgument',...
        'Bad input class.' ...
    );
end
