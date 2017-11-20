%this is to transform xy coordinates using the transform matrix derived
%from cp2tform in 'track_cp2tform.m'
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% function  transformer
currentfolder = pwd;
day = currentfolder(end-5:end);
startvideo = input('what is the first video? ');
endvideo = input('what is the last video? ');

answer1 = input('Do you want to re-use the transformation matrix saved previously? 1= Yes, 2 = NO: ');
if answer1 == 1 %re-use the old tform info from mat file
    tform_file = uigetfile('*.mat','Select the file that contains the transformation matrix');
    load(tform_file);
else %if this is the first time after the camera has moved, do the followings
    
    %if there is already saved registered reference image, just use the image.
    %If not, manually go through the following step to get the image.
    answer1 = input('Is there a registered reference image? 1= Yes, 2= No: ');
    if answer1==1 %if there is a registered image
        unregistered_file = uigetfile({'*.jpg;*.png;*.bmp','Figure files (*.jpg,*.png,*.bmp)'},'Select the registered image file');
        unregistered = imread(unregistered_file);
    else
        %if there is no translation mat file
        translation_info = uigetfile('*.mat*','What is the mat file that contains mask info?');
        load(translation_info,'c','ypixel','base_point','unregistered_points','tform');
        projective_t= tform;
        %% load movie files: only the first set (two reference images)
        unregistered = uigetfile('*.avi', 'Select the refence image file you would like to register', '.');
        unreg = VideoReader(unregistered);
        base = uigetfile('*.avi', 'Select the reference image file you are registering to', '.');
        base = VideoReader(base);
        
        filename = (unregistered(1:end-6));
        %% make a composite transformation matrix for projective and translation
        translate=eye(3,3);
        translate(3,2)=c(2); %move the second image the amount of the difference between the two clicked points in the y dimension
        translate(3,1)=c(1);
                
        translate_t = maketform('affine',translate);
        tform_p_t = maketform('composite',[translate_t projective_t]); %projective + translation matrix
        
        [registered xdata ydata] = imtransform(unregframe,tform_p_t,'FillValues', 255,'XData', [1 size(baseframe,2)],...
            'YData', [1 size(baseframe,1)]); %transform the image and constrain it to the size of the base image - make empty space white
        imshow(registered, 'XData', xdata, 'YData', ydata); hold on%display the transformed image
        h = imshow(baseframe, gray(256));
        set(h, 'AlphaData', 0.6);
        
        hold on
        
        x = [.5, 640, 640, .5, .5];
        y = [.5, .5, ypixel, ypixel,.5]; %selecting points for a rectangular mask
        mask1 = poly2mask(x,y,480,640);
        oldmask = repmat(mask1,[1,1,3]); % make the matrix 3D so it affects all layers of your image
        
        baseframe(oldmask)= registered(oldmask);
        h = imshow(baseframe);
        numpic = input('what should the registered image be numbered? ');
        imwrite(baseframe,['registeredimage' num2str(numpic) '.jpg']);%imwirte does not change resolution, don't use saveas
        
        unregistered =(['registeredimage' num2str(numpic) '.jpg']);
        unregistered = imread(unregistered);
    end
    
    %cropped image is 640X480!
    base = ('C:\Seung-Hye\registration_files\topregistrationimage111219_cropped.bmp');
    base = imread(base);
    
    %either load the transformation matrix saved previously or make new matrix
    answer2 = input('Do you want to re-use the transformation matrix saved previously? 1= Yes, 2 = NO');
    if answer2 == 1
        tform_file = uigetfile('*.mat','Select the file that contains the transformation matrix');
        load(tform_file);
    else %make a new tform matrix
        [unregistered_points, base_points, tform] = transformgenerator(unregistered, base);
    end

end
%%

%get the fly track and inner and outer rim data
% ellipsepointsyn = input('If you clicked rim points in DLTdv5, press 1. If you drew an ellipse, press 2');
% if ellipsepointsyn == 1;
%     % reading inner rim values
%     filename_position_inner = uigetfile('*.csv', 'Select the file for INNER rim position');
%     numvals_pi = xlsread(filename_position_inner);
%     numvals_pi(:,2) = 480-numvals_pi(:,2);%this is to fix the bug in DLTdv5
%
%     %reading outer rim values
%     filename_position_outer = uigetfile('*.csv', 'Select the file for OUTER rim position');
%     numvals_po = xlsread(filename_position_outer);
%     numvals_po(:,2) = 480-numvals_po(:,2);%this is to fix the bug in DLTdv5
%
%     numvals_po_tf = tformfwd(tform,numvals_po);
%
%     numvals_pi_tf= tformfwd(tform,numvals_pi);
%
%
%     xyptsname_inner = [num2str(day) '_xypts_inner_transformed.csv'];
%     csvwrite(xyptsname_inner,numvals_pi_tf,1);
%
%     xyptsname_outer = [num2str(day) '_xypts_outer_transformed.csv'];
%     csvwrite(xyptsname_outer,numvals_po_tf,1);
%
% else
rim_file = [num2str(day) '_3rimpoints.mat'];
load(rim_file);

numvals_pi = inner;
numvals_po = outer;

outer_transformed = tformfwd(tform,numvals_po);

inner_transformed= tformfwd(tform,numvals_pi);

save([num2str(day) '_3transformedrimpoints.mat'], 'inner_transformed', 'outer_transformed');
save([num2str(day) 'transformedrimpoints.mat'], 'inner_transformed', 'outer_transformed');

xyptsname_inner = [num2str(day) '_xypts_inner_transformed.csv'];
csvwrite(xyptsname_inner,inner_transformed,1);

xyptsname_outer = [num2str(day) '_xypts_outer_transformed.csv'];
csvwrite(xyptsname_outer,outer_transformed,1);
% end
%%

for nv=startvideo:endvideo %loop through first video to n'th video
    
    filename_behavior = [num2str(day) 'reg' num2str(nv) 'bgs_xypts.csv'];
    
    
    % filename_behavior = uigetfile('*.csv', 'Select the file for FLY track');
    numvals = xlsread(filename_behavior);
    numvals(:,2) = 480-numvals(:,2);%this is to fix the bug in DLTdv5
    
    
    % %transform the fly track
    numvals_tf = tformfwd(tform, numvals);
    
    xyptsname = [num2str(day) 'video' num2str(nv) '_xypts_transformed.csv'];
    csvwrite(xyptsname,numvals_tf,1);
    close all
    
end
