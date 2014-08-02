function [] = choose_slices(data,slice_numberx,slice_numbery,slice_numberz)
sizd = size(data);
ddata = zeros(sizd(2),sizd(1),sizd(3));
for i = 1:sizd(3);
    ddata(:,:,i) = double(data(:,:,i));
    ddata(:,:,i) = rot90(ddata(:,:,i));  %------¯x°}°fÂà90
    ddata(:,:,i) = flipud(ddata(:,:,i)); %------¤W¤UÄA­Ë
end
[x,y,z] = meshgrid(1:sizd(1),1:sizd(2),1:sizd(3));
h = slice(x,y,z,ddata,slice_numberx,slice_numbery,slice_numberz);
alpha('color')
set(h,'EdgeColor','none','FaceColor','interp',...
    'FaceAlpha',1,'FaceLighting','flat')
alphamap('rampdown')
alphamap('decrease',0)
axis image;
colormap(gray);