function msk = voi_CreateMSK(hfile, bbo, vspec)
% VOI::CreateMSK  - create a MSK object of VOI voxels
%
% FORMAT:       msk = voi.CreateMSK(bbo [, vspec])
%
% Input fields:
%
%       bbo         bounding box or object to create bounding box from
%       vspec       voi index specification (list of indices, default: all)
%
% Output fields:
%
%       msk         MSK (or HDR/NII) object with VOI voxels set to 1

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2011, 2013, 2014, Jochen Weber
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
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'voi') || ...
    numel(bbo) ~= 1 || ...
   (~xffisobject(bbo, true, {'ava', 'cmp', 'gcm', 'glm', 'hdr', 'ica', 'msk', 'vdw', 'vmp', 'vtc'}) && ...
    (~isstruct(bbo) || ...
     ~isfield(bbo, 'BBox') || ...
     ~isfield(bbo, 'DimXYZ') || ...
     ~isfield(bbo, 'FCube') || ...
     ~isfield(bbo, 'ResXYZ')))
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
if nargin < 3 || ...
   ~isa(vspec, 'double') || ...
    isempty(vspec) || ...
    any(isinf(vspec(:)) | isnan(vspec(:)) | vspec(:) < 1 | vspec(:) ~= fix(vspec(:)))
    vspec = 1:numel(bc.VOI);
else
    vspec = unique(vspec(:))';
end
if any(vspec > numel(bc.VOI))
    error( ...
        'xff:BadArgument', ...
        'Selected VOI(s) out of bounds.' ...
    );
end

% coordinate space
natspc = ~strcmpi(bc.ReferenceSpace, 'tal');
if natspc
    voxres = [bc.OriginalVMRResolutionX, bc.OriginalVMRResolutionY, ...
        bc.OriginalVMRResolutionZ];
    voxoff = [bc.OriginalVMROffsetX, bc.OriginalVMROffsetY, ...
        bc.OriginalVMROffsetZ];
    convflag = 'bvi2bvx';
else
    convflag = 'tal2bvx';
end

% get bounding box if necessary
if xffisobject(bbo, true)

    % HDR object ?
    if xffisobject(bbo, true, 'hdr')

        % copy the object
        msk = bless(aft_CopyObject(bbo));
        mskc = xffgetcont(msk.L);

        % get coordinate frame
        cfr = hdr_CoordinateFrame(msk);

        % remove RunTimeVars content (other than default fields)
        rtv = mskc.RunTimeVars;
        mskc.RunTimeVars = struct( ...
            'Discard', [], ...
            'Map',     rtv.Map(1), ...
            'Mat44',   rtv.Mat44(:, :, 1:min(1, size(rtv.Mat44, 3))), ...
            'xffID',   rtv.xffID);
        if isfield(rtv, 'TrfPlus')
            mskc.RunTimeVars.TrfPlus = ...
                rtv.TrfPlus(:, :, 1:min(1, size(rtv.TrfPlus, 3)));
        end

        % generate mask
        voxmask = size(mskc.VoxelData);
        voxmask(4:end) = [];
        voxmask = uint8(zeros(voxmask));

        % compute voxel coordinates
        voxcoord = cat(1, bc.VOI(vspec).Voxels);
        voxcoord(:, 4) = 1;
        voxcoord = voxcoord * inv(cfr.Trf)';
        voxcoord(:, 4) = [];
        voxcoord = unique(round(voxcoord), 'rows');

        % fill mask
        voxmask(sub2ind(size(voxmask), voxcoord(:, 1), voxcoord(:, 2), voxcoord(:, 3))) = 1;

        % store back
        mskc.ImgDim.Dim([1, 5:8]) = [4, 1, 0, 0, 0];
        mskc.ImgDim.DataType = 2;
        mskc.ImgDim.BitsPerPixel = 8;
        mskc.ImgDim.ScalingSlope = 1;
        mskc.ImgDim.ScalingIntercept = 0;
        mskc.ImgDim.CalMaxDisplay = 1;
        mskc.ImgDim.CalMinDisplay = 0;
        mskc.VoxelData = voxmask;

        % set content
        xffsetcont(msk.L, mskc);

        % return already
        return;
    end

    % otherwise
    bbo = aft_BoundingBox(bbo);
end

% create MSK
msk = bless(xff('new:msk'), 1);
mskc = xffgetcont(msk.L);

% adapt resolution, etc.
xyzdim = bbo.DimXYZ;
xyzend = bbo.BBox(1, :) + bbo.ResXYZ(1) .* xyzdim;
mskc.Resolution = bbo.ResXYZ(1);
mskc.XStart = bbo.BBox(1, 1);
mskc.XEnd = xyzend(1);
mskc.YStart = bbo.BBox(1, 2);
mskc.YEnd = xyzend(2);
mskc.ZStart = bbo.BBox(1, 3);
mskc.ZEnd = xyzend(3);

% create empty mask
mskc.Mask = repmat(uint8(0), xyzdim);

% iterate over selected VOIs
for vc = 1:numel(vspec)

    % get voxels
    vox = bc.VOI(vspec(vc)).Voxels;

    % native space
    if natspc

        % adapt voxels first
        nvox = ones(size(vox, 1), 1);
        vox = vox .* voxres(nvox, :) + voxoff(nvox, :);
    end

    % convert
    vox = bvcoordconv(vox, convflag, bbo);

    % remove out-of-box indices (now NaN!)
    vox(isnan(vox)) = [];

    % fill coordinates with 1's
    mskc.Mask(vox) = 1;
end

% set content
xffsetcont(msk.L, mskc);
