function [sdata, fs, ls, srat] = acq_SampleData(hfile, ch, from, to, nsmp, freq, fw, ui)
% ACQ::SampleData  - sample data in a window
%
% FORMAT:       [sd, fs, ls, sr] = acq.SampleData(ch, from, to, nsmp [,f [, fw [, ui]]])
%
% Input fields:
%
%       ch          channel number
%       from        from-time
%       to          to-time
%       nsmp        number of samples
%       f           frequency of underlying data (default: from file)
%       fw          additional gaussian FWHM in seconds (default: 0)
%       ui          up-interp. method, one of {'cubic'}, 'linear', 'nearest'
%
% Output fields:
%
%       sd          sampled data
%       fs          first sample
%       ls          last sample ( + 0.5 srat)
%       sr          sampling rate

% Version:  v0.9d
% Build:    14061710
% Date:     Jun-17 2014, 10:30 AM EST
% Author:   Jochen Weber, SCAN Unit, Columbia University, NYC, NY, USA
% URL/Info: http://neuroelf.net/
%
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

% argument check
if nargin < 5 || ...
    numel(hfile) ~= 1 || ...
   ~xffisobject(hfile, true, 'acq') || ...
   ~isa(ch, 'double') || ...
    numel(ch) ~= 1 || ...
    isinf(ch) || ...
    isnan(ch) || ...
    ch < 1 || ...
    ch ~= fix(ch) || ...
   ~isa(from, 'double') || ...
    numel(from) ~= 1 || ...
    isinf(from) || ...
    isnan(from) || ...
   ~isa(to, 'double') || ...
    numel(to) ~= 1 || ...
    isinf(to) || ...
    isnan(to) || ...
   ~isa(nsmp, 'double') || ...
    numel(nsmp) ~= 1 || ...
    isinf(nsmp) || ...
    isnan(nsmp) || ...
    nsmp < 1 || ...
    nsmp ~= fix(nsmp)
    error( ...
        'xff:BadArguments', ...
        'Invalid call to %s.', ...
        mfilename ...
    );
end
bc = xffgetcont(hfile.L);
if ch > bc.NrOfChannels
    error( ...
        'xff:BadArguments', ...
        'Channel number out of bounds.' ...
    );
end
if nargin < 6 || ...
   ~isa(freq, 'double') || ...
    numel(freq) ~= 1 || ...
    isinf(freq) || ...
    isnan(freq) || ...
    freq <= 0
    freq = 1000 / bc.MillisecsPerSample;
end
if nargin < 7 || ...
   ~isa(fw, 'double') || ...
    numel(fw) ~= 1 || ...
    isinf(fw) || ...
    isnan(fw) || ...
    fw < 0
    fw = 0;
end
if nargin < 8 || ...
   ~ischar(ui) || ...
    isempty(ui) || ...
   ~any(lower(ui(1)) == 'ln')
    ui = 'c';
else
    ui = lower(ui(1));
end

% get channel data
cdata = acq_ChannelData(hfile, ch);

% compute samples
froms = from * freq;
tos = to * freq;

% compute sampling ratio
dist = abs(tos - froms);
srat = dist / nsmp;

% only one sample
if nsmp == 1
    fs = froms + 1;
    ls = froms;
    sdata = flexinterpn_method(cdata, fs, 'cubic');
    return;
end

% compute first and last sample position
fs = froms + 0.5 * srat;
ls = froms + nsmp * srat;

% get kernel
erat = srat + fw * freq;
if erat > sqrt(2) || ...
    ui == 'c'
    [null, k] = resampleaa([0; 0], erat);
elseif ui == 'l'
    k = {[0; 1; 0], 1};
else
    sdata = cdata(round(fs:srat:ls));
    sdata = sdata(:);
    return;
end

% resample
sdata = flexinterpn(cdata, [Inf; fs; srat; ls], k{:}, 0);
