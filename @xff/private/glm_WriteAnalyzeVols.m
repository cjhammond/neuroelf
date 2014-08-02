function rvalue = glm_WriteAnalyzeVols(hfile, cons)
% GLM::WriteAnalyzeVols  - write Analyze images from a GLM file
%
% FORMAT:       [success = ] glm.WriteAnalyzeVols(cons)
%
% Input fields:
%
%       cons        1xC struct with settings
%        .c         Px1 contrast vector
%        .pattern   filename pattern with tokens
%                   $s for subject ID
%                   $c contrast name with _ and GT replacements
%                   if empty, default: '$s_$c.img'
%
% Output fields:
%
%       success     true if successful

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
   ~xffisobject(hfile, true, 'glm') || ...
   ~isstruct(cons) || ...
    isempty(cons) || ...
   ~isfield(cons, 'c')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
sc = xffgetscont(hfile.L);
bc = sc.C;
if isempty(bc.Map) || ...
    mapno > numel(bc.Map)
    error( ...
        'xff:BadArgument', ...
        'Empty VMP or map number too high.' ...
    );
end
bcm = bc.Map(mapno);

% default rvalue
rvalue = false;

% filename
filename = sc.F;
filename = [filename(1:end-3) 'img'];
hdrfname = [filename(1:end-3) 'hdr'];
matfname = [filename(1:end-3) 'mat'];

% dimension and datatype
resxyz = bc.Resolution;
vmpdat = single(permute(bcm.VMPData(end:-1:1, end:-1:1, end:-1:1), [3, 1, 2]));
vmpdsc = bcm.Name;
if numel(vmpdsc) > 80
    vmpdsc = [vmpdsc(1:77) '...'];
end
isiz = size(vmpdat);
offx = bc.ZEnd - 128;
offy = bc.XEnd - 128;
offz = bc.YEnd - 128;
orgx = 1 + round(offx / resxyz);
orgy = 1 + round(offy / resxyz);
orgz = 1 + round(offz / resxyz);

% build mat
tmat = resxyz .* eye(4);
tmat(end) = 1;
tmat(1:3, 4) = -[offx; offy; offz];

% try volume creation
hdrc = cell(1, 1);
try
    hdr = xff('new:hdr');
    hdrc{1} = hdr;
    hdrbc = xffgetcont(hdr.L);
catch ne_eo;
    clearxffobjects(hdrc);
    error( ...
        'xff:InternalError', ...
        'Error creating Analyze header object: %s.', ...
        ne_eo.message ...
    );
end

% set dims and data
hdrbc.ImgDim.Dim(1:4) = [3, isiz];
hdrbc.ImgDim.PixSpacing(2:4) = [resxyz, resxyz, resxyz];
hdrbc.ImgDim.DataType = 16;
hdrbc.ImgDim.BitsPerPixel = 32;
hdrbc.ImgDim.CalMaxDisplay = 32767;
hdrbc.ImgDim.CalMinDisplay = -32768;
hdrbc.DataHist.Description = vmpdsc;
hdrbc.DataHist.OriginSPM = [orgx, orgy, orgz, 0, 0];
hdrbc.VoxelData = vmpdat;
xffsetcont(hdr.L, hdrbc);

% save hdr/img
try
    aft_SaveAs(hdr, hdrfname);
    rvalue = hdr_SaveVoxelData(hdr);
catch ne_eo;
    warning( ...
        'xff:InternalError', ...
        'Error writing Analyze header/image %s (%s).', ...
        hdrfname, ne_eo.message ...
    );
    return;
end
if ~rvalue
    return;
end

% save mat
try
    eval('M=tmat;mat=tmat;save(matfname,''M'',''mat'',''-v6'');')
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end
if exist(matfname, 'file') ~= 2
    rvalue = false;
end
