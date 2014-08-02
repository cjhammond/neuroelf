function ccvmp = vtc_CrossCorrelate(hfile, hfile2, opts)
% VTC::CrossCorrelate  - create CC map of two VTCs
%
% FORMAT:       ccvmp = vtc.CrossCorrelate(vtc2 [, opts])
%
% Input fields:
%
%       vtc2        second VTC (must match in dims and layout)
%       opts        options settings
%        .lag       lagged correlation, default: 0
%        .reverse   reverse time courses of second VTC
%        .spatial   perform spatial cross-correlation
%        .tfiltfrq  temporal filter frequency cut-off (default: 3)
%        .tfilttyp  filtering type, either of {'DCT'}, 'Fourier'
%        .trobust   perform filtering robustly
%
% Output fields:
%
%       ccvmp       cross-correlation r-VMP
%
% Note: the toolbox internal cov_nd function is used which gives
%       slightly different r values than corrcoef.

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
   ~xffisobject(hfile, true, 'vtc') || ...
    numel(hfile2) ~= 1 || ...
   ~xffisobject(hfile2, true, 'vtc')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bb1 = aft_Layout(hfile);
bb2 = aft_Layout(hfile2);
if any(bb1 ~= bb2)
    error( ...
        'xff:BadArgument', ...
        'Dimensions and/or Layout mismatch.' ...
    );
end
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'lag') || ...
   ~isa(opts.lag, 'double') || ...
    numel(opts.lag) ~= 1 || ...
    isinf(opts.lag) || ...
    isnan(opts.lag) || ...
    opts.lag < 1
    opts.lag = {};
else
    opts.lag = {floor(opts.lag)};
end
if ~isfield(opts, 'reverse') || ...
    numel(opts.reverse) ~= 1 || ...
   ~islogical(opts.reverse)
    opts.reverse = false;
else
    opts.reverse = opts.reverse(1);
end
if opts.reverse
    revstr = ' TC-reversed';
else
    revstr = '';
end
if ~isfield(opts, 'spatial') || ...
    numel(opts.spatial) ~= 1 || ...
   ~isa(opts.spatial, 'double') || ...
   ~any((0:3) == opts.spatial)
    opts.spatial = 0;
else
    revstr = sprintf('%s spatial-%d', revstr, opts.spatial);
end
if ~isfield(opts, 'tfiltfrq') || ...
    numel(opts.tfiltfrq) ~= 1 || ...
   ~isa(opts.tfiltfrq, 'double') || ...
    isinf(opts.tfiltfrq) || ...
    opts.tfiltfrq < 0 || ...
    opts.tfiltfrq > 12
    opts.tfiltfrq = [];
end
if hfile == hfile2 && ...
    isempty(opts.tfiltfrq)
    opts.tfiltfrq = 3;
elseif isempty(opts.tfiltfrq)
    opts.tfiltfrq = 0;
end
if ~isfield(opts, 'tfilttyp') || ...
   ~ischar(opts.tfilttyp) || ...
   ~any(strcmpi(opts.tfilttyp(:)', {'dct', 'fourier'}))
    opts.tfilttyp = 'dct';
else
    opts.tfilttyp = lower(opts.tfilttyp(:)');
end

% get contents
sc1 = xffgetscont(hfile.L);
bc1 = sc1.C;
sc2 = xffgetscont(hfile2.L);
bc2 = sc2.C;

% filter content
if opts.tfiltfrq > 0

    % prepare tempfilter options
    topts = opts;
    topts.spat = false;
    topts.tdim = 1;
    topts.temp = true;
    if opts.tfilttyp(1) == 'd'
        topts.tempdct = ceil(size(bc1.VTCData, 1) / opts.tfiltfrq);
        topts.tempsc = 0;
    else
        topts.tempdct = Inf;
        topts.tempsc = opts.tfiltfrq;
    end

    % temp filter data of first object
    bc1.VTCData = tempfilter(double(bc1.VTCData), topts);

    % only one object?
    if hfile == hfile2

        % and also set in second object
        bc2.VTCData = bc1.VTCData;

    % two objects
    else

        % filter second object also
        bc2.VTCData = tempfilter(double(bc2.VTCData), topts);
    end
end

% create vmp
bb1 = aft_BoundingBox(hfile);
ccvmp = newnatresvmp(bb1.BBox, bc1.Resolution, 2);
bcvmp = xffgetcont(ccvmp.L);
bcvmp.OriginatingVTC = sc1.F;
bcvmp.LinkedPRT = bc1.NameOfLinkedPRT;
[p, f1] = fileparts(sc1.F);
[p, f2] = fileparts(sc2.F);
bcvmp.Map.Name = sprintf('CC %s <-> %s%s', f1, f2, revstr);
bcvmp.Map.DF1 = size(bc1.VTCData, 1) - 2;

% for non-spatial correlation
if opts.spatial == 0

    % iterate over last spatial dim
    for z = 1:size(bc1.VTCData, 4);

        % get components for cov_nd
        r1 = double(permute(bc1.VTCData(:, :, :, z), [2, 3, 1, 4]));
        if ~opts.reverse
            r2 = double(permute(bc2.VTCData(:, :, :, z), [2, 3, 1, 4]));
        else
            r2 = double(permute(bc2.VTCData(end:-1:1, :, :, z), [2, 3, 1, 4]));
        end

        % compute r value
        [cc, cr] = cov_nd(r1, r2, opts.lag{:});
        cr(isnan(cr)) = 0;
        bcvmp.Map.VMPData(:, :, z) = single(cr);
    end

% spatial correlation
else

    % temporarily permute VTCData elements
    bc1.VTCData = permute(bc1.VTCData, [2, 3, 4, 1]);
    if hfile == hfile2
        bc2.VTCData = bc1.VTCData;
    else
        bc2.VTCData = permute(bc2.VTCData, [2, 3, 4, 1]);
    end

    % face-displacement
    displace = [1, 0, 0; 0, 1, 0; 0, 0, 1];

    % edge displacement also
    if opts.spatial > 1
        displace = [displace; ...
            1, 1, 0; 1, -1, 0; 1, 0, 1; 1, 0, -1; 0, 1, 1; 0, 1, -1];
    end

    % vertex displacement also
    if opts.spatial > 2
        displace = [displace; ...
            1, 1, 1; 1, 1, -1; 1, -1, 1; 1, -1, -1];
    end

    % create necessary map space
    vsz = size(bc1.VTCData);
    vsz(4) = [];
    vs1 = 2:(vsz(1) - 1);
    vs2 = 2:(vsz(2) - 1);
    vs3 = 2:(vsz(3) - 1);
    crm = zeros([vsz, 2 * size(displace, 1)]);
    crs = logical(crm);

    % iterate over displacements
    for dc = 1:size(displace, 1)

        % get displacement values
        d = displace(dc, :);
        d1 = d(1);
        d2 = d(2);
        d3 = d(3);

        % then cross-correlate with shifted matrix
        [cc, cr] = cov_nd(bc1.VTCData(vs1, vs2, vs3, :), ...
            bc2.VTCData(vs1+d1, vs2+d2, vs3+d3, :));

        % correct array, and z-transform
        cr = fisherr2z(limitrangec(cr, eps - 1, 1 - eps, 0));

        % then add to target
        crm(vs1, vs2, vs3, 2 * dc - 1) = cr;
        crs(vs1, vs2, vs3, 2 * dc - 1) = true;

        % and repeat for opposite direction
        [cc, cr] = cov_nd(bc1.VTCData(vs1, vs2, vs3, :), ...
            bc2.VTCData(vs1-d1, vs2-d2, vs3-d3, :));
        cr = fisherr2z(limitrangec(cr, eps-1, 1-eps, 0));
        crm(vs1, vs2, vs3, 2 * dc) = cr;
        crs(vs1, vs2, vs3, 2 * dc) = true;
    end

    % finally sum over crm/crs and combine
    cr = fisherr2z(limitrangec(sum(crm, 4) ./ sum(crs, 4), ...
        -100, 100, 0), true);

    % and put into map
    bcvmp.Map.VMPData = single(cr);
end

% set data to VMP
bcvmp.Map.BonferroniValue = sum(bcvmp.Map.VMPData(:) ~= 0);
fdrl = [0.1, 0.05, 0.04, 0.03, 0.02, 0.01, 0.005, 0.001];
fdrt2 = applyfdr(double(bcvmp.Map.VMPData), 'r', fdrl(:), bcvmp.Map.DF1, 0, true);
bcvmp.Map.FDRThresholds = [fdrl(:), fdrt2];
bcvmp.Map.NrOfFDRThresholds = numel(fdrl);
bcvmp.Map.LowerThreshold = fdrt2(end);
bcvmp.Map.UpperThreshold = min(1, 2 * fdrt2(end));

% override for spatial and same object
if hfile == hfile2 && ...
    opts.spatial > 0
    mmm = minmaxmean(abs(bcvmp.Map.VMPData(bcvmp.Map.VMPData ~= 0)), 5);
    bcvmp.Map.LowerThreshold = mmm(3) - 0.5 * sqrt(mmm(6));
    bcvmp.Map.UpperThreshold = min(1, mmm(3) + 1.5 * sqrt(mmm(6)));
end
xffsetcont(ccvmp.L, bcvmp);
