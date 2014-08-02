function hfile = vmr_MinBox(hfile, minval, fringe)
% VMR::Reframe  - reframe the VMR to fit a minimum box
%
% FORMAT:       vmr.MinBox([minval [, fringe]])
%
% Input fields:
%
%       minval      minimum value (default: 1)
%       fringe      additional fringe (e.g. for operations, default: 1)
%
% No output fields.
%
% Note: this function removes any filename association!

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
        'Invalid call to %s.', ...
        mfilename ...
    );
end
if nargin < 2 || ...
   ~isa(minval, 'double') || ...
    numel(minval) ~= 1 || ...
    isinf(minval) || ...
    isnan(minval) || ...
    minval < 1
    minval = 1;
end
if nargin < 3 || ...
   ~isa(fringe, 'double') || ...
    numel(fringe) ~= 1 || ...
    isinf(fringe) || ...
    isnan(fringe) || ...
    fringe < 0
    fringe = 1;
else
    fringe = min(511, round(fringe));
end

% get contents
sc = xffgetscont(hfile.L);
bc = sc.C;
osz = size(bc.VMRData);

% minsize
if ~isempty(bc.VMRData16)
    [bc.VMRData16, off, sz] = ...
        minarray(bc.VMRData16(:, :, :), minval, 65535, fringe);
    ofs = off + sz - 1;
    bc.VMRData = bc.VMRData(off(1):ofs(1), off(2):ofs(2), off(3):ofs(3));
else
    [bc.VMRData, off, sz] = minarray(bc.VMRData(:, :, :));
end

% update UndoBuffer
if isfield(bc.RunTimeVars, 'UndoBuffer') && ...
    isequal(size(bc.RunTimeVars.UndoBuffer), osz)
    ofs = off + sz - 1;
    bc.RunTimeVars.UndoBuffer = ...
        bc.RunTimeVars.UndoBuffer(off(1):ofs(1), off(2):ofs(2), off(3):ofs(3));
end

% reject empty data
if isempty(bc.VMRData)
    error( ...
        'xff:EmptyData', ...
        'VMR empty. Invalid call.' ...
    );
end

% update size and offsets
off = off - 1;
bc.DimX = sz(1);
bc.DimY = sz(2);
bc.DimZ = sz(3);
bc.OffsetX = bc.OffsetX + off(1);
bc.OffsetY = bc.OffsetY + off(2);
bc.OffsetZ = bc.OffsetZ + off(3);

% set content (and clear filename, reload is not valid!)
sc.C = bc;
sc.F = '';
xffsetscont(hfile.L, sc);
