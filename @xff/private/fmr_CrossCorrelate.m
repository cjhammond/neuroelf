function ccmap = fmr_CrossCorrelate(hfile, hfile2, opts)
% FMR::CrossCorrelate  - create CC map of two FMRs
%
% FORMAT:       ccmap = fmr.CrossCorrelate(fmr2 [, opts])
%
% Input fields:
%
%       fmr2        second FMR (must match in dims and layout)
%       opts        options settings
%        .reverse   reverse time courses of second VTC
%
% Output fields:
%
%       ccmap       cross-correlation r-VMP
%
% Note: the toolbox internal cov_nd function is used which gives
%       slightly different r values than corrcoef.

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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

% argument check
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'fmr') || ...
    numel(hfile2) ~= 1 || ...
   ~xffisobject(hfile2, true, 'fmr')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
fmr1s = xffgetscont(hfile.L);
fmr2s = xffgetscont(hfile2.L);
fmr1f = fmr1s.F;
fmr2f = fmr2s.F;
if isempty(fmr1f)
    fmr1f = '<Unknown 1>';
end
if isempty(fmr2f)
    fmr2f = '<Unknown 2>';
end
fmr1 = fmr1s.C;
fmr2 = fmr2s.C;
if fmr1.ResolutionX ~= fmr2.ResolutionX || ...
    fmr1.ResolutionY ~= fmr2.ResolutionY || ...
    fmr1.NrOfSlices ~= fmr2.NrOfSlices || ...
    fmr1.NrOfVolumes ~= fmr2.NrOfVolumes
    error( ...
        'xff:BadArgument', ...
        'Dimension/Layout mismatch.' ...
    );
end
if fmr1.NrOfVolumes < 3
    error( ...
        'xff:BadArgument', ...
        'FMRs must have at least 3 volumes each.' ...
    );
end
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'reverse') || ...
    isempty(opts.reverse) || ...
   ~islogical(opts.reverse)
    opts.reverse = false;
else
    opts.reverse = opts.reverse(1);
end
if opts.reverse
    revstr = ' TC-reversed';
else
    revstr = '';
end

% create map
df1 = fmr1.NrOfVolumes - 2;
ccmap = bless(xff('new:map'), 1);
map = xffgetcont(ccmap.L);
map.Type = 1;
map.NrOfSlices = fmr1.NrOfSlices;
map.CombinedTypeSlices = 10000 * map.Type + map.NrOfSlices;
map.DimX = fmr1.ResolutionX;
map.DimY = fmr1.ResolutionY;
map.ClusterSize = 1;
map.LowerThreshold = correlinvtstat(-sdist('tinv', 0.005, df1), fmr1.NrOfVolumes);
map.UpperThreshold = correlinvtstat(-sdist('tinv', 0.0001, df1), fmr1.NrOfVolumes);
map.DF1 = df1;
map.DF2 = 0;
map.NameOfSDMFile = sprintf('<CC %s <-> %s%s>', fmr1f, fmr2f, revstr);
map.Map = struct('Number', 1, 'Data', single(zeros(fmr1.ResolutionY, fmr1.ResolutionX)));
map.Map = map.Map(1, ones(1, fmr1.NrOfSlices));

% iterate over last spatial dim
for z = 1:fmr1.NrOfSlices

    % get components for cov_nd
    if fmr1.DataStorageFormat < 2
        r1 = double(fmr1.Slice(z).STCData(:, :, :));
    else
        r1 = double(fmr1.Slice.STCData(:, :, :, z));
    end
    if fmr2.DataStorageFormat < 2
        r2 = double(fmr2.Slice(z).STCData(:, :, :));
    else
        r2 = double(fmr2.Slice.STCData(:, :, :, z));
    end
    if opts.reverse
        r2 = r2(:, :, end:-1:1);
    end

    % compute r value
    [cc, cr] = cov_nd(r1, r2);
    cr(isinf(cr) | isnan(cr)) = 0;
    cr = sign(cr) .* (1 - abs(cr));
    cr(cr == 1) = 0;
    map.Map(z).Number = z;
    map.Map(z).Data = single(cr);
end

% set data to VMP
xffsetcont(ccmap.L, map);
