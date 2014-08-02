function wmvmr = vmr_MarkWhiteMatter(hfile, opts)
% VMR::MarkWhiteMatter  - mark white matter (e.g. for IC)
%
% FORMAT:       wmvmr = vmr.MarkWhiteMatter([opts])
%
% Input fields:
%
%       opts        optional settings
%        .gsmoothc  gradient smoothing cycles (default: 6)
%        .smoothc   smoothing cycles (default: 5)
%        .smoothr   smoothing radius (default: 5)
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
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vmr')
    error( ...
        'xff:BadArgument', ...
        'Invalid object in call to VMR::MarkWhiteMatter' ...
    );
end
if nargin < 2 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'gsmoothc')
    opts.gsmoothc = 6;
end
if ~isfield(opts, 'smoothc')
    opts.smoothc = 5;
end
if ~isfield(opts, 'smoothr')
    opts.smoothr = 5;
end

% copy object
vc = aft_CopyObject(hfile);

% get content of copy
bc = xffgetcont(vc.L);
if ~isempty(bc.VMRData16)
    bc = bc.VMRData16;
else
    bc = bc.VMRData;
end
bm = mean(bc(:));

% perform number of gradient smoothings
for sc = 1:opts.gsmoothc
    bc = gradsmooth(bc);
end
bd = bc * (bm / mean(bc(:)));

% set content to temporary VMR
bc = xffgetcont(vc.L);
if ~isempty(bc.VMRData16)
    bc.VMRData16 = uint16(bd);
else
    bc.VMRData = uint8(bd);
end
xffsetcont(vc.L, bc);

% create gradient VMR
g = vmr_GradientVMR(vc);

% get gradient data
gc = xffgetcont(g.L);
gc = gc.VMRData;

% delete temporary VMRs
xffclear(g.L);
xffclear(vc.L);

% mark white matter
wm = (bd > mean(bd(:))) & (gc < mean(gc(:)));

% create WM VMR
wmvmr = xff('new:vmr');
wmc = xffgetcont(wmvmr.L);
wmc.VMRData = uint8([]);
wmc.VMRData(size(wm, 1), size(wm, 2), size(wm, 3)) = 0;
wmc.VMRData(wm) = 240;
xffsetcont(wmvmr.L, wmc);
