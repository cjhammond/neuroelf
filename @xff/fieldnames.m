function names = fieldnames(S)
% xff::fieldnames  - overloaded method (completion, etc.)
%
% method used for getting property list (and methods), especially
% for the auto completion feature in the GUI

% Version:  v0.9b
% Build:    11051101
% Date:     Apr-07 2011, 11:53 AM EST
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
global xffconf;
persistent xffmeth;
if isempty(xffmeth)
    xffmeth = xff(0, 'methods');
end

% only valid if not empty
if isempty(S)
    names = {};
    return;
end

% get structed version and lookup
sfile = struct(S);
if ~isempty(sfile)
    try
        last = sfile(1).L;
        sc = xffgetscont(last);
    catch ne_eo;
        error( ...
            'xff:InvalidObject', ...
            'Memory of object freed or invalid object: %s.', ...
            ne_eo.message ...
        );
    end
end
pril = (last == xffconf.last(2));
xffconf.last = [last, xffconf.last(1)];

% get file type
stype = lower(sc.S.Extensions{1});

% return original names
names = fieldnames(sc.C);

% add methods if any
if isfield(xffmeth, stype)
    tm = xffmeth.(stype);
    mf = fieldnames(tm);

    % iterate
    nnames = numel(names);
    names(nnames + numel(mf)) = names(nnames);
    for mc = 1:numel(mf)
        sm = tm.(mf{mc}){1};
        up = find(sm == '_');
        if pril
            names{nnames + mc} = [sm(up(1)+1:end) tm.(mf{mc}){2}];
        else
            names{nnames + mc} = sm(up(1)+1:end);
        end
    end
end

% add AFT methods
tm = xffmeth.aft;
mf = fieldnames(tm);

% iterate
nnames = numel(names);
names{nnames + numel(mf)} = '';
for mc = 1:numel(mf)
    sm = tm.(mf{mc}){1};
    if pril
        names{nnames + mc} = [sm(5:end) tm.(mf{mc}){2}];
    else
        names{nnames + mc} = sm(5:end);
    end
end
