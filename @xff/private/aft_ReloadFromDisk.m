function hfile = aft_ReloadFromDisk(hfile)
% AFT::ReloadFromDisk  - try reloading the object from disk
%
% FORMAT:       obj.ReloadFromDisk;
%
% No input / output fields.
%
% TYPES: ALL
%
% Note: if the object requires large amount of memory, this method
%       is bound to fail!

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
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
global xffconf;

% only valid for single file
if nargin ~= 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get object's super-struct
sc = xffgetscont(hfile.L);
if isempty(sc.F) || ...
   ~isabsolute(sc.F) || ...
    exist(sc.F, 'file') ~= 2
    error( ...
        'xff:BadFileName', ...
        'Cannot reload from disk, invalid file: ''%s''.', ...
        sc.F ...
    );
end

% try to load file
rs = xffconf.reloadsame;
try
    xffconf.reloadsame = true;
    nobj = xff(sc.F, sc.S.Extensions{1});
    if ~xffisobject(nobj, true, sc.S.Extensions{1})
        error('LOAD_ERROR');
    end
catch ne_eo;
    xffconf.reloadsame = rs;
    rethrow(ne_eo);
end
xffconf.reloadsame = rs;

% get object contents then clear re-loaded object
objcont = xffgetcont(nobj.L);
xffclear(nobj.L);

% keep RunTimeVars as they were!
objcont.RunTimeVars = sc.C.RunTimeVars;

% copy contents from reloaded object to calling object
xffsetcont(hfile.L, objcont);
