function s = glm_Subjects(hfile, full)
% GLM::Subjects  - return list of subjects of multi-subject GLM
%
% FORMAT:       subjects = glm.Subjects([full]);
%
% Input fields:
%
%       full        flag, if true, returns subject IDs for each study
%
% Output fields:
%
%       subjects    subjects list (Sx1 cell array)

% Version:  v0.9d
% Build:    14052916
% Date:     May-29 2014, 4:20 PM EST
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

% check arguments
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'glm')
    error( ...
        'xff:BadArgument', ...
        'Invalid object handle in call.' ...
    );
end
if nargin < 2 || ...
   ~islogical(full) || ...
    numel(full) ~= 1
    full = false;
end
sbc = xffgetscont(hfile.L);
bc = sbc.C;
if isfield(sbc.H, 'SubjectIDs') && ...
    iscell(sbc.H.SubjectIDs) && ...
    numel(sbc.H.SubjectIDs) == numel(bc.Study)
    s = sbc.H.SubjectIDs;
else
    s = {bc.Study(:).NameOfAnalyzedFile};
    s = s(:);
    for sc = 1:numel(s)
        [p, s{sc}] = fileparts(s{sc});
        s{sc} = regexprep(s{sc}, '^([^_]+)_.*$', '$1');
    end
    sbc.H.SubjectIDs = s;
    xffsetscont(hfile.L, sbc);
end
if full
    return;
end
[su, sui] = unique(s);
if bc.ProjectTypeRFX > 0 && ...
    numel(su) ~= bc.NrOfSubjects
    warning( ...
        'xff:InternalError', ...
        'NrOfSubjects does not match with unique subject IDs.' ...
    );
end
s = s(sort(sui));
