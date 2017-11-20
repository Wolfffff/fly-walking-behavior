function [vel_i2o_bin_mean,vel_o2i_bin_mean,vel_i2o_bin_SEM,vel_o2i_bin_SEM,...
    vel_i2o_by_bin_h,vel_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,...
    velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr)

%This function bins data according to the pre-set binEdges,etc and performs
% paired student's t-test to compare 'before' and 'during' data, and
% outputs the binned data means and t-test results (h=1: significant
% difference, p<0.05)

num_used_flies = size(velocity_i2o_ind_avg_bf,2);

%preallocate
bin_vel_i2o_bf = nan(numBins,num_used_flies);
bin_vel_i2o_dr = nan(numBins,num_used_flies);
bin_vel_o2i_bf = nan(numBins,num_used_flies);
bin_vel_o2i_dr = nan(numBins,num_used_flies);

for i=1:numBins
    flagBinMembers = (whichBin == i); %check each bin
    %i2o
    %before
    binMembers = velocity_i2o_ind_avg_bf(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_vel_i2o_bf(i,:) = binMean;
    
    %during
    binMembers = velocity_i2o_ind_avg_dr(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_vel_i2o_dr(i,:) = binMean;
    
    %o2i
    %before
    binMembers = velocity_o2i_ind_avg_bf(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_vel_o2i_bf(i,:) = binMean;
    %during
    binMembers = velocity_o2i_ind_avg_dr(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_vel_o2i_dr(i,:) = binMean;
end

%mean of binned data
vel_i2o_bin_mean(:,1) =  nanmean(bin_vel_i2o_bf,2);
vel_i2o_bin_mean(:,2) =  nanmean(bin_vel_i2o_dr,2);
vel_o2i_bin_mean(:,1) =  nanmean(bin_vel_o2i_bf,2);
vel_o2i_bin_mean(:,2) =  nanmean(bin_vel_o2i_dr,2);

%std of binned data
vel_i2o_bin_std(:,1) = nanstd(bin_vel_i2o_bf,0,2);
vel_i2o_bin_std(:,2) = nanstd(bin_vel_i2o_dr,0,2);
vel_o2i_bin_std(:,1) = nanstd(bin_vel_o2i_bf,0,2);
vel_o2i_bin_std(:,2) = nanstd(bin_vel_o2i_dr,0,2);

%SEM
vel_i2o_bin_SEM = vel_i2o_bin_std./(sqrt(num_used_flies));
vel_o2i_bin_SEM = vel_o2i_bin_std./(sqrt(num_used_flies));

%one sample, ttest
%pre-allocate
vel_i2o_by_bin_h = nan(1,numBins);
vel_i2o_by_bin_p = nan(1,numBins);
vel_i2o_by_bin_ci = nan(2,numBins);
vel_o2i_by_bin_h = nan(1,numBins);
vel_o2i_by_bin_p = nan(1,numBins);
vel_o2i_by_bin_ci = nan(2,numBins);

for i=1:numBins
    [h, p, ci] = ttest(bin_vel_i2o_bf(i,:),bin_vel_i2o_dr(i,:));
    vel_i2o_by_bin_h(i) = h;
    vel_i2o_by_bin_p(i) = p;
    vel_i2o_by_bin_ci(:,i) = ci;
    
    [h, p, ci] = ttest(bin_vel_o2i_bf(i,:),bin_vel_o2i_dr(i,:));
    vel_o2i_by_bin_h(i) = h;
    vel_o2i_by_bin_p(i) = p;
    vel_o2i_by_bin_ci(:,i) = ci;
end