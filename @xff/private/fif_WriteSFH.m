function sfh = fif_WriteSFH(hfile, sfhfile)
% FIF::WriteSFH  - write SFH file
%
% FORMAT:       sfh = fif.CreateCTC(sfhfile)
%
% Input fields:
%
%       sfhfile     name of SFH output file
%
% Output fields:
%
%       sfh         the created object

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
   ~xffisobject(hfile, true, 'fif') || ...
   ~ischar(sfhfile) || ...
    isempty(sfhfile)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
sfhfile = sfhfile(:)';

% get object
bc = xffgetcont(hfile.L);

% create CTC in memory
sfh = xff('new:sfh');
sfc = xffgetcont(sfh.L);

% get fif shortcut
fif = bc.FIFStructure;

% any dig points ?
iel = any(fif.Lookup == 213);
if ~iel
    xff(0, 'clearobj', sfh.L);
    error( ...
        'xff:BadInputFile', ...
        'FIF file does not contain DigPoint tags.' ...
    );
end

% get all DigPoints
dps = fif_Value(hfile, 'DigPoint');

% parse dig points
cfid = zeros(1, 0);
chpi = zeros(1, 0);
cext = zeros(1, 0);
for pc = 1:numel(dps)
    switch lower(dps(pc).Kind)
        case {'headfiducial'}
            if ~any(dps(pc).Ident == [1, 2, 3])
                xff(0, 'clearobj', sfh.L);
                error( ...
                    'xff:UnexpectedToken', ...
                    'Only three major fiducials supported.' ...
                );
            end
            cfid(dps(pc).Ident) = pc;
        case {'hpipoint'}
            chpi(dps(pc).Ident) = pc;
        case {'extrapoint'}
            cext(dps(pc).Ident) = pc;
        otherwise
            warning( ...
                'xff:UnexpectedToken', ...
                'Unknown kind of DigPoint %d for point %d.', ...
                dps(pc).Kind, pc ...
            );
    end
end
if numel(cfid) ~= 3 || ...
    any([cfid, chpi, cext] == 0)
	xff(0, 'clearobj', sfh.L);
    error( ...
        'xff:InvalidFile', ...
        'Invalid organization of fiducial points.' ...
    );
end

% build fiducial list
fstr = struct;
fstr.Fid_T9  = [1000 * dps(cfid(1)).Coord, 3, 255, 128, 255];
fstr.Fid_Nz  = [1000 * dps(cfid(2)).Coord, 3, 255, 128, 255];
fstr.Fid_T10 = [1000 * dps(cfid(3)).Coord, 3, 255, 128, 255];
for fc = 1:numel(chpi)
    fstr.(sprintf('HPI_%d', fc + 3)) = ...
        [1000 * dps(chpi(fc)).Coord, 2, 0, 255, 0];
end
for fc = 1:numel(cext)
    fstr.(sprintf('Extra_%d', fc + 3 + numel(chpi))) = ...
        [1000 * dps(cext(fc)).Coord, 2, 0, 255, 255];
end

% set number of points and save
sfc.Fiducials = fstr;
sfc.NrOfPoints = numel(fieldnames(fstr));
xffsetcont(sfh.L, sfc);
try
    aft_SaveAs(sfh, sfhfile);
catch ne_eo;
    warning( ...
        'xff:SaveFailed', ...
        'Saving SFH file failed: %s.', ...
        ne_eo.message ...
    );
end
