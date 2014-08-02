function hfile = prt_AddRest(hfile, opts)
% PRT::AddRest  - add a rest condition to a PRT file
%
% FORMAT:       [prt = ] prt.AddRest([opts]);
%
% Input fields:
%
%       opts        optional settings
%        .color     condition color (default: [128, 128, 128])
%        .maxtime   maximum time to fill (default until last event)
%        .condno    condition number (default: 1)
%
% Output fields:
%
%       prt         altered PRT object

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
   ~xffisobject(hfile, true, 'prt')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'color') || ...
   ~isa(opts.color, 'double') || ...
    numel(opts.color) ~= 3 || ...
    any(isinf(opts.color) | isnan(opts.color) | opts.color < 0 | opts.color > 255)
    opts.color = [128, 128, 128];
else
    opts.color = opts.color(:)';
    if all(opts.color <= 1)
        opts.color = 255 * opts.color;
    end
    opts.color = round(opts.color);
end
if ~isfield(opts, 'maxtime') || ...
   ~isa(opts.maxtime, 'double') || ...
    numel(opts.maxtime) ~= 1 || ...
    isinf(opts.maxtime) || ...
    isnan(opts.maxtime)
    opts.maxtime = -1;
end
if ~isfield(opts, 'condno') || ...
   ~isa(opts.condno, 'double') || ...
    numel(opts.condno) ~= 1 || ...
    isinf(opts.condno) || ...
    isnan(opts.condno) || ...
    opts.condno < 1
    opts.condno = 1;
end
bc = xffgetcont(hfile.L);
opts.condno = fix(min(numel(bc.Cond), opts.condno));

% get maxtime
coo = zeros(0, 2);
for cc = 1:numel(bc.Cond)
    coo = [coo; bc.Cond(cc).OnOffsets];
end
[cons, coni] = sort(coo(:, 1));
coo = coo(coni, :);
if opts.maxtime < 0
    opts.maxtime = max(coo(:,2));
end

% build rest condition
oo = zeros(0, 2);
fo = 0;
for oc = 1:size(coo, 1)
    if fo >= opts.maxtime
        break;
    end
    if fo < coo(oc, 1)
        oo(end + 1, :) = [fo, coo(oc, 1) - 1];
    end
    fo = max(fo, coo(oc, 2) + 1);
end
if opts.maxtime > fo
    oo(end + 1, :) = [fo + 1, opts.maxtime];
end

% return if nothing done
if isempty(oo)
    return;
end

% build new condition
newc = struct( ...
    'ConditionName', {{'Rest'}}, ...
    'NrOfOnOffsets', size(oo, 1), ...
    'OnOffsets',     oo, ...
    'Weights',       zeros(size(oo, 1), 0), ...
    'Color',         opts.color);

% update object
if ~isempty(bc.Cond)
    prec = bc.Cond(1:(opts.condno-1));
    posc = bc.Cond(opts.condno:end);
else
    prec = newc([]);
    posc = newc([]);
end
bc.Cond = [prec(:)', newc, posc(:)'];
bc.NrOfConditions = numel(bc.Cond);
xffsetcont(hfile.L, bc);
