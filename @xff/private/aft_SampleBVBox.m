function [y, bb, ya] = aft_SampleBVBox(hfile, bb, vol, imeth, trans, sn, ask)
% AFT::SampleBVBox  - sample VoxelData within a BV based box
%
% FORMAT:       y = obj.SampleBVBox([bb [, vol [, imeth [, trans [, sn]]]]])
%
% Input fields:
%
%       bb          BoundingBox struct with fields
%        .BBox      XYZ start/end, default is a MNI "default" box
%                   must be given in BrainVoyager's axes order!!
%        .ResXYZ    resolution (either 1x1 or 1x3), default: [3, 3, 3]
%       vol         volume number (default 1)
%       imeth       method 'cubic', 'lanczos3', {'linear'}, 'nearest'
%       trans       optional 4x4 transformation matrix applied to the
%                   coordinates
%       sn          SPM normalization parameters (file or structure)
%
% Output fields:
%
%       y           double precision data sampled at given coordinates
%
% TYPES: AMR, CMP, DDT, DMR, FMR, GLM, HDR, HEAD, MAP, MSK, NLF, SRF, TVL, VDW, VMP, VMR, VTC
%
% Note: This method requires the MEX file flexinterpn. Also, for use
%       in BrainVoyager (i.e. as VTC), the resolution must be uniform!

% Version:  v0.9d
% Build:    14062311
% Date:     Jun-23 2014, 11:24 AM EST
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
   ~xffisobject(hfile, true)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
sc = xffgetscont(hfile.L);
st = sc.S.Extensions{1};
if ~any(strcmpi(st, {'ava', 'glm', 'hdr', 'head', 'msk', 'nlf', 'vdw', 'vmp', 'vmr', 'vtc'}))
    error( ...
        'xff:BadArgument', ...
        'Invalid file type for ::SampleBVBox.' ...
    );
end
if nargin < 2 || ...
   ~isstruct(bb) || ...
    numel(bb) ~= 1
    bb = struct;
end
if ~isfield(bb, 'BBox') || ...
   ~isequal(size(bb.BBox), [2, 3]) || ...
   ~isa(bb.BBox, 'double') || ...
    any(isinf(bb.BBox(:)) | isnan(bb.BBox(:)) | bb.BBox(:) < 0 | bb.BBox(:) > 256) || ...
    any(diff(bb.BBox) < 0)
    bb.BBox = [44, 38, 44; 241, 193, 211];
end
if ~isfield(bb, 'ResXYZ') || ...
   ~isa(bb.ResXYZ, 'double') || ...
   ~any([1, 3] == numel(bb.ResXYZ)) || ...
    any(isinf(bb.ResXYZ) | isnan(bb.ResXYZ) | bb.ResXYZ < 0.25 | bb.ResXYZ > 15)
    bb.ResXYZ = [3, 3, 3];
else
    if numel(bb.ResXYZ) ~= 3
        bb.ResXYZ = bb.ResXYZ([1, 1, 1]);
    end
end
if nargin < 3 || ...
    isempty(vol)
    vol = 1;
elseif numel(vol) ~= 1 || ...
   ~isa(vol, 'double') || ...
    isinf(vol) || ...
    isnan(vol) || ...
    vol < 1 || ...
    vol ~= fix(vol)
    error( ...
        'xff:BadArgument', ...
        'Invalid vol argument.' ...
    );
end
if nargin < 5 || ...
    isempty(trans)
    trans = eye(4);
elseif ~isa(trans, 'double') || ...
   ~isequal(size(trans), [4, 4]) || ...
    any(isinf(trans(:)) | isnan(trans(:))) || ...
    any(trans(4, :) ~= [0, 0, 0, 1])
    error( ...
        'xff:BadArgument', ...
        'Invalid trans argument.' ...
    );
else
    trans = [0, 0, 1, 0; 1, 0, 0, 0; 0, 1, 0, 0; 0, 0, 0, 1] * trans * ...
        [0, 1, 0, 0; 0, 0, 1, 0; 1, 0, 0, 0; 0, 0, 0, 1];
end
if nargin > 5 && ...
    islogical(sn) && ...
    numel(sn) == 1 && ...
    sn && ...
    isfield(sc.C.RunTimeVars, 'SPMsn') && ...
    numel(sc.C.RunTimeVars.SPMsn) == 1 && ...
    isstruct(sc.C.RunTimeVars.SPMsn)
    sn = sc.C.RunTimeVars.SPMsn;
end
if nargin < 6 || ...
   (~ischar(sn) && ...
    ~isstruct(sn))
    sn = [];
elseif ischar(sn) && ...
   ~isempty(sn)
    try
        sn = load(sn);
    catch ne_eo;
        rethrow(ne_eo);
    end
end
if ~isempty(sn) && ...
   (~isstruct(sn) || ...
     numel(sn) ~= 1 || ...
    ~isfield(sn, 'Affine') || ...
    ~isfield(sn, 'Tr') || ...
    ~isfield(sn, 'VF') || ...
    ~isfield(sn, 'VG') || ...
    ~isa(sn.Affine, 'double') || ...
    ~isequal(size(sn.Affine), [4, 4]) || ...
     any(isinf(sn.Affine(:)) | isnan(sn.Affine(:))) || ...
     any(sn.Affine(4, :) ~= [0, 0, 0, 1]) || ...
     ndims(sn.Tr) ~= 4 || ...
     any(size(sn.Tr) < 2) || ...
     size(sn.Tr, 4) ~= 3 || ...
     any(isinf(sn.Tr(:)) | isnan(sn.Tr(:))) || ...
    ~isstruct(sn.VF) || ...
     isempty(sn.VF) || ...
    ~isfield(sn.VF, 'mat') || ...
    ~isa(sn.VF(1).mat, 'double') || ...
    ~isequal(size(sn.VF(1).mat), [4, 4]) || ...
     any(isinf(sn.VF(1).mat(:)) | isnan(sn.VF(1).mat(:))) || ...
     any(sn.VF(1).mat(4, :) ~= [0, 0, 0, 1]) || ...
    ~isstruct(sn.VG) || ...
     isempty(sn.VG) || ...
    ~isfield(sn.VG, 'mat') || ...
    ~isa(sn.VG(1).mat, 'double') || ...
    ~isequal(size(sn.VG(1).mat), [4, 4]) || ...
     any(isinf(sn.VG(1).mat(:)) | isnan(sn.VG(1).mat(:))) || ...
     any(sn.VG(1).mat(4, :) ~= [0, 0, 0, 1]))
    error( ...
        'xff:BadArgument', ...
        'Invalid sn argument.' ...
    );
end

% for non-BV types, get coordinate frame, otherwise the bounding box
if strcmpi(st, 'head')
    cfr = head_CoordinateFrame(hfile, vol);
    cres = prod(cfr.Resolution) ^ (1/3);
elseif strcmpi(st, 'hdr')
    cfr = hdr_CoordinateFrame(hfile, vol);
    cres = prod(cfr.Resolution) ^ (1/3);
elseif strcmpi(st, 'nlf')
    cfr = nlf_CoordinateFrame(hfile, vol);
    cres = prod(cfr.Resolution) ^ (1/3);
else
    mbx = aft_BoundingBox(hfile);
    cfr = struct('Trf', mbx.QuatB2T);
    cres = prod(mbx.ResXYZ) ^ (1/3);
end
if nargin < 7 || ...
   ~isa(ask, 'double') || ...
    numel(ask) ~= 1 || ...
    isinf(ask) || ...
    isnan(ask) || ...
    ask < (0.5 * cres)
    ask = 0;
else
    ask = min(4, ask / cres);
end
try
    tmat = inv(double(cfr.Trf)) * trans;
catch ne_eo;
    rethrow(ne_eo);
end
if nargin < 4 || ...
   ~ischar(imeth) || ...
   ~any(strcmpi(imeth(:)', {'cubic', 'lanczos3', 'lanczos8', 'linear', 'nearest'}))
    imeth = 'linear';
else
    imeth = lower(imeth(:)');
end
bb.BBox(2, :) = bb.BBox(1, :) + bb.ResXYZ .* ceil(diff(bb.BBox) ./ bb.ResXYZ) - bb.ResXYZ;
bb.SBox = [ ...
    Inf, Inf, Inf; ...
    128 - bb.BBox(1, [3, 1, 2]); ...
    -bb.ResXYZ; ...
    128 - bb.BBox(2, [3, 1, 2])];

% get data in single precision
try
    [vdt, trfplus, snmat, ya] = aft_GetVolume(hfile, vol, true);
    if nargout > 2 && ...
        ask ~= 0 && ...
        numel(ya) > 1
        yas = limitrangec(smoothdata3(ya, ask), 0, 1, 0);
        yasc = (ya > 0);
        yasc = (yasc & ~erode3d(yasc));
        ya(yasc) = yas(yasc);
    end
    vdt = single(vdt);
    if ~isempty(snmat)
        sn = snmat;
    end
    trfplusi = inv(trfplus);
catch ne_eo;
    rethrow(ne_eo);
end

% set NaNs to 0 first
vdt(isnan(vdt)) = 0;
rtv = sc.C.RunTimeVars;

% without normalization
if isempty(sn)

    % sampling transformation
    tmatb = tmat([2, 3, 4, 5, 7, 8, 9, 10, 12]);
    if all(abs(tmatb) <= eps)
        bb.SBox(2:4, :) = bb.SBox(2:4, :) .* tmat([1, 6, 11; 1, 6, 11; 1, 6, 11]);
        bb.SBox([2, 4], :) = bb.SBox([2, 4], :) + tmat([13, 14, 15; 13, 14, 15]);
        tmat = {};
        bb.Trf = eye(4);
    else
        bb.Trf = tmat;
        tmat = {tmat};
    end

    % and yet additional from TrfPlus
    if isfield(rtv, 'TrfPlus') && ...
        isequal([4, 4], size(rtv.TrfPlus)) && ...
        any(any(rtv.TrfPlus ~= eye(4)))
        bb.Trf = bb.Trf * rtv.TrfPlus * trfplus;
        if isempty(tmat)
            tmat = {trfplusi * inv(rtv.TrfPlus)};
        else
            tmat = {tmat{1} * trfplusi * inv(rtv.TrfPlus)};
        end
    end

    % interpolation
    y = permute(flexinterpn_method(vdt(:, :, :, 1), bb.SBox, 0, tmat{:}, imeth), [2, 3, 1]);
    for d5c = 2:size(vdt, 5)
        y(:, :, :, d5c) = permute(flexinterpn_method( ...
            vdt(:, :, :, 1, d5c), bb.SBox, 0, tmat{:}, imeth), [2, 3, 1]);
    end
    if numel(ya) > 1 && ...
        nargout > 2
        ya = permute(flexinterpn_method(ya, bb.SBox, 0, tmat{:}, imeth), [2, 3, 1]);
    end

% with normalization
else

    % compute required x/y voxels and slices
    nx = numel(bb.SBox(2, 2):bb.SBox(3, 2):bb.SBox(4, 2));
    ny = numel(bb.SBox(2, 3):bb.SBox(3, 3):bb.SBox(4, 3));
    zp = bb.SBox(2, 1):bb.SBox(3, 1):bb.SBox(4, 1);
    nz = numel(zp);

    % compute post multiplication part
    tmat = tmat * trfplusi;
    if isfield(rtv, 'TrfPlus') && ...
        isequal([4, 4], size(rtv.TrfPlus)) && ...
        any(any(rtv.TrfPlus ~= eye(4)))
        tmat = tmat * inv(rtv.TrfPlus);
    end

    % create output data
    y = zeros(nx, ny, nz, size(vdt, 5));

    % sample slice-by-slice (and volume-by-volume)
    ivgm = inv(sn.VG(1).mat);
    yasrc = ya;
    if numel(ya) > 1 && ...
        nargout > 2
        ya = zeros(nx, ny, nz);
    end
    for zc = 1:nz
        bb.SBox([2, 4], 1) = zp(zc);
        normcrd = applyspmsnc(bb.SBox, sn.Tr, sn.VG(1).dim, ...
                ivgm, tmat * sn.VF.mat * sn.Affine);
        for d5c = 1:size(vdt, 5)
            y(:, :, zc, d5c) = reshape(flexinterpn_method( ...
                vdt(:, :, :, 1, d5c), normcrd, 0, imeth), nx, ny);
        end
        if numel(yasrc) > 1 && ...
            nargout > 2
            ya(:, :, zc) = reshape(flexinterpn_method( ...
                yasrc, normcrd, 0, imeth), nx, ny);
        end
    end
end
