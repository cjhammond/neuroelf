function dmr = fmr_ConvertToDMR(hfile, dmrfile)
% FMR::ConvertToDMR  - convert an FMR to DMR
%
% FORMAT:       dmr = fmr.ConvertToDMR(dmrfile)
%
% Input fields:
%
%       dmrfile     name of output DMR file
%
% Output fields:
%
%       dmr         created DMR object
%
% Note: the DWI data file will be created and then linked as transio.

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
   ~xffisobject(hfile, true, 'fmr') || ...
   ~ischar(dmrfile) || ...
    isempty(dmrfile)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
dmrfile = dmrfile(:)';

% try DMR save first
dmr = xff('new:dmr');
try
    aft_SaveAs(dmr, dmrfile);
catch ne_eo;
    xffclear(dmr.L);
    error( ...
        'xff:SaveFailed', ...
        'Error saving DMR file: %s.', ...
        ne_eo.message ...
    );
end

% get filename particles
[fnp{1:3}] = fileparts(dmrfile);
if isempty(fnp{1})
    fnp{1} = '.';
end
dwifile = [fnp{1} '/' fnp{2} '.dwi'];

% get FMR content
sc = xffgetscont(hfile.L);
bc = sc.C;

% get resolution
res = [bc.ResolutionX, bc.ResolutionY, bc.NrOfSlices, bc.NrOfVolumes];

% get DWI data from Slice
if bc.DataStorageFormat == 1
    dwid = uint16(zeros(res));
    for slc = 1:res(3)
        dwid(:, :, slc, :) = ...
            reshape(bc.Slice(slc).STCData(:, :, :), [res(1:2), 1, res(4)]);
    end
else
    dwid = permute(bc.Slice.STCData(:, :, :, :), [1, 2, 4, 3]);
end

% create temporary DWI
dwi = xff('new:dwi');
dwic = xffgetcont(dwi.L);
dwic.NrOfVolumes = res(4);
dwic.NrOfSlices = res(3);
dwic.ResolutionX = res(1);
dwic.ResolutionY = res(2);
dwic.DWIData = dwid;
xffsetcont(dwi.L, dwic);
try
    aft_SaveAs(dwi, dwifile);
catch ne_eo;
    xffclear(dwi.L);
    error( ...
        'xff:SaveError', ...
        'Error saving DWI data to file: %s', ...
        ne_eo.message ...
    );
end
xffclear(dwi.L);

% copy fields to DMR
dmrc = xffgetcont(dmr.L);
dmrc.NrOfVolumes                    = bc.NrOfVolumes;
dmrc.NrOfSlices                     = bc.NrOfSlices;
dmrc.NrOfSkippedVolumes             = bc.NrOfSkippedVolumes;
dmrc.Prefix                         = fnp{2};
dmrc.DataType                       = bc.DataType;
dmrc.DataStorageFormat              = 3;
dmrc.TR                             = bc.TR;
dmrc.InterSliceTime                 = bc.InterSliceTime;
dmrc.TimeResolutionVerified         = bc.TimeResolutionVerified;
dmrc.TE                             = bc.TE;
dmrc.SliceAcquisitionOrder          = bc.SliceAcquisitionOrder;
dmrc.SliceAcquisitionOrderVerified  = bc.SliceAcquisitionOrderVerified;
dmrc.ResolutionX                    = bc.ResolutionX;
dmrc.ResolutionY                    = bc.ResolutionY;
dmrc.LoadAMRFile                    = bc.LoadAMRFile;
dmrc.ShowAMRFile                    = bc.ShowAMRFile;
dmrc.ImageIndex                     = bc.ImageIndex;
dmrc.LayoutNColumns                 = bc.LayoutNColumns;
dmrc.LayoutNRows                    = bc.LayoutNRows;
dmrc.LayoutZoomLevel                = bc.LayoutZoomLevel;
dmrc.SegmentSize                    = bc.SegmentSize;
dmrc.SegmentOffset                  = bc.SegmentOffset;
dmrc.ProtocolFile                   = bc.ProtocolFile;
dmrc.InplaneResolutionX             = bc.InplaneResolutionX;
dmrc.InplaneResolutionY             = bc.InplaneResolutionY;
dmrc.SliceThickness                 = bc.SliceThickness;
dmrc.SliceGap                       = bc.SliceGap;
dmrc.VoxelResolutionVerified        = bc.VoxelResolutionVerified;
dmrc.PosInfosVerified               = bc.PosInfosVerified;
dmrc.CoordinateSystem               = bc.CoordinateSystem;
dmrc.Slice1CenterX                  = bc.Slice1CenterX;
dmrc.Slice1CenterY                  = bc.Slice1CenterY;
dmrc.Slice1CenterZ                  = bc.Slice1CenterZ;
dmrc.SliceNCenterX                  = bc.SliceNCenterX;
dmrc.SliceNCenterY                  = bc.SliceNCenterY;
dmrc.SliceNCenterZ                  = bc.SliceNCenterZ;
dmrc.RowDirX                        = bc.RowDirX;
dmrc.RowDirY                        = bc.RowDirY;
dmrc.RowDirZ                        = bc.RowDirZ;
dmrc.ColDirX                        = bc.ColDirX;
dmrc.ColDirY                        = bc.ColDirY;
dmrc.ColDirZ                        = bc.ColDirZ;
dmrc.NRows                          = bc.NRows;
dmrc.NCols                          = bc.NCols;
dmrc.FoVRows                        = bc.FoVRows;
dmrc.FoVCols                        = bc.FoVCols;
dmrc.GapThickness                   = bc.GapThickness;
dmrc.NrOfPastSpatialTransformations = bc.NrOfPastSpatialTransformations;
dmrc.Trf                            = bc.Trf;
dmrc.Convention                     = bc.Convention;
dmrc.FirstDataSourceFile            = bc.FirstDataSourceFile;
dmrc.GradientDirectionsVerified     = 'NO';
dmrc.GradientInformationAvailable   = 'NO';

% set content back
xffsetcont(dmr.L, dmrc);

% save
aft_SaveAs(dmr, dmrfile);
try
    aft_ReloadFromDisk(dmr);
catch ne_eo;
    warning( ...
        'xff:LoadError', ...
        'Error re-loading DMR from disk (for DWI access): %s', ...
        ne_eo.message ...
    );
end
