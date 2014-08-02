function hfile = plp_AddColumn(hfile, colname, coldata, icase)
% PLP::AddColumn  - add a column to a PLP object
%
% FORMAT:       [plp = ] plp.AddColumn(colname [, coldata [, icase]])
%
% Input fields:
%
%       colname     name for column, if found replace existing column
%       coldata     Cx1 double/cell, if given C must be size(plp.Points, 1)
%       icase       ignore case of string labels (default: true)
%
% Output fields:
%
%       plp         altered PLP object

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
% Copyright (c) 2011, 2014, Jochen Weber
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
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'plp') || ...
   ~ischar(colname) || ...
    isempty(colname) || ...
    numel(colname) ~= size(colname, 2) || ...
   ~isvarname(colname)
    error( ...
        'xff:BadArgument', ...
        'Bad or missing argument.' ...
    );
end
bc = xffgetcont(hfile.L);
if nargin < 3 || ...
   (~iscell(coldata) && ...
    ~isa(coldata, 'double')) || ...
   (~isempty(bc.Points) && ...
    numel(coldata) ~= size(bc.Points, 1))
    coldata = zeros(size(bc.Points, 1), 1);
elseif iscell(coldata)
    if nargin < 4 || ...
       ~islogical(icase) || ...
        numel(icase) ~= 1
        icase = true;
    end
    oldlabels = bc.Labels;
    olc = numel(oldlabels);
    newlabels = cell(size(bc.Points, 1), 1);
    newlabuse = 0;
    newcoldata = zeros(size(newlabels));
    if icase
        for cc = 1:numel(coldata)
            if ischar(coldata{cc}) && ...
               ~isempty(coldata{cc})
                lfound = findfirst(strcmpi(coldata{cc}(:)', oldlabels));
                if ~isempty(lfound)
                    newcoldata(cc) = lfound;
                    continue;
                end
                if newlabuse > 0
                    lfound = findfirst(strcmpi(coldata{cc}(:)', newlabels(1:newlabuse)));
                    if ~isempty(lfound)
                        newcoldata(cc) = olc + lfound;
                        continue;
                    end
                end
                newlabuse = newlabuse + 1;
                newlabels{newlabuse} = coldata{cc}(:)';
                newcoldata(cc) = olc + newlabuse;
            elseif isa(coldata{cc}, 'double') && ...
                numel(coldata{cc}) == 1
                newcoldata(cc) = coldata{cc};
            end
        end
    else
        for cc = 1:numel(coldata)
            if ischar(coldata{cc}) && ...
               ~isempty(coldata{cc})
                lfound = findfirst(strcmp(coldata{cc}(:)', oldlabels));
                if ~isempty(lfound)
                    newcoldata(cc) = lfound;
                    continue;
                end
                if newlabuse > 0
                    lfound = findfirst(strcmp(coldata{cc}(:)', newlabels(1:newlabuse)));
                    if ~isempty(lfound)
                        newcoldata(cc) = olc + lfound;
                        continue;
                    end
                end
                newlabuse = newlabuse + 1;
                newlabels{newlabuse} = coldata{cc}(:)';
                newcoldata(cc) = newlabuse;
            elseif isa(coldata{cc}, 'double') && ...
                numel(coldata{cc}) == 1
                newcoldata(cc) = coldata{cc};
            end
        end
    end
    if newlabuse > 0
        bc.Labels = [bc.Labels(:); newlabels(1:newlabuse)];
    end
    coldata = newcoldata;
end

% add coldata
lfound = findfirst(strcmpi(colname, bc.ColumnNames));
if isempty(lfound)
    lfound = size(bc.Points, 2) + 1;
    bc.ColumnNames{lfound} = colname;
end
bc.Points(1:numel(coldata), lfound) = coldata;

% set back
bc.ColumnNames = bc.ColumnNames(:)';
bc.Labels = bc.Labels(:)';
bc.NrOfPoints = size(bc.Points, 1);
bc.NrOfColumns = size(bc.Points, 2);
bc.NrOfLabels = numel(bc.Labels);
xffsetcont(hfile.L, bc);
