function nhfile = vtc_Resample(hfile, ifunc, ts, xs, ys, zs)
% VTC::Resample  - resample a VTC
%
% FORMAT:       newvtc = vtc.Resample(ifunc, ts, [xs, ys, zs])
%
% Input fields:
%
%       ifunc       interpolation function,
%                   'linear', 'cubic', 'nearest'
%       ts          temporal sampling points (in MS!)
%       xs, ys, zs  spatial sampling points (BV coords, all given or none)

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
   ~xffisobject(hfile, true, 'vtc') || ...
   ~ischar(ifunc) || ...
   ~any(strcmpi(ifunc(:)', {'linear', 'cubic', 'nearest'})) || ...
   ~isa(ts, 'double') || ...
    isempty(ts) || ...
    length(ts) ~= numel(ts) || ...
    (numel(ts) > 2 && any(abs(diff(ts, 2) > 1))) || ...
    any(isinf(ts(:)) | isnan(ts(:))) || ...
    (nargin > 5 && ( ...
     ~isa(xs, 'double') || ...
     ~isa(ys, 'double') || ...
     ~isa(zs, 'double') || ...
      length(xs) ~= numel(xs) || ...
      length(ys) ~= numel(ys) || ...
      length(zs) ~= numel(zs) || ...
      numel(xs) < 3 || ...
      numel(ys) < 3 || ...
      numel(zs) < 3 || ...
      any(xs < 0 | xs > 255) || ...
      any(ys < 0 | ys > 255) || ...
      any(zs < 0 | zs > 255) || ...
      any(diff(xs, 2)) || ...
      any(diff(ys, 2)) || ...
      any(diff(zs, 2)) || ...
      xs(1) ~= fix(xs(1)) || ...
      ys(1) ~= fix(ys(1)) || ...
      zs(1) ~= fix(zs(1)) || ...
      abs(xs(1) - xs(2)) ~= fix(abs(xs(1) - xs(2))) || ...
      abs(xs(1) - xs(2)) ~= fix(abs(ys(1) - ys(2))) || ...
      abs(xs(1) - xs(2)) ~= fix(abs(zs(1) - zs(2)))))
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
ifunc = lower(ifunc(:)');
bc = xffgetcont(hfile.L);
nv = size(bc.VTCData, 1);
if any(ts < 0 | ts > (bc.TR * (nv + 1)))
    warning( ...
        'xff:BadArgument', ...
        'Sampling points out of bounds.' ...
    );
end

% get current array size
oOffsetX = bc.XStart;
oOffsetY = bc.YStart;
oOffsetZ = bc.ZStart;
oDimX = size(bc.VTCData, 2);
oDimY = size(bc.VTCData, 3);
oDimZ = size(bc.VTCData, 4);
oRes = bc.Resolution;

% decide on spatial sampling points
if nargin < 6
    nOffsetX = oOffsetX;
    nOffsetY = oOffsetY;
    nOffsetZ = oOffsetZ;
    nRes = oRes;
    xs = 1:oDimX;
    ys = 1:oDimY;
    zs = 1:oDimZ;
else
    nOffsetX = min(xs(1), xs(end));
    nOffsetY = min(ys(1), ys(end));
    nOffsetZ = min(zs(1), zs(end));
    nRes = abs(xs(1) - xs(2));
    xs = 1 + (xs(:)' - oOffsetX) / oRes;
    ys = 1 + (ys(:)' - oOffsetY) / oRes;
    zs = 1 + (zs(:)' - oOffsetZ) / oRes;
end

% create sampling grid argument
txyz = [Inf, Inf, Inf, Inf; ...
    1, xs(1), ys(1), zs(1); ...
    1, [1, 1, 1] .* (xs(2) - xs(1)); ...
    1, xs(end), ys(end), zs(end)];

% get newTR
if numel(ts) > 1
    nTR = round(mean(diff(ts(:))));
else
    nTR = bc.TR;
end
TRfac = nTR / bc.TR;
ts = 1 + ts(:) / bc.TR;

% try progress bar
try
    pbar = xprogress;
    xprogress(pbar, 'setposition', [80, 200, 640, 36]);
    xprogress(pbar, 'settitle', 'Resampling VTC...');
    xprogress(pbar, 0, 'Scaling original VTC...', 'visible', 0, 10);
    pvx = 9 / numel(ts);
    pvc = 1;
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    pbar = [];
end

% create data arrays (old in single AND new in uint16 must fit into mem!)
try
    if bc.FileVersion < 3 || ...
        bc.DataType < 2
        nVTC = uint16(0);
        oVTC = single(bc.VTCData(:, :, :, :));
        mVTC = mean(oVTC);
        mVTC(mVTC == 0) = 1;
        oVTC = 10000 * (oVTC ./ repmat(mVTC, [nv, 1]));
        toui16 = true;
    else
        nVTC = single(0);
        oVTC = single(bc.VTCData(:, :, :, :));
        toui16 = false;
    end
    nVTC(numel(ts), numel(xs), numel(ys), numel(zs)) = nVTC(1);
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    error( ...
        'xff:OutOfMemory', ...
        'Out of memory (old and new VTC must fit in memory).' ...
    );
end

% create new VTC object
if ~isempty(pbar)
    xprogress(pbar, 0.5, 'Creating new object...');
end
nhfile = xff('new:vtc');
ncfile = xffgetcont(nhfile.L);
ncfile.FileVersion = bc.FileVersion;
ncfile.NameOfSourceFMR = bc.NameOfSourceFMR;
ncfile.NrOfLinkedPRTs = bc.NrOfLinkedPRTs;
ncfile.NameOfLinkedPRT = bc.NameOfLinkedPRT;
ncfile.DataType = bc.DataType;
ncfile.NrOfVolumes = numel(ts);
ncfile.Resolution = nRes;
ncfile.XStart = nOffsetX;
ncfile.XEnd = nOffsetX + nRes * numel(xs);
ncfile.YStart = nOffsetY;
ncfile.YEnd = nOffsetY + nRes * numel(ys);
ncfile.ZStart = nOffsetZ;
ncfile.ZEnd = nOffsetZ + nRes * numel(zs);
ncfile.TR = nTR;
ncfile.SegmentSize = fix(bc.SegmentSize * TRfac);
ncfile.SegmentOffset = fix(bc.SegmentOffset * TRfac);

% discarded volumes and temporal resam pling?
if ~isempty(bc.RunTimeVars.Discard) && ...
    TRfac ~= 1

    % create 0/1-vector
    dvols = zeros(size(bc.VTCData, 1), 1);
    dvols(bc.RunTimeVars.Discard) = 1;

    % resample
    dvols = flexinterpn_method(dvols, ts(:), 'linear');

    % and put as new discarded into RunTimeVars
    ncfile.RunTimeVars.Discard = find(dvols >= 0.5);
end

% loop over slices dims
if ~isempty(pbar)
    xprogress(pbar, 1, sprintf('Resampling with %s interpolation...', ifunc));
end
for tc = 1:numel(ts)
    txyz([2,4], 1) = ts(tc);
    if toui16
        nVTC(tc, :, :, :) = uint16(round(flexinterpn_method(oVTC, txyz, 0, ifunc)));
    else
        nVTC(tc, :, :, :) = flexinterpn_method(oVTC, txyz, 0, ifunc);
    end
    if ~isempty(pbar)
        xprogress(pbar, 1 + pvc * pvx);
        pvc = pvc + 1;
    end
end

% set final field
ncfile.VTCData = nVTC;
clear oVTC;

% but content into array
xffsetcont(nhfile.L, ncfile);

% remove bar
if ~isempty(pbar)
    closebar(pbar);
end
