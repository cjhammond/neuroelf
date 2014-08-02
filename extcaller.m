function fromwhere = extcaller(varargin)
% extcaller  - from where was a call issued
%
% FORMAT:       callername = extcaller
%
% No input fields.
%
% Output fields:
%
%       callername  string identifying function name of calling function
%
% See also DBSTACK

% Version:  v0.9a
% Build:    10051716
% Date:     May-17 2010, 10:48 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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

% persistent versioning information
persistent ec_mlv;
if isempty(ec_mlv)
    ec_mlv = version;
    if ec_mlv(1) > '6'
        ec_mlv = 'file';
    else
        ec_mlv = 'name';
    end
end

% how to get stack info
switch (ec_mlv), case {'file'}
    pathstack = dbstack('-completenames');
case {'name'}
    pathstack = dbstack;
otherwise
    error( ...
        'neuroelf:MemoryCorruption', ...
        'Interal variable glitch.' ...
    );
end

% set default caller name
fromwhere = 'CONSOLE_OR_GUI';
if numel(pathstack) < 3
    return;
end

% input argument handling
if nargin < 1
    func = lower(pathstack(2).(ec_mlv));

elseif ischar(varargin{1})
    func = lower(varargin{1});

elseif isnumeric(varargin{1}) && ...
   ~isempty(varargin{1}) && ...
   ~isnan(varargin{1}(1))
    func = lower(pathstack(2).(ec_mlv));
    if varargin{1}(1) == 1
        func = fileparts(func);
    end

else
    error( ...
        'neuroelf:BadArgument', ...
        'Unsupported input argument.' ...
    );
end

% try to find matching caller
for dbsi = 3:numel(pathstack)
    if isempty(strfind(lower(pathstack(dbsi).(ec_mlv)), func))
        break;
    end
end
if dbsi < numel(pathstack) || ...
    isempty(strfind(lower(pathstack(dbsi).(ec_mlv)), func))
    fromwhere = pathstack(dbsi).(ec_mlv);
end
