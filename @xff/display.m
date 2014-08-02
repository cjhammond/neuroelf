function display(S)
% xff::display  - overloaded method
%
% for 1x1 objects, displays content struct (property list),
% otherwise MxN xff matrix

% Version:  v0.9d
% Build:    14061918
% Date:     Jun-19 2014, 6:28 PM EST
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

% global storage
global xffcont;

% check size
if numel(S) ~= 1
    osz = sprintf('%d-by-', size(S));
    disp([char(10) '    xff object: ' osz(1:end-4) char(10)]);
else
    try
        if xffisobject(S, true)
            dispstruct(xffgetcont(S.L));
            if S.L == -1 && ...
                numel(xffcont) > 1
                disp('  List of currently loaded objects:');
                disp(repmat('-', 1, 80));
                disp('   # | Type  | Filename (or xffID)');
                disp(repmat('-', 1, 80));
                for oc = 2:numel(xffcont)
                    if isempty(xffcont(oc).F)
                        disp(sprintf('%4d | %4s  | obj::xffID = %s', oc - 1, ...
                            xffcont(oc).S.Extensions{1}, xffcont(oc).C.RunTimeVars.xffID));
                    else
                        disp(sprintf('%4d | %4s  | %s', oc - 1, ...
                            xffcont(oc).S.Extensions{1}, xffcont(oc).F));
                    end
                end
                disp(repmat('-', 1, 80));
                tspc = whos('xffcont');
                disp(sprintf('  Total MB occupied: %.3f', tspc.bytes / 1048576));
            end
        else
            disp([char(10) '    xff object (cleared): 1-by-1' char(10)]);
        end
    catch ne_eo;
        neuroelf_lasterr(ne_eo);
    end
end
