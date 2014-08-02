function tc = voi_TalCoords(hfile, voi)
% VOI::TalCoords  - return Talairach coords for a voi
%
% FORMAT:       tc = voi.TalCoords(voi)
%
% Input fields:
%
%       voi         number or name of VOI
%
% Output fields:
%
%       tc         Nx3 coords in Talairach space

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2011, 2014, Jochen Weber
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
   (~ischar(voi) && ~isa(voi, 'double')) || ...
    isempty(voi)
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
numvois = numel(bc.VOI);
if ischar(voi)
    voi = findfirst(strcmpi(voi(:)', {bc.VOI.Name}));
    if isempty(voi)
        error( ...
            'xff:InvalidName', ...
            'Named VOI not found.' ...
        );
    end
else
    voi = real(voi(:)');
    if any(isinf(voi) | isnan(voi) | voi < 1 | voi > numvois) || ...
        numel(unique(fix(voi))) ~= numel(voi)
        error( ...
            'xff:BadArgument', ...
            'Invalid VOI selection.' ...
        );
    end
    voi = fix(voi);
end

% get voi
voi = bc.VOI(voi);

% initialize bvc
tc = cat(1, voi.Voxels);

% transform?
if ~strcmpi(bc.ReferenceSpace, 'tal')
    tc = [bc.OriginalVMRResolutionX .* (tc(:, 1) + bc.OriginalVMROffsetX), ...
          bc.OriginalVMRResolutionY .* (tc(:, 2) + bc.OriginalVMROffsetY), ...
          bc.OriginalVMRResolutionZ .* (tc(:, 3) + bc.OriginalVMROffsetZ)];
    tc = 0.5 .* (bc.OriginalVMRFramingCubeDim(ones(size(tc, 1), 1), 1) * ...
        [bc.OriginalVMRResolutionZ, bc.OriginalVMRResolutionX, bc.OriginalVMRResolutionY]) - ...
        tc(:, [3, 1, 2]);
end
