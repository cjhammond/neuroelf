function [tc, tcf, tcv, tr] = mdm_POITimeCourses(hfile, poi, opts)
% MDM::POITimeCourses  - extract time courses for referenced MTCs
%
% FORMAT:       [tc, tcf, tcv, tr] = mdm.POITimeCourses(poi [, options])
%
% Input fields:
%
%       poi         POI object
%       options     optional 1x1 struct with fields
%        .poisel    cell array with sub-POI selection to use
%        .subsel    cell array with subject IDs to work on
%        .subpois   subject specific POIs, either 'sub_', '_sub', {'poi'}
%        .trans     either of {'none'}, 'psc', 'z'
%        .unique    flag, only extract unique functional voxels (false)
%
% Output fields:
%
%       tc          Sx1 cell array with TxV time courses (S = NrOfStudies)
%       tcf         Sx1 cell array with time-course file names
%       tcv         Sx1 cell array with 1xV POI indices used

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
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

% argument check
if nargin < 2 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'mdm') || ...
    numel(poi) ~= 1 || ...
   ~xffisobject(poi, true, 'poi')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
cfs = struct('autofind', true, 'silent', true);
try
    hfile = mdm_CheckFiles(hfile, cfs);
catch ne_eo;
    error( ...
        'xff:InternalError', ...
        'Error finding referenced files: %s.', ...
        ne_eo.message ...
    );
end
bc = xffgetcont(hfile.L);
if ~strcmpi(bc.TypeOfFunctionalData, 'mtc') || ...
   ~any(size(bc.XTC_RTC, 2) == [2, 3])
    error( ...
        'xff:BadArgument', ...
        'MDM must be MTC-based.' ...
    );
end

% check options
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'subsel') || ...
   ~iscell(opts.subsel) || ...
    isempty(opts.subsel)
    opts.subsel = mdm_Subjects(hfile);
else
    opts.subsel = opts.subsel(:);
    try
        ssm = multimatch(opts.subsel, mdm_Subjects(hfile));
    catch ne_eo;
        rethrow(ne_eo);
    end
    if any(ssm < 1)
        error( ...
            'xff:BadArgument', ...
            'Invalid subject ID in selection.' ...
        );
    end
end
subids = mdm_Subjects(hfile, true);
subseli = multimatch(subids, opts.subsel);
nsubsel = sum(subseli > 0);
if nsubsel == 0
    error( ...
        'xff:BadArgument', ...
        'No subjects selected.' ...
    );
end
if ~isfield(opts, 'subpois') || ...
   ~ischar(opts.subpois) || ...
    isempty(opts.subpois) || ...
   ~any(lower(opts.subpois(1)) == '_s')
    opts.subpois = 'v';
else
    opts.subpois = lower(opts.subpois(1));
end
if ~isfield(opts, 'trans') || ...
   ~ischar(opts.trans) || ...
    isempty(opts.trans) || ...
   ~any('npz' == lower(opts.trans(1)))
    opts.trans = 'n';
    if bc.PSCTransformation > 0
        opts.trans = 'p';
    end
    if bc.zTransformation > 0
        opts.trans = 'z';
    end
else
    opts.trans = lower(opts.trans(1));
end
if ~isfield(opts, 'unique') || ...
   ~islogical(opts.unique) || ...
    numel(opts.unique) ~= 1
    opts.unique = false;
end
pois = poi_POINames(poi);
if ~isfield(opts, 'poisel') || ...
   ~iscell(opts.poisel) || ...
    isempty(opts.poisel)
    switch (opts.subpois)
        case {'_'}
            spois = unique(lower(regexprep(pois, '_[^_]+$', '')));
            for vc = numel(spois):-1:1
                vf = true;
                for sc = 1:numel(opts.subsel)
                    if ~any(strcmpi(pois, [spois{vc} '_' opts.subsel{sc}]))
                        vf = false;
                        break;
                    end
                end
                if ~vf
                    spois(vc) = [];
                    continue;
                end
            end
            if isempty(spois)
                error( ...
                    'xff:BadArgument', ...
                    'No POI is available for all subjects.' ...
                );
            end
            opts.poisel = spois;
        case {'s'}
            spois = unique(lower(regexprep(pois, '^[^_]+_', '')));
            for vc = numel(spois):-1:1
                vf = true;
                for sc = 1:numel(opts.subsel)
                    if ~any(strcmpi(pois, [opts.subsel{sc} '_' spois{vc}]))
                        vf = false;
                        break;
                    end
                end
                if ~vf
                    spois(vc) = [];
                    continue;
                end
            end
            if isempty(spois)
                error( ...
                    'xff:BadArgument', ...
                    'No POI is available for all subjects.' ...
                );
            end
            opts.poisel = spois;
        case {'v'}
            opts.poisel = pois;
    end
else
    opts.poisel = opts.poisel(:);
    try
        switch (opts.subpois)
            case {'_'}
                for vc = 1:numel(opts.poisel)
                    for sc = 1:numel(opts.subsel)
                        if ~any(strcmpi(pois, [opts.poisel{vc} '_' opts.subsel{sc}]))
                            error( ...
                                'xff:BadArgument', ...
                                'POI %s not available for subject %s.', ...
                                opts.poisel{vc}, opts.subsel{sc} ...
                            );
                        end
                    end
                end
            case {'s'}
                for vc = 1:numel(opts.poisel)
                    for sc = 1:numel(opts.subsel)
                        if ~any(strcmpi(pois, [opts.subsel{sc} '_' opts.poisel{vc}]))
                            error( ...
                                'xff:BadArgument', ...
                                'POI %s not available for subject %s.', ...
                                opts.poisel{vc}, opts.subsel{sc} ...
                            );
                        end
                    end
                end
            case {'v'}
                for vc = 1:numel(opts.poisel)
                    if ~any(strcmpi(pois, opts.poisel{vc}))
                        error( ...
                            'xff:BadArgument', ...
                            'POI %s not available.', ...
                            opts.poisel{vc} ...
                        );
                    end
                end
        end
    catch ne_eo;
        rethrow(ne_eo);
    end
end

% generate output arguments
tc = cell(nsubsel, 1);
if nargout > 1
    tcf = cell(nsubsel, 1);
    if nargout > 2
        tcv = cell(nsubsel, 1);
        if nargout > 3
            tr = zeros(nsubsel, 1);
        end
    end
end

% set transio for MTCs
tios = xff(0, 'transiosize');
xff(0, 'transiosize', 'mtc', 8192);

% copy POI object and get content
cpoi = aft_CopyObject(poi);
cpoic = xffgetcont(cpoi.L);
opoic = cpoic;
cpoin = {cpoic.POI.Name};

% POI indices
vid = zeros(1, numel(opts.poisel));
cpoic.NrOfPOIs = numel(vid);

% POI pattern (without subject ID in name)
if opts.subpois == 'v'
    for vc = 1:numel(opts.poisel)
        vid(vc) = findfirst(strcmpi(cpoin, opts.poisel{vc}));
    end
    cpoic.POI = opoic.POI(vid);
    xffsetcont(cpoi.L, cpoic);
end

% to-clear objects
tco = {cpoi, []};

% big TRY/CATCH
try

    % iterate over subsel
    tcfi = 1;
    for sc = 1:numel(opts.subsel)

        % get required time course files
        tcfs = bc.XTC_RTC(subseli == sc, 1);

        % iterate over time courses
        for fc = 1:numel(tcfs)

            % store name
            if nargout > 1
                tcf{tcfi} = tcfs{fc};
            end

            % open MTC
            tco{2} = xff(tcfs{fc});

            % get TR if necessary
            if nargout > 3
                tcoc = xffgetcont(tco{2}.L);
                tr(tcfi) = tcoc.TR;
            end

            % depending on access
            switch (opts.subpois)

                % POI_SUB pattern
                case {'_'}

                    % iterate over selected POIs
                    for vc = 1:numel(opts.poisel)
                        vid(vc) = findfirst(strcmpi(cpoin, ...
                            [opts.subsel{sc} '_' opts.poisel{vc}]));
                    end

                % SUB_POI pattern
                case {'s'}
                    for vc = 1:numel(opts.poisel)
                        vid(vc) = findfirst(strcmpi(cpoin, ...
                            [opts.poisel{vc} '_' opts.subsel{sc}]));
                    end
            end

            % patch copied POI
            if opts.subpois ~= 'v'
                cpoic.POI = opoic.POI(vid);
                xffsetcont(cpoi.L, cpoic);
            end

            % extract time courses
            tc{tcfi} = aft_POITimeCourse(tco{2}, cpoi, ...
                struct('weights', 1 - double(opts.unique)));
            aft_ClearObject(tco{2});
            tco{2} = [];

            % transformation
            switch (opts.trans)
                case {'p'}
                    tc{tcfi} = psctrans(tc{tcfi}, 1);
                case {'z'}
                    tc{tcfi} = ztrans(tc{tcfi}, 1);
            end

            % POI names
            if nargout > 2
                tcv{tcfi} = vid;
            end

            % increase counter
            tcfi = tcfi + 1;

            % keep UI alive
            drawnow;
        end
    end
catch ne_eo;

    % re-set transiosize
    xff(0, 'transiosize', tios);

    % free copied POI/MTC object
    clearxffobjects(tco);

    % bail out
    rethrow(ne_eo);
end

% re-set transiosize
xff(0, 'transiosize', tios);

% free copied POI object as well as MTC object
clearxffobjects(tco);
