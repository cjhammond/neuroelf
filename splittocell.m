function [linetocell, cellcount] = splittocell(line, delimiter, varargin)
% splittocell  - split a delimited string into a cell array
%
% usage is straight forward:
%
% FORMAT:         [out, cnt] = splittocell(string [,delims, md, ad, hq])
%
% Input fields:
%    string       1xN char array to split
%    delims       char array containing one or more delimiters
%                 if left empty -> char(9) == <TAB>
%    md           must be '1' (numeric) to be effective, if set
%                 multiple delimiters will be treated as one
%    ad           match any of the delimiters (for multi-char
%                 delimiters strings)
%    hq           must be '1' (numeric) to be effective, if set
%                 delimiters within quotes will be ignored, sets
%                 md and ad to false!
%
% Output fields:
%    out          cell array containing the tokens after split
%    cnt          number of tokens in result
%
% See also gluetostring.
%
% Note: this is the function equivalent to splittocellc, written in
%       Matlab code for situations where the MEX file is not yet
%       compiled. Once this is done, functions use the faster one.

% Version:  v0.9a
% Build:    10051716
% Date:     May-17 2010, 10:48 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, Jochen Weber
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
if nargin < 1
    error( ...
        'neuroelf:TooFewArguments', ...
        'Too few arguments. Try ''help %s''.', ...
        mfilename ...
    );
end

% initialize return values and varargin{3}
linetocell = cell(0);
cellcount  = 0;
multidelim = false;
anydelim   = false;
heedquotes = false;

% do we have useful input ?
if isempty(line)
    return;
end
if ~ischar(line) || ...
    size(line, 2) ~= numel(line)
    error( ...
        'neuroelf:BadArgument', ...
        'Input must be a 1xN shaped char array!' ...
    );
end

% reset cellcount
cellcount = 1;

% are any other arguments specified
if nargin < 2 || ...
   ~ischar(delimiter)
    delimiter = char(9);
else
    delimiter = delimiter(:)';
end
if nargin > 2 && ...
   ~isempty(varargin{1}) && ...
   (isnumeric(varargin{1}) || ...
    islogical(varargin{1})) && ...
    varargin{1}(1)
    multidelim = true;
end
if nargin > 3 && ...
   ~isempty(varargin{2}) && ...
   (isnumeric(varargin{2}) || ...
    islogical(varargin{2})) && ...
    varargin{2}(1)
    anydelim = true;
end
if nargin > 4 && ...
   ~isempty(varargin{3}) && ...
   (isnumeric(varargin{3}) || ...
    islogical(varargin{3})) && ...
    varargin{3}(1)
    heedquotes = true;
end
if heedquotes
    multidelim = false;
    anydelim = false;
end

% set initial parameters
lline  = size(line, 2);
ldelim = size(delimiter, 2);

% standard approach
if ~anydelim
    if ldelim < lline
        if strcmp(line(end+1-ldelim:end), delimiter)
            cpos = [(1 - ldelim), strfind(line, delimiter)];
        else
            cpos = [(1 - ldelim), strfind(line, delimiter), lline + 1];
        end
    elseif ldelim == lline
        if strcmp(line, delimiter)
            linetocell = {''};
        else
            linetocell = {line};
        end
        return;
    else
        linetocell = {line};
        return;
    end

% any of the given delimiters (e.g. white spaces)
else

    % last char is a delimiter
    if ~any(delimiter == line(end))
        cpos = [0, lline + 1];
    else
        cpos = 0;
    end

    % get all delimiter positions
    for pchar = delimiter
        cpos = union(cpos, strfind(line, pchar));
    end

    % set ldelim to 1!
    ldelim = 1;
end

% number of delimiters
lcpos = length(cpos);

% any delimiter found at all ?
if lcpos < 2
    error( ...
        'neuroelf:InternalError', ...
        'Error working with pattern.' ...
    );
elseif lcpos == 2
    linetocell = {line(cpos(1) + ldelim:cpos(2) - 1)};
    return;
end

% concatenate in case of multidelims
ecpos = cpos(2:end) - 1;
if multidelim
    if ecpos(1) == 0
        mcpos = [1, find(diff(ecpos) <= ldelim) + 1];
    else
        mcpos = find(diff(ecpos) <= ldelim) + 1;
    end
    cpos(mcpos) = [];
    ecpos(mcpos) = [];
end
cpos = cpos + ldelim;
ncpos = numel(ecpos);
cellcount = ncpos;
linetocell = cell(1, ncpos);

% extract substrings
if ~heedquotes
    for dpos = 1:ncpos
        if cpos(dpos) <= ecpos(dpos)
            linetocell{dpos} = line(cpos(dpos):ecpos(dpos));
        else
            linetocell{dpos} = '';
        end
    end
else
    dpos = 1;
    tpos = 1;
    while dpos <= ncpos
        cellc = line(cpos(dpos):ecpos(dpos));
        hq = false;
        if ~isempty(cellc) && ...
            any(cellc(1) == '"''')
            if numel(cellc) > 1 && ...
                cellc(1) == cellc(end)
                if numel(cellc) > 2
                    cellc = cellc(2:end-1);
                else
                    cellc = '';
                end
            else
                for xpos = dpos+1:ncpos
                    xcellc = line(cpos(xpos):ecpos(xpos));
                    if ~isempty(xcellc) && ...
                        xcellc(end) == cellc(1)
                        hq = true;
                        break;
                    end
                end
            end
        elseif isempty(cellc)
            cellc = '';
        end
        if hq
            linetocell{tpos} = line(cpos(dpos)+1:ecpos(xpos)-1);
            dpos = xpos;
        else
            linetocell{tpos} = cellc;
        end
        dpos = dpos + 1;
        tpos = tpos + 1;
    end
    if tpos < dpos
        linetocell(tpos:end) = [];
    end
end
