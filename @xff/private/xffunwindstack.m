function u = xffunwindstack(nu)
% xff::_unwindstack  - unwind stack of xff class

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
global xffclup xffconf xffcont;
persistent msc;
if isempty(msc)
    mlv = version;
    msc = (str2double(mlv(1)) < 7);
end


% allow to change setting
if nargin > 0 && ...
    islogical(nu) && ...
    numel(nu) == 1
    xffconf.unwindstack = nu;
end

% doesn't work if not enabled
if ~xffconf.unwindstack
    u = false;
    return;
end

% which version
if msc
    cst = dbstack;
    cst = {cst.name};
else
    cst = dbstack('-completenames');
    cst = {cst.file};
end

% remove xff from stack
cst(1:2) = [];

% get current stack
rst = true(size(cst));
for rc = 1:numel(rst)
    rst(rc) = isempty(strfind(cst{rc}, '@xff'));
end
cst = cst(rst);

% iterate over all objects
uobjs = false(1, numel(xffcont));
ost = {xffcont(:).U};
for uc = 2:numel(uobjs)

    % continue if stack is empty
    if isempty(ost{uc})
        continue;
    end

    % compare last entries
    if numel(cst) < numel(ost{uc}) || ...
        any(~strcmp(ost{uc}, cst(end+1-numel(ost{uc}):end)))
        uobjs(uc) = true;
    end
end

% clear objects
if any(uobjs)
    xffclear(xffclup(uobjs), false);
end

% return flag
u = xffconf.unwindstack;
