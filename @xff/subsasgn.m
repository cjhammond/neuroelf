function hfile = subsasgn(hfile, S, V)
% xff::subsasgn  - overloaded method
%
% used to update properties in objects
%
% vmr.DimX = 512;
%
% if the Update method (vmr_Update in this case) is available,
% it will be called, unless the update function has been disabled
% with xff(0, 'updatedisable', 'vmr');

% Version:  v0.9d
% Build:    14061918
% Date:     Jun-19 2014, 6:29 PM EST
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

% global storage and config
global xffclup;
global xffconf;
global xffcont;

% persistent methods
persistent xffmeth;
if isempty(xffmeth)
    xffmeth = xff(0, 'methods');
end

% class check
if nargin > 2 && ...
    ~isa(hfile, 'xff')
    try
        hfile = builtin('subsasgn', hfile, S, V);
    catch ne_eo;
        rethrow(ne_eo);
    end
    return;
end

% argument check
if nargin < 3 || ...
   isempty(S)
    error( ...
        'xff:BadSubsAsgn', ...
        'S struct must not be empty.' ...
    );
end

% get struct version and good fieldnames
sfile = struct(hfile);

% decide on kind of subscripting, first struct-like notation
slen  = length(S);
stype = S(1).type;
ssubs = S(1).subs;
switch stype, case {'.'}

    % allow cell with one char call type
    if iscell(ssubs) && ...
        numel(ssubs) == 1
        ssubs = ssubs{1};
    end

    % check for subscript type
    if ~ischar(ssubs) || isempty(ssubs)
        error( ...
            'xff:BadSubsAsgn', ...
            'Struct notation needs a non-empty char property.' ...
        );
    end

    % only works for singular object
    if numel(hfile) ~= 1 || ...
        hfile.L == -1
        error( ...
            'xff:InvalidObjectSize', ...
            'Struct notation only works on singular non-ROOT objects.' ...
        );
    end

    % get index
    ifile = find(xffclup == hfile.L);
    if isempty(ifile)
        error( ...
            'xff:InvalidObject', ...
            'Object removed from memory.' ...
        );
    end

    % make content linear
    ssubs = ssubs(:)';

    % unless Handles is (sub-) set
    if ~strcmp(ssubs, 'Handles')

        % only allow already existing fields -> direct content
        fgood = fieldnames(xffcont(ifile).C);
        ffound = strcmpi(ssubs, fgood);

        % if not found
        if ~any(ffound)

            % also test RunTimeVars content
            fgood = fieldnames(xffcont(ifile).C.RunTimeVars);
            ffound = strcmpi(ssubs, fgood);

            % bail out if still not found
            if ~any(ffound)
                error( ...
                    'xff:InvalidProperty', ...
                    'Non-existing property for this xff type.' ...
                );
            end

            % get correct case fieldname
            ffound = find(ffound);
            ssubs = fgood{ffound(1)};

            % copied implementation (to avoid further if/else/end's!)
            % set complete property
            if slen == 1

                % try setting value
                try
                    xffcont(ifile).C.RunTimeVars.(ssubs) = V;
                catch ne_eo;
                    rethrow(ne_eo);
                end

            % set sub value
            else

                % try getting, altering and re-setting value
                try
                    xffcont(ifile).C.RunTimeVars.(ssubs) = subsasgn( ...
                        xffcont(ifile).C.RunTimeVars.(ssubs), S(2:end), V);
                catch ne_eo;
                    rethrow(ne_eo);
                end
            end

            % return early!
            return;

        % found in actual content
        else

            % get correct case fieldname
            ffound = find(ffound);
            ssubs = fgood{ffound(1)};
        end
    end

    % for update
    ftype = lower(xffcont(ifile).S.Extensions{1});
    if isfield(xffmeth, ftype) && ...
        isfield(xffmeth.(ftype), 'update') && ...
        xffconf.update.(ftype) && ...
       ~strcmp(ssubs, 'RunTimeVars') && ...
       ~strcmp(ssubs, 'Handles')
        oV = xffcont(ifile).C.(ssubs);
    end

    % set complete property
    if slen == 1

        % try setting value
        try
            xffcont(ifile).C.(ssubs) = V;
        catch ne_eo;
            rethrow(ne_eo);
        end

    % set sub value
    else

        % try getting, altering and re-setting value
        try
            if slen ~= 2 || ...
               ~strcmp(S(2).type, '()')
                xffcont(ifile).C.(ssubs) = subsasgn(xffcont(ifile).C.(ssubs), S(2:end), V);
            else
                xffcont(ifile).C.(ssubs)(S(2).subs{:}) = V;
            end
        catch ne_eo;
            neuroelf_lasterr(ne_eo);

            % handle access?
            if strcmp(ssubs, 'Handles') && ...
                strcmp(S(2).type, '.')

                % try to pass to handle
                try
                    oV = subsasgn(aft_Handles(hfile), S(2:end), V);
                    aft_SetHandle(hfile, S(2).subs, oV.(S(2).subs));
                    return;
                catch ne_eo;
                    rethrow(ne_eo);
                end

            % handle cell-array extension of string
            elseif isfield(xffcont(ifile).C, ssubs) && ...
                isa(xffcont(ifile).C(ssubs), 'char') && ...
                strcmp(S(2).type, '{}')

                % try to use on cellstr
                try
                    xffcont(ifile).C.(ssubs) = subsasgn( ...
                        {xffcont(ifile).C(ssubs)}, S(2:end), V);
                catch ne_eo;
                    rethrow(ne_eo);
                end

            % otherwise throw error
            else
                rethrow(ne_eo);
            end
        end
    end

    % perform obj_Update call ?
    ftype = lower(xffcont(ifile).S.Extensions{1});
    if isfield(xffmeth, ftype) && ...
        isfield(xffmeth.(ftype), 'update') && ...
        xffconf.update.(ftype) && ...
       ~strcmp(ssubs, 'RunTimeVars')
        try
            eval([xffmeth.(ftype).update{1} '(hfile, ssubs, S, oV);']);
        catch ne_eo;
            error( ...
                'xff:ObjectUpdateError', ...
                'Error performing object update: ''%s''.', ...
                ne_eo.message ...
            );
        end
    end

% indexing requested
case {'()'}

    % we need non-empty cell subscript
    if ~iscell(ssubs) || isempty(ssubs)
        error( ...
            'xff:BadSubsRef', ...
            'Can''t index into xff array.' ...
        );
    end

    % try to retrieve subscripted array
    try
        subset = subsref(sfile, S(1));
    catch ne_eo;
        error( ...
            'xff:BadSubsRef', ...
            'Invalid subscript (%s). Dynamic growing unavailable.', ...
            ne_eo.message ...
        );
    end

    % no further subsasgn requested
    if slen == 1
        if ~xffisobject(V, true)
            error( ...
                'xff:BadSubsAsgnValue', ...
                'Class mismatch error or invalid object.' ...
            );
        end

        % try to assign new objects into matrix
        try
            sfile = subsasgn(sfile, S(1), struct(V));
            hfile = xff(0, 'makeobject', sfile);
        catch ne_eo;
            error( ...
                'xff:BadSubsAsgnIndex', ...
                'Couldn''t assign partial object matrix (%s).', ...
                ne_eo.message ...
            );
        end

        % unwind stack
        if xffconf.unwindstack
            xff(0, 'unwindstack');
        end
        return;
    end

    % further indexing only allowed for single object
    if numel(subset) ~= 1 || ...
        subset.L == -1
        error( ...
            'xff:InvalidObjectSize', ...
            'Subscripting only works for singular, non-ROOT objects.' ...
        );
    end

    % try subsasgn
    try
        subsasgn(xff(0, 'makeobject', subset), S(2:end), V);
    catch ne_eo;
        error( ...
            'xff:BadSubsAsgnSubs', ...
            'Error passing subsasgn to object (%s).', ...
            ne_eo.message ...
        );
    end

% generally wrong
otherwise

    error( ...
        'xff:BadSubsAsgn', ...
        'Only struct notation allowed to set values.' ...
    );
end

% unwind stack
if xffconf.unwindstack
    xff(0, 'unwindstack');
end
