function hfile = aft_SaveAs(hfile, newfile, dtitle)
% AnyFileType::SaveAs  - method for any xff type
%
% FORMAT:       obj.SaveAs([newfilename, dtitle]);
%
% Input fields:
%
%       newfilename save-as filename, if not give, UI-based
%       dtitle      if given, override UI default title
%
% No output fields:
%
%       obj         xff object with newly set filename
%
% TYPES: ALL

% Version:  v0.9d
% Build:    14071510
% Date:     Jul-15 2014, 10:07 AM EST
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

% check arguments
if nargin < 1 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true)
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end

% get objects super-struct
sc = xffgetscont(hfile.L);

% arguments
ndtitle = '';
if nargin > 1 && ...
    ischar(newfile) && ...
   ~any(newfile == '.')
    ndtitle = newfile(:)';
    newfile = '';
end
if nargin < 2 || ...
   ~ischar(newfile) || ...
    isempty(newfile)
    if isempty(sc.F)
        newfile = ['*.' sc.S.Extensions{1}];
    else
        [of{1:3}] = fileparts(sc.F);
        newfile = ['*' of{3}];
    end
    if strcmpi(sc.S.Extensions{1}, 'hdr') && ...
        strcmpi(sc.C.FileMagic, 'n+1')
        newfile = regexprep(newfile, '^(.*)\.hdr$', '$1.nii', 'preservecase');
    end
end
if nargin < 3 || ...
   ~ischar(dtitle) || ...
    isempty(dtitle)
    if ~isempty(ndtitle)
        dtitle = ndtitle;
    else
        dtitle = 1;
    end
end
newfile = newfile(:)';

% don't allow volume marker
if ~isempty(regexpi(newfile, ',\d+$'))
    error( ...
        'xff:BadArgument', ...
        'Saving of sub-volumes not permitted.' ...
    );
end

% make absolute name
[isabs{1:2}] = isabsolute(newfile);
newfile = isabs{2};
[fnparts{1:3}] = fileparts(newfile);

% check for "*.???"
if isempty(fnparts{2})
    fnparts{2} = '*';
end
if isempty(fnparts{3}) || ...
    strcmp(fnparts{3}, '.')
    fnparts{3} = ['.' sc.S.Extensions{1}];
end
if any(fnparts{2} == '*')
    extensions   = xff(0, 'extensions');
    file_formats = xff(0, 'formats');
    filename = xffrequestfile(dtitle, ...
        [fnparts{1} filesep fnparts{2} fnparts{3}], ...
        extensions, file_formats, true);
    if isempty(filename)
        return;
    end
    if iscell(filename)
        filename = filename{1};
    end
    [isabs{1:2}] = isabsolute(filename);
    newfile = isabs{2};
end

% what to do
try
    switch (lower(sc.S.FFTYPE))
        case {'bff'}
            sc.C = bffio(newfile, sc.S, sc.C);
            sc.F = newfile;
        case {'tff'}
            [sc.C, sc.F] = tffio(newfile, sc.S, sc.C);
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
        sc.F(:)', ne_eo.message ...
    );
end

% remove GZIPext/file from handles
if isfield(sc.H, 'GZIPext')
    sc.H = rmfield(sc.H, 'GZIPext');
end
if isfield(sc.H, 'GZIPfile')
    sc.H = rmfield(sc.H, 'GZIPfile');
end

% set new filename and maybe also content
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
