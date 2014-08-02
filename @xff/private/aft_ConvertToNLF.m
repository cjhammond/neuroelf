function hfile = aft_ConvertToNLF(hfile, opts)
% AFT::ConvertToNLF  - convert an object to NLF (if appropriate)
%
% FORMAT:       obj.ConvertToNLF([opts]);
%
% Input fields:
%
%       opts        optional settings
%        .nodata    flag, if data is transio, use reference (default: false)
%        .vmr16     flag, choose VMRData16 (if available, default: false)
%
% No output fields.
%
% TYPES: GLM, SMP, SRF, VMP, VMR, VTC

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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

% check arguments
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, {'glm', 'smp', 'srf', 'vmp', 'vmr', 'vtc'})
    error( ...
        'xff:BadArguments', ...
        'This type of object does not support To-NLF-conversion.' ...
    );
end

% options
if nargin < 2 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'nodata') || ...
   ~islogical(opts.nodata) || ...
    numel(opts.nodata) ~= 1
    opts.nodata = false;
end
if ~isfield(opts, 'vmr16') || ...
   ~islogical(opts.vmr16) || ...
    numel(opts.vmr16) ~= 1
    opts.vmr16 = false;
end

% get content and object type
sc = xffgetscont(hfile.L);
bc = sc.C;
ext = lower(sc.S.Extensions{1});

% get filename particles
[hfdir, hffile, hfext] = fileparts(sc.F);
if isempty(hffile)
    hffile = 'unsaved';
end
if isempty(hfext)
    hfext = sprintf('.%s', ext);
end

% create and get NLF content, then destroy object
nlf = xff('new:nlf');
nsc = xffgetscont(nlf.L);
xffclear(nlf.L);

% depending on extension
switch (ext)

    % for VMRs
    case {'vmr'}

        % get bounding box
        bbox = aft_BoundingBox(hfile);

        % ensure intent code
        nsc.C.Intent = 'a3d';
        nsc.C.NrOfDims = 3;
        nsc.C.DimMeaning = 'xyz.....';
        nsc.C.DimUnit = 'mmm.....';

        % put data into appropriate fields
        if opts.vmr16 && ...
           ~isempty(bc.VMRData16)
            nsc.C.Data = bc.VMRData16;
            nsc.C.DataType = mltype('uint16');
        else
            nsc.C.Data = bc.VMRData;
            nsc.C.DataType = mltype('uint8');
            nsc.C.A3D.NrOfSVCs = 30;
            nsc.C.A3D.SVColors = ...
                [226:255; ...
                 255 .* ones(1, 10), zeros(1, 10), 255 .* ones(1, 10); ...
                 75:20:255, 75:20:255, 255 .* ones(1, 10); ...
                 zeros(1, 10), 255:-20:75, 255 .* ones(1, 10)]';
        end

        % some more settings
        nsc.C.Size = [size(nsc.C.Data), ones(1, 5)];
        nsc.C.Resolution = [bc.VoxResX, bc.VoxResY, bc.VoxResZ, ones(1, 5)];
        nsc.C.ScalingSlope = 1;
        nsc.C.ScalingIntercept = 0;
        nsc.C.GlobalTransform = bbox.QuatB2T;
        nsc.C.Name = [hffile, hfext];
        nsc.C.A3D.NrOfTransforms = numel(bc.Trf);
        for tc = 1:numel(bc.Trf)
            nsc.C.A3D.Transform(tc).Type = ...
                32 + bc.Trf(tc).TypeOfSpatialTransformation;
            nsc.C.A3D.Transform(tc).NrOfValues = ...
                numel(bc.Trf(tc).TransformationValues);
            nsc.C.A3D.Transform(tc).Values = ...
                bc.Trf(tc).TransformationValues(:);
        end
end

% for transio data
if istransio(nsc.C.Data)

    % keep reference data
    if opts.nodata

        % update filename, etc.
        nsc.C.DataType = mltype(datatype(nsc.C.Data));
        nsc.C.DataExternal = 1;
        nsc.C.DataExternalEndian = littleendian(nsc.C.Data);
        nsc.C.DataFile = filename(nsc.C.Data);
        nsc.C.DataOffset = offset(nsc.C.Data);

    % resolve data
    else
        nsc.C.Data = resolve(nsc.C.Data);
    end
end

% put into global position of current hfile, replacing original object
nsc.C.SourceFilename = sc.F;
nsc.C.RunTimeVars = bc.RunTimeVars;
nsc.H = sc.H;
nsc.L = sc.L;
nsc.U = sc.U;

% this effectively changes the type (also removing the filename)
xffsetscont(hfile.L, nsc);
