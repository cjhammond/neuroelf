function ohelp = root_Help(hfile, m)
% ROOT::Help  - get Help on methods
%
% FORMAT:       [helptext] = xff.Help([typmeth]);
%
% Input fields:
%
%       typmeth     optional type or method
%
% Output fields:
%
%       help        complete help over all methods

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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

% get list of extensions
x = xff(0, 'extensions');
xf = fieldnames(x);

if nargin > 1 && ...
    ischar(m) && ...
   ~isempty(m)
    m = lower(m(:)');

    % rethrow error if necessary
    try
        obj = cell(1, 1);
        % test for extension
        if isfield(x, m)

            % pass good object
            obj{1} = new(hfile, m);
            ohelp = aft_Help(obj{1});
            clearxffobjects(obj);

        % or pass to aft_Help for root
        else
            ohelp = aft_Help(hfile, m);
        end
    catch ne_eo;
        clearxffobjects(obj);
        rethrow(ne_eo);
    end
    return;
end

% remove double entries
for xc = numel(xf):-1:2
    if x.(xf{xc}){2} == x.(xf{xc-1}){2}
        xf(xc) = [];
    end
end
xf = sort(xf);

% create new objects and get help
obj = [];
ohelp = cell(numel(xf), 1);
for xc = numel(xf):-1:1
    try
        if strcmpi(xf{xc}, 'root')
            ohelp{xc} = aft_Help(hfile);
        else
            obj = new(hfile, xf{xc});
            ohelp{xc} = aft_Help(obj);
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
        ohelp{xc} = '';
    end
    if ~isempty(obj)
        xffclear(obj.L);
    end
    obj = [];
    ohelp{xc} = regexprep(ohelp{xc}, '^No methods.*$', '');
    if isempty(ohelp{xc})
        ohelp(xc) = [];
    end
end
ohelp = gluetostringc(ohelp, char(10));
