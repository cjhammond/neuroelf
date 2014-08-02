function asciirep = any2ascii(S, varargin)
% xff::any2ascii  - get xff object as ascii-string
%
% FORMAT:       asciirep = any2ascii(xffo [, ...])
%
% Input fields:
%
%       xffo        xff-object variable/array
%
% Output fields:
%
%       asciirep    result string
%

% Version:  v0.9b
% Build:    10061506
% Date:     Jun-15 2010, 12:37 PM EST
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

% check size
sS = struct(S);

% for multiple objects
if numel(sS) ~= 1
    asciirep = cell(1, numel(sS));
    for sc = 1:numel(sS)
        asciirep{sc} = any2ascii(class(sS(sc), 'xff'));
    end
    asciirep = sprintf('%s,', asciirep{:});
    sizearg = sprintf('%d,', size(sS));
    asciirep = sprintf('reshape([%s], [%s])', asciirep(1:end-1), sizearg(1:end-1));

% single object
else

    % for root object
    if sS.L < 0
        asciirep = 'xff';

    % for file-based object
    else

        % get object
        sc = xffgetscont(sS.L);

        % filename empty
        if isempty(sc.F)

            % give content
            asciirep = sprintf('struct(''%s'',%s)', sc.S.Extensions{1}, ...
                any2ascii(sc.C));
            asciirep = sprintf('xff(0,''makeobject'',%s)', asciirep);
        % filename given
        else
            asciirep = sprintf('xff(0,''object'',%s)', sprintf('''%s''', sc.F));
        end
    end
end
