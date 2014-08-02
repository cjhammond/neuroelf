function [y, trfplus, snmat, ya] = aft_GetVolume(hfile, volnum, ccheck)
% AFT::GetVolume  - get one volume from a (multi-volume) dataset
%
% FORMAT:       [y, trfplus, snmat] = obj.GetVolume([volnum [, ccheck]])
%
% Input fields:
%
%       volnum      1x1 double index (default: 1)
%       ccheck      use EnableClusterCheck flag from Map (default: false)
%
% Output fields:
%
%       y           uninterpolated volume data (in source datatype)
%       trfplus     additional map-based TrfPlus component
%       snmat       additional map-based (replacement) SPMsn/SNmat component
%
% Note: this methods works with
%
%       amr       get AMR data (volnum discarded, can only be 1)
%       cmp       get component map with number volnum
%       ddt       get the corresponding volume (1 .. 12)
%       dmr       get according volume of DWI file
%       fmr       get according volume of STC file(s)
%       glm       get beta map with index volnum (scheme PxS)
%       hdr       get sub-volume of 4D image file (1st volume otherwise)
%       head      get sub-brick data from HEAD/BRIK object
%       map       get FMR based map (volnum discarded, can only be 1)
%       msk       get MSK data (volnum discarded, can only be 1)
%       nlf       get NLF volume data
%       vdw       get tensor imaging volume with number volnum
%       vmp       get according statistical map with number volnum
%       vmr       get VMR data (volnum discarded, can only be 1)
%       vtc       get functional volume with number volnum
%
% TYPES: AMR, AVA, CMP, DDT, DMR, FMR, GLM, HDR, HEAD, MAP, MSK, NLF, VDW, VMP, VMR, VTC

% Version:  v0.9d
% Build:    14071012
% Date:     Jul-10 2014, 12:30 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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

% global configuration
global xffconf;

% argument check
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~isa(volnum, 'double') || ...
    isempty(volnum) || ...
    numel(volnum) > 2 || ...
    any(isinf(volnum) | isnan(volnum) | volnum < 1)
    volnum = [1, 1];
else
    volnum = floor(volnum);
end
if nargin < 3 || ...
    numel(ccheck) ~= 1 || ...
   (~islogical(ccheck) && ...
    ~isa(ccheck, 'double'))
    ccheck = false;
elseif islogical(ccheck) && ...
    ccheck
    ccheck = 2;
else
    ccheck = isequal(ccheck, 1);
end

% get super-struct
ssc = xffgetscont(hfile.L);
rtv = ssc.C.RunTimeVars;
ft = lower(ssc.S.Extensions{1});
if ~any(strcmp(ft, ...
    {'amr', 'ava', 'cmp', 'ddt', 'dmr', 'fmr', 'glm', 'hdr', ...
     'head', 'map', 'msk', 'nlf', 'vdw', 'vmp', 'vmr', 'vtc'}))
    error( ...
        'xff:BadArgument', ...
        'GetVolume not supported for this object type.' ...
    );
end

% preset alpha value
ya = 1;

% second vol-number only for NLF
if ~strcmp(ft, 'nlf')
    volnum = volnum(1);
elseif numel(volnum) == 1
    volnum(2) = 1;
end

% preset outputs
trfplus = eye(4);
snmat = [];

% depends on filetype
bc = ssc.C;
switch (ft)

    % AMR
    case {'amr'}

        % initialize data
        y = uint8([]);
        y(1:size(bc.Slice(1).AMRData, 1), 1:size(bc.Slice(1).AMRData, 2), 1:numel(bc.Slice)) = 0;

        % iterate over slices
        for sc = 1:numel(bc.Slice)
            y(:, :, sc) = bc.Slice(sc).AMRData(:, :);
        end

    % AVA
    case {'ava'}
        am = fieldnames(bc.Maps);
        while volnum > 1 && ...
           ~isempty(am)
            avm = bc.Maps.(am{1});
            if size(avm, 4) < volnum
                volnum = volnum - size(avm, 4);
                am(1) = [];
            else
                y = avm(:, :, :, volnum);
                return;
            end
        end
        if isempty(am)
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end
        avm = bc.Maps.(am{1});
        y = avm(:, :, :, volnum);

    % CMP
    case {'cmp'}
        if volnum > numel(bc.Map)
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end
        y = bc.Map(volnum).CMPData(:, :, :);
        if isa(ccheck, 'double')
            ccheck = (bc.Map(volnum).EnableClusterCheck > 0);
        end
        if ccheck
            y(~bc.Map(volnum).CMPDataCT) = 0;
        end

    % DDT
    case {'ddt'}
        if volnum > 12
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end
        if ~istransio(bc.TensorEigenVs)
            y = squeeze(bc.TensorEigenVs(volnum, :, :, :));
        else
            y = resolve(bc.TensorEigenVs);
            y = squeeze(y(volnum, :, :, :));
        end

    % DMR
    case {'dmr'}
        if volnum > bc.NrOfVolumes
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end

        % depends on storage format
        switch (bc.DataStorageFormat)
            case {2}
                y = squeeze(bc.DWIData(:, :, volnum, :));
            case {3}
                y = bc.DWIData(:, :, :, volnum);
            case {4}
                y = squeeze(bc.DWIData(volnum, :, :, :));
            otherwise
                error( ...
                    'xff:BadObject', ...
                    'DataStorageFormat unknown.' ...
                );
        end

    % FMR
    case {'fmr'}
        if volnum > bc.NrOfVolumes
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end

        % data must be loaded
        if isempty(bc.Slice)
            error( ...
                'xff:BadObject', ...
                'STC data not loaded.' ...
            );
        end

        % depends on FileVersion and DataStorageFormat
        if bc.FileVersion < 5 || ...
            bc.DataStorageFormat == 1
            y = uint16([]);
            y(1:bc.ResolutionX, 1:bc.ResolutionY, 1:bc.NrOfSlices) = uint16(0);

            % iterate over slices
            for sc = 1:bc.NrOfSlices
                y(:, :, sc) = bc.Slice(sc).STCData(:, :, volnum);
            end
        else
            switch (bc.DataStorageFormat)
                case {2}
                    y = squeeze(bc.Slice.STCData(:, :, volnum, :));
                case {3}
                    y = bc.Slice.STCData(:, :, :, volnum);
                case {4}
                    y = squeeze(bc.Slice.STCData(volnum, :, :, :));
                otherwise
                    error( ...
                        'xff:BadObject', ...
                        'DataStorageFormat unknown.' ...
                    );
            end
        end

    % GLM
    case {'glm'}

        % what type of GLM
        if ~bc.ProjectTypeRFX
            nd = numel(size(bc.GLMData.BetaMaps));
            nbetas = size(bc.GLMData.BetaMaps, nd);
            if volnum > (2 * nbetas + 3 + bc.SerialCorrelation)
                error( ...
                    'xff:BadArgument', ...
                    'Volume number out of bounds.' ...
                );
            end
            if volnum <= nbetas
                if nd == 2
                    if istransio(bc.GLMData.BetaMaps) && ...
                        xffconf.settings.Behavior.BufferGLMData
                        bc.GLMData.BetaMaps = buffer( ...
                            bc.GLMData.BetaMaps, {':', volnum});
                        xffsetcont(hfile.L, bc);
                    end
                    y = bc.GLMData.BetaMaps(:, volnum);
                elseif nd == 4
                    if istransio(bc.GLMData.BetaMaps) && ...
                        xffconf.settings.Behavior.BufferGLMData
                        bc.GLMData.BetaMaps = buffer( ...
                            bc.GLMData.BetaMaps, {':', ':', ':', volnum});
                        xffsetcont(hfile.L, bc);
                    end
                    y = bc.GLMData.BetaMaps(:, :, :, volnum);
                else
                    error( ...
                        'xff:BadObject', ...
                        'Unsupported GLMData size.' ...
                    );
                end
            elseif volnum <= (2 * nbetas)
                volnum = volnum - nbetas;
                if nd == 2
                    if istransio(bc.GLMData.XY) && ...
                        xffconf.settings.Behavior.BufferGLMData
                        bc.GLMData.XY = buffer( ...
                            bc.GLMData.XY, {':', volnum});
                        xffsetcont(hfile.L, bc);
                    end
                    y = bc.GLMData.XY(:, volnum);
                elseif nd == 4
                    if istransio(bc.GLMData.XY) && ...
                        xffconf.settings.Behavior.BufferGLMData
                        bc.GLMData.XY = buffer( ...
                            bc.GLMData.XY, {':', ':', ':', volnum});
                        xffsetcont(hfile.L, bc);
                    end
                    y = bc.GLMData.XY(:, :, :, volnum);
                else
                    error( ...
                        'xff:BadObject', ...
                        'Unsupported GLMData size.' ...
                    );
                end
            else
                volnum = volnum - 2 * nbetas;
                if nd == 2
                    switch volnum
                        case {1}
                            y = bc.GLMData.MultipleRegressionR(:);
                        case {2}
                            y = bc.GLMData.MCorrSS(:);
                        case {3}
                            y = bc.GLMData.TimeCourseMean(:);
                        otherwise
                            y = bc.GLMData.ARLag(:, volnum - 3);
                    end
                elseif nd == 4
                    switch volnum
                        case {1}
                            y = bc.GLMData.MultipleRegressionR(:, :, :);
                        case {2}
                            y = bc.GLMData.MCorrSS(:, :, :);
                        case {3}
                            y = bc.GLMData.TimeCourseMean(:, :, :);
                        otherwise
                            y = bc.GLMData.ARLag(:, :, :, volnum - 3);
                    end
                else
                    error( ...
                        'xff:BadObject', ...
                        'Unsupported GLMData size.' ...
                    );
                end
            end
            if bc.NrOfSubjects == 1 && ...
               (isfield(rtv, 'SubjectSPMsn') && ...
                isstruct(rtv.SubjectSPMsn) && ...
                numel(fieldnames(rtv.SubjectSPMsn)) == 1) || ...
               (isfield(rtv, 'SubjectTrfPlus') && ...
                isstruct(rtv.SubjectTrfPlus) && ...
                numel(fieldnames(rtv.SubjectTrfPlus)) == 1)
                sid = bc.Study(1).NameOfAnalyzedFile;
                [sidp, sid] = fileparts(sid);
                sid = regexprep(sid, '^([^_]+)_.*$', '$1');
                tsid = makelabel(sid);
                if isfield(rtv.SubjectTrfPlus, tsid)
                    trfplus = rtv.SubjectTrfPlus.(tsid);
                end
                if isfield(rtv.SubjectSPMsn, tsid)
                    snmat = rtv.SubjectSPMsn.(tsid);
                end
            end
        else
            nd = numel(size(bc.GLMData.Subject(1).BetaMaps));
            ns = size(bc.GLMData.Subject);
            nsp = size(bc.GLMData.Subject(1).BetaMaps, nd);
            if volnum > (ns * nsp)
                error( ...
                    'xff:BadArgument', ...
                    'Volume number out of bounds.' ...
                );
            end
            snum = floor((volnum - 1) / nsp) + 1;
            pnum = volnum - (snum - 1) * nsp;
            if nd == 2
                if istransio(bc.GLMData.Subject(snum).BetaMaps) && ...
                    xffconf.settings.Behavior.BufferGLMData
                    bc.GLMData.Subject(snum).BetaMaps = buffer( ...
                        bc.GLMData.Subject(snum).BetaMaps, {':', pnum});
                    xffsetcont(hfile.L, bc);
                end
                y = bc.GLMData.Subject(snum).BetaMaps(:, pnum);
            elseif nd == 4
                if istransio(bc.GLMData.Subject(snum).BetaMaps) && ...
                    xffconf.settings.Behavior.BufferGLMData
                    bc.GLMData.Subject(snum).BetaMaps = buffer( ...
                        bc.GLMData.Subject(snum).BetaMaps, {':', ':', ':', pnum});
                    xffsetcont(hfile.L, bc);
                end
                y = bc.GLMData.Subject(snum).BetaMaps(:, :, :, pnum);
                if (isfield(rtv, 'SubjectSPMsn') && ...
                    isstruct(rtv.SubjectSPMsn) && ...
                    ~isempty(fieldnames(rtv.SubjectSPMsn))) || ...
                   (isfield(rtv, 'SubjectTrfPlus') && ...
                    isstruct(rtv.SubjectTrfPlus) && ...
                    ~isempty(fieldnames(rtv.SubjectTrfPlus)))
                    if ~isfield(ssc.H, 'SubjectIDs') || ...
                       ~iscell(ssc.H.SubjectIDs) || ...
                        numel(ssc.H.SubjectIDs) ~= numel(bc.Study)
                        sids = glm_Subjects(hfile, true);
                    else
                        sids = ssc.H.SubjectIDs;
                    end
                    [sidu, sidui] = unique(sids);
                    sids = sids(sort(sidui));
                    tsid = makelabel(sids{snum});
                    if isfield(rtv.SubjectTrfPlus, tsid)
                        trfplus = rtv.SubjectTrfPlus.(tsid);
                    end
                    if isfield(rtv.SubjectSPMsn, tsid)
                        snmat = rtv.SubjectSPMsn.(tsid);
                    end
                end
            else
                error( ...
                    'xff:BadObject', ...
                    'Unsupported GLMData size.' ...
                );
            end
        end
        if isa(ccheck, 'double')
            if isfield(rtv, 'Map') && ...
                isstruct(rtv.Map) && ...
                numel(rtv.Map) >= volnum && ...
                isfield(rtv.Map, 'EnableClusterCheck') && ...
                isfield(rtv.Map, 'DataCT') && ...
                isequal(size(rtv.Map(volnum).DataCT), size(y))
                ccheck = (rtv.Map(volnum).EnableClusterCheck > 0);
            else
                ccheck = false;
            end
        end
        if ccheck
            y(~rtv.Map(volnum).DataCT) = 0;
        end

    % HDR
    case {'hdr'}

        % deal with complex datatypes
        if any(bc.ImgDim.DataType == [32, 128, 1536, 1792, 2048, 2304])
            switch (bc.ImgDim.DataType)
                case {32, 1792}
                    if volnum > size(bc.VoxelDataComplex, 4)
                        error( ...
                            'xff:BadArgument', ...
                            'Volume number out of bounds.' ...
                        );
                    end
                    y = complex(bc.VoxelData(:, :, :, volnum), ...
                        bc.VoxelDataComplex(:, :, :, volnum));
                case {128, 2304}
                    if volnum > size(bc.VoxelDataRGBA, 4)
                        error( ...
                            'xff:BadArgument', ...
                            'Volume number out of bounds.' ...
                        );
                    end
                    y = bc.VoxelDataRGBA(:, :, :, volnum, :);
                case {1536, 2048}
                    error( ...
                        'xff:Unsupported', ...
                        'longdouble datatype not yet supported.' ...
                    );
            end
            return;
        end

        if volnum > size(bc.VoxelData, 4)
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end
        y = bc.VoxelData(:, :, :, volnum);

        % scaling
        if any([2, 4, 8, 130, 132, 136, 256, 512, 768] == bc.ImgDim.DataType) && ...
           (bc.ImgDim.ScalingIntercept ~= 0 || ...
            all([0, 1] ~= bc.ImgDim.ScalingSlope))
            if bc.ImgDim.ScalingSlope ~= 0
                y = bc.ImgDim.ScalingIntercept + ...
                    bc.ImgDim.ScalingSlope .* double(y);
            else
                y = bc.ImgDim.ScalingIntercept + double(y);
            end
        end

        % cluster check
        if isa(ccheck, 'double')
            if isfield(rtv, 'Map') && ...
                isstruct(rtv.Map) && ...
                numel(rtv.Map) >= volnum && ...
                isfield(rtv.Map, 'EnableClusterCheck') && ...
                isfield(rtv.Map, 'DataCT') && ...
                isequal(size(rtv.Map(volnum).DataCT), size(y))
                ccheck = (rtv.Map(volnum).EnableClusterCheck > 0);
            else
                ccheck = false;
            end
        end
        if ccheck
            y(~rtv.Map(volnum).DataCT) = 0;
        end

    % HEAD
    case {'head'}
        if volnum > numel(bc.Brick)
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end
        y = bc.Brick(volnum).Data(:, :, :);
        if isa(ccheck, 'double')
            if isfield(rtv, 'Map') && ...
                isstruct(rtv.Map) && ...
                numel(rtv.Map) >= volnum && ...
                isfield(rtv.Map, 'EnableClusterCheck') && ...
                isfield(rtv.Map, 'DataCT') && ...
                isequal(size(rtv.Map(volnum).DataCT), size(y))
                ccheck = (rtv.Map(volnum).EnableClusterCheck > 0);
            else
                ccheck = false;
            end
        end
        if ccheck
            y(~rtv.Map(volnum).DataCT) = 0;
        end

    % MAP
    case {'map'}

        % initialize data
        y = single([]);
        y(1:bc.DimX, 1:bc.DimY, 1:numel(bc.Map)) = single(0);

        % iterate over slices
        for sc = 1:size(y, 3)
            y(:, :, sc) = bc.Map(sc).Data(:, :);
        end

    % MSK
    case {'msk'}
        y = bc.Mask(:, :, :);

    % NLF
    case {'nlf'}

        % for anatomical data
        it = bc.Intent;
        switch (it)
            case {'a3d'}
                volnum = min(volnum, size(bc.Data, 4));
                y = bc.Data(:, :, :, volnum(1));
        end

    % VDW
    case {'vdw'}
        if volnum > bc.NrOfVolumes
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end

        % make sure to load transio object
        t = bc.VDWData;
        if istransio(t)
            t = t(:, :, :, :);
        end
        y = squeeze(t(volnum, :, :, :));

    % VMP
    case {'vmp'}
        if volnum > numel(bc.Map)
            error( ...
                'xff:BadArgument', ...
                'Volume number out of bounds.' ...
            );
        end
        y = bc.Map(volnum).VMPData;
        if isa(ccheck, 'double')
            ccheck = (bc.Map(volnum).EnableClusterCheck > 0);
        end
        if ccheck
            y(~bc.Map(volnum).VMPDataCT) = 0;
        end

    % VMR
    case {'vmr'}
        if volnum <= 1 || ...
            isempty(bc.VMRData16)
            y = bc.VMRData;
        else
            y = bc.VMRData16;
        end

    % VTC
    case {'vtc'}
        t = bc.VTCData;
        if istransio(t)
            t = t(:, :, :, :);
        end
        if ~isfield(rtv, 'AvgVTC') || ...
           ~rtv.AvgVTC
            if volnum > bc.NrOfVolumes
                error( ...
                    'xff:BadArgument', ...
                    'Volume number out of bounds.' ...
                );
            end

            % make sure to load transio object
            y = squeeze(t(volnum, :, :, :));
        else
            if volnum > rtv.NrOfConditions
                error( ...
                    'xff:BadArgument', ...
                    'Volume (map) number out of bounds.' ...
                );
            end
            vptc = rtv.NrOfVolumesPerTC;
            smv = max(min(rtv.SubMapVol, vptc), 1);
            condi = round(volnum);
            tcpc = rtv.NrOfTCsPerCondition;
            cthr = rtv.ConditionThresholds(condi, 2, :);
            volnum = smv;
            if volnum == round(volnum)
                ya = double(squeeze(bc.VTCData((condi - 1) * tcpc * vptc + volnum + vptc, :, :, :)));
            else
                smv = round(volnum);
                smd = volnum - smv;
                rweights = flexinterpn_method([0; 0; 0; 1; 0; 0; 0], ...
                    [Inf; 1 - smd;1;7], 'cubic');
                rweight1 = findfirst(rweights ~= 0);
                rweights = rweights(rweight1:findfirst(rweights ~= 0, -1));
                smv = smv - 4 + rweight1;
                if smv < 1
                    rweights = rweights(2 - smv:end);
                    smv = 1;
                end
                while (smv + numel(rweights) - 1) > rtv.NrOfVolumesPerTC
                    rweights(end) = [];
                end
                smv = smv + (condi - 1) * tcpc * vptc;
                if isempty(rweights)
                    rweights = 1;
                end
                odatasz = size(bc.VTCData);
                odatasz(1) = [];
                ya = zeros(odatasz);
            end
            if volnum == round(volnum)
                y = squeeze(bc.VTCData(volnum + (condi - 1) * tcpc * vptc, :, :, :));
                if strcmpi(rtv.TCNames{2}, 'sd')
                    ya = (1 / sqrt(rtv.NrOfConditionOnsets(condi))) .* ya;
                end
                if lower(rtv.TCNames{2}(1)) == 's'
                    ya = abs(y) ./ abs(ya);
                    ya(isnan(volnum)) = 0;
                end
                ya = limitrangec((1 / max(cthr(2) - cthr(1), sqrt(eps))) .* (ya - cthr(1)), 0, 1, 0);
            else
                y = zeros(odatasz);
                for rwc = 1:numel(rweights)
                    odatap = squeeze(bc.VTCData(smv+rwc-1, :, :, :));
                    yap = squeeze(bc.VTCData(vptc+smv+rwc-1, :, :, :));
                    if strcmpi(rtv.TCNames{2}, 'sd')
                        yap = (1 / sqrt(rtv.NrOfConditionOnsets(condi))) .* yap;
                    end
                    if lower(rtv.TCNames{2}(1)) == 's'
                        yap = abs(odatap) ./ abs(yap);
                        yap(isinf(yap) | isnan(yap)) = 0;
                    end
                    y = y + rweights(rwc) .* odatap;
                    ya = ya + rweights(rwc) .* ...
                        limitrangec((1 / max(cthr(2) - cthr(1), sqrt(eps))) .* (yap - cthr(1)), 0, 1, 0);
                end
            end
        end
end

% final check
if istransio(y)
    y = y(:, :, :);
end
