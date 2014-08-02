function success = hdr_SaveVoxelData(hfile, flip)
% HDR::SaveVoxelData  - save Analyze image voxel data
%
% FORMAT:       hdr.SaveVoxelData([flip]);
%
% Input fields:
%
%       flip        optional flipping string (e.g. 'xy', default: '')
%
% No output fields.

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
   ~xffisobject(hfile, true, 'hdr')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~ischar(flip) || ...
    numel(flip) > 3
    flip = '';
else
    flip = lower(flip(:)');
end
if any(flip == 'x')
    xflip = true;
else
    xflip = false;
end
if any(flip == 'y')
    yflip = true;
else
    yflip = false;
end
if any(flip == 'z')
    zflip = true;
else
    zflip = false;
end

% get HDR file name -> IMG file
hdrs = xffgetscont(hfile.L);
hdrc = hdrs.C;
fflp = hdrs.F;

% no VoxelData
if isempty(hdrc.VoxelData)
    disp('Empty VoxelData field. Nothing saved.');
    return;
end

% look in same folder
[ffpn, fflp] = fileparts(fflp);
ifname = [ffpn filesep fflp '.img'];
ifnamc = [ffpn filesep fflp '.IMG'];
if ~exist(ifname, 'file') == 2 && ...
    exist(ifnamc, 'file') == 2
    ifname = ifnamc;
end

% get data size and type
try
    dsize = hdrc.ImgDim.Dim(2:1 + hdrc.ImgDim.Dim(1));
    tsize = prod(dsize);
catch ne_eo;
    error( ...
        'xff:BadFileContent', ...
        'Analyze ImgDim.Dim field error (%s).', ...
        ne_eo.message ...
    );
end
dtype = hdrc.ImgDim.DataType;
if isempty(dtype)
    dtype = 0;
end
endian = hdrs.S.EncodingSyntax;
if dtype > 255
    dtype = fix(dtype / 256);
    switch lower(endian)
        case {'ieee-le'}
            endian = 'ieee-be';
        case {'ieee-be'}
            endian = 'ieee-le';
        otherwise
            error( ...
                'xff:InternalError', ...
                'Bad machine datatype/encoding syntax combination.' ...
            );
    end
end
[tmat, stype] = analyzetype(dtype);
stype = splittocell(stype, '=');
stype = stype{1};

% occupy mem
try
    if ~any([xflip, yflip, zflip])
        tmat = reshape(hdrc.VoxelData(:), [tsize, 1]);
    else
        tmat = hdrc.VoxelData;
        if istransio(tmat)
            tmat = resolve(tmat);
        end
        if xflip
            tmat = tmat(end:-1:1, :, :, :);
        end
        if yflip
            tmat = tmat(:, end:-1:1, :, :);
        end
        if zflip
            tmat = tmat(:, :, end:-1:1, :);
        end
        tmat = reshape(tmat, [tsize, 1]);
    end
catch ne_eo;
    error( ...
        'xff:InvalidArraySize', ...
        'Invalid VoxelData array size (%s).', ...
        ne_eo.message ...
    );
end

% open image file
try
    fid = [];
    fid = fopen(ifname, 'wb', endian);
    fseek(fid, 0, 'bof');
    if hdrc.ImgDim.VoxOffset > 0
        fwrite(fid, ...
            char(zeros(1, floor(hdrc.ImgDim.VoxOffset))), ...
            'char');
    end
catch ne_eo;
    oeo = ne_eo;
    try
        fclose(fid);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
    error( ...
        'xff:FileNotReadable', ...
        'Error opening/writing image file %s (%s).', ...
        ifname, oeo.message ...
    );
end

% write data to voxeldata file
try
    success = (fwrite(fid, tmat, stype) == tsize);
catch ne_eo;
    success = false;
    warning( ...
        'xff:ErrorWritingData', ...
        'Couldn''t write image data into file %s (%s).', ...
        ifname, ne_eo.message ...
    );
end
fclose(fid);
