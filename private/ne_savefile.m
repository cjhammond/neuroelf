% PUBLIC FUNCTION ne_savefile: save the selected slice/stats file (as...)
function varargout = ne_savefile(varargin)

% Version:  v0.9b
% Build:    11050712
% Date:     Apr-10 2011, 4:52 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

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

% global variable
global ne_gcfg;
cc = ne_gcfg.fcfg;
ch = ne_gcfg.h;

% preset output
if nargout > 0
    varargout = cell(1, nargout);
end

% get var to save
try
    svar = cc.(varargin{3});
    if nargout > 0
        varargout{1} = svar;
    end

    % save
    if varargin{4} == 0 && ...
       ~isempty(svar.FilenameOnDisk)
        svar.Save;

        % echo
        if ne_gcfg.c.echo
            ne_echo(varargin{3}, 'Save');
        end

    % or save as
    else
        svar.SaveAs;
        if ne_gcfg.c.echo
            ne_echo(varargin{3}, 'SaveAs', svar.FilenameOnDisk);
        end

        % then also update name in control's list
        h = ch.(varargin{3});
        [fp, fn, fe] = fileparts(svar.FilenameOnDisk);
        h.String{h.Value} = [fn, fe];
    end
catch ne_eo;
    rethrow(ne_eo);
end
