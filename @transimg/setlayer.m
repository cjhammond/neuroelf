function ti = setlayer(ti, l, p, a, tr)
% transimg::setlayer  - set a layer of an image

% Version:  v0.9c
% Build:    14022202
% Date:     Jan-22 2012, 5:46 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2012, Jochen Weber
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

% global variables for storage
global tiobj ...
       tiobjlup;

% check arguments
lup = find(tiobjlup == ti.L);
if numel(lup) ~= 1
    error( ...
        'transimg:ObjectRemoved', ...
        'Object removed from global storage.' ...
    );
end
tio = tiobj(lup);
if nargin > 4
    if ~isa(tr, 'double') || ...
       (numel(tr) ~= 2 && ...
        numel(tr) ~= 3 && ...
        ~isequal(size(tr), [3, 3]) && ...
        ~isequal(size(tr), [4, 4])) || ...
        any(isinf(tr(:)) | isnan(tr(:)))
        error( ...
            'transimg:BadArgument', ...
            'Invalid transformation for partial/transformed content.' ...
        );
    end
    if numel(tr) == 2
        ltype = 'p';
    else
        ltype = 't';
    end
else
    ltype = 'f';
    tr = [];
end
if nargin < 3 || ...
   ~isa(l, 'double') || ...
    numel(l) ~= 1 || ...
    isinf(l) || ...
    isnan(l) || ...
    l < 1 || ...
   (~isa(p, 'uint8') && ...
    ~isa(p, 'double') && ...
    ~isa(p, 'single') && ...
    ~isa(p, 'transio')) || ...
   (ltype == 'f' && ...
    (size(p, 1) ~= tio.Height || ...
     size(p, 2) ~= tio.Width)) || ...
   ~any([1, 3] == size(p, 3)) || ...
   (nargin > 3 && ...
    ((~isa(a, 'double') && ...
      ~isa(a, 'single') && ...
      ~isa(a, 'uint8')) || ...
     (numel(a) ~= 1 && ...
      (ndims(a) ~= 2 || ...
       size(a, 1) ~= size(p, 1) || ...
       size(a, 2) ~= size(p, 2)))))
    error( ...
        'transimg:InvalidCall', ...
        'Invalid call to transimg::setlayer.' ...
    );
end
l = floor(real(l));
if nargin < 4
    a = single(1);
else
    if isa(a, 'uint8')
        a = single(1 / 255) .* single(a);
    else
        a = limitrangec(single(a), 0, 1, 0);
    end
end

% convert pixel data if necessary
if ~isa(p, 'uint8')
    p = limitrangec(single(p(:, :, :)), 0, 255, 0);
end

% reset IsRendered flag
tio.IsRendered = false;

% fill in missing layers with zeros
if l > (numel(tio.Layer) + 1)
    tio.Layer(end+1:l-1) = struct( ...
        'Type',       'f', ...
        'Pixel',      uint8(zeros(tio.Height, tio.Width)), ...
        'Alpha',      single(0), ...
        'Trans',      [], ...
        'IsRendered', true, ...
        'RPixel',     [], ...
        'RAlpha',     [], ...
        'Ref',        []);
end

% set layer
tio.Layer(l).Type = ltype;
tio.Layer(l).Alpha = a;
tio.Layer(l).Pixel = p;
tio.Layer(l).Trans = tr;
tio.Layer(l).IsRendered = true;

% set back in global storage
tiobj(lup) = tio;
