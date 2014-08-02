function smp = aft_CreateSMP(hfile, srf, opts)
% AFT::CreateSMP  - sample SMPs from the maps in a VMP
%
% FORMAT:       smp = obj.CreateSMP(srf, opts)
%
% Input fields:
%
%       srf         required surface file
%       opts        1x1 struct with optional fields
%        .interp    method ('nearest', {'linear'}, 'cubic', 'lanczos3')
%        .ipfrom    interpolate from VC + n * normal vector, default: -3
%        .ipstep    interpolation stepsize, default: 1 (in normal vectors)
%        .ipto      interpolate to VC + n * normal vector, default: 1
%        .mapsel    map selection, default: all maps in VMP
%        .method    method to get value ('max', {'mean'}, 'median', 'min')
%        .recalcn   boolean, recalc normals before sampling, default: false
%
% Output fields:
%
%       smp         SMP object with as many maps as selected
%
% TYPES: CMP, HEAD, HDR, VMP
%
% Notes: results slightly differ from BV's results (sampling method)
%
%        VC + n * normal vector := VertexCoordinate + n * VertexNormal

% Version:  v0.9d
% Build:    14050317
% Date:     May-03 2014, 5:11 PM EST
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

% check arguments
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, {'cmp', 'head', 'hdr', 'vmp'}) || ...
    numel(srf) ~= 1 || ...
   ~xffisobject(srf, true, 'srf')
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
sc = xffgetscont(hfile.L);
bc = sc.C;
ftype = lower(sc.S.Extensions{1});
mnames = aft_MapNames(hfile);
srfs = xffgetscont(srf.L);
srfc = srfs.C;
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'interp') || ...
   ~ischar(opts.interp) || ...
   ~any(strcmpi(opts.interp(:)', ...
        {'cubic', 'lanczos3', 'linear', 'nearest'}))
    opts.interp = 'linear';
else
    opts.interp = lower(opts.interp(:))';
end
if ~isfield(opts, 'ipfrom') || ...
   ~isa(opts.ipfrom, 'double') || ...
    numel(opts.ipfrom) ~= 1 || ...
    isnan(opts.ipfrom) || ...
    opts.ipfrom < -10 || ...
    opts.ipfrom > 10
    opts.ipfrom = -3;
end
if ~isfield(opts, 'ipstep') || ...
   ~isa(opts.ipstep, 'double') || ...
    numel(opts.ipstep) ~= 1 || ...
    isnan(opts.ipstep) || ...
    opts.ipstep <= 0 || ...
    opts.ipstep > 10
    opts.ipstep = 1;
end
if ~isfield(opts, 'ipto') || ...
   ~isa(opts.ipto, 'double') || ...
    numel(opts.ipto) ~= 1 || ...
    isnan(opts.ipto) || ...
    opts.ipto < opts.ipfrom || ...
    opts.ipto > 10
    opts.ipto = 1;
end
if ~isfield(opts, 'mapsel') || ...
   ~isa(opts.mapsel, 'double') || ...
    any(isinf(opts.mapsel(:)) | isnan(opts.mapsel(:)) | ...
        opts.mapsel(:) ~= fix(opts.mapsel(:)) | ...
        opts.mapsel(:) < 1 | opts.mapsel(:) > numel(mnames))
    opts.mapsel = 1:numel(mnames);
else
    opts.mapsel = opts.mapsel(:)';
end
if ~isfield(opts, 'method') || ...
   ~ischar(opts.method) || ...
   ~any(strcmpi(opts.method(:)', ...
        {'max', 'mean', 'median', 'min'}))
    opts.method = 'mean';
else
    opts.method = lower(opts.method(:))';
end
if ~isfield(opts, 'recalcn') || ...
   ~islogical(opts.recalcn) || ...
    numel(opts.recalcn) ~= 1
    opts.recalcn = false;
end
if opts.recalcn
    srf_RecalcNormals(srf);
    srfc = bqvxfile_getcont(srf.L);
end
if any(strcmp(ftype, {'cmp', 'vmp'}))
    vmpres  = bc.Resolution;
elseif strcmp(ftype, 'hdr')

    % reject complex datatypes
    if any(bc.ImgDim.DataType == [32, 128, 1792, 2048, 2304])
        error( ...
            'xff:Unsupported', ...
            'SMP sampling not supported for complex datatypes.' ...
        );
    end

    % get coordinate frame
    cframe = hdr_CoordinateFrame(hfile);
    vmptrf = inv(cframe.Trf);
else
    cframe = head_CoordinateFrame(hfile);
    vmptrf = inv(cframe.Trf);
end
ipsamp  = opts.ipfrom:opts.ipstep:opts.ipto;
ipsnum  = numel(ipsamp);
nummaps = numel(opts.mapsel);

% get coordinates and normals
crd = srfc.VertexCoordinate;
nrm = srfc.VertexNormal;
numv = size(crd, 1);

% create output
smp = xff('new:smp');
smpc = xffgetcont(smp.L);
smpc.NrOfVertices = numv;
smpc.NrOfMaps = nummaps;
smpc.NameOfOriginalSRF = srfs.F;
smpc.Map.UseValuesAboveThresh = 1;
if nummaps > 1
    smpc.Map(2:nummaps) = smpc.Map;
end

% compute coordinate for CMP/VMP
if any(strcmp(ftype, {'cmp', 'vmp'}))

    % subtract XStart, YStart, ZStart
    crd = 1 + (1 / vmpres) .* [ ...
        crd(:, 1) - bc.XStart, ...
        crd(:, 2) - bc.YStart, ...
        crd(:, 3) - bc.ZStart];
    nrm = (1 / vmpres) .* nrm;

% for HDR/HEAD
else

    % use transformation matrix (also on normals)
    crd = srfc.MeshCenter(ones(numv, 1), [3, 1, 2]) - crd(:, [3, 1, 2]);
    nrm = -nrm(:, [3, 1, 2]);
    crd(:, 4) = 1;
    crd = crd * vmptrf';
    crd(:, 4) = [];
    nrm = nrm * vmptrf(1:3, 1:3)';
end

% iterate over maps
for mc = 1:nummaps

    % depending on type
    switch (ftype)

        % CMP/VMP
        case {'cmp', 'vmp'}

            % get source map (settings)
            srcmap = bc.Map(opts.mapsel(mc));

        % HDR/HEAD
        case {'hdr', 'head'}

            % get source map (settings)
            srcmap = bc.RunTimeVars.Map(opts.mapsel(mc));
    end

    % get values with unified method
    [mapval, trfplus, snmat] = aft_GetVolume(hfile, opts.mapsel(mc));
    mapval = double(mapval);

    % prepare interpolation array
    ipvals = zeros(numv, ipsnum);

    % fill some SMP fields
    smpc.Map(mc).Type = srcmap.Type;
    smpc.Map(mc).LowerThreshold = srcmap.LowerThreshold;
    smpc.Map(mc).UpperThreshold = srcmap.UpperThreshold;
    smpc.Map(mc).UseValuesAboveThresh = srcmap.UseValuesAboveThresh;
    smpc.Map(mc).RGBLowerThreshPos = srcmap.RGBLowerThreshPos;
    smpc.Map(mc).RGBUpperThreshPos = srcmap.RGBUpperThreshPos;
    smpc.Map(mc).RGBLowerThreshNeg = srcmap.RGBLowerThreshNeg;
    smpc.Map(mc).RGBUpperThreshNeg = srcmap.RGBUpperThreshNeg;
    smpc.Map(mc).UseRGBColor = srcmap.UseRGBColor;
    smpc.Map(mc).TransColorFactor = srcmap.TransColorFactor;
    smpc.Map(mc).DF1 = srcmap.DF1;
    smpc.Map(mc).DF2 = srcmap.DF2;
    smpc.Map(mc).BonferroniValue = min(numv, srcmap.BonferroniValue);
    smpc.Map(mc).Name = mnames{opts.mapsel(mc)};

    % only simple approach for non-CC maps
    if srcmap.Type ~= 3

        % interpolate according to method
        for ipc = 1:ipsnum
            nf = ipsamp(ipc);
            ipvals(:, ipc) = flexinterpn_method(mapval, ...
                [crd(:, 1) + nf * nrm(:, 1), ...
                 crd(:, 2) + nf * nrm(:, 2), ...
                 crd(:, 3) + nf * nrm(:, 3)], 0, opts.interp);
        end

    % CC maps are dealt with more complicated
    else

        % fill some
        smpc.Map(mc).NrOfLags = srcmap.NrOfLags;
        smpc.Map(mc).MinLag = srcmap.MinLag;
        smpc.Map(mc).MaxLag = srcmap.MaxLag;
        smpc.Map(mc).CCOverlay = srcmap.CCOverlay;

        % extract lags
        maplag = max(0, floor(mapval));
        mapval = max(0, mapval - maplag);

        % prepate additional array
        iplags = zeros(numv, ipsnum);

        % interpolate according to method
        for ipc = 1:ipsnum
            nf = ipsamp(ipc);
            ipvals(:, ipc) = max(0, min(1, flexinterpn_method(mapval, ...
                [crd(:, 1) + nf * nrm(:, 1), ...
                 crd(:, 2) + nf * nrm(:, 2), ...
                 crd(:, 3) + nf * nrm(:, 3)], 0, opts.interp)));
            iplags(:, ipc) = max(0, min(srcmap.MaxLag, round(flexinterpn_method( ...
                maplag, ...
                [crd(:, 1) + nf * nrm(:, 1), ...
                 crd(:, 2) + nf * nrm(:, 2), ...
                 crd(:, 3) + nf * nrm(:, 3)], 0, opts.interp))));
        end
    end

    % what summary method
    switch opts.method

        % max value
        case {'max'}
            mapsgn = sign(min(ipvals, [], 2) + max(ipvals, [], 2));
            smpc.Map(mc).SMPData = mapsgn .* max(abs(ipvals), [], 2);
            if srcmap.Type == 3
                smpc.Map(mc).SMPData = smpc.Map(mc).SMPData + ...
                    1000 * min(iplags, [], 2);
            end
            smpc.Map(mc).SMPData = single(smpc.Map(mc).SMPData);

        % mean value
        case {'mean'}
            if srcmap.Type ~= 3
                smpc.Map(mc).SMPData = single(mean(ipvals, 2));
            else
                smpc.Map(mc).SMPData = single(mean(ipvals, 2)) + ...
                    1000 * single(round(mean(iplags, 2)));
            end

        % median
        case {'median'}
            if srcmap.Type ~= 3
                smpc.Map(mc).SMPData = single(median(ipvals, 2));
             else
                smpc.Map(mc).SMPData = single(median(ipvals, 2)) + ...
                    1000 * single(median(iplags, 2));
            end

        % min value
        case {'min'}
            mapsgn = sign(ipvals(:, 1));
            difsgn = (sign(min(ipvals, [], 2)) ~= sign(max(ipvals, [], 2)));
            smpc.Map(mc).SMPData = mapsgn .* min(abs(ipvals), [], 2);
            if srcmap.Type == 3
                smpc.Map(mc).SMPData = smpc.Map(mc).SMPData + ...
                    1000 * min(iplags, [], 2);
            end
            smpc.Map(mc).SMPData = single(smpc.Map(mc).SMPData);
            smpc.Map(mc).SMPData(difsgn) = 0;
    end
end

% put content in new object
xffsetcont(smp.L, smpc);
