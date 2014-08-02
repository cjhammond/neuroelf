function hfile = prt_SetDuration(hfile, conds, dur)
% PRT::SetDuration  - set duration(s) in conditions of a PRT
%
% FORMAT:       [prt =] prt.SetDuration(conds, dur)
%
% Input fields:
%
%       conds       1xC condition list
%       dur         duration in units of PRT
%
% Output fields:
%
%       prt         altered PRT
%
% Examples:
%
%   prt.SetDuration(2:8, 4000);
%

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
if nargin < 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'prt') || ...
   ~isa(conds, 'double') || ...
    isempty(conds) || ...
    any(isinf(conds(:)) | isnan(conds(:)) | conds(:) < 0.5) || ...
   ~isa(dur, 'double') || ...
    numel(dur) ~= 1 || ...
    isinf(dur) || ...
    isnan(dur) || ...
    dur < 0
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
conds = unique(round(conds(:)'));
bc = xffgetcont(hfile.L);

% get number of conditions
ncon = numel(bc.Cond);
conds(conds > ncon) = [];

for cc = conds
    bc.Cond(cc).OnOffsets(:, 2) = bc.Cond(cc).OnOffsets(:, 1) + dur;
end

% set new content
xffsetcont(hfile.L, bc);
