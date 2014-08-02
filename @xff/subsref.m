function [varargout] = subsref(hfile, S)
% xff::subsref  - overloaded method
%
% Usage is either for methods
%
% object.method(arguments)
%
%  - or properties
%
% object.property

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:11 AM EST
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

% global storage
global xffclup;
global xffconf;
global xffcont;

% persistent methods
persistent xffmeth;
if isempty(xffmeth)
    xffmeth = xff(0, 'methods');
end

% argument check
if nargin < 2 || ...
   ~isstruct(S) || ...
    isempty(S)
    error( ...
        'xff:BadSubsRef', ...
        'No S struct given or empty.' ...
    );
end

% get structed version
sfile = struct(hfile);

% for multiple objects
nfile = numel(hfile);
if nfile > 1 && ...
    ~strcmp(S(1).type, '()')
    varargout = cell(size(sfile));
    for oc = 1:nfile
        try
            varargout{oc} = subsref(xff(0, 'makeobject', sfile(oc)), S);
        catch ne_eo;
            error( ...
                'xff:InternalError', ...
                'Error passing subsref to object %d: %s.', ...
                oc, ne_eo.message ...
            );
        end
    end
    return;
end

% unwind stack
if xffconf.unwindstack
    xffunwindstack;
end

% default varargout
varargout = cell(1, nargout);
if nargout < 1
    varargout = {};
end

% what type of subsref
slen  = length(S);
stype = S(1).type;
ssubs = S(1).subs;
switch (stype)

    % struct notation
    case {'.'}

        % find lookup
        ifile = find(xffclup == sfile.L);

        % already cleared...
        if isempty(ifile)
            error( ...
                'xff:InvalidObject', ...
                'Object removed from memory.' ...
            );
        end

        % allow cell with one char call type
        if iscell(ssubs) && ...
            numel(ssubs) == 1
            ssubs = ssubs{1};
        end

        % check for subscript type
        if ~ischar(ssubs) || ...
            isempty(ssubs)
            error( ...
                'xff:BadSubsRef', ...
                'Struct notation needs a non-empty char property.' ...
            );
        end

        % only works for singular object
        if length(hfile) ~= 1
            error( ...
                'xff:InvalidInputSize', ...
                'Struct notation works only on singular objects.' ...
            );
        end

        % make content linear
        ssubs = ssubs(:)';

        % try different things
        try

            % get file type for methods
            ftype = lower(xffcont(ifile).S.Extensions{1});

            % methods
            if isfield(xffmeth, ftype) && ...
                isfield(xffmeth.(ftype), lower(ssubs))
                if slen > 1 && ...
                    strcmp(S(2).type, '()')
                    fargs = S(2).subs;
                    S(2)  = [];
                    slen  = length(S);
                else
                    fargs = {};
                end
                try
                    if slen > 1
                        [varargout{1}] = feval( ...
                              xffmeth.(ftype).(lower(ssubs)){6}, hfile, fargs{:});
                    else
                        if nargout > 0
                            [varargout{1:nargout}] = feval( ...
                                  xffmeth.(ftype).(lower(ssubs)){6}, hfile, fargs{:});
                        else
                            [varargout{1}] = feval( ...
                                  xffmeth.(ftype).(lower(ssubs)){6}, hfile, fargs{:});
                        end
                    end
                catch ne_eo;
                    rethrow(ne_eo);
                end

                % if no more args in S
                if slen < 2
                    return;
                end

            % methods of "any type"
            elseif isfield(xffmeth.aft, lower(ssubs)) && ...
               (any(strcmpi(ftype, xffmeth.aft.(lower(ssubs)){5})) || ...
                strcmpi(xffmeth.aft.(lower(ssubs)){5}{1}, 'all'))
                if slen > 1 && ...
                    strcmp(S(2).type, '()')
                    fargs = S(2).subs;
                    S(2)  = [];
                    slen  = length(S);
                else
                    fargs = {};
                end
                try
                    if slen > 1
                        [varargout{1}] = feval( ...
                              xffmeth.aft.(lower(ssubs)){6}, hfile, fargs{:});
                    else
                        if nargout > 1
                            [varargout{1:nargout}] = feval( ...
                                  xffmeth.aft.(lower(ssubs)){6}, hfile, fargs{:});
                        else
                            [varargout{1}] = feval( ...
                                  xffmeth.aft.(lower(ssubs)){6}, hfile, fargs{:});
                        end
                    end
                catch ne_eo;
                    rethrow(ne_eo);
                end

                % if no more args in S and non empty input name
                if slen < 2
                    return;
                end
            else
                try
                    if isfield(xffcont(ifile).C, ssubs)
                        varargout{1} = xffcont(ifile).C.(ssubs);
                    elseif isfield(xffcont(ifile).C.RunTimeVars, ssubs)
                        varargout{1} = xffcont(ifile).C.RunTimeVars.(ssubs);
                    elseif numel(xffcont(ifile).S.DefaultProperty) > 1 && ...
                        sum(xffcont(ifile).S.DefaultProperty{2} == '%') == 1 && ...
                        sum(xffcont(ifile).S.DefaultProperty{2} == '%') == 1
                        subsrepl = eval(strrep(strrep( ...
                            xffcont(ifile).S.DefaultProperty{2}, ...
                            '%', ssubs), '@', 'xffcont(ifile).C.'));
                        varargout{1} = eval(strrep(strrep( ...
                            xffcont(ifile).S.DefaultProperty{1}, ...
                            '%', 'subsrepl'), '@', 'xffcont(ifile).C.'));
                    else

                        % try a "catch-abbreviation"
                        meths = {};
                        if isfield(xffmeth, ftype)
                            meths = fieldnames(xffmeth.(ftype));
                        end
                        meths = [meths; fieldnames(xffmeth.aft)];
                        methi = find(~cellfun('isempty', regexpi(meths, ['^', lower(ssubs)])));
                        if numel(methi) ~= 1
                            error( ...
                                'xff:UnknownFieldOrMethod', ...
                                'Field or method %s unknown for type %s objects.', ...
                                ssubs, upper(ftype) ...
                            );
                        end

                        % re-call
                        S(1).subs = meths{methi};
                        if slen > 1
                            eval('varargout{1}=subsref(hfile, S);');
                        else
                            if nargout > 1
                                eval('[varargout{1:nargout}]=subsref(hfile, S);');
                            else
                                eval('varargout{1}=subsref(hfile, S);');
                            end
                        end
                        return;
                    end
                catch ne_eo;
                    rethrow(ne_eo);
                end
            end
        catch ne_eo;
            rethrow(ne_eo);
        end

        % more sub-indexing ?
        if slen > 1
            try

                % make sure that multiple arguments are OK
                if slen > 2 && ...
                    strcmp(S(end-1).type, '()') && ...
                    strcmp(S(end).type, '.')
                    if nargout > 0
                        [varargout{1:nargout}] = subsref(varargout{1}, S(2:end));
                    else
                        varargout{1} = subsref(varargout{1}, S(2:end));
                    end
                else
                    varargout{1} = subsref(varargout{1}, S(2:end));
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);

                % still allow {1} for strings
                if ischar(varargout{1}) && ...
                    numel(S) == 2 && ...
                    strcmp(S(2).type, '{}')
                    try
                        varargout{1} = subsref({varargout{1}}, S(2));
                    catch ne_eo;
                        rethrow(ne_eo);
                    end
                    return;
                end

                % try to perform a "safe-subsref"
                try
                    outnum = 1;
                    for sc = 2:numel(S)
                        if isstruct(varargout{1}) && ...
                            strcmpi(S(sc).type, '.') && ...
                            numel(varargout{1}) ~= 1
                            if outnum > 1
                                error( ...
                                    'xff:BadSubsRef', ...
                                    'Invalid multi-indexing.' ...
                                );
                            end
                            eval(['outval = {varargout{1}.' S(sc).subs ';']);
                            outnum = numel(outval);
                            for oc = 1:numel(outval)
                                varargout{oc} = outval{oc};
                            end
                        elseif iscell(varargout{1}) && ...
                            strcmpi(S(sc).type, '{}')
                            if outnum > 1
                                error( ...
                                    'xff:BadSubsRef', ...
                                    'Invalid multi-indexing.' ...
                                );
                            end
                            eval(['outval = {varargout{1}' any2ascii(S(sc).subs) '};']);
                            outnum = numel(outval);
                            for oc = 1:numel(outval)
                                varargout{oc} = outval{oc};
                            end
                        else
                            for oc = 1:outnum
                                varargout{oc} = subsref(varargout{oc}, S(sc));
                            end
                        end
                    end
                    return;
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end

                % generate an error message
                error( ...
                    'xff:IllegalSubsRef', ...
                    'Couldn''t pass further subscripting to property value.' ...
                );
            end
        end

    case {'()'}

        % we need non-empty cell subscript
        if ~iscell(ssubs) || ...
            isempty(ssubs)
            error( ...
                'xff:BadSubsRef', ...
                'Can''t index into xff array.' ...
            );
        end

        % for singular object, try default property!
        if numel(sfile) == 1
            sfiles = xffgetscont(sfile.L);
            if numel(sfiles.S.DefaultProperty) == 1
                try
                    Sa = S(1);
                    Sa.type = '.';
                    Sa.subs = sfiles.S.DefaultProperty{1};
                    S = [Sa; S(:)];
                    if nargout < 1
                        varargout{1} = subsref(hfile, S);
                    else
                        [varargout{1:nargout}] = subsref(hfile, S);
                    end
                    return;
                catch ne_eo;
                    rethrow(ne_eo);
                end
            end
        end

        % try to retrieve subscripted matrix
        try
            subset = subsref(sfile, S(1));
            hfile  = xff(0, 'makeobject', subset);
        catch ne_eo;
            error( ...
                'xff:BadSubsRef', ...
                'Invalid subscript error (%s).', ...
                ne_eo.message ...
            );
        end

        % return sub-matrix if only one subscript
        if slen == 1
            varargout{1} = hfile;
            return;
        end

        % try to pass subscripts
        try
            varargout = cell(size(hfile));
            for oc = 1:numel(hfile)
                varargout{oc} = subsref(hfile(oc), S(2:end));
            end
        catch ne_eo;
            rethrow(ne_eo);
        end
    otherwise
        error( ...
            'xff:BadSubsRef', ...
            'Only struct and array index subsref allowed.' ...
        );
end
