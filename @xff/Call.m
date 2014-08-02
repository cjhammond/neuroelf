function varargout = Call(hfile, method, varargin)
% xff::Call  - call a method (needed for older MATLAB versions)
%
% FORMAT:       [varargout] = Call(hObject, method, ...)
%
% Input fields:
%
%       hObject     1x1 xff object handle
%       method      name of method to call
%       ...         arguments
%
% Output fields:
%
%       varargout   as requested
%
% Note: this call usually produces the same effect as overloading
%       subsref, but in older releases this might be required to
%       obtain multiple outputs. So,
%
% >> [output{1:nout}] = Call(hObject, 'method', ...);
%
%       and
%
% >> [output{1:nout}] = hObject.method(...);
%
%       should produce the same results.

% Version:  v0.9d
% Build:    14061918
% Date:     Jun-19 2014, 6:27 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2011, 2014, Jochen Weber
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

% global config
global xffconf;

% to check availability of functions use own dir!
persistent call_methdir;
if isempty(call_methdir)
    call_methdir = [fileparts(mfilename('fullpath')) '/private/'];
end

% argument check
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true) || ...
   ~ischar(method) || ...
    isempty(method)
    error( ...
        'xff:BadSubsRef', ...
        'No S struct given or empty.' ...
    );
end
sc = xffgetscont(hfile.L);
otype = sc.S.Extensions{1};

% check all file types first
if exist([call_methdir 'aft_' method(:)' '.m'], 'file') == 2
    otype = 'aft';
end

% try call
try
    if nargout > 0
        varargout = cell(1, nargout);
        eval(['[varargout{1:nargout}]=' lower(otype) '_' method(:)' ...
              '(hfile, varargin{:});']);
    else

        eval(['[varargout{1}]=' lower(otype) '_' method(:)' ...
              '(hfile, varargin{:});']);
    end
catch ne_eo;
    error( ...
        'xff:CallError', ...
        'Error calling method ''%s'' of type ''%s'': %s.', ...
        method(:)', ...
        upper(otype), ...
        ne_eo.message ...
    );
end

% unwind stack
if xffconf.unwindstack
    xff(0, 'unwindstack');
end
