function onsets = mdm_ConditionOnsets(hfile, stlist, opts)
% MDM::ConditionOnsets  - read onsets from PRTs in an MDM file
%
% FORMAT:       onsets = mdm.ConditionOnsets(stlist, [options])
%
% Input fields:
%
%       stlist      list of conditions to extract onsets for
%       options     optional 1x1 struct with fields
%        .collapse  Cx2 or Cx3 cell array with PRT::Collapse arguments
%        .prtr      1x1 or Sx1 TR if PRTs in Volumes
%
% Output fields:
%
%       onsets      SxC cell array with OnOffsets from PRTs

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2011, 2014, Jochen Weber
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
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'mdm')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
sc = xffgetscont(hfile.L);
bc = sc.C;
hc = sc.H;
rfiles = bc.XTC_RTC(:, end);
numstudy = numel(rfiles);
if nargin < 2 || ...
   ~iscell(stlist) || ...
    isempty(stlist)
    if isfield(hc, 'OOstlist') && ...
        iscell(hc.OOstlist) && ...
       ~isempty(hc.OOstlist) && ...
        isfield(hc, 'OOstcols') && ...
        isa(hc.OOstcols, 'double') && ...
        isequal(size(hc.OOstcols), [numel(hc.OOstlist), 3])
        stlist = hc.OOstlist(:);
    else
        try
            prts = {[]};
            for stc = 1:numstudy
                prts{1} = xff(rfiles{stc});
                if ~xffisobject(prts{1}, true, 'prt')
                    error( ...
                        'xff:BadArgument', ...
                        'Single-trial SDMs only possible with all-PRTs in XTC_RTC.' ...
                    );
                end
                if stc == 1
                    [stlist, stcols] = prt_ConditionNames(prts{1});
                else
                    [clist, ccols] = prt_ConditionNames(prts{1});
                    clmatch = (multimatch(clist, stlist) == 0);
                    if any(clmatch)
                        stlist = cat(1, stlist, clist(clmatch));
                        stcols = cat(1, stcols, ccols(clmatch, :));
                    end
                end
                xffclear(prts{1}.L);
                prts{1} = [];
            end
        catch ne_eo;
            clearxffobjects(prts);
            rethrow(ne_eo);
        end
        hc.OOstcols = stcols;
        hc.OOstlist = stlist;
        sc.H = hc;
        xffsetscont(hfile.L, sc);
    end
end
stlist = stlist(:);
numcond = numel(stlist);
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'collapse') || ...
   ~iscell(opts.collapse) || ...
   ~any([2, 3] == size(opts.collapse, 2)) || ...
    ndims(opts.collapse) ~= 2 || ...
    isempty(opts.collapse)
    collapse = cell(0, 2);
else
    collapse = opts.collapse;
end
tfiles = bc.XTC_RTC(:, end-1);
if isfield(hc, 'OnOffsets') && ...
    iscell(hc.OnOffsets) && ...
    size(hc.OnOffsets, 1) == numstudy && ...
    isfield(hc, 'OOcollapse') && ...
    iscell(hc.OOcollapse) && ...
    numel(hc.OOcollapse) == numel(collapse) && ...
    isequal(hc.OOcollapse, collapse) && ...
    isfield(hc, 'OOstlist') && ...
    iscell(hc.OOstlist) && ...
    numel(hc.OOstlist) == numel(stlist) && ...
    all(strcmp(hc.OOstlist(:), stlist))
    onsets = hc.OnOffsets;
    return;
end
if ~isfield(opts, 'prtr') || ...
   ~isa(opts.prtr, 'double') || ...
   ~any([1, numstudy] == numel(opts.prtr)) || ...
    any(isinf(opts.prtr(:)) | isnan(opts.prtr(:)) | opts.prtr(:) <= 0)
    if isfield(hc, 'TR') && ...
        numel(hc.TR) == numstudy
        opts.prtr = hc.TR(:);
    else
        opts.prtr = [];
    end
else
    opts.prtr = opts.prtr(:);
end
if ~isfield(opts, 'tshift') || ...
   ~isa(opts.tshift, 'double') || ...
    numel(opts.tshift) ~= 1 || ...
    isinf(opts.tshift) || ...
    isnan(opts.tshift)
    opts.tshift = 0;
end

% read TR (and number of volumes) from files
if isempty(opts.prtr)
    try
        nvol = zeros(numstudy, 1);
        prtr = zeros(numstudy, 1);
        for stc = 1:numel(opts.prtr)
            trstr = xff(tfiles{stc}, 'h');
            if isfield(trstr, 'NrOfVolumes')
                nvol(stc) = trstr.NrOfVolumes;
            else
                nvol(stc) = trstr.NrOfTimePoints;
            end
            prtr(stc) = trstr.TR;
        end
    catch ne_eo;
        rethrow(ne_eo);
    end
    hc.NrOfVolumes = nvol;
    hc.TR = prtr;
    sc.H = hc;
    xffsetscont(hfile.L, sc);
elseif numel(opts.prtr) == 1
    opts.prtr = opts.prtr(ones(1, numstudy), 1);
end

% create output
onsets = repmat({zeros(0, 2)}, numstudy, numcond);

% read
prts = {[]};
try
    for stc = 1:numstudy
        prts{1} = xff(rfiles{stc});
        if ~xffisobject(prts{1}, true, 'prt')
            error( ...
                'xff:BadArgument', ...
                'Single-trial SDMs only possible with all-PRTs in XTC_RTC.' ...
            );
        end
        for cc = 1:size(collapse, 1)
            prt_Collapse(prts{1}, collapse{cc, :});
        end
        prtc = xffgetcont(prts{1}.L);
        if lower(prtc.ResolutionOfTime(1)) ~= 'm'
            prt_ConvertToMS(prts{1}, opts.prtr(stc));
            prtc = xffgetcont(prts{1}.L);
        end
        prtcond = prt_ConditionNames(prts{1});
        xffclear(prts{1}.L);
        for cc = 1:numcond
            mmi = find(strcmpi(stlist{cc}, prtcond));
            if ~isempty(mmi)
                onsets{stc, cc} = [ ...
                    cat(1, prtc.Cond(mmi).OnOffsets + opts.tshift), ...
                    cat(1, prtc.Cond(mmi).Weights)];
            end
        end
    end
    hc.OnOffsets = onsets;
    sc.H = hc;
    xffsetscont(hfile.L, sc);
catch ne_eo;
    clearxffobjects(prts);
    rethrow(ne_eo);
end
