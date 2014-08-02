function hfile2 = vmp_SaveSubset(hfile, sset, nfilename)
% VMP::SaveSubset  - save a subset of maps to a new file
%
% FORMAT:       [subset] = vmp.SaveSubset(sset, newfilename)
%
% Input fields:
%
%       sset        1xN list of Maps to save
%       newfilename name for new VMP file
%
% Output fields:
%
%       subset      VMP object with sub-selection

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
if nargin ~= 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vmp') || ...
   ~isa(sset, 'double') || ...
    isempty(sset) || ...
    any(isinf(sset(:)') | isnan(sset(:)') | fix(sset(:)') ~= sset(:)') || ...
    any(sset(:)' < 1) || ...
   ~ischar(nfilename) || ...
    isempty(nfilename)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);

% correctly get arguments
sset = unique(min(sset(:), bc.NrOfMaps));
if isempty(sset)
    error( ...
        'xff:BadArgument', ...
        'No maps to save remain.' ...
    );
end

% copy hfile but only wanted maps
try
    hfile2 = aft_CopyObject(hfile);
catch ne_eo;
    rethrow(ne_eo);
end
bc2 = xffgetcont(hfile.L);
bc2.Map = bc.Map(sset(:)');
bc2.NrOfMaps = numel(bc2.Map);
xffsetcont(hfile2.L, bc2);

% try to save
try
    aft_SaveAs(hfile2, nfilename(:)');
catch ne_eo;
    warning( ...
        'xff:InternalError', ...
        'Error saving maps to new file: ''%s''.', ...
        ne_eo.message ...
    );
end

% remove object from memory
aft_ClearObject(hfile2);
