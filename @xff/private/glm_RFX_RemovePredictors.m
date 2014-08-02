function hfile = glm_RFX_RemovePredictors(hfile, removep)
% GLM::RFX_RemovePredictors  - removes predictors for each subject
%
% FORMAT:       [glm] = glm.RFX_RemovePredictors(removep)
%
% Input fields:
%
%       removep     specification of predictors to remove

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2010, 2014, Jochen Weber
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
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'glm') || ...
    isempty(removep) || ...
   (~isa(removep, 'double') && ...
    ~ischar(removep) && ...
    ~iscell(removep))
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
if bc.ProjectTypeRFX ~= 1
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
nums = bc.NrOfSubjects;
nump = bc.NrOfSubjectPredictors;
if ~isa(removep, 'double')
    if ~iscell(removep)
        removep = {removep};
    end
    sp = glm_SubjectPredictors(hfile);
    for pc = numel(removep):-1:1
        if ~ischar(removep{pc}) || ...
           ~any(strcmpi(sp, removep{pc}(:)'))
            removep(pc) = [];
        else
            removep{pc} = findfirst(strcmpi(sp, removep{pc}(:)'));
        end
    end
    if isempty(removep)
        return;
    end
    removep = unique(cat(2, removep{:}));
    removep = removep(:)';
else
    removep = removep(:)';
    removep(isinf(removep) | isnan(removep) | removep < 1 | ...
        removep(:) ~= fix(removep(:)) | removep >= nump) = [];
    if isempty(removep)
        return;
    end
end

% build to-be-removed/-kept index variables
remi = false(1, nump - 1);
remi(removep) = true;
keepi = ~remi;
keepi(end+1) = true;
remi = repmat(remi, [1, nums]);
remi(end+1:numel(bc.Predictor)) = false;
nnump = sum(~remi) / nums;
if nnump ~= fix(nnump)
    error( ...
        'xff:InvalidObject', ...
        'Invalid object given.' ...
    );
end

% make changes
bc.NrOfSubjectPredictors = nnump;
bc.NrOfPredictors = sum(~remi);
bc.Predictor(remi) = [];

% rename predictor (Name1)
for pc = 1:numel(bc.Predictor)
    bc.Predictor(pc).Name1 = sprintf('Predictor: %d', pc);
end

% alter BetaMaps
switch (bc.ProjectType)
    case {0, 1}
        for sc = 1:nums
            bc.GLMData.Subject(sc).BetaMaps = ...
                bc.GLMData.Subject(sc).BetaMaps(:, :, :, keepi);
        end
    case {2}
        for sc = 1:nums
            bc.GLMData.Subject(sc).BetaMaps = ...
                bc.GLMData.Subject(sc).BetaMaps(:, keepi);
        end
    otherwise
        error( ...
            'xff:InvalidObject', ...
            'Invalid ProjectType setting in GLM.' ...
        );
end

% set back
xffsetcont(hfile.L, bc);
