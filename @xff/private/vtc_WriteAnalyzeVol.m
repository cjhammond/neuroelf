function rvalue = vtc_WriteAnalyzeVol(hfile, volnum, filename)
% VTC::WriteAnalyzeVol  - write an Analyze image from one VTC volume
%
% FORMAT:       [writeok] = vtc.WriteAnalyzeVol(number, filename)
%
% Input fields:
%
%       number      volume (time point) number
%       filename    analyze filename
%
% Output fields:
%
%       writeok     boolean indicator whether write was successful

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
if nargin ~= 3 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vtc')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get object reference
sc = xffgetscont(hfile.L);
bc = sc.C;

% create struct version
ofile = sc.F;
[opath{1:2}] = fileparts(ofile);
ofile = opath{2};

% check further arguments
if nargin < 2 || ...
   ~isa(volnum, 'double') || ...
    numel(volnum) ~= 1 || ...
    isnan(volnum) || ...
    isinf(volnum) || ...
    volnum ~= fix(volnum) || ...
    volnum < 1 || ...
    volnum > bc.NrOfVolumes
    error( ...
        'xff:BadArgument', ...
        'Invalid or missing volnum argument for call to %s.', ...
        mfilename ...
    );
end
if nargin < 3 || ...
   ~ischar(filename) || ...
    isempty(filename) || ...
    numel(filename) ~= length(filename) || ...
    length(filename) < 5 || ...
  (~strcmpi(filename(end-3:end), '.hdr') && ...
   ~strcmpi(filename(end-3:end), '.img'))
    error( ...
        'xff:BadArgument', ...
        'Invalid or missing filename argument for call to %s.', ...
        mfilename ...
    );
end

% filename
filename = filename(:)';
filename = [filename(1:end-3) 'img'];
hdrfname = [filename(1:end-3) 'hdr'];
matfname = [filename(1:end-3) 'mat'];

% voxel and time resolution
vres = bc.Resolution;
tres = bc.TR / 1000;

% dimension and datatype
xpix = (bc.XEnd - bc.XStart) / vres;
ypix = (bc.YEnd - bc.YStart) / vres;
zpix = (bc.ZEnd - bc.ZStart) / vres;
isiz = [xpix, ypix, zpix, 1];

% positional information
xvec = vres .* [0; 1; 0];
yvec = vres .* [0; 0;-1];
zvec = vres .* [1; 0; 0];
svec = [bc.XStart; bc.YStart; bc.ZStart] - 128;

% build mat
tfmat = eye(4);
tfmat(2, 2) = -1;
tmat = [[xvec, yvec, zvec], svec;  0, 0, 0, 1];
tmat = tfmat * tmat;

% try volume creation
hdr = xff('new:hdr');
hdrc = xffgetcont(hdr.L);

% set dims and data
hdrc.ImgDim.Dim(1:5) = [4, isiz];
if bc.FileVersion < 3 || ...
    bc.DataType < 2
    hdrc.ImgDim.DataType = 132;
    hdrc.ImgDim.BitsPerPixel = 16;
    toui16 = true;
else
    hdrc.ImgDim.DataType = 16;
    hdrc.ImgDim.BitsPerPixel = 32;
    toui16 = false;
end
hdrc.ImgDim.PixSpacing(2:5) = [vres, vres, vres, tres];
hdrc.ImgDim.CalMaxDisplay = 32767;
hdrc.ImgDim.CalMinDisplay = 0;
hdrc.ImgDim.GLMax = 32767;
hdrc.ImgDim.GLMin = 0;
hdrc.DataHist.Description = sprintf('Volume %d of VTC %s', volnum, ofile);
hdrc.DataHist.ScanNumber = sprintf('%d', volnum);
if istransio(bc.VTCData)
    try
        bc.VTCData = resolve(bc.VTCData);
        xffsetcont(hfile.L, bc);
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end
if toui16
    hdrc.VoxelData = uint16(round(squeeze(bc.VTCData(volnum, :, :, :))));
else
    hdrc.VoxelData = single(squeeze(bc.VTCData(volnum, :, :, :)));
end

% save hdr/img
try
	aft_SaveAs(hdr, hdrfname);
    rvalue = hdr_SaveVoxelData(hdr);
catch ne_eo;
    xff(0, 'clearobj', hdr.L);
    error( ...
        'xff:InternalError', ...
        'Error writing Analyze header/image %s (%s).', ...
        hdrfname, ne_eo.message ...
    );
end
xff(0, 'clearobj', hdr.L);
if ~rvalue
    return;
end

% save mat
try
    eval('M=tmat;mat=tmat;save(matfname,''M'',''mat'',''-v6'');');
catch ne_eo;
    neuroelf_lasterr(ne_eo);
end
if exist(matfname, 'file') ~= 2
    rvalue = false;
end
