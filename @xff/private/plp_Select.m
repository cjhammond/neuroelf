function sel = plp_Select(hfile, cond, mask)
% PLP::Select  - select rows according to a condition
%
% FORMAT:       sel = plp.Select(cond [, mask])
%
% Input fields:
%
%       cond        conditional statement, e.g.
%                   '$Study >= 1 & $Study <= 3 & $Type == 2'
%                   whereas $names are replaced by their column data
%                   and syntax as in '$Column == ''content''' is translated
%                   into a call to strcmpi (or regexpi for patterns)
%       mask        filename to masking object (must be XFF-compatible)
%
% Output fields:
%
%       sel         Px1 boolean selection

% Version:  v0.9d
% Build:    14062015
% Date:     Jun-20 2014, 3:08 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2011, 2014, Jochen Weber
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
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'plp') || ...
   ~ischar(cond)
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
cn = bc.ColumnNames(:);
p = bc.Points;
labels = bc.Labels(:);
if numel(cn) ~= size(p, 2)
    error( ...
        'xff:BadObject', ...
        'PLP object has an invalid ColumnNames/Points combination. Please fix.' ...
    );
end
cond = ddeblank(lower(cond(:)'));
if isempty(cond)
    sel = true(size(p, 1), 1);
    return;
end
cond = ['(' cond ')'];
cregx = regexp(cond, '(\$[a-zA-Z][a-zA-Z_0-9]*\s*==\s*''[^'']+'')', 'tokens');
while ~isempty(cregx) && ...
   ~isempty(cregx{1})
    cregp = regexp(cregx{1}{1}, '^\$([a-zA-Z][a-zA-Z_0-9]*)\s*==\s*''([^'']+)''$', 'tokens');
    if ~iscell(cregp) || ...
        numel(cregp) ~= 1 || ...
       ~iscell(cregp{1}) || ...
        numel(cregp{1}) ~= 2
        error( ...
            'xff:BadArgument', ...
            'Invalid conditional statement.' ...
        );
    end
    if any(cregp{1}{2} == '*')
        cond = strrep(cond, cregx{1}{1}, sprintf( ...
            '~cellfun(''isempty'', regexpi(labels($%s), ''%s''))', cregp{1}{:}));
    else
        cond = strrep(cond, cregx{1}{1}, sprintf( ...
            'strcmpi(labels($%s), ''%s'')', cregp{1}{:}));
    end
    cregx = regexp(cond, '(\$[a-zA-Z][a-zA-Z_0-9]*\s*==\s*''[^'']+'')', 'tokens');
end
cregx = regexp(cond, '(\$[a-zA-Z][a-zA-Z_0-9]*\s*~=\s*''[^'']+'')', 'tokens');
while ~isempty(cregx) && ...
   ~isempty(cregx{1})
    cregp = regexp(cregx{1}{1}, '^\$([a-zA-Z][a-zA-Z_0-9]*)\s*~=\s*''([^'']+)''$', 'tokens');
    if ~iscell(cregp) || ...
        numel(cregp) ~= 1 || ...
       ~iscell(cregp{1}) || ...
        numel(cregp{1}) ~= 2
        error( ...
            'xff:BadArgument', ...
            'Invalid conditional statement.' ...
        );
    end
    if any(cregp{1}{2} == '*')
        cond = strrep(cond, cregx{1}{1}, sprintf( ...
            'cellfun(''isempty'', regexpi(labels($%s), ''%s''))', cregp{1}{:}));
    else
        cond = strrep(cond, cregx{1}{1}, sprintf( ...
            '~strcmpi(labels($%s), ''%s'')', cregp{1}{:}));
    end
    cregx = regexp(cond, '(\$[a-zA-Z][a-zA-Z_0-9]*\s*~=\s*''[^'']+'')', 'tokens');
end
cnl = zeros(numel(cn), 1);
for cnc = 1:numel(cn)
    cnl(cnc) = numel(cn{cnc});
end
[cnl, cni] = sort(cnl, 'descend');
cns = cn(cni);
for cnc = 1:numel(cn)
    cond = strrep(cond, ['$' lower(cns{cnc})], sprintf('p(:,%d)', cni(cnc)));
end

% then parse condition
try
    sel = eval(cond);
catch ne_eo;
    error( ...
        'xff:BadArgument', ...
        'Bad condition given: %s.', ...
        ne_eo.message ...
    );
end

% no additional masking
if nargin < 3 || ...
   ~ischar(mask) || ...
    isempty(mask) || ...
    exist(mask(:)', 'file') ~= 2

    % return early
    return;
end

% get XYZ columns
xc = findfirst(strcmpi(cn, 'x'));
if isempty(xc)
    xc = 1;
end
yc = findfirst(strcmpi(cn, 'y'));
if isempty(xc)
    yc = 2;
end
zc = findfirst(strcmpi(cn, 'z'));
if isempty(xc)
    zc = 3;
end
xyz = [xc, yc, zc];

% try to temporarily load mask
msko = {[]};
try
    msko{1} = xff(mask(:)');
    if ~xffisobject(msko{1}, true, {'hdr', 'msk', 'vmr'})
        error( ...
            'xff:BadArgument', ...
            'Argument ''mask'' must specify a valid masking object.' ...
        );
    end

    % apply additional selection
    sel = sel & (aft_SampleData3D(msko{1}, p(:, xyz), struct('method', 'linear')) >= 0.5);
catch ne_eo;
    clearxffobjects(msko);
    rethrow(ne_eo);
end

% clear masking object
clearxffobjects(msko);
