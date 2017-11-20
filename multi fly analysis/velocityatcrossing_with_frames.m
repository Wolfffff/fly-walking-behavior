function [velocity_in2out_before,velocity_in2out_during,velocity_in2out_after,...
    velocity_out2in_before,velocity_out2in_during,velocity_out2in_after...
    crossing_i2o_frames_bf,crossing_i2o_frames_dr,crossing_i2o_frames_af,...
    crossing_o2i_frames_bf,crossing_o2i_frames_dr,crossing_o2i_frames_af]...
    = velocityatcrossing_with_frames(fig_title,crossing_in_before,crossing_in_during,...
    crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
    vel_total,framespertimebin, timeperiods, timebefore, totaltime)

% saves velocity at crossing from -'timebefore' sec before crossing for
% 'totaltime' (sec)
% This function should work for all other velocity calculations such as
% rad_vel, rad_vel_sqrt, velocity_classified, run_stop etc.
%just replace vel_total with other variable

%OUTPUT VARIABLES
% velocity_in2out_before/during/after: original velocity at crosssing in2out
% crossing_i2o_frames_bf/dr/af: frame# for crossings used in this function

%% Use this part to load variables from file to test function
% clear all;
% load('120605video35 w1118_ACV-4 V10 variables.mat','fig_title','crossing_in_before','crossing_in_during',...
%     'crossing_in_after', 'crossing_out_before','crossing_out_during','crossing_out_after',...
%     'vel_total','framespertimebin', 'timeperiods', 'cmap','vel_unit');
% timebefore =2;
% totaltime= 5;
% color = [0 1 0 ; 1 0 0; 0 0 1];
%%
timeperiods(4) = length(vel_total);
% filename = fig_title;

crossing_in_cell = {crossing_in_before; crossing_in_during; crossing_in_after};
crossing_out_cell = {crossing_out_before; crossing_out_during; crossing_out_after};

%to avoid errors that occur when there is no crossing======================
period_1 =1;
period_2 =3;

if isempty(crossing_in_before) == 1 %no crossing in 'before'
    period_1 = 2; %skip 'before' period
    display([fig_title ' There is no crossing in the before period']);
    
elseif isempty(crossing_in_after) ==1 %no crossing in 'after'
    period_2 = 2; %skip 'after' period
    display([fig_title ' There is no crossing in the after period']);
end


%==========================================================================
period_name ={'Before','During','After'};

%decides how many crossings in/out in each period
for a = 1:3
    b(a) = length(crossing_in_cell{a});
    c(a) = length(crossing_out_cell{a});
end

lengthin = max(b); %find the timeperiod with the most crossings
lengthout= max(c);

velocitytoplot_out2in = cell(3,lengthin);
velocitytoplot_in2out = cell(3,lengthout);

notreal_out = zeros(1,3); %to decide whether some crossing in or out is real

crossing_o2i_frames = cell(3,1);
crossing_i2o_frames = cell(3,1);

%% %make crossing-in the first crossing event ================================
%for example
%if it is [out in out in out], this will change it to [in out in out]
%if it is [in out in out in ], this will add out so that crossing will be
%[in out in out in out]

for period = period_1:period_2 %each odor period (only the ones with at least one crossing event)
    if isempty(crossing_out_cell{period})==1 %if there is no crossing out, make the end of that period as crossing out
        crossing_out_cell{period}(1) = timeperiods(period+1);
        notreal_out(period) = 1;%mark that this crossing out was added
        
    else %if there is at least one crossing out event,
        
        if crossing_in_cell{period,1}(1) < crossing_out_cell{period,1}(1);
            display ([fig_title ' ' period_name{period} '; fly is going in first'])
            if numel(crossing_in_cell{period}) > numel(crossing_out_cell{period}); %if fly is inside at the end of period
                crossing_out_cell{period}(end+1) = timeperiods(period+1);
                display ('make crossing out time the end of the odorperiod')
                notreal_out(period) = 1;%mark that this crossing out was added
            end
            
        else %if fly was inside and crossed out
            display([fig_title ' ' period_name{period} ': fly is coming out first']);
            crossing_out_cell{period,1}(1) = [];
            display('remove first crossing out')
            if numel(crossing_in_cell{period}) > numel(crossing_out_cell{period})
                crossing_out_cell{period}(end+1)= timeperiods(period+1);
                display('making crossing out time the end of the odorperiod');
            end
        end
    end
    %======================================================================
    %%
    %out2in events first=======================================================
    
    %for the very first crossing out2in in 'before' period
    if isempty(crossing_in_before) == 0 
        if crossing_in_before(1) < timebefore*framespertimebin+1 %if there is less than timebefore sec before the first crossing in the before period
            %first pre-allocate the matrix so that the crossing frame is at
            %for 'timebefore' frames
            velocitytoplot_out2in{1,1} = nan((crossing_out_cell{1,1}(1)-crossing_in_cell{1,1}(1)+timebefore*framespertimebin),1);
            %then add the values
            velocitytoplot_out2in{1,1}(((timebefore*framespertimebin)-crossing_in_before(1)+2):end,1) =...
                vel_total(1:(crossing_out_cell{1}(1))-1);
            
            %         save which frames I used to get the velocity
            crossing_o2i_frames{1,1} = 1:(crossing_out_cell{1}(1))-1;
            
            
        else %if there is longer than 10 sec before the first crossing in
            velocitytoplot_out2in{1,1} =...
                vel_total((crossing_in_cell{1}(1))-(timebefore*framespertimebin):(crossing_out_cell{1}(1))-1);
            
            %save which frames I used to get the velocity
            crossing_o2i_frames{1,1} = (crossing_in_cell{1}(1))-(timebefore*framespertimebin):(crossing_out_cell{1}(1))-1;
            
        end
    end
    
    
    %for the first crossing in other periods
    if period > 1
        if isempty(crossing_out_cell{period-1}) == 0 %if there was any crossing out 'before'
            if crossing_in_cell{period}(1)-(crossing_out_cell{period-1}(end))<(timebefore*framespertimebin)
                %if timebefore seconds before the crossing in is before the last crossing out
                
                frames_after = crossing_out_cell{period}(1)-(crossing_in_cell{period}(1))-1; %determine how many frames after crossing
                velocitytoplot_out2in{period, 1} = nan(frames_after+(timebefore*framespertimebin),1);%create the empty vector
                
                nannumber = timebefore*framespertimebin- (crossing_in_cell{period}(1)-(crossing_out_cell{period-1}(end)));%how many nans will it take to make this vector the same length?
                velocitytoplot_out2in{period, 1}(nannumber:end,1)...
                    = vel_total((crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1); %just take the portion that is outside
                
                %save which frames I used to get the velocity
                crossing_o2i_frames{period,1} = (crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1;
                
            else
                velocitytoplot_out2in{period, 1} =...
                    vel_total((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));
                
                %save which frames I used to get the velocity
                crossing_o2i_frames{period,1} = (crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1);
                
                
            end
        else %if there was no crossins in 'before'
            velocitytoplot_out2in{period, 1} =...
                vel_total((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));
            
            %save which frames I used to get the velocity
            crossing_o2i_frames{period,1} = (crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1);
            
        end
    end
    
    %for second crossing and afterwards====================================
    for h = 2:length(crossing_in_cell{period});
        
        if crossing_in_cell{period}(h)-crossing_out_cell{period}(h-1) < (timebefore*framespertimebin) %if 2 seconds before the crossing in is before the last crossing out
            frames_after = crossing_out_cell{period}(h)-crossing_in_cell{period}(h);
            velocitytoplot_out2in{period, h} = nan(frames_after+(timebefore*framespertimebin),1);
            nannumber = timebefore*framespertimebin- (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h-1)));%how many nans will it take to make this vector the same length?
            velocitytoplot_out2in{period, h}(nannumber+1:end,1)...
                = vel_total((crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1)); %just take the portion that is outside
            
            %save which frames I used to get the velocity
            crossing_o2i_frames{period,h} = (crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1);
            
        else
            velocitytoplot_out2in{period, h} =...
                vel_total((crossing_in_cell{period}(h))-(timebefore*framespertimebin):(crossing_out_cell{period}(h)-1));
            %save which frames I used to get the velocity
            crossing_o2i_frames{period,h} = (crossing_in_cell{period}(h))-(timebefore*framespertimebin):(crossing_out_cell{period}(h)-1);
            
        end
    end
    
    %%
    %for in2out events====================================================
    
    for h = 1:length(crossing_in_cell{period})-1;
        if crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)) < (timebefore*framespertimebin) ;
            %if timebefore seconds before the crossing out is before the last crossing in
            frames_after = crossing_in_cell{period}(h+1)-crossing_out_cell{period}(h);
            velocitytoplot_in2out{period, h} = nan(frames_after+(timebefore*framespertimebin),1);
            
            nannumber = timebefore*framespertimebin- (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)));%how many nans will it take to make this vector the same length?
            velocitytoplot_in2out{period, h}(nannumber+1:end,1)...
                = vel_total((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside
            
            %save which frames I used to get the velocity
            crossing_i2o_frames{period,h} = (crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1);
            
        else
            velocitytoplot_in2out{period, h} =...
                vel_total((crossing_out_cell{period}(h))-(timebefore*framespertimebin):((crossing_in_cell{period}(h+1)-1)));
            
            %save which frames I used to get the velocity
            crossing_i2o_frames{period,h} = (crossing_out_cell{period}(h))-(timebefore*framespertimebin):((crossing_in_cell{period}(h+1)-1));
        end
    end
    
   
    if notreal_out(period) == 0 %do the following only when last crossing_out is real crossing
        %for the last in2out crossing
        if length(crossing_out_cell{period}) == 1; %only one crossing
            if crossing_out_cell{period}(end)-crossing_in_cell{period}(end) < (timebefore*framespertimebin)  ; %there is less than timebefore sec before last crossing out and period end
                frames_after = timeperiods(period+1)-crossing_out_cell{period}(1);
                velocitytoplot_in2out{period, 1} = nan(frames_after+(timebefore*framespertimebin),1);
                nannumber = timebefore*framespertimebin- (crossing_out_cell{period}(end)-crossing_in_cell{period}(end));%how many nans will it take to make this vector the same length?
                
                velocitytoplot_in2out{period, 1}(nannumber+1:end,1)...
                    = vel_total((crossing_in_cell{period}(end)):(timeperiods(period+1)-1)); %just take the portion that is outside
                
                crossing_i2o_frames{period,1}=(crossing_in_cell{period}(end)):(timeperiods(period+1)-1);
                
            else %only one crossing, more than 'timebefore' -long data before crossing
                velocitytoplot_in2out{period, 1} =...
                    vel_total((crossing_out_cell{period}(end))-(timebefore*framespertimebin):(timeperiods(period+1)-1));
                
                %save which frames I used to get the velocity
                crossing_i2o_frames{period,1}=(crossing_out_cell{period}(end))-(timebefore*framespertimebin):(timeperiods(period+1)-1);
                
            end
        else %more than one crossing
            if crossing_out_cell{period}(end)-(timebefore*framespertimebin) < crossing_in_cell{period}(end); %there is less than timebefore sec before last crossing out and period end
                frames_after = timeperiods(period+1)-crossing_out_cell{period}(end);
                velocitytoplot_in2out{period, h+1} = nan(frames_after+(timebefore*framespertimebin),1);
                nannumber = timebefore*framespertimebin- (crossing_out_cell{period}(end)-crossing_in_cell{period}(end));%how many nans will it take to make this vector the same length?
                
                velocitytoplot_in2out{period, h+1}(nannumber+1:end,1)...
                    = vel_total((crossing_in_cell{period}(end)):timeperiods(period+1)-1); %just take the portion that is outside
                
                %save which frames I used to get the velocity
                crossing_i2o_frames{period,h+1}=(crossing_in_cell{period}(end)):timeperiods(period+1);
                
            else
                velocitytoplot_in2out{period, h+1} =...
                    (vel_total((crossing_out_cell{period}(end))-(timebefore*framespertimebin):timeperiods(period+1)));
                %save which frames I used to get the velocity
                crossing_i2o_frames{period,h+1}=(crossing_out_cell{period}(end))-(timebefore*framespertimebin):timeperiods(period+1);
                
            end
        end
    end
end
%%
%deleting the empty elements in the cell array
for i=1:3
    new_array = {crossing_i2o_frames{i,:}};
    new_array2 = new_array(~cellfun('isempty',new_array));
    if i==1
        crossing_i2o_frames_bf = new_array2;
    elseif i==2
        crossing_i2o_frames_dr = new_array2;
    else
        crossing_i2o_frames_af = new_array2;
    end
    
    new_array = {crossing_o2i_frames{i,:}};
    new_array2 = new_array(~cellfun('isempty',new_array));
    if i==1
        crossing_o2i_frames_bf = new_array2;
    elseif i==2
        crossing_o2i_frames_dr = new_array2;
    else
        crossing_o2i_frames_af = new_array2;
    end
    
end

%% clean up velocitytoplot, get rid of empty cells
%before
velocitytoplot_in2out_before = velocitytoplot_in2out(1,:);
vel_i2o_before = velocitytoplot_in2out_before(~cellfun('isempty',velocitytoplot_in2out_before));

velocitytoplot_out2in_before = velocitytoplot_out2in(1,:);
vel_o2i_before = velocitytoplot_out2in_before(~cellfun('isempty',velocitytoplot_out2in_before));

%during
velocitytoplot_in2out_during = velocitytoplot_in2out(2,:);
vel_i2o_during = velocitytoplot_in2out_during(~cellfun('isempty',velocitytoplot_in2out_during));

velocitytoplot_out2in_during = velocitytoplot_out2in(2,:);
vel_o2i_during = velocitytoplot_out2in_during(~cellfun('isempty',velocitytoplot_out2in_during));

%after
velocitytoplot_in2out_after = velocitytoplot_in2out(3,:);
vel_i2o_after = velocitytoplot_in2out_after(~cellfun('isempty',velocitytoplot_in2out_after));

velocitytoplot_out2in_after = velocitytoplot_out2in(3,:);
vel_o2i_after = velocitytoplot_out2in_after(~cellfun('isempty',velocitytoplot_out2in_after));


%%
%in2out: copy everything to double array

%pre-allocate
nb1 = length(vel_i2o_before);
velocity_in2out_before = nan(totaltime*framespertimebin,nb1);
nb2 = length(vel_o2i_before);
velocity_out2in_before = nan(totaltime*framespertimebin,nb2);

nd1 = length(vel_i2o_during);
velocity_in2out_during = nan(totaltime*framespertimebin,nd1);
nd2 = length(vel_o2i_during);
velocity_out2in_during = nan(totaltime*framespertimebin,nd2);

na1 = length(vel_i2o_after);
velocity_in2out_after = nan(totaltime*framespertimebin,na1);
na2 = length(vel_o2i_after);
velocity_out2in_after = nan(totaltime*framespertimebin,na2);

%in case the vector is empty just make an nan vector to prevent a bug later
if nb1 == 0; nb1=1; vel_i2o_before{1,1}=nan(totaltime*framespertimebin,1); end
if nb2 == 0; nb2=1; vel_o2i_before{1,1}=nan(totaltime*framespertimebin,1); end
if nd1 == 0; nd1=1; vel_i2o_during{1,1}=nan(totaltime*framespertimebin,1);end
if nd2 == 0; nd2=1; vel_o2i_during{1,1}=nan(totaltime*framespertimebin,1);end
if na1 == 0; na1=1; vel_i2o_after{1,1}=nan(totaltime*framespertimebin,1);end
if na2 == 0; na2=1; vel_o2i_after{1,1}=nan(totaltime*framespertimebin,1);end
   
%before
for n=1:nb1
    %in2out
    if length(vel_i2o_before{1,n}) >= totaltime*framespertimebin
        velocity_in2out_before(1:totaltime*framespertimebin,n) = vel_i2o_before{1,n}(1:totaltime*framespertimebin,:);        
    else
        velocity_in2out_before(1:length(vel_i2o_before{1,n}),n) = vel_i2o_before{1,n};       
    end
end

for n=1:nb2
    %out2in
    if length(vel_o2i_before{1,n}) >= totaltime*framespertimebin
        velocity_out2in_before(1:totaltime*framespertimebin,n) = vel_o2i_before{1,n}(1:totaltime*framespertimebin,:);        
    else
        velocity_out2in_before(1:length(vel_o2i_before{1,n}),n) = vel_o2i_before{1,n};
    end
end
vel_i2o_avg(:,1) = nanmean(velocity_in2out_before,2);
vel_o2i_avg(:,1) = nanmean(velocity_out2in_before,2);

%during
for n=1:nd1
    %in2out
    if length(vel_i2o_during{1,n}) >= totaltime*framespertimebin
        velocity_in2out_during(1:totaltime*framespertimebin,n) = vel_i2o_during{1,n}(1:totaltime*framespertimebin,:);        
    else
        velocity_in2out_during(1:length(vel_i2o_during{1,n}),n) = vel_i2o_during{1,n};
        
    end
end

for n=1:nd2
    %out2in
    if length(vel_o2i_during{1,n}) >= totaltime*framespertimebin
        velocity_out2in_during(1:totaltime*framespertimebin,n) = vel_o2i_during{1,n}(1:totaltime*framespertimebin,:);
    else
        velocity_out2in_during(1:length(vel_o2i_during{1,n}),n) = vel_o2i_during{1,n};      
    end
end
vel_i2o_avg(:,2) = nanmean(velocity_in2out_during,2);
vel_o2i_avg(:,2) = nanmean(velocity_out2in_during,2);

%after
for n=1:na1
    %in2out
    if length(vel_i2o_after{1,n}) >= totaltime*framespertimebin
        velocity_in2out_after(1:totaltime*framespertimebin,n) = vel_i2o_after{1,n}(1:totaltime*framespertimebin,:);        
    else
        velocity_in2out_after(1:length(vel_i2o_after{1,n}),n) = vel_i2o_after{1,n};        
    end
end

for n=1:na2
    %out2in
    if length(vel_o2i_after{1,n}) >= totaltime*framespertimebin
        velocity_out2in_after(1:totaltime*framespertimebin,n) = vel_o2i_after{1,n}(1:totaltime*framespertimebin,:);       
    else
        velocity_out2in_after(1:length(vel_o2i_after{1,n}),n) = vel_o2i_after{1,n};        
    end
end

vel_i2o_avg(:,3)= nanmean(velocity_in2out_after,2);
vel_o2i_avg(:,3) = nanmean(velocity_out2in_after,2);

%if there is no crossing, then make nan vectors for that period
if period_1 == 2 %no crossing in the before period
    velocity_in2out_before = nan(totaltime*framespertimebin,1);
    velocity_out2in_before = nan(totaltime*framespertimebin,1);
end
if period_2 ==2 % no crossing in the 'after' period
    velocity_in2out_after = nan(totaltime*framespertimebin,1);
    velocity_out2in_after = nan(totaltime*framespertimebin,1);
end
%% Uncomment this part to test the function!
% %to plot the outputs
% %average: MEDIAN
% velocity_i2o_avg(:,1) = nanmedian(velocity_in2out_before,2);
% velocity_i2o_avg(:,2) = nanmedian(velocity_in2out_during,2);
% velocity_i2o_avg(:,3) = nanmedian(velocity_in2out_after,2);
% 
% velocity_o2i_avg(:,1) = nanmedian(velocity_out2in_before,2);
% velocity_o2i_avg(:,2) = nanmedian(velocity_out2in_during,2);
% velocity_o2i_avg(:,3) = nanmedian(velocity_out2in_after,2);
% 
% velocity_i2o_std = nan(length(velocity_o2i_avg),3);
% velocity_o2i_std = nan(length(velocity_o2i_avg),3);
% 
% velocity_i2o_std(:,1) = nanstd(velocity_in2out_before,0,2);
% velocity_i2o_std(:,2) = nanstd(velocity_in2out_during,0,2);
% velocity_i2o_std(:,3) = nanstd(velocity_in2out_after,0,2);
% 
% velocity_o2i_std(:,1) = nanstd(velocity_out2in_before,0,2);
% velocity_o2i_std(:,2) = nanstd(velocity_out2in_during,0,2);
% velocity_o2i_std(:,3) = nanstd(velocity_out2in_after,0,2);
% 
% figure
% set(gcf,'color','white','Position',[520 20 700 800]);
% 
% period_name = {'Before','During','After'};
% x_range_min = -timebefore;
% x_range_max = totaltime - timebefore;
% x_range = x_range_min:1/30:x_range_max-1/30;
% 
% %for crossing out2in
% %before
% subplot(4,2,1)
% for h = 1:size(velocity_out2in_before,2);
%     p = rem(h,20)+1;
%     plot (x_range,velocity_out2in_before(:,h) ,'color', cmap(p,:))
%     hold on
%     plot(x_range,velocity_o2i_avg(:,1),'linewidth',2);
%     plot([0 0],[0 2],'k:') %dotted line marking 0
%     
%     xlim([x_range_min x_range_max]);
%     ylim ([0 2])
%     title(['Crossing in: ' period_name{1}],'fontsize',9);
% 
%     %     xlabel('frame number','fontsize',9);
%     ylabel(vel_unit,'fontsize',9);
%     set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);
% end
% 
% %during
% subplot(4,2,3)
% for h = 1:size(velocity_out2in_during,2);
%     p = rem(h,20)+1;
%     plot (x_range,velocity_out2in_during(:,h) ,'color', cmap(p,:))
%     hold on
%     plot(x_range,velocity_o2i_avg(:,2),'linewidth',2);
%     
%     plot([0 0],[0 2],'k:') %dotted line marking 0
%     xlim([x_range_min x_range_max]);
%     ylim ([0 2])
%     title(['Crossing in: ' period_name{2}],'fontsize',9);
%     %     xlabel('frame number','fontsize',9);
%     ylabel(vel_unit,'fontsize',9);
%     set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);
% end
% 
% %after
% subplot(4,2,5)
% for h = 1:size(velocity_out2in_after,2);
%     p = rem(h,20)+1;
%     
%     plot (x_range,velocity_out2in_after(:,h) ,'color', cmap(p,:))
%     hold on
%     plot(x_range,velocity_o2i_avg(:,3),'linewidth',2);
%         plot([0 0],[0 2],'k:') %dotted line marking 0    
% 
%     xlim([x_range_min x_range_max]);
%     ylim ([0 2])
%     title(['Crossing in: ' period_name{3}],'fontsize',9);
%     %     xlabel('frame number','fontsize',9);
%     ylabel(vel_unit,'fontsize',9);
%     set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);
% end
% 
% %for crossing in2out:
% %before
% subplot(4,2,2)
% for h = 1:size(velocity_in2out_before,2)
%     p = rem(h,20)+1;
%     plot (x_range,velocity_in2out_before(:,h) ,'color', cmap(p,:))
%     hold on
%     plot(x_range,velocity_i2o_avg(:,1),'linewidth',2);
%     xlim([x_range_min x_range_max]);
%     ylim ([0 2])
%     plot([0 0],[0 2],'k:') %dotted line marking 0    
%     title(['Crossing out: ' period_name{1}],'fontsize',9);
%     %     xlabel('frame number','fontsize',9);
%     ylabel(vel_unit,'fontsize',9);
%     set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);
%     
% end
% 
% %during
% subplot(4,2,4)
% for h = 1:size(velocity_in2out_during,2)
%     p = rem(h,20)+1;
%     plot (x_range,velocity_in2out_during(:,h) ,'color', cmap(p,:))
%     hold on
%     plot(x_range,velocity_i2o_avg(:,2),'linewidth',2);
%     xlim([x_range_min x_range_max]);
%     ylim ([0 2])
%     plot([0 0],[0 2],'k:') %dotted line marking 0    
%     title(['Crossing out: ' period_name{2}],'fontsize',9);
%     %     xlabel('frame number','fontsize',9);
%     ylabel(vel_unit,'fontsize',9);
%     set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);
%     
% end
% 
% %after
% subplot(4,2,6)
% for h = 1:size(velocity_in2out_after,2)
%     p = rem(h,20)+1;
%     plot (x_range,velocity_in2out_after(:,h) ,'color', cmap(p,:))
%     hold on
%     plot(x_range,velocity_i2o_avg(:,3),'linewidth',2);
%     xlim([x_range_min x_range_max]);
%     ylim ([0 2])
%     plot([0 0],[0 2],'k:') %dotted line marking 0    
%     title(['Crossing out: ' period_name{3}],'fontsize',9);
%     %     xlabel('frame number','fontsize',9);
%     ylabel(vel_unit,'fontsize',9);
%     set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);
%     
% end
% 
% 
% 
% subplot(4,2,7)
% for i=1:3
%     plot(x_range,velocity_o2i_avg(:,i),'color',color(i,:),'linewidth',2);hold on
% end
% xlim([x_range_min x_range_max]);
% ylim ([0 1.5])
% plot([0 0],[0 2],'k:') %dotted line marking 0
% title(['Crossing In: Mean'],'fontsize',9);
% %     xlabel('frame number','fontsize',9);
% ylabel(vel_unit,'fontsize',9);
% set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);
% 
% subplot(4,2,8)
% 
% for i=1:3
%     plot(x_range,velocity_i2o_avg(:,i),'color',color(i,:),'linewidth',2);hold on
% end
% xlim([x_range_min x_range_max]);
% ylim ([0 1.5])
% plot([0 0],[0 2],'k:') %dotted line marking 0
% title(['Crossing out: Mean'],'fontsize',9);
% %     xlabel('frame number','fontsize',9);
% ylabel(vel_unit,'fontsize',9);
% set(gca,'Box','off','Xtick',(-10:1:10),'fontsize',8);