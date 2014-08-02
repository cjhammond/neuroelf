function hfile = fif_ReadInfoHeaders(hfile, ispec)
% FIF::ReadInfoHeaders  - read info headers into memory
%
% FORMAT:       fif.ReadInfoHeaders([ispec])
%
% Input fields:
%
%       ispec       optional list of header block types to read,
%                   default: [101, 900]

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
   ~xffisobject(hfile, true, 'fif')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~isa(ispec, 'double') || ...
    isempty(ispec)
    ispec = [101, 900];
else
    ispec = unique(fix(ispec(:)'));
    ispec(isinf(ispec) | isnan(ispec) | ispec < 1 | ispec > 16777216) = [];
    if isempty(ispec)
        ispec = [101, 900];
    end
end

% get object reference
bc = xffgetcont(hfile.L);

% get FIF
fif = bc.FIFStructure;
lup = fif.BlockLookup;

% load blocks
bli = zeros(1, 0);
for ic = ispec
    bli = [bli, find(lup(1, :) == ic)];
end
for buc = bli
    fif = fifio(fif, 'readelem', lup(2, buc):lup(3, buc));
end

% put back into object
bc.FIFStructure = fif;
xffsetcont(hfile.L, bc);
