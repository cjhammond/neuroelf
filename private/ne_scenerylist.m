% PUBLIC FUNCTION ne_scenerylist: return list (UserData) of scenery objects
function varargout = ne_scenerylist(varargin)

% Version:  v0.9b
% Build:    11050712
% Date:     Apr-10 2011, 4:52 PM EST
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

% preset varargout
if nargout > 1
    varargout = cell(1, nargout);
end

% set command embedded
if nargin > 3 && ...
    ischar(varargin{3}) && ...
    strcmpi(varargin{3}(:)', 'set') && ...
    isa(varargin{4}, 'double') && ...
   ~any(isinf(varargin{4}(:)) | isnan(varargin{4}(:)) | varargin{4}(:) < 1 | ...
        varargin{4}(:) > size(ne_gcfg.h.Scenery.UserData, 1))

    % try to set Scenery.Value and update
    try
        ne_gcfg.h.Scenery.Value = unique(round(varargin{4}(:)));
        ne_setsurfpos(0, 0, 1);
        if ne_gcfg.fcfg.page ~= 3
            ne_showpage(0, 0, 3);
        end
    catch ne_eo;
        ne_gcfg.c.lasterr = ne_eo;
    end
end

% output
if nargout > 0
    varargout{1} = ne_gcfg.h.Scenery.UserData;
    if nargout > 1
        varargout{2} = ne_gcfg.h.Scenery.Value;
    end
end
