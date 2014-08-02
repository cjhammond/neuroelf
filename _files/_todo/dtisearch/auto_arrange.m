function auto_arrange

[filename, pathname] = uigetfile( ...
{  '*.*','Dicom-images (*.ima,*.dcm)'; ...
   '*.*',  'All Files (*.*)'}, ...
   'Please open dicom images');
if ~ischar(pathname);
%     msgbox('no valid Directory selected.','Message Box','warn')
    return;
end
h1 = waitbar(0,'Loading DWI images fileheader.... , Please wait...','name','Message Box');
all_select = dir(pathname);
all_select = all_select(3:end);%去掉路徑資料夾中的路徑控制檔
sizefile = length(all_select);
filehead{sizefile,1} = [];
SequenceName{sizefile,1} = [];
Sequence_value = zeros(sizefile,1);
SliceLocation = zeros(sizefile,1);

for i = 1:sizefile;
    filehead{i,1} = dicominfo([pathname all_select(i).name]); 
    SliceLocation(i,1) = filehead{i,1}.(dicomlookup('0020', '1041'));
    SequenceName{i,1} = filehead{i,1}.(dicomlookup('0018', '0024'));
    Sequence_value(i,1) = sum(SequenceName{i,1});%計算字元ASCII編碼位元數
    waitbar(i/sizefile,h1,['Loading DWI images fileheader.... ' num2str(i) ' of ' num2str(sizefile) ' images']); 
end
close(h1);

nslice = size(unique(SliceLocation),1);
nseries = size(unique(Sequence_value),1);
if sizefile ~= nslice*nseries;
    msgbox('Maybe losed images of this directory, check the images integrality','Message Box','warn')
    return;
end
Esti = SliceLocation+Sequence_value*1000;%
h2 = waitbar(0,'Rename and restored DWI images..., Please wait...','name','Message Box');
for j = 1:sizefile;
    [row,col] = find(Esti==min(Esti));
    SequenceName_ASCII = double(SequenceName{row,1});%double>將字串轉為字元，char>字元轉字串
    SequenceName_ASCII = SequenceName_ASCII(1,2:end);%去掉第一個字元(*)
    now_slice = rem(j,nslice);
    now_slice(now_slice==0) = nslice;
    if now_slice < 10;
        movefile([pathname all_select(row).name],[pathname '\' char(SequenceName_ASCII) '_00' num2str(now_slice) '.ima'],'f');    
    elseif now_slice < 100 && now_slice >= 10;
        movefile([pathname all_select(row).name],[pathname '\' char(SequenceName_ASCII) '_0' num2str(now_slice) '.ima'],'f');
    else
        movefile([pathname all_select(row).name],[pathname '\' char(SequenceName_ASCII) '_' num2str(now_slice) '.ima'],'f');
    end
    Esti(row,1) = NaN;
    waitbar(j/sizefile,h2,['Rename and restored DWI images...' num2str(j) ' of ' num2str(sizefile) ' images']); 
end
close(h2);

