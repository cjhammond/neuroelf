function hfile = dmr_Write4DNifti(hfile, outfile, range)
% DMR::Write4DNifti  - writes analyze vols for the (entire) DWI data
%
% FORMAT:       dmr.Write4DNifti(outfile, range)
%
% Input fields:
%
%       outfile     output filename (if empty, replace .dmr with .nii)
%       range       range of volumes (default: all)
%
% No output fields.

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
   ~xffisobject(hfile, true, 'dmr')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
sc = xffgetscont(hfile.L);
bc = sc.C;
if nargin < 2 || ...
   ~ischar(outfile) || ...
    numel(outfile) < 5
    if isempty(sc.F)
        error( ...
            'xff:FilenameRequired', ...
            'DMR unsaved, filename required.' ...
        );
    end
    outfile = [sc.F(1:end-4) '.nii'];
else
    outfile = outfile(:)';
    if ~strcmpi(outfile(end-3:end), '.nii')
        outfile = [outfile '.nii'];
    end
end

% get the data
try
    stcd = bc.DWIData;
    if istransio(stcd)
        stcd = resolve(stcd);
    end
    if bc.DataStorageFormat == 2
        stcd = permute(stcd, [1, 2, 4, 3]);
    elseif bc.DataStorageFormat == 4
        stcd = permute(stcd, [2, 3, 4, 1]);
    elseif bc.DataStorageFormat ~= 3 || ...
        isempty(stcd)
        error( ...
            'xff:BadArgument', ...
            'DMR object has unsupported DataStorageFormat or missing data.' ...
        );
    end
catch ne_eo;
    rethrow(ne_eo);
end

% get settings
vs = size(stcd);
numvol = vs(4);
if nargin < 3 || ...
   ~isa(range, 'double') || ...
    isempty(range) || ...
    numel(range) ~= max(size(range)) || ...
    any(isinf(range) | isnan(range) | range < 1 | range > numvol | range ~= fix(range))
    range = [];
else
    range = range(:)';
end
vr = [bc.InplaneResolutionX, bc.InplaneResolutionY, ...
    bc.SliceThickness + bc.SliceGap];

% big TRY/CATCH
nio = {[]};
try

    % create temporary NII object
    nio{1} = xff('new:nii');
    nii = xffgetcont(nio{1}.L);

    % general settings
    nii.NIIFileType = 2;
    nii.FileMagic = 'n+1';

    % set VoxelData
    if isempty(range)
        nii.VoxelData = stcd;
    else
        nii.VoxelData = stcd(:, :, :, range);
    end

    % set size, type, etc.
    nii.ImgDim.Dim(1:5) = [4, size(nii.VoxelData)];
    if ~strcmpi(class(nii.VoxelData), 'single')
        nii.ImgDim.DataType = 512;
        nii.ImgDim.BitsPerPixel = 16;
    else
        nii.ImgDim.DataType = 16;
        nii.ImgDim.BitsPerPixel = 32;
    end
    nii.ImgDim.PixSpacing(2:4) = vr;

    % generate transformation matrix rows
    trf = fmr_CoordinateFrame(hfile);
    trf = trf.Trf;
    trf(1:3, 4) = trf(1:3, 4) + trf(1:3, 1:3) * [1; 1; 1];
    nii.DataHist.NIftI1.AffineTransX = trf(1, :);
    nii.DataHist.NIftI1.AffineTransY = trf(2, :);
    nii.DataHist.NIftI1.AffineTransZ = trf(3, :);

    % set in object
    xffsetcont(nio{1}.L, nii);

    % save file
    aft_SaveAs(nio{1}, outfile);
catch ne_eo;
    clearxffobjects(nio);
    rethrow(ne_eo);
end

% clear object
clearxffobjects(nio);
