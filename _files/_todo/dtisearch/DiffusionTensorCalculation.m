function DiffusionTensorCalculation
tic;

% This code produces a DTI 'mat'-file for "SearchDTI" if you have a Matlab 
% However: "you *must* adapt this code in order for it to work...": your
% input (coded somewhere in this script) should be the DWI matrix and b-matrix (or b-value and gradients)
% If all of this is just to much for you to deal with - you may always send me an example data 
% set (with all relevant specs, such as the b-value, gradient directions, or b-matrix, voxel-size, etc...)

%---------------------------------------------------------------
% At the end, data is being saved...it is a fixed nominal structure:
% variables that should be incorporated in the mat-file in order to be able to be loaded into ExploreDTI are:
% 
% 1.	DT (diffusion tensor)			:	4D single matrix (row, column, slice, 9)
% 2.	DWI (diffusion weighted images)	:	4D uint16 matrix (row, column, slice, number of non-DWIs + DWIs)
% 3.	FA (fractional anisotropy)		:	3D single matrix (row, column, slice)
% 4.	FE (first eigenvector)			:	4D single matrix (row, column, slice, 3)
% 5.	SE (second eigenvector)		      :	4D single matrix (row, column, slice, 3)
% 6.	FEFA (FA*abs(FE))			      :	4D single matrix (row, column, slice, 3)
% 7.	MDims (matrix dimensions)		:	1D double matrix (e.g. [128 128 60] for [coronal sagittal axial])
% 8.	VDims (voxel dimensions)		:	1D double matrix (e.g. [2 2 2] in mm)
% 9.	eigval (eigenvalues)			:	4D single matrix (row, column, slice, 3)
% 10.	b (b-matrix)				:	2D single matrix (number of non-DWIs + DWIs, 6)
% 11. bval (b-value)                      :     0D double number in s/mm^2 (e.g., 1500)
% 12. g (gradient matrix)                 :     2D double matrix (number of gradient directions,3)
% 13. NrB0 (no of non-DWIs)               :     0D double number (e.g., 7)
% 14. chi_sq (chi-square)			:	3D single matrix (row, column, slice)
%-----------------------------------------------------------------

% Technical note: for historical reasons, the FA is within the range [0 sqrt(3)]...so for further analysis, 
% divide it by sqrt(3) when using it outside the ExploreDTI environment.
% I try to follow the radiological convention in orientation...so my matrices A(i,j,k) are as follows:
% front 2 back <--> low 2 high 'i' index
% left 2 right <--> low 2 high 'j' index
% bottom 2 top <--> low 2 high 'k' index

% You need the following toolboxes to run this file: Image processing,
% Statistics, and Optimization.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Parameters Setting                         % START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DWI = zeros(128,128,55,13);
for a=1:55; % No. of Slice
    for b=1:13; % No. of non-DW images + No. of DW images(= no. of gradients)
     t=load([pwd '/DATA_DWI_12direction/dwi_slice',num2str(a)]);
     DWI(:,:,a,b)=t.img(:,:,b);
    end
end

VDims = [2.1875 2.1875 2.2]; % define voxel size (in mm)
MDims = [128 128 55]; % matrix size (in voxels)
NrB0 = 1; % No. of non-DW images
bval = 1000; % b-value (in s/mm^2)
NrOfDirections = 12; % No. of DW images (= no. of gradients)

g = [1 0 0.5; 0 0.5 1; 0.5 1 0; 1 0.5 0; 0 1 0.5;...
    0.5 0 1; 1 0 -0.5; 0 -0.5 1; -0.5 1 0; 1 -0.5 0;...
    0 1 -0.5; -0.5 0 1]; % gradient directions (should be of size 'NrOfDirections' x 3)

fnam = 'DTI12dir.mat'; % Save mat-file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Parameters Setting                         % END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% normalize gradients
gg = sqrt(sum(g.*g,2));
g = g./repmat(gg,[1 3]);


% %%% IMPORTANT %%%
% % Change, if needed, the x,y,z diffusion directions (i.e. permute) /
% % orientations (i.e. sign)...Coordinate system stuff!
% g(:,[1 2 3]) = g(:,[1 2 3]); % change x and y (for example)
% 
% % Sign
% g(:,1)= - g(:,1); % change x-direction (for example)
% g(:,2)= - g(:,2);
% g(:,3)= - g(:,3);

% b-matrix (calculated from gradients and b-value)
% *or* you could load your b-matrix directly of course (check coordinate system!!!)
b = bval*[g(:,1).^2 2*g(:,1).*g(:,2) 2*g(:,1).*g(:,3)...
    g(:,2).^2 2*g(:,2).*g(:,3) g(:,3).^2];
b = [zeros(NrB0, 6); b];

% bval = mean(sum(b(NrB0+1:end,[1 4 6]),2)); % if only a b-matrix was provided


% b should be of size (NrB0 + NrOfDirections) x 6;

% ###### load DWI data here for example ######


% ################################

% Create mask ____________________________________________________________

mask_tuning = 0.8; % fine-tuning range to calculate the mask: [0.5 1.5]
cluster_s = 10; % omit pixel clusters smaller than 'cluster_s' during masking

BZ = mean(DWI(:,:,:,NrB0+1:end),4);
BZ = mat2gray(BZ);
level = graythresh(BZ(:));
mask_glass = im2bw(BZ(:),mask_tuning*level);
mask = reshape(mask_glass,size(BZ));

[L,NUM] = bwlabeln(mask,6);
SL = L(L~=0);
sd = hist(SL,1:NUM);
[M,I] = max(sd);
mask(L~=I)=0;
mask=double(mask);
mask = imfill(mask,6,'holes');

for i=1:size(mask,3)

    mask(:,:,i) = imfill(mask(:,:,i),'holes');
    mask(:,:,i) = bwareaopen(mask(:,:,i),cluster_s);

end
mask=permute(mask,[1 3 2]);
for i=1:size(mask,3)

    mask(:,:,i) = imfill(mask(:,:,i),'holes');
    mask(:,:,i) = bwareaopen(mask(:,:,i),cluster_s);
end
mask=permute(mask,[1 3 2]);
mask=permute(mask,[3 2 1]);
for i=1:size(mask,3)
    mask(:,:,i) = imfill(mask(:,:,i),'holes');
    mask(:,:,i) = bwareaopen(mask(:,:,i),cluster_s);
end
mask=permute(mask,[3 2 1]);

se = strel('disk',2,0);
for i=1:size(mask,3)
    mask(:,:,i) = imdilate(mask(:,:,i),se);
    mask(:,:,i) = imfill(mask(:,:,i),'holes');
    mask(:,:,i) = imerode(mask(:,:,i),se);
end

[L,NUM] = bwlabeln(mask,6);
SL = L(L~=0);
sd = hist(SL,1:NUM);
[M,I] = max(sd);
mask(L~=I)=0;
mask=double(mask);
mask = imfill(mask,6,'holes');

mask = logical(mask);

% Done creating mask _____________________________________________________

% Estimate diffusion tensor (simple weighted linear approach)
DT = repmat(single(nan), [MDims(1) MDims(2) MDims(3) 9]);
chi_sq = repmat(single(nan), [MDims(1) MDims(2) MDims(3)]);
chi_sq_iqr = repmat(single(nan), [MDims(1) MDims(2) MDims(3)]);
DWIB0 = repmat(single(nan), [MDims(1) MDims(2) MDims(3)]);
outlier = repmat(logical(0),size(DWI));
order = [1 2 3 5 6 9];
b2 = [ones(size(DWI,4),1) -b];

for k=1:MDims(3);
    for i=1:MDims(1);
        for j=1:MDims(2);        

            if mask(i,j,k)

                dwi = double(squeeze(DWI(i,j,k,:)));

                dwi(dwi==0)=1;

                covar = diag(dwi.^2);
                X = inv(b2'*covar*b2)*(b2'*covar)*log(dwi);

                fit = exp(b2*X);
                resid = abs(fit - dwi);
                DWIB0(i,j,k) = fit(1);

                y = prctile(resid,[25 50 75]);
                chi_sq(i,j,k) = y(2);
                chi_sq_iqr(i,j,k) = y(3)-y(1);
                outlier(i,j,k,:) = abs(resid(:)-y(2))>1.5*(y(3)-y(1));
                DT(i,j,k,order) = single(X(2:end));

            end

        end
    end

end
DT(:,:,:,4) = DT(:,:,:,2);
DT(:,:,:,7) = DT(:,:,:,3);
DT(:,:,:,8) = DT(:,:,:,6);

% Done estimating tensor _____________________________________________________


% Calculate eigenvalue decomposition ____________________________________

order = [1 2 3 5 6 9];
Dummy = repmat(single(nan),[size(DT,1) size(DT,2) size(DT,3)]);

X = repmat(single(0),[6 sum(mask(:))]);

for k=1:size(X,1);
    Dummy = DT(:,:,:,order(k));
    X(k,:)=single(Dummy(mask(:)));
end

A = double(X);
clear X;

a1 = A(1,:);
a2 = A(2,:);
a3 = A(3,:);
a4 = A(4,:);
a5 = A(5,:);
a6 = A(6,:);

L=length(a1);
clear A;

I1 = a1 + a4 + a6;
I2 = a1.*a4 + a1.*a6 + a4.*a6;
I2 = I2 - (a2.*a2 + a3.*a3 + a5.*a5);
I3 = a1.*a4.*a6 + 2*a2.*a3.*a5;
I3 = I3 - (a6.*a2.*a2 + a4.*a3.*a3 + a1.*a5.*a5);

v = (I1.*I1)/9 - I2/3;
s = (I1.*I1.*I1)/27 - (I1.*I2)/6 + I3/2;

temp = ((s./v).*(1./sqrt(v)));
temp(temp>1)=1;
temp(temp<-1)=-1;

phi = acos(temp)/3;
clear s;

D = repmat(double(0),[3 L]);

D(1,:) = I1/3 + 2*sqrt(v).*cos(phi);
D(2,:) = I1/3 - 2*sqrt(v).*cos(pi/3 + phi);
D(3,:) = I1/3 - 2*sqrt(v).*cos(pi/3 - phi);


PD = repmat(logical(1),[4 L]);
PD(1,:) = I3>0;
clear I1 I2 I3 v phi;

V = repmat(double(0),[3 3 L]);

for i=1:3

    A = a1-D(i,:);
    B = a4-D(i,:);
    C = a6-D(i,:);

    V(1,i,:) = (a2.*a5 - B.*a3).*(a3.*a5 - C.*a2);
    V(2,i,:) = (a3.*a5 - C.*a2).*(a3.*a2 - A.*a5);
    V(3,i,:) = (a2.*a5 - B.*a3).*(a3.*a2 - A.*a5);

end

qv1 = repmat(sqrt(sum(V(:,1,:).*V(:,1,:),1)),[3 1 1]);
qv2 = repmat(sqrt(sum(V(:,2,:).*V(:,2,:),1)),[3 1 1]);
qv3 = repmat(sqrt(sum(V(:,3,:).*V(:,3,:),1)),[3 1 1]);

qv1(qv1==0)=nan;
qv2(qv2==0)=nan;
qv3(qv3==0)=nan;

V(:,1,:) = V(:,1,:)./qv1;
V(:,2,:) = V(:,2,:)./qv2;
V(:,3,:) = V(:,3,:)./qv3;

PD(2,:) = (a1.*a4 - a2.*a2)>=0;
PD(3,:) = (a1.*a6 - a3.*a3)>=0;
PD(4,:) = (a4.*a6 - a5.*a5)>=0;

PD = all(PD,1);

% PosDef = repmat(logical(0), [size(DT,1) size(DT,2) size(DT,3)]);
% PosDef(mask)=~PD;
% imagescn(PosDef,[0 1])

FE = repmat(single(nan), [size(DT,1) size(DT,2) size(DT,3) 3]);
SE = repmat(single(nan), [size(DT,1) size(DT,2) size(DT,3) 3]);
eigval = repmat(single(nan), [size(DT,1) size(DT,2) size(DT,3) 3]);

for i=1:3        
    Dummy(mask) = D(i,:);
    eigval(:,:,:,i) = Dummy;
    Dummy(mask) = V(i,1,:);
    FE(:,:,:,i) = Dummy;
    Dummy(mask) = V(i,2,:);
    SE(:,:,:,i) = Dummy;
end

clear V;



FA = repmat(single(nan), [size(DT,1) size(DT,2) size(DT,3)]);
FA(mask) = FrAn(D(1,:),D(2,:),D(3,:));

FEFA = repmat(single(nan), [size(DT,1) size(DT,2) size(DT,3) 3]);

for i=1:3    
    Dummy = FE(:,:,:,i);
    Dummy(mask) = FA(mask).*abs(Dummy(mask));
    FEFA(:,:,:,i) = Dummy;
end
FA(FA>1) = 1;
FEFA(FEFA>1) = 1;
% FA(mask) = FA(mask)*sqrt(3);

% Done calculating eigenvalue decomposition ____________________________



save(fnam,'DT');
clear DT;
save(fnam,'DWI','-append');
clear DWI;
save(fnam,'b','-append');
clear b;
save(fnam,'FE','-append');
clear FE;
save(fnam,'SE','-append');
clear SE;
save(fnam,'FA','-append');
clear FA;
save(fnam,'FEFA','-append');
clear FEFA;
save(fnam,'VDims','-append');
clear VDims;
save(fnam,'MDims','-append');
clear MDims;
save(fnam,'eigval','-append');
clear eigval;
save(fnam,'bval','-append');
save(fnam,'g','-append');
% save(fnam,'info','-append');
save(fnam,'NrB0','-append');
% save(fnam,'chi_sq','-append');
save(fnam,'DWIB0','-append');
% save(fnam,'outlier','-append');
time = toc;
disp(['cost time : ' num2str(time) 'sec.'])

% calculating the Fractional Anisotropy for large data sets...
function fa = FrAn(L1,L2,L3)

mask = ~isnan(L1);
L1 = L1(mask);
L2 = L2(mask);
L3 = L3(mask);

D1 = L1-L2;
D1 = D1.^2;

D2 = L2-L3;
D2 = D2.^2;

D1 = D1 + D2;

D2 = L3-L1;
D2 = D2.^2;

D1 = D1 + D2;
D1 = sqrt(D1);

clear D2;

L1 = L1.^2;
L2 = L2.^2;
L3 = L3.^2;

L1 = L1 + L2;
L1 = L1 + L3;

clear L2 L3;

L1 = 2*L1;
L1 = sqrt(L1);
fa = repmat(single(nan),size(mask));
fa(mask) = D1./L1;



