function hfile2 = vmr_Talairach(hfile, imeth, tal, acpc, inverse)
% VMR::Talairach  - Un/Talairachize VMR
%
% FORMAT:       talvmr = vmr.Talairach(imeth, tal [, acpc, inverse]);
%
% Input fields:
%
%       imeth   interpolation method ('linear', 'cubic', 'lanczos3')
%       tal     TAL object
%       acpc    optional ACPC TRF file to go from/back to native space
%       inverse perform inverse (un-Tal, un-ACPC) operation
%
% Output fields:
%
%       tvmr    (un-) Talairachized VMR
%
% Note: only works on VMRs in 1mm or 0.5mm ISOvoxel resolution

% TODO: piecewise interpolation !!

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
if nargin < 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vmr') || ...
   ~ischar(imeth) || ...
    isempty(imeth) || ...
   ~any(strcmpi(imeth(:)', {'cubic', 'lanczos3', 'linear'})) || ...
    numel(tal) ~= 1 || ...
   ~xffisobject(tal, true, 'tal')
    error( ...
        'xff:BadArgument', ...
        'Bad or missing argument.' ...
    );
end
bc = xffgetcont(hfile.L);
if (bc.FileVersion > 1 && ...
    (any([bc.VoxResX, bc.VoxResY, bc.VoxResZ] ~= 1 & ...
         [bc.VoxResX, bc.VoxResY, bc.VoxResZ] ~= 0.5) || ...
     ~all([bc.VoxResY, bc.VoxResZ] == bc.VoxResX)))
    error( ...
        'xff:InvaldObject', ...
        'Method only valid for 1mm or 0.5mm ISOvoxel VMRs.' ...
    );
end
doovinv = false;
if nargin == 4 && ...
    islogical(acpc) && ...
   ~isempty(acpc)
    ovinv = acpc(1);
    doovinv = true;
end
if nargin < 4 || ...
    numel(acpc) ~= 1 || ...
   ~xffisobject(acpc, true, 'trf')
    acpc = [];
else
    acpcbc = xffgetcont(acpc.L);
    if ~strcmpi(acpcbc.DataFormat, 'Matrix') || ...
        acpcbc.TransformationType ~= 2
        acpc = [];
    else
        acpc = acpcbc.TFMatrix;
    end
end
if nargin < 5 || ...
   ~islogical(inverse) || ...
    isempty(inverse)
    inverse = false;
else
    inverse = inverse(1);
end
if doovinv
    inverse = ovinv;
end
if inverse && ...
   ~isempty(acpc)
    try
        acpc = inv(acpc)';
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        error( ...
            'xff:BadArgument', ...
            'Couldn''t invert ACPC transformation matrix.' ...
        );
    end
elseif ~isempty(acpc)
    acpc = acpc';
end
tvmrd = bc.VMRData(1);
tvmrd(1) = 0;

% create new VMR
hfile2 = xff('new:vmr');
cfile2 = xffgetcont(hfile2.L);
cfile2.VMR8bit = bc.VMR8bit;
if ~inverse
    cfile2.VoxResInTalairach = true;
end
cfile2.VoxResVerified = bc.VoxResVerified;

% grids depend on
res = bc.VoxResX;
if res == 1
    cs = 256;
else
    cs = 512;
    cfile2.VoxResX = res;
    cfile2.VoxResY = res;
    cfile2.VoxResZ = res;
end
[xgrd, ygrd] = ndgrid(0:res:255.5, 0:res:255.5);
tc = [xgrd(:), ygrd(:), zeros(numel(xgrd), 1)];
zval = 0:res:255.5;
zc = [zeros(numel(zval), 2), zval(:)];

% the simple way only works for forward or single transformation !
if ~inverse || ...
    isempty(acpc)
    tc(:, [3, 1, 2]) = acpc2tal(tc(:, [3, 1, 2]), tal, ~inverse);
    zc(:, [3, 1, 2]) = acpc2tal(zc(:, [3, 1, 2]), tal, ~inverse);
end
if ~isempty(acpc)
    tc = tc - 127.5;
    zc = zc - 127.5;
end
zval = zc(:, 3)';
tc(:, 4) = 1;

% determine progress bar capabilities
try
    if ~inverse
        if isempty(acpc)
            step = 'Talairach transforming';
        else
            step = 'ACPC / Talairach transforming';
        end
    else
        if isempty(acpc)
            step = 'Un-Talairach transforming';
        else
            step = 'Un-Tal / Un-ACPC transforming';
        end
    end

    pbar = xprogress;
    xprogress(pbar, 'setposition', [80, 200, 640, 36]);
    xprogress(pbar, 'settitle', sprintf('%s VMR...', step));
    xprogress(pbar, 0, 'Setting up target VMR...', 'visible', 0, 1);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    pbar = [];
end

% get sampling data
try
    if istransio(bc.VMRData)
        sdt = bc.VMRData(:, :, :);
    else
        sdt = bc.VMRData;
    end
catch ne_eo;
    xffclear(hfile2.L);
    rethrow(ne_eo);
end

% create output matrix
cfile2.VMRData = tvmrd;
tvmrd(1:(cs * cs), 1:cs) = tvmrd;

% get sampling offset and size
ssz = size(sdt) + 1;
try
    sof = [bc.OffsetX, bc.OffsetY, bc.OffsetZ];
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    sof = [0, 0, 0];
end

% iterate over z slices
if ~isempty(pbar)
    xprogress(pbar, 0, 'Interpolating...', 'visible', 0, numel(zval));
end
for zc = 1:numel(zval)

    % apply transformation
    tc(:, 3) = zval(zc);
    if ~isempty(acpc)
        sc = (tc * acpc) + 127.5;
    else
        sc = tc;
    end

    % apply UnTal after ACPC
    if inverse && ...
       ~isempty(acpc)
        sc(:, [3, 1, 2]) = acpc2tal(sc(:, [3, 1, 2]), tal);
    end

    % good scaling / origin
    if res == 0.5
        sc = (2 .* sc + 1.5);
    else
        sc = sc + 1;
    end

    % offset
    if any(sof)
        sc = [sc(:, 1) - sof(1), sc(:, 2) - sof(2), sc(:, 3) - sof(3)];
    end

    % good samples
    p = (sc(:, 1) >= 0 & sc(:, 1) <= ssz(1) & ...
         sc(:, 2) >= 0 & sc(:, 2) <= ssz(2) & ...
         sc(:, 3) >= 0 & sc(:, 3) <= ssz(3));

    % sample VMR
    if any(p)

        % sample whole volume
        tvmrd(p, zc) = round( ...
            flexinterpn_method(sdt, sc(p, 1:3), 0, imeth));
    end

    % progress bar
    if ~isempty(pbar)
        xprogress(pbar, zc);
    end
end

% make sure to limit 8bit VMR
if strcmpi(class(tvmrd), 'uint8')
    tvmrd = min(tvmrd, uint8(225));
end

% set some more VMR fields
tvmrd = reshape(tvmrd, [cs, cs, cs]);
cfile2.VMRData = tvmrd;
cfile2.VoxResInTalairach = double(~inverse);

% make sure that V16 files are FileVersion 1
if ~cfile2.VMR8bit || ...
    strcmpi(class(cfile2.VMRData), 'uint16')
    hfile2 = vmr_Update(hfile2, 'FileVersion', [], 1);
    cfile2.VMR8bit = false;
end
xffsetcont(hfile2.L, cfile2);

% progress bar
if ~isempty(pbar)
    closebar(pbar);
end
