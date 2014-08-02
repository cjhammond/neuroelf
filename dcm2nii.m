function dcm2nii(source, target, opts)
% dcm2nii  - convert DICOM to NII files
%
% FORMAT:       dcm2nii(source, target, opts)
%
% Input fields:
%
%       source      source folder containing DICOM files
%       target      target folder
%       opts        optional settings
%        .dcmpat    DICOM file pattern, default: '*.dcm'
%        .format    either {'img'} or 'nii'
%
% No output fields.

% Version:  v0.9d
% Build:    14072315
% Date:     Jul-23 2014, 3:22 PM EST
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

% use Chris Rorden's version if available
persistent d2nc;
if numel(d2nc) ~= 1 || ...
   ~isstruct(d2nc)
    nini = xini([neuroelf_path('config') '/neuroelf.ini'], 'convert');
    d2ncs = nini.Tools.dcm2nii;
    nini.Release;
    mext = lower(mexext);
    mext(1:3) = [];
    if ~isfield(d2ncs, mext)
        d2ncs = '';
    else
        d2ncs = [neuroelf_path('contrib') filesep d2ncs.(mext)];
    end
    d2nc = struct('d2nbin', d2ncs);
    if isempty(d2nc.d2nbin) || ...
        exist(d2nc.d2nbin, 'file') ~= 2
        d2nc.d2nbin = '';
    end
end

% arguments
if nargin < 2 || ...
   ~ischar(source) || ...
    isempty(source) || ...
    exist(source(:)', 'dir') ~= 7 || ...
   ~ischar(target) || ...
    isempty(target) || ...
    exist(target(:)', 'dir') ~= 7
    error( ...
        'neuroelf:BadArgument', ...
        'Bad or missing argument.' ...
    );
end
source = source(:)';
target = target(:)';
if nargin < 3 || ...
   ~isstruct(opts) || ...
    numel(opts) ~= 1
    opts = struct;
end
if ~isfield(opts, 'dcmpat') || ...
    isempty(opts.dcmpat) || ...
   (~ischar(opts.dcmpat) && ...
    ~iscell(opts.dcmpat))
    opts.dcmpat = '*.dcm';
end
if ~isfield(opts, 'format') || ...
   ~ischar(opts.format) || ...
   ~any(strcmpi(opts.format(:)', {'img', 'nii'}))
    opts.format = 'img';
else
    opts.format = lower(opts.format(:)');
end

% available
if ~isempty(d2nc.d2nbin)

    % try
    try
        args = '-g n ';
        if opts.format(1) == 'i'
            args = [args '-4 n '];
        end
        [o, s] = invsystem(sprintf('%s %s -o "%s" "%s"', d2nc.d2nbin, args, ...
            target, source));
        if s == 0
            disp(o);
            return;
        else
            error( ...
                'neuroelf:systemerror', ...
                'Error executing dcm2nii: %s.', ...
                o ...
            );
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end

% load SPM defaults and matching job
try
    sv = spm('ver');
    if ~any(strcmpi(sv, {'spm5', 'spm8'}))
        error('BAD_VERSION');
    end
    if strcmpi(sv, 'spm5')
        sv = 5;
        spm_defaults;
        jobs = neuroelf_file('p', 'spm5_dicomimport_job');
    else
        sv = 8;
        spm('defaults', 'FMRI');
        jobs = neuroelf_file('p', 'spm8_dicomimport_job');
    end
    jobs = jobs.jobs;
catch ne_eo;
    error( ...
        'neuroelf:SPMError', ...
        'Invalid or missing SPM installation (%s).', ...
        ne_eo.message ...
    );
end

% look for files
try
    dcmfiles = findfiles(source, opts.dcmpat, 'depth=1');
catch ne_eo;
    neuroelf_lasterr(ne_eo);
    dcmfiles = {};
end
if isempty(dcmfiles)
    warning( ...
        'neuroelf:NoFilesFound', ...
        'No DICOM files found in source location.' ...
    );
    return;
end

% depending on SPM version
if sv == 5
    jobs{1}.util{1}.dicom.data = dcmfiles;
    jobs{1}.util{1}.dicom.outdir{1} = target;
    jobs{1}.util{1}.dicom.convopts.format = opts.format;
else
    jobs{1}.spm.util.dicom.data = dcmfiles;
    jobs{1}.spm.util.dicom.outdir{1} = target;
    jobs{1}.spm.util.dicom.convopts.format = opts.format;
end

% run import job
try
    spm_jobman('run', jobs);
catch ne_eo;
    rethrow(ne_eo);
end
