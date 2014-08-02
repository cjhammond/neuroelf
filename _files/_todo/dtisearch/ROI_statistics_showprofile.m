function ROI_statistics_showprofile(varargin)

global pixel_width pixel_height text_Info axes_index;

% ROI_value=evalin('base','ROI_value');
% get(gcf,'currentaxes')

ROI_ALLvalue=varargin{1};
% RadioButton_h=varargin{2};
Select=get(gcf,'UserData');
ROI_value=ROI_ALLvalue{Select};
ALLRadioButton_h=evalin('base','ALLRadioButton_h');
RadioButton_h=ALLRadioButton_h{Select};

axes(axes_index);
current_radio=get(RadioButton_h,'value');
if current_radio{1}==1;
    sta_value=ROI_value(:,1);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    title('T2','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='T2:';
elseif current_radio{2}==1;   
    sta_value=ROI_value(:,2);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    title('ADC (mm^2/s)','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='ADC (mm^2/s):';
elseif current_radio{3}==1; 
    sta_value=ROI_value(:,3);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('Lambda 1 (mm^2)','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='Lambda 1 (mm^2):';
elseif current_radio{4}==1; 
    sta_value=ROI_value(:,4);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('Lambda 2 (mm^2)','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='Lambda 2 (mm^2):';
elseif current_radio{5}==1; 
    sta_value=ROI_value(:,5);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('Lambda 3 (mm^2)','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='Lambda 3 (mm^2):';
elseif current_radio{6}==1; 
    sta_value=ROI_value(:,6);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('Mean Diffusion (mm^2)','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='Mean Diffusion (mm^2):';
elseif current_radio{7}==1; 
    sta_value=ROI_value(:,7);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('FA','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='FA:';
elseif current_radio{8}==1; 
    sta_value=ROI_value(:,8);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('FI','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='FI:';
elseif current_radio{9}==1; 
    sta_value=ROI_value(:,9);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('RA','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='RA:';
elseif current_radio{10}==1; 
    sta_value=ROI_value(:,10);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('VR','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='VR:';
elseif current_radio{11}==1; 
    sta_value=ROI_value(:,11);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('VF','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='VF:';
elseif current_radio{12}==1; 
    sta_value=ROI_value(:,12);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('CL','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='CL:';
elseif current_radio{13}==1; 
    sta_value=ROI_value(:,13);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('CS','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='CS:';
elseif current_radio{14}==1; 
    sta_value=ROI_value(:,14);
    max_value=max(sta_value);%average
    min_value=min(sta_value);%minimum
    ave_value=mean(sta_value);%max
    std_value=std(sta_value,0,1);%std
    if min_value==max_value;
    x=min_value-max_value*0.012:((max_value+max_value*0.01)-(min_value-max_value*0.012))*0.015:max_value+max_value*0.01;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    else
    x=min_value:(max_value-min_value)*0.015:max_value;
    hist(sta_value,x);
    xlim([min_value-max_value*0.012 max_value+max_value*0.01]);
    end
    title('CP','Color','w','FontWeight','bold','FontAngle','Oblique')
    INFO{1,1}='CP:';
end

set(axes_index,'Color','k','XColor','w','YColor','w','FontWeight','bold','FontAngle','Oblique');
xlabel('Values');ylabel('Frequency');
h=findobj(axes_index,'Type','patch');
ROI_ALLColor=evalin('base','ROI_ALLColor');
set(h,'FaceColor','k','EdgeColor',ROI_ALLColor{Select})

area_ROI=size(sta_value,1)*pixel_height*pixel_width;%­±¿n¤j¤p
INFO{2,1}=['Area(pixel): ' num2str(size(sta_value,1))];
INFO{3,1}=['Area(mm^2): ' num2str(area_ROI,'%.2f')];
INFO{4,1}=['Mean: ' num2str(ave_value,'%.6f')];
INFO{5,1}=['Max: ' num2str(max_value)];
INFO{6,1}=['Min: ' num2str(min_value)];
INFO{7,1}=['Std: ' num2str(std_value,'%.6f')];
set(text_Info,'string',INFO,'Max', length(INFO),'HorizontalAlignment','Left','FontSize',9);  
  