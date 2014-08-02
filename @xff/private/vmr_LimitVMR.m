function hfile = vmr_LimitVMR(hfile, opts)
% VMR::LimitVMR  - apply intensity limits to V16 of VMR
%
% FORMAT:       [vmr = ] vmr.LimitVMR([opts])
%
% Input fields:
%
%       opts        1x1 struct with optional settings
%        .range     either 1x2 intensity range (limits included) or
%                   1x2 relative limiting (default: [0.001, 0.999])
%        .recalc8b  flag whether or not to recalc 8-bit portion {false}
%
% Output fields:
%
%       vmr         altered object
%
% Note: the VMRData16 field must be set correctly

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2011, 2014, Jochen Weber
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
   ~xffisobject(hfile, true, 'vmr')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
if isempty(bc.VMRData16) || ...
    numel(size(bc.VMRData16)) ~= numel(size(bc.VMRData)) || ...
    any(size(bc.VMRData16) ~= size(bc.VMRData))
    error( ...
        'xff:InvalidObject', ...
        'VMR16 data not found.' ...
    );
end
numvox = numel(bc.VMRData);
if nargin < 2 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'range') || ...
   ~isa(opts.range, 'double') || ...
    numel(opts.range) ~= 2 || ...
    any(isinf(opts.range) | isnan(opts.range) | opts.range < 0) || ...
    any(opts.range ~= fix(opts.range) & opts.range > 1)
    opts.range = [0.001, 0.999];
end
if ~isfield(opts, 'recalc8b') || ...
   ~islogical(opts.recalc8b) || ...
    numel(opts.recalc8b) ~= 1
    opts.recalc8b = false;
end

% resolve if transio
if istransio(bc.VMRData16)
    bc.VMRData16 = resolve(bc.VMRData16);
end

% get maximum value
mmm = minmaxmean(bc.VMRData16);
mx = mmm(2);

% is range a relative setting (within histogram counts)?
if any(opts.range ~= fix(opts.range))

    % get histogram count (up to max)
    hn = histcount(bc.VMRData16, 1, mx, 1);
    cn = cumsum(hn);
    numvox = cn(end);
    if opts.range(1) ~= fix(opts.range(1))
        miny = findfirst(cn > (numvox * opts.range(1)));
        if isempty(miny)
            opts.range(1) = mx - 1;
        else
            opts.range(1) = miny - 1;
        end
    end
    if opts.range(2) ~= fix(opts.range(2))
        maxy = findfirst(cn < (numvox * opts.range(2)), -1);
        if isempty(maxy)
            opts.range(2) = mx;
        else
            opts.range(2) = maxy;
        end
    end
end

% limit VMR (hard-limiting V16 data)
if ~opts.recalc8b
    if opts.range(1) > 0
        minmask = (bc.VMRData16 < opts.range(1));
        bc.VMRData16(minmask) = opts.range(1);
        bc.VMRData16 = bc.VMRData16 - opts.range(1);
    end
    if opts.range(2) < mx
        maxmask = (bc.VMRData16 > opts.range(2));
        bc.VMRData16(maxmask) = opts.range(2) - opts.range(1);
    end

    % and update Min/Mean/Max values
    mmm = minmaxmean(bc.VMRData16);
    bc.MinOriginalValue = mmm(1);
    bc.MeanOriginalValue = round(mmm(3));
    bc.MaxOriginalValue = mmm(2);

% actually re-compute 8-bit data
else

    % compute new values
    vdt = single(225.999 / (opts.range(2) - opts.range(1))) .* ...
        (single(bc.VMRData16) - single(opts.range(1)));
    bc.VMRData = uint8(floor(limitrangec(vdt, 0, 225, 0)));
end

% set to content array
xffsetcont(hfile.L, bc);
