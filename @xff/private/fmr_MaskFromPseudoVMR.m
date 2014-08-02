function hfile = fmr_MaskFromPseudoVMR(hfile, vmr, mval, mtype, flipped)
% FMR::MaskFromPseudoVMR  - apply (pseudo) VMR mask on FMR data
%
% FORMAT:       fmr.MaskFromPseudoVMR(vmr [,mval, mtype, flipped])
%
% Input fields:
%
%       vmr         pseudo VMR object, must match dimensions!
%       mval        masking value, default: 240
%       mtype       type, either of {'keep'}, 'null'
%       flipped     boolean, flip along BV's Y axis, default: true
%
% Output fields:
%
%       fmr         FMR with altered slices (renamed)
%
% See also FMR::CreatePseudoVMR

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
    numel(vmr) ~= 1 || ...
   ~xffisobject(hfile, true, 'fmr') || ...
   ~xffisobject(vmr, true, 'vmr')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
vmrc = xffgetcont(vmr.L);
dtsf = bc.DataStorageFormat;
if isempty(bc.Slice) || ...
    ~isstruct(bc.Slice) || ...
    ~isfield(bc.Slice, 'STCData')
    try
        fmr_LoadSTC(hfile);
        bc = xffgetcont(hfile.L);
        slc = bc.Slice;
    catch ne_eo;
        error( ...
            'xff:InternalError', ...
            'Error loading slices: ''%s''.', ...
            ne_eo.message ...
        );
    end
else
    slc = bc.Slice;
end
if nargin < 3 || ...
   ~isa(mval, 'double') || ...
    numel(mval) ~= 1 || ...
    isinf(mval) || ...
    isnan(mval) || ...
    mval < 0 || ...
    mval > 255
    mval = 240;
else
    mval = fix(real(mval));
end
if nargin < 4 || ...
   ~ischar(mtype) || ...
   ~strcmpi(mtype(:)', 'null')
    mtype = 1;
else
    mtype = 0;
end
if nargin < 5 || ...
    numel(flipped) ~= 1 || ...
   (~isnumeric(flipped) && ~islogical(flipped)) || ...
    flipped(1)
    flipped = true;
else
    flipped = false;
end

% check dimensions
vdn = zeros(1, 3);
vdn(2) = size(vmrc.VMRData, 1);
vdz = size(vmrc.VMRData, 2);
vdn(1) = size(vmrc.VMRData, 3);
if dtsf == 1
    if numel(slc) ~= vdz
        error( ...
            'xff:BadObject', ...
            'Number of slices mismatch.' ...
        );
    end
    vdn(3) = size(slc(1).STCData, 3);
    for sc = 1:vdz
        if numel(size(slc(sc).STCData)) ~= 3 || ...
           ~all(size(slc(sc).STCData) == vdn)
            error( ...
                'xff:BadObject', ...
                'Dimension mismatch.' ...
            );
        end
    end
else
    switch (dtsf)
        case {2}
            vdn(3) = size(slc.STCData, 3);
        case {3}
            vdn(3) = size(slc.STCData, 4);
        case {4}
            vdn(3) = size(slc.STCData, 1);
        otherwise
            error( ...
                'xff:InvalidObject', ...
                'Unsupported DataStorageFormat' ...
            );
    end
    slc.STCData = slc.STCData(:, :, :, :);
end

% reshape VMR data and get
vmrd = (vmrc.VMRData == mval);
if ~mtype
    vmrd = ~vmrd;
end
vmrd = uint16(shiftdim(vmrd, 2));
if flipped
    vmrd = vmrd(:, :, vdz:-1:1);
end

% depending on data storage format
switch (dtsf)

    % iterate over slices
    case {1}
        vmrm = repmat(vmrd(:, :, sc), [1, 1, vdn(3)]);
        for sc = 1:vdz
            slc(sc).STCData = slc(sc).STCData(:, :, :) .* vmrm;
        end

    % single file, format 2
    case {2}
        vmrm = repmat(vmrd(:, :, sc), [1, 1, vdn(3)]);
        for sc = 1:vdz
            slc.STCData(:, :, :, sc) = slc.STCData(:, :, :, sc) .* vmrm;
        end

    % single file, format 3
    case {3}
        vmrm = repmat(vmrd(:, :, sc), [1, 1, 1, vdn(3)]);
        for sc = 1:vdz
            slc.STCData(:, :, sc, :) = slc.STCData(:, :, :, sc) .* vmrm;
        end

    % single file, format 4
    case {4}
        vsz = size(vmrd);
        vmrm = repmat(reshape(vmrd(:, :, sc), [1, vsz(1), vsz(2)]), [vdn(3), 1]);
        for sc = 1:vdz
            slc.STCData(:, :, :, sc) = slc.STCData(:, :, :, sc) .* vmrm;
        end

    % otherwise
    otherwise
        error( ...
            'xff:OptionUnsupported', ...
            'DataStorageFormat unsupported: %d.', ...
            dtsf ...
        );
end

% put new slices into FMR
bc.Prefix = [bc.Prefix '_m'];
bc.Slice = slc;
xffsetcont(hfile.L, bc);
