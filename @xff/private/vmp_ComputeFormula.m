function hfile = vmp_ComputeFormula(hfile, formula, opts)
% VMP::ComputeFormula  - compute a new map from existing VMP maps
%
% FORMAT:       [vmp = ] vmp.ComputeFormula(formula [, opts])
%
% Input fields:
%
%       formula     string giving a formula, supporting the following
%                   #i -> .Map(i).VMPData
%                   $i -> .Map(opts.mapsel(i)).VMPData
%                   whereas i can be a single number, or a valid range
%                   using the i1:i2 or i1:s:i2 format
%       opts        optional settings
%       .mapsel     sub-selection of maps (for enhanced indexing)
%       .name       set target map name to name
%       .pvalues    flag, if true, convert maps to pvalues
%       .source     map used as template, default first map encountered
%       .target     specify a target map index (otherwise added at end)
%                   - additionally all other Map. subfields are accepted
%
% Output fields:
%
%       vmp         VMP with added/replaced map
%
% Note:

% Version:  v0.9d
% Build:    14072414
% Date:     Jul-24 2014, 2:34 PM EST
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
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vmp') || ...
   ~ischar(formula) || ...
    isempty(formula)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
formula = formula(:)';

% get content
bc = xffgetcont(hfile.L);
maps = bc.Map(:);
nummaps = numel(maps);

% check options
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
mnames = lsqueeze({maps(:).Name});
if ~isfield(opts, 'mapsel') || ...
   ((~isa(opts.mapsel, 'double') || ...
     any(isinf(opts.mapsel(:)) | isnan(opts.mapsel(:)) | opts.mapsel(:) < 1 | ...
         opts.mapsel(:) > nummaps | opts.mapsel(:) ~= fix(opts.mapsel(:)))) && ...
    (~ischar(opts.mapsel) || ...
     isempty(opts.mapsel)))
    opts.mapsel = [];
elseif isa(opts.mapsel, 'double')
    opts.mapsel = opts.mapsel(:);
else
    opts.mapsel = ~cellfun('isempty', regexpi(mnames, opts.mapsel(:)'));
end
if ~isempty(opts.mapsel)
    selmnames = mnames(opts.mapsel);
end
if ~isfield(opts, 'name') || ...
   ~ischar(opts.name) || ...
    numel(opts.name) ~= size(opts.name, 2)
    opts.name = formula;
end
if ~isfield(opts, 'pvalues') || ...
   ~islogical(opts.pvalues) || ...
    numel(opts.pvalues) ~= 1
    opts.pvalues = false;
end
if ~isfield(opts, 'source') ||...
   ~isa(opts.source, 'double') || ...
    numel(opts.source) ~= 1 || ...
    isinf(opts.source) || ...
    isnan(opts.source) || ...
    opts.source < 1 || ...
    opts.source > nummaps || ...
    opts.source ~= fix(opts.source)
    opts.source = [];
end
if ~isfield(opts, 'target') || ...
   ~isa(opts.target, 'double') || ...
    numel(opts.target) ~= 1 || ...
    isinf(opts.target) || ...
    isnan(opts.target) || ...
    opts.target < 1 || ...
    opts.target > (nummaps + 1)
    opts.target = nummaps + 1;
else
    opts.target = fix(opts.target);
end

% parse formula
try
    oformula = formula;
    if any(formula == '$') && ...
       ~isempty(opts.mapsel)
        formula = strrep(formula, ':$', sprintf(':%d', numel(opts.mapsel)));
        if ~opts.pvalues
            formula = parseformula(formula, ...
                '$', 'bc.Map($).VMPData', 4, opts.mapsel);
        else
            formula = parseformula(formula, ...
                '$', 'mappvalue(bc.Map($).VMPData, bc.Map($))', 4, opts.mapsel);
        end
    end
    if any(formula == '#')
        if ~opts.pvalues
            formula = parseformula(formula, ...
                '#', 'bc.Map(#).VMPData', 4, 1:nummaps);
        else
            formula = parseformula(formula, ...
                '#', 'mappvalue(bc.Map(#).VMPData, bc.Map(#))', 4, 1:nummaps);
        end
    end
catch ne_eo;
    rethrow(ne_eo);
end

% valid formula?
fm = strfind(formula, 'bc.Map(');
if isempty(fm)
    error( ...
        'xff:BadArgument', ...
        'Formula didn''t produce any indexing operation.' ...
    );
end

% get first map if necessary
if isempty(opts.source)
    [fns, fne] = regexp(formula(fm(1):end), '\d+');
    opts.source = str2double(formula((fm(1)-1) + (fns(1):fne(1))));
end

% try to perform computation
try
    newmap = bc.Map(opts.source);
    newmap.VMPDataCT = [];
    newmap.RunTimeVars.Formula = oformula;
    newmap.RunTimeVars.FormulaSelection = {opts.mapsel, selmnames, mnames};
    if ~opts.pvalues
        newmap.VMPData = single(eval(formula));
    else
        newmap.VMPData = single(mappvalue(eval(formula), newmap, true));
    end
catch ne_eo;
    error( ...
        'xff:BadArgument', ...
        'Error computing formula: ''%s''.', ...
        ne_eo.message ...
    );
end

% set fields
of = fieldnames(opts);
mf = fieldnames(newmap);
for fc = 1:numel(mf)
    fm = findfirst(strcmpi(of, mf{fc}));
    if ~isempty(fm)
        newmap.(mf{fc}) = opts.(of{fm});
    end
end

% also extend MapParameter if needed
if ~isempty(bc.MapParameter)
    for fc = 1:numel(bc.MapParameter)
        if numel(bc.MapParameter(fc).Values) < opts.target
            bc.MapParameter(fc).Values(end+1:opts.target) = ...
                bc.MapParameter(fc).Values(opts.source);
        end
    end
end

% set into target
bc.Map(opts.target) = newmap;
bc.NrOfMaps = numel(bc.Map);
bc.RunTimeVars.AutoSave = true;
xffsetcont(hfile.L, bc);
