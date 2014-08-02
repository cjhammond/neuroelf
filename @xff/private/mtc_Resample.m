function nhfile = mtc_Resample(hfile, ifunc, ts)
% MTC::Resample  - temporally resample an MTC
%
% FORMAT:       newmtc = mtc.Resample(ifunc, ts)
%
% Input fields:
%
%       ifunc       interpolation function,
%                   'linear', 'cubic', 'nearest', 'lanczos3'
%       ts          temporal sampling points (in MS!)
%
% Output fields:
%
%       newmtc      MTC with resampled timepoints

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
   ~xffisobject(hfile, true, 'mtc') || ...
   ~ischar(ifunc) || ...
   ~any(strcmpi(ifunc(:)', {'cubic', 'lanczos3', 'linear', 'nearest'})) || ...
   ~isa(ts, 'double') || ...
    isempty(ts) || ...
    length(ts) ~= numel(ts) || ...
    (numel(ts) > 2 && any(abs(diff(ts, 2) > 1))) || ...
    any(isinf(ts(:)) | isnan(ts(:)))
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
ifunc = lower(ifunc(:)');
bc = xffgetcont(hfile.L);
nv = size(bc.MTCData, 1);
np = size(bc.MTCData, 2);
if any(ts < 0 | ts > (bc.TR * (nv - 0.5)))
    warning( ...
        'xff:BadArgument', ...
        'Sampling points out of bounds.' ...
    );
end

% get newTR
if numel(ts) > 1
    nTR = round(mean(diff(ts(:))));
else
    nTR = bc.TR;
end
TRfac = nTR / bc.TR;
ts = 1 + ts(:) / bc.TR;
sts = min(np, 4096);
tss = [Inf, Inf; ts(1), 1; mean(diff(ts)), 1; ts(end), np];

% try progress bar
try
    pbar = xprogress;
    xprogress(pbar, 'setposition', [80, 200, 640, 36]);
    xprogress(pbar, 'settitle', 'Resampling MTC...');
    xprogress(pbar, 0, 'Preparing structures...', 'visible', 0, 10);
    pvx = 9 / np;
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    pbar = [];
end

% create data arrays (old in single AND new in uint16 must fit into mem!)
nMTC = single(0);
try
    oMTC = bc.MTCData(:, :);
    nMTC(numel(ts), np) = nMTC(1);
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
nhfile = xff('new:mtc');
ncfile = xffgetcont(nhfile.L);
ncfile.NrOfVertices = size(bc.MTCData, 2);
ncfile.NrOfTimePoints = numel(ts);
ncfile.SourceVTCFile = bc.SourceVTCFile;
ncfile.LinkedPRTFile = bc.LinkedPRTFile;
ncfile.HemodynamicDelay = bc.HemodynamicDelay;
ncfile.TR = nTR;
ncfile.HRFDelta = bc.HRFDelta;
ncfile.HRFTau = bc.HRFTau;
ncfile.ProtocolSegmentSize = fix(bc.ProtocolSegmentSize * TRfac);
ncfile.ProtocolSegmentOffset = fix(bc.ProtocolSegmentOffset * TRfac);
ncfile.MTCData = single([]);

% loop over points with stepsize
if ~isempty(pbar)
    xprogress(pbar, 1, sprintf('Resampling with %s interpolation...', ifunc));
end
for sc = 1:sts:np
    tss(2, 2) = sc;
    tss(4, 2) = min(np, sc + sts - 1);
    nMTC(:, tss(2, 2):tss(4, 2)) = ...
        single(flexinterpn_method(oMTC, tss, 0, ifunc));
    if ~isempty(pbar)
        xprogress(pbar, 1 + sc * pvx);
    end
end

% set final field
ncfile.MTCData = nMTC;
clear oMTC;

% but content into array
xffsetcont(nhfile.L, ncfile);

% remove bar
if ~isempty(pbar)
    closebar(pbar);
end
