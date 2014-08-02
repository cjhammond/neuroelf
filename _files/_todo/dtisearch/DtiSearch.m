function varargout = DtiSearch(varargin)
%DTISEARCH M-tool for DtiSearch.fig
%      DTISEARCH, by itself, creates a new DTISEARCH or raises the existing
%      singleton*.
%
%      H = DTISEARCH returns the handle to a new DTISEARCH or the handle to
%      the existing singleton*.
%
%      DTISEARCH('Property','Value',...) creates a new DTISEARCH using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to DtiSearch_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      DTISEARCH('CALLBACK') and DTISEARCH('CALLBACK',hObject,...) call the
%      local function named CALLBACK in DTISEARCH.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text_axialslice to modify the response to about DtiSearch

% Last Modified by GUIDE v2.5 21-Nov-2011 11:47:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DtiSearch_OpeningFcn, ...
                   'gui_OutputFcn',  @DtiSearch_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before DtiSearch is made visible.
function DtiSearch_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for DtiSearch
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DtiSearch wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%===========(各項數值初始化)===========%
global direction;
global arrow_ok;
global axial_ready sagittal_ready coronal_ready;
global popumenu_index_ready ROI_ready ROI_series;
global ZoomFCurrent ZoomFSeries color ROI_times ROI_tagPos Hidden_ROIText;


arrow_ok = 1;%值為1時游標顯視為arrow
axial_ready = 0;%axes_axial還未有影像讀入
sagittal_ready = 0;%axes_sagittal還未有影像讀入
coronal_ready = 0;%axes_coronal還未有影像讀入
popumenu_index_ready = 0;%還未按下index caculation
ROI_ready = 0;%不可執行ROI相關指令
ROI_series = 0;%initializing ROI_statastics序列
direction = 0;%initializing loading diffusion directions
ZoomFCurrent = 4;% initializing zoom factor of current image
ZoomFSeries = 3;% initializing zoom factor of montage series image
color = [1 1 1];%initializing the color of ROI line 
ROI_times = 0;%initializing the times of press ROI 
ROI_tagPos = 0;%initializing of the ROI Tag position 
Hidden_ROIText = 0;%initializing of hidden ROI Text
% ALLRadioButton_h = {};
% assignin('base','ALLRadioButton_h',ALLRadioButton_h); 
clc;

% --- Outputs from this function are returned to the command line.
function varargout = DtiSearch_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider_axial_Callback(hObject, eventdata, handles)

set(gcf,'Pointer','arrow');
global slider2_slice MDims VDims;
global slidervalue2 selection_index axial_ready;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v;
global xdata_coronal_v ydata_coronal_v;
global axial_h_m1 axial_h_m2 axial_v_m1 axial_v_m2;
global sagittal_v_m1 sagittal_v_m2;
global coronal_v_m1 coronal_v_m2;
global axial_on sagittal_on coronal_on;
global ROI_ready Hidden_ROIText;

if axial_ready == 1;% image OK of axes_axial
%===========(setting current axes to axes_axial)===========%  
axial_on = 1;sagittal_on = 0;coronal_on = 0;
set(handles.radiobutton_axial,'value',1);
set(handles.radiobutton_sagittal,'value',0);
set(handles.radiobutton_coronal,'value',0);    
    
%===========(setting current axes to axial, deciding slice of image by slidervalue)===========%
slidervalue2 = get(hObject,'value');% get slidervalue
slider2_slice = round(slidervalue2);% round slidervalue to integer
%===========(plotting axial image and set text string)===========%
axes(handles.axes_axial);
cla(gcf); 
if selection_index == 2 ||selection_index == 4;% current image is color-FA
        %===========(plotting axial image of axes_axial)===========%       
        IVa_now = getappdata(handles.Load,'IVa_now');        
        imagesc(IVa_now(:,:,:,slider2_slice));axis off;axis equal;colormap gray        
        axis image;
        daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
        set(handles.text_axialslice,'string', num2str(slider2_slice));
        setappdata(handles.Load,'IMa_now',IVa_now(:,:,:,slider2_slice)); 
        
else
        IVa_now = getappdata(handles.Load,'IVa_now');
        imagesc(IVa_now(:,:,slider2_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
        set(handles.text_axialslice,'string', num2str(slider2_slice));
        setappdata(handles.Load,'IMa_now',IVa_now(:,:,slider2_slice)); 
end
hold on;
%===========(setting the default of vertical motion line marker)===========%
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
%===========(setting the default of horizontal motion line marker)===========%
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
hold off;

%===========(synchronal sagittal & coronal linemarker)===========%
axes(handles.axes_sagittal);% synchronalsagittal linemarker
hold on;
set(sagittal_v_m1,'visible','off');set(sagittal_v_m2,'visible','off');
slice_axial = (MDims(3)-slider2_slice)+1;% correction slice_axial error, correction axial slice UP and linemarker DOWN
ydata_sagittal_v = [slice_axial slice_axial];
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
hold off;
axes(handles.axes_coronal);% synchronal coronal linemarker
hold on;
set(coronal_v_m1,'visible','off');set(coronal_v_m2,'visible','off');
ydata_coronal_v = [slice_axial slice_axial];
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
hold off;

%===========(ROI axes_axial)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
axes(handles.axes_axial);
hold on;
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==1 && ROI_ALLposition{i}(2,3)==slider2_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
            text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
        end
    end
end
hold off;
end

end

% --- Executes during object creation, after setting all properties.
function slider_axial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_axial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider_sagittal_Callback(hObject, eventdata, handles)

set(gcf,'Pointer','arrow');
global slidervalue3 slider3_slice;
global VDims selection_index sagittal_ready;
global xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_h ydata_coronal_h;
global axial_h_m1 axial_h_m2 coronal_h_m1 coronal_h_m2;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global axial_on sagittal_on coronal_on ROI_ready Hidden_ROIText;

if sagittal_ready == 1;% image OK of axes_sagittal
%===========(setting current axes to axes_sagittal)===========%  
axial_on = 0;sagittal_on = 1;coronal_on = 0;
set(handles.radiobutton_axial,'value',0);
set(handles.radiobutton_sagittal,'value',1);
set(handles.radiobutton_coronal,'value',0);  
%===========(setting current axes to sagittal, deciding slice of image by slidervalue)===========%
slidervalue3 = get(hObject,'value');% get slidervalue
slider3_slice = round(slidervalue3);% round slidervalue to integer
%===========(plotting axial image and set text string)===========%
axes(handles.axes_sagittal);
cla(gcf); 
if selection_index == 2 ||selection_index == 4;% current image is color-FA
        IVs_now = getappdata(handles.Load,'IVs_now');  
        imagesc(IVs_now(:,:,:,slider3_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
        set(handles.text_sagittalslice,'string', num2str(slider3_slice));
        setappdata(handles.Load,'IMs_now',IVs_now(:,:,:,slider3_slice));
else
        IVs_now = getappdata(handles.Load,'IVs_now');
        imagesc(IVs_now(:,:,slider3_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
        set(handles.text_sagittalslice,'string', num2str(slider3_slice));
        setappdata(handles.Load,'IMs_now',IVs_now(:,:,slider3_slice));
end
hold on;
%===========(setting the default of vertical motion line marker)===========%
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
%===========(setting the default of horizontal motion line marker)===========%
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
hold off;
%===========(synchronal sagittal & coronal linemarker)===========%
axes(handles.axes_axial);% synchronal axial linemarker
hold on;
set(axial_h_m1,'visible','off');set(axial_h_m2,'visible','off');
slice_axial = slider3_slice;
xdata_axial_h = [slice_axial slice_axial];
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
hold off;

axes(handles.axes_coronal);% synchronal coronal linemarker
hold on;
set(coronal_h_m1,'visible','off');set(coronal_h_m2,'visible','off');
xdata_coronal_h = [slice_axial slice_axial];
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
hold off;

%===========(ROI axes_sagittal)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
axes(handles.axes_sagittal);
hold on;
if size(ROI_ALLposition,2)~=0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 2 && ROI_ALLposition{i}(2,3) == slider3_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText == 0;
            text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
        end
    end
end
hold off;
end

end

% --- Executes during object creation, after setting all properties.
function slider_sagittal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_sagittal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider_coronal_Callback(hObject, eventdata, handles)

set(gcf,'Pointer','arrow');
global slidervalue4 slider4_slice;
global  VDims selection_index coronal_ready ;
global xdata_axial_v ydata_axial_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;
global sagittal_h_m1 sagittal_h_m2 axial_v_m1 axial_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;
global axial_on sagittal_on coronal_on ROI_ready Hidden_ROIText;

if coronal_ready == 1;% image OK of axes_coronal
%===========(setting current axes to axes_coronal)===========%  
axial_on = 0;sagittal_on = 0;coronal_on = 1;
set(handles.radiobutton_axial,'value',0);
set(handles.radiobutton_sagittal,'value',0);
set(handles.radiobutton_coronal,'value',1);      
    
%===========(setting current axes to coronal, deciding slice of image by slidervalue)===========%
slidervalue4 = get(hObject,'value');% get slidervalue
slider4_slice = round(slidervalue4);% round slidervalue to integer
%===========(plotting axial image and set text string)===========%
axes(handles.axes_coronal);
cla(gcf); 
if selection_index == 2 ||selection_index == 4;% current image is color-FA
        IVc_now = getappdata(handles.Load,'IVc_now');  
        imagesc(IVc_now(:,:,:,slider4_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
        set(handles.text_coronalslice,'string', num2str(slider4_slice));
        setappdata(handles.Load,'IMc_now',IVc_now(:,:,:,slider4_slice));
else
        IVc_now = getappdata(handles.Load,'IVc_now');
        imagesc(IVc_now(:,:,slider4_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
        set(handles.text_coronalslice,'string', num2str(slider4_slice));
        setappdata(handles.Load,'IMc_now',IVc_now(:,:,slider4_slice));
end
hold on;
%===========(setting the default of vertical motion line marker)===========%
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'coronal_v_m1',coronal_v_m1);setappdata(handles.Load,'coronal_v_m2',coronal_v_m2);
%===========(setting the default of horizontal motion line marker)===========%
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'coronal_h_m1',coronal_h_m1);setappdata(handles.Load,'coronal_h_m2',coronal_h_m2);
hold off;
%===========(synchronal sagittal & coronal linemarker)===========%
axes(handles.axes_axial);% synchronal axial linemarker
hold on;
set(axial_v_m1,'visible','off');set(axial_v_m2,'visible','off');
slice_coronal = slider4_slice;%修正slice_axial誤差
ydata_axial_v = [slice_coronal slice_coronal];
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
hold off;

axes(handles.axes_sagittal);% synchronal sagittal linemarker
hold on;
set(sagittal_h_m1,'visible','off');set(sagittal_h_m2,'visible','off');
xdata_sagittal_h = [slice_coronal slice_coronal];
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
hold off;

%===========(ROI axes_coronal)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
axes(handles.axes_coronal);
hold on;
if size(ROI_ALLposition,2) ~= 0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 3 && ROI_ALLposition{i}(2,3) == slider4_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText == 0;
            text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
        end
    end
end
hold off;
end

end

% --- Executes during object creation, after setting all properties.
function slider_coronal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_coronal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in radiobutton_axial.
function radiobutton_axial_Callback(hObject, eventdata, handles)

global axial_on sagittal_on coronal_on;

set(hObject,'value',1);
axial_on=1;
sagittal_on=0;
coronal_on=0;
set(handles.radiobutton_sagittal,'value',0);
set(handles.radiobutton_coronal,'value',0);

% --- Executes on button press in radiobutton_sagittal.
function radiobutton_sagittal_Callback(hObject, eventdata, handles)

global axial_on sagittal_on coronal_on;

set(hObject,'value',1);
axial_on=0;
sagittal_on=1;
coronal_on=0;
set(handles.radiobutton_axial,'value',0);
set(handles.radiobutton_coronal,'value',0);

% --- Executes on button press in radiobutton_coronal.
function radiobutton_coronal_Callback(hObject, eventdata, handles)

global axial_on sagittal_on coronal_on;

set(hObject,'value',1);
axial_on=0;
sagittal_on=0;
coronal_on=1;
set(handles.radiobutton_sagittal,'value',0);
set(handles.radiobutton_axial,'value',0);

% --- Executes on button press in pushbutton_rect.
function pushbutton_rect_Callback(hObject, eventdata, handles)

global axial_on sagittal_on coronal_on MDims;
global slider2_slice slider3_slice slider4_slice ;
global ROI_ready color vis_ROI ROI_times ROI_tagPos Hidden_ROIText;
  
if axial_on == 1;
    axes(handles.axes_axial);
    RECT = roi_rect(gcf,color);    
    ROI_position(1,1) = RECT(1,1);
    ROI_position(1,2) = RECT(1,2);
    ROI_position(2,1) = RECT(1,1)+RECT(1,3);
    ROI_position(2,2) = RECT(1,2);
    ROI_position(3,1) = RECT(1,1)+RECT(1,3);
    ROI_position(3,2) = RECT(1,2)+RECT(1,4);
    ROI_position(4,1) = RECT(1,1);
    ROI_position(4,2) = RECT(1,2)+RECT(1,4);
    ROI_position(5,1) = RECT(1,1);
    ROI_position(5,2) = RECT(1,2);
    [X, Y] = meshgrid(1:MDims(1), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,ROI_position(:,1),ROI_position(:,2));
    [Seed(:,1),Seed(:,2)] = find(BW_ROI);
    Seed(:,3) = slider2_slice;    
    ROI_position(1,3) = 1;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider2_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(2)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
elseif sagittal_on == 1;    
    axes(handles.axes_sagittal); 
    RECT = roi_rect(gcf,color);    
    ROI_position(1,1) = RECT(1,1);
    ROI_position(1,2) = RECT(1,2);
    ROI_position(2,1) = RECT(1,1)+RECT(1,3);
    ROI_position(2,2) = RECT(1,2);
    ROI_position(3,1) = RECT(1,1)+RECT(1,3);
    ROI_position(3,2) = RECT(1,2)+RECT(1,4);
    ROI_position(4,1) = RECT(1,1);
    ROI_position(4,2) = RECT(1,2)+RECT(1,4);
    ROI_position(5,1) = RECT(1,1);
    ROI_position(5,2) = RECT(1,2);
    rect = ROI_position;
    rect(:,2) = MDims(3)-rect(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(1));
    BW_ROI = inpolygon(X,Y,rect(:,2),rect(:,1));
    [Seed(:,1),Seed(:,3)] = find(BW_ROI);
    Seed(:,2) = slider3_slice; 
    assignin('base','Seed',Seed)
    ROI_position(1,3) = 2;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider3_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
elseif coronal_on == 1;
    axes(handles.axes_coronal);
    RECT = roi_rect(gcf,color);    
    ROI_position(1,1) = RECT(1,1);
    ROI_position(1,2) = RECT(1,2);
    ROI_position(2,1) = RECT(1,1)+RECT(1,3);
    ROI_position(2,2) = RECT(1,2);
    ROI_position(3,1) = RECT(1,1)+RECT(1,3);
    ROI_position(3,2) = RECT(1,2)+RECT(1,4);
    ROI_position(4,1) = RECT(1,1);
    ROI_position(4,2) = RECT(1,2)+RECT(1,4);
    ROI_position(5,1) = RECT(1,1);
    ROI_position(5,2) = RECT(1,2);
    rect = ROI_position;
    rect(:,2) = MDims(3)-rect(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,rect(:,2),rect(:,1));
    [Seed(:,2),Seed(:,3)] = find(BW_ROI);
    Seed(:,1) = slider4_slice;
    ROI_position(1,3) = 3;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider4_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(2)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
end 

if (max(ROI_position(:,1))-min(ROI_position(:,1)))<=1 || (max(ROI_position(:,2))-min(ROI_position(:,2)))<=1;%when ROI region too small
    msgbox('Please draw the bigger ROI.','Message Box','warn')
    return
end

hold on;
vis_ROI = line(ROI_position(:,1),ROI_position(:,2),'color',color,'LineWidth',1); 
hold off;
%===========(Check ROI OK#)===========%
ROI_times = ROI_times+1;% ROI string increase 1
ROI_tagPos = ROI_tagPos+1;% ROI tag position increase 1
prompt = {'Please key in the Tag of this ROI :'};% name ROI
dlg_title = 'Do you use this ROI?';
num_lines = 1;
if ROI_position(1,3) == 1;
    def = {['ROI' num2str(ROI_times) '(Axial,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 2;
    def = {['ROI' num2str(ROI_times) '(Sagittal,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 3;
    def = {['ROI' num2str(ROI_times) '(Coronal,' num2str(ROI_position(2,3)) ')']};
end
options.Resize = 'on';
options.WindowStyle = 'normal';
options.Interpreter = 'tex';
input_ans = inputdlg(prompt,dlg_title,num_lines,def,options);
if isempty(input_ans);%if user press cancel
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
end
if length(input_ans{1}) == 0;%if user key in empty name
    msgbox('Please input the tag of ROI.','Message Box','warn')
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
else

    if ROI_tagPos>1;
        ListString = getappdata(handles.Load,'ListString');
    end
    ListString{ROI_tagPos} = input_ans{1};
    setappdata(handles.Load,'ListString',ListString);
    set(handles.listbox_roi,'string',ListString, 'Value', length(ListString))
end
    ROI_TextPos(1) = (max(ROI_position(:,1))-min(ROI_position(:,1)))/2+min(ROI_position(:,1));
    ROI_TextPos(2) = (max(ROI_position(:,2))-min(ROI_position(:,2)))/2+min(ROI_position(:,2));
if Hidden_ROIText == 0;
    text(ROI_TextPos(1),ROI_TextPos(2),ListString(ROI_tagPos),'HorizontalAlignment','center','Color',color,'FontSize',8);
end

if ROI_tagPos>1;% starting save ROI points
    ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
    ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
    ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
end
ROI_ALLposition{ROI_tagPos} = ROI_position;
ROI_ALLTextPos{ROI_tagPos} = ROI_TextPos;
ROI_ALLColor{ROI_tagPos} = color;
ROI_ALLSeed{ROI_tagPos} = Seed;
setappdata(handles.Load,'ROI_ALLposition',ROI_ALLposition);
setappdata(handles.Load,'ROI_ALLTextPos',ROI_ALLTextPos);
setappdata(handles.Load,'ROI_ALLColor',ROI_ALLColor);
setappdata(handles.Load,'ROI_ALLSeed',ROI_ALLSeed);

assignin('base','ROI_ALLposition',ROI_ALLposition);
assignin('base','ROI_ALLTextPos',ROI_ALLTextPos);
assignin('base','ListString',ListString);
assignin('base','ROI_ALLColor',ROI_ALLColor);
assignin('base','ROI_ALLSeed',ROI_ALLSeed);


setappdata(handles.Load,'ROI_position',ROI_position);
setappdata(handles.Load,'vis_ROI',vis_ROI);
ROI_ready = 1;
set(handles.Rename,'Enable','on');%initialing of ROI options
set(handles.Remove,'Enable','on');
set(handles.Reset_color,'Enable','on');
set(handles.Export_ROI,'Enable','on');%initialiaing enable of Export ROI option

%===========(ROI operation)===========%
InMa = getappdata(handles.Load,'InMa');
t = 0; 
for i = 1:length(Seed);
    if isempty(InMa{Seed(i,1),Seed(i,2),Seed(i,3)}) == 0;
        for j = 1:length(InMa{Seed(i,1),Seed(i,2),Seed(i,3)});
            t = t+1;           
            Index_Tract_N(t) =  InMa{Seed(i,1),Seed(i,2),Seed(i,3)}(j);
        end
    end
end
Index_Tract_N = unique(Index_Tract_N);

if get(handles.togglebutton_non,'Value') == 1;  
    
    Index_Tract = Index_Tract_N; % ROI 'NON' operation     
    
elseif get(handles.togglebutton_or,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = union(Index_Tract_B, Index_Tract_N);% ROI 'OR' operation
    end    
    
elseif get(handles.togglebutton_and,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = intersect(Index_Tract_B, Index_Tract_N);% ROI 'AND' operation
    end
    
else
   ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        for i = 1:length(Index_Tract_N);% ROI 'NOT' operation
            Index_Tract_B(Index_Tract_B == Index_Tract_N(i)) = NaN;
        end
        Index_Tract_B = Index_Tract_B(isnan(Index_Tract_B) == 0);
        Index_Tract = Index_Tract_B;
    end
    
end
setappdata(handles.Load,'Index_Tract',Index_Tract);


% --- Executes on button press in pushbutton_oval.
function pushbutton_oval_Callback(hObject, eventdata, handles)

global axial_on sagittal_on coronal_on MDims;
global slider2_slice slider3_slice slider4_slice ;
global ROI_ready color vis_ROI ROI_times ROI_tagPos Hidden_ROIText;
  
if axial_on == 1;
    axes(handles.axes_axial);
    RECT = roi_oval(gcf,color);    
    x_center = RECT(1)+RECT(3)/2;
    y_center = RECT(2)+RECT(4)/2;
    x_RO = RECT(3)/2;
    y_RO = RECT(4)/2;
    t = 0:pi/20:2*pi; 
    oval(:,1) = x_RO*cos(t)+x_center;
    oval(:,2) = y_RO*sin(t)+y_center; 
    ROI_position = oval;
    [X, Y] = meshgrid(1:MDims(1), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,ROI_position(:,1),ROI_position(:,2));
    [Seed(:,1),Seed(:,2)] = find(BW_ROI);
    Seed(:,3) = slider2_slice;    
    ROI_position(1,3) = 1;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider2_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(2)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
elseif sagittal_on == 1;    
    axes(handles.axes_sagittal); 
    RECT = roi_oval(gcf,color);    
    x_center = RECT(1)+RECT(3)/2;
    y_center = RECT(2)+RECT(4)/2;
    x_RO = RECT(3)/2;
    y_RO = RECT(4)/2;
    t = 0:pi/20:2*pi; 
    oval(:,1) = x_RO*cos(t)+x_center;
    oval(:,2) = y_RO*sin(t)+y_center; 
    ROI_position = oval;
    oval(:,2) = MDims(3)-oval(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(1));
    BW_ROI = inpolygon(X,Y,oval(:,2),oval(:,1));
    [Seed(:,1),Seed(:,3)] = find(BW_ROI);
    Seed(:,2) = slider3_slice;    
    ROI_position(1,3) = 2;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider3_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
elseif coronal_on == 1;
    axes(handles.axes_coronal);
    RECT = roi_oval(gcf,color);    
    x_center = RECT(1)+RECT(3)/2;
    y_center = RECT(2)+RECT(4)/2;
    x_RO = RECT(3)/2;
    y_RO = RECT(4)/2;
    t = 0:pi/20:2*pi; 
    oval(:,1) = x_RO*cos(t)+x_center;
    oval(:,2) = y_RO*sin(t)+y_center; 
    ROI_position = oval;
    oval(:,2) = MDims(3)-oval(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,oval(:,2),oval(:,1));
    [Seed(:,2),Seed(:,3)] = find(BW_ROI);
    Seed(:,1) = slider4_slice;
    ROI_position(1,3) = 3;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider4_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(2)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
end 

if (max(ROI_position(:,1))-min(ROI_position(:,1)))<=1 || (max(ROI_position(:,2))-min(ROI_position(:,2)))<=1;%when ROI region too small
    msgbox('Please draw the bigger ROI.','Message Box','warn')
    return
end

hold on;
vis_ROI = line(ROI_position(:,1),ROI_position(:,2),'color',color,'LineWidth',1); 
hold off;
%===========(Check ROI OK#)===========%
ROI_times = ROI_times+1;% ROI string increase 1
ROI_tagPos = ROI_tagPos+1;% ROI tag position increase 1
prompt = {'Please key in the Tag of this ROI :'};% name ROI
dlg_title = 'Do you use this ROI?';
num_lines = 1;
if ROI_position(1,3) == 1;
    def = {['ROI' num2str(ROI_times) '(Axial,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 2;
    def = {['ROI' num2str(ROI_times) '(Sagittal,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 3;
    def = {['ROI' num2str(ROI_times) '(Coronal,' num2str(ROI_position(2,3)) ')']};
end
options.Resize = 'on';
options.WindowStyle = 'normal';
options.Interpreter = 'tex';
input_ans = inputdlg(prompt,dlg_title,num_lines,def,options);
if isempty(input_ans);%if user press cancel
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
end
if length(input_ans{1}) == 0;%if user key in empty name
    msgbox('Please input the tag of ROI.','Message Box','warn')
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
else

    if ROI_tagPos>1;
        ListString = getappdata(handles.Load,'ListString');
    end
    ListString{ROI_tagPos} = input_ans{1};
    setappdata(handles.Load,'ListString',ListString);
    set(handles.listbox_roi,'string',ListString, 'Value', length(ListString))
end
    ROI_TextPos(1) = (max(ROI_position(:,1))-min(ROI_position(:,1)))/2+min(ROI_position(:,1));
    ROI_TextPos(2) = (max(ROI_position(:,2))-min(ROI_position(:,2)))/2+min(ROI_position(:,2));
if Hidden_ROIText == 0;
    text(ROI_TextPos(1),ROI_TextPos(2),ListString(ROI_tagPos),'HorizontalAlignment','center','Color',color,'FontSize',8);
end

if ROI_tagPos>1;% starting save ROI points
    ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
    ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
    ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
end
ROI_ALLposition{ROI_tagPos} = ROI_position;
ROI_ALLTextPos{ROI_tagPos} = ROI_TextPos;
ROI_ALLColor{ROI_tagPos} = color;
ROI_ALLSeed{ROI_tagPos} = Seed;
setappdata(handles.Load,'ROI_ALLposition',ROI_ALLposition);
setappdata(handles.Load,'ROI_ALLTextPos',ROI_ALLTextPos);
setappdata(handles.Load,'ROI_ALLColor',ROI_ALLColor);
setappdata(handles.Load,'ROI_ALLSeed',ROI_ALLSeed);

assignin('base','ROI_ALLposition',ROI_ALLposition);
assignin('base','ROI_ALLTextPos',ROI_ALLTextPos);
assignin('base','ListString',ListString);
assignin('base','ROI_ALLColor',ROI_ALLColor);
assignin('base','ROI_ALLSeed',ROI_ALLSeed); 


setappdata(handles.Load,'ROI_position',ROI_position);
setappdata(handles.Load,'vis_ROI',vis_ROI);
ROI_ready = 1;
set(handles.Rename,'Enable','on');%initialing of ROI options
set(handles.Remove,'Enable','on');
set(handles.Reset_color,'Enable','on');
set(handles.Export_ROI,'Enable','on');%initialiaing enable of Export ROI option

%===========(ROI operation)===========%
InMa = getappdata(handles.Load,'InMa');
t = 0; 
for i = 1:length(Seed);
    if isempty(InMa{Seed(i,1),Seed(i,2),Seed(i,3)}) == 0;
        for j = 1:length(InMa{Seed(i,1),Seed(i,2),Seed(i,3)});
            t = t+1;           
            Index_Tract_N(t) =  InMa{Seed(i,1),Seed(i,2),Seed(i,3)}(j);
        end
    end
end
Index_Tract_N = unique(Index_Tract_N);

if get(handles.togglebutton_non,'Value') == 1;  
    
    Index_Tract = Index_Tract_N; % ROI 'NON' operation     
    
elseif get(handles.togglebutton_or,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = union(Index_Tract_B, Index_Tract_N);% ROI 'OR' operation
    end    
    
elseif get(handles.togglebutton_and,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = intersect(Index_Tract_B, Index_Tract_N);% ROI 'AND' operation
    end
    
else
   ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        for i = 1:length(Index_Tract_N);% ROI 'NOT' operation
            Index_Tract_B(Index_Tract_B == Index_Tract_N(i)) = NaN;
        end
        Index_Tract_B = Index_Tract_B(isnan(Index_Tract_B) == 0);
        Index_Tract = Index_Tract_B;
    end
    
end
setappdata(handles.Load,'Index_Tract',Index_Tract);
assignin('base','Index_Tract',Index_Tract);

% --- Executes on button press in pushbutton_poly.
function pushbutton_poly_Callback(hObject, eventdata, handles)

global axial_on sagittal_on coronal_on MDims;
global slider2_slice slider3_slice slider4_slice ;
global ROI_ready color vis_ROI ROI_times ROI_tagPos Hidden_ROIText;
  
if axial_on == 1;
    axes(handles.axes_axial);
    [poly(:,1),poly(:,2)] = roi_poly(gcf,color);
    poly(end+1,:) = poly(1,:);% put first point to end for a whole contour  
    ROI_position = poly;
    [X, Y] = meshgrid(1:MDims(1), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,ROI_position(:,1),ROI_position(:,2));
    [Seed(:,1),Seed(:,2)] = find(BW_ROI);
    Seed(:,3) = slider2_slice;
    ROI_position(1,3) = 1;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider2_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(2)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
elseif sagittal_on == 1;    
    axes(handles.axes_sagittal); 
    [poly(:,1),poly(:,2)] = roi_poly(gcf,color);
    poly(end+1,:) = poly(1,:);% put first point to end for a whole contour  
    ROI_position = poly;
    poly(:,2) = MDims(3)-poly(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(1));
    BW_ROI = inpolygon(X,Y,poly(:,2),poly(:,1));
    [Seed(:,1),Seed(:,3)] = find(BW_ROI);
    Seed(:,2) = slider3_slice;
    ROI_position(1,3) = 2;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider3_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
elseif coronal_on == 1;
    axes(handles.axes_coronal);
    [poly(:,1),poly(:,2)] = roi_poly(gcf,color);
    poly(end+1,:) = poly(1,:);% put first point to end for a whole contour  
    ROI_position = poly;
    poly(:,2) = MDims(3)-poly(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,poly(:,2),poly(:,1));
    [Seed(:,2),Seed(:,3)] = find(BW_ROI);
    Seed(:,1) = slider4_slice;
    ROI_position(1,3) = 3;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider4_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(2)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
end 

if (max(ROI_position(:,1))-min(ROI_position(:,1)))<=1 || (max(ROI_position(:,2))-min(ROI_position(:,2)))<=1;%when ROI region too small
    msgbox('Please draw the bigger ROI.','Message Box','warn')
    return
end

hold on;
vis_ROI = line(ROI_position(:,1),ROI_position(:,2),'color',color,'LineWidth',1); 
hold off;
%===========(Check ROI OK#)===========%
ROI_times = ROI_times+1;% ROI string increase 1
ROI_tagPos = ROI_tagPos+1;% ROI tag position increase 1
prompt = {'Please key in the Tag of this ROI :'};% name ROI
dlg_title = 'Do you use this ROI?';
num_lines = 1;
if ROI_position(1,3) == 1;
    def = {['ROI' num2str(ROI_times) '(Axial,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 2;
    def = {['ROI' num2str(ROI_times) '(Sagittal,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 3;
    def = {['ROI' num2str(ROI_times) '(Coronal,' num2str(ROI_position(2,3)) ')']};
end
options.Resize = 'on';
options.WindowStyle = 'normal';
options.Interpreter = 'tex';
input_ans = inputdlg(prompt,dlg_title,num_lines,def,options);
if isempty(input_ans);%if user press cancel
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
end
if length(input_ans{1}) == 0;%if user key in empty name
    msgbox('Please input the tag of ROI.','Message Box','warn')
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
else

    if ROI_tagPos>1;
        ListString = getappdata(handles.Load,'ListString');
    end
    ListString{ROI_tagPos} = input_ans{1};
    setappdata(handles.Load,'ListString',ListString);
    set(handles.listbox_roi,'string',ListString, 'Value', length(ListString))
end
    ROI_TextPos(1) = (max(ROI_position(:,1))-min(ROI_position(:,1)))/2+min(ROI_position(:,1));
    ROI_TextPos(2) = (max(ROI_position(:,2))-min(ROI_position(:,2)))/2+min(ROI_position(:,2));
if Hidden_ROIText == 0;
    text(ROI_TextPos(1),ROI_TextPos(2),ListString(ROI_tagPos),'HorizontalAlignment','center','Color',color,'FontSize',8);
end

if ROI_tagPos>1;% starting save ROI points
    ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
    ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
    ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
end
ROI_ALLposition{ROI_tagPos} = ROI_position;
ROI_ALLTextPos{ROI_tagPos} = ROI_TextPos;
ROI_ALLColor{ROI_tagPos} = color;
ROI_ALLSeed{ROI_tagPos} = Seed;
setappdata(handles.Load,'ROI_ALLposition',ROI_ALLposition);
setappdata(handles.Load,'ROI_ALLTextPos',ROI_ALLTextPos);
setappdata(handles.Load,'ROI_ALLColor',ROI_ALLColor);
setappdata(handles.Load,'ROI_ALLSeed',ROI_ALLSeed);

assignin('base','ROI_ALLposition',ROI_ALLposition);
assignin('base','ROI_ALLTextPos',ROI_ALLTextPos);
assignin('base','ListString',ListString);
assignin('base','ROI_ALLColor',ROI_ALLColor);
assignin('base','ROI_ALLSeed',ROI_ALLSeed);


setappdata(handles.Load,'ROI_position',ROI_position);
setappdata(handles.Load,'vis_ROI',vis_ROI);
ROI_ready = 1;
set(handles.Rename,'Enable','on');%initialing of ROI options
set(handles.Remove,'Enable','on');
set(handles.Reset_color,'Enable','on');
set(handles.Export_ROI,'Enable','on');%initialiaing enable of Export ROI option


%===========(ROI operation)===========%
InMa = getappdata(handles.Load,'InMa');
t = 0; 
for i = 1:length(Seed);
    if isempty(InMa{Seed(i,1),Seed(i,2),Seed(i,3)}) == 0;
        for j = 1:length(InMa{Seed(i,1),Seed(i,2),Seed(i,3)});
            t = t+1;           
            Index_Tract_N(t) =  InMa{Seed(i,1),Seed(i,2),Seed(i,3)}(j);
        end
    end
end
Index_Tract_N = unique(Index_Tract_N);

if get(handles.togglebutton_non,'Value') == 1;  
    
    Index_Tract = Index_Tract_N; % ROI 'NON' operation     
    
elseif get(handles.togglebutton_or,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = union(Index_Tract_B, Index_Tract_N);% ROI 'OR' operation
    end    
    
elseif get(handles.togglebutton_and,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = intersect(Index_Tract_B, Index_Tract_N);% ROI 'AND' operation
    end
    
else
   ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        for i = 1:length(Index_Tract_N);% ROI 'NOT' operation
            Index_Tract_B(Index_Tract_B == Index_Tract_N(i)) = NaN;
        end
        Index_Tract_B = Index_Tract_B(isnan(Index_Tract_B) == 0);
        Index_Tract = Index_Tract_B;
    end
    
end
setappdata(handles.Load,'Index_Tract',Index_Tract);



% --- Executes on button press in pushbutton_free.
function pushbutton_free_Callback(hObject, eventdata, handles)

global axial_on sagittal_on coronal_on MDims;
global slider2_slice slider3_slice slider4_slice ;
global ROI_ready color vis_ROI ROI_times ROI_tagPos Hidden_ROIText;
  
if axial_on == 1;
    axes(handles.axes_axial);
    [free(:,1),free(:,2)] = roi_free(gcf,color);
    free(end+1,:) = free(1,:);% put first point to end for a whole contour  
    ROI_position = free;
    [X, Y] = meshgrid(1:MDims(1), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,ROI_position(:,1),ROI_position(:,2));
    [Seed(:,1),Seed(:,2)] = find(BW_ROI);
    Seed(:,3) = slider2_slice;
    ROI_position(1,3) = 1;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider2_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(2)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
elseif sagittal_on == 1;    
    axes(handles.axes_sagittal); 
    [free(:,1),free(:,2)] = roi_free(gcf,color);
    free(end+1,:) = free(1,:);% put first point to end for a whole contour  
    ROI_position = free;
    free(:,2) = MDims(3)-free(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(1));
    BW_ROI = inpolygon(X,Y,free(:,2),free(:,1));
    [Seed(:,1),Seed(:,3)] = find(BW_ROI);
    Seed(:,2) = slider3_slice;
    ROI_position(1,3) = 2;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider3_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(1)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
elseif coronal_on == 1;
    axes(handles.axes_coronal);
    [free(:,1),free(:,2)] = roi_free(gcf,color);
    free(end+1,:) = free(1,:);% put first point to end for a whole contour  
    ROI_position = free;
    free(:,2) = MDims(3)-free(:,2);
    assignin('base','ROI_position',ROI_position);
    [X, Y] = meshgrid(1:MDims(3), 1:MDims(2));
    BW_ROI = inpolygon(X,Y,free(:,2),free(:,1));
    [Seed(:,2),Seed(:,3)] = find(BW_ROI);
    Seed(:,1) = slider4_slice;
    ROI_position(1,3) = 3;% ROI header, decideing axial=1;sigittal=2;coronal=3
    ROI_position(2,3) = slider4_slice;% ROI header, decideing slice
    if min(ROI_position(:,1))<0.5 || min(ROI_position(:,2))<0.5 || max(ROI_position(:,1))>MDims(2)+0.5 || max(ROI_position(:,2))>MDims(3)+0.5;%when ROI region outside image
        msgbox('Please draw the ROI intra image.','Message Box','warn')
        return
    end
    
end 

if (max(ROI_position(:,1))-min(ROI_position(:,1)))<=1 || (max(ROI_position(:,2))-min(ROI_position(:,2)))<=1;%when ROI region too small
    msgbox('Please draw the bigger ROI.','Message Box','warn')
    return
end

hold on;
vis_ROI = line(ROI_position(:,1),ROI_position(:,2),'color',color,'LineWidth',1); 
hold off;
%===========(Check ROI OK#)===========%
ROI_times = ROI_times+1;% ROI string increase 1
ROI_tagPos = ROI_tagPos+1;% ROI tag position increase 1
prompt = {'Please key in the Tag of this ROI :'};% name ROI
dlg_title = 'Do you use this ROI?';
num_lines = 1;
if ROI_position(1,3) == 1;
    def = {['ROI' num2str(ROI_times) '(Axial,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 2;
    def = {['ROI' num2str(ROI_times) '(Sagittal,' num2str(ROI_position(2,3)) ')']};
elseif ROI_position(1,3) == 3;
    def = {['ROI' num2str(ROI_times) '(Coronal,' num2str(ROI_position(2,3)) ')']};
end
options.Resize = 'on';
options.WindowStyle = 'normal';
options.Interpreter = 'tex';
input_ans = inputdlg(prompt,dlg_title,num_lines,def,options);
if isempty(input_ans);%if user press cancel
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
end
if length(input_ans{1}) == 0;%if user key in empty name
    msgbox('Please input the tag of ROI.','Message Box','warn')
    ROI_times = ROI_times-1;
    ROI_tagPos = ROI_tagPos-1;
    delete(vis_ROI);
    return
else

    if ROI_tagPos>1;
        ListString = getappdata(handles.Load,'ListString');
    end
    ListString{ROI_tagPos} = input_ans{1};
    setappdata(handles.Load,'ListString',ListString);
    set(handles.listbox_roi,'string',ListString, 'Value', length(ListString))
end
    ROI_TextPos(1) = (max(ROI_position(:,1))-min(ROI_position(:,1)))/2+min(ROI_position(:,1));
    ROI_TextPos(2) = (max(ROI_position(:,2))-min(ROI_position(:,2)))/2+min(ROI_position(:,2));
if Hidden_ROIText == 0;
    text(ROI_TextPos(1),ROI_TextPos(2),ListString(ROI_tagPos),'HorizontalAlignment','center','Color',color,'FontSize',8);
end

if ROI_tagPos>1;% starting save ROI points
    ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
    ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
    ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
end
ROI_ALLposition{ROI_tagPos} = ROI_position;
ROI_ALLTextPos{ROI_tagPos} = ROI_TextPos;
ROI_ALLColor{ROI_tagPos} = color;
ROI_ALLSeed{ROI_tagPos} = Seed;
setappdata(handles.Load,'ROI_ALLposition',ROI_ALLposition);
setappdata(handles.Load,'ROI_ALLTextPos',ROI_ALLTextPos);
setappdata(handles.Load,'ROI_ALLColor',ROI_ALLColor);
setappdata(handles.Load,'ROI_ALLSeed',ROI_ALLSeed);

assignin('base','ROI_ALLposition',ROI_ALLposition);
assignin('base','ROI_ALLTextPos',ROI_ALLTextPos);
assignin('base','ListString',ListString);
assignin('base','ROI_ALLColor',ROI_ALLColor);
assignin('base','ROI_ALLSeed',ROI_ALLSeed);


setappdata(handles.Load,'ROI_position',ROI_position);
setappdata(handles.Load,'vis_ROI',vis_ROI);
ROI_ready = 1;
set(handles.Rename,'Enable','on');% initialing of ROI options
set(handles.Remove,'Enable','on');
set(handles.Reset_color,'Enable','on');
set(handles.Export_ROI,'Enable','on');% initialiaing enable of Export ROI option


%===========(ROI operation)===========%
InMa = getappdata(handles.Load,'InMa');
t = 0; 
for i = 1:length(Seed);
    if isempty(InMa{Seed(i,1),Seed(i,2),Seed(i,3)}) == 0;
        for j = 1:length(InMa{Seed(i,1),Seed(i,2),Seed(i,3)});
            t = t+1;           
            Index_Tract_N(t) =  InMa{Seed(i,1),Seed(i,2),Seed(i,3)}(j);
        end
    end
end
Index_Tract_N = unique(Index_Tract_N);

if get(handles.togglebutton_non,'Value') == 1;  
    
    Index_Tract = Index_Tract_N; % ROI 'NON' operation     
    
elseif get(handles.togglebutton_or,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = union(Index_Tract_B, Index_Tract_N);% ROI 'OR' operation
    end    
    
elseif get(handles.togglebutton_and,'Value') == 1;
    
    ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        Index_Tract = intersect(Index_Tract_B, Index_Tract_N);% ROI 'AND' operation
    end
    
else
   ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
    if length(ROI_ALLSeed) == 1;
        Index_Tract = Index_Tract_N;% ROI 'NON' operation 
    else
        Index_Tract_B = getappdata(handles.Load,'Index_Tract');
        assignin('base','Index_Tract_N',Index_Tract_N)
        assignin('base','Index_Tract_B',Index_Tract_B)
        for i = 1:length(Index_Tract_N);% ROI 'NOT' operation
            Index_Tract_B(Index_Tract_B == Index_Tract_N(i)) = NaN;
        end
        Index_Tract_B = Index_Tract_B(isnan(Index_Tract_B) == 0);
        Index_Tract = Index_Tract_B;
    end
    
end
setappdata(handles.Load,'Index_Tract',Index_Tract);


% --- Executes on button press in pushbutton_statistic.
function pushbutton_statistic_Callback(hObject, eventdata, handles)

global ROI_ready color ROI_tagPos;

if ROI_ready == 1;
Select = get(handles.listbox_roi,'Value');
ROI_ALLvalue = getappdata(handles.Load,'ROI_ALLvalue');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
ListString = getappdata(handles.Load,'ListString');
ROI_statistics(ROI_ALLvalue,ROI_ALLColor,ListString{Select},Select);

end

% --- Executes on selection change in listbox_roi.
function listbox_roi_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_roi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox_roi contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_roi


% --- Executes during object creation, after setting all properties.
function listbox_roi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_roi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_setcolor.
function pushbutton_setcolor_Callback(hObject, eventdata, handles)

global color;

temp_color = uisetcolor;
if isequal(temp_color,0);
   return
else
    color = temp_color;
    set(handles.pushbutton_setcolor,'BackgroundColor',color);
end


% --- Executes on selection change in popupmenu_index.
function popupmenu_index_Callback(hObject, eventdata, handles)

global selection_index;
global MDims VDims;
global slider2_slice slider3_slice slider4_slice;
global ROI_ready Hidden_ROIText;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;
global axial_h_m1 axial_h_m2 axial_v_m1 axial_v_m2;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;

selection_index = get(gcbo,'Value');

if selection_index == 1;% FA   
    IVa_now = getappdata(handles.Load,'FA');
    IVs_now = permute(IVa_now,[3 1 2]);
    for i = 1:MDims(2);
        IVs_now(:,:,i) = flipud(IVs_now(:,:,i));
    end
    IVc_now = permute(IVa_now,[3 2 1]);
    for i = 1:MDims(1);
        IVc_now(:,:,i) = flipud(IVc_now(:,:,i));
    end
elseif selection_index == 2 ||selection_index == 4;% RGB FA
    if selection_index == 2;
        IVa_now = getappdata(handles.Load,'FEFA');  
    else
        IVa_now = getappdata(handles.Load,'LFA');
    end
    IVs_now = permute(IVa_now,[4 1 3 2]);
    for i = 1:3;
        for j = 1:MDims(2);        
            IVs_now(:,:,i,j) = flipud(IVs_now(:,:,i,j));
        end
    end
    IVc_now = permute(IVa_now,[4 2 3 1]);
    for i = 1:3;
        for j = 1:MDims(2);        
            IVc_now(:,:,i,j) = flipud(IVc_now(:,:,i,j));
        end
    end
elseif selection_index == 3;% B0
    IVa_now = getappdata(handles.Load,'DWIB0');
    IVs_now = permute(IVa_now,[3 1 2]);
    for i = 1:MDims(2);
        IVs_now(:,:,i) = flipud(IVs_now(:,:,i));
    end
    IVc_now = permute(IVa_now,[3 2 1]);
    for i = 1:MDims(1);
        IVc_now(:,:,i) = flipud(IVc_now(:,:,i));
    end
end

if selection_index == 2 ||selection_index == 4;% RGB FA
        %===========(plotting axial image of axes_axial)===========%
        axes(handles.axes_axial);
        imagesc(IVa_now(:,:,:,slider2_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
        setappdata(handles.Load,'IVa_now',IVa_now);
        setappdata(handles.Load,'IMa_now',IVa_now(:,:,:,slider2_slice));
        %===========(plotting sagittal image of axes_sagittal)===========%
        axes(handles.axes_sagittal);
        imagesc(IVs_now(:,:,:,slider3_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
        setappdata(handles.Load,'IVs_now',IVs_now);
        setappdata(handles.Load,'IMs_now',IVs_now(:,:,:,slider3_slice));
        %===========(plotting coronal image of axes_coronal)===========%
        axes(handles.axes_coronal);
        imagesc(IVc_now(:,:,:,slider4_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
        setappdata(handles.Load,'IVc_now',IVc_now);
        setappdata(handles.Load,'IMc_now',IVc_now(:,:,:,slider4_slice));
    
else       
        %===========(axial show image & text)===========%
        axes(handles.axes_axial);
        cla(gcf); 
        imagesc(IVa_now(:,:,slider2_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
        setappdata(handles.Load,'IVa_now',IVa_now);
        setappdata(handles.Load,'IMa_now',IVa_now(:,:,slider2_slice));

        %===========(sagittal show image & text)===========%
        axes(handles.axes_sagittal);
        cla(gcf); 
        imagesc(IVs_now(:,:,slider3_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
        setappdata(handles.Load,'IVs_now',IVs_now);
        setappdata(handles.Load,'IMs_now',IVs_now(:,:,slider3_slice));
        %===========(coronal show image & text)===========%
        axes(handles.axes_coronal);
        cla(gcf); 
        imagesc(IVc_now(:,:,slider4_slice));axis off;axis equal;colormap gray
        axis image;
        daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
        setappdata(handles.Load,'IVc_now',IVc_now);
        setappdata(handles.Load,'IMc_now',IVc_now(:,:,slider4_slice));
end

axes(handles.axes_axial);% axial
hold on;
%===========(setting the default of vertical and horizontal motion line marker)===========%
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');

%===========(ROI axes_axial)===========%
if ROI_ready == 1;%if ROI is input
    ListString = getappdata(handles.Load,'ListString');
    ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
    ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
    ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    if size(ROI_ALLposition,2) ~= 0;
        for i = 1:size(ROI_ALLposition,2);
            if ROI_ALLposition{i}(1,3) == 1 && ROI_ALLposition{i}(2,3) == slider2_slice;
                line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
                if Hidden_ROIText == 0;
                    text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
                end
            end
        end
    end
end
hold off;

axes(handles.axes_sagittal);%sagittal
hold on;
%===========(setting the default of vertical and horizontal motion line marker)===========%
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');

%===========(ROI axes_sagittal)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    if size(ROI_ALLposition,2) ~= 0;
        for i = 1:size(ROI_ALLposition,2);
            if ROI_ALLposition{i}(1,3) == 2 && ROI_ALLposition{i}(2,3) == slider3_slice;
                line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
                if Hidden_ROIText == 0;
                    text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
                end
            end
        end
    end
end
hold off;

axes(handles.axes_coronal);%coronal      
hold on;
%===========(setting the default of vertical and horizontal motion line marker)===========%
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');

%===========(ROI axes_coronal)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    if size(ROI_ALLposition,2) ~= 0;
        for i = 1:size(ROI_ALLposition,2);
            if ROI_ALLposition{i}(1,3) == 3 && ROI_ALLposition{i}(2,3) == slider4_slice;
                line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
                if Hidden_ROIText == 0;
                    text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
                end
            end
        end
    end
end
hold off;

% --- Executes during object creation, after setting all properties.
function popupmenu_index_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in togglebutton_non.
function togglebutton_non_Callback(hObject, eventdata, handles)

set(handles.togglebutton_non,'Value',1);
set(handles.togglebutton_or,'Value',0);
set(handles.togglebutton_and,'Value',0);
set(handles.togglebutton_not,'Value',0);


% --------------------------------------------------------------------
function Tool_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function Current_image_axial_unpure_Callback(hObject, eventdata, handles)

global MDims ZoomFCurrent;

currPicture = getframe(handles.axes_axial);
currPicture = imresize(currPicture.cdata,[MDims(1)*ZoomFCurrent MDims(2)*ZoomFCurrent]);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');

if isequal(filename,0);
   return
end
imwrite(currPicture,[pathname filename]);

% --------------------------------------------------------------------
function Load_Callback(hObject, eventdata, handles)

global filename pathname MDims VDims StepRate;
global axial_ready sagittal_ready coronal_ready;
global corsshair_value;
global selection_index;
global slider2_slice slider3_slice slider4_slice;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;
global axial_h_m1 axial_h_m2 axial_v_m1 axial_v_m2;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;
global axial_on sagittal_on coronal_on;

%===========(load DTI-mat-data file)===========%
[filename, pathname] = uigetfile( ...
{'*.mat','Mat Files (*.mat)'}, ...
   'Please select the DTI-mat-data file', ...
   'MultiSelect', 'off');
if isequal(filename,0);
   return
end
set(handles.text_condition,'string','Busy....');
h = waitbar(0,'Loading DTI-mat-data, Please wait...','name','Message Box');
load([pathname filename]);
waitbar(1,h,'Loading DTI-mat-data complete...'); 

setappdata(handles.Load,'DWIB0',DWIB0);
setappdata(handles.Load,'FA',FA);
FEFA = permute(FEFA,[1 2 4 3]);
setappdata(handles.Load,'FEFA',FEFA);
setappdata(handles.Load,'InMa',InMa);
setappdata(handles.Load,'TractAng',TractAng);
setappdata(handles.Load,'TractFA',TractFA);
setappdata(handles.Load,'TractFE',TractFE);
setappdata(handles.Load,'TractL',TractL);
setappdata(handles.Load,'Tracts',Tracts);
setappdata(handles.Load,'CMa',CMa);
IVa_now = FA;
setappdata(handles.Load,'IVa_now',IVa_now);
close(h);

%===========(setting the default of image slider)===========%
slider_step1 = 1/(MDims(3)-1);% axial
slider_step2 = 3/(MDims(3)-1); 
set(handles.slider_axial,'sliderstep',[slider_step1 slider_step2],'max',MDims(3),'min',1,'value',MDims(3)/2);
slider_step1 = 1/(MDims(2)-1);% sagittal
slider_step2 = 3/(MDims(2)-1); 
set(handles.slider_sagittal,'sliderstep',[slider_step1 slider_step2],'max',MDims(2),'min',1,'value',MDims(2)/2);
slider_step1 = 1/(MDims(1)-1);% coronal
slider_step2 = 3/(MDims(1)-1); 
set(handles.slider_coronal,'sliderstep',[slider_step1 slider_step2],'max',MDims(1),'min',1,'value',MDims(1)/2);

%===========(plotting axial image of axes_axial)===========%
axes(handles.axes_axial);
imagesc(IVa_now(:,:,round(MDims(3)/2)));axis off;axis equal;colormap gray
axis image;
daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
set(handles.text_axialslice,'string', num2str(round(MDims(3)/2)));
setappdata(handles.Load,'IVa_now',IVa_now);
setappdata(handles.Load,'IMa_now',IVa_now(:,:,round(MDims(3)/2)));
axial_ready = 1;

hold on;
%===========(setting the default of vertical motion line marker)===========%
axes_XLim = get(gca, {'XLim'});
xdata_axial_v = cell2mat(axes_XLim);
ydata_axial_v = [MDims(1)/2 MDims(1)/2];
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
%===========(setting the default of horizontal motion line marker)===========%
axes_YLim = get(gca, {'YLim'});
ydata_axial_h = cell2mat(axes_YLim);
xdata_axial_h = [MDims(2)/2 MDims(2)/2];
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
hold off;

%===========(plotting sagittal image of axes_sagittal)===========%
axes(handles.axes_sagittal);
IMs_now = IVa_now;
IMs_now = permute(IMs_now,[3 1 2]);
for i = 1:MDims(2);
    IMs_now(:,:,i) = flipud(IMs_now(:,:,i));
end
imagesc(IMs_now(:,:,round(MDims(2)/2)));axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
set(handles.text_sagittalslice,'string',num2str(round(MDims(2)/2)));
setappdata(handles.Load,'IVs_now',IMs_now);
setappdata(handles.Load,'IMs_now',IMs_now(:,:,round(MDims(2)/2)));
sagittal_ready = 1;

hold on;
%===========(setting the default of vertical motion line marker)===========%
axes_XLim = get(gca, {'XLim'});
xdata_sagittal_v = cell2mat(axes_XLim);
ydata_sagittal_v = [round(MDims(3)-MDims(3)/2+1) round(MDims(3)-MDims(3)/2+1)];
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
%===========(setting the default of horizontal motion line marker)===========%
axes_YLim = get(gca, {'YLim'});
ydata_sagittal_h = cell2mat(axes_YLim);
xdata_sagittal_h = [round(MDims(1)/2) round(MDims(1)/2)];
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
hold off;

%===========(plotting coronal image of axes_coronal)===========%
axes(handles.axes_coronal);
IMc_now = IVa_now;
IMc_now = permute(IMc_now,[3 2 1]);
for i = 1:MDims(1);
    IMc_now(:,:,i) = flipud(IMc_now(:,:,i));
end
imagesc(IMc_now(:,:,round(MDims(1)/2)));axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
set(handles.text_coronalslice,'string',num2str(round(MDims(1)/2)));
setappdata(handles.Load,'IVc_now',IMc_now);
setappdata(handles.Load,'IMc_now',IMc_now(:,:,round(MDims(1)/2)));
coronal_ready = 1;

hold on;
%===========(setting the default of vertical motion line marker)===========%
axes_XLim = get(gca, {'XLim'});
xdata_coronal_v = cell2mat(axes_XLim);
ydata_coronal_v = [round(MDims(3)-MDims(3)/2+1) round(MDims(3)-MDims(3)/2+1)];
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
%===========(setting the default of horizontal motion line marker)===========%
axes_YLim = get(gca, {'YLim'});
ydata_coronal_h = cell2mat(axes_YLim);
xdata_coronal_h = [round(MDims(1)/2) round(MDims(1)/2)];
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
hold off;

%===========(axes_visualization)===========%
% axes(handles.axes_reconstruction);
% % imagesc(DWI(:,:,MDims(3)/2,1));axis off;axis equal;colormap gray
% slices_visualization(DWI(:,:,:,1),im_width/2,im_height/2,MDims(3)/2);
% set(gca,'color','none'); 


%===========(initializing index popupmenu)===========%
IndexString{1} = 'FA images';
IndexString{2} = 'Color-coded FA images';
IndexString{3} = 'b0 images';
set(handles.popupmenu_index,'String',IndexString)




%===========(other setting)===========%
selection_index = 1;
corsshair_value = 1;
set(handles.text_condition,'string',[]);
slider2_slice = round(MDims(3)/2);
slider3_slice = round(MDims(2)/2);
slider4_slice = round(MDims(1)/2);


set(handles.radiobutton_axial,'value',1);%initializing axial radiobuttun
axial_on = 1;
sagittal_on = 0;
coronal_on = 0;
set(handles.radiobutton_sagittal,'value',0);
set(handles.radiobutton_coronal,'value',0);
%===========(initializing of button setting)===========%
set(handles.Import_ROI,'Enable','on');%initialiaing enable of Import ROI option
set(handles.pushbutton_rect,'Enable','on');
set(handles.pushbutton_oval,'Enable','on');
set(handles.pushbutton_poly,'Enable','on');
set(handles.pushbutton_free,'Enable','on');
set(handles.popupmenu_index,'Enable','on');

set(handles.togglebutton_non,'Enable','on');
set(handles.togglebutton_non,'Value',1);
set(handles.togglebutton_or,'Enable','on');
set(handles.togglebutton_or,'Value',0);
set(handles.togglebutton_and,'Enable','on');
set(handles.togglebutton_and,'Value',0);
set(handles.togglebutton_not,'Enable','on');
set(handles.togglebutton_not,'Value',0);

% set(handles.pushbutton_statistic,'Enable','on');
set(handles.listbox_roi,'Enable','on');
set(handles.pushbutton_setcolor,'Enable','on');
set(handles.pushbutton_setcolor,'BackgroundColor',[1 1 1]);
set(handles.Save_images_axial,'Enable','on');%initializing save image options
set(handles.Save_images_sagittal,'Enable','on');
set(handles.Save_images_coronal,'Enable','on');
set(handles.Hidden,'Enable','on');
set(handles.pushbutton_fiber,'Enable','on');
set(handles.togglebutton_arrow,'Enable','on');
set(handles.togglebutton_arrow,'Value',1);%initializing of arrow togglebutton
set(handles.togglebutton_zoom,'Enable','on');
set(handles.togglebutton_pan,'Enable','on');


% --------------------------------------------------------------------
function DICOM_Header_Callback(hObject, eventdata, handles)

pathname = getappdata(handles.Load,'pathname');
DICOMViewer(pathname);

% --------------------------------------------------------------------
function Save_images_axial_Callback(hObject, eventdata, handles)
% hObject    handle to Save_images_axial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Save_images_sagittal_Callback(hObject, eventdata, handles)
% hObject    handle to Save_images_sagittal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Save_images_coronal_Callback(hObject, eventdata, handles)
% hObject    handle to Save_images_coronal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function set_zoomF_Callback(hObject, eventdata, handles)

global ZoomFCurrent ZoomFSeries;

%===========(Setup matrix size of output image)===========%
prompt = {'Zoom Factor of Current Image :','Zoom Factor of Montage Series Images  :'};
dlg_title = 'Output Image Parameters';
num_lines = 1;
def = {num2str(ZoomFCurrent),num2str(ZoomFSeries)};
input_ans = inputdlg(prompt,dlg_title,num_lines,def);

if isempty(input_ans);
   return
elseif str2num(input_ans{1})<1 || str2num(input_ans{2})<1;
    msgbox('The zoom factor should be positive for output images.','Message Box','warn');
    return
elseif str2num(input_ans{1})>20 || str2num(input_ans{2})>10;
    msgbox('The zoom factor is too large for output images.','Message Box','warn');
    return    
end
ZoomFCurrent = str2num(input_ans{1});
ZoomFSeries = str2num(input_ans{2});

% --------------------------------------------------------------------
function Exit_Callback(hObject, eventdata, handles)

Button=questdlg('Do you really want to close DTI_Search?','Message Box','Yes','No','No');
switch Button
    case 'Yes'
        delete(handles.figure1);
    case 'No'
        return
end

% --------------------------------------------------------------------
function Aligment_image_Callback(hObject, eventdata, handles)

auto_arrange;

% --------------------------------------------------------------------
function Rename_Callback(hObject, eventdata, handles)

global ROI_tagPos VDims Hidden_ROIText ;
global slider2_slice slider3_slice slider4_slice;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;

if ROI_tagPos > 0;% if listbox have ROI
Select = get(handles.listbox_roi,'Value');
ListString = getappdata(handles.Load,'ListString');

prompt = {'Rename the tag of ROI :'};% Rename ROI
dlg_title = 'Parameters';
num_lines = 1;
def = {ListString{Select}};
input_ans = inputdlg(prompt,dlg_title,num_lines,def);

    if isempty(input_ans);% if user press cancel
        return
    end
    if length(input_ans{1})==0;% if user key in empty name
        msgbox('Please input the tag of ROI.','Message Box','warn')
        return
    else
    ListString{Select} = input_ans{1};
    set(handles.listbox_roi,'string',ListString);
    setappdata(handles.Load,'ListString',ListString);   
    end
end

ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
%===========(ROI axes_axial)===========%
axes(handles.axes_axial);
IMa_now = getappdata(handles.Load,'IMa_now');
imagesc(IMa_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 1 && ROI_ALLposition{i}(2,3) == slider2_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_sagittal)===========%
axes(handles.axes_sagittal);
IMs_now = getappdata(handles.Load,'IMs_now');
imagesc(IMs_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
hold on;
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 2 && ROI_ALLposition{i}(2,3) == slider3_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_coronal)===========%
axes(handles.axes_coronal);
IMc_now = getappdata(handles.Load,'IMc_now');
imagesc(IMc_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 3 && ROI_ALLposition{i}(2,3) == slider4_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

assignin('base','ListString',ListString);

% --------------------------------------------------------------------
function Remove_Callback(hObject, eventdata, handles)

global ROI_tagPos Hidden_ROIText VDims MDims selection_index;
global slider2_slice slider3_slice slider4_slice;
global axial_h_m1 axial_h_m2 axial_v_m1 axial_v_m2;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;


if ROI_tagPos > 0;%ROI tag position decrease 1
    ROI_tagPos = ROI_tagPos-1;
end
Select = get(handles.listbox_roi,'Value');
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');

if size(ListString,2) > 1;
    Tempo_ListString{size(ListString,2)-1} = [];
    Tempo_ROI_ALLposition{size(ListString,2)-1} = [];
    Tempo_ROI_ALLTextPos{size(ListString,2)-1} = [];
    Tempo_ROI_ALLColor{size(ListString,2-1)} = [];
    Tempo_ROI_ALLSeed{size(ListString,2-1)} = [];
end

if Select == size(ListString,2);%if select the last ROI
    for i = 1:size(ListString,2)-1;
        Tempo_ListString(i) = ListString(i);  
        Tempo_ROI_ALLposition{i} = ROI_ALLposition{i};
        Tempo_ROI_ALLTextPos{i} = ROI_ALLTextPos{i};
        Tempo_ROI_ALLColor{i} = ROI_ALLColor{i};
        Tempo_ROI_ALLSeed{i} = ROI_ALLSeed{i};
    end   
else
    for i = 1:size(ListString,2);%if select the ROI
        if i>Select;%after selectpoint
            Tempo_ListString(i-1) = ListString(i);  
            Tempo_ROI_ALLposition{i-1} = ROI_ALLposition{i};
            Tempo_ROI_ALLTextPos{i-1} = ROI_ALLTextPos{i};
            Tempo_ROI_ALLColor{i-1} = ROI_ALLColor{i};
            Tempo_ROI_ALLSeed{i-1} = ROI_ALLSeed{i};
        else%before selectpoint
            Tempo_ListString(i) = ListString(i);
            Tempo_ROI_ALLposition{i} = ROI_ALLposition{i};
            Tempo_ROI_ALLTextPos{i} = ROI_ALLTextPos{i};
            Tempo_ROI_ALLColor{i} = ROI_ALLColor{i};
            Tempo_ROI_ALLSeed{i} = ROI_ALLSeed{i};
        end
    end
end
if size(ListString,2)>1;
    ListString = Tempo_ListString;
    ROI_ALLposition = Tempo_ROI_ALLposition;
    ROI_ALLTextPos = Tempo_ROI_ALLTextPos;
    ROI_ALLColor = Tempo_ROI_ALLColor;
    ROI_ALLSeed = Tempo_ROI_ALLSeed;
else
    ListString = {}; 
    ROI_ALLposition = {};
    ROI_ALLTextPos = {};
    ROI_ALLColor = {};
    ROI_ALLSeed = {};
    Index_Tract = [];
    
    setappdata(handles.Load,'Index_Tract',Index_Tract);
    set(handles.Rename,'Enable','off');%initialing of ROI options
    set(handles.Remove,'Enable','off');
    set(handles.Reset_color,'Enable','off');
    set(handles.Export_ROI,'Enable','off');
    
    IndexString = get(handles.popupmenu_index,'String');
    temp_IndexString{length(IndexString)-1} = [];
    for i = 1:length(IndexString)-1;
        temp_IndexString{i} = IndexString{i};
    end   
    set(handles.popupmenu_index,'String',temp_IndexString);
    if selection_index == 4;
        set(handles.popupmenu_index,'Value',1);
        selection_index = 1;% return to FA images
        IVa_now = getappdata(handles.Load,'FA');
        IVs_now = permute(IVa_now,[3 1 2]);
        for i = 1:MDims(2);
            IVs_now(:,:,i) = flipud(IVs_now(:,:,i));
        end
        IVc_now = permute(IVa_now,[3 2 1]);
        for i = 1:MDims(1);
            IVc_now(:,:,i) = flipud(IVc_now(:,:,i));
        end
        setappdata(handles.Load,'IVa_now',IVa_now);
        setappdata(handles.Load,'IMa_now',IVa_now(:,:,slider2_slice));
        setappdata(handles.Load,'IVs_now',IVs_now);
        setappdata(handles.Load,'IMs_now',IVs_now(:,:,slider3_slice));
        setappdata(handles.Load,'IVc_now',IVc_now);
        setappdata(handles.Load,'IMc_now',IVc_now(:,:,slider4_slice));
    end
    set(handles.togglebutton_non,'Value',1);
    set(handles.togglebutton_or,'Value',0);
    set(handles.togglebutton_and,'Value',0);
    set(handles.togglebutton_not,'Value',0);
end


%===========(ROI axes_axial)===========%
axes(handles.axes_axial);
IMa_now = getappdata(handles.Load,'IMa_now');
imagesc(IMa_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2) ~= 0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==1 && ROI_ALLposition{i}(2,3)==slider2_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_sagittal)===========%
axes(handles.axes_sagittal);
IMs_now = getappdata(handles.Load,'IMs_now');
imagesc(IMs_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
hold on;
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==2 && ROI_ALLposition{i}(2,3)==slider3_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_coronal)===========%
axes(handles.axes_coronal);
IMc_now = getappdata(handles.Load,'IMc_now');
imagesc(IMc_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==3 && ROI_ALLposition{i}(2,3)==slider4_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end


set(handles.listbox_roi,'string',ListString, 'Value', min(Select,size(ListString,2)));
setappdata(handles.Load,'ListString',ListString);
setappdata(handles.Load,'ROI_ALLposition',ROI_ALLposition);
setappdata(handles.Load,'ROI_ALLTextPos',ROI_ALLTextPos);
setappdata(handles.Load,'ROI_ALLColor',ROI_ALLColor);
setappdata(handles.Load,'ROI_ALLSeed',ROI_ALLSeed);
assignin('base','ListString',ListString);
assignin('base','ROI_ALLposition',ROI_ALLposition);
assignin('base','ROI_ALLTextPos',ROI_ALLTextPos);
assignin('base','ROI_ALLColor',ROI_ALLColor);
assignin('base','ROI_ALLSeed',ROI_ALLSeed);

% --------------------------------------------------------------------
function Hidden_Callback(hObject, eventdata, handles)

global VDims;
global slider2_slice slider3_slice slider4_slice ;
global axial_h_m1 axial_h_m2 axial_v_m1 axial_v_m2;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;
global Hidden_ROIText

if strcmp(get(hObject,'Checked'), 'on') == 1;% if check don't to hidden ROI text
    set(hObject,'Checked','off');
    Hidden_ROIText = 0;
else% hidden ROI text
    set(hObject,'Checked','on');
    Hidden_ROIText = 1;
end

ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
%===========(ROI axes_axial)===========%
axes(handles.axes_axial);
IMa_now = getappdata(handles.Load,'IMa_now');
imagesc(IMa_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==1 && ROI_ALLposition{i}(2,3)==slider2_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_sagittal)===========%
axes(handles.axes_sagittal);
IMs_now = getappdata(handles.Load,'IMs_now');
imagesc(IMs_now);axis off;axis equal;colormap gray
daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
hold on;
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==2 && ROI_ALLposition{i}(2,3)==slider3_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_coronal)===========%
axes(handles.axes_coronal);
IMc_now = getappdata(handles.Load,'IMc_now');
imagesc(IMc_now);axis off;axis equal;colormap gray
daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==3 && ROI_ALLposition{i}(2,3)==slider4_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

% --------------------------------------------------------------------
function ROI_context_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_context (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function axes_axial_CreateFcn(hObject, eventdata, handles)

global AxialPos
AxialPos = get(hObject,'Position');


% --- Executes during object creation, after setting all properties.
function axes_sagittal_CreateFcn(hObject, eventdata, handles)

global SagittalPos
SagittalPos = get(hObject,'Position');

% --- Executes during object creation, after setting all properties.
function axes_coronal_CreateFcn(hObject, eventdata, handles)

global CoronalPos
CoronalPos = get(hObject,'Position');


% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function Current_image_axial_pure_Callback(hObject, eventdata, handles)

global MDims ZoomFCurrent;

IMa_now = getappdata(handles.Load,'IMa_now');
IMa_now(isnan(IMa_now)) = 0;
IMa_now = mat2gray(IMa_now);% transformation grayscalar between 0 to 1
IMa_now = imresize(IMa_now,[MDims(1)*ZoomFCurrent MDims(2)*ZoomFCurrent]);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');
if isequal(filename,0);
   return
end
imwrite(IMa_now ,[pathname filename]);

% --------------------------------------------------------------------
function Series_images_axial_Callback(hObject, eventdata, handles)

global selection_index MDims ZoomFSeries;

%===========(Setup the slice of montage)===========%
prompt = {'Start of Slice Number :','End of Slice Number :'};% setting START % END slices
dlg_title = 'Output Parameters';
num_lines = 1;
def = {'1',num2str(MDims(3))};
input_ans = inputdlg(prompt,dlg_title,num_lines,def);

if isempty(input_ans);
    return
elseif str2num(input_ans{1})<1  || str2num(input_ans{2})<1 || str2num(input_ans{2})>MDims(3) || str2num(input_ans{1})>MDims(3);
    msgbox('Please input the correct ''START'' & ''END'' slice number.','Message Box','warn');
    return
elseif str2num(input_ans{1})>str2num(input_ans{2});
    msgbox('The ''END'' slice number must bigger than ''START'' slice number.','Message Box','warn');
    return
end
StartSlice = str2num(input_ans{1});
EndSlice = str2num(input_ans{2});
IVa_now = getappdata(handles.Load,'IVa_now');
IVa_now(isnan(IVa_now)) = 0;
if selection_index == 2 || selection_index == 4;% when series images are color images    
   IVa_now = reshape(IVa_now,MDims(1),MDims(2),3,[]);%reshape matrix formation 
else%when series images are gray-scale images
    IVa_now = reshape(IVa_now,MDims(1),MDims(2),1,[]);%reshape matrix formation
end
IVa_now = mat2gray(IVa_now);% transformation grayscalar between 0 to 1
MonImg = figure('Name',['Montage images (' num2str(StartSlice) '~' num2str(EndSlice) ') Slices' ],'NumberTitle','off');
montage(IVa_now, 'Indices', StartSlice:EndSlice);
if selection_index ~= 2 && selection_index ~= 4;
    ImCon = imcontrast;
end
pause;
currPicture = getframe(get(MonImg,'CurrentAxes'));
currPicture = imresize(currPicture.cdata,ZoomFSeries);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');
if isequal(filename,0);
   return
end
FileNameTag = ['(' num2str(StartSlice) '~' num2str(EndSlice) ' Slices)' filename];
imwrite(currPicture,[pathname FileNameTag]);
close(MonImg);     
if selection_index ~= 2 && selection_index ~= 4 && (ishandle(ImCon));
    delete(ImCon);
end

% --------------------------------------------------------------------
function Current_image_sagittal_pure_Callback(hObject, eventdata, handles)

global MDims VDims ZoomFCurrent;
IMs_now = getappdata(handles.Load,'IMs_now');
IMs_now(isnan(IMs_now)) = 0;
IMs_now = mat2gray(IMs_now);% transformation grayscalar between 0 to1
IMs_now = imresize(IMs_now,[MDims(3)*VDims(3)*ZoomFCurrent MDims(1)*VDims(1)*ZoomFCurrent]);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');
if isequal(filename,0);
   return
end
imwrite(IMs_now ,[pathname filename]);

% --------------------------------------------------------------------
function Current_image_sagittal_unpure_Callback(hObject, eventdata, handles)

global MDims VDims ZoomFCurrent;

currPicture = getframe(handles.axes_sagittal);
currPicture = imresize(currPicture.cdata,[MDims(3)*VDims(3)*ZoomFCurrent MDims(1)*VDims(1)*ZoomFCurrent]);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');
if isequal(filename,0);
   return
end
imwrite(currPicture,[pathname filename]);

% --------------------------------------------------------------------
function Series_images_sagittal_Callback(hObject, eventdata, handles)

global selection_index MDims VDims ZoomFSeries;

%===========(Setup the slice of montage)===========%
prompt = {'Start of Sagittal Slice Number :','End of Sagittal Slice Number :'};%setting START % END slices
dlg_title = 'Output Parameters';
num_lines = 1;
def = {'1',num2str(MDims(2))};
input_ans = inputdlg(prompt,dlg_title,num_lines,def);

if isempty(input_ans) 
    return
elseif str2num(input_ans{1})<1  || str2num(input_ans{2})<1 || str2num(input_ans{2})>MDims(2) || str2num(input_ans{1})>MDims(2);
    msgbox('Please input the correct ''START'' & ''END'' slice number.','Message Box','warn');
    return
elseif str2num(input_ans{1})>str2num(input_ans{2});
    msgbox('The ''END'' slice number must bigger than ''START'' slice number.','Message Box','warn');
    return
end
StartSlice = str2num(input_ans{1});
EndSlice = str2num(input_ans{2});
IVs_now = getappdata(handles.Load,'IVs_now');
IVs_now(isnan(IVs_now)) = 0;
if selection_index == 2 || selection_index == 4;% when series images are color images
%    CurrImg=reshape(CurrImg,size(CurrImg,1),size(CurrImg,2),3,[]);%reshape matrix formation   
else% when series images are gray-scale images
    IVs_now = reshape(IVs_now,MDims(3),MDims(1),1,[]);% reshape matrix formation
end
IVs_now = mat2gray(IVs_now);% transformation grayscalar between 0 to 1
MonImg = figure('Name',['Montage images (' num2str(StartSlice) '~' num2str(EndSlice) ') Slices' ],'NumberTitle','off');

Temp_MonSize = sqrt((abs(EndSlice-StartSlice)+1)/((VDims(1)*MDims(1))/(MDims(3)*VDims(3))));%reshape montage image matrix size
MonSizeHeight = floor(Temp_MonSize*((VDims(1)*MDims(1))/(MDims(3)*VDims(3))))-1;
MonSizeWidth = ceil(Temp_MonSize);
if MonSizeHeight*MonSizeWidth <= abs(EndSlice-StartSlice)+1;
    MonSizeWidth = MonSizeWidth+1;
end
if (MonSizeHeight-2)*MonSizeWidth >= abs(EndSlice-StartSlice)+1;
    MonSizeHeight = MonSizeHeight-2;
elseif (MonSizeHeight-1)*MonSizeWidth >= abs(EndSlice-StartSlice)+1;
    MonSizeHeight = MonSizeHeight-1;
end

montage(IVs_now, 'Indices', StartSlice:EndSlice, 'Size', [MonSizeHeight MonSizeWidth]);
daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
if selection_index ~= 2 && selection_index ~= 4;
    ImCon = imcontrast;
end
pause;
currPicture = getframe(get(MonImg,'CurrentAxes'));
currPicture = imresize(currPicture.cdata,ZoomFSeries);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');
if isequal(filename,0);
   return
end
FileNameTag=['(' num2str(StartSlice) '~' num2str(EndSlice) ' Slices)' filename];
imwrite(currPicture,[pathname FileNameTag]);
close(MonImg);     
if selection_index ~= 2 && selection_index ~= 4 && (ishandle(ImCon));
    delete(ImCon);
end

% --------------------------------------------------------------------
function Current_image_coronal_pure_Callback(hObject, eventdata, handles)

global MDims VDims ZoomFCurrent;
IMc_now = getappdata(handles.Load,'IMc_now');
IMc_now(isnan(IMc_now)) = 0;
IMc_now = mat2gray(IMc_now);% transformation grayscalar between 0 to1
IMc_now = imresize(IMc_now,[MDims(3)*VDims(3)*ZoomFCurrent MDims(2)*VDims(2)*ZoomFCurrent]);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');
if isequal(filename,0);
   return
end
imwrite(IMc_now,[pathname filename]);

% --------------------------------------------------------------------
function Current_image_coronal_unpure_Callback(hObject, eventdata, handles)

global MDims VDims ZoomFCurrent;
currPicture = getframe(handles.axes_coronal);
currPicture = imresize(currPicture.cdata,[MDims(3)*VDims(3)*ZoomFCurrent MDims(2)*VDims(2)*ZoomFCurrent]);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');

if isequal(filename,0);
   return
end
imwrite(currPicture,[pathname filename]);

% --------------------------------------------------------------------
function Series_images_coronal_Callback(hObject, eventdata, handles)

global selection_index MDims VDims ZoomFSeries;

%===========(Setup the slice of montage)===========%
prompt = {'Start of Coronal Slice Number :','End of Coronal Slice Number :'};%setting START % END slices
dlg_title = 'Output Parameters';
num_lines = 1;
def = {'1',num2str(MDims(1))};
input_ans = inputdlg(prompt,dlg_title,num_lines,def);

if isempty(input_ans) 
    return
elseif str2num(input_ans{1})<1  || str2num(input_ans{2})<1 || str2num(input_ans{2})>MDims(1) || str2num(input_ans{1})>MDims(1);
    msgbox('Please input the correct ''START'' & ''END'' slice number.','Message Box','warn');
    return
elseif str2num(input_ans{1})>str2num(input_ans{2});
    msgbox('The ''END'' slice number must bigger than ''START'' slice number.','Message Box','warn');
    return    
end
StartSlice = str2num(input_ans{1});
EndSlice = str2num(input_ans{2});
IVc_now = getappdata(handles.Load,'IVc_now');
IVc_now(isnan(IVc_now)) = 0;
if selection_index == 2 || selection_index == 4;%when series images are color images
%    CurrImg=reshape(CurrImg,size(CurrImg,1),size(CurrImg,2),3,[]);%reshape matrix formation 
   
else% when series images are gray-scale images
    IVc_now = reshape(IVc_now,MDims(3),MDims(2),1,[]);% reshape matrix formation
end
IVc_now = mat2gray(IVc_now);% transformation grayscalar between 0 to 1
MonImg = figure('Name',['Montage images (' num2str(StartSlice) '~' num2str(EndSlice) ') Slices' ],'NumberTitle','off');

Temp_MonSize = sqrt((abs(EndSlice-StartSlice)+1)/((VDims(2)*MDims(2))/(MDims(3)*VDims(3))));%reshape montage image matrix size
MonSizeHeight = floor(Temp_MonSize*((VDims(2)*MDims(2))/(MDims(3)*VDims(3))))-1;
MonSizeWidth = ceil(Temp_MonSize);
if MonSizeHeight*MonSizeWidth <= abs(EndSlice-StartSlice)+1;
    MonSizeWidth = MonSizeWidth+1;
end
if (MonSizeHeight-2)*MonSizeWidth >= abs(EndSlice-StartSlice)+1;
    MonSizeHeight = MonSizeHeight-2;
elseif (MonSizeHeight-1)*MonSizeWidth >= abs(EndSlice-StartSlice)+1;
    MonSizeHeight = MonSizeHeight-1;
end
montage(IVc_now, 'Indices', StartSlice:EndSlice, 'Size', [MonSizeHeight MonSizeWidth]);
daspect([VDims(3) VDims(2) 1]);% consider image thickness to chang voxel size
if selection_index ~= 2 && selection_index ~= 4;
ImCon = imcontrast;
end
pause;
currPicture = getframe(get(MonImg,'CurrentAxes'));
currPicture = imresize(currPicture.cdata,ZoomFSeries);
[filename, pathname] = uiputfile({ '*.png','Portable Network Graphics images (*.png)';...
    '*.bmp','Bitmap images (*.bmp)';...
    '*.jpg','JPEG images (*.jpg)'},'Please input file name');
if isequal(filename,0);
   return
end
FileNameTag=['(' num2str(StartSlice) '~' num2str(EndSlice) ' Slices)' filename];
imwrite(currPicture,[pathname FileNameTag]);
close(MonImg);     
if selection_index ~= 2 && selection_index ~= 4 && (ishandle(ImCon));
    delete(ImCon);
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)

Button = questdlg('Do you really want to close DTI_Search?','Message Box','Yes','No','No');
switch Button
    case 'Yes'
        delete(handles.figure1);
    case 'No'
        return
end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)

global selection_index ndir;
global axial_ready sagittal_ready coronal_ready;
global slider2_slice slider2_series slider3_slice slider3_series slider4_slice slider4_series;
global VDims MDims;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;
global axial_h_m1 axial_h_m2 axial_v_m1 axial_v_m2;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;
global axial_on sagittal_on coronal_on;
global AxialPos SagittalPos CoronalPos ROI_ready Hidden_ROIText;


p = get(gcf,'currentpoint');
if p(1)>=AxialPos(1) && p(1)<=AxialPos(1)+AxialPos(3) && p(2)>=AxialPos(2) && p(2)<=AxialPos(2)+AxialPos(4) && axial_ready == 1;
%===========(axes_axial Check mouse right key)===========%   
mouse_select=get(gcf,'SelectionType');
switch mouse_select
    case 'alt'
%         set(gcf,'UIContextMenu',ROI_context_Callback)
%         disp('ok####')
    case 'normal'
%===========(setting current window to axes_axial)===========%  
axial_on = 1;sagittal_on = 0;coronal_on = 0;
set(handles.radiobutton_axial,'value',1);
set(handles.radiobutton_sagittal,'value',0);
set(handles.radiobutton_coronal,'value',0);
position = get(handles.axes_axial,'currentpoint');% getting image coordinate
position = ceil(position-0.5);% correction image coordinate
%===========(if mouse on linemarker,change sagittal slice)===========%
if position(1,1) == xdata_axial_h(1);
    axes(handles.axes_axial);
    set(axial_h_m1,'visible','off');set(axial_h_m2,'visible','off');
    line_position = slice_marker_horizontal(gcf,[0 0 1]);% control sagittal slice
    line_position = round(line_position);
    line_position(line_position == 0) = 1;% correction image border
    line_position(line_position == (MDims(2)+1)) = MDims(2);% correction image border
    xdata_axial_h = [line_position(1) line_position(1)];
    hold on;
    axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
    axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
    hold off;
    %===========(synchronal sagittal slice linemarker of coronal)===========%
    axes(handles.axes_coronal);
    set(coronal_h_m1,'visible','off');set(coronal_h_m2,'visible','off');
    xdata_coronal_h = [line_position(1) line_position(1)];
    hold on;
    coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
    coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
    hold off;
    %===========(change sagittal slice)===========%
    axes(handles.axes_sagittal);
    slider3_slice = line_position(1);
    set(handles.slider_sagittal,'value',slider3_slice);% setting sliderslice_sagittalvalue

    if selection_index == 2 ||selection_index == 4;
            IVs_now = getappdata(handles.Load,'IVs_now');
            imagesc(IVs_now(:,:,:,slider3_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
            set(handles.text_sagittalslice,'string', num2str(slider3_slice));
            setappdata(handles.Load,'IMs_now',IVs_now(:,:,:,slider3_slice));  
    else
            IVs_now = getappdata(handles.Load,'IVs_now');
            imagesc(IVs_now(:,:,slider3_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
            set(handles.text_sagittalslice,'string', num2str(slider3_slice));
            setappdata(handles.Load,'IMs_now',IVs_now(:,:,slider3_slice));  
    end
    hold on;
    %===========(setting the default of vertical motion line marker)===========%
    sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
    sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
    %===========(setting the default of horizontal motion line marker)===========%
    sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
    sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
    %===========(ROI axes_sagittal)===========%
    if ROI_ready == 1;%if ROI is input
    ListString = getappdata(handles.Load,'ListString');
    ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
    ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
    ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
    if size(ROI_ALLposition,2) ~= 0;
        for i = 1:size(ROI_ALLposition,2);
            if ROI_ALLposition{i}(1,3) == 2  && ROI_ALLposition{i}(2,3) == slider3_slice;
                line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
                if Hidden_ROIText == 0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
                end
            end
        end
    end
    end
    hold off;



    %===========(if mouse on linemarker,change coronal slice)===========%
    elseif position(1,2) == ydata_axial_v;
    axes(handles.axes_axial);
    set(axial_v_m1,'visible','off');set(axial_v_m2,'visible','off');
    line_position = slice_marker_vertical(gcf,[0 1 0]);% control coronal slice
    line_position = round(line_position);
    line_position(line_position==0) = 1;
    line_position(line_position==(MDims(1)+1)) = MDims(1);
    ydata_axial_v = [line_position(2) line_position(2)];
    hold on;
    axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
    axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
    hold off;
    %===========(synchronal coronal slice linemarker of sagittal)===========%
    axes(handles.axes_sagittal);
    set(sagittal_h_m1,'visible','off');set(sagittal_h_m2,'visible','off');
    xdata_sagittal_h = [line_position(2) line_position(2)];
    hold on;
    sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
    sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
    hold off;
    %===========(change coronal slice)===========%
    axes(handles.axes_coronal);
    slider4_slice = line_position(2);
    set(handles.slider_coronal,'value',slider4_slice);
    if selection_index == 2 ||selection_index == 4;
            IVc_now = getappdata(handles.Load,'IVc_now');
            imagesc(IVc_now(:,:,:,slider4_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_coronalslice,'string', num2str(slider4_slice));
            setappdata(handles.Load,'IMc_now',IVc_now(:,:,:,slider4_slice));  
    else
            IVc_now = getappdata(handles.Load,'IVc_now');
            imagesc(IVc_now(:,:,slider4_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_coronalslice,'string', num2str(slider4_slice));
            setappdata(handles.Load,'IMc_now',IVc_now(:,:,slider4_slice));  
    end

    hold on;
    %===========(setting the default of vertical motion line marker)===========%
    coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
    coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
    setappdata(handles.Load,'coronal_v_m1',coronal_v_m1);setappdata(handles.Load,'coronal_v_m2',coronal_v_m2);
    %===========(setting the default of horizontal motion line marker)===========%
    coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
    coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
    setappdata(handles.Load,'coronal_h_m1',coronal_h_m1);setappdata(handles.Load,'coronal_h_m2',coronal_h_m2);
    %===========(ROI axes_coronal)===========%
    if ROI_ready==1;%if ROI is input
    ListString=getappdata(handles.Load,'ListString');
    ROI_ALLposition=getappdata(handles.Load,'ROI_ALLposition');
    ROI_ALLTextPos=getappdata(handles.Load,'ROI_ALLTextPos');
    ROI_ALLColor=getappdata(handles.Load,'ROI_ALLColor');
    if size(ROI_ALLposition,2) ~= 0;
        for i = 1:size(ROI_ALLposition,2);
            if ROI_ALLposition{i}(1,3) == 3 && ROI_ALLposition{i}(2,3) == slider4_slice;
                line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
                if Hidden_ROIText == 0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
                end
            end
        end
    end
    end
    hold off;

end
end
    
elseif p(1)>=SagittalPos(1) && p(1)<=SagittalPos(1)+SagittalPos(3) && p(2)>=SagittalPos(2) && p(2)<=SagittalPos(2)+SagittalPos(4) && sagittal_ready == 1;
%===========(axes_sagittal Check mouse right key)===========%   
mouse_select=get(gcf,'SelectionType');
switch mouse_select
    case 'alt'
%         set(gcf,'UIContextMenu',ROI_context_Callback)
%         disp('ok####')
    case 'normal'
%===========(setting current window to axes_sagittal)===========%  
axial_on = 0;sagittal_on = 1;coronal_on = 0;
set(handles.radiobutton_axial,'value',0);
set(handles.radiobutton_sagittal,'value',1);
set(handles.radiobutton_coronal,'value',0);   
position = get(handles.axes_sagittal,'currentpoint');% getting image coordinate
position = ceil(position-0.5);% correction image coordinat
%===========(if mouse on linemarker,change coronal slice)===========%
if position(1,1) == xdata_sagittal_h;
axes(handles.axes_sagittal);
set(sagittal_h_m1,'visible','off');set(sagittal_h_m2,'visible','off');
line_position = slice_marker_horizontal(gcf,[0 1 0]);
line_position = round(line_position);
line_position(line_position==0) = 1;
line_position(line_position==(MDims(1)+1)) = MDims(1);
xdata_sagittal_h = [line_position(1) line_position(1)];
hold on;
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
hold off;
%===========(synchronal sagittal slice linemarker of axial)===========%
axes(handles.axes_axial);
set(axial_v_m1,'visible','off');set(axial_v_m2,'visible','off');
ydata_axial_v = [line_position(1) line_position(1)];
hold on;
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
hold off;
%===========(change axes_coronal slice)===========%
axes(handles.axes_coronal);
slider4_slice = line_position(1);
set(handles.slider_coronal,'value',slider4_slice);
    if selection_index == 2 ||selection_index == 4;
            IVc_now = getappdata(handles.Load,'IVc_now');
            imagesc(IVc_now(:,:,:,slider4_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_coronalslice,'string', num2str(slider4_slice));
            setappdata(handles.Load,'IMc_now',IVc_now(:,:,:,slider4_slice));  
    else
            IVc_now = getappdata(handles.Load,'IVc_now');
            imagesc(IVc_now(:,:,slider4_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_coronalslice,'string', num2str(slider4_slice));
            setappdata(handles.Load,'IMc_now',IVc_now(:,:,slider4_slice));  
    end
hold on;
%===========(setting the default of vertical motion line marker)===========%
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'coronal_v_m1',coronal_v_m1);setappdata(handles.Load,'coronal_v_m2',coronal_v_m2);
%===========(setting the default of horizontal motion line marker)===========%
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'coronal_h_m1',coronal_h_m1);setappdata(handles.Load,'coronal_h_m2',coronal_h_m2);
%===========(ROI axes_coronal)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
if size(ROI_ALLposition,2)~=0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 3 && ROI_ALLposition{i}(2,3) == slider4_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText == 0;
            text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
        end
    end
end
end
hold off;



%===========(if mouse on linemarker,change axial slice)===========%
elseif position(1,2) == ydata_sagittal_v;
axes(handles.axes_sagittal);
set(sagittal_v_m1,'visible','off');set(sagittal_v_m2,'visible','off');
line_position = slice_marker_vertical(gcf,[1 0 0]);
line_position = round(line_position);
line_position(line_position==0) = 1;
line_position(line_position==(MDims(3)+1)) = MDims(3);
ydata_sagittal_v = [line_position(2) line_position(2)];
hold on;
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
hold off;
%===========(synchronal axial slice linemarker of coronal)===========%
axes(handles.axes_coronal);
set(coronal_v_m1,'visible','off');set(coronal_v_m2,'visible','off');
ydata_coronal_v = [line_position(2) line_position(2)];
hold on;
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
hold off;
%===========(change axial slice)===========%
axes(handles.axes_axial);
slider2_slice = (MDims(3)-line_position(2)+1);
set(handles.slider_axial,'value',slider2_slice);
    if selection_index == 2 ||selection_index == 4;
            IVa_now = getappdata(handles.Load,'IVa_now');
            imagesc(IVa_now(:,:,:,slider2_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(1)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_axialslice,'string', num2str(slider2_slice));
            setappdata(handles.Load,'IMa_now',IVa_now(:,:,:,slider2_slice));  
    else
            IVa_now = getappdata(handles.Load,'IVa_now');
            imagesc(IVa_now(:,:,slider2_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(1)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_axialslice,'string', num2str(slider2_slice));
            setappdata(handles.Load,'IMa_now',IVa_now(:,:,slider2_slice));  
    end
hold on;
%===========(setting the default of vertical motion line marker)===========%
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'axial_v_m1',axial_v_m1);setappdata(handles.Load,'axial_v_m2',axial_v_m2);
%===========(setting the default of horizontal motion line marker)===========%
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'axial_h_m1',axial_h_m1);setappdata(handles.Load,'axial_h_m2',axial_h_m2);
%===========(ROI axes_axial)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
if size(ROI_ALLposition,2)~=0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 1 && ROI_ALLposition{i}(2,3) == slider2_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText == 0;
            text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
        end
    end
end
end
hold off;


end
end

    
elseif p(1)>=CoronalPos(1) && p(1)<=CoronalPos(1)+CoronalPos(3) && p(2)>=CoronalPos(2) && p(2)<=CoronalPos(2)+CoronalPos(4) && coronal_ready == 1;
%===========(axes_coronal Check mouse right key)===========%   
mouse_select = get(gcf,'SelectionType');
switch mouse_select
    case 'alt'
%         set(gcf,'UIContextMenu',ROI_context_Callback)
%         disp('ok####')
    case 'normal'
%===========(setting current window to axes_coronal)===========%  
axial_on = 0;sagittal_on = 0;coronal_on = 1;
set(handles.radiobutton_axial,'value',0);
set(handles.radiobutton_sagittal,'value',0);
set(handles.radiobutton_coronal,'value',1);   
position = get(handles.axes_coronal,'currentpoint');
position = ceil(position-0.5);  
%===========(if mouse on linemarker,change axial slice)===========%
if position(1,2) == ydata_coronal_v;
axes(handles.axes_coronal);
set(coronal_v_m1,'visible','off');set(coronal_v_m2,'visible','off');
line_position = slice_marker_vertical(gcf,[1 0 0]);
line_position = round(line_position);
line_position(line_position==0) = 1;
line_position(line_position==(MDims(3)+1)) = MDims(3);
ydata_coronal_v = [line_position(2) line_position(2)];
hold on;
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
hold off;     
%===========(synchronal axial slice linemarker of coronal)===========%
axes(handles.axes_sagittal);
set(sagittal_v_m1,'visible','off');set(sagittal_v_m2,'visible','off');
ydata_sagittal_v = [line_position(2) line_position(2)];
hold on;
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
hold off;
%===========(change axial slice)===========%
axes(handles.axes_axial);
slider2_slice = (MDims(3)-line_position(2)+1);
set(handles.slider_axial,'value',slider2_slice);
    if selection_index == 2 ||selection_index == 4;
            IVa_now = getappdata(handles.Load,'IVa_now');
            imagesc(IVa_now(:,:,:,slider2_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(1)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_axialslice,'string', num2str(slider2_slice));
            setappdata(handles.Load,'IMa_now',IVa_now(:,:,:,slider2_slice));  
    else
            IVa_now = getappdata(handles.Load,'IVa_now');
            imagesc(IVa_now(:,:,slider2_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(1)  VDims(2) 1]);% consider image thickness to chang voxel size
            set(handles.text_axialslice,'string', num2str(slider2_slice));
            setappdata(handles.Load,'IMa_now',IVa_now(:,:,slider2_slice));  
    end
hold on;
%===========(setting the default of vertical motion line marker)===========%
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'axial_v_m1',axial_v_m1);setappdata(handles.Load,'axial_v_m2',axial_v_m2);
%===========(setting the default of horizontal motion line marker)===========%
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
setappdata(handles.Load,'axial_h_m1',axial_h_m1);setappdata(handles.Load,'axial_h_m2',axial_h_m2);
%===========(ROI axes_axial)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
if size(ROI_ALLposition,2) ~= 0;
    for i = 1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 1 && ROI_ALLposition{i}(2,3) == slider2_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText == 0;
            text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
        end
    end
end
end
hold off;


%===========(if mouse on linemarker,change sagittal slice)===========%
elseif position(1,1) == xdata_coronal_h(1);
axes(handles.axes_coronal);
set(coronal_h_m1,'visible','off');set(coronal_h_m2,'visible','off');
line_position = slice_marker_horizontal(gcf,[0 0 1]);
line_position = round(line_position);
line_position(line_position==0) = 1;
line_position(line_position==(MDims(2)+1)) = MDims(2);
xdata_coronal_h = [line_position(1) line_position(1)];
hold on;
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
hold off;    
%===========(synchronal sagittal slice linemarker of axial)===========%
axes(handles.axes_axial);
set(axial_h_m1,'visible','off');set(axial_h_m2,'visible','off');
xdata_axial_h = [line_position(1) line_position(1)];
hold on;
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
hold off;
%===========(change sagittal slice)===========%
axes(handles.axes_sagittal);
slider3_slice = line_position(1);
set(handles.slider_sagittal,'value',slider3_slice);
    if selection_index == 2 ||selection_index == 4;
            IVs_now = getappdata(handles.Load,'IVs_now');
            imagesc(IVs_now(:,:,:,slider3_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
            set(handles.text_sagittalslice,'string', num2str(slider3_slice));
            setappdata(handles.Load,'IMs_now',IVs_now(:,:,:,slider3_slice));  
    else
            IVs_now = getappdata(handles.Load,'IVs_now');
            imagesc(IVs_now(:,:,slider3_slice));axis off;axis equal;colormap gray
            axis image;
            daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
            set(handles.text_sagittalslice,'string', num2str(slider3_slice));
            setappdata(handles.Load,'IMs_now',IVs_now(:,:,slider3_slice));  
    end
hold on;
%===========(setting the default of vertical motion line marker)===========%
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
%===========(setting the default of horizontal motion line marker)===========%
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
%===========(ROI axes_sagittal)===========%
if ROI_ready == 1;%if ROI is input
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
if size(ROI_ALLposition,2) ~= 0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3) == 2 && ROI_ALLposition{i}(2,3) == slider3_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText == 0;
            text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
        end
    end
end
end
hold off;
end
end 
else  
set(gcf,'Pointer','arrow');
set(handles.text_value,'string',[]);
end    


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)

global arrow_ok selection_index MDims;
global slider2_slice slider3_slice slider4_slice;
global axial_ready sagittal_ready coronal_ready;
global ydata_axial_v xdata_axial_h;
global ydata_sagittal_v xdata_sagittal_h;
global ydata_coronal_v xdata_coronal_h;
global AxialPos SagittalPos CoronalPos;

%===========(using currentpoint to decide current window)===========%
p = get(gcf,'currentpoint');
if p(1)>=AxialPos(1) && p(1)<=AxialPos(1)+AxialPos(3) && p(2)>=AxialPos(2) && p(2)<=AxialPos(2)+AxialPos(4) && axial_ready == 1;
    IMa_now = getappdata(handles.Load,'IMa_now');% loading current image of axial-axes
    position = get(handles.axes_axial,'currentpoint');% getting current point position 
    position = ceil(position-0.5);% correction currentpoint coordinate error
    if position(1,2)>=1 && position(1,2)<=MDims(1) && position(1,1)>=1 && position(1,1)<=MDims(2) && arrow_ok == 1;% confirm cursor is in image area
            set(gcf,'Pointer','arrow');% change cursor to arrow 
        if selection_index == 1 | selection_index == 4;% FA(gray scale) images
            current_signal = IMa_now(position(1,2),position(1,1));% X,Y of image currentpoint are inverse to  X,Y of matrix
            set(handles.text_value,'string',[ '(' num2str(position(1,2)) ',' num2str(position(1,1)) ',' num2str(slider2_slice) ') = ' num2str(current_signal(1),'%2.3f')]);
        elseif selection_index == 2;% RGB images
            current_signal = IMa_now(position(1,2),position(1,1),:);% X,Y of image currentpoint are inverse to  X,Y of matrix, COLOR_RGB is diffrernt to gray scale   
            set(handles.text_value,'string',[ '(' num2str(position(1,2)) ',' num2str(position(1,1)) ',' num2str(slider2_slice) ') = ' num2str(current_signal(1),'%1.3f') ', ' num2str(current_signal(2),'%1.3f') ', ' num2str(current_signal(3),'%1.3f')])    
        else % B0 images
            current_signal = IMa_now(position(1,2),position(1,1));% X,Y of image currentpoint are inverse to  X,Y of matrix 
            set(handles.text_value,'string',[ '(' num2str(position(1,2)) ',' num2str(position(1,1)) ',' num2str(slider2_slice) ') = ' num2str(current_signal)]);  
        end

        if position(1,1) == xdata_axial_h(1);% if mouse on linemarker, change to L-R arrow
            double_arrow(1)
        elseif position(1,2) == ydata_axial_v(1);% if mouse on linemarker, change to U-D arrow
            double_arrow(0)  
        end

    end    
    
elseif p(1)>=SagittalPos(1) && p(1)<=SagittalPos(1)+SagittalPos(3) && p(2)>=SagittalPos(2) && p(2)<=SagittalPos(2)+SagittalPos(4) && sagittal_ready == 1;
        IMs_now = getappdata(handles.Load,'IMs_now');% loading current image of sagittal-axes
        position = get(handles.axes_sagittal,'currentpoint');% getting current point position 
        position = ceil(position-0.5);% correction currentpoint coordinate error
    if position(1,2)>=1 && position(1,2)<=MDims(3) && position(1,1)>=1 && position(1,1)<=MDims(1) && arrow_ok == 1;% confirm cursor is in image area
        set(gcf,'Pointer','arrow');% change cursor to arrow
        if selection_index == 1 ||selection_index == 4;% FA(gray scale) images
            current_signal = IMs_now(position(1,2),position(1,1));% X,Y of image currentpoint are inverse to  X,Y of matrix    
            set(handles.text_value,'string',[ '(' num2str(position(1,2)) ',' num2str(slider3_slice) ',' num2str(position(1,1)) ') = ' num2str(current_signal(1),'%2.3f')]); 
        elseif selection_index == 2;% RGB images
            current_signal = IMs_now(position(1,2),position(1,1),:);% X,Y of image currentpoint are inverse to  X,Y of matrix, COLOR_RGB is diffrernt to gray scale    
            set(handles.text_value,'string',[ '(' num2str(position(1,2)) ',' num2str(slider3_slice) ',' num2str(position(1,1)) ') = ' num2str(current_signal(1),'%1.3f') ', ' num2str(current_signal(2),'%1.3f') ', ' num2str(current_signal(3),'%1.3f')])    
        else % B0 images
            current_signal = IMs_now(position(1,2),position(1,1));% X,Y of image currentpoint are inverse to  X,Y of matrix    
            set(handles.text_value,'string',[ '(' num2str(position(1,2)) ',' num2str(slider3_slice) ',' num2str(position(1,1)) ') = ' num2str(current_signal)]);  
        end

        if position(1,1) == xdata_sagittal_h(1);% if mouse on linemarker, change to L-R arrow
            double_arrow(1)
        elseif position(1,2) == ydata_sagittal_v(1);% if mouse on linemarker, change to U-D arrow
            double_arrow(0)  
        end

    end    
    
    elseif p(1)>=CoronalPos(1) && p(1)<=CoronalPos(1)+CoronalPos(3) && p(2)>=CoronalPos(2) && p(2)<=CoronalPos(2)+CoronalPos(4) && coronal_ready == 1;
        IMc_now = getappdata(handles.Load,'IMc_now');% loading current image of coronal-axes
        position = get(handles.axes_coronal,'currentpoint');% getting current point position
        position = ceil(position-0.5);% correction currentpoint coordinate error
    if position(1,2)>=1 && position(1,2)<=MDims(3) && position(1,1)>=1 && position(1,1)<=MDims(2) && arrow_ok == 1;% confirm cursor is in image area
        set(gcf,'Pointer','arrow');% change cursor to arrow 
        if selection_index == 1 ||selection_index == 4;% FA(gray scale) images      
            current_signal = IMc_now(position(1,2),position(1,1));% X,Y of image currentpoint are inverse to  X,Y of matrix    
            set(handles.text_value,'string',[ '(' num2str(slider4_slice) ',' num2str(position(1,2)) ',' num2str(position(1,1)) ') = ' num2str(current_signal(1),'%2.3f')]); 
        elseif selection_index == 2;% RGB images
            current_signal = IMc_now(position(1,2),position(1,1),:);% X,Y of image currentpoint are inverse to  X,Y of matrix, COLOR_RGB is diffrernt to gray scale    
            set(handles.text_value,'string',[ '(' num2str(slider4_slice) ',' num2str(position(1,2)) ',' num2str(position(1,1)) ') = ' num2str(current_signal(1),'%1.3f') ', ' num2str(current_signal(2),'%1.3f') ', ' num2str(current_signal(3),'%1.3f')])    
        else % B0 images
            current_signal = IMc_now(position(1,2),position(1,1));% X,Y of image currentpoint are inverse to  X,Y of matrix   
            set(handles.text_value,'string',[ '(' num2str(slider4_slice) ',' num2str(position(1,2)) ',' num2str(position(1,1)) ') = ' num2str(current_signal)]);    
        end

        if position(1,1) == xdata_coronal_h(1);% if mouse on linemarker, change to L-R arrow
            double_arrow(1)
        elseif position(1,2) == ydata_coronal_v(1);% if mouse on linemarker, change to U-D arrow
            double_arrow(0)  
        end

    end    
    
else  
    set(gcf,'Pointer','arrow');% if cursoris outside of image, change cursor to arrow
    set(handles.text_value,'string',[]);
end


% --------------------------------------------------------------------
function Import_ROI_Callback(hObject, eventdata, handles)

global ROI_tagPos color Hidden_ROIText ROI_ready;
global slider2_slice slider3_slice slider4_slice;
global MDims;

[filename, pathname] = uigetfile( ...
    {'*.mat','ROI data (.mat)'}, ...
   'Please Select ROI Data File');
if isequal(filename,0);
   return
end
load([pathname filename]);

ROI_tagPos = ROI_tagPos+1;% ROI tag position increase 1

ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');

ROI_ALLposition{ROI_tagPos} = ROI_position;
filename_ASCII = double(filename);% double>character, char>character string 
ROI_name = char(filename_ASCII(1:(length(double(filename))-4)));% delete parafilename

%===========(loading ROI data)===========%
if ROI_position(1,3) == 1;% axial
    ListString{ROI_tagPos} = [ROI_name '(Axial,' num2str(ROI_position(2,3)) ')'];
    ROI_TextPos(1) = (max(ROI_position(:,1))-min(ROI_position(:,1)))/2+min(ROI_position(:,1));
    ROI_TextPos(2) = (max(ROI_position(:,2))-min(ROI_position(:,2)))/2+min(ROI_position(:,2));
    
%     [X, Y] = meshgrid(1:MDims(1), 1:MDims(2));% Create seed points @ 12/10/10
%     BW_ROI = inpolygon(X,Y,ROI_position(:,1),ROI_position(:,2));
%     [Seed(:,1),Seed(:,2)] = find(BW_ROI);
%     Seed(:,3) = slider2_slice;
    
    if ROI_position(2,3) == slider2_slice;% if ROI is in current image slice
        axes(handles.axes_axial);
        hold on;
        line(ROI_position(:,1),ROI_position(:,2),'color',color,'LineWidth',1);
            if Hidden_ROIText == 0;
                text(ROI_TextPos(1),ROI_TextPos(2),ListString(ROI_tagPos),'HorizontalAlignment','center','Color',color,'FontSize',8);
            end
        hold off;
    end

elseif ROI_position(1,3) == 2;% sagittal
    ListString{ROI_tagPos} = [ROI_name '(Sagittal,' num2str(ROI_position(2,3)) ')'];
    ROI_TextPos(1) = (max(ROI_position(:,1))-min(ROI_position(:,1)))/2+min(ROI_position(:,1));
    ROI_TextPos(2) = (max(ROI_position(:,2))-min(ROI_position(:,2)))/2+min(ROI_position(:,2));
    
%     [X, Y] = meshgrid(1:MDims(3), 1:MDims(1));% Create seed points @ 12/10/10
%     BW_ROI = inpolygon(X,Y,ROI_position(:,2),ROI_position(:,1));
%     [Seed(:,1),Seed(:,3)] = find(BW_ROI);
%     Seed(:,2) = slider3_slice;  
    
    if ROI_position(2,3) == slider3_slice;% if ROI is in current image slice
        axes(handles.axes_sagittal);
        hold on;
        line(ROI_position(:,1),ROI_position(:,2),'color',color,'LineWidth',1);
            if Hidden_ROIText == 0;
                text(ROI_TextPos(1),ROI_TextPos(2),ListString(ROI_tagPos),'HorizontalAlignment','center','Color',color,'FontSize',8);
            end
        hold off;
    end
    
elseif ROI_position(1,3) == 3;% coronal  
    ListString{ROI_tagPos} = [ROI_name '(Coronal,' num2str(ROI_position(2,3)) ')'];
    ROI_TextPos(1) = (max(ROI_position(:,1))-min(ROI_position(:,1)))/2+min(ROI_position(:,1));
    ROI_TextPos(2) = (max(ROI_position(:,2))-min(ROI_position(:,2)))/2+min(ROI_position(:,2));
    
%     [X, Y] = meshgrid(1:MDims(3), 1:MDims(2));% Create seed points @ 12/10/10
%     BW_ROI = inpolygon(X,Y,ROI_position(:,2),ROI_position(:,1));
%     [Seed(:,2),Seed(:,3)] = find(BW_ROI);
%     Seed(:,1) = slider4_slice;
    
    if ROI_position(2,3) == slider4_slice;% if ROI is in current image slice
        axes(handles.axes_coronal);
        hold on;
        line(ROI_position(:,1),ROI_position(:,2),'color',color,'LineWidth',1);
            if Hidden_ROIText == 0;
                text(ROI_TextPos(1),ROI_TextPos(2),ListString(ROI_tagPos),'HorizontalAlignment','center','Color',color,'FontSize',8);
            end
        hold off;
    end
end

ROI_ALLposition{ROI_tagPos} = ROI_position;
ROI_ALLTextPos{ROI_tagPos} = ROI_TextPos;
ROI_ALLColor{ROI_tagPos} = color;
% ROI_ALLSeed{ROI_tagPos} = Seed;% Create seed points @ 12/10/10

set(handles.listbox_roi,'string',ListString,'Value',size(ListString,2));
setappdata(handles.Load,'ListString',ListString);

setappdata(handles.Load,'ROI_ALLposition',ROI_ALLposition);
setappdata(handles.Load,'ROI_ALLTextPos',ROI_ALLTextPos);
setappdata(handles.Load,'ROI_ALLColor',ROI_ALLColor);
% setappdata(handles.Load,'ROI_ALLSeed',ROI_ALLSeed);% Create seed points @ 12/10/10
setappdata(handles.Load,'Index_Tract',Index_Tract);  % Modify ROI file format @ 12/10/10


assignin('base','ROI_ALLposition',ROI_ALLposition);
assignin('base','ROI_ALLTextPos',ROI_ALLTextPos);
assignin('base','ListString',ListString);
assignin('base','ROI_ALLColor',ROI_ALLColor);
% assignin('base','ROI_ALLSeed',ROI_ALLSeed);% Create seed points @ 12/10/10

set(handles.Rename,'Enable','on');%initialing of ROI options
set(handles.Remove,'Enable','on');
set(handles.Reset_color,'Enable','on');
set(handles.Export_ROI,'Enable','on');%initialiaing enable of Export ROI option
ROI_ready = 1;

% --------------------------------------------------------------------
function Export_ROI_Callback(hObject, eventdata, handles)

global ROI_tagPos;

if ROI_tagPos>0;% if listbox have ROI
Select = get(handles.listbox_roi,'Value');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');   
Index_Tract = getappdata(handles.Load,'Index_Tract'); % Modify ROI file format @ 12/10/10
ROI_position = ROI_ALLposition{Select};
[filename pathname] = uiputfile('\.mat','Please input file name');
if isequal(filename,0);
   return
end
% dlmwrite([pathname filename],ROI_position, 'precision', '%.6f','newline', 'pc')
save([pathname filename], 'Index_Tract','ROI_position'); % Modify ROI file format @ 12/10/10
end


% --------------------------------------------------------------------
function Reset_color_Callback(hObject, eventdata, handles)

global Hidden_ROIText VDims;
global slider2_slice slider3_slice slider4_slice;
global axial_h_m1 axial_h_m2 axial_v_m1 axial_v_m2;
global sagittal_h_m1 sagittal_h_m2 sagittal_v_m1 sagittal_v_m2;
global coronal_h_m1 coronal_h_m2 coronal_v_m1 coronal_v_m2;
global xdata_axial_v ydata_axial_v xdata_axial_h ydata_axial_h;
global xdata_sagittal_v ydata_sagittal_v xdata_sagittal_h ydata_sagittal_h;
global xdata_coronal_v ydata_coronal_v xdata_coronal_h ydata_coronal_h;


    
Select = get(handles.listbox_roi,'Value');
ListString = getappdata(handles.Load,'ListString');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition');
ROI_ALLTextPos = getappdata(handles.Load,'ROI_ALLTextPos');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');

color = uisetcolor;
if isequal(color,0);
   return
end
ROI_ALLColor{Select} = color;
%===========(ROI axes_axial)===========%
axes(handles.axes_axial);
IMa_now = getappdata(handles.Load,'IMa_now');
imagesc(IMa_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(1) VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
axial_v_m1 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[0 0 0],'LineStyle','-');
axial_v_m2 = line('XData',xdata_axial_v,'YData',ydata_axial_v,'Color',[1 1 1],'LineStyle',':');
axial_h_m1 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[0 0 0],'LineStyle','-');
axial_h_m2 = line('XData',xdata_axial_h,'YData',ydata_axial_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==1 && ROI_ALLposition{i}(2,3)==slider2_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_sagittal)===========%
axes(handles.axes_sagittal);
IMs_now = getappdata(handles.Load,'IMs_now');
imagesc(IMs_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(1) 1]);% consider image thickness to chang voxel size
hold on;
sagittal_v_m1 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[0 0 0],'LineStyle','-');
sagittal_v_m2 = line('XData',xdata_sagittal_v,'YData',ydata_sagittal_v,'Color',[1 1 1],'LineStyle',':');
sagittal_h_m1 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[0 0 0],'LineStyle','-');
sagittal_h_m2 = line('XData',xdata_sagittal_h,'YData',ydata_sagittal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==2 && ROI_ALLposition{i}(2,3)==slider3_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end

%===========(ROI axes_coronal)===========%
axes(handles.axes_coronal);
IMc_now = getappdata(handles.Load,'IMc_now');
imagesc(IMc_now);axis off;axis equal;colormap gray
axis image;
daspect([VDims(3)  VDims(2) 1]);% consider image thickness to chang voxel size
hold on;
coronal_v_m1 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[0 0 0],'LineStyle','-');
coronal_v_m2 = line('XData',xdata_coronal_v,'YData',ydata_coronal_v,'Color',[1 1 1],'LineStyle',':');
coronal_h_m1 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[0 0 0],'LineStyle','-');
coronal_h_m2 = line('XData',xdata_coronal_h,'YData',ydata_coronal_h,'Color',[1 1 1],'LineStyle',':');
if size(ROI_ALLposition,2)~=0;
    for i=1:size(ROI_ALLposition,2);
        if ROI_ALLposition{i}(1,3)==3 && ROI_ALLposition{i}(2,3)==slider4_slice;
            line(ROI_ALLposition{i}(:,1),ROI_ALLposition{i}(:,2),'color',ROI_ALLColor{i},'LineWidth',1);
            if Hidden_ROIText==0;
                text(ROI_ALLTextPos{i}(1),ROI_ALLTextPos{i}(2),ListString{i},'HorizontalAlignment','center','Color',ROI_ALLColor{i},'FontSize',8);
            end
            hold off;
        end
    end
end
setappdata(handles.Load,'ROI_ALLColor',ROI_ALLColor);
assignin('base','ROI_ALLColor',ROI_ALLColor);


% --- Executes on button press in togglebutton_arrow.
function togglebutton_arrow_Callback(hObject, eventdata, handles)

global arrow_ok
zoom off;pan off;
set(handles.togglebutton_zoom,'Value',0);
set(handles.togglebutton_pan,'Value',0);
arrow_ok=1;

% --- Executes on button press in togglebutton_zoom.
function togglebutton_zoom_Callback(hObject, eventdata, handles)

global arrow_ok
zoom on;pan off;
set(handles.togglebutton_arrow,'Value',0);
set(handles.togglebutton_pan,'Value',0);
arrow_ok=0;

% --- Executes on button press in togglebutton_pan.
function togglebutton_pan_Callback(hObject, eventdata, handles)

global arrow_ok
zoom off;pan on;
set(handles.togglebutton_arrow,'Value',0);
set(handles.togglebutton_zoom,'Value',0);
arrow_ok=0;


% --------------------------------------------------------------------
function Help_Callback(hObject, eventdata, handles)



% --------------------------------------------------------------------
function About_Callback(hObject, eventdata, handles)

Data=1:64;Data=(Data'*Data)/64;
CreateStruct.WindowStyle='replace';
CreateStruct.Interpreter='tex';
msgbox(['This program of DtiSearch is still in developing... ',...
        'Developed by Chia-Hao Chang. Taiwan, 2008. ',...
        'For more information or make a suggestion, please contact me: oh75420@gmail.com '],...
        'Message Box','custom',Data,hot(64),CreateStruct);


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)


% --- Executes on button press in pushbutton_fiber.
function pushbutton_fiber_Callback(hObject, eventdata, handles)

global MDims VDims StepRate;

% InMa = getappdata(handles.Load,'InMa');
Tracts = getappdata(handles.Load,'Tracts');
FA = getappdata(handles.Load,'FA');
DWIB0 = getappdata(handles.Load,'DWIB0');
Index_Tract = getappdata(handles.Load,'Index_Tract');
Select = get(handles.listbox_roi,'Value');
ROI_ALLposition = getappdata(handles.Load,'ROI_ALLposition'); 
% ROI_ALLSeed = getappdata(handles.Load,'ROI_ALLSeed');
ROI_ALLColor = getappdata(handles.Load,'ROI_ALLColor');
% Seed = ROI_ALLSeed{Select};
color = ROI_ALLColor{Select};


assignin('base','Index_Tract',Index_Tract);

%===========(pick up the fiber pass through the ROI)===========%
TractsROI{length(Index_Tract),1} = 0;
for i = 1:length(Index_Tract);            
    TractsROI{i,1} = Tracts{Index_Tract(i)};          
end

%===========(labeling the fiber pass through the ROI of image)===========%
CMaROI = zeros(MDims);
for i = 1:length(TractsROI);
    Index = unique(ceil(TractsROI{i}),'rows');
    for j = 1:length(Index);
        temp_CMaROI  = CMaROI(Index(j,1),Index(j,2),Index(j,3));
        CMaROI(Index(j,1),Index(j,2),Index(j,3)) = temp_CMaROI +1;
    end
end
BMaROI = logical(CMaROI);
% GMaROI = CMaROI./max(CMaROI(:));
temp_FA = FA;
temp_FA(BMaROI==1) = 1;
LFA(:,:,1,:) = temp_FA;
% LFA = reshape(LFA+GMaROI,[MDims(1) MDims(2) 1 MDims(3)]);
temp_FA(BMaROI==1) = 0;
LFA(:,:,2,:) = temp_FA;LFA(:,:,3,:) = temp_FA;



assignin('base','CMaROI',CMaROI);
setappdata(handles.Load,'LFA',LFA); 
setappdata(handles.Load,'CMaROI',CMaROI);
IndexString = get(handles.popupmenu_index,'String');
IndexString{4} = 'Marked FA images';
set(handles.popupmenu_index,'String',IndexString);
figure;
%===========(visualization the fiber pass through the ROI)===========%
%--------B0
temp_DWIB0 = sort(reshape(DWIB0,1,[]));
temp_DWIB0 = temp_DWIB0(isnan(temp_DWIB0) == 0);
Cmin = temp_DWIB0(1);
Cmax = temp_DWIB0(round(length(temp_DWIB0)*.97));% window width
DWIB0(DWIB0 < Cmin) = 0;
DWIB0(DWIB0 > Cmax) = Cmax;
temp_DWIB0 = DWIB0./(Cmax-Cmin);
%--------B0 end

choose_slices(FA,70,64,30); 
TractROIL = zeros(length(TractsROI),1);
for m = 1:length(TractsROI);
    p = patch([(TractsROI{m,1}(:,1))' NaN],[(TractsROI{m,1}(:,2))' NaN],[(TractsROI{m,1}(:,3))' NaN],0); 
    joint = ([TractsROI{m,1}(2:end,:); NaN NaN NaN]-TractsROI{m,1});
    joint(end,:) = joint(end-1,:);
    temp_joint = joint;
    joint(:,1) = temp_joint(:,2);
    joint(:,2) = temp_joint(:,1);
    cdata = [abs(joint./StepRate); NaN NaN NaN];
    cdata = reshape(cdata,length(cdata),1,3);
    set(p,'CData', cdata, 'EdgeColor','interp') 
    TractROIL(m,1) = length(TractsROI{m,1});       
end
 

% ROI_position = ROI_ALLposition{Select};
% if ROI_position(1,3) == 1;% axial
%     ROI_position(:,3) = ROI_position(2,3);
% elseif ROI_position(1,3) == 2;% sagittal
%     temp_ROI_position = ROI_position;
%     ROI_position(:,2) = temp_ROI_position(:,1);
%     ROI_position(:,1) = temp_ROI_position(2,3);
%     ROI_position(:,3) = MDims(3) - temp_ROI_position(:,2);
% elseif ROI_position(1,3) == 3;% coronal
%     temp_ROI_position = ROI_position;
%     ROI_position(:,1) = temp_ROI_position(:,1);
%     ROI_position(:,2) = temp_ROI_position(2,3);
%     ROI_position(:,3) = MDims(3) - temp_ROI_position(:,2);
% end
% line(ROI_position(:,2),ROI_position(:,1),ROI_position(:,3),'color',color,'LineWidth',1); 
set(gca,'XTick',[],'YTick',[],'ZTick',[],'Color',[0 0 0],'XColor',[1 1 1],'YColor',[1 1 1],'ZColor',[1 1 1]);
set(gcf,'Color',[0 0 0]);
xlabel('Anterior - Posterior');ylabel('Right - Left');zlabel('Inferior - Superior');
axis equal;hold off;
axis([1 MDims(1) 1  MDims(2) 1  MDims(3)]);
daspect([ VDims(3)/VDims(1)  VDims(3)/VDims(2) 1]);
view(3);zoom(3);box on;


% --- Executes on button press in togglebutton_or.
function togglebutton_or_Callback(hObject, eventdata, handles)

set(handles.togglebutton_non,'Value',0);
set(handles.togglebutton_or,'Value',1);
set(handles.togglebutton_and,'Value',0);
set(handles.togglebutton_not,'Value',0);


% --- Executes on button press in togglebutton_and.
function togglebutton_and_Callback(hObject, eventdata, handles)

set(handles.togglebutton_non,'Value',0);
set(handles.togglebutton_or,'Value',0);
set(handles.togglebutton_and,'Value',1);
set(handles.togglebutton_not,'Value',0);


% --- Executes on button press in togglebutton_not.
function togglebutton_not_Callback(hObject, eventdata, handles)

set(handles.togglebutton_non,'Value',0);
set(handles.togglebutton_or,'Value',0);
set(handles.togglebutton_and,'Value',0);
set(handles.togglebutton_not,'Value',1);


% --- Executes on mouse press over axes background.
function axes_axial_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_axial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
