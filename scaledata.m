function sdata = scaledata(cdata, mm)
% scaledata  - automatically scale data between gray-scale boundaries
%
% FORMAT:       sdata = scaledata(C [, mm])
%
% Input fields:
%
%       C           N-dim data that is shown with a 256 grayscale
%       mm          min/max boundaries [default: 0, 255.999]
%
% Output fields:
%
%       sdata       scaled data (unrounded)

% Version:  v0.9d
% Build:    14072513
% Date:     Jul-25 2014, 1:55 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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
if ~isnumeric(cdata)
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid color data given.' ...
    );
end
cdata = double(cdata);
if nargin < 2 || ...
   ~isa(mm, 'double') || ...
    numel(mm) ~= 2 || ...
    any(isinf(mm) | isnan(mm)) || ...
    mm(1) == mm(2)
    mm = [0, 255.999];
end
md = mm(2) - mm(1);
mmm = minmaxmean(cdata(:), 4);
sdata = mm(1) + (md / (eps + (mmm(2) - mmm(1)))) .* (cdata - mmm(1));
