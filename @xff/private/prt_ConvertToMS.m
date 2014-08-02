function hfile = prt_ConvertToMS(hfile, tr)
% PRT::ConvertToMS  - convert a volume-based PRT to ms-based
%
% FORMAT:       [prt] = prt.ConvertToMS(tr)
%
% Input fields:
%
%       tr          TR
%
% Output fields:
%
%       prt         altered protocol

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
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'prt') || ...
   ~isa(tr, 'double') || ...
    numel(tr) ~= 1 || ...
    isinf(tr) || ...
    isnan(tr) || ...
    tr < 1 || ...
    tr ~= fix(tr)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);

% return if not in volumes
if isempty(bc.ResolutionOfTime) || ...
    lower(bc.ResolutionOfTime(1)) ~= 'v'
    warning( ...
        'xff:NothingToDo', ...
        'PRT has a ResolutionOfTime that is not Volumes. PRT unchanged.' ...
    );
    return;
end

% iterate over conditions
c = bc.Cond;
for cc = 1:numel(c)

    % get onsets
    oo = c(cc).OnOffsets;

    % if all onsets are integer volumes
    if all(oo(:) == round(oo(:)))

        % use BV's logic
        bc.Cond(cc).OnOffsets = [(oo(:, 1) - 1) * tr, oo(:, 2) * tr];

    % otherwise
    else

        % assume that on/offsets are given in SPM logic
        bc.Cond(cc).OnOffsets = round(oo * tr);
    end
end

% set to MS
bc.ResolutionOfTime = 'msec';
xffsetcont(hfile.L, bc);
