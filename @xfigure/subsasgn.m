function hFigure = subsasgn(hFigure, S, V)
% xfigure::subsasgn  - set properties on objects
%
% FORMAT:       FigureObject.PropertyName = Value

% Version:  v0.9c
% Build:    11050319
% Date:     May-02 2011, 6:17 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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

% class check
if nargin > 2 && ...
    ~isa(hFigure, 'xfigure')
    try
        hFigure = builtin('subsasgn', hFigure, S, V);
    catch ne_eo;
        rethrow(ne_eo);
    end
    return;
end

% argument check
if isempty(S)
    error( ...
        'xfigure:BadSubsAsgn', ...
        'S struct may not be empty.' ...
    );
end
slen  = length(S);
stype = S(1).type;
ssubs = S(1).subs;

% decide on kind of subscripting, first struct-like notation
switch stype, case {'.'}

    % allow cell with one char call type
    if iscell(ssubs) && ...
        numel(ssubs) == 1
        ssubs = ssubs{1};
    end

    % check for subscript type
    if ~ischar(ssubs) || ...
        isempty(ssubs)
        error( ...
            'xfigure:BadSubsAsgn', ...
            'Struct notation needs a non-empty char property.' ...
        );
    end

    % only works for singular object
    if numel(hFigure) ~= 1
        error( ...
            'xfigure:InvalidObjectSize', ...
            'Struct notation only works on singular objects.' ...
        );
    end

    % make content linear
    ssubs = ssubs(:)';

    % set complete property
    if slen == 1

        % try setting value
        try
            if strcmpi(get(hFigure.mhnd, 'Type'), 'axes') && ...
                strcmpi(ssubs, 'visible')
                set(get(hFigure.mhnd, 'Children'), 'Visible', V);
                xfigure(hFigure, 'Set', 'Visible', V);
            else
                set(hFigure.mhnd, ssubs, V);
            end
        catch ne_eo;
            oeo = ne_eo;
            if ~isempty(strfind(lower(ne_eo.identifier), 'invalidproperty')) || ...
               (isempty(ne_eo.identifier) && ...
                ~isempty(regexpi(ne_eo.message, 'no ''\w+'' property in')))
                try
                    set(get(hFigure.mhnd, 'Children'), ssubs, V);
                    if strcmpi(ssubs, 'cdata')
                        set(hFigure.mhnd, 'XLim', [0.5, 0.5 + size(V, 2)]);
                        set(hFigure.mhnd, 'YLim', [0.5, 0.5 + size(V, 1)]);
                    end
                    return;
                catch ne_eo;
                    neuroelf_lasterr(ne_eo);
                end
            end
            rethrow(oeo);
        end

    % set sub value
    else

        % for TagStruct use alternative approach
        if strcmpi(ssubs, 'tagstruct')
            ts = xfigure(hFigure, 'TagStruct');
            to = subsref(ts, S(2));
            subsasgn(to, S(3:end), V);
            return;
        end

        % try getting, altering and re-setting value
        try
            cV = get(hFigure.mhnd, ssubs);
            cV = subsasgn(cV, S(2:end), V);
            set(hFigure.mhnd, ssubs, cV);
        catch ne_eo;
            rethrow(ne_eo);
        end
    end

% indexing requested
case {'()'}

    % we need non-empty cell subscript
    if ~iscell(ssubs) || ...
        isempty(ssubs)
        error( ...
            'xfigure:BadSubsRef', ...
            'Can''t index into xfigure matrix.' ...
        );
    end

    % convert hFigure to struct
    sFigure = struct(hFigure);

    % try to retrieve subscripted matrix
    try
        subset   = subsref(sFigure, S(1));
    catch ne_eo;
        error( ...
            'BQVXfigure:BadSubsRef', ...
            'Invalid subscript (%s).', ...
            ne_eo.message ...
        );
    end

    % no further subsasgn requested
    if slen == 1
        if ~strcmpi(class(V), 'xfigure')
            error( ...
                'xfigure:BadSubsAsgnValue', ...
                'Class mismatch error.' ...
            );
        end

        % try to assign new objects into matrix
        try
            sFigure = subsasgn(sFigure, S(1), struct(V));
            hFigure = class(sFigure, 'xfigure');
        catch ne_eo;
            error( ...
                'xfigure:BadSubsAsgnIndex', ...
                'Couldn''t assign partial object matrix (%s).', ...
                ne_eo.message ...
            );
        end
        return;
    end

    if numel(subset) ~= 1
        error( ...
            'xfigure:InvalidObjectSize', ...
            'Further subscripting only works for singular objects.' ...
        );
    end

    try
        subsasgn(class(subset, 'xfigure'), S(2:end), V);
    catch ne_eo;
        error( ...
            'xfigure:BadSubsAsgnSubs', ...
            'Error passing subsasgn to object (%s).', ...
            ne_eo.message ...
        );
    end

otherwise
    error( ...
        'xfigure:BadSubsAsgn', ...
        'Only struct notation allowed to set values.' ...
    );
end
