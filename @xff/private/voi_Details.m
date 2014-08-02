function void = voi_Details(hfile, vmp, vmpnum)
% VOI::Details  - extract VOI details from a VMP
%
% FORMAT:       void = voi.Details(vmp [, vmpnum])
%
% Input fields:
%
%       vmp         VMP object
%       vmpnum      map number (default: 1)
%
% Output fields:
%
%       void        ROID object with ROI details

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
   ~xffisobject(hfile, true, 'voi') || ...
    numel(vmp) ~= 1 || ...
   ~xffisobject(vmp, true, 'vmp')
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
vmpc = xffgetcont(vmp.L);
if nargin < 3 || ...
   ~isa(vmpnum, 'double') || ...
   ~isreal(vmpnum) || ...
    numel(vmpnum) ~= 1 || ...
    isinf(vmpnum) || ...
    isnan(vmpnum) || ...
    vmpnum < 1 || ...
    vmpnum > numel(vmpc.Map)
    vmpnum = 1;
else
    vmpnum = fix(vmpnum);
end

% get coords
numvois = numel(bc.VOI);
voitype = bc.ReferenceSpace;
crdsnum = zeros(1, numvois);
coords = cell(numvois, 1);
for vc = 1:numvois
    coords{vc} = bc.VOI(vc).Voxels;
    crdsnum(vc) = size(coords{vc}, 1);
end

% total coords
crdssum = sum(crdsnum);
crdstat = zeros(crdssum, 5);
crdoffs = cumsum([1, crdsnum]);

% stat type
calcp = '';
df1 = vmpc.Map(vmpnum).DF1;
switch (vmpc.Map(vmpnum).Type)
    case {1}
        statype = sprintf('t(%d)', df1);
        calcp = 't';
        crdstat(:, end + 1) = 0;
    case {2}
        statype = sprintf('r(%d)', df1);
    otherwise
        statype = 'unsupported';
end

% get stats for each VOI
for vc = 1:numvois
    fromc = crdoffs(vc);
    toc = crdoffs(vc + 1) - 1;
    if strcmpi(voitype, 'tal')
        bcrd = bvcoordconv(coords{vc}, 'tal2bvi');
        crdstat(fromc:toc, 1:3) = bcrd(:, [3,1,2]);
    else
        crdstat(fromc:toc, 1:3) = coords{vc}(:, [3,1,2]);
    end
    crdstat(fromc:toc, 4) = vc;
    crdstat(fromc:toc, 5) = ...
        vmp_VoxelStats(vmp, vmpnum, coords{vc}, voitype);
end

% calculate further stats
switch (calcp)
    case {'t'}
        crdstat(fromc:toc, 6) = 2 - 2 * sdist('tcdf', abs(crdstat(:, 5)), df1);
end

% output object
void = xff('new:roid');
bc2 = xffgetcont(void.L);
bc2.TypeOfStatistic = statype;
bc2.NrOfVoxels = crdssum;
bc2.StatMinValue = min(crdstat(:, 5));
bc2.StatMaxValue = max(crdstat(:, 5));
bc2.AvgStatValue = mean(crdstat(:, 5));
bc2.StatWeightedMass = sum(crdstat(:, 5));
switch (calcp)
    case {'t'}
        bc2.AvgPValue = mean(crdstat(:, 6));
        bc2.PWeightedMass = sum(crdstat(:, 6));
    otherwise
        bc2.AvgPValue = 1;
        bc2.PWeightedMass = 0;
end
bc2.VoxelData = crdstat;
bc2.VoxelCoords = crdstat(:, 1:3);
bc2.VoxelStats = crdstat(:, 5);
bc2.NrOfSubROIs = numvois;

% sub ROIs
for vc = 1:numvois
    fromc = crdoffs(vc);
    toc = crdoffs(vc + 1) - 1;
    bc2.ROI(vc).NrOfVoxels = toc + 1 - fromc;
    bc2.ROI(vc).VoxelCoords = crdstat(fromc:toc, 1:3);
    bc2.ROI(vc).VoxelStats = crdstat(fromc:toc, 5);
end

% put back
xffsetcont(void.L, bc2);
