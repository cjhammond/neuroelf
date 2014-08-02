function f = neuroelf_file(p, name)
% neuroelf_file  - return file contents
%
% FORMAT:       f = neuroelf_file(p, name)
%
% Input fields:
%
%       p           path, either of
%                   - 'c' (colin)
%                   - 'f' (figure/tfg)
%                   - 'i' (icons)
%                   - 'l' (lut)
%                   - 'p' (spm)
%                   - 's' (splash)
%                   - 't' (talairach files)
%                   - 'u' (unit meshes)
%
% Output fields:
%
%       f           file contents (xfigure/xff/image data/content)

% Version:  v0.9b
% Build:    11050212
% Date:     Apr-09 2011, 11:08 PM EST
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

% persistent memory
persistent nelf_fp;
if numel(nelf_fp) ~= 1 || ...
   ~isstruct(nelf_fp)

    % create struct
    nelf_fp = struct;

    % get path
    px = strrep(fileparts(mfilename('fullpath')), '\', '/');
    if px(end) == '/'
        px(end) = [];
    end

    % put path in base field
    p2 = [px '/_core/'];
    p3 = [px '/_files/'];

    % create folder names
    nelf_fp.c = [p3 'colin/'];
    nelf_fp.f = [p2 'tfg/'];
    nelf_fp.i = [p2 'icons/'];
    nelf_fp.l = [p2 'lut/'];
    nelf_fp.p = [p3 'spm/'];
    nelf_fp.s = [p2 'splash/'];
    nelf_fp.t = [p3 'tal/'];
    nelf_fp.u = [p3 'srf/'];
end

% argument check
if nargin < 2 || ...
   ~ischar(p) || ...
    numel(p) ~= 1 || ...
   ~any('cfilpstu' == lower(p)) || ...
   ~ischar(name) || ...
    isempty(name)
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid or missing argument.' ...
    );
end
p = lower(p);
name = name(:)';

% depending on path
try
    switch (p)

        % files from colin folder
        case {'c'}
            f = bless(xff([nelf_fp.c name]), 1);

        % tfg
        case {'f'}
            f = xfigure([nelf_fp.f name '.tfg']);

        % icons
        case {'i'}
            f = imread([nelf_fp.i name '.tif']);

        % lut
        case {'l'}
            f = bless(xff([nelf_fp.l name '.olt']), 1);

        % lut
        case {'p'}
            f = load([nelf_fp.p name '.mat']);

        % splash
        case {'s'}
            f = imread([nelf_fp.s name '.jpg']);

        % talairach
        case {'t'}
            f = [nelf_fp.t name];

        % files from colin folder
        case {'u'}
            f = bless(xff([nelf_fp.u 'unit' name '.srf']), 1);
    end
catch ne_eo;
    rethrow(ne_eo);
end
