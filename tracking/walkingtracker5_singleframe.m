function walkingtracker5_singleframe(vid_no,framenumber)
%% called by batch processing code - does not work otherwise.

%11/12/2013 by SJ : trying to improve walkingtracker4
%problem with version 4: when the fly is approachin the IR, version 4 places
%the centroid in between the actual fly and its reflection on the tube.
%In version 5, it will check how big the object is and if it is reasonably
%big, it will ignore the smaller object (probably the reflection)
currentfolder = pwd;
day = currentfolder(end-5:end); %automatically finds the date from the folder name
%load rimpoints mat file
load([num2str(day) '_3rimpoints.mat']);

flylength = 27;

    % reading background subtracted video
    fname1 = ([num2str(day) 'reg' num2str(vid_no) 'bgs.avi']);
    fname1string = fname1;
    fname1 = VideoReader(fname1);
    
        I=read(fname1,framenumber);
        
            %read slightly bigger/smaller IRs
            v=slightlybig(:,1);
            x=slightlybig(:,2);
            y=slightlysmall(:,1);
            z=slightlysmall(:,2);
            
            J = im2bw(I,0.02); %convert image to black and white, brightness threshold
            K= bwareaopen(J,8); %size threshold
            imshow(K);
            L = imfill(K,'holes');
            s = regionprops(L,{'Centroid', 'Area'});
            A = [s.Area];
            
            N=isempty(A); %could it detect the fly?
            if (N==1) %if there is no object above two thresholds,
                display('if loop')
                
                J =im2bw(I,0.02); %look for less bright object
                K= bwareaopen(J,10);
                L = imfill(J,'holes');
                s = regionprops(L,{'Centroid', 'Area'});
                A = [s.Area];
                [maxArea, maxIndex] = max(A);
                
            else
                [maxArea, maxIndex] = max(A);
            end
            
            L = imfill(K,'holes'); %this line is not necessary? (SJ)
            
           
            
            if isempty(maxIndex) ==1; %no fly detected
                xypts(a,:) = [5,5]; %random xy points in case there is no detectable fly
                
            else
                
                fly_x= s(maxIndex).Centroid(1); %get the centroid x and y points
                fly_y= s(maxIndex).Centroid(2);
                
               
                
                %special case when fly is near the IR
                IN1=inpolygon(fly_x,fly_y,v,x); %slightly bigger IR
                IN2=inpolygon(fly_x,fly_y,y,z); %slightly smaller IR
                if ((IN1==1)&& (IN2==0))
                    
                    if(maxArea < 180) %if the fly is in between slighly biger and slightly smaller IRs
                        % AND if the fly is smaller than 170, it is likely that the fly is under the IR
                        rect = [(fly_x-flylength),(fly_y-flylength),60,60];
                        K = imcrop(K,rect);
                        L = bwconvhull(K);
                        s = regionprops(L,{'Centroid', 'Area'});
                        A = [s.Area];
                        [maxArea, maxIndex] = max(A);
                       
                            s(maxIndex).Centroid(1)=s(maxIndex).Centroid(1)+ fly_x - flylength;
                            s(maxIndex).Centroid(2)=s(maxIndex).Centroid(2)+ fly_y - flylength;
                      
                        
                        
                    elseif maxArea > 300 %normally the fly is not this big thus this means that reflection is merged with the real fly
                        
                        J =im2bw(I,0.21); %look for bright object to get rid of shade
                        K= bwareaopen(J,150); %look for bigger object to get rid of shade
                        L = imfill(J,'holes');
                        s = regionprops(L,{'Centroid', 'Area'});
                        A = [s.Area];
                        [maxArea, maxIndex] = max(A);
                        
                       
                        
                    end
                end
                
                clear I J K L s A;
            end
        
       
    end
    
        
    
                  