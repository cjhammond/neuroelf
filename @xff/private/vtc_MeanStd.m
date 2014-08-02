function hfile2 = vtc_MeanStd(hfile, vsel)
% VTC::MeanStd  - calculate mean/std maps over (some) volumes
%
% FORMAT:       msvmp = vtc.MeanStd([vsel])
%
% Input fields:
%
%       vsel        volume selection, default all volumes
%                   can also be a cell array of selections
%
% Output fields:
%
%       msvmp       VMP with mean and PSC total signal variance image(s)

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
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vtc')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get object reference
bc = xffgetcont(hfile.L);
nv = bc.NrOfVolumes;
vsz = size(bc.VTCData);

% check vsel
if nargin < 2 || ...
   (~isa(vsel, 'double') && ...
    ~iscell(vsel)) || ...
    isempty(vsel)
    vsel = 1:nv;
end
if isa(vsel, 'double')
    vsel = {vsel};
end
vsel = vsel(:)';
for cc = 1:numel(vsel)
    if ~isa(vsel{cc}, 'double') || ...
        isempty(vsel{cc}) || ...
        any(isinf(vsel{cc}(:)) | isnan(vsel{cc}(:)) | vsel{cc}(:) < 1 | ...
            vsel{cc}(:) > nv | vsel{cc}(:) ~= round(vsel{cc}(:))) || ...
        numel(vsel{cc}(:)) ~= numel(unique(vsel{cc}(:)))
        error( ...
            'xff:BadArgument', ...
            'Invalid volume selection.' ...
        );
    end
    vsel{cc} = unique(vsel{cc}(:)');
end

% create output files
bbox = aft_BoundingBox(hfile);
hfile2 = newnatresvmp(bbox.BBox, bc.Resolution);
bc2 = xffgetcont(hfile2.L);
bc2.Map.Type = 1;
bc2.Map.DF2 = 0;
bc2.Map(2:2 * numel(vsel)) = bc2.Map(1);

% get timecourse as single
tc = single(bc.VTCData(:, :, :, :));

% generate mean and std maps
for cc = 1:numel(vsel)
    mc = 2 * cc - 1;
    bc2.Map(mc).Name = sprintf('mean(vol selection %d)', cc);
    mapv = squeeze(mean(tc(vsel{cc}, :, :, :)));
    mapv(isnan(mapv) | isinf(mapv)) = 0;
    mval = mean(mapv(mapv ~= 0));
    mstd = std(mapv(mapv ~= 0));
    bc2.Map(mc).LowerThreshold = double(max(eps, mval - 0.5 * mstd));
    bc2.Map(mc).UpperThreshold = double(mval + 1.5 * mstd);
    bc2.Map(mc).DF1 = numel(vsel{cc}) - 1;
    bc2.Map(mc).VMPData = mapv;
    mc = mc + 1;
    bc2.Map(mc).Name = sprintf('std(vol selection %d)', cc);
    mapv(mapv == 0) = Inf;
    if mval > 2
        mapv = (squeeze(std(tc(vsel{cc}, :, :, :))) ./ mapv) .* ...
            (mapv > bc2.Map(mc - 1).LowerThreshold);
    else
        mapv = squeeze(std(tc(vsel{cc}, :, :, :))) .* (mapv ~= 0);
    end
    mapv(isnan(mapv) | isinf(mapv)) = 0;
    mval = mean(mapv(mapv ~= 0));
    mstd = std(mapv(mapv ~= 0));
    bc2.Map(mc).LowerThreshold = ...
        double(max(sqrt(1 / (2 * vsz(1))), 100 * (mval - 2 * mstd)));
    bc2.Map(mc).UpperThreshold = double(100 * (mval + 3 * mstd));
    bc2.Map(mc).DF1 = numel(vsel{cc}) - 1;
    bc2.Map(mc).VMPData = 100 * mapv;
end
bc2.NrOfMaps = mc;

% put into object
xffsetcont(hfile2.L, bc2);
