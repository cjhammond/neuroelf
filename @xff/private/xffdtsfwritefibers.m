function xffdtsfwritefibers(fid, fibers)
% xffdtsfwritefibers  - write fibers to DTSF file
%
% FORMAT:       writeok = xffdtsfwritefibers(fid, fibers)
%
% Input fields:
%
%       fid         output file fid (already open)
%       fibers      Nx1 struct array with fields
%        .NrOfPoints   number of points for that fiber
%        .Selected     uint8, either 0 or 1
%        .RGB          1x3 uint8 array
%        .FromToPoint  1x2 double array, [0, NrOfPoints]
%        .Coord        Px3 coordinates of fiber points
%
% Output fields
%
%       fibers      Nx1 struct array with fields
%
% See also xff

% Version:  v0.9b
% Build:    11050711
% Date:     Apr-08 2011, 8:51 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2010, 2011, Jochen Weber
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
   ~isa(fid, 'double') || ...
    isempty(fid) || ...
   ~isreal(fid) || ...
   ~any(fopen('all') == fid(1)) || ...
   ~isstruct(fibers) || ...
   ~isfield(fibers, 'NrOfPoints') || ...
   ~isfield(fibers, 'Selected') || ...
   ~isfield(fibers, 'RGB') || ...
   ~isfield(fibers, 'FromToPoint') || ...
   ~isfield(fibers, 'Coord')
    error( ...
        'xff:BadArgument', ...
        'Bad or missing argument.' ...
    );
end

% try ...
numfib = numel(fibers);
try

    % loop over fibers
    for fc = 1:numfib

        % write fiber data
        fwrite(fid, fibers(fc).NrOfPoints(1)   , 'uint32');
        fwrite(fid, fibers(fc).Selected(1)     , 'uint8');
        fwrite(fid, fibers(fc).RGB(1:3)        , 'uint8');
        fwrite(fid, fibers(fc).FromToPoint(1:2), 'uint32');
        fwrite(fid, fibers(fc).Coord(1:fibers(fc).NrOfPoints(1), 1:3)', 'single');
    end

catch ne_eo;
    rethrow(ne_eo);
end
