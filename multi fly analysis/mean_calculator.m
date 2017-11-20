function [velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,velocity_i2o_ind_avg_af,...
    velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr,velocity_o2i_ind_avg_af,...
    velocity_i2o_avg,velocity_i2o_std,velocity_i2o_SEM,...
    velocity_o2i_avg,velocity_o2i_std,velocity_o2i_SEM,...
    velocity_i2o_avg_bf_sel,velocity_i2o_avg_dr_sel,velocity_i2o_avg_af_sel,...
    velocity_o2i_avg_bf_sel,velocity_o2i_avg_dr_sel,velocity_o2i_avg_af_sel,...
    velocity_i2o_avg_sel,velocity_i2o_std_sel,velocity_i2o_SEM_sel,...
    velocity_o2i_avg_sel,velocity_o2i_std_sel,velocity_o2i_SEM_sel,...
    flies_used,num_used_flies]...
    = mean_calculator(how_long,numflies,crossing_number_flies,crossing_min,...
    velocity_i2o_before_cell,velocity_i2o_during_cell,velocity_i2o_after_cell,...
    velocity_o2i_before_cell,velocity_o2i_during_cell,velocity_o2i_after_cell)
%This function outputs mean velocity of individual flies,std and SEM.
% velocity_i2o_avg etc includes all the flies
% velocity_i2o_avg_sel only includes flies that had crossings more than the
% crossing_min set


%pre-allocating the matrices
velocity_i2o_ind_avg_bf = nan(how_long,numflies);
velocity_i2o_ind_avg_dr= nan(how_long,numflies);
velocity_i2o_ind_avg_af= nan(how_long,numflies);
velocity_o2i_ind_avg_bf = nan(how_long,numflies);
velocity_o2i_ind_avg_dr = nan(how_long,numflies);
velocity_o2i_ind_avg_af = nan(how_long,numflies);

velocity_i2o_avg = nan(how_long,3);
velocity_o2i_avg = nan(how_long,3);

%calculate means at each frame excluding nans (mean of individual fly
%means), 
for fly=1:numflies
        velocity_i2o_ind_avg_bf(:,fly) = nanmean(velocity_i2o_before_cell{fly},2);
        velocity_i2o_ind_avg_dr(:,fly) = nanmean(velocity_i2o_during_cell{fly},2);
        velocity_i2o_ind_avg_af(:,fly) = nanmean(velocity_i2o_after_cell{fly},2);
        
        velocity_o2i_ind_avg_bf(:,fly) = nanmean(velocity_o2i_before_cell{fly},2);
        velocity_o2i_ind_avg_dr(:,fly) = nanmean(velocity_o2i_during_cell{fly},2);
        velocity_o2i_ind_avg_af(:,fly) = nanmean(velocity_o2i_after_cell{fly},2);
end

%then get the mean of means (individual flies' velocity means)
velocity_i2o_avg(:,1) = nanmean(velocity_i2o_ind_avg_bf,2);
velocity_i2o_avg(:,2) = nanmean(velocity_i2o_ind_avg_dr,2);
velocity_i2o_avg(:,3) = nanmean(velocity_i2o_ind_avg_af,2);

velocity_o2i_avg(:,1) = nanmean(velocity_o2i_ind_avg_bf,2);
velocity_o2i_avg(:,2) = nanmean(velocity_o2i_ind_avg_dr,2);
velocity_o2i_avg(:,3) = nanmean(velocity_o2i_ind_avg_af,2);

%std
velocity_i2o_std(:,1) = nanstd(velocity_i2o_ind_avg_bf,0,2);
velocity_i2o_std(:,2) = nanstd(velocity_i2o_ind_avg_dr,0,2);
velocity_i2o_std(:,3) = nanstd(velocity_i2o_ind_avg_af,0,2);

velocity_o2i_std(:,1) = nanstd(velocity_o2i_ind_avg_bf,0,2);
velocity_o2i_std(:,2) = nanstd(velocity_o2i_ind_avg_dr,0,2);
velocity_o2i_std(:,3) = nanstd(velocity_o2i_ind_avg_af,0,2);

%SEM
velocity_i2o_SEM = velocity_i2o_std/sqrt(numflies);
velocity_o2i_SEM = velocity_o2i_std/sqrt(numflies);

%In other set, exclude flies that entered the odor zone less than the
%pre-set minimum (crossing_min) (only in 'before' and 'during')
check = nan(1,numflies);
for fly=1:numflies
check(fly) = (min(crossing_number_flies(fly,1:2)) > crossing_min);
end
flies_used =  find(check); %which flies had more crossings than crossing_min?
%how many flies were used after the above crossing min condition?
num_used_flies = length(flies_used);

%Save different set of means that only select the 'flies_used'
velocity_i2o_avg_bf_sel = velocity_i2o_ind_avg_bf(:,flies_used);
velocity_i2o_avg_dr_sel = velocity_i2o_ind_avg_dr(:,flies_used);
velocity_i2o_avg_af_sel = velocity_i2o_ind_avg_af(:,flies_used);

velocity_o2i_avg_bf_sel = velocity_o2i_ind_avg_bf(:,flies_used);
velocity_o2i_avg_dr_sel = velocity_o2i_ind_avg_dr(:,flies_used);
velocity_o2i_avg_af_sel = velocity_o2i_ind_avg_af(:,flies_used);

%then get the mean of means (individual flies' velocity means)
velocity_i2o_avg_sel(:,1) = nanmean(velocity_i2o_avg_bf_sel,2);
velocity_i2o_avg_sel(:,2) = nanmean(velocity_i2o_avg_dr_sel,2);
velocity_i2o_avg_sel(:,3) = nanmean(velocity_i2o_avg_af_sel,2);

velocity_o2i_avg_sel(:,1) = nanmean(velocity_o2i_avg_bf_sel,2);
velocity_o2i_avg_sel(:,2) = nanmean(velocity_o2i_avg_dr_sel,2);
velocity_o2i_avg_sel(:,3) = nanmean(velocity_o2i_avg_af_sel,2);

%std
velocity_i2o_std_sel(:,1) = nanstd(velocity_i2o_avg_bf_sel,0,2);
velocity_i2o_std_sel(:,2) = nanstd(velocity_i2o_avg_dr_sel,0,2);
velocity_i2o_std_sel(:,3) = nanstd(velocity_i2o_avg_af_sel,0,2);

velocity_o2i_std_sel(:,1) = nanstd(velocity_o2i_avg_bf_sel,0,2);
velocity_o2i_std_sel(:,2) = nanstd(velocity_o2i_avg_dr_sel,0,2);
velocity_o2i_std_sel(:,3) = nanstd(velocity_o2i_avg_af_sel,0,2);

%SEM
velocity_i2o_SEM_sel = velocity_i2o_std_sel/sqrt(num_used_flies);
velocity_o2i_SEM_sel = velocity_o2i_std_sel/sqrt(num_used_flies);
