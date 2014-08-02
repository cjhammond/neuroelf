function hfile = glm_WriteAnalyzeBetas(hfile, tfolder, cv, cvname)
% GLM::WriteAnalyzeBetas  - write beta images as Analyze
%
% FORMAT:       glm.WriteAnalyzeBetas(tfolder [, cv, cvname])
%
% Input fields:
%
%       tfolder     target folder
%       cv          contrast vector (if empty, all conditions separately)
%       cvname      contrast name ('contrast' if not given or empty)
%
% No output fields.
%
% Note: RFX GLMs

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

% argument check
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'glm') || ...
   ~ischar(tfolder) || ...
    isempty(tfolder) || ...
    exist(tfolder(:)', 'dir') ~= 7
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
tfolder = tfolder(:)';
if ~bc.ProjectTypeRFX
    error( ...
        'xff:InvalidObject', ...
        'Method only valid for RFX GLM objects.' ...
    );
end
if nargin < 3 || ...
   ~isa(cv, 'double') || ...
   ~any(numel(cv) == (bc.NrOfSubjectPredictors + [-1, 0])) || ...
    any(isinf(cv(:)) | isnan(cv(:))) || ...
   (any(cv(:) < 0) && ...
    abs(sum(cv(:))) > sqrt(eps))
    cv = [];
else
    cv = cv(:)';
    if numel(cv) < bc.NrOfSubjectPredictors
        cv(end+1) = 0;
    end
end
if nargin < 4 || ...
   ~ischar(cvname) || ...
    isempty(cvname)
    cvname = 'contrast';
else
    cvname = cvname(:)';
end

% get subject and predictor names
subnames = regexprep(glm_Subjects(hfile), '[ \!\@\#\$\%\&\*\(\)\[\]]', '');
prednames = glm_SubjectPredictors(hfile);

% data handling depends on project type
imdims = size(bc.GLMData.RFXGlobalMap);
switch (bc.ProjectType)
    case {0}
        imsize = imdims;
        ires = 3;
        istart = 128 - round(1.5 * imdims);
    case {1}
        imdims = imdims([3, 1, 2]);
        imsize = imdims;
        ires = bc.Resolution * ones(1, 3);
        istart = 128 - [bc.ZEnd, bc.XEnd, bc.YEnd] + ires;
    case {2}
        if imdims(1) > 50000
            ires = 2;
        else
            ires = 3;
        end

        % try to find good shape
        imsize = [2, 2, 2] * ceil((imdims(1) ^ (1 / 3)) / 2);
        istart = 128 - round(ires * 0.5 * imsize);
        imdims = imsize;
    otherwise
        error( ...
            'xff:InvalidObject', ...
            'ProjectType %d not supported.', ...
            bc.ProjectType ...
        );
end

% get Analyze framework right
ai = xff('new:hdr');
aibc = xffgetcont(ai.L);
aibc.FileMagic = 'ni1';
aibc.NIIFileType = 1;
aibc.ImgDim.Dim = [4, imdims, 1, 0, 0, 0];
aibc.ImgDim.DataType = 16;
aibc.ImgDim.BitsPerPixel = 32;
aibc.ImgDim.PixelSpacing = [0, ires, ires, ires, 1, 0, 0, 0];
aibc.DataHist.NIftI1.QFormCode = 2;
aibc.DataHist.NIftI1.SFormCode = 2;
aibc.DataHist.NIftI1.QuaternionB = 0;
aibc.DataHist.NIftI1.QuaternionC = 1;
aibc.DataHist.NIftI1.QuaternionD = 0;
aibc.DataHist.NIftI1.QuatOffsetX = istart(1);
aibc.DataHist.NIftI1.QuatOffsetY = istart(2);
aibc.DataHist.NIftI1.QuatOffsetZ = istart(3);
aibc.DataHist.NIftI1.AffineTransX = [ires(1), 0, 0, istart(1)];
aibc.DataHist.NIftI1.AffineTransY = [0, ires(2), 0, istart(2)];
aibc.DataHist.NIftI1.AffineTransZ = [0, 0, ires(3), istart(3)];

% no contrasts
if isempty(cv)

    % preset VoxelData
    if bc.ProjectType == 2
        aibc.VoxelData = single(zeros(prod(imsize), 1));
    end

    % iterate over subjects, predictors
    for sc = 1:bc.NrOfSubjects
        for pc = 1:bc.NrOfSubjectPredictors

            % depends on Project Type
            switch (bc.ProjectType)
                case {0}
                    aibc.VoxelData = bc.GLMData.Subject(sc).BetaMaps(:, end:-1:1, :, pc);
                case {1}
                    aibc.VoxelData = permute( ...
                        bc.GLMData.Subject(sc).BetaMaps(end:-1:1, end:-1:1, end:-1:1, pc), ...
                        [3, 1, 2]);
                case {2}
                    aibc.VoxelData(1:imdims(1)) = ...
                        bc.GLMData.Subjects(sc).BetaMaps(:, pc);
            end

            % set content and write as Analyze
            aibc.HdrKey.DBName = sprintf('BVGLM S%03d P%03d', sc, pc);
            aibc.DataHist.Description = ...
                sprintf('beta - sub %s, cond %s', subnames{sc}, ...
                prednames{pc});
            xffsetcont(ai.L, aibc);
            try
                aft_SaveAs(ai, sprintf('%s/%s_%s_beta.hdr', tfolder, ...
                    subnames{sc}, makelabel(prednames{pc})));
                hdr_SaveVoxelData(ai);
                aibc = xffgetcont(ai.L);
            catch ne_eo;
                xffclear(ai.L);
                rethrow(ne_eo.message);
            end
        end
    end

% with contrasts
else

    % contrast weights
    cvp = find(cv ~= 0);
    cvw = cv(cvp);
    cvlabel = makelabel(cvname);

    % preset data
    switch (bc.ProjectType)
        case {0, 1}
            evdata = zeros(imsize);
        case {2}
            evdata = zeros(prod(imsize), 1);
    end

    % iterate over subjects
    for sc = 1:bc.NrOfSubjects

        % get a copy
        vdata = evdata;

        % then iterate over values
        for pc = 1:numel(cvp)

            % add according to project type
            switch (bc.ProjectType)
                case {0}
                    vdata = vdata + cvw(pc) .* ...
                        bc.GLMData.Subject(sc).BetaMaps(:, end:-1:1, :, cvp(pc));
                case {1}
                    vdata = vdata + cvw(pc) .* permute(...
                        bc.GLMData.Subject(sc).BetaMaps(end:-1:1, end:-1:1, end:-1:1, cvp(pc)), ...
                        [3, 1, 2]);
                case {2}
                    vdata(1:imdims(1)) = vdata(1:imdims(1)) + cvw(pc) .* ...
                        bc.GLMData.Subjects(sc).BetaMaps(:, cvp(pc));
            end
        end

        % set content and write as Analyze
        aibc.VoxelData = single(vdata);
        aibc.HdrKey.DBName = sprintf('BVGLM S%03d CON', sc, pc);
        aibc.DataHist.Description = ...
            sprintf('beta - sub %s contrast %s', subnames{sc}, cvname);
        xffsetcont(ai.L, aibc);
        try
            aft_SaveAs(ai, sprintf('%s/%s_contrast_%s.hdr', tfolder, subnames{sc}, cvlabel));
            hdr_SaveVoxelData(ai);
            aibc = xffgetcont(ai.L);
        catch ne_eo;
            xffclear(ai.L);
            rethrow(ne_eo.message);
        end
    end
end

% clear object
xffclear(ai.L);
