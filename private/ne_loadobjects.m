% PUBLIC FUNCTION ne_loadobjects: add all currently loaded vars in xff
function varargout = ne_loadobjects(varargin)

% Version:  v0.9d
% Build:    14062317
% Date:     Feb 2012, 10:15 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010 - 2012, 2014, Jochen Weber
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

% global variable
global ne_gcfg;

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% get objects
nelfo = xff(0, 'objects');

% begin with VMRs
hasvmr = false;

% iterate over found objects
for oc = 2:numel(nelfo)

    % if is a VMR
    if strcmpi(nelfo(oc).S.Extensions{1}, 'vmr')

        % then add to list by using the openfile call
        ne_openfile(0, 0, xff(nelfo(oc).L), false, false);

        % and keep track of VMR status
        hasvmr = true;
    end
end

% if no VMR was found
if ~hasvmr

    % try loading the colin.vmr file instead
    try
        dv = ne_gcfg.c.ini.MainFig.DefaultVMR;
        for oc = 1:numel(dv)
            if any(dv{oc} == '/' | dv{oc} == '\')
                dvi = dv{oc};
            else
                dvi = [neuroelf_path('colin') filesep dv{oc}];
            end
            if exist(dvi, 'file') > 0
                ne_openfile(0, 0, dvi, true, true);
                break;
            end
        end
    catch ne_eo;
        ne_gcfg.c.lasterr = ne_eo;
    end
end

% try putting all other supported objects in NeuroElf's workspace
for xc = {'vmp', 'cmp', 'glm', 'hdr', 'head', 'vtc', 'fmr', 'dmr', 'msk', 'smp', 'srf'}
    for oc = 2:numel(nelfo)
        if strcmpi(nelfo(oc).S.Extensions{1}, xc{1})
            ne_openfile(0, 0, xff(nelfo(oc).L), false, false);
        end
    end
end

% set CVar and StatVar to first index (only on first call)
if nargin > 0
    ne_gcfg.h.SliceVar.Value = 1;
    ne_setcvar;
    ne_gcfg.h.StatsVar.Value = 1;
    ne_setcstats;
    ne_gcfg.h.SurfVar.Value = 1;
    ne_setcsrf;
end
