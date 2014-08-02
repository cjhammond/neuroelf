function xffclear(l, cgui)
% xff::_clear  - clears objects' memory for given handles

% Version:  v0.9a
% Build:    13042410
% Date:     May-17 2010, 10:48 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2010, Jochen Weber
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
global xffclup;
global xffcont;
global ne_gcfg;

try
    [rl{1:2}] = intersect(xffclup(2:end), l);
    rl = rl{2} + 1;
    clu = {xffcont(rl).H};
    for c = 1:numel(clu)
        if isfield(clu{c}, 'CleanUp') && ...
            iscell(clu{c}.CleanUp) && ...
           ~isempty(clu{c}.CleanUp)
            clus = clu{c}.CleanUp;
            for cluc = 1:numel(clus)
                if ischar(clus{cluc}) && ...
                   ~isempty(clus{cluc})
                    evalin('base', clus{cluc}(:)', '');
                end
            end
        end
        if isfield(clu{c}, 'ShownInGUI') && ...
            islogical(clu{c}.ShownInGUI) && ...
            numel(clu{c}.ShownInGUI) == 1 && ...
            clu{c}.ShownInGUI && ...
           (nargin < 2 || ...
            cgui) && ...
           ~isempty(ne_gcfg)
            neuroelf_gui('closefile', xff(0, 'makeobject', struct('L', clu{c}.xff)), false);
        end
        if isfield(clu{c}, 'GZIPext') && ...
            ischar(clu{c}.GZIPext) && ...
            strcmpi(clu{c}.GZIPext, '.gz') && ...
            isfield(clu{c}, 'GZIPfile') && ...
            ischar(clu{c}.GZIPfile) && ...
           ~isempty(clu{c}.GZIPfile) && ...
            exist([clu{c}.GZIPfile clu{c}.GZIPext], 'file') == 2
            cluf = xffcont(rl(c)).F;
            if ~isempty(cluf) && ...
                exist(cluf, 'file') == 2
                try
                    delete(cluf);
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
        end
    end
    xffcont(rl) = [];
    xffclup(rl) = [];
catch ne_eo;
    error( ...
        'xff:LookupError', ...
        'Error looking up/clearing objects: %s.', ...
        ne_eo.message ...
    );
end
