% FUNCTION ne_clonefile: copy data to new object
function varargout = ne_clonefile(varargin)
% ne_clonefile  - add copy of file to workspace and, possibly, controls
%
% FORMAT:       [obj = ] ne_clonefile(src, evt, control)
%
% Input fields:
%
%       src         handle of UI object issuing the call (0 for GUI)
%       evt         event data (currently unused)
%       control     either of 'SliceVar', 'StatsVar'
%
% Output fields:
%
%       obj         object reference (e.g. for filenames)

% Version:  v0.9d
% Build:    14061209
% Date:     Jun-12 2014, 9:44 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2010, 2014, Jochen Weber
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

% only with valid input
if nargin < 3 || ...
   ~ischar(varargin{3}) || ...
    numel(varargin{3}) ~= size(varargin{3}, 2) || ...
   ~any(strcmp(varargin{3}, {'SliceVar', 'StatsVar'}))
    return;
end

% get current selection
slvar = cc.(varargin{3});
if ~isxff(slvar, true)
    return;
end

% create copy of object
slvarcpy = bless(slvar.CopyObject);

% open copy
ne_openfile(0, 0, slvarcpy, true);

% get corresponding variable name
slvarname = cv_varlist(0, 0, slvarcpy);

% set as tool-loaded
if ~isempty(slvarname)
    ne_gcfg.wc.(slvarname) = true;
end

% improve name a little
[fp, fn, fe] = fileparts(slvar.FilenameOnDisk(true));
if isempty(fn)
    fn = 'untitled';
end
if isempty(fe)
    fe = sprintf('.%s', lower(slvar.Filetype));
end
fn = sprintf('<copy of %s%s>', fn, fe);

% find in control
ud = ch.(varargin{3}).UserData;
udf = false;
for udc = 1:size(ud, 1)
    if ud{udc, 4} == slvarcpy
        udf = true;
        break;
    end
end
if udf
    ch.(varargin{3}).String{udc} = fn;
end

% and put into output
if nargout > 0
    varargout{1} = slvarcpy;
end
