function hfile2 = glm_ConvertToVMP(hfile)
% GLM::ConvertToVMP  - create VMP with beta maps of GLM
%
% FORMAT:       glmvmp = glm.ConvertToVMP;
%
% No input fields.
%
% Output fields:
%
%       glmvmp      VMP object

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
   ~xffisobject(hfile, true, 'glm')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get content
bc = xffgetcont(hfile.L);
if bc.ProjectType ~= 1
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bbox = aft_BoundingBox(hfile);
mnames = aft_MapNames(hfile);

% currently only for RFX-GLMs
if bc.ProjectTypeRFX < 1
    error( ...
        'xff:NotYetImplemented', ...
        'Currently only valid for RFX GLMs.' ...
    );
end

% create VMP
hfile2 = newnatresvmp(bbox.BBox, bc.Resolution, 15);
bc2 = xffgetcont(hfile2.L);

% get total number of maps and fill vmp
nsubs = numel(bc.GLMData.Subject);
nsubp = size(bc.GLMData.Subject(1).BetaMaps, 4);
tmaps = nsubs * nsubp;
mapc = 1;
bc2.Map = bc2.Map(ones(1, tmaps));
for sc = 1:nsubs
    for pc = 1:nsubp
        bc2.Map(mapc).Name = mnames{mapc};
        bc2.Map(mapc).VMPData = bc.GLMData.Subject(sc).BetaMaps(:, :, :, pc);
        mapc = mapc + 1;
    end
end

% also copy TrfPlus
bc2.RunTimeVars.TrfPlus = bc.RunTimeVars.TrfPlus;

% set back
xffsetcont(hfile2.L, bc2);
