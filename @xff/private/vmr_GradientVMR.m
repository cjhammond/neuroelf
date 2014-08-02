function [hfile2, hfile3, hfile4, hfile5] = vmr_GradientVMR(hfile, gdir)
% VMR::GradientVMR  - compute gradient VMR(s)
%
% FORMAT:       [gvmr, gvmrx, gvmry, gvmrz] = vmr.GradientVMR([gdir]);
%
% Input fields:
%
%       gdir        flag whether to create directional VMRs too
%
% Output fields:
%
%       gvmr        gradient VMR (intensity of gradient)
%       gvmrx       X-gradient VMR (TAL X axis!)
%       gvmry       Y-gradient VMR (TAL Y axis!)
%       gvmrz       Z-gradient VMR (TAL Z axis!)

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
bcs = xffgetcont(hfile.L);
if nargin < 2 || ...
   ~islogical(gdir) || ...
    isempty(gdir)
    gdir = false;
else
    gdir = gdir(1);
end

% first make a copy
vsz = size(bcs.VMRData);
hfile2 = aft_CopyObject(hfile);
sfile2 = xffgetscont(hfile2.L);
sfile2.F = '';
sfile2.C.VMRData = uint8([]);
sfile2.C.VMRData(1:vsz(1), 1:vsz(2), 1:vsz(3)) = uint8(0);
sfile2.C.VMRData16 = [];
xffsetscont(hfile2.L, sfile2);
bc2 = sfile2.C;
if ~gdir
    hfile3 = [];
    hfile4 = [];
    hfile5 = [];
else
    hfile3 = aft_CopyObject(hfile2);
    bc3 = xffgetcont(hfile3.L);
    hfile4 = aft_CopyObject(hfile2);
    bc4 = xffgetcont(hfile4.L);
    hfile5 = aft_CopyObject(hfile2);
    bc5 = xffgetcont(hfile5.L);
end
clobs = {hfile2, hfile3, hfile4, hfile5};

% take resolution into account
try
    xres = single(bcs.VoxResZ);
    yres = single(bcs.VoxResX);
    zres = single(bcs.VoxResY);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    xres = single(1);
    yres = single(1);
    zres = single(1);
end

% calculus
onestep = true;
usev16 = false;
if prod(vsz) < 2e7
    try
        if isempty(bcs.VMRData16) || ...
            numel(size(bcs.VMRData16)) ~= numel(size(bcs.VMRData)) || ...
            any(size(bcs.VMRData16) ~= size(bcs.VMRData))
            usev16 = true;
            [grz, gry, grx] = ...
                gradient(single(bcs.VMRData), zres, yres, xres);
        else
            [grz, gry, grx] = ...
                gradient(single(bcs.VMRData16), zres, yres, xres);
        end
        grl = sqrt(grx .* grx + gry .* gry + grz .* grz);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        onestep = false;
    end
else
    onestep = false;
end
if ~onestep
    try
        if gdir
            grx = single([]);
            gry = single([]);
            grz = single([]);
            grx(1:vsz(1), 1:vsz(2), 1:vsz(3)) = 0;
            gry(1:vsz(1), 1:vsz(2), 1:vsz(3)) = 0;
            grz(1:vsz(1), 1:vsz(2), 1:vsz(3)) = 0;
        end
        grl = single([]);
        grl(1:vsz(1), 1:vsz(2), 1:vsz(3)) = 0;

        % make in packs
        for zc = 2:(vsz(3) - 1)
            if ~usev16
                [pgz, pgy, pgx] = gradient(single( ...
                    bcs.VMRData(:, :, (zc-1:zc+1))), zres, yres, xres);
            else
                [pgz, pgy, pgx] = gradient(single( ...
                    bcs.VMRData16(:, :, (zc-1:zc+1))), zres, yres, xres);
            end
            if zc == 2
                pgx = pgx(:, :, 1:2);
                pgy = pgy(:, :, 1:2);
                pgz = pgz(:, :, 1:2);
                pgl = sqrt(pgx .* pgx + pgy .* pgy + pgz .* pgz);
                if gdir
                    grx(:, :, 1:2) = pgx;
                    gry(:, :, 1:2) = pgy;
                    grz(:, :, 1:2) = pgz;
                end
                grl(:, :, 1:2) = pgl;
            elseif zc == (vsz(3) - 1)
                pgx = pgx(:, :, 2:3);
                pgy = pgy(:, :, 2:3);
                pgz = pgz(:, :, 2:3);
                pgl = sqrt(pgx .* pgx + pgy .* pgy + pgz .* pgz);
                if gdir
                    grx(:, :, end-1:end) = pgx;
                    gry(:, :, end-1:end) = pgy;
                    grz(:, :, end-1:end) = pgz;
                end
                grl(:, :, end-1:end) = pgl;
            else
                pgx = pgx(:, :, 2);
                pgy = pgy(:, :, 2);
                pgz = pgz(:, :, 2);
                pgl = sqrt(pgx .* pgx + pgy .* pgy + pgz .* pgz);
                if gdir
                    grx(:, :, zc) = pgx;
                    gry(:, :, zc) = pgy;
                    grz(:, :, zc) = pgz;
                end
                grl(:, :, zc) = pgl;
            end
        end
        clear pg*
    catch ne_eo;
        clearxffobjects(clobs);
        error( ...
            'xff:OutOfMemory', ...
            'Out of memory (%s).', ...
            ne_eo.message ...
        );
    end
end

% useful limitting depends on VMR type
mxg = single(ceil(max(grl(:))));
mxt = single(220);
[hn, hx] = hist(grl(grl > 0), 10 * mxg);
hnc = cumsum(hn);
ofx = find(hnc >= (0.999 * numel(grl)));
if isempty(ofx)
    ofx = floor(0.999 * numel(hn));
end
mxg = hx(ofx(1));
grl = min(mxt, grl ./ (mxg / mxt));
bc2.VMRData(1:vsz(1), 1:vsz(2), 1:vsz(3)) = round(grl);
xffsetcont(hfile2.L, bc2);

% directions
if gdir

    % thresholding
    mxt = mxt / single(2);
    mxx = max(abs(grx(:)));
    mxy = max(abs(gry(:)));
    mxz = max(abs(grz(:)));
    mxg = 2 * max([mxx, mxy, mxz]);
    if mxg > mxt
        grx = (-grx - abs(min(grx(:)))) ./ (mxg ./ mxt);
        gry = (-gry - abs(min(gry(:)))) ./ (mxg ./ mxt);
        grz = (-grz - abs(min(grz(:)))) ./ (mxg ./ mxt);
    end

    % absolute values, in TAL notation !
    bc3.VMRData(:, :, :) = grz;
    bc4.VMRData(:, :, :) = grx;
    bc5.VMRData(:, :, :) = gry;
    xffsetcont(hfile3.L, bc3);
    xffsetcont(hfile4.L, bc4);
    xffsetcont(hfile5.L, bc5);
end
