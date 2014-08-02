function vtc = vmr_CreateVTC(hfile, fmr, afs, vtcfile, res, meth, bbox, dt)
% VMR::CreateVTC  - mimick BV's VTC creation
%
% FORMAT:       [vtc] = vmr.CreateVTC(fmr, afs, vtcfile, res, meth, bbox, dt);
%
% Input fields:
%
%       fmr         FMR object to create VTC from
%       afs         cell array: alignment file objects ({ia, fa, acpc, tal})
%       vtcfile     filename of output VTC
%       res         resolution (default: 3)
%       meth        interpolation, 'cubic', 'lanczos3', {'linear'}, 'nearest'
%       bbox        2x3 bounding box (optional, default: small TAL box)
%       dt          datatype override (default: uint16, FV 2)
%
% Output fields:
%
%       vtc         VTC object

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

% global settings
global xffconf;

% check arguments
if nargin < 4 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vmr') || ...
    numel(fmr) ~= 1 || ...
   ~xffisobject(fmr, true, 'fmr') || ...
   ~iscell(afs) || ...
    isempty(afs) || ...
    numel(afs{1}) ~= 1 || ...
   ~xffisobject(afs{1}, true, 'trf') || ...
   ~ischar(vtcfile) || ...
    isempty(vtcfile)
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
vtcfile = vtcfile(:)';
if nargin < 5 || ...
   ~isa(res, 'double') || ...
    numel(res) ~= 1 || ...
   ~any([1, 2, 3] == res)
    res = 3;
end
if nargin < 6 || ...
   ~ischar(meth) || ...
    isempty(meth) || ...
   ~any(strcmpi(meth(:)', {'cubic', 'lanczos3', 'linear', 'nearest'}))
    meth = 'linear';
else
    meth = lower(meth(:)');
end
if nargin < 7 || ...
   ~isa(bbox, 'double') || ...
    numel(size(bbox)) ~= 2 || ...
    any(size(bbox) ~= [2, 3]) || ...
    any(isinf(bbox(:)) | isnan(bbox(:)) | bbox(:) < 0 | bbox(:) > 255 | ...
        bbox(:) ~= fix(bbox(:))) || ...
    any((bbox(2, :) - res) <= bbox(1, :))
    bbox = [59, 57, 52; 197, 231, 172];
end
bbox(2, :) = bbox(1, :) + res .* round(diff(bbox) ./ res);
if nargin < 8 || ...
   ~isa(dt, 'double') || ...
    numel(dt) ~= 1 || ...
    isinf(dt) || ...
    isnan(dt) || ...
   ~any(dt == [1, 2])
    dt = xffconf.settings.DataTypes.VTC;
end

% generate target coordinate list and data field
c = {bbox(1, 1):res:(bbox(2, 1) - 1), ...
     bbox(1, 2):res:(bbox(2, 2) - 1), ...
     bbox(1, 3):res:(bbox(2, 3) - 1)};
xr = numel(c{1});
yr = numel(c{2});
zr = numel(c{3});

% check alignment files
hasia = 0;
for ac = numel(afs):-1:1
    if numel(afs{ac}) == 1 && ...
        xffisobject(afs{ac}, true, 'trf')
        trfbc = xffgetcont(afs{ac}.L);
        if hasia > 0
            afs(hasia) = [];
        end
        if trfbc.TransformationType == 1 && ...
            trfbc.AlignmentStep == 1
            hasia = ac;
        end
    elseif numel(afs{ac}) ~= 1 || ...
       ~xffisobject(afs{ac}, true, 'tal')
        error( ...
            'xff:BadArgument', ...
            'Invalid alignment file object list.' ...
        );
    end
end
if hasia == 0
    afs = [{initialalignment(hfile, fmr)}, afs(:)'];
end

% generate sample output with target coordinates
fmrsc = xffgetscont(fmr.L);
fmrbc = fmrsc.C;
nslc = fmrbc.NrOfSlices;
smpd = uint16(0);
smpd(fmrbc.ResolutionX, fmrbc.ResolutionY, nslc) = 0;

% try sampling
try
    [y, sc] = samplefmrspace(smpd, c, fmr, afs, meth);
catch ne_eo;
    rethrow(ne_eo);
end

% generate VTC
nvol = fmrbc.NrOfVolumes;
vtc = xff('new:vtc');
vtcc = xffgetcont(vtc.L);
vtcc.NameOfSourceFMR = fmrsc.F;
vtcc.NameOfLinkedPRT = fmrbc.ProtocolFile;
vtcc.NrOfVolumes = nvol;
vtcc.Resolution = res;
vtcc.XStart = bbox(1, 2);
vtcc.XEnd = bbox(2, 2);
vtcc.YStart = bbox(1, 3);
vtcc.YEnd = bbox(2, 3);
vtcc.ZStart = bbox(1, 1);
vtcc.ZEnd = bbox(2, 1);
vtcc.TR = fmrbc.TR;
vtcc.SegmentSize = fmrbc.SegmentSize;
vtcc.SegmentOffset = fmrbc.SegmentOffset;
if dt == 1
    vtcc.VTCData = uint16(0);
else
    vtcc.FileVersion = 3;
    vtcc.VTCData = single(0);
end
vtcc.VTCData(nvol, yr, zr, xr) = vtcc.VTCData(1);

% test saving
try
    xffsetcont(vtc.L, vtcc);
    vtc = aft_SaveAs(vtc, vtcfile);
    vtcc = xffgetcont(vtc.L);
catch ne_eo;
    fclose('all');
    xffclear(vtc.L);
    rethrow(ne_eo);
end

% make sure FMR data is loaded
fmr_LoadSTC(fmr);
fmrbc = xffgetcont(fmr.L);

% iterate over volumes
vr = [1, xr, yr, zr];
for vc = 1:nvol

    % FMR access depends on fileversion of FMR
    if fmrbc.FileVersion < 5 || ...
        fmrbc.DataStorageFormat == 1
        for ssc = 1:nslc
            smpd(:, :, ssc) = squeeze(fmrbc.Slice(ssc).STCData(:, :, ssc));
        end
    else
        switch (fmrbc.DataStorageFormat)
            case {2}
                smpd = squeeze(fmrbc.Slice.STCData(:, :, vc, :));
            otherwise
                xffclear(vtc.L);
                error( ...
                    'xff:NotYetImplemented', ...
                    'DataStorageFormat of FMR not yet supported.' ...
                );
        end
    end

    % sample at given coords
    if dt == 1
        vtcc.VTCData(vc, :, :, :) = permute(reshape(uint16(round( ...
            flexinterpn_method(smpd, sc, 0, meth))), vr), [1, 3, 4, 2]);
    else
        vtcc.VTCData(vc, :, :, :) = permute(reshape( ...
            flexinterpn_method(smpd, sc, 0, meth), vr), [1, 3, 4, 2]);
    end
end

% save VTC again
xffsetcont(vtc.L, vtcc);
aft_Save(vtc);
