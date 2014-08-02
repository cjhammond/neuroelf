function isf = isfield(S, F)
% xff::isfield  - overloaded method (test fieldnames)
%
% method used for testing whether a fieldname (or list of names) resolves
% to actual fieldnames in the underlying memory structure (or RunTimeVars)

% Version:  v0.9c
% Build:    12120416
% Date:     Dec-04 2012, 4:09 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2012, Jochen Weber
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

% only valid if not empty
if isempty(S)
    isf = false;
    return;
end
sfile = struct(S);

% if S is not 1x1 or F is a cell array error out
if numel(sfile) ~= 1 && ...
    iscell(F)
    error( ...
        'xff:InvalidSyntax', ...
        'fieldnames cannot be called with multiple object and fields.' ...
    );
end

% sanity check
if isempty(F) || ...
  (~ischar(F) && ...
   ~iscell(F))
    error( ...
        'xff:BadArgument', ...
        'F must be either a single fieldname or a list of fieldnames.' ...
    );
end
if ischar(F)
    F = {F(:)'};
end
F = F(:)';
for fc = 1:numel(F)
    if ~ischar(F{fc}) || ...
        isempty(F{fc}) || ...
       ~strcmp(makelabel(F{fc}(:)'), F{fc}(:)')
        error( ...
            'xff:BadArgument', ...
            'Invalid fieldname: ''%s''.', ...
            F{fc}(:)' ...
        );
    end
    F{fc} = F{fc}(:)';
end

% single object
if numel(sfile) == 1

    % create output
    isf = false(size(F));

    % return original names
    sc = xffgetscont(sfile.L);
    names = fieldnames(sc.C);

    % check for fieldnames
    for fc = 1:numel(F)
        isf(fc) = any(strcmp(names, F{fc}));
    end

% multiple objects
else

    % create output
    isf = false(1, numel(sfile));

    % iterate across objects
    for oc = 1:numel(sfile)

        % get object and test
        sc = xffgetscont(sfile(oc).L);

        % test
        isf(oc) = any(strcmp(fieldnames(sc.C), F{1}));
    end
end
