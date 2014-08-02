function hfile = root_ClearObjects(hfile, dspec)
% ROOT::ClearObjects  - delete multiple objects
%
% FORMAT:       xff.ClearObjects(dspec);
%
% Input fields:
%
%       dspec       (partial) filename (or pattern)
%
% No output fields.

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:08 AM EST
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
global xffclup;
global xffcont;

% argument check
if nargin ~= 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'root') || ...
    hfile.L ~= -1 || ...
    ~ischar(dspec) || ...
    isempty(dspec)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
dspec = lower(dspec(:)');

% specification is extension (e.g. all VMRs)
if any(numel(dspec) == [3, 4]) && ...
    any(strcmpi(dspec, fieldnames(xffcont(1).C.Extensions)))

    % match extensions
    ons = {xffcont(:).S};
    for oc = 1:numel(ons)
        ons{oc} = ons{oc}.Extensions{1};
    end

% otherwise
else

    % get available objects' filenames
    ons = {xffcont(:).F};
end

% filename (without pattern)
if ~any(dspec == '*' | dspec == '?')

    % use strcmpi
    clo = strcmpi(dspec, ons);

% pattern
else

    % make sure pattern is valid
    ast = find(dspec == '*');
    if ~isempty(ast) && ...
       (ast(1) == 1 || ...
        any(dspec(ast - 1) ~= '.' & dspec(ast - 1) ~= ']'))
        dspec = strrep(dspec, '*', '.*');
        dspec = strrep(dspec, '**', '*');
    end
    clo = ~cellfun('isempty', regexpi(ons, dspec));
end

% don't meddle with ROOT object's content!
clo(1) = false;

% any matches
if any(clo)

    % remove from global storage
    xffclear(xffclup(clo));
end
