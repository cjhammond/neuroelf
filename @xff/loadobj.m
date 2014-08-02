function hfile = loadobj(hfile)
% xff::loadobj  - unpack object from MAT file
%
% FORMAT:       obj = loadobj(obj);
%
% Input fields:
%
%       obj         srored xff object
%
% Output fields:
%
%       obj         object with restored content

% Version:  v0.9b
% Build:    11050711
% Date:     Apr-07 2011, 11:53 AM EST
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

% global content
global xffcont;
if isempty(xffcont)
    xff;
end

% argument check
if nargin ~= 1 || ...
    numel(hfile) ~= 1 || ...
   ~isa(hfile, 'xff') || ...
   ~isfield(struct(hfile), 'L')
    error( ...
        'xff:BadArgument', ...
        'Invalidly stored object.' ...
    );
end

% convert to struct
hstr = struct(hfile);
hstr = hstr.L;
if ~isfield(hstr, 'BEH') || ...
   ~isfield(hstr, 'DAT') || ...
   ~isfield(hstr, 'EXT') || ...
   ~isfield(hstr, 'TYP')
    error( ...
        'xff:BadArgument', ...
        'Invalidly stored object.' ...
    );
end

% root object
if strcmpi(hstr.TYP, 'root')

    % simply return current root object
    hfile = xff;
    return;
end

% depending on behavior
b = hstr.BEH;
switch (b)

    % loading from data
    case {'data'}

        % create new object
        hfile = xff(['new:' hstr.EXT]);

        % and set content
        xffsetcont(hfile.L, hstr.DAT);

    % load from file
    case {'filename'}

        % try loading
        try
            hfile = xff(hstr.DAT);
        catch ne_eo;
            neuroelf_lasterr(ne_eo);
            hfile = xff(['new:' hstr.EXT]);
            warning( ...
                'xff:LoadError', ...
                'Error loading saved object from ''%s'' (using default): %s.', ...
                hStr.DAT, ne_eo.message ...
            );
        end
end
