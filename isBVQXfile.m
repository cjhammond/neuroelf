function isf = isBVQXfile(hfile, varargin)
% isBVQXfile  - check (and validate) object
%
% FORMAT:       isf = isBVQXfile(hfile [, valid])
%
% Input fields:
%
%       hfile       MxN argument check for class
%       valid       if given and true, perform validation
%
% Output fields:
%
%       isf         logical array of input size with check result

% Version:  v0.9b
% Build:    10112323
% Date:     Nov-23 2010, 11:24 PM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/

% base argument check
if nargin < 1
    error( ...
        'neuroelf:TooFewArguments', ...
        'At least one input argument is required.' ...
    );
end
chstrict = false;
chtypest = '';
if nargin > 1 && ...
    numel(varargin{1}) == 1 && ...
   (isnumeric(varargin{1}) || ...
    islogical(varargin{1}))
    if varargin{1}
        chstrict = true;
    end
elseif nargin > 1 && ...
   (ischar(varargin{1}) || ...
    iscell(varargin{1})) && ...
    ~isempty(varargin{1})
    chstrict = true;
    chtypest = varargin{1}(:)';
end

% make call
isf = xff(0, 'isobject', hfile, chstrict, chtypest);
