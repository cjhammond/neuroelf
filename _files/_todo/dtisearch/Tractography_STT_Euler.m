clear;clc;close all;

%---------------------------------------------------------------
% At the end, data is being saved...it is a fixed nominal structure:
% variables that should be incorporated in the mat-file in order to be able to be loaded into DTISearch are:
% 
% 1.	DWIB0 (Non-DW images)	:	4D single matrix (row, column, slice)
% 2.	FA (Fractional anisotropy)		:	3D single matrix (row, column, slice)
% 3.	FEFA (FA*abs(FE))			      :	4D single matrix (row, column, slice, 3)
% 4.	MDims (matrix dimensions)		:	1D double matrix (e.g. [128 128 60] for [coronal sagittal axial])
% 5.	VDims (voxel dimensions)		:	1D double matrix (e.g. [2 2 2] in mm)
% 6.    Tracts (Fiber tracts position table)		      :	1D cell matrix ({no. of fiber} X Y Z position)
% 7.    TractL (No. of fiber tracts step)		      :	1D double matrix (no. of fiber)
% 8.    TractAng (Deviation angle table of fiber tracts)		      :	1D cell matrix ({no. of fiber} deviation angle [degree])
% 9.    TractFA (Fractional anisotropy table of fiber tracts)		      :	1D cell matrix ({no. of fiber} Fractional anisotropy value)
% 10.   TractFE (FEFA table of fiber tracts)		      :	1D cell matrix ({no. of fiber} FEFA value)
% 11.	InMa (Index map of fiber tractography)		      :	4D cell matrix ({row, column, slice} no. of fiber)
% 12.	CMa	(Counts of fiber index map)	:	4D double matrix (row, column, slice)
% 13.   StepRate (Ratio of the Dis. of forward fiber in one step (mm) to the norm of VDims (mm))  
%-----------------------------------------------------------------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Parameters Setting                         % START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load DTI12dir; % The path of TENSOR.mat file
tic;
Th_FLmin = 50;% Threshold of minimum fiber length (mm)
Th_FLmax = 600;% Threshold of maximum fiber length (mm)
Th_Angle = 70;% Threshold of fiber deviation angle (degree)
Th_FA = .2;% Threshold of stopping fiber tracking criteria (Fractional Anisotropy, FA) 
Step = 1;% Distance of forward fiber in one step (mm)
ColorEncod = 2; % set 1 for single color; set 2 for RGB color
% -------------------------- Setting the range of seed point, the range
% should be involved in the volume of data
SeedX = 30:100;
SeedY = 30:100;
SeedZ = 2:54;
fnam = 'Fiber_12dir_WholeBrain'; % Save mat-file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Parameters Setting                         %END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[X,Y,Z] = meshgrid(SeedX,SeedY,SeedZ);
Seed(:,1) = reshape(X,1,[])';
Seed(:,2) = reshape(Y,1,[])';
Seed(:,3) = reshape(Z,1,[])';
Box(1,:) = Seed(1,:);Box(2,:) = Seed(end,:);Box(2,1) = Seed(1,1);Box(1,3) = Seed(end,3);
Box(3,:) = Seed(end,:);Box(4,:) = Seed(end,:);Box(4,2) = Seed(1,2);Box(5,:) = Seed(1,:);
Box(5,1) = Seed(end,1);Box(6,:) = Seed(end,:);Box(6,3) = Seed(1,3);Box(7,:) = Seed(1,:);
Box(7,2) = Seed(end,2);Box(8,:) = Seed(1,:);Box(9,:) = Seed(1,:);Box(9,3) = Seed(end,3);
Box(10,:) = Seed(end,:);Box(10,2) = Seed(1,2);Box(11,:) = Seed(1,:);Box(11,1) = Seed(end,1);
Box(12,:) = Seed(1,:);Box(13,:) = Seed(1,:);Box(13,2) = Seed(end,2);Box(14,:) = Seed(end,:);
Box(14,1) = Seed(1,1);Box(15,:) = Seed(end,:);Box(16,:) = Seed(end,:);Box(16,3) = Seed(1,3);
% ----------
E1x = -FE(:,:,:,2);
E1y = FE(:,:,:,1);
E1z = -FE(:,:,:,3);
% ---------- Starting fiber tracking
t = 0;% Reset starting point of total fiber

Num_OverLength = 0;
Num_BelowFA = 0;
Num_OutsideImage = 0;
Num_OverCurvatureT = 0;
StepRate = Step./norm(VDims);
for q = 1:size(Seed,1);
    Temp_Tracts = [];Temp_TractFA = [];Temp_TractAng = [];Temp_TractFE = [];
    i = Seed(q,1);
    j = Seed(q,2);
    k = Seed(q,3); 
    s = 0;% Reset starting point of single fiber segment in the first direction
    t = t + 1;% Increment of total fiber point
    sre = 0;% Reset starting point of single fiber segment in the second direction
    for dir = 1:2;        
        if dir == 2;
            Temp_Tracts = flipud(Temp_Tracts);
            i = Seed(q,1);
            j = Seed(q,2);
            k = Seed(q,3);
            s = s - 1; % Substraction one point when seed point at another direction          
        end
         while (i <= MDims(1) && i >= 1 && j <= MDims(2) && j >= 1 && k >= 1 && k <= MDims(3));   
             Int_i = ceil(i);Int_j = ceil(j);Int_k = ceil(k);% ceil the number of current point
                   if dir == 2;
                       sre = sre + 1;% Increment of single fiber segment in the second direction
                   end
             s = s + 1;% Increment of single fiber segment in first direction
                   if (FA(Int_i,Int_j,Int_k) < Th_FA && s == 1);
                      break
                   elseif (FA(Int_i,Int_j,Int_k) < Th_FA && s ~= 1);
                          Num_BelowFA = Num_BelowFA + 1;                    
                          s = s - 1; % StopFA before fiber point stored, so substraction one point
                      break
                   else
                        Temp_Tracts(s,:) = [i,j,k];% Stored region
                        Temp_TractFA(s,:) = FA(Int_i,Int_j,Int_k);                        
                        Temp_TractFE(s,:) = FE(Int_i,Int_j,Int_k,:);                        
                   end
                   if s*Step >= Th_FLmax;% If a single fiber segment bigger than length threshold, stopping fiber tracking
                        Num_OverLength = Num_OverLength + 1;
                      break
                   end 
% ---------- Input Tensor 
%             Tensor = [DT(Int_i,Int_j,Int_k,1) DT(Int_i,Int_j,Int_k,2) DT(Int_i,Int_j,Int_k,3)
%                       DT(Int_i,Int_j,Int_k,4) DT(Int_i,Int_j,Int_k,5) DT(Int_i,Int_j,Int_k,6)
%                       DT(Int_i,Int_j,Int_k,7) DT(Int_i,Int_j,Int_k,8) DT(Int_i,Int_j,Int_k,9)];            
                     if s == 1 || sre == 1;        
                             if dir == 1;% First fiber direction
                                 Vout = [E1x(i,j,k),E1y(i,j,k),VDims(3)/VDims(1)*E1z(i,j,k)]';  
                             else% Second fiber direction
                                 Vout = -[E1x(i,j,k),E1y(i,j,k),VDims(3)/VDims(1)*E1z(i,j,k)]';  
                             end                                  
                     else 
                            Vout = [E1x(Int_i,Int_j,Int_k),E1y(Int_i,Int_j,Int_k),VDims(3)/VDims(1)*E1z(Int_i,Int_j,Int_k)]'; 
                            Dotproduct = (Vout'*NVout)/(norm(Vout')*norm(NVout')); 
                            if Dotproduct < 0;
                                Vout = -Vout;
                            end
                            theta = real(acos((Vout'*NVout)/(norm(Vout')*norm(NVout'))));  
                            Temp_TractAng(s,:) = theta*180/pi;
                            if theta > Th_Angle*pi/180;
                                Num_OverCurvatureT = Num_OverCurvatureT+1;
%                                 StopAngle(Num_OverCurvatureT,:) = [i;j;k;abs(theta)*180/pi];
                                break   
                            end
                     end
% ---------- Tensor deflection vector
                            NVout = Vout;
                            i = i + StepRate*(NVout(1)/norm(NVout'));
                            j = j + StepRate*(NVout(2)/norm(NVout'));
                            k = k + StepRate*(NVout(3)/norm(NVout'));        
         end
    end
             if t > 0 && size(Temp_Tracts,1)*Step > Th_FLmin;   
                Tracts{t,1} = Temp_Tracts;
                TractFA{t,1} = Temp_TractFA;
                TractAng{t,1} = Temp_TractAng;
                TractFE{t,1} = Temp_TractFE;
             elseif t > 0 && size(Temp_Tracts,1)*Step <= Th_FLmin;
                t = t - 1;
             end
end
% ----------
InMa{MDims(1),MDims(2),MDims(3)} = 0;
CMa = zeros(MDims);
for i = 1:length(Tracts);
    Index = unique(ceil(Tracts{i}),'rows');
    for j = 1:length(Index);
        InL = length(InMa{Index(j,1),Index(j,2),Index(j,3)});
        InMa{Index(j,1),Index(j,2),Index(j,3)}(InL+1) = i;
        temp_CMa = CMa(Index(j,1),Index(j,2),Index(j,3));
        CMa(Index(j,1),Index(j,2),Index(j,3)) = temp_CMa+1;
    end
end

clear Temp*;
% ---------- Visualzation Fiber Tractography
close gcf;
hold on;
% choose_slices(FA,70,64,25); 
TractL(length(Tracts),1) = 0;
if ColorEncod == 1;
    for m = 1:length(Tracts);
        plot3(Tracts{m,1}(:,1),Tracts{m,1}(:,2),Tracts{m,1}(:,3),'Color',[0 0 1]); 
        hold on;
        TractL(m,1) = length(Tracts{m,1});
    end
elseif ColorEncod == 2;
    for m = 1:length(Tracts);
        p = patch([(Tracts{m,1}(:,1))' NaN],[(Tracts{m,1}(:,2))' NaN],[(Tracts{m,1}(:,3))' NaN],0); 
        joint = ([Tracts{m,1}(2:end,:); NaN NaN NaN]-Tracts{m,1});
        joint(end,:) = joint(end-1,:);
        temp_joint = joint;
        joint(:,1) = temp_joint(:,2);
        joint(:,2) = temp_joint(:,1);
        cdata = [abs(joint./StepRate); NaN NaN NaN];
        cdata = reshape(cdata,length(cdata),1,3);
        set(p,'CData', cdata, 'EdgeColor','interp','SpecularColorReflectance',1) 
        hold on;
        TractL(m,1) = length(Tracts{m,1});
    end
end


% plot3(Box(:,1),Box(:,2),Box(:,3),'Color',[1 1 0],'LineWidth',2);
% line(ROI_position(:,1),ROI_position(:,2),ROI_position(:,3),'color',[0 1 0],'LineWidth',1.5); 
set(gca,'XTick',[],'YTick',[],'ZTick',[],'Color',[0 0 0],'XColor',[1 1 1],'YColor',[1 1 1],'ZColor',[1 1 1]);
set(gcf,'Color',[0 0 0]);
% xlabel('Anterior - Posterior');ylabel('Right - Left');zlabel('Inferior - Superior');
axis equal;hold off;
axis([1 MDims(1) 1  MDims(2) 1  MDims(3)]);
daspect([ VDims(3)/VDims(1)  VDims(3)/VDims(2) 1]);
view(-90,0);zoom(1.8);box on;
MaxTractL = max(TractL)*Step;
MinTractL = min(TractL)*Step;
MeanTractL = mean(TractL)*Step;

time = toc;
disp(['Tracking Processing Cost : ' num2str(time) ' sec.']);
disp(['No. of Tracts : ' num2str(size(Tracts,1)) ' #']);
disp(['No. of Over Length Fiber : ' num2str(Num_OverLength) ' #']);
disp(['Below FA Threshold Number : ' num2str(Num_BelowFA) ' #']);
disp(['Outside Image Number : ' num2str(Num_OutsideImage) ' #']);
disp(['Over Curvature Threshold Number : ' num2str(Num_OverCurvatureT) ' #']);
disp(['Maximum Length : ' num2str(MaxTractL) ' mm']);
disp(['Minimum Length : ' num2str(MinTractL) ' mm']);
disp(['Average Length : ' num2str(MeanTractL,'%.2f') ' mm']);

save(fnam,'FA');
save(fnam,'MDims','-append');
save(fnam,'TractL','-append');
save(fnam,'Tracts','-append');
save(fnam,'TractFA','-append');
save(fnam,'TractAng','-append');
save(fnam,'TractFE','-append');
save(fnam,'StepRate','-append');
save(fnam,'DWIB0','-append');
save(fnam,'InMa','-append');
save(fnam,'FEFA','-append');
save(fnam,'CMa','-append');
save(fnam,'VDims','-append');
