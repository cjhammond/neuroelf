function info = aft_Info(hfile)
% AFT::Info  - get info on the terminal about an object
%
% FORMAT:       info = obj.Info;
%
% No input fields.
%
% Output fields:
%
%       info        1x1 struct with additional information, at least
%        .
%
% TYPES: HDR, PRT

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, {'hdr', 'prt'})
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
sc = xffgetscont(hfile.L);
bc = sc.C;
w = whos;
sw = w(strcmp({w.name}, 'bc'));
ss = sw.bytes;
if ss > 1048575
    sh = sprintf('%.3fMb', 0.001 * round(1000 * ss / 1048576));
elseif ss > 1023
    sh = sprintf('%.3fkb', 0.001 * round(1000 * ss / 1024));
else
    sh = sprintf('%gb', ss);
end

% general info
info = struct;
if isempty(sc.F)
    info.Filename = sprintf('<unknown.%s>', lower(sc.S.Extensions{1}));
else
    info.Filename = sc.F;
end
info.Filetype = sc.S.Extensions{1};
info.IOFormat = lower(sc.S.FFTYPE);
info.BytesAllocated = ss;
info.SizeString = sh;

% switch on filetype
ft = lower(sc.S.Extensions{1});
switch (ft)

    % HDR
    case {'hdr'}

        % get coordinate frame (and copy)
        cfr = hdr_CoordinateFrame(hfile);
        info.CoordinateFrame = cfr;

        % DataType
        info.DataType = class(bc.VoxelData);

        % 4D?
        info.FourD = (cfr.DimT > 1);
        info.FourDSize = cfr.DimT;

        % generate layout
        info.Layout = [cfr.DimX, cfr.DimY, cfr.DimZ, ...
            lsqueeze(cfr.Trf(1:3, 1:4))'];

        % get scaling information as one
        info.Scaling = [bc.ImgDim.ScalingIntercept, bc.ImgDim.ScalingSlope];

    % PRT
    case {'prt'}

        % all condition names and number of onsets
        cn = {bc.Cond.ConditionName};
        co = {bc.Cond.OnOffsets};
        cn = cat(2, cn{:});
        if isempty(cn)
            cn = {};
        end
        for oc = 1:numel(co)
            co{oc} = size(co{oc}, 1);
        end
        co = cat(2, co{:});
        if isempty(co)
            co = [];
        end
        info.Conditions = cn;
        if isempty(cn)
            cn = ', ';
        else
            cn = sprintf('%s, ', cn{:});
        end
        info.ConditionNames = cn(1:end-2);
        info.ConditionOnsets = co;

        % total number and first and last onset
        oo = cat(1, bc.Cond.OnOffsets);
        info.TotalOnsets = size(oo, 1);
        info.FirstOnset = min(oo(:, 1));
        info.LastOffset = max(oo(:, 2));
        info.Resolution = bc.ResolutionOfTime;

    % not supported
    otherwise
        error('BAD_FILETYPE');
end
