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


% clear all; close all;

vidname = uigetfile('*.avi','Select the movie file');
filename = [vidname(1:end-4) 'bgs_xypts.csv']; % original, not transformed file

matfilename=uigetfile('*.mat','Select the mat file that contains the variables');
load(matfilename,'fly_x','fly_y','crossing_in','crossing_out','velocity_classified','frame_turn','curv_long_mat','frame_turn','frame_turn_sh');

fragSize = 1000;
% cd(rootdir);

% inner_rim_file = ('110613video1_inner_rim.csv');
% inner_rim = csvread(inner_rim_file,1);
% inner_rim(:,2) = 420-inner_rim(:,2);
rim_file = [vidname(1:6) 'rimpoints.mat'];
load(rim_file);
inner_rim = inner;
inner_radius = 1.2; %new chamber (cm)
%bigger inner_radius: change this number to see the effect
inner_radius_bigger = 1.5; %3 mm increase
%use circle fit to find the center and radius
in_x = inner_rim(:,1);
in_y = inner_rim(:,2);

[ctr_x,ctr_y,circRad] = circfit(in_x,in_y);

%translate x and y points so that the center is (0,0)
in_x_tsl = in_x - ctr_x;
in_y_tsl = in_y - ctr_y;

%now increase the IR and find new and bigger in_x and in_y points
in_x_bigger = in_x_tsl.*inner_radius_bigger/inner_radius;
in_y_bigger = in_y_tsl.*inner_radius_bigger/inner_radius;

%translate the points back
in_x_bigger = in_x_bigger + ctr_x;
in_y_bigger = in_y_bigger + ctr_y;

%replace numvals_pi with new values
bigger_in_x = in_x_bigger;
bigger_in_y = in_y_bigger;

% original data
[num,raw,txt] = xlsread(filename,1);
xcoords = num(:,1);%(:,1);
ycoords = 480-num(:,2);
% ycoords = 420-num(:,2:2:end);

%smoothed data to match with the analysis
xcoords1 = smooth(xcoords,10);
ycoords1 = smooth(ycoords,10);
% % ycoords1 = 420-num1(:,2:2:end);
% phi = linspace(0,2*pi,50);
% cosphi = cos(phi);
% sinphi = sin(phi);
%
% %further smoothed data (data used for curvature calculation)
% xcoords_C = Vertices(:,1);
% ycoords_C = Vertices(:,2);
%

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
startframe = 5401;
endframe = 6400;
numfrags = 1;
%==========================================================================


for f = 1:numfrags,
    close all;
    boutVec = [startframe endframe]
    %display(vidfile);
    thisBoutVid = read(vidfile,boutVec);
    vidObj = VideoWriter([vidname(1:end-4) '_marked_fr' num2str(boutVec(1)) ...
        'to' num2str(boutVec(2))],'Motion JPEG AVI');
    VidObj.FrameRate = 30;
    open(vidObj);
    h=figure(1);
    set(h,'position',[300 400 640 480]);
    
    for (t = 1:fragSize),
        imshow(rgb2gray(thisBoutVid(:,:,:,t))); hold on;
        if (startframe+t-1<=length(xcoords)),
            %             fly centroids
            %             plot(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:),'r*'); hold on;
            %smoothed data
            plot(xcoords1(startframe+t-1,:),ycoords1(startframe+t-1,:),'go');
            
            %             plot(xcoords1(startframe+t:startframe+t+30),ycoords1(startframe+t:startframe+t+30),'w.','markersize',4);
            %next 30 frames (smoothed just like in curvature calculation)
            
            if (startframe+t-60) >0
                plot(xcoords1(startframe+t-60:startframe+t-1,:),ycoords1(startframe+t-60:startframe+t-1,:),'w.','markersize',4);
                %previous 30 frames (smoothed just like in curvature calculation)
                %             plot(xcoords_C(startframe+t-30:startframe+t-1,:),ycoords_C(startframe+t-30:startframe+t-1,:),'g.','markersize',4);
            end
            
            %markinig turns as magenta traces
            for n = startframe+t-60:startframe+t-1
                if (find(curv_long_mat == n) ~= 0) % if this frame is curving/turning
                    plot(xcoords1(n,:),ycoords1(n,:),'g.','markersize',4);
                end
            end
            
            
            %inner rim + bigger inner rim
            plot(inner_rim(:,1),inner_rim(:,2),'w');
            %             plot(bigger_in_x,bigger_in_y,'w:');
            
            %mark crossings
            %             if find(crossing_in == (startframe+t-1)) ~= 0%if this frame is crossing in
            %                 text(300,200,['Crossing In: ' num2str(startframe+t-1)],'color','r','fontsize',14);
            %             elseif find(crossing_out == (startframe+t-1)) ~= 0 %if this frame is crossing out
            %                 text(300,200,['Crossing Out: ' num2str(startframe+t-1)],'color','g','fontsize',14);
            %             end
            
            %mark turning/curving
            if (find(curv_long_mat == (startframe+t-1)) ~= 0) % if this frame is curving/turning
                plot(xcoords1(startframe+t-1,:),ycoords1(startframe+t-1,:),'ms','markersize',10);
            end
            
            %  mark turns : for 3 frames
            %for wide turns
            %             if (find(frame_turn_cv_w == (startframe+t-1)) ~= 0)  %if this frame is 'turning'
            %                 text(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:)+10,'W-TURN','color','w');
            %             end
            %             if (find(frame_turn_cv_w == (startframe+t-2)) ~= 0)  %if the previous frame was 'turning'
            %                 text(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:)+10,'W-TURN','color','w');
            %             end
            %             if (find(frame_turn_cv_w == (startframe+t-3)) ~= 0) %if the 2 previous frame is 'turning' (display the text for 3 frames)
            %                 text(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:)+10,'W-TURN','color','w');
            %             end
            %
            %             %for sharp turns
            if (find(frame_turn_sh == (startframe+t-1)) ~= 0)  %if this frame is 'turning'
                text(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:)+10,'S-TURN','color','m');
            end
            if (find(frame_turn_sh == (startframe+t-2)) ~= 0)  %if the previous frame was 'turning'
                text(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:)+10,'S-TURN','color','m');
            end
            if (find(frame_turn_sh == (startframe+t-3)) ~= 0) %if the 2 previous frame is 'turning' (display the text for 3 frames)
                text(xcoords(startframe+t-1,:),ycoords(startframe+t-1,:)+10,'S-TURN','color','m');
            end
            
            
            
            %mark stops
            if velocity_classified(startframe+t-1) == 0 %if this frame is 'stopping'
                text(xcoords1(startframe+t-1,:),ycoords1(startframe+t-1,:)-10,'stop','color','r');
            end
            %
            %
        end;
        text(15,15,num2str(startframe+t-1),'color','r');
        %         text(10,20,['dotted line marks ' num2str(inner_radius_bigger) 'cm'],'color','b');
        text(15,30,'magenta square marks curving/turning','color','m');
        
        %         text(10,30,['green dots mark smoothed fly track'],'color','g');
        %         text(10,40,['turns (14 smoothing)'],'color','k');
        hold off;
        currentImg = getframe(h);
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
