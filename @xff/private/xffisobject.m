function isf = xffisobject(hfile, s, t)
% xff::_isobject  - test an input for being a (valid) object

% Version:  v0.9d
% Build:    14030412
% Date:     Mar-04 2014, 12:45 PM EST
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

% global storage
global xffclup xffcont;

% class check first
if ~isa(hfile, 'xff')
    isf = false;
    return;
end

% arguments
if nargin > 1 && ...
    islogical(s) && ...
    ~isempty(s) && ...
    s(1)
    if nargin > 2 && ...
        ischar(t) && ...
       ~isempty(t)
        t = {t(:)'};
    elseif nargin > 2 && ...
        iscell(t) && ...
       ~isempty(t)
        t = t(:);
    else
        t = {};
    end
else
    isf = true(size(hfile));
    return;
end

if numel(hfile) == 1
    if ~any(xffclup == hfile.L)
        isf = false;
        return;
    end
    if ~isempty(t) && ...
       ~any(strcmpi(xffcont(xffclup == hfile.L).S.Extensions{1}, t))
        isf = false;
    else
        isf = true;
    end
    return;
end

isf = true(size(hfile));
for oc = 1:numel(hfile)

    % L must lead to global storage
    if ~any(xffclup == hfile(oc).L)
        isf(oc) = false;
        continue;
    end

    % if that passed, check extension if given
    if ~isempty(t) && ...
       ~any(strcmpi(xffcont(xffclup == hfile(oc).L).S.Extensions{1}, t))
        isf(oc) = false;
    end
end
