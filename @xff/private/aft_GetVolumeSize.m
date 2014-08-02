function ys = aft_GetVolumeSize(hfile)
% AFT::GetVolumeSize  - get volume size from a (multi-volume) object
%
% FORMAT:       ys = obj.GetVolumeSize;
%
% No input fields.
%
% Output fields:
%
%       ys          size of uninterpolated (raw) volume of object
%
% Note: this methods works with
%
%       amr       get AMR data (volnum discarded, can only be 1) size
%       cmp       get component map with number volnum size
%       ddt       get the corresponding volume (1 .. 12) size
%       dmr       get according volume size of DWI file
%       fmr       get according volume size of STC file(s)
%       glm       get beta map size with index volnum (scheme PxS)
%       hdr       get sub-volume size of 4D image file (1st volume otherwise)
%       head      get sub-brick data size from HEAD/BRIK object
%       map       get FMR based map size (volnum discarded, can only be 1)
%       msk       get MSK data size (volnum discarded, can only be 1)
%       nlf       get NeuroElf data size
%       vdw       get tensor imaging volume size with number volnum
%       vmp       get according statistical map size with number volnum
%       vmr       get VMR data size (volnum discarded, can only be 1)
%       vtc       get functional volume size with number volnum
%
% TYPES: AMR, AVA, CMP, DDT, DMR, FMR, GLM, HEAD, MAP, MSK, NLF, VDW, VMP, VMR, VTC

% Version:  v0.9d
% Build:    14030412
% Date:     Mar-04 2014, 12:45 PM EST
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

% get super-struct
ssc = xffgetscont(hfile.L);
ft = lower(ssc.S.Extensions{1});
if ~any(strcmp(ft, ...
    {'amr', 'ava', 'cmp', 'ddt', 'dmr', 'fmr', 'glm', 'hdr', ...
     'head', 'map', 'msk', 'nlf', 'vdw', 'vmp', 'vmr', 'vtc'}))
    error( ...
        'xff:BadArgument', ...
        'GetVolume not supported for this object type.' ...
    );
end
ys = [0, 0, 0];

% depends on filetype
bc = ssc.C;
switch (ft)

    % AMR
    case {'amr'}

        % number of slices first
        ys(3) = numel(bc.Slice);
        if ys(3) > 0
            as = size(bc.Slice(1).AMRData);
            ys(1:2) = as(1:2);
        end

    % AVA
    case {'ava'}
        as = size(bc.Maps.CellMeans);
        try
            ys = as(1:3);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xff:InvalidObject', ...
                'AVA object must have valid CellMeans Map in Maps.' ...
            );
        end

    % CMP
    case {'cmp'}
        if ~isempty(bc.Map)
            as = size(bc.Map(1).CMPData);
            try
                ys = as(1:3);
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                error( ...
                    'xff:InvalidObject', ...
                    'CMP Map contains invalid CMPData member.'  ...
                );
            end
        else
            try
                if bc.DocumentType == 0
                    ys = [bc.NrOfColumns, bc.NrOfRows, bc.NrOfSlices];
                elseif bc.DocumentType == 1
                    ys = diff([bc.XStart, bc.YStart, bc.ZStart; ...
                        bc.XEnd, bc.YEnd, bc.ZEnd]) ./ bc.Resolution;
                else
                    ys = [bc.NrOfVertices, 1];
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                error( ...
                    'xff:InvalidObject', ...
                    'CMP has invalid X/Y/Z-Start/End or Resolution setting.'  ...
                );
            end
        end

    % DDT
    case {'ddt'}
        as = size(bc.TensorEigenVs);
        try
            ys = as(2:4);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xff:InvalidObject', ...
                'Bad TensorEigenVs array in DDT object.' ...
            );
        end

	% DMR
    case {'dmr'}

        % depends on storage format
        as = size(bc.DWIData);
        try
            ys = [];
            switch (bc.DataStorageFormat)
                case {2}
                    ys = as([1, 2, 4]);
                case {3}
                    ys = as(1:3);
                case {4}
                    ys = as(2:4);
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xff:InvalidObject', ...
                'Bad DWIData array in DMR object.' ...
            );
        end
        if isempty(ys)
            error( ...
                'xff:InvalidObject', ...
                'DataStorageFormat unknown.' ...
            );
        end

    % FMR
    case {'fmr'}
        if isempty(bc.Slice)
            error( ...
                'xff:InvalidObject', ...
                'STC data must be loaded first.' ...
            );
        end

        % depends on FileVersion and DataStorageFormat
        if bc.FileVersion < 5 || ...
            bc.DataStorageFormat == 1
            ys = [0, 0, 0];
            ys(3) = numel(bc.Slice);
            if ys(3) > 0
                as = size(bc.Slice(1).STCData);
                ys(1:2) = as(1:2);
            else
                ys(1:2) = [bc.ResolutionX, bc.ResolutionY];
            end
        else
            try
                ys = [];
                as = size(bc.Slice(1).STCData);
                switch (bc.DataStorageFormat)
                    case {2}
                        ys = as([1, 2, 4]);
                    case {3}
                        ys = as(1:3);
                    case {4}
                        ys = as(2:4);
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                error( ...
                    'xff:InvalidObject', ...
                    'Invalid STCData in FMR.Slice.' ...
                );
            end
            if isempty(ys)
                error( ...
                    'xff:InvalidObject', ...
                    'Invalid DataStorageFormat in FMR.' ...
                );
            end
        end

    % GLM
    case {'glm'}
        if bc.ProjectType > 1
            error( ...
                'xff:InvalidObject', ...
                'Not valid for SRF/MTC-based GLMs.' ...
            );
        end
        try
            if bc.ProjectTypeRFX <= 0
                as = size(bc.GLMData.BetaMaps);
            else
                if ~isempty(bc.GLMData.Subject)
                    as = size(bc.GLMData.Subject(1).BetaMaps);
                else
                    as = diff([bc.XStart, bc.YStart, bc.ZStart; ...
                        bc.XEnd, bc.YEnd, bc.ZEnd]) ./ bc.Resolution;
                end
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xff:InvalidObject', ...
                'Missing corresponding BetaMaps array.' ...
            );
        end
        try
            ys = as(1:3);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xff:InvalidObject', ...
                'Invalid BetaMaps array size.' ...
            );
        end

    % HDR
    case {'hdr'}
        try
            if any(bc.ImgDim.DataType == [128, 2304])
                as = size(bc.VoxelDataRGBA);
            else
                as = size(bc.VoxelData);
            end
            ys = as(1:3);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xff:InvalidObject', ...
                'Invalid VoxelData array.' ...
            );
        end

    % HEAD
    case {'head'}
        if ~isempty(bc.Brick) && ...
           ~isempty(bc.Brick(1).Data)
            as = size(bc.Brick(1).Data);
        else
            as = bc.DataDimensions;
        end
        try
            ys = as(1:3);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            error( ...
                'xff:InvalidObject', ...
                'Bad Data and/or DataDimensions in HEAD object.' ...
            );
        end

    % MAP
    case {'map'}

        % initialize data
        ys = [0, 0, numel(bc.Map)];
        if ys(3) > 0
            as = size(bc.Map(1).Data);
            ys(1:2) = as(1:2);
        end

    % MSK
    case {'msk'}
        ys = size(bc.Mask);
        if numel(ys) > 3
            ys(4:end) = [];
        end

    % NLF
    case {'nlf'}

        % only valid for 3D data
        if isempty(regexpi(bc.DimMeaning, 'xyz'))
            ys = [];
            return;
        end

        % get size over xyz
        xd = find(bc.DimMeaning == 'x');
        ys = bc.Size(xd:xd+2);

    % VDW
    case {'vdw'}
        as = size(bc.VDWData);
        if numel(as) ~= 4 || ...
            any(as(2:4) == 0)
            as = diff([0, bc.XStart, bc.YStart, bc.ZStart; ...
                0, bc.XEnd, bc.YEnd, bc.ZEnd]) ./ bc.Resolution;
        end
        ys = as(2:4);

    % VMP
    case {'vmp'}
        if ~isempty(bc.Map) && ...
           ~isempty(bc.Map(1).VMPData) && ...
            ndims(bc.Map(1).VMPData) == 3
            ys = size(bc.Map(1).VMPData);
        else
            ys = diff([bc.XStart, bc.YStart, bc.ZStart; ...
                bc.XEnd, bc.YEnd, bc.ZEnd]) ./ bc.Resolution;
        end

    % VMR
    case {'vmr'}
        ys = size(bc.VMRData);

    % VTC
    case {'vtc'}
        as = size(bc.VTCData);
        if numel(as) ~= 4 || ...
            any(as(2:4) == 0)
            as = diff([0, bc.XStart, bc.YStart, bc.ZStart; ...
                0, bc.XEnd, bc.YEnd, bc.ZEnd]) ./ bc.Resolution;
        end
        ys = as(2:4);
end
