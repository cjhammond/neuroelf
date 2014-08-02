function ROI_statistics_Export(varargin)


%讀取data
global pixel_width pixel_height;
ROI_ALLvalue = evalin('base','ROI_ALLvalue');
Select = varargin{1};
ROI_value = ROI_ALLvalue{Select};

%製作表格
Export_data{1,1}='ROI Series:';
Export_data{2,1}='Image Series:';Export_data{2,2}='T2';Export_data{2,3}='ADC(mm^2/s)';Export_data{2,4}='Lambda 1(mm^2)';Export_data{2,5}='Lambda 2(mm^2)';
Export_data{2,6}='Lambda 3(mm^2)';Export_data{2,7}='Mean Diffusion(mm^2)';Export_data{2,8}='FA';Export_data{2,9}='FI';
Export_data{2,10}='RA';Export_data{2,11}='VR';Export_data{2,12}='VF';Export_data{2,13}='CL';
Export_data{2,14}='CS';Export_data{2,15}='CP';
Export_data{3,1}='Mean:';
Export_data{4,1}='Max:';
Export_data{5,1}='Min:';
Export_data{6,1}='Std:';
Export_data{7,1}='ROI Area(pixels):';Export_data{7,2}=size(ROI_value,1);
Export_data{8,1}='ROI Area(mm^2):';Export_data{8,2}=size(ROI_value,1)*pixel_height*pixel_width;%面積大小;
for i=1:14;
Export_data{3,i+1}=mean(ROI_value(:,i));
Export_data{4,i+1}=max(ROI_value(:,i));
Export_data{5,i+1}=min(ROI_value(:,i));
Export_data{6,i+1}=std(ROI_value(:,i),0,1);
end
[filename pathname] = uiputfile('\.xls','Please input file name');
if isequal(filename,0);
   return
end
h = waitbar(0,'Please waitting for second.','name','Message Box');
xlswrite([pathname filename],Export_data);
waitbar(1,h,'ROI statistics results Export completely'); 
pause(1);
close(h);
