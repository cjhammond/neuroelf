function [vmv] = srf_CreateVMVfromSMP(hfile, smp, opts)
% SRF::CreateVMVfromSMP  - create VMV from SMP
%
% FORMAT:       vmv = srf.CreateVMVfromSMP(smp, opts)
%
% Input fields:
%
%       smp         multi-map SMP object
%       opts        1x1 struct with optional fields
%        .smorph    number of morphing steps, default: 6
%        .threshmax maximum threshold, default: use SMP value
%        .threshmin minimum threshold, default: use SMP value
%
% Output fields:
%
%       vmv         VMV containing the SRF positions and color coding

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
   ~xffisobject(hfile, true, 'srf') || ...
    numel(smp) ~= 1 || ...
   ~xffisobject(smp, true, 'smp')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'smorph') || ...
   ~isa(opts.smorph, 'double') || ...
    numel(opts.smorph) ~= 1 || ...
    isinf(opts.smorph) || ...
    isnan(opts.smorph) || ...
    opts.smorph < 1 || ...
    opts.smorph ~= fix(opts.smorph)
    opts.smorph = 8;
end

% get contents
sc = xffgetscont(hfile.L);
bc = sc.C;
smpc = xffgetcont(smp.L);
nrv = bc.NrOfVertices;

% checks
if nrv ~= smpc.NrOfVertices
    error( ...
        'xff:ObjectsMismatch', ...
        'NrOfVertices must match between SRF and SMP.' ...
    );
end

% generate VMV object
vmv = xff('new:vmv');
vmvc = xffgetcont(vmv.L);

% fill some fields
nrm = numel(smpc.Map);
vmvc.NrOfPositions = nrm;
vmvc.NrOfVertices = nrv;
vmvc.UseViewPoint = 0;
vmvc.UseVertexColor = 1;
vmvc.NameOfOriginateSRF = sc.F;
vmvc.VertexPosition.Coordinates = bc.VertexCoordinate;
vmvc.VertexPosition.Normals = bc.VertexNormal;
vmvc.VertexPosition.Colors = bc.VertexColor;
vmvc.VertexPosition.MorphingSteps = opts.smorph;
vmvc.VertexPosition.NameOfState = '';
vmvc.VertexPosition(2:nrm) = vmvc.VertexPosition(1);

% loop over maps
for mc = 1:nrm
    tmap = smpc.Map(mc).SMPData;
    tmap = max(0, tmap - smpc.Map(mc).LowerThreshold);
    tmap = tmap ./ (smpc.Map(mc).UpperThreshold - smpc.Map(mc).LowerThreshold + eps);
    tmi = find(tmap > 0);
    tmap = tmap(tmi);
    vmvc.VertexPosition(mc).Colors(tmi, 1) = NaN;
    vmvc.VertexPosition(mc).Colors(tmi, 2) = 255;
    vmvc.VertexPosition(mc).Colors(tmi, 3) = round(255 * tmap);
    vmvc.VertexPosition(mc).NameOfState = smpc.Map(mc).Name;
end

% store information back
xffsetcont(vmv.L, vmvc);
