% PUBLIC FUNCTION ne_delcluster: remove clusters from list
function varargout = ne_delcluster(varargin)

% Version:  v0.9b
% Build:    11050712
% Date:     Apr-09 2011, 11:48 PM EST
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

% global variable
global ne_gcfg;
ch = ne_gcfg.h;

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% get clusters
lbc = ch.Clusters;
clidx = lbc.Value;
if isempty(clidx)
    return;
end

% remove from listbox
lbc.Value = [];
lbs = lbc.String;
if ~iscell(lbs)
    lbs = cellstr(lbs);
end
lbs(clidx) = [];
lbc.String = lbs;

% remove from VOI
try
    ne_gcfg.voi.VOI(clidx) = [];
    ne_gcfg.voi.NrOfVOIs = numel(ne_gcfg.voi.VOI);

    % echo
    if ne_gcfg.c.echo
        ne_echo({'voi.VOI(%s) = [];', any2ascii(clidx)});
    end
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
end
