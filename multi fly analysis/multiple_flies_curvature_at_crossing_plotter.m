%multiple_flies_curvature_at_crossing_plotter.m


% calculate average of curvature at crossing

% 'mean_calculator' outputs mean curvature of individual flies,std and SEM.
% curv_i2o_avg etc includes all the flies
% curv_i2o_avg_sel only includes flies that had crossings more than the
% crossing_min set
[curv_i2o_ind_avg_bf,curv_i2o_ind_avg_dr,curv_i2o_ind_avg_af,...
    curv_o2i_ind_avg_bf,curv_o2i_ind_avg_dr,curv_o2i_ind_avg_af,...
    curv_i2o_avg,curv_i2o_std,curv_i2o_SEM,...
    curv_o2i_avg,curv_o2i_std,curv_o2i_SEM,...
    curv_i2o_avg_bf_sel,curv_i2o_avg_dr_sel,curv_i2o_avg_af_sel,...
    curv_o2i_avg_bf_sel,curv_o2i_avg_dr_sel,curv_o2i_avg_af_sel,...
    curv_i2o_avg_sel,curv_i2o_std_sel,curv_i2o_SEM_sel,...
    curv_o2i_avg_sel,curv_o2i_std_sel,curv_o2i_SEM_sel,...
    flies_used,num_used_flies]...
    = mean_calculator(how_long,numflies,crossing_number_flies,crossing_min,...
    curv_i2o_cell(1,:),curv_i2o_cell(2,:),curv_i2o_cell(3,:),...
    curv_o2i_cell(1,:),curv_o2i_cell(2,:),curv_o2i_cell(3,:));

% bin data and run t-test between 'before' and 'during'
numBins = 30; %how many bins? if there are 150 frames, 5 frames/bin
topEdge = timetotal*framespertimebin; %define limits
botEdge = 1; %define limits

binEdges = linspace(botEdge,topEdge,numBins); %define edges of bins

[h,whichBin] = histc([botEdge:topEdge],binEdges); %do histc to bin x or frame#
% binMean = nan(numflies,numBins); %pre-allocate to save mean of each bin


%'bin_ttest'; bins data according to the pre-set binEdges,etc and performs
% paired student's t-test to compare 'before' and 'during' data, and
% outputs the binned data means and t-test results (h=1: significant
% difference, p<0.05)

%whole fly group
[curv_i2o_bin_mean,curv_o2i_bin_mean,curv_i2o_bin_SEM,curv_o2i_bin_SEM,...
    curv_i2o_by_bin_h,curv_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    curv_i2o_ind_avg_bf,curv_i2o_ind_avg_dr,...
    curv_o2i_ind_avg_bf,curv_o2i_ind_avg_dr);

%%
%ACTUAL FIGURES
%==========================================================================
% 1. duration : plots ind fly mean plots (before /during), group
% mean plot, binned mean with t-test results
% 2. velocity_normalizer : normalize the curvature data
% 3. bin_ttest : binning + t-test
% 4. velocity_multiplots2: plots normalized group means, binned+t-test results
%==========================================================================

curv_ylim = [-2 2];
curv_unit = 'curvature';

plots_row = 4;
plots_column = 2;
figure_title = [fig_title ' curvature at crossing (all the flie)'];

%plots the first four rows of subplots
velocity_multiplots1(curv_o2i_ind_avg_bf,curv_o2i_ind_avg_dr,...
    curv_o2i_ind_avg_af,curv_i2o_ind_avg_bf,curv_i2o_ind_avg_dr,...
    curv_i2o_ind_avg_af,curv_o2i_avg,curv_i2o_avg,curv_o2i_SEM,...
    curv_i2o_SEM,curv_o2i_bin_mean,curv_i2o_bin_mean,...
    curv_o2i_bin_SEM,curv_i2o_bin_SEM,...
    curv_o2i_by_bin_h,curv_i2o_by_bin_h,...
    framespertimebin,how_long,x_range,bin_x,curv_unit,curv_ylim,crossing_min,numBins,...
    plots_row,plots_column);


ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
% fig_count = fig_count+1; saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
% print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%% calculate average of curvature at crossing (absolute values)

% 'mean_calculator' outputs mean curvature of individual flies,std and SEM.
% curv_i2o_avg etc includes all the flies
% curv_i2o_avg_sel only includes flies that had crossings more than the
% crossing_min set
[curv_abs_i2o_ind_avg_bf,curv_abs_i2o_ind_avg_dr,curv_abs_i2o_ind_avg_af,...
    curv_abs_o2i_ind_avg_bf,curv_abs_o2i_ind_avg_dr,curv_abs_o2i_ind_avg_af,...
    curv_abs_i2o_avg,curv_abs_i2o_std,curv_abs_i2o_SEM,...
    curv_abs_o2i_avg,curv_abs_o2i_std,curv_abs_o2i_SEM,...
    curv_abs_i2o_avg_bf_sel,curv_abs_i2o_avg_dr_sel,curv_abs_i2o_avg_af_sel,...
    curv_abs_o2i_avg_bf_sel,curv_abs_o2i_avg_dr_sel,curv_abs_o2i_avg_af_sel,...
    curv_abs_i2o_avg_sel,curv_abs_i2o_std_sel,curv_abs_i2o_SEM_sel,...
    curv_abs_o2i_avg_sel,curv_abs_o2i_std_sel,curv_abs_o2i_SEM_sel,...
    flies_used,num_used_flies]...
    = mean_calculator(how_long,numflies,crossing_number_flies,crossing_min,...
    curv_abs_i2o_cell(1,:),curv_abs_i2o_cell(2,:),curv_abs_i2o_cell(3,:),...
    curv_abs_o2i_cell(1,:),curv_abs_o2i_cell(2,:),curv_abs_o2i_cell(3,:));

% bin data and run t-test between 'before' and 'during'
numBins = 30; %how many bins? if there are 150 frames, 5 frames/bin
topEdge = timetotal*framespertimebin; %define limits
botEdge = 1; %define limits

binEdges = linspace(botEdge,topEdge,numBins); %define edges of bins

[h,whichBin] = histc([botEdge:topEdge],binEdges); %do histc to bin x or frame#
% binMean = nan(numflies,numBins); %pre-allocate to save mean of each bin


%'bin_ttest'; bins data according to the pre-set binEdges,etc and performs
% paired student's t-test to compare 'before' and 'during' data, and
% outputs the binned data means and t-test results (h=1: significant
% difference, p<0.05)

%whole fly group
[curv_abs_i2o_bin_mean,curv_abs_o2i_bin_mean,curv_abs_i2o_bin_SEM,curv_abs_o2i_bin_SEM,...
    curv_abs_i2o_by_bin_h,curv_abs_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    curv_abs_i2o_ind_avg_bf,curv_abs_i2o_ind_avg_dr,...
    curv_abs_o2i_ind_avg_bf,curv_abs_o2i_ind_avg_dr);

%%
%ACTUAL FIGURES
%==========================================================================
% 1. duration : plots ind fly mean plots (before /during), group
% mean plot, binned mean with t-test results
% 2. velocity_normalizer : normalize the curvature data
% 3. bin_ttest : binning + t-test
% 4. velocity_multiplots2: plots normalized group means, binned+t-test results
%==========================================================================

curv_abs_ylim = [0 2];
curv_unit = 'curvature';

plots_row = 4;
plots_column = 2;
figure_title = [fig_title ' abs. curvature at crossing (all the flie)'];

%plots the first four rows of subplots
velocity_multiplots1(curv_abs_o2i_ind_avg_bf,curv_abs_o2i_ind_avg_dr,...
    curv_abs_o2i_ind_avg_af,curv_abs_i2o_ind_avg_bf,curv_abs_i2o_ind_avg_dr,...
    curv_abs_i2o_ind_avg_af,curv_abs_o2i_avg,curv_abs_i2o_avg,curv_abs_o2i_SEM,...
    curv_abs_i2o_SEM,curv_abs_o2i_bin_mean,curv_abs_i2o_bin_mean,...
    curv_abs_o2i_bin_SEM,curv_abs_i2o_bin_SEM,...
    curv_abs_o2i_by_bin_h,curv_abs_i2o_by_bin_h,...
    framespertimebin,how_long,x_range,bin_x,curv_unit,curv_abs_ylim,crossing_min,numBins,...
    plots_row,plots_column);


ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');