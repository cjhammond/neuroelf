% FUNCTION ne_vmr_dbreco: create direct border reconstruction SRF
function varargout = ne_vmr_dbreco(varargin)

% Version:  v0.9d
% Build:    14063011
% Date:     Jun-30 2014, 11:59 AM EST
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

% global variable
global ne_gcfg;
cc = ne_gcfg.fcfg;
ch = ne_gcfg.h;
ci = ne_gcfg.c.ini.Surface;

% initialize output
varargout = cell(1, nargout);

% test SliceVar
svar = cc.SliceVar;
if numel(svar) ~= 1 || ...
   ~isxff(svar, 'vmr')
    return;
end

% set pointer to watch
mfp = ch.MainFig.Pointer;
ch.MainFig.Pointer = 'watch';
drawnow;

% try to run DBReco on VMR
try
    srf = bless(svar.DBReco(struct( ...
        'onesurf', ci.RecoOneSurfaceOnly, ...
        'tps',     ci.RecoTriPerVoxelFace)));
    if ~isxff(srf, true)
        ch.MainFig.Pointer = mfp;
        return;
    end
    if srf.NrOfVertices < 3
        srf.ClearObject;
        uiwait(warndlg('No voxels marked/transformed.', ...
            'NeuroElf - error message', 'modal'));
        ch.MainFig.Pointer = mfp;
        return;
    end
    srf.ConvexRGBA = (1 / 255) .* [ci.RecoColors(1, :), 1];
    srf.ConcaveRGBA = (1 / 255) .* [ci.RecoColors(2, :), 1];
    ne_openfile(0, 0, srf, true);

    % assign to output
    varargout{1} = srf;

% handle errors
catch ne_eo;
    uiwait(warndlg(sprintf('Error building DBReco of VMR: %s.', ...
        ne_eo.message), 'NeuroElf - error message', 'modal'));
end

% set pointer back to arrow
ch.MainFig.Pointer = mfp;
