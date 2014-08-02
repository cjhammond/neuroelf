function hfile = aft_Browse(hfile, varargin)
% AFT::Browse  - add variable to GUI
%
% FORMAT:       obj.Browse;
%
% No input/output fields.
%
% TYPES: AVA, CMP, DMR, DDT, FMR, GLM, HEAD, HDR, MSK, MTC, NLF, SMP, SRF, TVL, VDW, VMP, VMR, VTC
%
% Note: this function requires GUI being available (figure/uicontrol).

% Version:  v0.9d
% Build:    14030412
% Date:     Mar-04 2014, 12:45 PM EST
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

% global config
global ne_gcfg;

% argument check
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to ''%s''.', ...
        mfilename ...
    );
end

% for certain files, do nothing
ft = aft_Filetype(hfile);
switch (lower(ft))
    case {'ava', 'cmp', 'dmr', 'fmr', 'glm', 'head', 'hdr', 'msk', ...
          'mtc', 'nlf', 'smp', 'srf', 'v16', 'vdw', 'vmp', 'vmr', 'vtc'}
        % simply pass control to GUI
        try
            if isempty(ne_gcfg)
                neuroelf_gui;
            end
            neuroelf_gui('openfile', hfile);
        catch ne_eo;
            rethrow(ne_eo);
        end

        % for a sub-set
        if any(strcmp(ft, {'cmp', 'glm', 'vmp'})) && ...
            nargin > 1 && ...
            isa(varargin{1}, 'double') && ...
           ~isempty(varargin{1}) && ...
           ~any(isinf(varargin{1}(:)) | isnan(varargin{1}(:))) && ...
            all(varargin{1}(:) > 0 & varargin{1}(:) == fix(varargin{1}(:)))
            try
                neuroelf_gui('setcstatmap', varargin{1}(:));
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        elseif strcmp(ft, 'mtc') && ...
            nargin > 1 && ...
            isa(varargin{1}, 'double') && ...
           ~isempty(varargin{1}) && ...
           ~any(isinf(varargin{1}(:)) | isnan(varargin{1}(:))) && ...
            all(varargin{1}(:) > 0 & varargin{1}(:) == fix(varargin{1}(:)))
            if nargin > 2 && ...
                isa(varargin{2}, 'double') && ...
                numel(varargin{2}) == 1 && ...
               ~isinf(varargin{2}) && ...
               ~isnan(varargin{2}) && ...
                varargin{2} >= 1
                bc = xffgetcont(hfile.L);
                bc.RunTimeVars.SubMapVol = varargin{2};
                xffsetcont(hfile.L, bc);
            end
            try
                neuroelf_gui('setcsrfstatmap', varargin{1}(:));
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        elseif strcmp(ft, 'vtc') && ...
            nargin > 1 && ...
            isa(varargin{1}, 'double') && ...
           ~isempty(varargin{1}) && ...
           ~any(isinf(varargin{1}(:)) | isnan(varargin{1}(:))) && ...
            all(varargin{1}(:) > 0 & varargin{1}(:) == fix(varargin{1}(:)))
            try
                bc = xffgetcont(hfile.L);
                if isfield(bc.RunTimeVars, 'AvgVTC') && ...
                    islogical(bc.RunTimeVars.AvgVTC) && ...
                    numel(bc.RunTimeVars.AvgVTC) == 1 && ...
                    bc.RunTimeVars.AvgVTC
                    neuroelf_gui('setcstatmap', varargin{1}(:));
                end
            catch ne_eo;
                neuroelf_lasterr(ne_eo);
            end
        end
end
