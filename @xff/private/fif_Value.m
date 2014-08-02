function v = fif_Value(hfile, tag, varargin)
% FIF::Value  - retrieve value from FIF
%
% FORMAT:       value = fif.Value(tag)
%
% Input fields:
%
%       tag         string specifying the tagname (datakind), e.g.
%                   - NrOfChannels
%                   - SamplingFrequency
%                   - StimulusChannels
%
% Output fields:
%
%       value       element of read FIF structure

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

% persistent variable
persistent fif_lookup;
if isempty(fif_lookup)
    fl = fifio(0, 'fif_kinds');
    fif_lookup = fl.Lookup;
end
fl = fif_lookup.Datakind;

% argument check
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'fif') || ...
   ~ischar(tag) || ...
    isempty(tag)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
tag = tag(:)';
bc = xffgetcont(hfile.L);

% don't accept unknown tags
if ~isfield(fl, tag)
    warning( ...
        'xff:UnknownTag', ...
        'Unknown tag: %s.', ...
        tag ...
    );
    v = [];
    return;
end

% lookup tag
fif = bc.FIFStructure;
vpos = find(fif.Lookup == fl.(tag));
if isempty(vpos)
    warning( ...
        'xff:TagNotFound', ...
        'Tag %s not found in FIF object.', ...
        tag ...
    );
end

% make sure the data is loaded
fif = fifio(fif, 'readelem', vpos);
bc.FIFStructure = fif;
xffsetcont(hfile.L, bc);

% only one element
if numel(vpos) == 1

    % value is this one's value!
    v = fif.Children(vpos).Value;

% multiple elements
else

    % put into cell array first
    v = {fif.Children(vpos).Value};

    % do not combine values if more than one!
    if numel(v{1}) ~= 1
        return;
    end

    % for structures
    if isstruct(v{1})

        % check whether all other structs share layout
        fnames = fieldnames(v{1});
        nfield = numel(fnames);

        % iterate over elements
        for ec = 2:numel(v)

            % if not match, return
            if numel(v{ec}) ~= 1 || ...
                numel(fieldnames(v{ec})) ~= nfield || ...
               ~all(strcmp(fieldnames(v{ec}), fnames))
                return;
            end
        end

        % special case, no fields
        if nfield == 0
            v{1}(2:numel(v)) = v{1};
            v = v{1};
            return;
        end

        % otherwise combine
        v{1}(numel(v)).(fnames{1}) = [];
        for ec = 2:numel(v)
            v{1}(ec) = v{ec};
        end
        v = v{1};

        % lookup certain fields?
        if nargin > 2

            % char -> value pairs
            if nargin > 3
                vstr = struct;
                for ac = 1:2:(nargin - 2)
                    if ~ischar(varargin{ac}) || ...
                        isempty(varargin{ac}) || ...
                       ~strcmp(varargin{ac}(:)', makelabel(varargin{ac}(:)'))
                        return;
                    end
                    vstr.(varargin{ac}(:)') = varargin{ac + 1};
                end
            elseif isstruct(varargin{1}) && ...
                numel(varargin{1}) == 1
                vstr = varargin{1};
            else
                vstr = struct;
            end

            % check if all fields exist
            vfld = fieldnames(vstr);
            if isempty(vfld)
                return;
            end
            for fc = 1:numel(vfld)
                if ~isfield(v, vfld{fc})
                    return;
                end
            end

            % check each struct
            try
                for ec = numel(v):-1:1
                    for fc = 1:numel(vfld)
                        if ~strcmp(class(v(ec).(vfld{fc})), class(vstr.(vfld{fc}))) || ...
                            numel(v(ec).(vfld{fc})) ~= numel(vstr.(vfld{fc})) || ...
                            any(v(ec).(vfld{fc})(:) ~= vstr.(vfld{fc})(:))
                            v(ec) = [];
                            break;
                        end
                    end
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
                return;
            end
        end

    % for doubles
    elseif isa(v{1}, 'double')

        % if any is not the same, return
        for ec = 2:numel(v)
            if numel(v{ec}) ~= 1 || ...
                v{ec} ~= v{1}
                return;
            end
        end

        % return just the first
        v = v{1};
    end
end
