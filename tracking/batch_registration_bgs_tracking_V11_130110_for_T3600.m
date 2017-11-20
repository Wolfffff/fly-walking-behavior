%this code uses Vikas' new jumpless tracker and has a different selection mechanism for rim points.
clear all;
close all;

currentfolder = cd;
folder_day = currentfolder(end-5:end); %automatically finds the date from the folder name
start_no = input('From which video to start?');
end_no = input('Until which video?');

%% load movie files: only the first set
unregistered = uigetfile('*', 'Select the image file you would like to register', '.');
unreg = VideoReader(unregistered);
base = uigetfile('*', 'Select the reference image you are registering to (base)', '.');
base = VideoReader(base);

filename = (unregistered(1:end-6));

%% make a composite transformation matrix for projective and translation
fly_in_frame = input('Type in the frame number where the fly is inside the odor zone: ');
baseframe = read(base, fly_in_frame); %read the first frame
unregframe = read(unreg,fly_in_frame);

%% load registration points matrix
ans1 = input('If you want to re-use the old registration information, press 1, if not, press 2 ');
if ans1 == 1
    mask_file = uigetfile('*mask*.mat','Select the mask file');
    load(mask_file,'tform','c','ypixel');
    projective_t= tform;
else
    
    [fileName filePath] = uigetfile('*', 'Select file containing the registration matrix', '.');
    if filePath==0, error('None selected!'); end
    load([filePath fileName], 'base_points');
    load([filePath fileName], 'unregistered_points');
    load([filePath fileName], 'tform');
    projective_t= tform;
end

%%
%First we will register the first frame and choose a well-defined point on
%both the registered and the base image (for example a fly). The program
%will then calculate the difference in coordinates between those points to
%generate a translate transform
[registered1 xdata ydata] = imtransform(unregframe,tform,'FillValues', 255,'XData', [1 size(baseframe,2)],...
    'YData', [1 size(baseframe,1)]); %transform the image and constrain it to the size of the base image - make empty space white

if ans1 ==1 %if reusing the registration info from mask file
    translate=eye(3,3);
    translate(3,2)=c(2); %move the second image the amount of the difference between the two clicked points in the y dimension
    translate(3,1)=c(1);
else
    figure(1)
    imshow(registered1, 'XData', xdata, 'YData', ydata); %display the transformed image
    a=ginput(1); %record the coordinates of the user-clicked point
    
    figure(2)
    imshow(baseframe, gray(256));
    b=ginput(1);%record the coordinates of the user-clicked point
    c=b-a;
    %c=[0 -4];
    display(c)
    translate=eye(3,3);
    translate(3,2)=c(2); %move the second image the amount of the difference between the two clicked points in the y dimension
    translate(3,1)=c(1);
    close all;
end

%generates a composite matrix which will then do a projective and
%translational transform. Use it to overlay the registered and the base
%images and choose the mask. for the first frame, decide the mask area

translate_t = maketform('affine',translate);
tform_p_t = maketform('composite',[translate_t projective_t]);

[registered xdata ydata] = imtransform(unregframe,tform_p_t,'FillValues', 255,'XData', [1 size(baseframe,2)],...
    'YData', [1 size(baseframe,1)]); %transform the image and constrain it to the size of the base image - make empty space white

figure
imshow(registered, 'XData', xdata, 'YData', ydata); hold on%display the transformed image
h = imshow(baseframe, gray(256));
set(h, 'AlphaData', 0.6);
hold on

maskyn = input('to apply an existing mask, press 1, otherwise 2');
% if maskyn == 1;
%     oldmask = uigetfile('Choose the existing mask file');
%     load(oldmask);
    
if maskyn ==2 
    display('click on the image at the height at which you would like the image to be split');
    display(' between the two cameras. Then press RETURN.');
    [~, y, pixel] = impixel;
    
    ypixel = y;
end
display((ypixel));
x = [.5, 640, 640, .5, .5];
y = [.5, .5, ypixel, ypixel,.5]; %selecting points for a rectangular mask
mask1 = poly2mask(x,y,480,640);
oldmask = repmat(mask1,[1,1,3]); % make the matrix 3D so it affects all layers of your image
filename = [filename 'mask1'];
save(filename); %save the mask
save([num2str(folder_day) 'translation.mat'], 'c', 'ypixel');


%apply mask
baseframe(oldmask)= registered(oldmask);
h = imshow(baseframe);


%show the registered image of reference paper to estimate how well
%registration will work
ans2 = input('If you want to see the registered image of reference paper, press 1, if not press Enter');
if ans2 == 1
    %read the reference image files
    unreg_ref_name = uigetfile('*.avi','Select the video file to register');
    unreg_ref = VideoReader(unreg_ref_name);
    unreg_ref = read(unreg_ref,1);
    base_ref_name = uigetfile('*.avi','Select the video file to use as a base image');
    base_ref = VideoReader(base_ref_name);
    base_ref = read(base_ref,1);
    
    %use the same transformation matrix
    [registered_ref xdata ydata] = imtransform(unreg_ref,tform_p_t,'FillValues', 255,'XData', [1 size(base_ref,2)],...
        'YData', [1 size(base_ref,1)]); %transform the image and constrain it to the size of the base image - make empty space white
    
    figure
    imshow(registered_ref, 'XData', xdata, 'YData', ydata); hold on%display the transformed image
    h = imshow(base_ref, gray(256));
    set(h, 'AlphaData', 0.6);
    hold on
    
    %apply mask
    base_ref(oldmask)= registered_ref(oldmask);
    h = imshow(base_ref);
    
    %save the image file
    image_name1 = input('If you want to save the file, type in the name (excluding date, string only); ','s');
    imwrite(base_ref,[folder_day '_' image_name1 '.png']);
end

pointsyn = input('have you already saved rim points for this date? 1 for yes, 2 for no');

if pointsyn == 1
    load([num2str(folder_day) '_3rimpoints.mat'])
    
    hold on
    plot(inner(:,1),inner(:,2),'r');
    plot(outer(:,1),outer(:,2),'r');
    rim_ans=input('If rims look correct, press Enter to proceed, otherwise press 1 to create new rims');
    if isempty(rim_ans) == 1
        close all;
    else
        pointsyn = 2;
    end
end

if pointsyn ==2;
    %display a registered and masked frame from which to choose the ellipses
    baseframe(oldmask)= registered(oldmask);
    imshow(baseframe);
    display('choose an ellipse to fit the inner rim first, then double click.')
    display('Then a fly length larger and double click.')
    display('Then a fly length smaller and double click.')
    display('Finally choose outer rim and double click.');
    
    h=imellipse;
    inner=wait(h);
    i=imellipse;
    slightlybig=wait(i);
    j=imellipse;
    slightlysmall=wait(j);
    jj = imellipse;
    outer = wait(jj);
    
    save([num2str(folder_day) '_3rimpoints.mat'], 'inner', 'slightlybig', 'slightlysmall', 'outer');
end
close all;


%% read the video into matlab files
for numvids = start_no:end_no%loop through first video to n'th video
    %MAKE SURE video_2 IS THE UNREGISTERED VIDEO, if not change it!!!!
    unregistered = [num2str(folder_day) 'video' num2str(numvids)  '_1.avi'];
    unreg = VideoReader(unregistered);
    basename = [num2str(folder_day) 'video' num2str(numvids) '_2.avi'];
    base = VideoReader(basename);
%     unreg_newvidname = [unregistered(1:end-4) 'compressed.avi'];
%     base_newvidname = [basename(1:end-4) 'compressed.avi'];
    %% create movie object to write to
    warning off images:inv_lwm:cannotEvaluateTransfAtSomeOutputLocations;
    newvidname = [unregistered(1:6) 'reg' num2str(numvids) '.avi' ];
    
    vidObj = VideoWriter(newvidname,'Motion JPEG AVI'); %create the registered video
%     vidObj2 = VideoWriter(unreg_newvidname,'Motion JPEG AVI');% compress the original video
%     vidObj3 = VideoWriter(base_newvidname,'Motion JPEG AVI');% compress the original video
    
    if base.NumberofFrames < unreg.NumberofFrames %for videos with different total #s of frames
        frame_number_total = base.NumberofFrames; %make sure the number of frames in the registered video = the smaller number
    else
        frame_number_total = unreg.NumberofFrames;
    end
    
    open(vidObj);
%     open(vidObj2);
%     open(vidObj3);
    %% process video
    
    
    fragmentsize = 200;  % a chunk of 200 frames does imtransform instead of one frame at a time
    
    startframe = 1;
    display(startframe)
    endframe = startframe+fragmentsize-1;
    
    tic
    
    while(endframe<=(frame_number_total));
        %transform images
        data.unregframe= read(unreg,[startframe endframe]);
        data.baseframe = read(base,[startframe endframe]); %read each video frame into an image frame
        
        %write the compressed videos
%         writeVideo(vidObj2,data.unregframe);
%         writeVideo(vidObj3,data.baseframe);
        
        baseframe = read(base,1);
        
        [data.registered(:,:,:,1:fragmentsize) xdata ydata] = imtransform(data.unregframe,tform_p_t,'FillValues', 255,'XData', [1 size(baseframe,2)],...
            'YData', [1 size(baseframe,1)]); %transform the image and constrain it to the size of the base image - make empty space white
        
        
        mask = repmat(oldmask,[1,1,1,fragmentsize]);
        
        data.baseframe(mask)= data.registered(mask);
        writeVideo(vidObj, data.baseframe);
        clear('data.unregframe','data.baseframe');
        startframe = endframe+1
        endframe = startframe+fragmentsize-1;
    end
    
    if((startframe-1)~=(frame_number_total));
        endframe = frame_number_total;
        display(endframe);
        
        fragmentsize= endframe-startframe;
        fragmentsize_end = fragmentsize+1;
        display(fragmentsize_end);
        data.baseframe = read(base,[startframe endframe]);
        data.unregframe = read(unreg,[startframe endframe]);
        %write the compressed the videos
%         writeVideo(vidObj2,data.unregframe);
%         writeVideo(vidObj3,data.baseframe);
        
        baseframe = read(base,1);
        
        %if the remaining frame number is less than 200
        
        [data.registered_end(:, :, :, 1:fragmentsize_end) xdata ydata] = imtransform(data.unregframe,tform_p_t,'FillValues', 255,'XData', [1 size(baseframe,2)],...
            'YData', [1 size(baseframe,1)]);
% [registered_frag(:, :, :, 1:fragmentsize_end) xdata ydata] = imtransform(data.unregframe,tform_p_t,'FillValues', 255,'XData', [1 size(baseframe,2)],...
%     'YData', [1 size(baseframe,1)]);

        mask = repmat(oldmask,[1,1,1,fragmentsize_end]);
        
        data.baseframe(mask)= data.registered_end(mask);
        
        writeVideo(vidObj, data.baseframe); %write it to a win/mac compatible .avi file from matlab movie file
        
        
    end
    
    timetaken_in_registration=toc;
    display(timetaken_in_registration)
    close(vidObj);
%     close(vidObj2);close(vidObj3);
    clear vidObj vidObj2 vidObj3 base unreg;
    clear vidObj base unreg;
end
%% BACKGROUND SUBTRACTION (backgroundsubtract_VB_larger)
%    start_no = 4;
%    end_no =13;

for numvids=start_no:end_no;
    currentfolder = pwd;
    folder_day = currentfolder(end-5:end);
    newvidname = [num2str(folder_day) 'reg'];
    
    fname1string = [newvidname(1:9) num2str(numvids) '.avi'];
    newvidname = [fname1string(1:end-4) 'bgs.avi'];
    %
    fname1 = VideoReader(fname1string);
    % third_frame = floor(fname1.NumberofFrames/3); %this makes frame selection flexible, regardless of
    tcount=1;
    %      ii = 1:50:3750;
    %      iii =3750:50:fname1.NumberofFrames;
    v = 1:50:fname1.NumberofFrames;
    %      v =5697:20:10158;
    for i=v;
        %frames that will be averaged to get the background that will be subtracted
        data.backgroundvideo(:,:,:,tcount) = read(fname1,i);
        tcount=tcount+1;
    end
    % average the background video
    data.background_double = im2double(data.backgroundvideo);
    sum1 = sum(data.background_double,4);
    nframes = size(data.backgroundvideo,4);
    data.average = sum1/nframes;
    clear('data.background_double','data.backgroundvideo');
    data.average2 = im2uint8(squeeze(data.average));
    clear('data.average');
    % subtract the background video from behavior video
    fragmentsize = 200;
    startframe = 1;
    endframe = startframe+fragmentsize-1;
    vidObj = VideoWriter(newvidname,'Motion JPEG AVI');
    open(vidObj);
    bgvid = repmat(data.average2,[1,1,1,fragmentsize]);
    clear('data.average2');
    while (endframe<=(fname1.NumberofFrames));
        data.behaviorvideo=read(fname1,[startframe endframe]);
        data.subtra_video(:,:,:,1:fragmentsize) = imsubtract(squeeze(data.behaviorvideo),bgvid) ; %when object is brighter than background
        writeVideo(vidObj,data.subtra_video);
        clear('data.subtra_video');
        clear('data.behavior_video');
        startframe = endframe+1;
        display(startframe);
        endframe = startframe+fragmentsize-1;
    end;
    if startframe-1 ~= fname1.NumberofFrames
        endframe = fname1.NumberofFrames;
        display('entering end loop');
        data.behaviorvideo=read(fname1,[startframe endframe]);
        endpiece = imsubtract(squeeze(data.behaviorvideo), ...
            bgvid(:,:,:,1:size(data.behaviorvideo,4))); %when object is brighter than background
        writeVideo(vidObj,endpiece);
        close(vidObj);
        clear('data.subtra_video');
    end;
    close(vidObj);
    clearvars -except start_no end_no numvids day
    
    
end

%% TRACKING(walkingtracker3_CH.m)
% %
currentfolder = pwd;
folder_day = currentfolder(end-5:end); %automatically finds the date from the folder name
%load rimpoints mat file
load([num2str(folder_day) '_3rimpoints.mat']);

%replaced with walkingtracker5 (13/11/13)
walkingtracker5(start_no, end_no, slightlybig, slightlysmall, folder_day);

[frames_to_correct] = framechecker(start_no, end_no);

%% trying to reduced incorect frames V 2.0

%trying to fix incorrect frames
%Change: finds a series of consecutive incorrect frames and plots 
%Only corrects frames where the change in the fly's position
%from the first correct frame to the last correct frame
%is less than 100 pixels (~the number of pixels in one cm)

%Adapted from previous 'trying to reduce incorect frames' program.
%Andrew Huan, NCSSM, September 7, 2016.



currentfolder = pwd;
folder_day = currentfolder(end-5:end);

for i = start_no:end_no
    
    temp = frames_to_correct{i};%get the frames to correct
    totalnumberofincorrectframes = length(temp); %how long?
    if totalnumberofincorrectframes>2
        fname1fun = [folder_day 'reg' num2str(i) 'bgs_xypts.csv']; %get the csv file
        numvals = csvread(fname1fun,1); %read the centroid positions
        
        frame= temp(1)-1; %let frame be the frame before the first frame to correct(this means that 'frame' is a correct frame).
        frame3= temp(1)-1;
        
        for excelrownames = 1:totalnumberofincorrectframes
           
             
                if temp(excelrownames)-frame3 == 1 %attempt to 'stairstep' up the frames to correct file to find the frame number corresponding to the last consecutive frame number of a series of frames.
               
                    frame3 = temp(excelrownames);
                    
                    
                else
                    
                    frame2 = frame3+1; %let frame2 be one frame after the last consecutive frame (this means that frame2 is a correct frame).
                    
                    difference= frame2-frame; %how many wrong frames are there in this series of consecutive wrong frames?
                    
                    Distanceinpixels = sqrt(((numvals(frame2,1)-numvals(frame,1))^2)+((numvals(frame2,2)-numvals(frame,2))^2));
                    
                    if Distanceinpixels > 100 %makes sure to not use the estimation if the fly moved for than 100 pixels (~1cm).
                        
                    excelrownames = excelrownames+1;                   
                        
                    else
                    
                    
                        while difference ~= 1          


                            x_frame = numvals(frame, 1);
                            y_frame = numvals(frame, 2);

                            x_frame2 = numvals(frame2, 1);
                            y_frame2 = numvals(frame2, 2);

                            x_step = (x_frame2-x_frame)/difference;
                            y_step = (y_frame2-y_frame)/difference;

                            x_frame = x_step + x_frame;
                            y_frame = y_step + y_frame;

                            numvals(temp(excelrownames-difference+1),:) = [x_frame, y_frame]; %Overwrites the old file with fixed points.

                            frame= temp(excelrownames-difference+1);

                            difference= frame2-frame;
                        end;                            

                        excelrownames = excelrownames+1;
                    end     
                end
        end
    %save changes to csv files    
    csvwrite(fname1fun,numvals,1);
    end
    
end

%this next part will correct any errors that involve the centroid marker
%jumping from one end of the fly's body the other
%For the sake of ease, this next part is just an edited verion of the program above. Perhaps this next part could be combined with code above.

currentfolder = pwd;
folder_day = currentfolder(end-5:end);

for i = start_no:end_no
    
    temp = frames_to_correct{i};%get the frames to correct
    totalnumberofincorrectframes = length(temp); %how long?
    if totalnumberofincorrectframes>2
        fname1fun = [folder_day 'reg' num2str(i) 'bgs_xypts.csv']; %get the csv file
        numvals = csvread(fname1fun,1); %read the centroid positions
       
              
        for excelrownames = 2:totalnumberofincorrectframes-1 %if the first or last frame is incorrect, there will be an error; this is why they are not accounted for.
           
             
                if temp(excelrownames+1) - temp(excelrownames) ~= 1 && temp(excelrownames) - temp(excelrownames-1) ~= 1
               
                            x_frame = numvals(excelrownames - 1, 1);
                            y_frame = numvals(excelrownames - 1, 2);

                            x_frame2 = numvals(excelrownames + 1, 1);
                            y_frame2 = numvals(excelrownames + 1, 2);

                            x_step = (x_frame2-x_frame)/2;
                            y_step = (y_frame2-y_frame)/2;

                            x_new = x_step + x_frame;
                            y_new = y_step + y_frame;

                            numvals(temp(excelrownames),:) = [x_new, y_new]; %Overwrites the old file with fixed points.
                    
                end     
                    
        end
    %save changes to csv files    
    csvwrite(fname1fun,numvals,1);
    end
    
end

