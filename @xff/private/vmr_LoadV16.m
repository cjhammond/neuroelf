function hfile = vmr_LoadV16(hfile, v16fname)
% VMR::LoadV16  - load matching V16 file into VMRData16
%
% FORMAT:       [vmr] = vmr.LoadV16([v16fname])
%
% Input fields:
%
%       v16fname    alternative filename, otherwise use VMR's filename
%
% Output fields:
%
%       vmr         VMR object with VMRData16 field set

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
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'vmr')
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end
sbc = xffgetscont(hfile.L);
bc = sbc.C;
if strcmpi(class(bc.VMRData), 'uint16')
    error( ...
        'xff:InvalidObject', ...
        'Method only defined for 8-bit VMRs.' ...
    );
end
if nargin < 2
    [vmrfname{1:3}] = fileparts(sbc.F);
    if isempty(vmrfname{2})
        error( ...
            'xff:InvalidObject', ...
            'This method only works without arguments on loaded VMRs.' ...
        );
    end
    v16fnlc = [vmrfname{1} '/' vmrfname{2} '.v16'];
    v16fulc = [vmrfname{1} '/' vmrfname{2} '.V16'];
    if exist(v16fnlc, 'file') == 2
        v16fname = v16fnlc;
    elseif exist(v16fnuc, 'file') == 2
        v16fname = v16fulc;
    else
        warning( ...
            'xff:FileNotFound', ...
            'The required, auto-linking V16 file was not found.' ...
        );
        return;
    end
elseif ~ischar(v16fname) || ...
    isempty(v16fname) || ...
    exist(v16fname(:)', 'file') ~= 2
    error( ...
        'xff:BadArgument', ...
        'Invalid V16 filename argument.' ...
    );
end
v16fname = v16fname(:)';

% try to load V16
try
    vmr16l = [];
    vmr16 = xff(v16fname);
    vmr16l = vmr16.L;
    vmr16c = xffgetcont(vmr16l);
    if ~all([bc.DimX, bc.DimX, bc.DimX] == ...
            [vmr16c.DimX, vmr16c.DimX, vmr16c.DimX])
        error('DIM_MISMATCH');
    end
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    xffclear(vmr16l);
    error( ...
        'xff:BadObject', ...
        'V16 file not readable or dimension mismatch.' ...
    );
end

% copy read element
bc.VMRData16 = vmr16c.VMRData;
xffclear(vmr16l);
xffsetcont(hfile.L, bc);
