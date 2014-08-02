function hfile = root_Document(hfile, dspec)
% ROOT::Document  - get one "Document" (VB-Style interface)
%
% FORMAT:       object = xff.Document(dspec);
%
% Input fields:
%
%       dspec       either numbered object or (partial) filename
%
% Output fields:
%
%       object      found object (otherwise: error)

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
if nargin ~= 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'root') || ...
    hfile.L ~= -1 || ...
   (~isa(dspec, 'double') && ...
    ~ischar(dspec)) || ...
    isempty(dspec)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end

% get available objects (without ROOT!)
o = xff(0, 'objects');
o(1) = [];

% for strings, look for xffID, filename and partial match
if ischar(dspec)
    dspec = dspec(:)';
    fm = [];
    if numel(dspec) == 24
        ons = {o(:).C};
        for c = 1:numel(ons)
            try
                ons{c} = ons{c}.RunTimeVars.xffID;
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                ons{c} = 'NO_VALID_XFFID_FOUND';
            end
        end
        fm = findfirst(strcmpi(dspec, ons));
    end
    ons = {o(:).F};
    if isempty(fm)
        fm = findfirst(strcmpi(dspec, ons));
    end
    if isempty(fm)
        for c = 1:numel(ons)
            [p, f, e] = fileparts(ons{c});
            ons{c} = [f, e];
        end
        [p, f, e] = fileparts(dspec);
        f = [f, e];
        fm = findfirst(strcmpi(f, ons));
    end
    if ~isempty(fm)
        hfile = xff(0, 'makeobject', struct('L', o(fm).L));
    else
        error( ...
            'xff:LookupError', ...
            'Error finding file %s in object list.', ...
            dspec ...
        );
    end

% invalid double index lookup
elseif numel(dspec) ~= 1 || ...
    isinf(dspec) || ...
    isnan(dspec) || ...
    dspec < 1 || ...
    dspec > numel(o)
    error( ...
        'xff:LookupError', ...
        'Invalid Document index given.' ...
    );

% valid index
else

    % make object
    hfile = xff(0, 'makeobject', struct('L', o(round(dspec)).L));
end
