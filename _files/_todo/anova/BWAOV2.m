function [BWAOV2] = BWAOV2(X,alpha)
% BWAOV1 Between- and Within- Subject Variables Analysis of Variance Test.
%   ANOVA with between- and within- subject variables (mixed) is used to analyze the relationship 
%   for designs that have a combination of between and within-subject variables.
%   
%   Syntax: function [BWAOV2] = BWAOV2(X,alpha) 
%      
%     Inputs:
%          X - data matrix (Size of matrix must be n-by-4;dependent variable=column 1;
%              independent variable 1 [between-subject]=column 2;independent variable 2
%              [within-subject]=column 3; subject=column 4). 
%      alpha - significance level (default = 0.05).
%    Outputs:
%            - Complete Analysis of Variance Table.
%
%    Example: From the David M. Lane's hyperstat online textbook Chapter 14 (within-subjects /repeated measures 
%             ANOVA) example 6 and its selected answers (http://davidmlane.com/hyperstat/questions/Chapter_14.html).
%             The next experiment has the scores (times) for males (M) and females (F) on each of three tasks:
%             1.Subjects read the names of colors printed in black ink (T1). 
%             2.Subjects name the colors of rectangles (T2). 
%             3.Subjects are given the names of colors written in ink of different colors. For example, blue 
%               might be written in red ink (T3).
%             Gender is a between-subject variable (BS) since each subject is in either one sex group or the other. 
%             Tasks (trials) is a within-subject variable (WS) since each subject performs on all three trials. 
%             With a significance level = 0.05, we are interested to perform a with between- and within-
%             subject variables analysis of variance.
%
%                                             M                                         F
%                                  -----------------------                   -----------------------
%                     Subject       T1       T2       T3        Subject       T1       T2       T3
%                     ------------------------------------      ------------------------------------
%                        1          14       17       38          32          17       22	    32
%                        2          17       15       58          33          15	   27	    40
%                        3          17       18       35          34          24	   25	    33
%                        4          16       20       39          35          25	   27	    38
%                        5          16       18       33          36          15	   23	    32
%                        6          17       20       32          37          27	   24	    40
%                        7          17       20       45          38          13	   19	    46
%                        8          16       19       52          39          12	   15	    24
%                        9          14       17       31          40          14	   21	    33
%                       10          19       21       29          41          18	   26	    37
%                       11          22       23       33          42          18	   24	    49
%                       12          15       16       25          43          16	   17	    35
%                       13          15       18       41          44          12	   17	    25
%                       14          29       29       33          45          16	   19	    34
%                       15          14       18       42          46          21	   30	    49
%                       16          11       16       30          47          15	   20	    37
%                       17          13       18       31        ------------------------------------
%                       18          14       22       37
%                       19          12       19       34
%                       20          17       20       45
%                       21          15       24       45
%                       22          14       19       35      
%                       23          13       20       36
%                       24          11       20       32
%                       25          14       21       49
%                       26          13       17       40
%                       27          13       17       38
%                       28          12       14       28
%                       29          15       18       29
%                       30          19       24       33
%                       31          14       17       28
%                    -------------------------------------
%                                       
%
%     Data matrix must be:
%     X=[14 1 1 1;17 1 2 1;38 1 3 1;17 1 1 2;15 1 2 2;58 1 3 2;17 1 1 3;18 1 2 3;35 1 3 3;16 1 1 4;20 1 2 4;39 1 3 4;16 1 1 5;18 1 2 5;33 1 3 5;
%     17 1 1 6;20 1 2 6;32 1 3 6;17 1 1 7;20 1 2 7;45 1 3 7;16 1 1 8;19 1 2 8;52 1 3 8;14 1 1 9;17 1 2 9;31 1 3 9;19 1 1 10;21 1 2 10;29 1 3 10;
%     22 1 1 11;23 1 2 11;33 1 3 11;15 1 1 12;16 1 2 12;25 1 3 12;15 1 1 13;18 1 2 13;41 1 3 13;29 1 1 14;29 1 2 14;33 1 3 14;14 1 1 15;18 1 2 15;
%     42 1 3 15;11 1 1 16;16 1 2 16;30 1 3 16;13 1 1 17;18 1 2 17;31 1 3 17;14 1 1 18;22 1 2 18;37 1 3 18;12 1 1 19;19 1 2 19;34 1 3 19;17 1 1 20;
%     20 1 2 20;45 1 3 20;15 1 1 21;24 1 2 21;45 1 3 21;14 1 1 22;19 1 2 22;35 1 3 22;13 1 1 23;20 1 2 23;36 1 3 23;11 1 1 24;20 1 2 24;32 1 3 24;
%     14 1 1 25;21 1 2 25;49 1 3 25;13 1 1 26;17 1 2 26;40 1 3 26;13 1 1 27;17 1 2 27;38 1 3 27;12 1 1 28;14 1 2 28;28 1 3 28;15 1 1 29;18 1 2 29;
%     29 1 3 29;19 1 1 30;24 1 2 30;33 1 3 30;14 1 1 31;17 1 2 31;28 1 3 31;17 2 1 32;22 2 2 32;32 2 3 32;15 2 1 33;27 2 2 33;40 2 3 33;24 2 1 34;
%     25 2 2 34;33 2 3 34;25 2 1 35;27 2 2 35;38 2 3 35;15 2 1 36;23 2 2 36;32 2 3 36;27 2 1 37;24 2 2 37;40 2 3 37;13 2 1 38;19 2 2 38;46 2 3 38;
%     12 2 1 39;15 2 2 39;24 2 3 39;14 2 1 40;21 2 2 40;33 2 3 40;18 2 1 41;26 2 2 41;37 2 3 41;18 2 1 42;24 2 2 42;49 2 3 42;16 2 1 43;17 2 2 43;
%     35 2 3 43;12 2 1 44;17 2 2 44;25 2 3 44;16 2 1 45;19 2 2 45;34 2 3 45;21 2 1 46;30 2 2 46;49 2 3 46;15 2 1 47;20 2 2 47;37 2 3 47];
%
%     Calling on Matlab the function: 
%             BWAOV2(X)
%
%       Answer is:
%
%    The number of IV1(BS) levels are: 2
%
%    The number of IV2(WS) levels are: 3
%
%    The number of subjects are:47
%
%    Between- and Within- Subject Variables Analysis of Variance Table.
%    ---------------------------------------------------------------------------
%    SOV                  SS          df           MS             F        P
%    ---------------------------------------------------------------------------
%    IV1                83.325         1         83.325         1.994   0.1648
%    Error(IV1)       1880.562        45         41.790
%    IV2             11054.482         2       5527.241       264.648   0.0000
%    IV1xIV2            55.846         2         27.923         1.337   0.2678
%    Error(IV1xIV2)   1879.672        90         20.885
%    Total           14953.887       140
%    ---------------------------------------------------------------------------
%    If the P results are smaller than 0.05
%    the corresponding Ho's tested result statistically significant. Otherwise, are not significative.
%
%    Created by A. Trujillo-Ortiz, R. Hernandez-Walls and R.A. Trujillo-Perez
%               Facultad de Ciencias Marinas
%               Universidad Autonoma de Baja California
%               Apdo. Postal 453
%               Ensenada, Baja California
%               Mexico.
%               atrujo@uabc.mx
%
%    Copyright.July 27, 2004.
%
%    To cite this file, this would be an appropriate format:
%    Trujillo-Ortiz, A., R. Hernandez-Walls and R.A. Trujillo-Perez. (2004). BWAOV2:Between- and within-
%      subject variables (mixed) ANOVA. A MATLAB file. [WWW document]. URL http://www.mathworks.com/
%      matlabcentral/fileexchange/loadFile.do?objectId=5579
%
%    References:
%    Lane, M. D. http://davidmlane.com/hyperstat/questions/Chapter_14.html
%    Huck, S. W. (2000), Reading Statistics and Research. 3rd. ed. 
%             New-York:Allyn&Bacon/Longman Pub. Chapter 16.
%

if nargin < 2,
   alpha = 0.05; %(default)
end; 

if (alpha <= 0 | alpha >= 1)
   fprintf('Warning: significance level must be between 0 and 1\n');
   return;
end;

if nargin < 1, 
   error('Requires at least one input argument.');
   return;
end;

a = max(X(:,2));
b = max(X(:,3));
s = max(X(:,4));

fprintf('The number of IV1(BS) levels are:%2i\n\n', a);
fprintf('The number of IV2(WS) levels are:%2i\n\n', b);
fprintf('The number of subjects are:%2i\n\n', s);

indice = X(:,2);
for i = 1:a
    Xe = find(indice==i);
    eval(['A' num2str(i) '=X(Xe,1);']);
end;

indice = X(:,3);
for j = 1:b
    Xe = find(indice==j);
    eval(['B' num2str(j) '=X(Xe,1);']);
end;

indice = X(:,4);
for k = 1:s
    Xe = find(indice==k);
    eval(['S' num2str(k) '=X(Xe,1);']);
end;

C = (sum(X(:,1)))^2/length(X(:,1));  %correction term
SSTO = sum(X(:,1).^2)-C;  %total sum of squares
dfTO = length(X(:,1))-1;  %total degrees of freedom
   
%procedure related to the IV1 (independent variable 1 [between-subject]).
A = [];
for i = 1:a
    eval(['x =((sum(A' num2str(i) ').^2)/length(A' num2str(i) '));']);
    A = [A,x];
end;
SSA = sum(A)-C;  %sum of squares for the IV1
dfA = a-1;  %degrees of freedom for the IV1
MSA = SSA/dfA;  %mean square for the IV1

%procedure related to the IV2 (independent variable 2 [within-subject]).
B = [];
for j = 1:b
    eval(['x =((sum(B' num2str(j) ').^2)/length(B' num2str(j) '));']);
    B =[B,x];
end;
SSB = sum(B)-C;  %sum of squares for the IV2
dfB = b-1;  %degrees of freedom for the IV2
MSB = SSB/dfB;  %mean square for the IV2

%procedure related to the within-subjects.
S = [];
for k = 1:s
    eval(['x =((sum(S' num2str(k) ').^2)/length(S' num2str(k) '));']);
    S = [S,x];
end;

%procedure related to the IV1-error.
SSEA = sum(S)-sum(A);  %sum of squares of the IV1-error
dfEA = s-a;  %degrees of freedom of the IV1-error
MSEA = SSEA/dfEA;  %mean square for the IV1-error

%procedure related to the IV1 and IV2 (between- and within- subject).
for i = 1:a
    for j = 1:b
        Xe = find((X(:,2)==i) & (X(:,3)==j));
        eval(['AB' num2str(i) num2str(j) '=X(Xe,1);']);
    end;
end;
AB = [];
for i = 1:a
    for j = 1:b
        eval(['x =((sum(AB' num2str(i) num2str(j) ').^2)/length(AB' num2str(i) num2str(j) '));']);
        AB = [AB,x];
    end;
end;
SSAB = sum(AB)-sum(A)-sum(B)+C;  %sum of squares of the IV1xIV2
dfAB = dfA*dfB;  %degrees of freedom of the IV1xIV2
MSAB = SSAB/dfAB;  %mean square for the IV1xIV2

%procedure related to the IV2-error.
for j = 1:b
    for k = 1:s
        Xe = find((X(:,3)==j) & (X(:,4)==k));
        eval(['IV2S' num2str(j) num2str(k) '=X(Xe,1);']);
    end;
end;
EIV2 = [];
for j = 1:b
    for k = 1:s
        eval(['x =((sum(IV2S' num2str(j) num2str(k) ').^2)/length(IV2S' num2str(j) num2str(k) '));']);
        EIV2 = [EIV2,x];
    end;
end;
SSEAB = sum(EIV2)-sum(AB)-sum(S)+sum(A);  %sum of squares of the IV2-error
dfEAB = dfEA*dfB;  %degrees of freedom of the IV2-error
MSEAB = SSEAB/dfEAB;  %mean square for the IV2-error

%F-statistics calculation
F1 = MSA/MSEA;
F2 = MSB/MSEAB;
F3 = MSAB/MSEAB;

%degrees of freedom re-definition
v1 = dfA;
v2 = dfEA;
v3 = dfB;
v4 = dfAB;
v5 = dfEAB;
v6 = dfTO;

%Probability associated to the F-statistics.
P1 = 1 - fcdf(F1,v1,v2);    
P2 = 1 - fcdf(F2,v3,v5);   
P3 = 1 - fcdf(F3,v4,v5);

disp('Between- and Within- Subject Variables Analysis of Variance Table.')
fprintf('---------------------------------------------------------------------------\n');
disp('SOV                  SS          df           MS             F        P')
fprintf('---------------------------------------------------------------------------\n');
fprintf('IV1           %11.3f%10i%15.3f%14.3f%9.4f\n\n',SSA,v1,MSA,F1,P1);
fprintf('Error(IV1)    %11.3f%10i%15.3f\n\n',SSEA,v2,MSEA);
fprintf('IV2           %11.3f%10i%15.3f%14.3f%9.4f\n\n',SSB,v3,MSB,F2,P2);
fprintf('IV1xIV2       %11.3f%10i%15.3f%14.3f%9.4f\n\n',SSAB,v4,MSAB,F3,P3);
fprintf('Error(IV1xIV2)%11.3f%10i%15.3f\n\n',SSEAB,v5,MSEAB);
fprintf('Total         %11.3f%10i\n\n',SSTO,v6);
fprintf('---------------------------------------------------------------------------\n');

fprintf('If the P results are smaller than% 3.2f\n', alpha );
disp('the corresponding Ho''s tested result statistically significant. Otherwise, are not significative.');

return;