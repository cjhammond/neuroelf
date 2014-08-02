function isf = isxff(hfile, varargin)
% isxff  - check (and validate) object
%
% FORMAT:       isf = isxff(hfile [, valid])
%
% Input fields:
%
%       hfile       MxN argument check for class
%       valid       if given and true, perform validation
%
% Output fields:
%
%       isf         logical array of input size with check result

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

% base argument check
if nargin < 1
    error( ...
        'neuroelf:TooFewArguments', ...
        'At least one input argument is required.' ...
    );
end
chstrict = false;
chtypest = '';
if nargin > 1 && ...
    numel(varargin{1}) == 1 && ...
   (isnumeric(varargin{1}) || ...
    islogical(varargin{1}))
    if varargin{1}
        chstrict = true;
    end
elseif nargin > 1 && ...
   (ischar(varargin{1}) || ...
    iscell(varargin{1})) && ...
    ~isempty(varargin{1})
    chstrict = true;
    chtypest = varargin{1}(:)';
end

% make call
isf = xff(0, 'isobject', hfile, chstrict, chtypest);
