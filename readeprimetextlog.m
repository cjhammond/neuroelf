function epti = readeprimetextlog(filename, flat)
% readeprimetextlog  - read eprime text log file
%
% FORMAT:       epti = readeprimetextlog(filename [, flat])
%
% Input fields:
%
%       filename    filename of text-based logfile
%       flat        if given and true, reduce all levels to single level
%
% Output fields:
%
%       epti        eprime text info

% Version:  v0.9d
% Build:    14061709
% Date:     Jun-17 2014, 9:50 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% Copyright (c) 2011 - 2014, Jochen Weber
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
   ~ischar(filename) || ...
    isempty(filename) || ...
    exist(filename(:)', 'file') ~= 2
    error( ...
        'neuroelf:BadArgument', ...
        'Bad or missing argument.' ...
    );
end
filename = filename(:)';

% read content
filecont = splittocellc(asciiread(filename), char([10, 13]), true, true);
filecont = filecont(:);

% tabular file guess
if numel(filecont) > 2 && ...
   ~isempty(strfind(filecont{1}, '.edat')) && ...
   (~isempty(strfind(filecont{2}, 'Experiment')) || ...
    ~isempty(strfind(filecont{3}, 'Experiment')))

    % skip first line and any empty lines
    filecont(1) = [];
    filecont(cellfun('isempty', filecont)) = [];

    % parse rest into cell arrays
    headers = splittocellc(filecont{1}, char(9));
    headers = headers(:);
    table = cell(numel(headers), numel(filecont) - 1);
    for lc = 2:numel(filecont)
        rowcont = splittocellc(filecont{lc}, char(9));
        if numel(rowcont) < numel(headers)
            table(1:numel(rowcont), lc - 1) = rowcont(:);
        else
            table(1:numel(headers), lc - 1) = lsqueeze(rowcont(1:numel(headers)));
        end
    end

    % replace numbers
    tnumber = find(~cellfun('isempty', regexpi(table(:), ...
        '^[\+\-]?(\d+|\d+\.\d+|\.\d+)([eE][\+\-]?\d+)?$')));
    for lc = 1:numel(tnumber)
        table{tnumber(lc)} = str2double(table{tnumber(lc)});
    end


    % make sure headers are labels
    for lc = 1:numel(headers)
        headers{lc} = makelabel(headers{lc});
    end
    if numel(unique(headers)) ~= numel(headers)
        error( ...
            'neuroelf:BadFileContent', ...
            'Header fields must be unique.' ...
        );
    end

    % create struct
    tstruct = cell2struct(table, headers, 1);

    % create output
    epti = struct( ...
        'Experiment',          'unknown', ...
        'Display_RefreshRate', 60, ...
        'Group',               1, ...
        'LevelName',           {{'FlatTable'}}, ...
        'Log',                 {{struct}}, ...
        'RandomSeed',          round((2^32 - 1) * (rand(1, 1) - 0.5)), ...
        'SessionDate',         datestr(now, 'mm-dd-yyyy'), ...
        'SessionTime',         datestr(now, 13), ...
        'Session',             1, ...
        'Subject',             1, ...
        'VersionPersist',      1);

    % overwrite fields
    if isfield(tstruct, 'Experiment')
        epti.Experiment = tstruct(1).Experiment;
        tstruct = rmfield(tstruct, 'Experiment');
    elseif isfield(tstruct, 'ExperimentName')
        epti.Experiment = tstruct(1).ExperimentName;
        tstruct = rmfield(tstruct, 'ExperimentName');
    end
    if isfield(tstruct, 'Display_RefreshRate')
        epti.Display_RefreshRate = tstruct(1).Display_RefreshRate;
        tstruct = rmfield(tstruct, 'Display_RefreshRate');
    end
    if isfield(tstruct, 'Group')
        epti.Group = tstruct(1).Group;
        tstruct = rmfield(tstruct, 'Group');
    end
    if isfield(tstruct, 'RandomSeed')
        epti.RandomSeed = tstruct(1).RandomSeed;
        tstruct = rmfield(tstruct, 'RandomSeed');
    end
    if isfield(tstruct, 'Session')
        epti.Session = tstruct(1).Session;
        tstruct = rmfield(tstruct, 'Session');
    end
    if isfield(tstruct, 'SessionDate')
        epti.SessionDate = tstruct(1).SessionDate;
        tstruct = rmfield(tstruct, 'SessionDate');
    end
    if isfield(tstruct, 'SessionTime')
        epti.SessionTime = tstruct(1).SessionTime;
        tstruct = rmfield(tstruct, 'SessionTime');
    end
    if isfield(tstruct, 'Subject')
        epti.Subject = tstruct(1).Subject;
        tstruct = rmfield(tstruct, 'Subject');
    end

    % set in epti
    epti.Log = tstruct;

    % return
    return;
end

% remove empty lines
for lc = 1:numel(filecont)
    filecont{lc} = ddeblank(filecont{lc});
end
filecont(cellfun('isempty', filecont)) = [];

% contains header
if ~isempty(regexpi(filecont{1}, 'header\s+start'))

    % split off header
    for lc = 2:numel(filecont)
        if ~isempty(regexpi(filecont{lc}, 'header\s+end'))
            break;
        end
    end
    epti = rep_parseframe([{'Level: 1'}; filecont(1:lc)]);
    epti.Log = {struct};
    filecont = filecont((lc+1):end);
else
    epti = struct( ...
        'Experiment',          'unknown', ...
        'Display_RefreshRate', 60, ...
        'Group',               1, ...
        'LevelName',           {{'Session', 'Block', 'Trial', 'SubTrial', 'LogLevel5'}}, ...
        'Log',                 {{struct}}, ...
        'RandomSeed',          round((2^32 - 1) * (rand(1, 1) - 0.5)), ...
        'SessionDate',         datestr(now, 'mm-dd-yyyy'), ...
        'SessionTime',         datestr(now, 13), ...
        'Session',             1, ...
        'Subject',             1, ...
        'VersionPersist',      1);
end

% find level lines
ll = find(~cellfun('isempty', regexpi(filecont(1:end-1), '^level\:\s+\d+$')) & ...
    ~cellfun('isempty', regexpi(filecont(2:end), 'logframe\s+start')));
ll(end+1) = numel(filecont) + 1;

% parse frames
f = cell(1, 10);
fl = 0;
for lc = 1:(numel(ll) - 1);

    % parse frame and get level
    try
        [fr, l] = rep_parseframe(filecont(ll(lc):(ll(lc+1)-1)));
    catch ne_eo;
        rethrow(ne_eo);
    end

    % stack previous frames
    if l < fl
        if l ~= (fl - 1)
            error( ...
                'neuroelf:BadHierarchy', ...
                'Bad log frame hierarchy detected.' ...
            );
        end
        fr.(sprintf('Level%d', fl)) = f{fl};
        f{fl} = [];
    end
    fl = l;

    % put into correct level
    if isempty(f{fl})
        f{fl} = fr;
    else
        f{fl} = catstruct(f{fl}(:), fr);
    end
end

% test last level
if fl ~= 1
    error( ...
        'neuroelf:ProcessError', ...
        'Error processing file: last level must be 1.' ...
    );
end

% stack into header
epti.Log = f{1};

% flat
if nargin > 1 && ...
    islogical(flat) && ...
    numel(flat) == 1 && ...
    flat
    epti.Log = flatlog(epti.Log, 2);
end



% sub-function: rep_parseframe
function [f, lv] = rep_parseframe(l)

% too few lines or bad content
if numel(l) < 3 || ...
    isempty(regexpi(l{2}, '\s+start\s+')) || ...
    isempty(regexpi(l{end}, '\s+end\s+'))
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid log frame layout.' ...
    );
end

% first line must contain level
if isempty(regexpi(l{1}, '^level\:\s+\d+$'))
    error( ...
        'neuroelf:BadArgument', ...
        'Invalid level indication in frame header: %s.', ...
        l{1} ...
    );
end
lv = regexprep(l{1}, 'level\:\s+', '', 'ignorecase');
lv = str2double(lv);

% parse the rest of the lines into a struct
f = struct;
for lc = 3:(numel(l) - 1)

    % get fieldname and value
    [fn, fv] = strtok(l{lc}, ':');
    fn = makelabel(fn);
    fv = ddeblank(fv(2:end));

    % value numerical
    if ~isempty(regexpi(fv, '^[\+\-]?(\d+|\d+\.\d+|\.\d+)([eE][\+\-]?\d+)?$'))
        fv = str2double(fv);
    end

    % value doesn't exist
    if ~isfield(f, fn)

        % assign
        f.(fn) = fv;

    % otherwise
    else

        % all numbers
        if isa(fv, 'double') && ...
            isa(f.(fn), 'double')

            % put at the end
            f.(fn) = [f.(fn)(:)', fv];

        % or
        else

            % convert to cell if necessary
            if ~iscell(f.(fn))
                f.(fn) = {f.(fn)};
            end

            % add to the end
            f.(fn) = [f.(fn)(:)', {fv}];
        end
    end
end


% flatten log structure
function log = flatlog(log, level)

% decompose
logc = cell(numel(log), 1);
for cc = 1:numel(log)
    logc{cc} = log(cc);
end

% for each cell, unlevel
levfield = sprintf('Level%d', level);
for cc = 1:numel(logc)

    % contains a sub-level
    if isfield(logc{cc}, levfield)

        % flatten first
        logc{cc}.(levfield) = flatlog(logc{cc}.(levfield), level + 1);

        % get fields of top struct
        topfields = fieldnames(logc{cc});
        topfields(strcmp(topfields, levfield)) = [];

        % then join
        logc{cc} = catstruct(logc{cc}, logc{cc}.(levfield));

        % then remove level
        logc{cc} = rmfield(logc{cc}, levfield);

        % and forward into lower fields
        for lcc = 2:numel(logc{cc})
            for lfc = 1:numel(topfields)
                logc{cc}(lcc).(topfields{lfc}) = logc{cc}(1).(topfields{lfc});
            end
        end
    end
end

% then join again
if numel(logc) > 1
    log = catstruct(logc{:});
else
    log = logc{1};
end
