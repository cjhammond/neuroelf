% FUNCTION ne_setsceneprops: set properties of scenery content
function varargout = ne_setsceneprops(varargin)

% Version:  v0.9d
% Build:    14062614
% Date:     Jun-26 2014, 2:27 PM EST
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

% global variable
global ne_gcfg;

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% scenery selection
ch = ne_gcfg.h;
sci = ch.Scenery.Value;
scu = ch.Scenery.UserData;
if numel(sci) ~= 1 || ...
   ~isxff(scu{sci, 4}, 'srf')
    return;
end
sco = scu{sci, 4};
sch = handles(sco);
scp = sch.SurfProps;

% translation, rotation, scaling, and alpha
tra = scp{1};
rot = (180 / pi) .* scp{2};
scl = scp{3};
alp = scp{4};
if scp{7}(1) == 'n'
    dvp = 'no';
else
    dvp = 'yes';
end

% request updated values
newv = inputdlg({ ...
    'Translation (X, Y, Z):', ...
    'Rotation (degrees):', ...
    'Scaling factors (X, Y, Z):', ...
    'Alpha (transparency)', ...
    'Display surface as (f)aces or (w)ireframe', ...
    'Display vertex coordinate points (yes/no)'}, ...
    'NeuroElf GUI - set surface properties within scene', 1, ...
    {sprintf('  %g', tra), sprintf('  %g', rot), sprintf('  %.3f', scl), ...
     sprintf('  %.3f', alp), ['  ' scp{5}], ['  ' dvp]});

% cancelled
if isempty(newv) || ...
   ~iscell(newv) || ...
    numel(newv) ~= 6;
    return;
end

% process new settings
try
    tra = eval(['[' newv{1} ']']);
    rot = eval(['[' newv{2} ']']);
    scl = eval(['[' newv{3} ']']);
    alp = str2double(newv{4});
    fow = newv{5};
    fow(fow == ' ') = '';
    dvp = newv{6};
    dvp(dvp == ' ') = '';
    if numel(tra) ~= 3 || ...
        any(isinf(tra) | isnan(tra) | tra < -256 | tra > 256) || ...
        numel(rot) ~= 3 || ...
        any(isinf(rot) | isnan(rot) | rot < -360 | rot > 360) || ...
        numel(scl) ~= 3 || ...
        any(isinf(scl) | isnan(scl) | abs(scl) < 0.2 | abs(scl) > 5) || ...
        numel(alp) ~= 1 || ...
        isinf(alp) || ...
        isnan(alp) || ...
        alp < 0 || ...
        alp > 1 || ...
        numel(fow) ~= 1 || ...
       ~any('fw' == lower(fow)) || ...
        isempty(dvp) || ...
       ~any('ny' == lower(dvp(1)))
        return;
    end

    % adapt rotation to radiens
    rot = (pi / 180) .* rot(:)';

    % if valid, make permanent
    if lower(dvp(1)) == 'y'
        dvp = 'flat';
    else
        dvp = 'none';
    end
    sco.SetHandle('SurfProps', {tra(:)', rot, scl(:)', alp, lower(fow), [], dvp});

    % and update screen
    ne_setsurfpos(0, 0, true);
catch ne_eo;
    ne_gcfg.c.lasterr = ne_eo;
    return;
end
