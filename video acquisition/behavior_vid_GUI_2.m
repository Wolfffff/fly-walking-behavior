function varargout = behavior_vid_GUI_2(varargin)
% BEHAVIOR_VID_GUI_2 MATLAB code for behavior_vid_GUI_2.fig
%      BEHAVIOR_VID_GUI_2, by itself, creates a new BEHAVIOR_VID_GUI_2 or raises the existing
%      singleton*.
%
%      H = BEHAVIOR_VID_GUI_2 returns the handle to a new BEHAVIOR_VID_GUI_2 or the handle to
%      the existing singleton*.
%
%      BEHAVIOR_VID_GUI_2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BEHAVIOR_VID_GUI_2.M with the given input arguments.
%
%      BEHAVIOR_VID_GUI_2('Property','Value',...) creates a new BEHAVIOR_VID_GUI_2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before behavior_vid_GUI_2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to behavior_vid_GUI_2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help behavior_vid_GUI_2

% Last Modified by GUIDE v2.5 22-Jan-2013 14:26:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @behavior_vid_GUI_2_OpeningFcn, ...
                   'gui_OutputFcn',  @behavior_vid_GUI_2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
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


% --- Executes just before behavior_vid_GUI_2 is made visible.
function behavior_vid_GUI_2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to behavior_vid_GUI_2 (see VARARGIN)

%Set directory.

dir = ['F:\Annu and Andrew data\' datestr(now,'yymmdd') '\'];

try
    cd(dir);
catch
    mkdir(dir);
    cd(dir);
end;

currdir = pwd;

set(handles.dir_edit,'String',currdir);
updatedir(hObject,eventdata,handles);
handles.framerate = str2num(get(handles.fps_edit,'String'));
handles.numsecs = str2num(get(handles.numsecs_edit,'String'));
numframes = handles.framerate*handles.numsecs;
handles.numframes = numframes;
%Name files.
%expNum = whatever function you're using to count numbers.
% set(handles.expnum_edit,'String',str2num(expNum));
% set(handles.trialnum_edit,'String',str2num(expNum));

%guidata(hObject, handles);
%Initialize video with default configuration.
[handles.vid1 handles.src1] = initializeVid1(hObject, eventdata, handles,[0 0 640 480], 89, 9, 2500);
[handles.vid2 handles.src2] = initializeVid2(hObject, eventdata, handles,[0 0 640 480], 89, 9, 2500);
%handles.s = initializeSession(hObject,eventdata,handles);
% display(handles.s);
guidata(hObject, handles);
% handles.src1.ExtendedShutter = 10000;
%display(handles);
% preview(handles.vid2,g);

% Choose default command line output for behavior_vid_GUI_2
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes behavior_vid_GUI_2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function [vid1, src1] = initializeVid1(hObject, eventdata, handles, roi, brightness, gain, extshutter)
% vid1 = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
vid1 = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
triggerconfig(vid1, 'manual');
vid1.ROIPosition = roi;
vid1.FramesPerTrigger=handles.numframes; 
vid1.LoggingMode = 'disk';

src1 = getselectedsource(vid1);
src1.FrameRate ='30';
src1.ExtendedShutter = 5250;
% src1.Shutter = extshutter;
% src1.ExposureOffset = 0;
% display(extshutter);
% src1.Shutter= 281; %if it is bigger than 1000, two cameras acquire at different times!
% src1.Shutter= 100;
src1.Brightness = 90;
src1.Gain = gain;
% display(src1.Timebase);
axes(handles.vid_axes1);
h = image();
preview(vid1,h);
%guidata(hObject, handles);

function [vid2, src2] = initializeVid2(hObject, eventdata, handles, roi, brightness, gain, extshutter)
% vid1 = videoinput('avtmatlabadaptor64_r2009b', 2, 'F0M5_Mono8_640x480');
vid2 = videoinput('avtmatlabadaptor64_r2009b', 2, 'F0M5_Mono8_640x480');
triggerconfig(vid2, 'manual');
vid2.ROIPosition = roi;
vid2.FramesPerTrigger=handles.numframes; 
vid2.LoggingMode = 'disk';
src2 = getselectedsource(vid2);
src2.FrameRate ='30';
% % src1.FrameRate ='30';
src2.ExtendedShutter = 5250;
% src1.ExtendedShutter = extshutter;
% src1.Shutter =  221;
% src1.Shutter = 80;

src2.Brightness = 90;
src2.Gain = gain;
% display(src1.Timebase);
axes(handles.vid_axes2);
g = image();
preview(vid2,g);

function data = initializeData(hObject, eventdata, handles)

% data.expNum = str2num(get(handles.expnum_edit,'String'));
data.trialNum = str2num(get(handles.trialnum_edit,'String'));%+30 to distinguish these files from the other set-up
data.trialtag = [datestr(now,'yymmdd') 'video' int2str(data.trialNum)];
%data.timefile = ['timestamps_' data.trialtag];
%data.vidtimefile = ['videotime_' data.trialtag];
data.avifile1 = [data.trialtag '_1.avi']
data.avifile2 = [data.trialtag '_2.avi']
data.roifile = [data.trialtag '_roi'];
data.odorpulse=0; %[];
%data.timestamps = 0; %[];
handles.data = data;
guidata(hObject, handles);

function s = initializeSession(hObject, eventdata, handles)
s = daq.createSession('ni');
s.Rate=10000;
s.addAnalogOutputChannel('Dev1',0,'Voltage');
s.addAnalogOutputChannel('Dev1',1,'Voltage');
display('initialize session has been called');
% 
function s = updateSessionOutput(hObject, eventdata, handles)
s = handles.s;
t = 0:(1/s.Rate):(handles.numsecs+1);
data.nsamp=s.Rate*(handles.numsecs+1);

% % %clearing====================================================
% data.stimon = handles.numsecs/10; 
% data.stimoff = (9*handles.numsecs)/10; 
% display('FLUSHING')
%============================================================

data.stimon = handles.numsecs/3; %3 min in 9 min video
data.stimoff = (2*handles.numsecs)/3; % 6 min in 9 min video
display('ODOR TRIAL')

data.stimonsamp = floor(data.stimon*s.Rate);
data.stimoffsamp= floor(data.stimoff*s.Rate) ;
outputData(:,1)=zeros(data.nsamp,1);
outputData(data.stimonsamp:data.stimoffsamp,1) = 5;
outputData(:,2)=zeros(data.nsamp,1);
outputData(data.stimonsamp:data.stimoffsamp,2) = 5;
s.queueOutputData(outputData);
s.NotifyWhenDataAvailableExceeds =s.Rate; %*10000;

% handles.s = s;
% guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = behavior_vid_GUI_2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function dir_edit_Callback(hObject, eventdata, handles)
% hObject    handle to dir_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dir_edit as text
%        str2double(get(hObject,'String')) returns contents of dir_edit as a double


% --- Executes during object creation, after setting all properties.
function dir_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dir_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in changedir_bttn.
function changedir_bttn_Callback(hObject, eventdata, handles)
% hObject    handle to changedir_bttn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
newdir = uigetdir();
display(newdir);
cd(newdir);
set(handles.dir_edit,'String',newdir);
updatedir(hObject,eventdata,handles);

function updatedir(hObject,eventdata,handles)
% sets the experiment number and the trial number to the default next value
% in the current directory.

%I do not use experiment number , only trial number to name video files
%(SJ)

prefix1 = [datestr(now,'yymmdd') 'video'];
prefix2 = ['*'];

experimentsInDir = dir([prefix1 prefix2 '_1.avi'])


if(size(experimentsInDir,1)==0),
    lastExp = 0;
    lastTrial= 30;
else
    expAccum = [];
    trialAccum = [];
    for (i = 1:size(experimentsInDir,1)),
        expr = experimentsInDir(i,1).name
        tok = regexp(expr,[prefix1 '(\d+)_' '1.avi'],'tokens');
        display(tok);
        tok1 = tok{1}{1};
        %tok2 = tok{1}{2};
        expAccum = [expAccum str2num(tok1)];
        trialAccum = [trialAccum str2num(tok1)];
    end;
%     display(expAccum);
    display(trialAccum);
%     lastExp = max(expAccum);
    lastTrial = max(trialAccum);%+30 to distinguish these files from the other set-up
end;
% set(handles.expnum_edit,'String',num2str(lastExp+1));
set(handles.trialnum_edit,'String',num2str(lastTrial+1));

% --- Executes on button press in changesettings_bttn1.
function changesettings_bttn1_Callback(hObject, eventdata, handles)
% hObject    handle to changesettings_bttn1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%stoppreview(handles.vid1);
% roi = handles.vid1.ROIPosition;
% brightness = handles.src1.Brightness;
% gain = handles.src1.Gain;
% extshutter = handles.src1.ExtendedShutter;
% delete(handles.vid1); 
vidsettings_GUI_4(handles.vid1, handles.src1);
% [roi, brightness, gain, extshutter] = vidsettings_GUI_3(1,roi,brightness,gain,extshutter);
% [handles.vid1, handles.src1] = initializeVid1(hObject, eventdata, handles,roi, brightness, gain, extshutter);
guidata(hObject, handles);


% --- Executes on button press in changesettings_bttn2.
function changesettings_bttn2_Callback(hObject, eventdata, handles)
% hObject    handle to changesettings_bttn2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%stoppreview(handles.vid2);
vidsettings_GUI_4(handles.vid2, handles.src2);
% [roi, brightness, gain, extshutter] = vidsettings_GUI_3(1,roi,brightness,gain,extshutter);
% [handles.vid1, handles.src1] = initializeVid1(hObject, eventdata, handles,roi, brightness, gain, extshutter);
guidata(hObject, handles)


function expnum_edit_Callback(hObject, eventdata, handles)
% hObject    handle to expnum_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of expnum_edit as text
%        str2double(get(hObject,'String')) returns contents of expnum_edit as a double


% --- Executes during object creation, after setting all properties.
function expnum_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to expnum_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numsecs_edit_Callback(hObject, eventdata, handles)
% hObject    handle to numsecs_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numsecs_edit as text
%        str2double(get(hObject,'String')) returns contents of numsecs_edit as a double


% --- Executes during object creation, after setting all properties.
function numsecs_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numsecs_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fps_edit_Callback(hObject, eventdata, handles)
% hObject    handle to fps_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fps_edit as text
%        str2double(get(hObject,'String')) returns contents of fps_edit as a double


% --- Executes during object creation, after setting all properties.
function fps_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fps_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in acquire_bttn.
function acquire_bttn_Callback(hObject, eventdata, handles)
% hObject    handle to acquire_bttn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
display('Acquire button is pressed.');

handles.numsecs = str2double(get(handles.numsecs_edit,'String'));
handles.framerate = str2double(get(handles.fps_edit,'String'));
handles.numframes = handles.numsecs*handles.framerate;
handles.vid1.FramesPerTrigger = handles.numframes;
handles.vid2.FramesPerTrigger = handles.numframes;
guidata(hObject, handles);
handles.data = initializeData(hObject, eventdata, handles);
handles.s = initializeSession(hObject,eventdata,handles);


diskLogger1 = VideoWriter([handles.data.avifile1], 'Motion JPEG AVI');

diskLogger2 = VideoWriter([handles.data.avifile2], 'Motion JPEG AVI');

handles.vid1.DiskLogger = diskLogger1;
handles.vid2.DiskLogger = diskLogger2;


handles.s = updateSessionOutput(hObject, eventdata, handles);
set(handles.status_edit,'String',['Acquiring Data']);
s  = handles.s; data = handles.data;
s.IsContinuous = true;
s.startBackground(); 
%start acquisition
start(handles.vid1);
start(handles.vid2);
trigger([handles.vid1, handles.vid2]); 
display('before waittime');
tic; %counting time to see how long it actually took
%pause(handles.numsecs+1);
wait([handles.vid2, handles.vid1],Inf);
pause(1);
toc
guidata(hObject, handles);

set(handles.trialnum_edit,'String',num2str(str2num(get(handles.trialnum_edit,'String'))+1));
set(handles.status_edit,'String',['Ready to Acquire']);
% end;
guidata(hObject, handles);


% --- Executes on button press in stop_bttn.
function stop_bttn_Callback(hObject, eventdata, handles)
% hObject    handle to stop_bttn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

display(['Stopping and saving data.']);
set(handles.status_edit,'String',['Saving data']);
guidata(hObject, handles);
%[frames_v1, timeStamp_v1, metdata1] = getdata(handles.vid1,450);
%[frames_v2, timeStamp_v2, metdata2] = getdata(handles.vid2,450);
display(handles)
diskLogger1 = VideoWriter([handles.data.avifile1], 'Motion JPEG AVI');
% 
diskLogger2 = VideoWriter([handles.data.avifile2], 'Motion JPEG AVI');

stop([handles.vid2, handles.vid1]); 
close([handles.vid2.diskLogger]);
close([handles.vid1.diskLogger]); 
% delete(handles.lis);delete(handles.s);
set(handles.trialnum_edit,'String',num2str(str2num(get(handles.trialnum_edit,'String'))));
guidata(hObject, handles);

daqreset;
%clear all;



function trialnum_edit_Callback(hObject, eventdata, handles)
% hObject    handle to trialnum_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trialnum_edit as text
%        str2double(get(hObject,'String')) returns contents of trialnum_edit as a double


% --- Executes during object creation, after setting all properties.
function trialnum_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialnum_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% % --- Executes on button press in roi_bttn1.
% function roi_bttn1_Callback(hObject, eventdata, handles)
% % hObject    handle to roi_bttn1 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% rectcoords = imrect(handles.vid_axes1);
% pos = wait(rectcoords);
% oldROI = handles.vid1.ROIPosition;
% delete(rectcoords);
% newPos = [oldROI(1)+pos(1) oldROI(2)+pos(2) pos(3) pos(4)];
% roundedPos = round(newPos/4)*4;
% stoppreview(handles.vid1);
% handles.vid1.ROIPosition = roundedPos;
% preview(handles.vid1);
% % set(handles.xoff_edit,'String',num2str(roundedPos(1)));
% % set(handles.yoff_edit,'String',num2str(roundedPos(2)));
% % set(handles.width_edit,'String',num2str(roundedPos(3)));
% % set(handles.height_edit,'String',num2str(roundedPos(4)));
% guidata(hObject, handles);
% 
% 
% % --- Executes on button press in roi_bttn2.
% function roi_bttn2_Callback(hObject, eventdata, handles)
% % hObject    handle to roi_bttn2 (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% rectcoords = imrect(handles.vid_axes2);
% pos = wait(rectcoords);
% oldROI = handles.vid2.ROIPosition;
% delete(rectcoords);
% newPos = [oldROI(1)+pos(1) oldROI(2)+pos(2) pos(3) pos(4)];
% roundedPos = round(newPos/4)*4;
% stoppreview(handles.vid2);
% handles.vid2.ROIPosition = roundedPos;
% preview(handles.vid2);
% guidata(hObject, handles);



function status_edit_Callback(hObject, ~, handles)
% hObject    handle to status_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of status_edit as text
%        str2double(get(hObject,'String')) returns contents of status_edit as a double


% --- Executes during object creation, after setting all properties.
function status_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to status_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
