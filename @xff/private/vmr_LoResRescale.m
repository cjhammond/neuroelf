function hfile2 = vmr_LoResRescale(hfile, cutoff)
% VMR::LoResRescale  - bring 0.5mm hires back to VMR space
%
% FORMAT:       lores = vmr.LoResRescale([cutoff])
%
% Input fields:
%
%       cutoff      optional flag, minimize VMR box (default false)
%
% Output fields:
%
%       lores       1x1x1 mm VMR

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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
if ~isfield(bc, 'VoxResX') || ...
    any([bc.VoxResX, bc.VoxResY, bc.VoxResZ] ~= 0.5)
    error( ...
        'xff:InvalidObject', ...
        'Method only valid for 0.5mm ISOvoxel VMRs.' ...
    );
end
if nargin < 2 || ...
   ~islogical(cutoff) || ...
    isempty(cutoff)
    cutoff = false;
else
    cutoff = cutoff(1);
end

% what outbox
if cutoff
    obox = [bc.OffsetX, bc.OffsetY, bc.OffsetZ];
    obox = [floor(obox / 2); floor((obox + size(bc.VMRData) - 1) / 2)];
else
    obox = [0, 0, 0; 255, 255, 255];
end

% make temporary copy
tfilel = [];
try
    tfile = aft_CopyObject(hfile);
    tfilel = tfile.L;
    vmr_Reframe(tfile, [obox(1, :) .* 2; obox(2, :) .* 2 + 1]);
    tfilec = xffgetcont(tfilel);
    xffclear(tfilel);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    if ~isempty(tfilel)
        xffclear(tfilel);
    end
    error( ...
        'xff:OutOfMemory', ...
        'Error creating temporary sampling object.' ...
    );
end

% create output VMR
hfile2 = xff('new:vmr');
vmr_Reframe(hfile2, obox);
bc2 = xffgetcont(hfile2.L);
nd = uint16([]);
nd(1:(obox(2, 1) + 1), 1:(obox(2, 2) + 1), 1:(obox(2, 3) + 1)) = 0;

% sum elements
for x = 1:2
    for y = 1:2
        for z = 1:2
            nd = nd + ...
                uint16(tfilec.VMRData(x:2:end, y:2:end, z:2:end));
        end
    end
end
for zc = 1:size(nd, 3)
    nd(:, :, zc) = uint16(double(nd(:, :, zc)) ./ 8);
end
if strcmpi(class(tfilec.VMRData), 'uint8')
    nd = uint8(nd);
end
bc2.VMRData = nd;

% do the same for V16 data if present
if ~isempty(tfilec.VMRData16) && ...
    numel(size(tfilec.VMRData16)) == numel(size(tfilec.VMRData)) && ...
    all(size(tfilec.VMRData16) == size(tfilec.VMRData))
    nd = uint16([]);
    nd(1:(obox(2, 1) + 1), 1:(obox(2, 2) + 1), 1:(obox(2, 3) + 1)) = 0;
    for x = 1:2
        for y = 1:2
            for z = 1:2
                nd = nd + ...
                    tfilec.VMRData16(x:2:end, y:2:end, z:2:end);
            end
        end
    end
    for zc = 1:size(nd, 3)
        nd(:, :, zc) = uint16(double(nd(:, :, zc)) ./ 8);
    end
    bc2.VMRData16 = nd;
end

% set offsets / dims
bc2.OffSetX = obox(1, 1);
bc2.OffSetY = obox(1, 2);
bc2.OffSetZ = obox(1, 3);
bc2.DimX = size(nd, 1);
bc2.DimY = size(nd, 2);
bc2.DimZ = size(nd, 3);
xffsetcont(hfile2.L, bc2);
