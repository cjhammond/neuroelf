function hfile = aft_Save(hfile)
% AnyFileType::Save  - saves any xff object back to disk
%
% FORMAT:       object.Save;
%
% No input / output fields.
%
% TYPES: ALL

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

% only valid for single file
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true)
    error( ...
        'xff:BadArgument', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get super-struct
sc = xffgetscont(hfile.L);

% check filename
if isempty(sc.F)
    error( ...
        'xff:BadFilename', ...
        'File not yet saved. Use SaveAs method instead.' ...
    );
end

% don't allow volume marker
if ~isempty(regexpi(sc.F, ',\d+$'))
    error( ...
        'xff:BadArgument', ...
        'Saving of sub-volumes not permitted.' ...
    );
end

% what to do
try
    switch (lower(sc.S.FFTYPE))
        case {'bff'}
            sc.C = bffio(sc.F, sc.S, sc.C);
        case {'tff'}
            [sc.C, sc.F] = tffio(sc.F, sc.S, sc.C);
        otherwise
            error( ...
                'xff:InvalidFileType', ...
                'Type not recognized (?FF): %s.', ...
                sc.S.FFTYPE ...
            );
    end
catch ne_eo;
    error( ...
        'xff:ErrorSavingFile', ...
        'Error saving file %s: %s.', ...
        sc.F, ne_eo.message ...
    );
end

% pack
if isfield(sc.H, 'GZIPext') && ...
    ischar(sc.H.GZIPext) && ...
    strcmpi(sc.H.GZIPext, '.gz') && ...
    isfield(sc.H, 'GZIPfile') && ...
    ischar(sc.H.GZIPfile) && ...
   ~isempty(sc.H.GZIPfile)
    try
        gzip(sc.F);
        [cps, cpm, cpi] = copyfile([sc.F '.gz'], [sc.H.GZIPfile sc.H.GZIPext]);
        if cps ~= 1
            error(cpi, cpm);
        end
    catch ne_eo;
        rethrow(ne_eo);
    end
end

% set possibly changed content back
xffsetscont(hfile.L, sc);

% then see if RunTimeVars are to be saved as well
if isfield(sc.C.RunTimeVars, 'AutoSave') && ...
    islogical(sc.C.RunTimeVars.AutoSave) && ...
    numel(sc.C.RunTimeVars.AutoSave) == 1 && ...
    sc.C.RunTimeVars.AutoSave

    % try automatic saving
    try
        aft_SaveRunTimeVars(hfile);
    catch ne_eo;
        warning( ...
            'xff:ErrorSavingFile', ...
            'Error saving RunTimeVars file: %s.', ...
            ne_eo.message ...
        );
    end
end
