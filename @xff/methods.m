function M = methods(S)
% xff::methods  - overloaded method
%
% gives the available methods for the current object (see subsref)

% Version:  v0.9b
% Build:    11050711
% Date:     Apr-07 2011, 2:47 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2011, Jochen Weber
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

% persistent methods
persistent xffmeth;
if isempty(xffmeth)
    xffmeth = xff(0, 'methods');
end

% default to empty
M = {};

% only valid if not empty
if isempty(S)
    return;
end

% get structed version and lookup
sfile = struct(S);
if ~isempty(sfile)
    try
        sc = xffgetscont(sfile(1).L);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        error( ...
            'xff:InvalidObject', ...
            'Memory of object freed.' ...
        );
    end
end

% get file type and set
stype = lower(sc.S.Extensions{1});

% add methods for this type if any
if isfield(xffmeth, stype)
    tm = xffmeth.(stype);
    mf = fieldnames(tm);

    % iterate
    M = cell(numel(mf), 1);
    for mc = 1:length(mf)
        sm = tm.(mf{mc}){1};
        up = find(sm == '_');
        M{mc} = sm(up(1)+1:end);
    end
end

% add AFT methods
tm = xffmeth.aft;
mf = fieldnames(tm);

% iterate
nM = numel(M);
M{nM + numel(mf)} = '';
for mc = 1:length(mf)
    sm = tm.(mf{mc}){1};
    M{nM + mc} = sm(5:end);
end
