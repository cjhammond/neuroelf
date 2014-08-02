function hfile = vmr_InhomogeneityCorrect(hfile, opts)
% VMR::InhomogeneityCorrect  - attempt automatic inhomogeneity correction
%
% FORMAT:       [vmr = ] vmr.InhomogeneityCorrect([opts])
%
% Input fields:
%
%       opts        optional struct with settings
%        .mask      either 3D uint8/logical data or VMR object with preseg
%                   if omitted, try automatic mask detection
%        .model     either of 'log', {'mult'}
%        .numpasses number of passes, default 3 (valid: 1 through 5)
%        .order     polynomial order, default 3 (valid: 2 through 7)
%        .xmask     use mask in conjunction with autodetected mask
%
% Note: this function uses pmbfilter.

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2011, 2012, 2014, Jochen Weber
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
if nargin < 2 || ...
    numel(opts) ~= 1 || ...
   ~isstruct(opts)
    opts = struct;
end
if ~isfield(opts, 'mask') || ...
    isempty(opts.mask)
    opts.mask = [];
end
if numel(opts.mask) == 1 && ...
    xffisobject(opts.mask, true, 'vmr')
    mbc = xffgetcont(opts.mask.L);
    opts.mask = mbc.VMRData;
    if ~isequal(size(opts.mask), size(bc.VMRData))
        opts.mask = [];
    end
    if ~isa(opts.mask, 'uint8')
        opts.mask = uint8([]);
    end
    if ~isempty(opts.mask)
        opts.mask(opts.mask < 226) = 0;
        opts.mask(opts.mask > 225) = opts.mask(opts.mask > 225) - 225;
        um = unique(opts.mask(:) + 1);
        ur = uint8(1:max(um));
        ur(uo) = 1:numel(um);
        opts.mask = ur(opts.mask);
    end
end
if ~isfield(opts, 'model') || ...
   ~ischar(opts.model) || ...
   ~any(strcmpi(opts.model(:)', {'l', 'log', 'm', 'mult'}))
    opts.model = 'mult';
else
    opts.model = lower(opts.model(1));
    if opts.model == 'l'
        opts.model = 'log';
    else
        opts.model = 'mult';
    end
end
if ~isfield(opts, 'numpasses') || ...
    numel(opts.numpasses) ~= 1 || ...
   ~isa(opts.numpasses, 'double') || ...
    isnan(opts.numpasses) || ...
   ~any((1:5) == opts.numpasses)
    opts.numpasses = 3;
end
if ~isfield(opts, 'order') || ...
    numel(opts.order) ~= 1 || ...
   ~isa(opts.order, 'double') || ...
    isnan(opts.order) || ...
   ~any((2:7) == opts.order)
    opts.order = 3;
end
if ~isfield(opts, 'xmask') || ...
    numel(opts.xmask) ~= 1 || ...
   ~islogical(opts.xmask)
    opts.xmask = false;
end

% either 8- or 16-bit data
if ~isempty(bc.VMRData16) && ...
    isequal(size(bc.VMRData16), size(bc.VMRData))
    v16 = true;
    vd = bc.VMRData16;
else
    v16 = false;
    vd = bc.VMRData;
end
if istransio(vd)
    vd = resolve(vd);
end

% apply correction (pre-filter)
for pc = 1:(opts.numpasses-1)
    vd = pmbfilter(vd, opts.order, opts.mask, struct('xmask', opts.xmask));
end

% apply final pass
vd = pmbfilter(vd, opts.order, opts.mask, struct( ...
    'bcutoff', 0.1, ...
    'cmask',   true, ...
    'robust',  true, ...
    'xmask',   opts.xmask));
vd(vd < 0) = 0;

% 16-bit output
if v16
    vd(vd > 32767) = 32767;
    vd = uint16(round(vd));
    bc.VMRData16 = vd;

% 8-bit output
else

    % potentially needs adaptation
    om = mean(bc.VMRData(vd > 0));
    nm = mean(vd(vd > 0));
    vd = (om / nm) .* vd;

    % limit to 225 values!
    vd(vd > 225) = 225;
    vd = uint8(round(vd));
    bc.VMRData = vd;
end

% set in output
xffsetcont(hfile.L, bc);

% also re-calc 8-bit data?
if v16
    vmr_LimitVMR(hfile, struct('recalc8b', true));
end
