function conmaps = glm_RFX_conmaps(hfile, c, mapopts)
% GLM::RFX_conmaps  - return contrast maps (sums of betas)
%
% FORMAT:       maps = glm.RFX_conmaps(c, [, mapopts])
%
% Input fields:
%
%       c           NxC contrast vector
%       mapopts     structure with optional fields
%        .meanr     boolean flag, remove mean from map (added as cov)
%        .meanrmsk  mask to get mean from (object or XxYxZ logical)
%        .subsel    subject selection (otherwise all subjects)
%
% Output fields:
%
%       maps        either 4D or 2D data array (VTC/MTC)

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2010, 2012, 2014, Jochen Weber
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
   ~isa(c, 'double') || ...
    isempty(c) || ...
    any(isnan(c(:)) | isinf(c(:)))
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
if bc.ProjectTypeRFX ~= 1 && ...
    bc.SeparatePredictors ~= 2
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
if ~any(bc.ProjectType == [1, 2])
    error( ...
        'xff:Unsupported', ...
        'RFX map extraction of FMRs are not yet supported.' ...
    );
end
isrfx = (bc.ProjectTypeRFX > 0);
ffxspred = glm_SubjectPredictors(hfile);
if isrfx
    numsubs = numel(bc.GLMData.Subject);
    numspred = size(bc.GLMData.Subject(1).BetaMaps, ...
        ndims(bc.GLMData.Subject(1).BetaMaps));
else
    ffxpred = bc.Predictor;
    ffxpred = {ffxpred(:).Name2};
    ffxpred = ffxpred(:);
    ffxsubs = glm_Subjects(hfile);
    numsubs = numel(ffxsubs);
    numspred = numel(ffxspred) + 1;
end
if numsubs < 3
    error( ...
        'xff:BadArgument', ...
        'Invalid RFX GLM object.' ...
    );
end
if any(numel(c) == [numspred, numspred - 1])
    c = c(:)';
end
if ~any(size(c, 2) == [numspred, numspred - 1])
    error( ...
        'xff:BadArgument', ...
        'Invalid first-level contrast spec.' ...
    );
end
if bc.ProjectType == 1
    if isrfx
        msz = size(bc.GLMData.RFXGlobalMap);
    else
        msz = size(bc.GLMData.MCorrSS);
    end
else
    if isrfx
        msz = numel(bc.GLMData.RFXGlobalMap);
    else
        msz = numel(bc.GLMData.MCorrSS);
    end
end
if nargin < 3 || ...
   ~isstruct(mapopts) || ...
    numel(mapopts) ~= 1
    mapopts = struct;
end
if ~isfield(mapopts, 'meanr') || ...
   ~islogical(mapopts.meanr) || ...
    numel(mapopts.meanr) ~= 1
    mapopts.meanr = false;
end
if isfield(mapopts, 'meanrmsk') && ...
    numel(mapopts.meanrmsk) == 1 && ...
    xffisobject(mapopts.meanrmsk, true, 'msk')
    mbc = xffgetcont(mapopts.meanrmsk.L);
    if numel(mbc.Mask) == prod(msz)
        mapopts.meanrmsk = lsqueeze(mbc.Mask > 0);
    else
        mapopts.meanrmsk = [];
    end
elseif isfield(mapopts, 'meanrmsk') && ...
    islogical(mapopts.meanrmsk) && ...
    numel(mapopts.meanrmsk) == prod(msz)
    mapopts.meanrmsk = lsqueeze(mapopts.meanrmsk);
else
    mapopts.meanrmsk = [];
end
if isempty(mapopts.meanrmsk) && ...
    mapopts.meanr && ...
    isrfx
    mapopts.meanrmsk = all(bc.GLMData.Subject(1).BetaMaps ~= 0, ...
        ndims(bc.GLMData.Subject(1).BetaMaps));
    for sc = 1:numsubs
        mapopts.meanrmsk = (mapopts.meanrmsk & ...
            all(bc.GLMData.Subject(1).BetaMaps ~= 0, ...
            ndims(bc.GLMData.Subject(1).BetaMaps)));
    end
    mapopts.meanrmsk = lsqueeze(mapopts.meanrmsk);
else
    mapopts.meanrmsk = false;
    mapopts.meanr = false;
end
meanrmsk = mapopts.meanrmsk;
if ~any(meanrmsk)
    mapopts.meanr = false;
end
meanrsum = 1 ./ sum(meanrmsk(:));
if ~isfield(mapopts, 'subsel') || ...
   ~isa(mapopts.subsel, 'double') || ...
    isempty(mapopts.subsel) || ...
    any(isinf(mapopts.subsel(:)) | isnan(mapopts.subsel(:))) || ...
    numel(unique(round(mapopts.subsel(:)))) ~= numel(mapopts.subsel) || ...
    any(mapopts.subsel(:) < 1 | mapopts.subsel(:) > numsubs)
    mapopts.subsel = 1:numsubs;
else
    mapopts.subsel = round(mapopts.subsel(:)');
end
subsel = mapopts.subsel;
numsubs = numel(subsel);
c = c';
if size(c, 1) == (numspred - 1)
    c(end + 1, :) = 0;
end
nummaps = size(c, 2);
if bc.ProjectType == 1
    subsa = {':', ':', ':', [], []};
    subsr = {':', ':', ':', []};
else
    subsa = {':', [], []};
    subsr = {':', []};
end

% extraction
conmaps = zeros([msz, numsubs, nummaps]);
for cc = 1:nummaps
    subsa{end} = cc;

    % fill contrast maps
    for pc = 1:numspred
        if c(pc, cc) ~= 0

            % RFX
            if isrfx
                subsr{end} = pc;
                subsrs = struct('type', '()', 'subs', {subsr});
                for sc = 1:numsubs
                    subsa{end-1} = sc;
                    subsas = struct('type', '()', 'subs', {subsa});
                    conext = subsref(bc.GLMData.Subject(subsel(sc)).BetaMaps, subsrs);
                    if mapopts.meanr
                        conext(meanrmsk) = conext(meanrmsk) - ...
                            meanrsum .* sum(conext(meanrmsk));
                    end
                    conmaps = subsasgn(conmaps, subsas, ...
                        subsref(conmaps, subsas) + c(pc, cc) .* conext);
                end

            % FFX
            else

                % find index
                for sc = 1:numsubs
                    subsa{end-1} = sc;
                    subsas = struct('type', '()', 'subs', {subsa});
                    keepsubi = findfirst(~cellfun('isempty', regexpi(ffxpred, ...
                        sprintf('^subject\\s+%s:\\s*%s', ...
                        ffxsubs{subsel(sc)}, ffxspred{pc}))));
                    if ~isempty(keepsubi)
                        subsr{end} = keepsubi;
                        subsrs = struct('type', '()', 'subs', {subsr});
                        conext = subsref(bc.GLMData.BetaMaps, subsrs);
                        if mapopts.meanr
                            conext(meanrmsk) = conext(meanrmsk) - ...
                                meanrsum .* sum(conext(meanrmsk));
                        end
                        conmaps = subsasgn(conmaps, subsas, ...
                            subsref(conmaps, subsas) + c(pc, cc) .* conext);
                    else
                        conmaps = subsasgn(conmaps, subsas, NaN);
                    end
                end
            end
        end
    end
end

% replace invalid maps with 0
if ~isrfx
    conmaps(isnan(conmaps)) = 0;
end
