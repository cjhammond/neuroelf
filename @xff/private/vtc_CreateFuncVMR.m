function vmr = vtc_CreateFuncVMR(hfile, vol, iptype)
% VTC::CreateFuncVMR  - create a (pseudo) VMR
%
% FORMAT:       vmr = vtc.CreateFuncVMR([vol, iptype])
%
% Input fields:
%
%       vol         volume number (default 1)
%       iptype      interpolation 'cubic', 'linear', {'nearest'}
%
% Output fields:
%
%       vmr         VMR object (in 256x256x256 frame)

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vtc')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get VTC object for some more checks
bc = xffgetcont(hfile.L);
szvtc = size(bc.VTCData);

if nargin < 2 || ...
   ~isa(vol, 'double') || ...
    numel(vol) ~= 1 || ...
    isnan(vol) || ...
    vol < 0 || ...
    vol > szvtc(1) || ...
    vol ~= fix(vol)
    vol = 1;
end
if nargin < 3 || ...
   ~ischar(iptype) || ...
   ~any(strcmpi(iptype(:)', {'cubic', 'linear', 'nearest'}))
    iptype = 'nearest';
else
    iptype = lower(iptype(:)');
end

% create VMR
vmr = xff('new:vmr');
vmrc = xffgetcont(vmr.L);

% get data
vd = bc.VTCData(:, :, :, :);
if vol > 0
    vd = squeeze(vd(vol, :, :, :));
else
    vd = squeeze(mean(vd));
end
vr = bc.Resolution;
iv = 1 / vr;
is = 1 - iv;
ixyz = [Inf, Inf, Inf; is, is, is; iv, iv, iv; szvtc(2:4) + eps + iv];

% what interpolation
vd = flexinterpn_method(vd, ixyz, 0, iptype);
vds = size(vd) - 1;

% put into V16 data at offset
vmrc.VMRData16 = uint16(vmrc.VMRData);
vmrc.VMRData16( ...
    bc.XStart:(bc.XStart + vds(1)), ...
    bc.YStart:(bc.YStart + vds(2)), ...
    bc.ZStart:(bc.ZStart + vds(3))) = uint16(vd);

% put back into array
xffsetcont(vmr.L, vmrc);

% thresholding
vmr_LimitVMR(vmr, struct('recalc8b', true));
