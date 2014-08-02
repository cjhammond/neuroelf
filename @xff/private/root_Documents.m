function [docs, doct] = root_Documents(hfile, type)
% ROOT::Documents  - get list of "Documents" (VB-Style interface)
%
% FORMAT:       [docs, doct] = xff.Documents([type]);
%
% Input fields:
%
%       type        if given, must be one of the valid 3/4 char types
%                   or a regexpi list of types '(ext1|ext2|ext3)'
%
% Output fields:
%
%       docs        currently loaded documents
%       doct        file types of loaded documents

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
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

% argument check
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'root') || ...
    hfile.L ~= -1
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~ischar(type)
    type = '';
else
    type = lower(type(:)');
end

% get available objects (without ROOT!)
o = xff(0, 'objects');
o(1) = [];

% empty?
if isempty(o)
    docs = cell(0, 1);
    return;
end

% compile filename list
docs = {o(:).F};
docs = docs(:);
if nargout > 1 || ...
   ~isempty(type)
    doct = {o(:).S};
    for dc = 1:numel(doct)
        doct{dc} = doct{dc}.Extensions(1);
    end
    doct = cat(1, doct{:});
end

% replace missing filenames with numbers
for dc = 1:numel(docs)
    if isempty(docs{dc}) || ...
        any(strcmp(docs{dc}, docs(1:dc-1)))
        docs{dc} = dc;
    end
end

% only those of given type
if ~isempty(type)

    % only return those where initial index matches
    if any((3:4) == numel(type))

        % either as a simple match
        match = strcmpi(doct, type);

    % or
    else

        % as a regexpi match for multiple types
        match = (~cellfun('isempty', regexpi(doct, type)));
    end

    % get matches
    docs = docs(match);

    % and also for type
    if nargout > 1
        doct = doct(match);
    end
end
