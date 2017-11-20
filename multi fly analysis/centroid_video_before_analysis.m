%cynthia's program that creates 1000(customizable)-frame video chunks with
%the centroid overlaid. 

% READ THIS BEFORE YOU RUN THIS SCRIPT!

% you need 4 files to run this script!
% 1. video avi file (for example, 120810reg1.avi)
% 2. mat file that contains the variables for the corresponding video file
% to get crossing info, velocity info etc.
% (To generate the mat file, run 'single_fly_analysis_for_one_file_only')
% 3. the original (not transformed) csv file for the fly track
% (for example, '120810reg1bgs_xypts.cvs')
% 4. the original (not transformed) mat file for the rim info
% (for example, '120810rimpoints.mat')
%
% 5. This script will use for loops to generate 1000 frame-long avi files
% for the entire video file. 
% To avoid this, 1) use lines 97~99 and comment out lines 92~94, 2) comment
% out lines 170~171 and the last cell
% 
% 6. The generated avi files might not run correctly in Quicktime. You can
% use Windows media player to run it (no frame-by-frame play) or use Fiji
% to play it frame-by-frame.


clear all; close all;

vidname = uigetfile('*.avi','Select the movie file');
filename = [vidname(1:end-4) '_xypts.csv']; % original, not transformed file

fragSize = 1000;
% cd(rootdir);

% original data
[num,raw,txt] = xlsread(filename,1);
xcoords = num(:,1);%(:,1);
ycoords = 480-num(:,2);
% ycoords = 420-num(:,2:2:end);

%smoothed data
xcoords1 = smooth(num(:,1),10);%(:,1);
ycoords1 = 480-smooth(num(:,2),10);
% ycoords1 = 420-num1(:,2:2:end);
phi = linspace(0,2*pi,50);
cosphi = cos(phi);
sinphi = sin(phi);

%further smoothed data (data used for curvature calculation)
% xcoords_C = smooth(xcoords,14);
% ycoords_C = smooth(ycoords,14);


%%
vidfile = VideoReader(vidname);
numframes = vidfile.NumberofFrames;

%==========================================================================
% To generate avi files for the entire video, Use this
% startframe = 1;
% endframe = startframe+fragSize-1;
% numfrags = floor((numframes-startframe+1)/fragSize);
%==========================================================================
%To get one avi file with specific frame numbers, Use this
startframe = 6000;
endframe = 7000;
numfrags = 1;
%==========================================================================

  
for f = 1:numfrags,
    close all;
    boutVec = [startframe endframe]
    %display(vidfile);
    thisBoutVid = read(vidfile,boutVec);
    vidObj = VideoWriter([vidname(1:end-4) '_marked_fr' num2str(boutVec(1)) ...
        'to' num2str(boutVec(2))],'Motion JPEG AVI');
    open(vidObj);
    for (t = 1:fragSize),        
        imshow(rgb2gray(thisBoutVid(:,:,:,t))); hold on;
        if (startframe+t-1<=length(xcoords)),
            %fly centroids
            plot(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:),'r*'); hold on;
            %smoothed data
            plot(xcoords1(startframe+t-1,:),ycoords1(startframe+t-1,:),'go');           
            
        end;
        text(10,10,num2str(startframe+t-1),'color','r');

        hold off;
        currentImg = getframe;
        writeVideo(vidObj,currentImg);
        clear currentImg;
    end;
    
    clear('thisBoutVid');
    close(vidObj);
    close all
    %Comment this part out if you only need one video with the specific
    %frame numbers.
%     startframe = endframe+1;
%     endframe = startframe+fragSize-1;
end;

%%
%Comment this part out if you only need one video with the specific frame
%numbers.
% 
% if(startframe~=numframes+1),
%     endBoutVid = read(vidfile,[startframe numframes]);
%     vidObj = VideoWriter([vidname(1:end-4) '_marked_fr' num2str(startframe) ...
%         'to' num2str(endframe)],'Motion JPEG AVI');
%     open(vidObj);
%     for(t = 1:size(endBoutVid,4)),
%         imagesc(endBoutVid(:,:,:,t));hold on;
%         if((startframe+t-1)<length(xcoords)),
%         plot(xcoords(startframe+t-1),ycoords(startframe+t-1),'r*'); hold on;
%         end;
%         text(10,10,num2str(startframe+t-1));hold off;
%         currentImg = getframe;
%         writeVideo(vidObj,currentImg);
%     end;
%     clear('thisBoutVid');
%     close(vidObj);
% end;
