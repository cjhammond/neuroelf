function clearxffobjects(olist)
% clearxffobjects  - issue ClearObject call on several objects
%
% FORMAT:       clearxffobjects(olist)
%
% Input fields:
%
%       olist       cell array with xff objects
%
% No output fields

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
if nargin ~= 1 || ...
   (~iscell(olist) && ...
    ~isa(olist, 'double') && ...
    ~isa(olist, 'xff')) || ...
    isempty(olist)
    return;
end

% for cell array iterate over cells
if iscell(olist)

    % prepare double list for alternative calling syntax
    nlist = ones(1, numel(olist));
    for c = 1:numel(olist)
        if isxff(olist{c})
            sfile = struct(olist{c});
            if numel(sfile) == 1
                nlist(c) = sfile.L;
            else
                alist = zeros(1, numel(sfile));
                for sc = 1:numel(sfile)
                    alist(sc) = sfile(sc).L;
                end
                nlist = [nlist, alist];
            end
        elseif iscell(olist{c})
            clearxffobjects(olist{c});
        end
    end

    % clear objects
    xff(0, 'clearobj', nlist);

% for double array
elseif isa(olist, 'double')
    xff(0, 'clearobj', olist);

% for xff objects
else
    clearxffobjects({olist});
end
