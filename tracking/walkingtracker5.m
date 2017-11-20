function walkingtracker5(start_no, end_no, slightlybig, slightlysmall, day)
%% called by batch processing code - does not work otherwise.

%11/12/2013 by SJ : trying to improve walkingtracker4
%problem with version 4: when the fly is approachin the IR, version 4 places
%the centroid in between the actual fly and its reflection on the tube.
%In version 5, it will check how big the object is and if it is reasonably
%big, it will ignore the smaller object (probably the reflection)


flylength = 27;

for numvids = start_no:end_no
    % reading background subtracted video
    fname1 = ([num2str(day) 'reg' num2str(numvids) 'bgs.avi']);
    fname1string = fname1;
    fname1 = VideoReader(fname1);
    
    xypts = nan(length(fname1.NumberofFrames),2);
    
    fragmentsize = 200;
    fragmentnum = 1;
    startframe = 1
    endframe = startframe+fragmentsize-1;
    
    data.behaviorvideo = NaN(640,480,3,endframe-startframe+1);
    while (endframe<=(fname1.NumberofFrames));
        data.behaviorvideo=read(fname1,[startframe endframe]);
        
        for j=1:fragmentsize, %this is to iterate through the frames in the chunk called "data.behaviorvideo".
            
            I = data.behaviorvideo(:,:,:,j);
            %read slightly bigger/smaller IRs
            v=slightlybig(:,1);
            x=slightlybig(:,2);
            y=slightlysmall(:,1);
            z=slightlysmall(:,2);
            
            J = im2bw(I,0.08); %convert image to black and white, brightness threshold
            K= bwareaopen(J,8); %size threshold
            L = imfill(K,'holes');
            s = regionprops(L,{'Centroid', 'Area'});
            A = [s.Area];
            
            N=isempty(A); %could it detect the fly?
            if (N==1) %if there is no object above two thresholds,
                display('if loop')
                
                a=startframe+j-1;
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
            
            a=startframe+j-1;
            
            if isempty(maxIndex) ==1; %no fly detected
                xypts(a,:) = [5,5]; %random xy points in case there is no detectable fly
                
            else
                
                fly_x= s(maxIndex).Centroid(1); %get the centroid x and y points
                fly_y= s(maxIndex).Centroid(2);
                
                try
                    xypts(a,:) =[s(maxIndex).Centroid(1), 480-s(maxIndex).Centroid(2)]; % makes the resolution match that of the new background subtractor (8.6.11)
                catch
                    xypts(a,:)=[5,5];
                end
                
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
                        try
                            s(maxIndex).Centroid(1)=s(maxIndex).Centroid(1)+ fly_x - flylength;
                            s(maxIndex).Centroid(2)=s(maxIndex).Centroid(2)+ fly_y - flylength;
                            
                            xypts(a,:) =[s(maxIndex).Centroid(1), 480-s(maxIndex).Centroid(2)]; % makes the resolution match that of the new background subtractor (8.6.11)
                        catch
                            xypts(a,:)=[5,5];
                        end
                        
                        
                    elseif maxArea > 300 %normally the fly is not this big thus this means that reflection is merged with the real fly
                        
                        J =im2bw(I,0.21); %look for bright object to get rid of shade
                        K= bwareaopen(J,150); %look for bigger object to get rid of shade
                        L = imfill(J,'holes');
                        s = regionprops(L,{'Centroid', 'Area'});
                        A = [s.Area];
                        [maxArea, maxIndex] = max(A);
                        
                        try
                            xypts(a,:) =[s(maxIndex).Centroid(1), 480-s(maxIndex).Centroid(2)];
                        catch
                            xypts(a,:)=[5,5];
                        end
                        
                    end
                end
                
                clear I J K L s A;
            end
        end;
        
        fragmentnum = fragmentnum+1;
        startframe = endframe + 1;
        display(startframe);
        endframe = startframe+fragmentsize-1;
    end
    clear 'data.behaviorvideo';
    
    %last fragments in case it is less than 200
    if startframe-1 == fname1.NumberofFrames %if frame number is exactly divisible by 200, end the program here
        
        display('exactly 16200 frames')
        endframe = fname1.NumberofFrames;
        display(endframe)
        
    elseif ((startframe-1)~=(fname1.NumberofFrames)),
        data.behaviorvideo = NaN(640,480,3,fname1.NumberofFrames-startframe+1);
        endframe = fname1.NumberofFrames;
        fragmentsize = endframe-startframe+1;
        %         display(fragmentsize)
        data.behaviorvideo=read(fname1,[startframe endframe]);
        
        for j=1:fragmentsize;
            I = data.behaviorvideo(:,:,:,j);
            J = im2bw(I,0.08);
            K= bwareaopen(J,8);
            L = imfill(K,'holes');
            s = regionprops(L,{'Centroid', 'Area'});
            A = [s.Area];
            N=isempty(A);
            if (N==1)
                display('if loop')
                
                a=startframe+j-1;
                J =im2bw(I,0.02);
                M = regionprops(J, 'Area','BoundingBox');
                K= bwareaopen(J,10);
                L = imfill(J,'holes');
                s = regionprops(L,{'Centroid', 'Area'});
                A = [s.Area];
                [maxArea, maxIndex] = max(A);
                
            else
                [maxArea, maxIndex] = max(A);
            end
            L = imfill(K,'holes');
            a=startframe+j-1;
            
            if isempty(maxIndex) ==1;
                xypts(a,:) = [5,5];
                
            else
                fly_x= s(maxIndex).Centroid(1);
                fly_y= s(maxIndex).Centroid(2);
                try
                    xypts(a,:) =[s(maxIndex).Centroid(1), 480-s(maxIndex).Centroid(2)]; % makes the resolution match that of the new background subtractor (8.6.11)
                catch
                    xypts(a,:)=[5,5];
                end
                IN1=inpolygon(fly_x,fly_y,v,x);
                IN2=inpolygon(fly_x,fly_y,y,z);
                if ((IN1==1)&& (IN2==0))
                    if (maxArea < 180) %if the fly is in between slighly biger and slightly smaller IRs
                        % AND if the fly is smaller than 170, it is likely that the fly is under the IR
                        
                        rect = [(fly_x-flylength*3/4),(fly_y-flylength*3/4),60,60];
                        K=imcrop(K,rect);
                        L = bwconvhull(K);
                        s = regionprops(L,{'Centroid', 'Area'});
                        A = [s.Area];
                        [maxArea, maxIndex] = max(A);
                        
                        try
                            s(maxIndex).Centroid(1)=s(maxIndex).Centroid(1)+fly_x-flylength*3/4;
                            s(maxIndex).Centroid(2)=s(maxIndex).Centroid(2)+fly_y-flylength*3/4;
                            
                            a=startframe+j-1;
                            
                            xypts(a,:) =[s(maxIndex).Centroid(1), 480-s(maxIndex).Centroid(2)]; % makes the resolution match that of the new background subtractor (8.6.11)
                        catch
                            xypts(a,:)=[5,5];
                        end
                        
                    end;
                    
                    if maxArea > 300 %normally the fly is not this big thus this means that reflection is merged with the real fly
                        
                        J =im2bw(I,0.2); %look for bright object to get rid of shade
                        K= bwareaopen(J,150); %look for bigger object to get rid of shade
                        L = imfill(J,'holes');
                        s = regionprops(L,{'Centroid', 'Area'});
                        A = [s.Area];
                        [maxArea, maxIndex] = max(A);
                        try
                            xypts(a,:) =[s(maxIndex).Centroid(1), 480-s(maxIndex).Centroid(2)];
                        catch
                            xypts(a,:)=[5,5];
                        end
                        
                        
                    end
                end
                clear I J K L s A;
                
            end
        end
        clear 'data.behaviorvideo';
        
        
    end
    xyzpts = NaN(endframe,3);
    xyzres = NaN(endframe,1);
    offsets = zeros(endframe,1);
    missed_frames = find(xypts ==5);
    missed_frames= missed_frames(1:length(missed_frames)/2);
    display(missed_frames);
    
    
    %WRITE NANS TO THE REST OF THE FILE!!
    xyptsname = [fname1string(1:end-4) '_xypts.csv'];
    csvwrite(xyptsname,xypts,1);
    
    xyzptsname = [fname1string(1:end-4) '_xyzpts.csv'];
    csvwrite(xyzptsname,xyzpts,1);
    
    xyzresname = [fname1string(1:end-4) '_xyzres.csv'];
    csvwrite(xyzresname,xyzres,1);
    
    offsetname = [fname1string(1:end-4) '_offsets.csv'];
    csvwrite(offsetname,offsets,1);
    
    
    close all;
    clear xypts xyzpts xyzres offsets;
    
end
end