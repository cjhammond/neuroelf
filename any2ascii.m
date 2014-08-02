function asciirep = any2ascii(anyvar, varargin)
% any2ascii  - packs simple as well as complex variables into ascii
%
% FORMAT:       asciirep = any2ascii(anyvar [,precision, formatted])
%
% Input fields:
%
%       anyvar      any non-object variable/array
%       precision   internal precision for num2str call [default := 8]
%       formatted   if given and not empty output is lazily formatted
%
% Output fields:
%
%       asciirep    result string
%
% NOTE 1) to re-obtain the original contents of a variable, just use eval:
%         prompt/script>  copied = eval(asciirep);
%         (or)
%         prompt/script>  eval(['copied = ' asciirep ';']);
%
% NOTE 2) any2ascii should handle the following datatypes:
%         - double precision values, including NaN, Inf and complex doubles
%         - chars, ranging from simple to formatted strings or 2D arrays
%         - cell arrays, as long as they contain other valid input types
%         - struct arrays, cell array restriction applies as well
%
% NOTE 3) since this algorithm uses some internals of MATLAB's num2str,
%         decimal numbers might lack some precision after transformation!
%         for a work-around, you can use 'exact' for precision, which will
%         convert doubles to a hexadecimal character representation via
%         hxdouble. Only works on first level (with anyvar of type double)
%         and requires the hxdouble function to be present when using eval
%
% See also disp, eval, hxdouble

% Version:  v0.9b
% Build:    11050712
% Date:     Apr-08 2011, 10:18 PM EST
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

% persistent config
persistent a2acfg;
if isempty(a2acfg)
    a2acfg.classes = struct( ...
        'cell',      'l', ...
        'char',      'c', ...
        'double',    'd', ...
        'single',    'i', ...
        'int8',      '7', ...
        'int16',     '5', ...
        'int32',     '1', ...
        'int64',     '3', ...
        'logical',   '9', ...
        'struct',    's', ...
        'uint8',     '8', ...
        'uint16',    '6', ...
        'uint32',    '2', ...
        'uint64',    '4' ...
    );
    a2acfg.itypes = { ...
                      'int32', 'uint32', ...
                      'int64', 'uint64', ...
                      'int16', 'uint16', ...
                      'int8',  'uint8',  ...
                      'logical' ...
                    };
    a2acfg.prcs = 8;
end

% enough arguments ?
if nargin < 1
    error( ...
        'neuroelf:TooFewArguments',...
        'Too few arguments. Try ''help %s''.',...
        mfilename ...
    );
end

% setup vars
prcs = a2acfg.prcs;
dxct = 0;

% precision in second argument
if nargin > 1 && ...
    isnumeric(varargin{1}) && ...
   ~isempty(varargin{1})
    prcs = floor(varargin{1}(1));

% use hxdouble instead
elseif nargin > 1 && ...
    ischar(varargin{1})
    dxctt = lower(varargin{1}(:)');
    if numel(dxctt) == 5 && ...
        all(dxctt == 'exact')
        dxct = 1;
    end
end

% deny negative precision
if prcs < 0
    prcs = -prcs;
end

% if precision is 0, no decimal point
if prcs == 0
    prcstr = '%0.0f,';
    cpxstr = '%g + %gi';

% otherwise use %g formatter
else
    prcstr = ['%.' int2str(prcs) 'g,'];
    cpxstr = [prcstr(1:end-1) ' + ' prcstr(1:end-1) 'i,'];
end

% find out input type and dims
try

    % try lookup from persistent car
    type = a2acfg.classes.(lower(class(anyvar)));

% error out if type unsupported
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    error( ...
        'neuroelf:BadArgument',...
        'Invalid input type: %s',...
        class(anyvar) ...
    );
end

% handle sparse matrices differently
if type == 'd' && ...
    issparse(anyvar)
    type = 'p';
end

% get dimensions
arraydims = size(anyvar);

% no array content
if any(arraydims == 0)

    % but not all dims zeros
    if ~all(arraydims == 0)

        % for numeric types
        if any('123456789cdip' == type)

            % simply build "empty" zeros with same size
            asciirep = ['[zeros(' any2ascii(arraydims) ')]'];

            % and prepend correct class cast
            if double(type) < 65
                asciirep = ['[' a2acfg.itypes{double(type) - 48} ...
                            '(' asciirep(2:(end-1))  ')]'];
            elseif type == 'c'
                asciirep = ['[char(' asciirep(2:(end-1)) ')]'];
            elseif type == 'i'
                asciirep = ['[single(' asciirep(2:(end-1)) ')]'];
            elseif type == 'p'
                asciirep = ['[sparse(' asciirep(2:(end-1)) ')]'];
            end

        % empty cell array
        elseif type == 'l'
            asciirep = ['[cell(' any2ascii(arraydims) ')]'];

        % empty struct
        else

            % get fieldnames
            fnams = fieldnames(anyvar);

            % empty field list
            if numel(fnams) == 0
                asciirep = ['[repmat(struct,' any2ascii(arraydims) ')]'];

            % or has fields
            else

                % create emptystruct call
                asciirep = ['[emptystruct(' any2ascii(fnams') ',' ...
                    any2ascii(arraydims) ')]'];
            end
        end

    % all empty dims
    else

        % numeric type
        if any('123456789cdip' == type)

            % generate call
            if type == 'd'
                asciirep = '[]';
            elseif type == 'c'
                asciirep = '['''']';
            elseif type == 'i'
                asciirep = '[single([])]';
            elseif type == 'p'
                asciirep = '[sparse([])]';
            else
                asciirep = ['[' a2acfg.itypes{double(type) - 48} '([])]'];
            end

        % empty cell
        elseif type == 'l'
            asciirep = '{}';

        % empty struct
        else

            % get fieldnames
            fnams = fieldnames(anyvar);

            % empty field list
            if numel(fnams) == 0
                asciirep = ['[repmat(struct,' any2ascii(arraydims) ')]'];

            % or has fields
            else

                % create emptystruct call
                asciirep = ['[emptystruct(' any2ascii(fnams') ',' ...
                    any2ascii(arraydims) ')]'];
            end
        end
    end
    return;
end
% we DO have content

% not a sparse matrix (max 2-D)
if type ~= 'p' && ...
    length(arraydims) < 3

    % if this is not a cell array, use '[' brackets
    if type ~= 'l'
        asciirep = '[';

        % switch over type
        switch type

        % standard doubles/singles
        case {'d', 'i'}

            % doubles without hxdouble or complex content
            if type == 'd' && ...
                (~dxct || ...
                 ~isreal(anyvar))

                % iterate over dims(1)
                numrep = cell(1, arraydims(1));
                for outer = 1:arraydims(1)

                    % try combined sprintf approach
                    if isreal(anyvar)
                        line = sprintf(prcstr, anyvar(outer, :));
                    else
                        line = sprintf(cpxstr, ...
                            lsqueeze([real(anyvar(outer, :)); ...
                                imag(anyvar(outer, :))])');
                    end

                    % replace last comma by semicolon
                    line(end) = ';';

                    % put line into asciirep
                    numrep{outer} = line;
                end
                asciirep = [asciirep sprintf('%s', numrep{:})];

            % yet doubles (use hxdouble then)
            elseif type == 'd'

                % more "lines"
                if arraydims(1) ~= 1

                    % make a reshaped array
                    asciirep = ['[reshape(hxdouble(''' ...
                                  hxdouble(reshape(anyvar, 1, prod(arraydims))) ...
                                  '''),' ...
                                  sprintf('[%d,%d]', arraydims(1), arraydims(2)) ...
                                  ')]'];

                % for one-liners, it's OK to use hxdouble directly
                else
                    asciirep = ['[hxdouble(''' hxdouble(anyvar) ''')]'];
                end

            % only singles remain
            else

                % more "lines"
                if arraydims(1) ~= 1

                    % make a reshaped array
                    asciirep = ['[reshape(hxsingle(''' ...
                                  hxsingle(reshape(anyvar, 1, prod(arraydims))) ...
                                  '''),' ...
                                  sprintf('[%d,%d]', arraydims(1), arraydims(2)) ...
                                  ')]'];

                % for one-liners, it's OK to use hxsingle directly
                else
                    asciirep = ['[hxsingle(''' hxsingle(anyvar) ''')]'];
                end
            end

        % struct array, recursive call for each member value
        case {'s'}

            % get fieldnames and number of names
            fnames = fieldnames(anyvar);
            nnames = numel(fnames);

            % we have content
            if nnames > 0

                % just a single (1x1) struct
                if all(arraydims == 1)

                    % create struct call
                    asciirep = '[struct(';

                    % iterate over names
                    for fcount = 1:nnames

                        % get field (works only on 1x1)
                        cv = anyvar(1).(fnames{fcount});

                        % if not is cell, directly
                        if ~iscell(cv)
                            asciirep = [asciirep '''' fnames{fcount} ''',' ...
                                        any2ascii(cv, prcs, []) ',' ];

                        % otherwise within {} to get call correct
                        else
                            asciirep = [asciirep '''' fnames{fcount} ''',{' ...
                                        any2ascii(cv, prcs, []) '},' ];
                        end
                    end

                    % put to representation
                    asciirep = [asciirep(1:end-1) ');'];

                % multi-struct (array)
                else

                    asciirep = ['[cell2struct(' ...
                                  any2ascii(struct2cell(anyvar)) ',' ...
                                  any2ascii(fnames) ',1);'];
                end

            % no content (no fields, but size valid)
            else
                % just struct
                if all(arraydims == 1)
                    asciirep = [asciirep 'struct,'];

                % use cell2struct/struct2cell pair to convert
                else
                    asciirep = sprintf('[cell2struct(cell([0,%d,%d]),{},1)]', ...
                                         arraydims(1),arraydims(2));
                end
            end

        % character arrays
        case {'c'}

            % for empty character arrays
            if prod(arraydims) == 0

                % always give an empty array (MATLAB FIX!)
                asciirep = [asciirep ''''','];

            % with content
            else

                % iterate over "lines"
                for outer = 1:arraydims(1)

                    % replace single quotes
                    ovar = strrep(anyvar(outer, :), '''', '''''');

                    % find illegal characters
                    illegalc = find(ovar<32 | ovar>127);

                    % replace those
                    while ~isempty(illegalc)
                        ovar = strrep(ovar, ovar(illegalc(1)), ...
                               [''' char(' ...
                                sprintf('%d',double(ovar(illegalc(1)))) ...
                                ') ''']);

                        % find anew
                        illegalc = find(ovar<32 | ovar>127);

                        % but keep track of bracket usage!
                        prcs = -1;
                    end

                    % use brackets?
                    if prcs >= 0
                        asciirep = [asciirep '''' ovar '''' ';'];
                    else
                        asciirep = [asciirep '[''' ovar '''' '];'];
                    end
                end
            end

        % int/uint arrays
        otherwise

            % general case: everything but 1x1 logical
            if type ~= '9' || ...
                numel(anyvar) ~= 1
                asciirep = [asciirep class(anyvar) '(' ...
                            any2ascii(double(anyvar), varargin{2:end}) '),'];

            % 1x1 logical -> true
            elseif anyvar
                asciirep = [asciirep 'true,'];
            else
                asciirep = [asciirep 'false,'];
            end

        end

        % either add or replace closing brackets (upon content given)
        if asciirep(end) ~= '['
            asciirep(end) = ']';
        else
            asciirep(end + 1) = ']';
        end

        % third argument
        if nargin > 2 && ...
            isempty(varargin{2}) && ( ...
           ((type == 'd' || ...
             type == 's') && ...
             all(arraydims == 1)) || ...
            (type == 'c' && ...
             arraydims(1) == 1))

            % remove those brackets (for internal use)
            asciirep = asciirep(2:end-1);
        end

        % double brackets?
        while length(asciirep) > 2 && ...
            all(asciirep(1:2) == '[') && ...
            all(asciirep(end-1:end) == ']')

            % remove those anyway
            asciirep=asciirep(2:end-1);
        end

    % cell arrays
    else

        % correct opener
        asciirep = '{';

        % iterate over outer dimension
        for outer = 1:arraydims(1)

            % create "line"'s
            line = '';

            % iterate over inner dimension
            for inner = 1:arraydims(2)
                line = [line any2ascii(anyvar{outer,inner}, prcs, []) ','];
            end
            asciirep = [asciirep line(1:end-1) ';'];
        end

        % on non-empty content
        if asciirep(end) ~= '{'

            % replace final delimiter
            asciirep(end) = '}';

        % for empty content
        else

            % add closing bracket
            asciirep(end + 1) = '}';
        end
    end

% N>2-D, but not a sparse -> add reshape code
elseif type ~= 'p'

    % so pack the contents just as we suspect it to be packed :)
    origdims = sprintf('%d,', arraydims);
    asciirep = ['[reshape(' ...
                any2ascii(reshape(anyvar, 1, prod(arraydims)), varargin{2:end}) ...
                ',' origdims(1:(end-1)) ')]'];

% for sparse matrices, make special code
else

    % get content nicely done
    [spi, spj, sps] = find(anyvar);
    asciirep = ['[sparse(' any2ascii(spi, 0) ',' any2ascii(spj, 0) ',' ...
                any2ascii(sps,varargin{2:end}) ',' ...
                sprintf('%.0f,%.0f', arraydims(1), arraydims(2)) ')]'];

end

% lazy reformatted
if nargin > 2 && ...
  ~isempty(varargin{2}) && ...
   varargin{2} > 0
    lb = [' ...' char(10) char(9)];
    asciirep = strrep(strrep(strrep(asciirep, ...
                      ',',    ', '), ...
                      ';',   [';' lb]), ...
                      '), ', ['),' lb]);
end
