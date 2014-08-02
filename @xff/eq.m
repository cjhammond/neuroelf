function q = eq(A,B)
% xff::eq  - overloaded method

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

% check sizes first
szA = size(A);
szB = size(B);
if ~isequal(szA, szB) && ...
    numel(A) ~= 1 && ...
    numel(B) ~= 1
    error( ...
        'xff:InvalidCall', ...
        'A call to eq(OBJ,OBJ) requires two same-sized or one scalar.' ...
    );
end

% prepare output
if ~isequal(szA, szB)
    if numel(A) == 1
        q = false(szB);
    else
        q = false(szA);
    end
else
    q = false(szA);
end

% classes different
if ~strcmp(class(A), class(B))

    % different !
    return;
end

% compare handles
if numel(A) == 1
    for ec = 1:numel(B)
        q(ec) = (A.L == B(ec).L);
    end
elseif numel(B) == 1
    for ec = 1:numel(A)
        q(ec) = (A(ec).L == B.L);
    end
else
    for ec = 1:numel(B)
        q(ec) = (A(ec).L == B(ec).L);
    end
end
