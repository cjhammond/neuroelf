function [rvalue] = subsref(hFigure, S)
% xfigure::subsref  - retrieve property via struct notation
%
% FORMAT:       propvalue = FigureObject.PropertyName
%
% Also, the subsref construct can be used as an alternative way of
% calling an object method:
%
% FORMAT:       hFigure.MethodName([Arguments]);
%
% Since method names are checked first, Parent() returns the parent
% object reference, not MABLAB's parent GUI handle !

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

% get method names for alias properties
global xfiguremeth;
if isempty(xfiguremeth)
    try
        methods(hFigure);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end

% argument check
if isempty(S)
    error( ...
        'xfigure:BadSubsRef', ...
        'S struct may not be empty.' ...
    );
end
slen  = length(S);
stype = S(1).type;
ssubs = S(1).subs;

% decide on kind of subscripting, first struct-like notation
switch stype
    case {'.'}

        % allow cell with one char call type
        if iscell(ssubs) && ...
            numel(ssubs) == 1
            ssubs = ssubs{1};
        end

        % check for subscript type
        if ~ischar(ssubs) || ...
            isempty(ssubs)
            error( ...
                'xfigure:BadSubsRef', ...
                'Struct notation needs a non-empty char property.' ...
            );
        end

        % only works for singular object
        if numel(hFigure) ~= 1
            error( ...
                'xfigure:InvalidInputSize', ...
                'Struct notation works only on singular objects.' ...
            );
        end

        % make content linear
        ssubs = ssubs(:)';

        % try to retrieve value
        try
            if any(strcmpi(ssubs, fieldnames(xfiguremeth.m)))
                if slen > 1 && ...
                    strcmp(S(2).type, '()')
                    fargs = S(2).subs;
                    S(2)  = [];
                    slen  = length(S);
                else
                    fargs = {};
                end
                rvalue = xfigure(hFigure, lower(ssubs), fargs{:});
            else
                rvalue = xfigure(hFigure, 'Get', ssubs);
            end
        catch ne_eo;
            rethrow(ne_eo);
        end

        % more sub-indexing ?
        if slen > 1
            try
                if slen > 2 && ...
                    strcmpi(ssubs, 'tagstruct') && ...
                    strcmp(S(2).type, '.') && ...
                    ischar(S(2).subs)
                    rvalue = rvalue.(S(2).subs);
                    rvalue = subsref(rvalue, S(3:end));
                else
                    rvalue = subsref(rvalue, S(2:end));
                end
            catch ne_eo;
                error( ...
                    'xfigure:IllegalSubsRef', ...
                    'Couldn''t pass further subscripting to property value: %s.', ...
                    ne_eo.message ...
                );
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
            subset  = subsref(sFigure, S(1));
            hFigure = class(subset, 'xfigure');
        catch ne_eo;
            error( ...
                'xfigure:BadSubsRef', ...
                'Invalid subscript error (%s).', ...
                ne_eo.message ...
            );
        end

        % return sub-matrix if only one subscript
        if slen == 1
            rvalue = hFigure;
            return;
        end

        if numel(hFigure) ~= 1
            error( ...
                'xfigure:InvalidObjectSize', ...
                'Further subscripting is only valid for singular objects.' ...
            );
        end

        % try to pass subscripts
        try
            rvalue = subsref(hFigure, S(2:end));
        catch ne_eo;
            rethrow(ne_eo);
        end

    otherwise
        error( ...
            'xfigure:BadSubsRef', ...
            'Only struct notation allowed to retrieve values.' ...
        );
end
