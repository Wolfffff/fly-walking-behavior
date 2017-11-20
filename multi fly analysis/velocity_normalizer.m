function [vel_norm_o2i_avg,vel_norm_i2o_avg,vel_norm_o2i_SEM,vel_norm_i2o_SEM,...
    vel_o2i_norm_before_flies,vel_o2i_norm_during_flies,vel_o2i_norm_after_flies,...
    vel_i2o_norm_before_flies,vel_i2o_norm_during_flies,vel_i2o_norm_after_flies] =...
    velocity_normalizer(velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr,velocity_o2i_ind_avg_af,...
    velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,velocity_i2o_ind_avg_af,...
    frame_norm,numflies)
%normalization of velocity so that velocity right before crossing is similar
%get the average during 'frame_norm', then subtract this from original
%velocity
% exceptions: if there are only nans during 'frame_norm', this function
% will skip that specific crossing data


%frame_norm defines which time period to use to get the average
% frame_norm =((timebefore-2)*framespertimebin +1):((timebefore-1)*framespertimebin);

%use the individual fly average data, normalize individually then average them later

numRows =size(velocity_o2i_ind_avg_bf,1);
vel_o2i_norm_before_flies = nan(numRows,numflies);
vel_o2i_norm_during_flies = nan(numRows,numflies);
vel_o2i_norm_after_flies = nan(numRows,numflies);

vel_i2o_norm_before_flies = nan(numRows,numflies);
vel_i2o_norm_during_flies = nan(numRows,numflies);
vel_i2o_norm_after_flies = nan(numRows,numflies);

%out2in
p=1;q=1;r=1;
for i=1:numflies
    %get all the crossing data during 'frame_norm', and get the average
    before_norm_fly = (nanmean(velocity_o2i_ind_avg_bf(frame_norm,i)));
    if isnan(before_norm_fly) ==1 %if there is no data during 'frame_norm'
        vel_o2i_norm_before_flies(:,p) = velocity_o2i_ind_avg_bf(:,i); %don't normalize
    else
        vel_o2i_before_fly = velocity_o2i_ind_avg_bf(:,i); %individual fly mean
        vel_o2i_norm_before_fly = vel_o2i_before_fly - before_norm_fly;%subtract the average
        vel_o2i_norm_before_flies(:,p) = vel_o2i_norm_before_fly;
    end
    p=p+1;
    
    during_norm_fly = (nanmean(velocity_o2i_ind_avg_dr(frame_norm,i)));
    if isnan(during_norm_fly) ==1 %if there is no data during 'frame_norm'
        vel_o2i_norm_during_flies(:,q) = velocity_o2i_ind_avg_dr(:,i); %don't normalize
    else
        vel_o2i_during_fly = velocity_o2i_ind_avg_dr(:,i);
        vel_o2i_norm_during_fly = vel_o2i_during_fly - during_norm_fly;%subtract the average
        vel_o2i_norm_during_flies(:,q) = vel_o2i_norm_during_fly;
    end
    q=q+1;
    
    after_norm_fly = (nanmean(velocity_o2i_ind_avg_af(frame_norm,i)));
    if isnan(after_norm_fly) ==1 %if there is no data during 'frame_norm'
        vel_o2i_norm_after_flies(:,r) = velocity_o2i_ind_avg_af(:,i); %don't normalize
    else
        vel_o2i_after_fly = velocity_o2i_ind_avg_af(:,i);
        vel_o2i_norm_after_fly = vel_o2i_after_fly - after_norm_fly;%subtract the average
        vel_o2i_norm_after_flies(:,r) = vel_o2i_norm_after_fly;
    end
    r=r+1;
end

%In2Out
p=1;q=1;r=1;

for i=1:numflies
    %get all the crossing data during 'frame_norm', and get the average
    before_norm_fly = (nanmean(velocity_i2o_ind_avg_bf(frame_norm,i)));
    if isnan(before_norm_fly) ==1 %if there is no data during 'frame_norm'
        vel_i2o_norm_before_flies(:,p) = velocity_i2o_ind_avg_bf(:,i); %don't normalize
    else
        vel_i2o_before_fly = velocity_i2o_ind_avg_bf(:,i); %individual fly mean
        vel_i2o_norm_before_fly = vel_i2o_before_fly - before_norm_fly;%subtract the average
        vel_i2o_norm_before_flies(:,p) = vel_i2o_norm_before_fly;
    end
    p=p+1;
    
    during_norm_fly = (nanmean(velocity_i2o_ind_avg_dr(frame_norm,i)));
    if isnan(during_norm_fly) ==1 %if there is no data during 'frame_norm'
        vel_i2o_norm_during_flies(:,q) = velocity_i2o_ind_avg_dr(:,i); %don't normalize
    else
        vel_i2o_during_fly = velocity_i2o_ind_avg_dr(:,i);
        vel_i2o_norm_during_fly = vel_i2o_during_fly - during_norm_fly;%subtract the average
        vel_i2o_norm_during_flies(:,q) = vel_i2o_norm_during_fly;
    end
    q=q+1;
    
    after_norm_fly = (nanmean(velocity_i2o_ind_avg_af(frame_norm,i)));
    if isnan(after_norm_fly) ==1 %if there is no data during 'frame_norm'
        vel_i2o_norm_after_flies(:,r) = velocity_i2o_ind_avg_af(:,i); %don't normalize
    else
        vel_i2o_after_fly = velocity_i2o_ind_avg_af(:,i);
        vel_i2o_norm_after_fly = vel_i2o_after_fly - after_norm_fly;%subtract the average
        vel_i2o_norm_after_flies(:,r) = vel_i2o_norm_after_fly;
    end
    r=r+1;
end

%get across flies average after normalization
vel_norm_o2i_avg = nanmean(vel_o2i_norm_before_flies,2);
vel_norm_o2i_avg(:,2) = nanmean(vel_o2i_norm_during_flies,2);
vel_norm_o2i_avg(:,3) = nanmean(vel_o2i_norm_after_flies,2);

vel_norm_i2o_avg = nanmean(vel_i2o_norm_before_flies,2);
vel_norm_i2o_avg(:,2) = nanmean(vel_i2o_norm_during_flies,2);
vel_norm_i2o_avg(:,3) = nanmean(vel_i2o_norm_after_flies,2);

%get Standard error of means
%OUt2IN
vel_norm_o2i_SD = (nanstd(vel_o2i_norm_before_flies,0,2)); %std first
vel_norm_o2i_SD(:,2) = (nanstd(vel_o2i_norm_during_flies,0,2));
vel_norm_o2i_SD(:,3) = (nanstd(vel_o2i_norm_after_flies,0,2));

%In2Out
vel_norm_i2o_SD = (nanstd(vel_i2o_norm_before_flies,0,2));
vel_norm_i2o_SD(:,2) = (nanstd(vel_i2o_norm_during_flies,0,2));
vel_norm_i2o_SD(:,3) = (nanstd(vel_i2o_norm_after_flies,0,2));

%SEM
vel_norm_o2i_SEM = vel_norm_o2i_SD/sqrt(numflies); %SEM
vel_norm_i2o_SEM = vel_norm_i2o_SD/sqrt(numflies); %SEM

