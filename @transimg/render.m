function ti = render(ti)
% transimg::render  - render the layers into .Rendered

% Version:  v0.9c
% Build:    12012217
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

% already rendered?
if tiobj(lup).IsRendered
    return;
end

% render individual layers
lt = {tiobj(lup).Layer.Type};
lr = {tiobj(lup).Layer.IsRendered};
for lc = 1:numel(lt)
    if ~ischar(lt{lc}) || ...
       ~any(strcmp(lt{lc}, {'f', 'p', 's', 't', 'x'}))
        error( ...
            'transimg:BadLayerType', ...
            'Invalid layer type in layer %d: %s.', ...
            lc, lt{lc} ...
        );
    end
    if any(lt{lc} == 'fp') || ...
        lr{lc}
        continue;
    end
    tiobj(lup).Layer(lc) = ti_renderlayer(tiobj(lup).Layer(lc), tiobj(lup).Height, tiobj(lup).Width);
end

% put back into .Rendered
tiobj(lup).Rendered = renderlayers(tiobj(lup));
tiobj(lup).IsRendered = true;
