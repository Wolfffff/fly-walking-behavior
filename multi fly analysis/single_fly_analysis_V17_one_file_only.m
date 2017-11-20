% single_fly_analysis_V17_one_file_only by Seung-Hye : for only one file (manually pick
% the file)

%% Big changes in V17
% additional function to sort runs into 'in' and 'out':run_in_out_divider.m
%this function gives frame # for runs that are occurring entirely inside
%the rim or outside of rim
            
% All the averages plotted are median values for a single fly analysis.
%% instructions
% 1. run the script
% 2. choose the csv file that contains fly xy coordinates (for example:
% 120628video6_xypts_transformed.csv)
% 3. enter '1' to plot only the main analysis plot or
% press 'Return' to plot the entire analyses
% 4. enter '1' to manually decide 'run' or 'stop' for the first point,
% if you already saved a file (for example "120628video7_runstop_info"),
% then enter 'Return'
% 5. When it is done, it will generate two pdf files one that contains the
% analysis and the other that contains individual crossing-related plots

%% This program needs following functions

% 1. period_def
% 2. crossingframes
% 3. radial_calculator_circle
% 4. vel_calculator
% 5. velocityatcrossing_basic
% 6. velocityatcrossing_with_frames
% 7. traceplotter_I2O, traceplotter_O2I
% 8. crossing_plotter
% 9. run_stop_generator1 ***V14
% 10. short_long_crossing
% 11. rad_velocity_binned
% 12. Velocity_Classifier
% 13. LineCurvature2D
% 14. runprobabilitySJ
% 15. run_in_out_divider


%%

clear all; close all;
warning('off');

prog_version =  'V17';

% set constants
framespertimebin =30;%how many frames/sec?
secsperperiod = 180;%how many seconds/period?

outer_radius = 3.2;
inner_radius = 1.2; %new chamber (cm)


bin_number = 5; %number of bins inside the odor zone for radial distribution calculation

%========loading the CSV + mat files=======================================
filename_behavior = uigetfile('*.csv', 'Select the file for FLY track');
fig_title1=filename_behavior(1:13);
%give an option to plot only main analysis or go through the whole analysis
display('Do you need only main anlaysis or the whole thing?');
analysis_option = input(['If you need the whole thing, press Enter, if you need only the main anlaysis, press 1: ']);

% if isempty(analysis_option) == 1 %if doing the whole analysis
display('Do you want to re-use the saved run/stop determination info?');
user_answer1 = input('If Yes, press Enter, If No, press 1');
if isempty(user_answer1) == 1 % if 'Yes'
    run_stop_info = [filename_behavior(1:13) 'runstop_info.mat'];
    load(run_stop_info);
else
    run_stop_info = nan(1,1);
end
% end

numvals = csvread(filename_behavior,2);%discard the first frame
%==========================================================================
if length(numvals) >= 10000; %to distinguish between 1 minute and 9 minute videos
    secsperperiod = 180;%how many seconds/period
    framespertimebin = 30;
else
    secsperperiod = 20;
    framespertimebin = 10;
end

%no smoothing for 3 fps video
fly_x_original = numvals(:,1);
fly_y_original = 480-numvals(:,2);  %flip y axis to match with the video
%smoothingfor 30 fps video
fly_x = smooth(fly_x_original,10);
fly_y = smooth(fly_y_original,10);


fig_title = [filename_behavior(1:13),' ', prog_version];

%Automatically find rim points files (all the CSV and mat files)
rimnametag_mat = [filename_behavior(1:6) 'transformedrimpoints.mat'];
% rimnametag_mat = [filename_behavior(1:6) 'rimpoints.mat'];
rimnametag_csv_in = [filename_behavior(1:6) 'video1_inner_rim.csv'];
rimnametag_csv_out = [filename_behavior(1:6) 'video1_outer_rim.csv'];


rimmatfiles = dir('*transformedrimpoints.mat');

rimmat = {rimmatfiles.name};

if find(strcmp(rimmat,rimnametag_mat)) ~= 0 % if there is a matching mat file
    display('Rim points file used is mat file')
    display(rimnametag_mat)
    load(rimnametag_mat);
    in_x= inner_transformed(:,1);
    in_y= 480-inner_transformed(:,2);%flip y axis to match with video
    out_x= outer_transformed(:,1);
    out_y= 480-outer_transformed(:,2);%flip y axis to match with video
elseif isempty(rimnametag_csv_in) ~= 0 % if there is no matching mat file, search for CSV files
    display('Rim points file used is CSV file')
    display(rimnametag_csv_in)
    csv_in = csvread(rimnametag_csv_in,1);
    in_x= csv_in(:,1);
    in_y = 480-csv_in(:,2);%flip y axis to match with video
    csv_out = csvread(rimnametag_csv_out,1);
    out_x = csv_out(:,1);
    out_y = 480-csv_out(:,2);%flip y axis to match with video
else %if there is no matching mat or CSV file, let the user choose it manually
    inner_rim_file = uigetfile('*.csv', 'Select the file for Inner Rim track');
    csv_in = csvread(inner_rim_file,1);
    in_x1 = csv_in(:,1);
    in_y1 = 480-csv_in(:,2);%flip y axis to match with video
    in_x = in_x1(~isnan(in_x1));%get rid of NaNs
    in_y = in_y1(~isnan(in_y1));
    outer_rim_file = [inner_rim_file(1:end-13) 'outer_rim.csv'];
    csv_out = csvread(outer_rim_file,1);
    out_x1 = csv_out(:,1);
    out_y1 = 480-csv_out(:,2);%flip y axis to match with video
    out_x = out_x1(~isnan(out_x1));%get rid of NaNs
    out_y = out_y1(~isnan(out_y1));
    
end


%% check if a fly is inside or outside the odor zone
inside_rim = inpolygon(fly_x,fly_y,in_x,in_y);%in=1, out=0
in_out_pts = zeros(length(fly_x),1);
in_out_pts(2:end) = diff(inside_rim);%ou2in=1, in2out = -1

% V14: instead of using inside_rim and in_out_pts right away, the script will check
% the velocity_calssified. If a fly is stopping, it will disregard any
% crossings and modify inside_rim and in_out_pts accordingly.

%using circfit to get the outer radius (out_R) in pixel unit
[out_xc,out_yc,out_R,out_a] = circfit(out_x,out_y);

%check velocity
vel_x_total = diff(fly_x);
vel_y_total = diff(fly_y);
vel_total_temp = sqrt((vel_x_total.^2+vel_y_total.^2));

%converting the unit of velocity to cm/sec
vel_total = vel_total_temp.*outer_radius/(out_R)*framespertimebin;
vel_total=[0;vel_total];


% Run_stop_analysis
% CLASSIFYING THE FIRST POINT
%threshold was set empirically by comparing the velocity with the video by
%Catherine
% runthreshold = .14*2;
% stopthreshold = .06*2;
runthreshold = .16;
stopthreshold = .1;


if isempty(user_answer1) == 0 %if run/stop info was not loaded from previously saved mat file, do the following
    
    xlim1 = 2; %x limits for the initial plot
    xlim2 = 26;
    xincrem = 5;
    
    ylim1 = 0;
    ylim2 = 2;
    yincrem = .1;
    
    
    x1 = (xlim1:xlim2);
    figure
    plot(x1,vel_total(xlim1:xlim2),'ro-'); hold on;
    %run threshold
    plot([xlim1,xlim2],[runthreshold, runthreshold],'k');
    %stop threshold
    plot([xlim1,xlim2],[stopthreshold, stopthreshold],'k');
    
    ylim ([ylim1 ylim2]);
    xlim ([xlim1 xlim2]);
    set(gca,'XTick', xlim1:xincrem:xlim2);
    set(gca,'YTick', ylim1:yincrem:ylim2);
    ylabel ('Velocity (cm/frame)');
    hold off;
    
    %if this is not the first time, just load the saved info
    
    %determine if the first four points are a run or a stop using the same
    %criteria used in velocity_classifier
    first_vel = vel_total(2:5);
    if first_vel(1) > stopthreshold || sum(first_vel >= stopthreshold) >= 2 %more than 2 frames are above stopthreshold
        first_input1 = 1;
    else
        first_input1 = 0;
    end
    
    display('Matlab determined the first point is ');
    if first_input1 == 1
        display('Run');
    else
        display('Stop');
    end
    
    % first_point = first_input1;
    
    %if it is accurate, get rid of this part later
    first_point = input ('Type a 1 if the first point is a RUN, 0 if a STOP');
    close all;
    run_stop_info = first_point;
    save([filename_behavior(1:13) 'runstop_info.mat'], 'run_stop_info');
else %if using saved mat file
    first_point = run_stop_info;
end

% CLASSIFYING POINTS
% for four consecutive frames, all four points are above stopthreshold, it
% is 'run'. if only the second frame is below stopthreshold, it is still
% 'run'.
% velocity_classified is just turning the velocity during "stops"  to zero
% velocity_classified_binary: runs =1 and stops =0
% runstops: NaN vector except the points when run becomes stop or stop
% becomes run (1)(if the first frame is run, it is '1')
[velocity_classified, velocity_classified_binary, runstops] =...
    Velocity_Classifier(vel_total, first_point, stopthreshold, runthreshold );

% using velocity_classified, check the crossing frames again, and remove the ones during the continuous stop
in_out_pts_ori = in_out_pts; %copy the original array
inside_rim_ori = inside_rim;

for i=2:length(in_out_pts)
    if in_out_pts(i) ~= 0 && velocity_classified(i) == 0 %if 'i'th frame is marked as crossing and classified as 'stop'
        if velocity_classified(i-1) == 0 % and the previous frame is also a stop
            inside_rim(i) = inside_rim(i-1); %then do not change in to out or out to in
        end
        in_out_pts(2:end) = diff(inside_rim);%re-check in_out_pts after changing inside_rim (ou2in=1, in2out = -1)
    end
end


%% This function outputs crossing events, odoron_frame etc.
[crossing,crossing_in,crossing_out,odoron_frame,odoroff_frame,timeperiods]=...
    period_def(fly_x,framespertimebin,secsperperiod,inside_rim,in_out_pts);

%%
% This function outputs crossing in/out in each period, frames in/out in
% each period: it uses only real crossing events.
% If a crossing-in occurs in during period and a crossing-out occurs in after period,
% that event will not be included!

[crossing_in_before, crossing_in_during, crossing_in_after,...
    crossing_out_before,crossing_out_during,crossing_out_after,crossing_before_No,crossing_during_No,crossing_after_No,...
    frames_in_before, frames_out_before,frames_in_during,frames_out_during,frames_in_after,frames_out_after]=...
    crossingframes(crossing,crossing_in,crossing_out,odoron_frame,odoroff_frame,timeperiods,in_out_pts, fly_x, fly_y);
%% get the start frame # and end frame # of stops and runs (V17)

rs_trans = find(isnan(runstops) == 0);%run/stop transition frames

if velocity_classified_binary(1) == 1 %if first frame is run
    run_start = rs_trans(2:2:end);run_start = [1;run_start];
    stop_start = rs_trans(1:2:end);
    
    run_end = stop_start -1;
    stop_end = run_start(2:end) -1;
    
else %if the first frame is stop
    run_start = rs_trans(1:2:end);
    stop_start = rs_trans(2:2:end);stop_start = [1;stop_start];
    
    run_end = stop_start(2:end) -1;
    stop_end = run_start -1;
    
end

%discard the last run or stop
if length(run_start) > length(run_end)
    run_start = run_start(1:end-1);
elseif length(stop_start) > length(stop_end)
    stop_start = stop_start(1:end-1);
end

%arrays that combine the start and end frames
run_st_end = horzcat(run_start,run_end);
stop_st_end = horzcat(stop_start,stop_end);


%%
% calculate the time fly spent inside in each time period
% actual frame numbers in fraction of total time
time_in_before = (sum(frames_in_before))/timeperiods(2);
time_in_during = (sum(frames_in_during))/(odoroff_frame-odoron_frame-1);
time_in_after = (sum(frames_in_after))/(timeperiods(4)-odoroff_frame-1);

%calculate time fly spent outisde in each time period
% in probability
time_out_before = 1-time_in_before;
time_out_during = 1-time_in_during;
time_out_after = 1-time_in_after;

%BEFORE
%get the individual time(sec) spent inside per transit
time_in_transit_before = frames_in_before/framespertimebin;
time_out_transit_before = frames_out_before/framespertimebin;
% get the average: MEDIAN
median_time_in_transit_before = median(time_in_transit_before);
median_time_out_transit_before = median(time_out_transit_before);

%DURING
%get the time spent inside per transit in second
time_in_transit_during = frames_in_during/framespertimebin;
time_out_transit_during = frames_out_during/framespertimebin;
% get the average: MEDIAN
median_time_in_transit_during = median(time_in_transit_during);
median_time_out_transit_during = median(time_out_transit_during);

%AFTER
%get the time spent inside per transit in second
time_in_transit_after = frames_in_after/framespertimebin;
time_out_transit_after = frames_out_after/framespertimebin;
% get the average:MEDIAN
median_time_in_transit_after = median(time_in_transit_after);
median_time_out_transit_after = median(time_out_transit_after);


%%
%radial distribution calculation

[our_R,fly_bin_probability, bin_radius, average_radius,fly_location_bin] = ...
    radial_calculator_circle(fly_x,fly_y, out_x,out_y,in_x,in_y,bin_number,...
    timeperiods,odoron_frame,odoroff_frame,inner_radius, outer_radius);

%%
%velocity calculation
%unit: cm/sec
vel_unit = 'velocity(cm/sec)';
vel_ylim = [0 2];

[vel_total,velocity_fly_in, velocity_fly_out,avgvelocity_by_fly_in, avgvelocity_by_fly_out...
    avgvelocity_by_fly_in_median,avgvelocity_by_fly_out_median]=...
    vel_calculator(fly_x,fly_y,timeperiods,our_R, crossing, framespertimebin, inside_rim,outer_radius);

%%
% PLOTS
%set color that will be used in plots
grey=[0.7,0.7,0.7];
color = [0 1 0;1 0 0;0 0 1];

cmap=[0.5781  0  0.8242;
    0.5451    0.5373    0.5373;
    1.0000    0.6471         0
    0         0.8078    0.8196;
    1         .02       0.2;
    0.3922    0.5843    0.9294;
    0.1961    0.8039    0.1961;
    0.9000    0.6471         0;
    0.5176    0.4392    1.0000;
    0.4196    0.5569    0.1373;
    0.7216    0.5255    0.0431;
    0.2745    0.5098    0.7059;
    0.4000    0.8039    0.6667;
    0.9333    0.7961    0.6784;
    0.6471    0.1647    0.1647;
    0         0.7490    1.0000;
    0.8588    0.4392    0.5765;
    0.5765    0.4392    0.8588;
    0.9804    0.5020    0.4471;
    0.5137    0.5451    0.5137];

figure(1)
set(gcf,'Position',[434 58 1000 750],'color','white')

subplot(5,6,[1 8])
plot(in_x,in_y,'k');hold on
plot(out_x,out_y,'k');

plot(fly_x(1:timeperiods(2)),fly_y(1:timeperiods(2)),'g','linewidth',0.5);
plot(fly_x(timeperiods(2):odoron_frame),fly_y(timeperiods(2):odoron_frame),'color',grey,'linewidth',0.5);
plot(fly_x(odoron_frame:odoroff_frame),fly_y(odoron_frame:odoroff_frame),'r','linewidth',0.5);
plot(fly_x(odoroff_frame:timeperiods(4)),fly_y(odoroff_frame:timeperiods(4)),'b','linewidth',0.5);

set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
axis tight;
title(fig_title,'fontsize',12,'fontweight','bold','interpreter','none');

subplot(5,6,[13 20])
plot(in_x,in_y,'k');hold on
plot(out_x,out_y,'k');

plot(fly_x(1:timeperiods(2)),fly_y(1:timeperiods(2)),'go-','markersize',1.5);
set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
axis tight;
xlabel('BEFORE','color','k');

subplot(5,6,[15 22])
plot(in_x,in_y,'k');hold on
plot(out_x,out_y,'k');

plot(fly_x(timeperiods(2):odoron_frame),fly_y(timeperiods(2):odoron_frame),'o-', 'color',grey, 'markersize',1.5);
plot(fly_x(odoron_frame:odoroff_frame),fly_y(odoron_frame:odoroff_frame),'ro-', 'markersize',1.5);
set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
axis tight;
xlabel('DURING','color','k');

subplot(5,6,[17 24])
plot(in_x,in_y,'k');hold on
plot(out_x,out_y,'k');

plot(fly_x(odoroff_frame:timeperiods(4)),fly_y(odoroff_frame:timeperiods(4)),'bo-','markersize',1.5);
set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
axis tight;
xlabel('AFTER','color','k');

%plot radial distribution
subplot(5,6,3);

plot([1.2 1.2],[0, .4], 'k:',...
    [average_radius(1),average_radius(1)],[0 .4],'g',...
    [average_radius(2),average_radius(2)],[0 .4],'r',...
    [average_radius(3),average_radius(3)],[0 .4],'b');
hold on;

plot(bin_radius,fly_bin_probability(1,:),'g','LineWidth',2);hold on
plot(bin_radius,fly_bin_probability(2,:),'r','LineWidth',2);
plot(bin_radius,fly_bin_probability(3,:),'b','LineWidth',2);

axis([0 bin_radius(end) 0 .4]);

set(gca,'Box','off','TickDir','out','Ytick',(0:0.2:.4),'YGrid','on','fontsize',8);
xlabel('r(cm)');
ylabel('p(r) (normalized to area)');

%plot time spent inside and outside
time_in =[time_in_before;time_in_during;time_in_after];
time_out = [time_out_before;time_out_during;time_out_after];
subplot(5,6,4)
for h=1:3
    b = bar(h,time_in(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
    set(b, 'FaceColor', color(:,h));
end
title('time spent inside odor zone' ,'fontsize',8,'interpreter','none');
ylim ([0 1]);
set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);

subplot(5,6,5)
for h=1:3
    b = bar(h,time_out(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
    set(b, 'FaceColor', color(:,h));
end
title('time spent outside odor zone' ,'fontsize',8);
ylim ([0 1]);
set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);

%plot number of transits (out2in)
subplot(5,6,6)
crossing_ins = [crossing_before_No; crossing_during_No; crossing_after_No];
for h=1:3
    b = bar(h,crossing_ins(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
    set(b, 'FaceColor', color(:,h));
end
title('number of transits (out to in)' ,'fontsize',8);
ylim ([0 30]);
set(gca,'Box','off','Xtick',[],'Ytick',(0:5:40),'YGrid','on','fontsize',8);

%plot time spent inside per transit(1 means entire period)
time_inside_per_transit = [median_time_in_transit_before,median_time_in_transit_during,median_time_in_transit_after];
subplot(5,6,9);

%plot the average (MEDIAN)
for h = 1:3,
    b = bar(h, time_inside_per_transit(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    p = plot(h, time_inside_per_transit(h), 'o', 'MarkerSize', 4, 'MarkerEdgeColor', 'w');
    set(p, 'MarkerFaceColor', color(:,h));
end;
plot(time_inside_per_transit, 'k');
%plot individual transits
for n=1:length(time_in_transit_before)
    plot(1,time_in_transit_before(n),'o','markersize',3,'MarkerEdgeColor', 'w','MarkerFaceColor',grey);hold on;
end
for n=1:length(time_in_transit_during)
    plot(2,time_in_transit_during(n),'o','markersize',3,'MarkerEdgeColor', 'w','MarkerFaceColor', grey);hold on
end
for n=1:length(time_in_transit_after)
    plot(3,time_in_transit_after(n),'o','markersize',3,'MarkerEdgeColor', 'w','MarkerFaceColor',grey);hold on
end

title('Time spent inside/transit' ,'fontsize',8);
ylabel('time(s)','fontsize',7);

if isnan(time_inside_per_transit) == 0
    maxlimit= max(time_inside_per_transit);
    ylim ([0 maxlimit+2]);
    if maxlimit+2>10
        set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((maxlimit+2/5),1)/2:maxlimit+2),'YGrid','on','fontsize',7);
    else
        set(gca,'Box','off','Xtick',[],'Ytick',(0:2:10),'YGrid','on','fontsize',7);
    end
else %it the fly never went inside (such as in control/AIR video)
    ylim([0 10]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:2:10),'YGrid','on','fontsize',7);
end
%plot odor rediscovery time (1 means entire period)
time_outside_per_transit = [median_time_out_transit_before,median_time_out_transit_during,median_time_out_transit_after];

subplot(5,6,10);

for h = 1:3,
    b = bar(h, time_outside_per_transit(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    p = plot(h, time_outside_per_transit(h), 'o', 'MarkerSize', 5, 'MarkerEdgeColor', 'w');
    set(p, 'MarkerFaceColor', color(:,h));
    
end;
plot(time_outside_per_transit, 'k');

%plot individual transits
for n=1:length(time_out_transit_before)
    plot(1,time_out_transit_before(n),'o','markersize',3,'MarkerEdgeColor', 'w','MarkerFaceColor',grey);hold on;
end
for n=1:length(time_out_transit_during)
    plot(2,time_out_transit_during(n),'o','markersize',3,'MarkerEdgeColor', 'w','MarkerFaceColor', grey);hold on
end
for n=1:length(time_out_transit_after)
    plot(3,time_out_transit_after(n),'o','markersize',3,'MarkerEdgeColor', 'w','MarkerFaceColor',grey);hold on
end

title('odor re-discovery time/transit' ,'fontsize',8);
ylabel('time(s)','fontsize',7);

if isnan(time_outside_per_transit) == 0
    maxlimit= max(time_outside_per_transit);
    ylim ([0 maxlimit+2]);
    if maxlimit+2>10
        set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((maxlimit+2/5),1)/2:maxlimit+2),'YGrid','on','fontsize',7);
    else
        set(gca,'Box','off','Xtick',[],'Ytick',(0:2:10),'YGrid','on','fontsize',7);
    end
else
    ylim([0 10]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:2:10),'YGrid','on','fontsize',7);
end
%average velocity
subplot(5,6,11);
for h = 1:3,
    b = bar(h, avgvelocity_by_fly_in(h), 'BarWidth', .4, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    
    p = plot(1:3, avgvelocity_by_fly_in, 'ko-', 'MarkerSize', 5, 'MarkerEdgeColor', 'w','markerfacecolor','k');
    ylabel(vel_unit,'fontsize',8);
    xlabel('MEAN velocity inside','fontsize',8);
    ylim ([0 max(avgvelocity_by_fly_out_median)+.5]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((max(avgvelocity_by_fly_out+2)/5),-1):max(avgvelocity_by_fly_out)+.5),'YGrid','on','fontsize',7);
    
end;

subplot(5,6,12);
for h = 1:3,
    b = bar(h, avgvelocity_by_fly_out(h), 'BarWidth', .4, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    p = plot(1:3, avgvelocity_by_fly_out, 'ko-', 'MarkerSize', 5, 'MarkerEdgeColor', 'w','markerfacecolor','k');
    
    ylabel(vel_unit,'fontsize',8);
    xlabel('MEAN velocity outside','fontsize',8);
    ylim ([0 max(avgvelocity_by_fly_out_median)+.5]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((max(avgvelocity_by_fly_out+2)/5),-1):max(avgvelocity_by_fly_out)+.5),'YGrid','on','fontsize',7);
    
end;

%radial distribution

subplot(5,6,[25 30])

plot(1:timeperiods(2), fly_location_bin(1:timeperiods(2)),'g');hold on;
plot(timeperiods(2):odoron_frame, fly_location_bin(timeperiods(2):odoron_frame),'color',grey);
plot(odoron_frame:odoroff_frame, fly_location_bin(odoron_frame:odoroff_frame),'r');
plot(odoroff_frame:timeperiods(4), fly_location_bin(odoroff_frame:timeperiods(4)),'b');xlim([1 timeperiods(4)]);
line([0 timeperiods(4)],[5 5],'linestyle',':','color',grey);

xlim([1 timeperiods(4)]);
ylim([1 length(fly_bin_probability)+1]);

set(gca,'box','off','TickDir','out');
xlabel('time (frame number)','fontsize',10);
ylabel('distance from center (bin)');

%save the figure as png file
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
%     saveas(gcf, [fig_title ' Main_analysis.png']);
print('-dpsc2',[fig_title '.ps']);

%Program ends here if user chose to plot main analysis only
if isempty(analysis_option) == 1 % if user wants to continue with the other analyses
    %%
    %traceplotter
    how_short = 3;
    period_name = {'before','during','after'};
    
    %crossing_in
    [fly_x_aligned,fly_y_aligned,rotated_in_x,rotated_in_y,...
        short_fly_x_aligned,short_fly_y_aligned,crossing_in_cell,crossing_out_cell...
        angle_bw_IO,period_1,period_2]...
        = traceplotter_O2I(crossing_in_before,crossing_in_during,crossing_in_after,...
        crossing_out_before,crossing_out_during,crossing_out_after,...
        in_x,in_y,fly_x,fly_y,how_short,framespertimebin,timeperiods);
    
    figure
    set(gcf,'position',[400 50 700 750],'color','white');
    
    subplot(4,3,1)
    for period = period_1:period_2;
        for h = 1:length(crossing_in_cell{period});
            plot (fly_x_aligned{h, period},fly_y_aligned{h, period} ,'color', color(period,:))
            hold on
        end
        plot([0 0],'ko','markersize',5);
        
        title({fig_title; 'Aligned crossing-ins'},'interpreter','none');
        set(gca,'xlim',[min(rotated_in_x{h,period})-10 max(rotated_in_x{h,period})],...
            'ylim',[min(rotated_in_y{h,period}) max(rotated_in_y{h,period})]);
        set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
    end
    
    subplot(4,3,2)
    for period =  period_1:period_2;
        for h = 1:length(crossing_in_cell{period});
            plot (short_fly_x_aligned{h, period},short_fly_y_aligned{h, period} ,'color', color(period,:))
            hold on
        end
        plot([0 0],'ko','markersize',5);
        title({[num2str(how_short) ' second']});
        set(gca,'xlim',[min(rotated_in_x{h,period})-10 max(rotated_in_x{h,period})],...
            'ylim',[min(rotated_in_y{h,period}) max(rotated_in_y{h,period})]);
        set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
    end
    
    
    for period =  period_1:period_2;
        subplot(4,3,period+3)
        for h = 1:length(crossing_in_cell{period});
            p=rem(h,20)+1;
            plot(fly_x_aligned{h, period},fly_y_aligned{h, period} ,'color', cmap(p,:));hold on
            plot(rotated_in_x{h,period},rotated_in_y{h,period},'color',grey);
            set(gca,'xlim',[min(rotated_in_x{h,period}) max(rotated_in_x{h,period})],...
                'ylim',[min(rotated_in_y{h,period}) max(rotated_in_y{h,period})]);
            set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
        end
        axis tight;
        title(period_name{period});
        if period ==2
            title({'whole crossing';period_name{period}});
        end
        
    end
    
    for period =  period_1:period_2;
        subplot(4,3,period+6)
        for h = 1:length(crossing_in_cell{period});
            p=rem(h,20)+1;
            plot(short_fly_x_aligned{h, period},short_fly_y_aligned{h, period} ,'color', cmap(p,:));hold on
            plot(rotated_in_x{h,period},rotated_in_y{h,period},'color',grey);
            set(gca,'xlim',[min(rotated_in_x{h,period}) max(rotated_in_x{h,period})],...
                'ylim',[min(rotated_in_y{h,period}) max(rotated_in_y{h,period})]);
            set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
        end
        axis tight;
        title(period_name{period});
        if period ==2
            title({[num2str(how_short) ' second only'];period_name{period}});
        end
    end
    
    subplot(4,3,3)
    for i=period_1:period_2;
        angle_period=angle_bw_IO(:,i);
        angle_period = angle_period(find(angle_period));
        plot(i,angle_period,'o');hold on
    end
    set(gca,'box','off','Xtick',(1:3),'Ytick',(-pi:pi/2:pi),'YTickLabel',{'-pi','-pi/2','0','pi/2','pi'});
    set(gca,'XTickLabel',{'Before','During','After'});
    plot([0 4],[0 0],'k--');
    xlim([0 4]);
    ylim([-pi-.5 pi+.5]);
    title('Angle between crossing In and next crossing Out');
    
    %averaging fly's position by odor period
    %first, make three arrays to save each period information
    subplot(4,3,10)
    for period = period_1:period_2
        crossing_count=1;
        %first decide the largest length of crossings
        for i=1:length(crossing_in_cell{period})
            length_x(crossing_count) = length(fly_x_aligned{i,period});
            crossing_count = crossing_count+1;
        end
        
        if period ==1 %before
            all_fly_x_aligned_bf = nan(max(length_x),length(crossing_in_cell{1}));
            all_fly_y_aligned_bf = nan(max(length_x),length(crossing_in_cell{1}));
            for i=1:length(crossing_in_cell{period})
                %check the slope of best fitted line and decide which way the
                %fly is going (going up or down)
                p = polyfit(fly_x_aligned{i,period},fly_y_aligned{i,period},1);
                if p(1)> 0 %slope +
                    all_fly_x_aligned_bf(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                    all_fly_y_aligned_bf(1:length(fly_y_aligned{i,period}),i) = fly_y_aligned{i,period};
                else % slope -
                    all_fly_x_aligned_bf(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                    all_fly_y_aligned_bf(1:length(fly_y_aligned{i,period}),i) = -fly_y_aligned{i,period};
                end
            end
            avg_fly_x_aligned_bf = nanmean(all_fly_x_aligned_bf,2);
            avg_fly_y_aligned_bf = nanmean(all_fly_y_aligned_bf,2);
            fly_x_aligned_bf_SD = nanstd(all_fly_x_aligned_bf,0,2);
            fly_y_aligned_bf_SD = nanstd(all_fly_y_aligned_bf,0,2);
            
        elseif period ==2 %during
            all_fly_x_aligned_dr = nan(max(length_x),length(crossing_in_cell{2}));
            all_fly_y_aligned_dr = nan(max(length_x),length(crossing_in_cell{2}));
            for i=1:length(crossing_in_cell{period})
                %check the slope of best fitted line and decide which way the
                %fly is going (going up or down)
                p = polyfit(fly_x_aligned{i,period},fly_y_aligned{i,period},1);
                if p(1)> 0
                    all_fly_x_aligned_dr(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                    all_fly_y_aligned_dr(1:length(fly_y_aligned{i,period}),i) = fly_y_aligned{i,period};
                else
                    all_fly_x_aligned_dr(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                    all_fly_y_aligned_dr(1:length(fly_y_aligned{i,period}),i) = -fly_y_aligned{i,period};
                end
            end
            avg_fly_x_aligned_dr = nanmean(all_fly_x_aligned_dr,2);
            avg_fly_y_aligned_dr = nanmean(all_fly_y_aligned_dr,2);
            
        else %after
            all_fly_x_aligned_af = nan(max(length_x),length(crossing_in_cell{3}));
            all_fly_y_aligned_af = nan(max(length_x),length(crossing_in_cell{3}));
            for i=1:length(crossing_in_cell{period})
                %check the slope of best fitted line and decide which way the
                %fly is going (going up or down)
                p = polyfit(fly_x_aligned{i,period},fly_y_aligned{i,period},1);
                if p(1)> 0
                    all_fly_x_aligned_af(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                    all_fly_y_aligned_af(1:length(fly_y_aligned{i,period}),i) = fly_y_aligned{i,period};
                else
                    all_fly_x_aligned_af(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                    all_fly_y_aligned_af(1:length(fly_y_aligned{i,period}),i) = -fly_y_aligned{i,period};
                end
                
            end
            avg_fly_x_aligned_af = nanmean(all_fly_x_aligned_af,2);
            avg_fly_y_aligned_af = nanmean(all_fly_y_aligned_af,2);
        end
        
    end
    
    frametoplot = 90;
    if frametoplot <= sum(~isnan(avg_fly_x_aligned_bf)) %if avg data length is longer than frametoplot
        plot(avg_fly_x_aligned_bf(1:frametoplot),avg_fly_y_aligned_bf(1:frametoplot),'g');
    else
        plot(avg_fly_x_aligned_bf,avg_fly_y_aligned_bf,'g');
    end
    hold on
    
    if frametoplot <= sum(~isnan(avg_fly_x_aligned_dr)) %if avg data length is longer than frametoplot
        plot(avg_fly_x_aligned_dr(1:frametoplot),avg_fly_y_aligned_dr(1:frametoplot),'r');
    else
        plot(avg_fly_x_aligned_dr,avg_fly_y_aligned_dr,'r');
    end
    
    if period_2 == 3
        if frametoplot <= sum(~isnan(avg_fly_x_aligned_af)) %if avg data length is longer than frametoplot
            plot(avg_fly_x_aligned_af(1:frametoplot),avg_fly_y_aligned_af(1:frametoplot),'b');
        else
            plot(avg_fly_x_aligned_af,avg_fly_y_aligned_af,'b');
        end
    end
    
    plot([0 0],'ko','markersize',5);
    
    title(['Averaged crossing-ins for ' num2str(frametoplot) ' frames'],'interpreter','none');
    set(gca,'xlim',[min(rotated_in_x{h,period})-10 max(rotated_in_x{h,period})],...
        'ylim',[min(rotated_in_y{h,period}) max(rotated_in_y{h,period})]);
    set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
    
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    %         saveas(gcf, [fig_title ' aligned_O2I.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    clear fly_x_aligned fly_y_aligned rotated_in_x rotated_in_y ...
        short_fly_x_aligned short_fly_y_aligned crossing_in_cell crossing_out_cell ...
        period_1 period_2;
    %%
    %crossing_out======================================================
    [fly_x_aligned,fly_y_aligned,rotated_in_x,rotated_in_y,...
        short_fly_x_aligned,short_fly_y_aligned,crossing_in_cell,crossing_out_cell,...
        angle_bw_OI,period_1,period_2]...
        = traceplotter_I2O(crossing_in_before,crossing_in_during,crossing_in_after,...
        crossing_out_before,crossing_out_during,crossing_out_after,...
        in_x,in_y,fly_x,fly_y,how_short,framespertimebin,timeperiods);
    
    figure
    set(gcf,'position',[400 50 800 700],'color','white');
    
    subplot(3,3,1)
    for period = period_1:period_2;
        for h = 1:length(crossing_in_cell{period});
            plot (fly_x_aligned{h, period},fly_y_aligned{h, period} ,'color', color(period,:))
            hold on
        end
        plot([0 0],'k+','markersize',10);
        
        title({fig_title; 'Aligned crossing-outs'},'interpreter','none');
        axis tight;
        set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
    end
    
    subplot(3,3,2)
    for period = period_1:period_2;
        for h = 1:length(crossing_in_cell{period});
            plot (short_fly_x_aligned{h, period},short_fly_y_aligned{h, period} ,'color', color(period,:))
            hold on
        end
        plot([0 0],'k+','markersize',10);
        title([num2str(how_short) ' second']);
        set(gca,'xlim',[min(rotated_in_x{h,period})-100 max(rotated_in_x{h,period})+100],...
            'ylim',[min(rotated_in_y{h,period})-100 max(rotated_in_y{h,period})+100]);
        set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
    end
    
    
    
    for period = period_1:period_2;
        subplot(3,3,period+3)
        for h = 1:length(crossing_in_cell{period});
            p = rem(h,20)+1;
            plot(fly_x_aligned{h, period},fly_y_aligned{h, period} ,'color', cmap(p,:));hold on
            plot(rotated_in_x{h,period},rotated_in_y{h,period},'color',grey);
            set(gca,'xlim',[min(rotated_in_x{h,period}) max(rotated_in_x{h,period})],...
                'ylim',[min(rotated_in_y{h,period}) max(rotated_in_y{h,period})]);
            set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
        end
        axis tight;
        title(period_name{period});
        if period ==2
            title({'whole crossing';period_name{period}});
        end
        
    end
    
    for period = period_1:period_2;
        subplot(3,3,period+6)
        for h = 1:length(crossing_in_cell{period});
            p = rem(h,20)+1;
            plot(short_fly_x_aligned{h, period},short_fly_y_aligned{h, period} ,'color', cmap(p,:));hold on
            plot(rotated_in_x{h,period},rotated_in_y{h,period},'color',grey);
            set(gca,'xlim',[min(out_x) max(out_x)],...
                'ylim',[min(out_y) max(out_y)]);
            set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1]);
        end
        axis tight;
        title(period_name{period});
        if period ==2
            title({[num2str(how_short) ' second only'];period_name{period}});
        end
    end
    
    subplot(3,3,3)
    for i=period_1:period_2;
        angle_period=angle_bw_OI(:,i);
        angle_period = angle_period(find(angle_period));
        plot(i,angle_period,'o');hold on
    end
    set(gca,'box','off','Xtick',(1:3),'Ytick',(-pi:pi/2:pi),'YTickLabel',{'-pi','-pi/2','0','pi/2','pi'});
    set(gca,'XTickLabel',{'Before','During','After'});
    plot([0 4],[0 0],'k--');
    xlim([0 4]);
    ylim([-pi-.5 pi+.5]);
    title('Angle between crossing out and next crossing in');
    
    %     clear crossing_in_cell crossing_out_cell;
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    print('-dpsc2',[fig_title '.ps'],'-append');
    %%
    %time_in_out_historgram.m
    %nanmean for time spent in/transit and time spent out/transit
    
    %first put all the cell array data into one matrix
    %time in /transit
    every_ti_before = time_in_transit_before;
    every_ti_during =  time_in_transit_during;
    every_ti_after = time_in_transit_after;
    
    %time out/transit (odor rediscovery time)
    every_to_before = time_out_transit_before;
    every_to_during =  time_out_transit_during;
    every_to_after = time_out_transit_after;
    
    % set the bin value here
    x = 0:1:100;
    
    % plot nanmean
    %histc will check each element and decide which bin the element belongs
    %and how many elements are in each bin (for example: x = 0:1:10, then [
    %0.1 2.2 4 4.5] will counted as bin # 1, 3, 5, 5)
    %time inside/transit
    [n_ti_before,Cib] = histc(every_ti_before,x);
    [n_ti_during,Cid] = histc(every_ti_during,x);
    [n_ti_after,Cia] = histc(every_ti_after,x);
    
    %time to return/transit
    [n_to_before,Cob] = histc(every_to_before,x);
    [n_to_during,Cod] = histc(every_to_during,x);
    [n_to_after,Coa] = histc(every_to_after,x);
    
    %get max value to use for ylim in plots
    max_ti = max([max(n_ti_before);max(n_ti_during);max(n_ti_after)]);
    max_to = max([max(n_to_before);max(n_to_during);max(n_to_after)]);
    
    ylim_ti = ceil(max_ti/10)*10;
    ylim_to = ceil(max_to/10)*10;
    
    
    figure
    set(gcf,'Position',[400 50 800 700],'color','white');
    for i=1:3
        subplot(3,2,2*i-1)
        if i ==1
            barplot = bar(x,n_ti_before,'histc'); hold on
            set(barplot,'edgecolor','w','facecolor','g');
            plot([nanmean(every_ti_before) nanmean(every_ti_before)],[0 100],'b--');
            text(10,20,{'black: mean of individual fly';'blue: mean of all events'; 'red:mean of all flies'});
            
        elseif i ==2
            barplot = bar(x,n_ti_during,'histc'); hold on
            set(barplot,'edgecolor','w','facecolor','r');
            plot([nanmean(every_ti_during) nanmean(every_ti_during)],[0 100],'b--');
            
        else
            barplot = bar(x,n_ti_after,'histc'); hold on
            set(barplot,'edgecolor','w');
            plot([nanmean(every_ti_after) nanmean(every_ti_after)],[0 100],'b--');
            
        end
        
        
        set(gca,'box','off','Ytick',(0:10:100),'Tickdir','out','Xlim',[-0.5 20],'Xtick',(0:5:20));
        ylim([-1 ylim_ti]);
        if i==1
            title({[fig_title ' Time spent inside/transit'];period_name{i}})
        else
            title(period_name{i});
        end
        xlabel('time (s)','fontsize',8);
        
    end
    
    for i=1:3
        subplot(3,2,2*i)
        if i ==1
            barplot = bar(x,n_to_before,'histc');    hold on
            set(barplot,'edgecolor','w','facecolor','g');
            plot([nanmean(every_to_before) nanmean(every_to_before)],[0 100],'b--');
            
        elseif i ==2
            barplot = bar(x,n_to_during,'histc');    hold on
            set(barplot,'edgecolor','w','facecolor','r');
            plot([nanmean(every_to_during) nanmean(every_to_during)],[0 100],'b--');
            
        else
            barplot = bar(x,n_to_after,'histc');    hold on
            set(barplot,'edgecolor','w');
            plot([nanmean(every_to_after) nanmean(every_to_after)],[0 100],'b--');
            
        end
        
        
        set(gca,'box','off','Ytick',(0:10:100),'Tickdir','out','Xlim',[-0.5 60],'Xtick',(0:5:100));
        ylim([-1 ylim_to]);
        if i==1
            title({[fig_title ' Time to return/transit'];period_name{i}})
        else
            title(period_name{i});
        end
        xlabel('time (s)','fontsize',8);
        
    end
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    % plotname = [fig_title, 'ti_to_analysis'];
    % saveas(gcf, [plotname '.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    % save('video8vals.mat','velocity_classified', 'crossing_in_cell', 'crossing_out_cell', 'timeperiods', 'frames', 'date')
    %%
    % radial velocity calculation + total_velocity binned by radius
    % both mean and median values, choose whichever is appropriate
    [radius_fly,rad_vel,circRad,radius_binned,rad_vel_sqrt,avg_vel_by_radius_before,...
        avg_vel_by_radius_during,avg_vel_by_radius_after,...
        avg_radvel_by_radius_before,avg_radvel_by_radius_during,avg_radvel_by_radius_after,...
        avg_vel_by_radius_before_median,avg_vel_by_radius_during_median,avg_vel_by_radius_after_median,...
        avg_radvel_by_radius_before_median,avg_radvel_by_radius_during_median,avg_radvel_by_radius_after_median]...
        = rad_velocity_binned(in_x,in_y, fly_x,fly_y,out_x,out_y,bin_number,...
        timeperiods,odoron_frame,odoroff_frame,vel_total,our_R,framespertimebin,outer_radius);
    
    %convert radius_fly (pixel) to cm unit
    radius_fly_cm = (radius_fly.*inner_radius)/circRad;
    
    %%
    %total and radial velocity plot at crossing============================
    %2 sec before and after crossing!
    % this function uses vel_total from vel_calculator
    %( this function can output the frames numbers used in the velocity
    %crossing if needed)
    
    %time (sec)  before the crossing to save the velocity info
    timebefore = 2;
    %total time (sec) to save the velocity including before and after
    %crossing
    timetotal = 5;
    
    [velocity_in2out_before,velocity_in2out_during,velocity_in2out_after,...
        velocity_out2in_before,velocity_out2in_during,velocity_out2in_after]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        vel_total,framespertimebin, timeperiods, timebefore, timetotal);
    
    %average: Median
    velocity_i2o_avg(:,1) = nanmedian(velocity_in2out_before,2);
    velocity_i2o_avg(:,2) = nanmedian(velocity_in2out_during,2);
    velocity_i2o_avg(:,3) = nanmedian(velocity_in2out_after,2);
    
    velocity_o2i_avg(:,1) = nanmedian(velocity_out2in_before,2);
    velocity_o2i_avg(:,2) = nanmedian(velocity_out2in_during,2);
    velocity_o2i_avg(:,3) = nanmedian(velocity_out2in_after,2);
    
    velocity_i2o_std = nan(length(velocity_o2i_avg),3);
    velocity_o2i_std = nan(length(velocity_o2i_avg),3);
    
    velocity_i2o_std(:,1) = nanstd(velocity_in2out_before,0,2);
    velocity_i2o_std(:,2) = nanstd(velocity_in2out_during,0,2);
    velocity_i2o_std(:,3) = nanstd(velocity_in2out_after,0,2);
    
    velocity_o2i_std(:,1) = nanstd(velocity_out2in_before,0,2);
    velocity_o2i_std(:,2) = nanstd(velocity_out2in_during,0,2);
    velocity_o2i_std(:,3) = nanstd(velocity_out2in_after,0,2);
    
    %normalization of velocity so that velocity right before crossing is similar
    %get the average between -1 and 0 sec, then subtract from original
    %velocity
    frame_norm =((timebefore-1.5)*framespertimebin +1):((timebefore-.5)*framespertimebin);
    before_norm = nanmean(velocity_o2i_avg(frame_norm,1));
    during_norm = nanmean(velocity_o2i_avg(frame_norm,2));
    after_norm = nanmean(velocity_o2i_avg(frame_norm,3));
    
    vel_o2i_norm_before = velocity_o2i_avg(:,1) - before_norm;
    vel_o2i_norm_during = velocity_o2i_avg(:,2) - during_norm;
    vel_o2i_norm_after = velocity_o2i_avg(:,3) - after_norm;
    
    % figure
    % plot(vel_o2i_norm_before,'g')
    % hold on
    % plot(vel_o2i_norm_during,'r')
    % plot(vel_o2i_norm_after)
    % plot([61 61],[-5 5],'k:')
    % plot([1 600],[0 0],'k:')
    %
    % xlim([1 timetotal*framespertimebin])
    % ylim([-1 1])
    
    %% velocity_classified at crossing
    
    [vel_clsf_in2out_before,vel_clsf_in2out_during,vel_clsf_in2out_after,...
        vel_clsf_out2in_before, vel_clsf_out2in_during,vel_clsf_out2in_after]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        velocity_classified,framespertimebin, timeperiods, timebefore, timetotal);
    
    
    %%
    [ll, in2outrunstops, out2inrunstops]...
        = runprobabilitySJ (vel_clsf_in2out_before,vel_clsf_in2out_during,vel_clsf_in2out_after,...
        vel_clsf_out2in_before, vel_clsf_out2in_during,vel_clsf_out2in_after, framespertimebin,fig_title,timebefore,timetotal);
    
    set(ll, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    %         saveas(gcf, [fig_title ' velocityplot.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    
    % Dividing Data into Runs and stops
    [runs, stops] = run_stop_generator1(runstops, velocity_classified, timeperiods,odoron_frame);
    %from V14, changed to run_stop_generator1. before ends at 3 min. after
    %starts at 6 min.
    
    %% CALCULATES RUN AND STOP STATISTICS
    
    % stats calculation + plotting corrected by SJ
    
    figure
    set(gcf, 'Position',[300 200 900 600]);
    period_name = {'Before','During','After'};
    
    for odorpd = 1:3
        
        % calculating run duration, run velocity for each period
        for x = 1:length(runs{odorpd})
            runsduration(x) = length(runs{odorpd}{x});%in frame
            runsduration_secs(x) = (runsduration(x))/framespertimebin;%in sec
            
            distance_final(x) = nanmean(runs{odorpd}{x}) * runsduration_secs(x); % in cm
            avg_velocity(x) = nanmean(runs{odorpd}{x}); % average velocity of each run in cm/sec
        end
        
        %calculating stop duration
        for x = 1:length(stops{odorpd})
            stopsduration(x) = length(stops{odorpd}{x});
            stopsduration_secs(x) = (stopsduration(x))/framespertimebin;
        end
        
        %how many runs or stops/period
        numruns(odorpd) = numel(runs{odorpd});
        numstops(odorpd) = numel(stops{odorpd});
        
        %average stop duration in sec and total time
        avgstopduration(odorpd) = nanmean(stopsduration_secs);
        stopduration_total = sum(stopsduration_secs);
        
        %average run duration in sec and total time
        avgrunduration(odorpd) = nanmean(runsduration_secs);
        runsduration_total = sum(runsduration_secs);
        
        %average velocity of all runs
        %avgavgvel(odorpd) = nanmean(avg_velocity); %till V13
        %collect all the run velocity and get the mean
        run_vel_all_cell = runs{odorpd};
        run_vel_all = cell2mat(run_vel_all_cell);
        avgavgvel(odorpd) = nanmean(run_vel_all);
        
        %average distance / run
        avgrunlength(odorpd) = nanmean(distance_final);
        %total time (should be same as period time)
        totaltime = runsduration_total+stopduration_total;
        %then save it for all periods
        matfortotaltime(odorpd) = totaltime;
        
        %histogram and plotting
        avg_velocity_hist = (0:(2/60):2);
        durationsecs_hist = (0:(40/60):40);
        stopsecs_hist = (0:(20/60):20);
        runlength_hist = (0:(17/60):17);%for what?
        
        %run duration plot
        subplot(3,3,odorpd)
        
        cc = histc(runsduration_secs,durationsecs_hist);
        bar(durationsecs_hist, cc, 'histc'); hold on
        plot([avgrunduration(odorpd) avgrunduration(odorpd) ],[0 100],'r:');
        
        xlim([0,40])
        ylim([0,20]);
        xlabel('Run Duration (secs)');
        ylabel('Number of Runs');
        if odorpd ==1
            title({fig_title; period_name{odorpd};[' ']},'interpreter','none','fontweight','bold');
        elseif odorpd ==2
            title({[' '];period_name{odorpd};['Run Duration']},'interpreter','none','fontweight','bold');
        else
            title({period_name{odorpd};[' ']},'fontweight','bold');
        end
        
        text(2, 19, ['# Runs = ' num2str(numruns(odorpd))], 'FontSize', 8);
        text(2, 16, ['Avg. Run = ' num2str(avgrunduration(odorpd),'%4.2f') 's'], 'FontSize',8);
        text(2, 13, ['Total Run Time = ' num2str(runsduration_total,'%4.2f') 's'], 'FontSize', 8);
        
        set(gca,'box','off');
        
        
        %stop duration plot
        subplot(3,3,(odorpd +3));
        
        cc = histc(stopsduration_secs,stopsecs_hist);
        bar(stopsecs_hist, cc, 'histc');hold on
        plot([avgstopduration(odorpd) avgstopduration(odorpd) ],[0 100],'r:');
        
        xlim([0,20])
        ylim([0,20])
        xlabel('Stops Duration (secs)');
        ylabel('Number of Stops');
        if odorpd ==2
            title('Stop Duration','fontweight','bold');
        end
        
        text(2, 19, ['# Stops = ' num2str(numstops(odorpd))], 'FontSize', 8);
        text(2, 16, ['Avg. Stop = ' num2str(avgstopduration(odorpd),'%4.2f') 's'], 'FontSize', 8);
        text(2, 13, ['Total Stop Time = ' num2str(stopduration_total,'%4.2f') 's'], 'FontSize',8);
        set(gca,'box','off');
        
        
        
        %average velocity plot
        subplot(3,3,odorpd+6);
        cc = histc(avg_velocity,avg_velocity_hist);
        bar(avg_velocity_hist, cc, 'histc');    hold on;
        plot([avgavgvel(odorpd) avgavgvel(odorpd)],[0 100],'r:');
        
        xlabel('avg. run velocity (cm/sec)');
        ylabel('number of runs');
        ylim ([0 10]);
        xlim ([0 2]);
        if odorpd ==2
            title('Average velocity of runs','fontweight','bold');
        end
        
        text(.75, 8, ['avg. vel./run = ' num2str(avgavgvel(odorpd),'%4.2f') 'cm/sec'], 'fontsize', 8);
        set(gca,'box','off');
        
        statistics_eachvid(odorpd,:) = {runsduration_secs, stopsduration_secs, avg_velocity, distance_final};
        
        clear runsduration runsduration_secs distance_final avg_velocity stopsduration stopsduration_secs
        
    end
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    %         saveas(gcf, [fig_title ' velocityplot.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    %% run/stop into in/out (V14)
    [vel_in_run, vel_in_stop, vel_out_run, vel_out_stop] =...
        vel_in_out_divider(velocity_classified, inside_rim,timeperiods,odoron_frame);
    
    figure
    set(gcf, 'Position',[300 10 900 700]);
    
    for period = 1:2
        
        % calculating run duration, run velocity for each period
        % in
        for x = 1:length(vel_in_run{period})
            A = vel_in_run{period}{x};
            runsduration_in(x) = length(A);%in frame
            runsduration_secs_in(x) = (runsduration_in(x))/framespertimebin;%in sec
            
            distance_final_in(x) = nanmean(A) * runsduration_secs_in(x); % in cm
            avg_velocity_in(x) = nanmean(A); % average velocity/run in cm/sec
        end
        
        %calculating stop duration
        for x = 1:length(vel_in_stop{period})
            A = vel_in_stop{period}{x};
            stopsduration_in(x) = length(A);
            stopsduration_secs_in(x) = (stopsduration_in(x))/framespertimebin;
        end
        
        %how many runs or stops/period
        numruns_in(period) = 0; numstops_in(period) = 0;
        if runsduration_in ~= 0
            numruns_in(period) = numel(vel_in_run{period});
        end
        
        if stopsduration_in ~= 0
            numstops_in(period) = numel(vel_in_stop{period});
        end
        
        %average stop duration in sec and total time
        avgstopduration_in(period) = nanmean(stopsduration_secs_in);
        stopduration_total_in = sum(stopsduration_secs_in);
        
        %average run duration in sec and total time
        avgrunduration_in(period) = nanmean(runsduration_secs_in);
        runsduration_total_in = sum(runsduration_secs_in);
        
        %average velocity of all runs
        %         avgavgvel_in(period) = nanmean(avg_velocity_in);%till V13
        %collect all the run velocity and get the mean (V14)
        run_vel_in_cell = vel_in_run{period}; run_vel_in_cell = run_vel_in_cell';
        run_vel_in_all = cell2mat(run_vel_in_cell);
        avgavgvel_in(period) = nanmean(run_vel_in_all);
        
        %average distance / run
        avgrunlength_in(period) = nanmean(distance_final_in);
        %total time (should be same as period time)
        totaltime_in = runsduration_total_in + stopduration_total_in;
        %then save it for all periods
        matfortotaltime_in(period) = totaltime_in;
        
        %histogram and plotting
        avg_velocity_hist = (0:(2/60):2);
        durationsecs_hist = (0:(40/60):40);
        stopsecs_hist = (0:(20/60):20);
        runlength_hist = (0:(17/60):17);%for what?
        
        %run duration plot
        subplot(3,4,period)
        
        cc = histc(runsduration_secs_in,durationsecs_hist);
        bar(durationsecs_hist, cc, 'histc'); hold on
        plot([avgrunduration_in(period) avgrunduration_in(period) ],[0 100],'r:');
        
        xlim([0,40])
        ylim([0,20]);
        xlabel('Run Duration (secs)');
        ylabel('Number of Runs');
        if period ==1
            title({fig_title; period_name{period};['IN']},'interpreter','none','fontweight','bold');
        elseif period ==2
            title({[' '];period_name{period};['Run Duration']},'interpreter','none','fontweight','bold');
        else
            title({period_name{period};[' ']},'fontweight','bold');
        end
        
        text(2, 19, ['# Runs = ' num2str(numruns_in(period))], 'FontSize', 8);
        text(2, 16, ['Avg. Run = ' num2str(avgrunduration_in(period),'%4.2f') 's'], 'FontSize',8);
        text(2, 13, ['Total Run Time = ' num2str(runsduration_total_in,'%4.2f') 's'], 'FontSize', 8);
        
        set(gca,'box','off');
        
        
        %stop duration plot
        subplot(3,4,(period +4));
        
        cc = histc(stopsduration_secs_in,stopsecs_hist);
        bar(stopsecs_hist, cc, 'histc');hold on
        plot([avgstopduration_in(period) avgstopduration_in(period) ],[0 100],'r:');
        
        xlim([0,20])
        ylim([0,20])
        xlabel('Stops Duration (secs)');
        ylabel('Number of Stops');
        if period ==2
            title('Stop Duration','fontweight','bold');
        end
        
        text(2, 19, ['# Stops = ' num2str(numstops_in(period))], 'FontSize', 8);
        text(2, 16, ['Avg. Stop = ' num2str(avgstopduration_in(period),'%4.2f') 's'], 'FontSize', 8);
        text(2, 13, ['Total Stop Time = ' num2str(stopduration_total_in,'%4.2f') 's'], 'FontSize',8);
        set(gca,'box','off');
        
        
        
        %average velocity plot
        subplot(3,4,period+8);
        cc = histc(avg_velocity_in,avg_velocity_hist);
        bar(avg_velocity_hist, cc, 'histc');    hold on;
        plot([avgavgvel_in(period) avgavgvel_in(period)],[0 100],'r:');
        
        xlabel('avg. run velocity (cm/sec)');
        ylabel('number of runs');
        ylim ([0 10]);
        xlim ([0 2]);
        if period ==2
            title('Average velocity of runs','fontweight','bold');
        end
        
        text(.2, 8, ['avg. vel./run = ' num2str(avgavgvel_in(period),'%4.2f') 'cm/sec'], 'fontsize', 8);
        set(gca,'box','off');
        
        statistics_eachvid_in(period,:) = {runsduration_secs_in, stopsduration_secs_in, avg_velocity_in, distance_final_in};
        
        clear runsduration_in runsduration_secs_in distance_final_in avg_velocity_in stopsduration_in stopsduration_secs_in
        
        
        %OUT
        
        for x = 1:length(vel_out_run{period})
            A = vel_out_run{period}{x};
            runsduration_out(x) = length(A);%in frame
            runsduration_secs_out(x) = (runsduration_out(x))/framespertimebin;%in sec
            
            distance_final_out(x) = nanmean(A) * runsduration_secs_out(x); % in cm
            avg_velocity_out(x) = nanmean(A); % average velocity/run in cm/sec
        end
        
        %calculating stop duration
        for x = 1:length(vel_out_stop{period})
            A = vel_out_stop{period}{x};
            stopsduration_out(x) = length(A);
            stopsduration_secs_out(x) = (stopsduration_out(x))/framespertimebin;
        end
        
        %how many runs or stops/period
        
        numruns_out(period) = 0; numstops_out(period) = 0;
        if runsduration_out ~= 0
            numruns_out(period) = numel(vel_out_run{period});
        end
        
        if stopsduration_out ~= 0
            numstops_out(period) = numel(vel_out_stop{period});
        end
        
        
        %average stop duration in sec and total time
        avgstopduration_out(period) = nanmean(stopsduration_secs_out);
        stopduration_total_out = sum(stopsduration_secs_out);
        
        %average run duration in sec and total time
        avgrunduration_out(period) = nanmean(runsduration_secs_out);
        runsduration_total_out = sum(runsduration_secs_out);
        
        %average velocity of all runs
        %         avgavgvel_out(period) = nanmean(avg_velocity_out);
        %collect all the run velocity and get the mean (V14)
        run_vel_out_cell = vel_out_run{period}; run_vel_out_cell = run_vel_out_cell';
        run_vel_out_all = cell2mat(run_vel_out_cell);
        avgavgvel_out(period) = nanmean(run_vel_out_all);
        
        %average distance / run
        avgrunlength_out(period) = nanmean(distance_final_out);
        %total time (should be same as period time)
        totaltime_out = runsduration_total_out + stopduration_total_out;
        %then save it for all periods
        matfortotaltime_out(period) = totaltime_out;
        
        %histogram and plotting
        avg_velocity_hist = (0:(2/60):2);
        durationsecs_hist = (0:(40/60):40);
        stopsecs_hist = (0:(20/60):20);
        runlength_hist = (0:(17/60):17);%for what?
        
        %run duration plot
        subplot(3,4,period+2)
        
        cc = histc(runsduration_secs_out,durationsecs_hist);
        bar(durationsecs_hist, cc, 'histc'); hold on
        plot([avgrunduration_out(period) avgrunduration_out(period) ],[0 100],'r:');
        
        xlim([0,40])
        ylim([0,20]);
        xlabel('Run Duration (secs)');
        ylabel('Number of Runs');
        if period ==1
            title({[' ']; period_name{period};['OUT']},'interpreter','none','fontweight','bold');
        elseif period ==2
            title({[' '];period_name{period};['Run Duration']},'interpreter','none','fontweight','bold');
        else
            title({period_name{period};[' ']},'fontweight','bold');
        end
        
        text(2, 19, ['# Runs = ' num2str(numruns_out(period))], 'FontSize', 8);
        text(2, 16, ['Avg. Run = ' num2str(avgrunduration_out(period),'%4.2f') 's'], 'FontSize',8);
        text(2, 13, ['Total Run Time = ' num2str(runsduration_total_out,'%4.2f') 's'], 'FontSize', 8);
        
        set(gca,'box','off');
        
        
        %stop duration plot
        subplot(3,4,(period +6));
        
        cc = histc(stopsduration_secs_out,stopsecs_hist);
        bar(stopsecs_hist, cc, 'histc');hold on
        plot([avgstopduration_out(period) avgstopduration_out(period) ],[0 100],'r:');
        
        xlim([0,20])
        ylim([0,20])
        xlabel('Stops Duration (secs)');
        ylabel('Number of Stops');
        if period ==2
            title('Stop Duration','fontweight','bold');
        end
        
        text(2, 19, ['# Stops = ' num2str(numstops_out(period))], 'FontSize', 8);
        text(2, 16, ['Avg. Stop = ' num2str(avgstopduration_out(period),'%4.2f') 's'], 'FontSize', 8);
        text(2, 13, ['Total Stop Time = ' num2str(stopduration_total_out,'%4.2f') 's'], 'FontSize',8);
        set(gca,'box','off');
        
        
        
        %average velocity plot
        subplot(3,4,period+10);
        cc = histc(avg_velocity_out,avg_velocity_hist);
        bar(avg_velocity_hist, cc, 'histc');    hold on;
        plot([avgavgvel_out(period) avgavgvel_out(period)],[0 100],'r:');
        
        xlabel('avg. run velocity (cm/sec)');
        ylabel('number of runs');
        ylim ([0 10]);
        xlim ([0 2]);
        if period ==2
            title('Average velocity of runs','fontweight','bold');
        end
        
        text(.2, 8, ['avg. vel./run = ' num2str(avgavgvel_out(period),'%4.2f') 'cm/sec'], 'fontsize', 8);
        set(gca,'box','off');
        
        statistics_eachvid_out(period,:) = {runsduration_secs_out, stopsduration_secs_out, avg_velocity_out, distance_final_out};
        
        clear runsduration_out runsduration_secs_out distance_final_out avg_velocity_out stopsduration_out stopsduration_secs_out
    end
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    
    %% runs entirely inside VS runs entire outisde
    [run_in_entire,run_out_entire] =...
        run_in_out_divider(velocity_classified_binary, inside_rim,runstops,timeperiods,odoron_frame)
    
    
    %%
    %divide velocity data into two groups : short time in/transit vs long time in/transit
    %this assumes that the real crossing data is saved after 10 seconds in
    %arrays. Output 'avg_...' is MEDIAN VALUE!
    
    %set the time limit/threshold to use to separate short and long crossings
    how_short2 = framespertimebin; %1 sec
    
    [vel_o2i_before_short,vel_o2i_during_short,vel_o2i_after_short,...
        vel_o2i_before_long,vel_o2i_during_long,vel_o2i_after_long,...
        vel_i2o_before_short,vel_i2o_during_short,vel_i2o_after_short,...
        vel_i2o_before_long,vel_i2o_during_long,vel_i2o_after_long,...
        avg_vel_o2i_short,avg_vel_o2i_long,avg_vel_i2o_short,avg_vel_i2o_long]...
        = short_long_crossings(how_short2,velocity_in2out_before,velocity_in2out_during,...
        velocity_in2out_after,velocity_out2in_before,velocity_out2in_during,velocity_out2in_after,...
        framespertimebin,timebefore,timetotal);
    
    
    
    %%
    %PLOT VELOCITYATCROSSING
    figure
    set(gcf,'color','white','Position',[520 20 700 800]);
    
    period_name = {'Before','During','After'};
    %x axis range to convert frame# to time (sec)
    x_range = [(-timebefore):1/framespertimebin:timetotal-timebefore-1/framespertimebin];
    
    %for crossing out2in
    %before
    for period = 1:3
        subplot(5,2,2*period-1)
        if period == 1 %before
            for h = 1:size(velocity_out2in_before,2);
                p = rem(h,20)+1;
                plot (x_range,velocity_out2in_before(:,h) ,'color', cmap(p,:))
                hold on
            end
        elseif period ==2 %during for h = 1:size(velocity_out2in_during,2);
            for h = 1:size(velocity_out2in_during,2);
                p = rem(h,20)+1;
                plot (x_range,velocity_out2in_during(:,h) ,'color', cmap(p,:))
                hold on
            end
            
        else %after
            for h = 1:size(velocity_out2in_after,2);
                p = rem(h,20)+1;
                plot (x_range,velocity_out2in_after(:,h) ,'color', cmap(p,:))
                hold on
            end
        end
        xlim([min(x_range) max(x_range)]);
        ylim ([0 vel_ylim(2)])
        plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
        title(['Crossing in: ' period_name{period}],'fontsize',9);
        %     xlabel('frame number','fontsize',9);
        ylabel(vel_unit,'fontsize',9);
        xlabel('time(sec)');
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    end
    
    %for crossing in2out
    %before
    for period = 1:3
        subplot(5,2,2*period)
        if period == 1 %before
            for h = 1:size(velocity_in2out_before,2);
                p = rem(h,20)+1;
                plot (x_range,velocity_in2out_before(:,h) ,'color', cmap(p,:))
                hold on
            end
        elseif period ==2 %during for h = 1:size(velocity_out2in_during,2);
            for h = 1:size(velocity_in2out_during,2);
                p = rem(h,20)+1;
                plot (x_range,velocity_in2out_during(:,h) ,'color', cmap(p,:))
                hold on
            end
            
        else %after
            for h = 1:size(velocity_in2out_after,2);
                p = rem(h,20)+1;
                plot (x_range,velocity_in2out_after(:,h) ,'color', cmap(p,:))
                hold on
            end
        end
        xlim([min(x_range) max(x_range)]);
        ylim ([0 vel_ylim(2)])
        plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
        title(['Crossing Out: ' period_name{period}],'fontsize',9);
        %     xlabel('frame number','fontsize',9);
        ylabel(vel_unit,'fontsize',9);
        xlabel('time(sec)');
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    end
    
    
    %average
    subplot(5,2,7)
    %crossing out2in
    for i=1:3
        plot(x_range,avg_vel_o2i_short(:,i),'color',color(i,:));hold on
    end
    xlim([min(x_range) max(x_range)]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    xlabel('time(sec)','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    title('short Crossing In (MEDIAN)','fontsize',10,'fontweight','b');
    
    subplot(5,2,8)
    for i=1:3
        plot(x_range,avg_vel_i2o_short(:,i),'color',color(i,:));hold on
    end
    xlim([min(x_range) max(x_range)]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    xlabel('time(sec)','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    title('short Crossing Out (MEDIAN)','fontsize',10,'fontweight','b');
    
    subplot(5,2,9)
    for i=1:3
        plot(x_range,avg_vel_o2i_long(:,i),'color',color(i,:));hold on
    end
    
    xlim([min(x_range) max(x_range)]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    xlabel('time(sec)','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    title(' Long Crossing in (MEDIAN)','fontsize',10,'fontweight','b');
    
    subplot(5,2,10)
    for i=1:3
        plot(x_range,avg_vel_i2o_long(:,i),'color',color(i,:));hold on
    end
    
    xlim([min(x_range) max(x_range)]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    xlabel('time(sec)','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    title('Long Crossing out (MEDIAN)','fontsize',10,'fontweight','b');
    
    ax = axes('position',[0,0,1,1],'visible','off');
    tx = text(0.3,0.97,[fig_title ' velocity at crossing events']);
    set(tx,'fontweight','bold');
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    %         saveas(gcf, [fig_title ' velocityplot.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    %%
    %plot average with standard deviation
    figure
    set(gcf,'color','white','Position',[520 50 800 600]);
    
    for i=1:3
        subplot(3,2,2*i-1)
        er_fig=errorbar(x_range,velocity_o2i_avg(:,i),velocity_o2i_std(:,i),'color',grey); hold on
        errorbar_tick(er_fig,0);
        plot(x_range,velocity_o2i_avg(:,i),'color',color(i,:));
        xlim([min(x_range) max(x_range)]);
        ylim ([0 vel_ylim(2)])
        plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
        title('Crossing in: MEDIAN + stdev');
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',10,'tickdir','out');
    end
    xlabel('time (sec)');
    ylabel(vel_unit,'fontsize',9);
    % title({fig_title; 'Velocity at crossing In'});
    
    
    for i=1:3
        subplot(3,2,2*i)
        er_fig = errorbar(x_range,velocity_i2o_avg(:,i),velocity_i2o_std(:,i),'color',grey); hold on
        errorbar_tick(er_fig,0);
        plot(x_range,velocity_i2o_avg(:,i),'color',color(i,:))
        xlim([min(x_range) max(x_range)]);
        ylim ([0 vel_ylim(2)])
        plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
        title('Crossing out: MEDIAN + stdev');
        %     xlabel('frame number','fontsize',9);
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',10,'tickdir','out');
    end
    ylabel(vel_unit,'fontsize',9);
    xlabel('time (sec)');
    
    ax = axes('position',[0,0,1,1],'visible','off');
    tx = text(0.3,0.97,[fig_title ' velocity at crossing events']);
    set(tx,'fontweight','bold','interpreter','none');
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    %         saveas(gcf, [fig_title ' velocityatcrossing.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    
    %%
    
    %plot the radius velocity vs radius (binned)
    figure
    set(gcf,'color','w','position',[300 50 800 700]);
    
    subplot(5,1,1)
    plot([bin_number bin_number],[0 2],'k--');hold on
    plot(radius_binned(1:timeperiods(2)),vel_total(1:timeperiods(2)),'go','markersize',3); hold on
    plot(avg_vel_by_radius_before_median,'g','linewidth',2);
    
    plot(radius_binned(1:timeperiods(2))+0.3,rad_vel_sqrt(1:timeperiods(2)),'+','color',grey,'markersize',3);
    plot([1.3:max(radius_binned)+0.3],avg_radvel_by_radius_before_median,'color',grey,'linewidth',2);
    
    
    set(gca,'xlim',[0 max(radius_binned) + 1],'ylim', [0 vel_ylim(2)],'box','off','tickdir','out','xtick',[1:2:100]);
    % leg1=legend('velocity','radial velocity');
    % set(leg1,'box','off');
    ylabel(vel_unit);
    
    title({[fig_title ' velocity and radial velocity vs radius (binned)+ median'];'before'},'interpreter','none');
    
    
    subplot(5,1,2)
    plot([bin_number bin_number],[0 2],'k--');hold on
    plot(radius_binned(odoron_frame:odoroff_frame),vel_total(odoron_frame:odoroff_frame),'ro','markersize',3);hold on
    plot(avg_vel_by_radius_during_median,'r','linewidth',2);
    
    plot(radius_binned(odoron_frame:odoroff_frame)+0.3,rad_vel_sqrt(odoron_frame:odoroff_frame),'+','color',grey,'markersize',3);
    plot([1.3:max(radius_binned)+0.3],avg_radvel_by_radius_during_median,'color',grey,'linewidth',2);
    
    
    set(gca,'xlim',[0 max(radius_binned) + 1],'ylim', [0 vel_ylim(2)],'box','off','tickdir','out','xtick',[1:2:100]);
    title('During');
    
    subplot(5,1,3)
    plot([bin_number bin_number],[0 2],'k--');hold on
    plot(radius_binned(odoroff_frame:end),vel_total(odoroff_frame:end),'bo','markersize',3);hold on
    plot(avg_vel_by_radius_after_median,'linewidth',2);
    
    plot(radius_binned(odoroff_frame:end)+0.3,rad_vel_sqrt(odoroff_frame:end),'+','color',grey,'markersize',3);
    plot([1.3:max(radius_binned)+0.3],avg_radvel_by_radius_after_median,'color',grey,'linewidth',2);
    
    set(gca,'xlim',[0 max(radius_binned) + 1],'ylim', [0 vel_ylim(2)],'box','off','tickdir','out','xtick',[1:2:100]);
    title('After');
    
    subplot(5,1,4)
    plot([bin_number bin_number],[0 2],'k--');hold on
    
    plot(avg_vel_by_radius_before_median,'g','linewidth',2);hold on
    plot(avg_vel_by_radius_during_median,'r','linewidth',2);
    plot(avg_vel_by_radius_after_median,'linewidth',2);
    set(gca,'xlim',[0 max(radius_binned) + 1],'ylim',[0 vel_ylim(2)],'box','off','tickdir','out','xtick',[1:2:100]);
    title('average of velocity in each period (MEDIAN)');
    
    subplot(5,1,5)
    plot([bin_number bin_number],[0 2],'k--');hold on
    plot(avg_radvel_by_radius_before_median,'g','linewidth',2);
    plot(avg_radvel_by_radius_during_median,'r','linewidth',2);
    plot(avg_radvel_by_radius_after_median,'linewidth',2);
    set(gca,'xlim',[0 max(radius_binned) + 1],'ylim',[0 vel_ylim(2)-1],'box','off','tickdir','out','xtick',[1:2:100]);
    title('average of radial velocity in each period(MEDIAN)');
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    
    %         saveas(gcf,[fig_title ' vel_VS_radius.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    
    
    %%
    %plot 1) the radius (distance from the center) VS time
    % 2) radial velocity VS time
    % 3) radial velocity as a function of radius
    
    figure
    set(gcf,'position',[400 20 1200 800])
    
    subplot(3,1,1)
    plot(1:timeperiods(2), radius_fly(1:timeperiods(2)),'g');hold on;
    plot(timeperiods(2):odoron_frame, radius_fly(timeperiods(2):odoron_frame),'color',grey);
    plot(odoron_frame:odoroff_frame, radius_fly(odoron_frame:odoroff_frame),'r');
    plot(odoroff_frame:timeperiods(4), radius_fly(odoroff_frame:timeperiods(4)),'b');
    line([0 timeperiods(4)],[circRad circRad],'linestyle',':','color',grey);
    xlim([1 timeperiods(4)]);
    ylim([0 max(radius_fly)+5]);
    ylabel('Distance from the center (in pixel)');
    
    set(gca,'box','off','xtick',[],'tickdir','out');
    title({fig_title; ' radial distance as a function of time'},'interpreter','none');
    
    
    subplot(3,1,2)
    plot(rad_vel_sqrt,'k-');hold on;
    xlim([1 timeperiods(4)]);
    ylim([0 vel_ylim(2)-1]);
    set(gca,'box','off','tickdir','out');
    ylabel(vel_unit);
    xlabel('time (frame#)');
    title(' radial velocity as a function of time');
    
    subplot(3,1,3)
    plot(radius_fly(1:timeperiods(2)),rad_vel_sqrt(1:timeperiods(2)),'go','markersize',1);hold on
    plot(radius_fly(odoron_frame:odoroff_frame),rad_vel_sqrt(odoron_frame:odoroff_frame),'ro','markersize',1);
    % plot(radius_fly(odoroff_frame:timeperiods(4)),rad_vel(odoroff_frame:timeperiods(4)),'o','markersize',1);
    ylabel(vel_unit);
    xlabel('radius (pixel)');
    set(gca,'box','off','tickdir','out','xlim',[0 max(radius_fly)+2],'ylim',[0 vel_ylim(2)-1] );
    
    % plot([0 max(radius_fly+2)],[0 0], 'k:','linewidth',2);
    plot([circRad circRad],[-1.5 1.5], 'k:','linewidth',2);
    
    title('radial velocity as a function of radius');
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    
    %         saveas(gcf,[fig_title ' radial vel.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    %%
    %velocity as a function of radius
    figure
    set(gcf,'position',[400 100 800 600]);
    
    %BEFORE
    subplot(3,1,1)
    plot(radius_fly(1:timeperiods(2)),vel_total(1:timeperiods(2)),'go','markersize',2);
    hold on
    plot([circRad circRad],[0 2],'k:','linewidth',2);
    ylabel(vel_unit);
    set(gca,'box','off','tickdir','out','xlim',[0 max(radius_fly)+2],'xtick',[],'ylim',[0 vel_ylim(2)]);
    title([fig_title '; velocity as a function of radius'],'fontweight','b','interpreter','none');
    
    %DURING
    subplot(3,1,2)
    plot(radius_fly(timeperiods(2)+1:odoron_frame-1),vel_total(timeperiods(2)+1:odoron_frame-1),...
        'o','markersize',2,'color',grey);hold on
    plot(radius_fly(odoron_frame:timeperiods(3)),vel_total(odoron_frame:timeperiods(3)),'ro','markersize',2);
    plot([circRad circRad],[0 2],'k:','linewidth',2);
    set(gca,'box','off','tickdir','out','xlim',[0 max(radius_fly)+2],'xtick',[],'ylim',[0 vel_ylim(2)]);
    ylabel(vel_unit);
    
    %AFTER
    subplot(3,1,3)
    plot(radius_fly(timeperiods(3)+1:end),vel_total(timeperiods(3)+1:end),'o','markersize',2);hold on
    plot([circRad circRad],[0 2],'k:','linewidth',2);
    set(gca,'box','off','tickdir','out','xlim',[0 max(radius_fly)+2],'ylim',[0 vel_ylim(2)]);
    xlabel('radius (pixel)');
    ylabel(vel_unit);
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    %         saveas(gcf,[fig_title ' vel_rad_plot.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    
    %% acceleration calculation
    %unit: cm/sec^2
    accel_unit = 'acceleration(cm/sec^2)';
    accel_ylim = [-.5 .5];
    
    acceleration = vel_total(2:end) - vel_total(1:end-1);
    %% acceleration at crossing
    
    [accel_in2out_before,accel_in2out_during,accel_in2out_after,...
        accel_out2in_before, accel_out2in_during,accel_out2in_after]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        acceleration,framespertimebin, timeperiods, timebefore, timetotal);
    
    %average: Median
    accel_i2o_avg(:,1) = nanmedian(accel_in2out_before,2);
    accel_i2o_avg(:,2) = nanmedian(accel_in2out_during,2);
    accel_i2o_avg(:,3) = nanmedian(accel_in2out_after,2);
    
    accel_o2i_avg(:,1) = nanmedian(accel_out2in_before,2);
    accel_o2i_avg(:,2) = nanmedian(accel_out2in_during,2);
    accel_o2i_avg(:,3) = nanmedian(accel_out2in_after,2);
    
    %acceleration at crossing plots and averages
    figure
    set(gcf,'color','white','Position',[520 20 700 800]);
    
    %for crossing out2in
    %before
    for period = 1:3
        subplot(4,2,2*period-1)
        if period == 1 %before
            for h = 1:size(accel_out2in_before,2);
                p = rem(h,20)+1;
                plot (x_range,accel_out2in_before(:,h) ,'color', cmap(p,:))
                hold on
            end
        elseif period ==2 %during for h = 1:size(accel_out2in_during,2);
            for h = 1:size(accel_out2in_during,2);
                p = rem(h,20)+1;
                plot (x_range,accel_out2in_during(:,h) ,'color', cmap(p,:))
                hold on
            end
            
        else %after
            for h = 1:size(accel_out2in_after,2);
                p = rem(h,20)+1;
                plot (x_range,accel_out2in_after(:,h) ,'color', cmap(p,:))
                hold on
            end
        end
        xlim([min(x_range) max(x_range)]);
        ylim ([accel_ylim(1) accel_ylim(2)])
        plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
        plot([min(x_range) max(x_range)],[0 0],'k:');
        title(['Crossing in: ' period_name{period}],'fontsize',9);
        %     xlabel('frame number','fontsize',9);
        ylabel(vel_unit,'fontsize',9);
        xlabel('time(sec)');
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    end
    
    %for crossing in2out
    %before
    for period = 1:3
        subplot(4,2,2*period)
        if period == 1 %before
            for h = 1:size(accel_in2out_before,2);
                p = rem(h,20)+1;
                plot (x_range,accel_in2out_before(:,h) ,'color', cmap(p,:))
                hold on
            end
        elseif period ==2 %during for h = 1:size(accel_out2in_during,2);
            for h = 1:size(accel_in2out_during,2);
                p = rem(h,20)+1;
                plot (x_range,accel_in2out_during(:,h) ,'color', cmap(p,:))
                hold on
            end
            
        else %after
            for h = 1:size(accel_in2out_after,2);
                p = rem(h,20)+1;
                plot (x_range,accel_in2out_after(:,h) ,'color', cmap(p,:))
                hold on
            end
        end
        xlim([min(x_range) max(x_range)]);
        ylim ([accel_ylim(1) accel_ylim(2)])
        plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
        plot([min(x_range) max(x_range)],[0 0],'k:');
        title(['Crossing Out: ' period_name{period}],'fontsize',9);
        %     xlabel('frame number','fontsize',9);
        ylabel(vel_unit,'fontsize',9);
        xlabel('time(sec)');
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    end
    
    
    %average
    subplot(4,2,7)
    %crossing out2in
    for i=1:3
        plot(x_range, accel_i2o_avg(:,i),'color',color(i,:));hold on
    end
    xlim([min(x_range) max(x_range)]);
    ylim ([accel_ylim(1)+.4 accel_ylim(2)-.4]);
    plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
    plot([min(x_range) max(x_range)],[0 0],'k:');
    xlabel('time(sec)','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    title('acceleration I2O(MEDIAN)','fontsize',10,'fontweight','b');
    
    subplot(4,2,8)
    for i=1:3
        plot(x_range, accel_o2i_avg(:,i),'color',color(i,:));hold on
    end
    xlim([min(x_range) max(x_range)]);
    ylim ([accel_ylim(1)+.4 accel_ylim(2)-.4]);
    plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
    plot([min(x_range) max(x_range)],[0 0],'k:');
    xlabel('time(sec)','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    title('acceleration O2I (MEDIAN)','fontsize',10,'fontweight','b');
    
    ax = axes('position',[0,0,1,1],'visible','off');
    tx = text(0.3,0.97,[fig_title ' Acceleration at crossing events']);
    set(tx,'fontweight','bold','interpreter','none');
    
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    %         saveas(gcf, [fig_title ' velocityplot.png']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    %% curvature calculation
    %the initial 10 frames moving window smoothing is not enough,
    %VB empirically decided that 25 works fairly well
    %I tested smoothing with 10, 15, 20, 25 and 15 seems to be sensitive but
    %not too noisy (9/25/12 SJ)
    Vertices(:,1)= fly_x; %no further smoothing
    Vertices(:,2)= fly_y;
    
    %Check the following link for information about linecurvature2D
    %http://www.mathworks.com/matlabcentral/fileexchange/32696
    k = LineCurvature2D(Vertices);
    k= k(1:end-1);%remove the last point
    k=[k;0]; %add 0 for the last point
    
    k_run=k.*(velocity_classified_binary); %changes all the curvature data during stops to 0
    
    %sharp VS wide turns
    curv_th_s = 1;
    [peaks,frame_turn_sh] = findpeaks(abs(k_run),'MINPEAKHEIGHT',curv_th_s,'MINPEAKDISTANCE',10);
    
    %wide turns
    curv_th_w = .2;
    [peaks,frame_turn] = findpeaks(abs(k_run),'MINPEAKHEIGHT',curv_th_w,'MINPEAKDISTANCE',6);
    
    %wide turns that are not sharp turns
    frame_turn_cv_w = setdiff(frame_turn,frame_turn_sh);
    
    
    % sum of  curvature with sliding windows===================================
    sizewin = 5; %set the size of the sliding window
    
    k_sum_win = nan(1,length(k_run));%pre-allocate an array to save sum of angle from sliding windows
    
    for i=1:sizewin %i = matrix ID
        n = floor(length(k_run(i:end))/sizewin); %how many columns? (or windows)
        temp = k_run(i:i-1+(sizewin*n));%get that part of data
        temp = temp';
        temp2 = reshape(temp,sizewin,n);%reshape to make the row# = sizewin
        k_reshp(i) = {temp2}; %save in a cell array
        k_sum = sum(temp2);%for each window, get the sum of angle
        
        for n=1:length(k_sum) %then save them according to the sliding window order
            k_sum_win((n-1)*sizewin + i) = k_sum(n);
        end
        
    end
    
    %sliding 2 frames by removing the last two frames and add two frames
    k_sum_win = k_sum_win(1:end-2);
    k_sum_win = [0 0 k_sum_win];
    %==========================================================================
    
    %==turning/curved walking analysis without using 'findpeaks'===============
    turn_th = 0.17; %set the threshold to define 'curving/turning' for sliding window-sum
    
    cv_frame_pos = find(k_sum_win > turn_th); %get the frame #: +
    cv_frame_neg = find(k_sum_win < -turn_th);
    
    % 1. if there is one frame between two turns, label that frame as also a
    % turn
    % 2. if one turning is less than 3 frame-long, discard those turns
    
    %if there is a period where only one frame is missing from the turn, also
    %label them as turn
    temp = cv_frame_pos(find(diff(cv_frame_pos) == 2));
    frame_bw_turn_pos = temp+1;
    temp = cv_frame_neg(find(diff(cv_frame_neg) == 2));
    frame_bw_turn_neg = temp+1;
    
    %make a new array to save frame # from both cv_frame_ and frame_bw_turn_
    temp = horzcat(cv_frame_pos,frame_bw_turn_pos);
    cv_frame_pos1 = sort(temp);
    temp = horzcat(cv_frame_neg,frame_bw_turn_neg);
    cv_frame_neg1 = sort(temp);
    
    %+ and - together
    cv_frame = horzcat(cv_frame_pos1,cv_frame_neg1);
    cv_frame = sort(cv_frame); %this is the variable used for quantification
    
    %sort out individual curved walks
    temp = diff(cv_frame);
    discontinuous = (find(temp ~= 1));%discontinous points; in between consecutive curving/turning (end of one turn)
    
    starts = [cv_frame(1) cv_frame(discontinuous+1)]; %start of each turn
    ends = [cv_frame(discontinuous) cv_frame(end)]; %end of each turn
    
    each_curv = cell(length(starts),1);
    for i=1:length(starts)
        each_curv{i} =(starts(i):ends(i))'; %this cell array contains all the curved walks, each as a cell
    end
    
    %get rid of 1-frame or 2 frame long curving/turning
    % to exclude other (e.g. 3 frame-long, or 4 frame-long), just add more
    % lines such as threeframeturn = find(curv_length ==3) etc...
    curv_length = cellfun(@length,each_curv);
    oneframeturn = find(curv_length == 1); %which cell's length is one?
    twoframeturn = find(curv_length ==2); %2 frame turn?
    onetwo_turn = [oneframeturn; twoframeturn];
    onetwo_turn = sort(onetwo_turn);%oneframeturn + twoframeturn
    
    long_turn = [1:length(each_curv)];
    long_turn = setdiff(long_turn,onetwo_turn); %find turns that are not one or two frames-long
    long_turn = long_turn'; %index for 3 or longer frame/turn
    curv_long = each_curv(long_turn); %get turnings that are longer than 3 frames
    
    %convert from cell array to matrix
    curv_long_mat = cell2mat(curv_long);%this array contains all the frame # for curved walks
    
    %==========================================================================
    
    %% quantification of turns/straight walk/curved walk
    
    % TURN from k_run thresholding
    % how many sharp turns/period, in/out
    %quantify turns by 'periods' then by 'in' and 'out' (all turns)
    
    %how many frames in/out in each period
    frame_in(1) = sum(inside_rim(1:timeperiods(2)));
    frame_in(2) = sum(inside_rim(odoron_frame:odoroff_frame-1));
    frame_in(3) = sum(inside_rim(odoroff_frame:end));
    
    frame_out(1) = timeperiods(2) - frame_in(1);
    frame_out(2) = (odoroff_frame-odoron_frame) - frame_in(2);
    frame_out(3) = (length(inside_rim) - odoroff_frame+1) - frame_in(3);
    
    %SHARP TURNS : how many sharp turns/sec?==================================
    
    %pre-allocate arrays
    turn_before = nan(1); turn_during = nan(1); turn_after = nan(1);
    turn_before_in = nan(1); turn_during_in = nan(1); turn_after_in = nan(1);
    turn_before_out = nan(1); turn_during_out = nan(1); turn_after_out = nan(1);
    
    
    p=1;q=1;r=1;
    s=1; t=1; u=1; v=1; w=1; y=1;
    for n=1:length(frame_turn_sh)
        ft = frame_turn_sh(n);
        if ft <= timeperiods(2) %before
            turn_before(p) = ft; p=p+1;
            
            if inside_rim(ft,1) ==1 %in
                turn_before_in(s) = ft; s=s+1;
            else
                turn_before_out(t) = ft; t=t+1;
            end
            
        elseif odoron_frame <= ft && ft < odoroff_frame %during
            turn_during(q) = ft; q=q+1;
            
            if inside_rim(ft,1) ==1 %in
                turn_during_in(u) = ft; u=u+1;
            else
                turn_during_out(v) = ft; v=v+1;
            end
            
        elseif odoroff_frame <= ft %after
            turn_after(r) = ft; r=r+1;
            
            if inside_rim(ft,1) ==1 %in
                turn_after_in(w) = ft; w=w+1;
            else
                turn_after_out(y) = ft; y=y+1;
            end
            
        end
    end
    turn_before = turn_before'; turn_during = turn_during'; turn_after= turn_after';
    turn_before_in = turn_before_in'; turn_before_out = turn_before_out';
    turn_during_in = turn_during_in'; turn_during_out = turn_during_out';
    turn_after_in = turn_after_in'; turn_after_out = turn_after_out';
    
    %how many turns/period?
    NumTurn = zeros(3,1);
    for i=1:3
        if i==1
            AA = turn_before;
        elseif i==2
            AA = turn_during;
        else
            AA = turn_after;
        end
        
        if isnan(AA) == 0
            NumTurn(i) = length(AA);
        end
    end
    
    %calculate turn frequency (turn #/sec)/period
    turn_rate = zeros(3,1);
    
    turn_rate(1) = NumTurn(1)/(timeperiods(2)/framespertimebin); %in sec
    during_time = (odoroff_frame - odoron_frame+1)/framespertimebin;
    turn_rate(2) = NumTurn(2)/during_time;%in sec
    turn_rate(3) = NumTurn(3)/((length(fly_x)-odoroff_frame+1)/framespertimebin);
    
    
    %how many turns in 'in' VS 'out'?
    NumTurn_in =nan(3,1);
    NumTurn_out = nan(3,1);
    for period =1:3
        if period ==1
            AA = turn_before_in; BB = turn_before_out;
        elseif period ==2
            AA = turn_during_in; BB = turn_during_out;
        else
            AA = turn_after_in; BB = turn_after_out;
        end
        
        if isnan(AA) == 0 %only non-nan values
            NumTurn_in(period) = length(AA);
        end
        
        if isnan(BB) == 0
            NumTurn_out(period) = length(BB);
        end
        
        
    end
    
    %arrays to save turn number in / out per fly
    turn_rate_in = nan(3,1);
    turn_rate_out = nan(3, 1);
    
    for i=1:3
        turn_rate_in(i) = NumTurn_in(i)/(frame_in(i)/framespertimebin);
        turn_rate_out(i) = NumTurn_out(i)/(frame_out(i)/framespertimebin);
    end
    %==========================================================================
    
    % quantification: curved walk
    % this includes the sharp turns, too. But instead of counting each turn as
    % one event, this counts the frame # (length of turns)
    
    curv_before = nan(1); curv_during = nan(1); curv_after = nan(1);
    curv_before_in = nan(1); curv_during_in = nan(1); curv_after_in = nan(1);
    curv_before_out = nan(1); curv_during_out = nan(1); curv_after_out = nan(1);
    
    
    p=1;q=1;r=1;
    s=1; t=1; u=1; v=1; w=1; y=1;
    ft = curv_long_mat;
    for n=1:length(ft)
        
        if ft(n) <= timeperiods(2) %before
            curv_before(p) = ft(n); p=p+1;
            
            if inside_rim(ft(n),1) ==1 %in
                curv_before_in(s) = ft(n); s=s+1;
            else
                curv_before_out(t) = ft(n); t=t+1;
            end
            
        elseif odoron_frame <= ft(n) && ft(n) < odoroff_frame %during
            curv_during(q) = ft(n); q=q+1;
            
            if inside_rim(ft(n),1) ==1 %in
                curv_during_in(u) = ft(n); u=u+1;
            else
                curv_during_out(v) = ft(n); v=v+1;
            end
            
        elseif odoroff_frame <= ft(n) %after
            curv_after(r) = ft(n); r=r+1;
            
            if inside_rim(ft(n),1) ==1 %in
                curv_after_in(w) = ft(n); w=w+1;
            else
                curv_after_out(y) = ft(n); y=y+1;
            end
            
        end
    end
    curv_before = curv_before'; curv_during = curv_during'; curv_after= curv_after';
    curv_before_in = curv_before_in'; curv_before_out = curv_before_out';
    curv_during_in = curv_during_in'; curv_during_out = curv_during_out';
    curv_after_in = curv_after_in'; curv_after_out = curv_after_out';
    
    
    %% what fraction of trajectory is classified as 'curved' VS 'straight'
    % only use 'non-stop' or 'run' portion of trajectory
    
    %frames that are classified as 'stops'
    stop_frames = find(velocity_classified == 0);
    stop_before = find(velocity_classified(1:timeperiods(2)) == 0);
    stop_during = find(velocity_classified(odoron_frame:odoroff_frame-1) == 0)+ odoron_frame-1;
    stop_after = find(velocity_classified(odoroff_frame:end) == 0) + odoroff_frame-1;
    
    %frames in each period that are classified as 'runs'
    run_frames = find(velocity_classified); %nonzeros in velocity_classified
    run_before = find(velocity_classified(1:timeperiods(2)));
    run_during = find(velocity_classified(odoron_frame:odoroff_frame-1))+ odoron_frame-1;
    run_after = find(velocity_classified(odoroff_frame:end)) + odoroff_frame-1;
    
    %run in/out
    fly_inside = find(inside_rim);
    run_before_in = intersect(run_before,fly_inside);
    run_during_in = intersect(run_during,fly_inside);
    run_after_in = intersect(run_after,fly_inside);
    
    run_before_out = setdiff(run_before,run_before_in);
    run_during_out = setdiff(run_during,run_during_in);
    run_after_out = setdiff(run_after,run_after_in);
    % stop and run frames # were confirmed by plotting them !
    
    %how many curving/turning frames per period, in/out (fraction)
    turn_frq = nan(3,1);
    turn_frq(1) = length(curv_before)/length(run_before);
    turn_frq(2) = length(curv_during)/length(run_during);
    turn_frq(3) = length(curv_after)/length(run_after);
    
    turn_frq_in = nan(3,1);
    turn_frq_in(1) = length(curv_before_in)/length(run_before_in);
    turn_frq_in(2) = length(curv_during_in)/length(run_during_in);
    turn_frq_in(3) = length(curv_after_in)/length(run_after_in);
    turn_frq_out = nan(3,1);
    turn_frq_out(1) = length(curv_before_out)/length(run_before_out);
    turn_frq_out(2) = length(curv_during_out)/length(run_during_out);
    turn_frq_out(3) = length(curv_after_out)/length(run_after_out);
    
    %% check what fraction of fly's walk is 'curved' in specific area
    
    %set the size of the area (a ring between two circles) (in cm)
    ring_outer = 1.6;
%     ring_inner = inner_radius;
    ring_inner = 1.2;
 
    %error checking
    if ring_outer <= ring_inner
        display('ring_outer has to be bigger than ring_inner');
    end

    %get xy coordinates for ring_outer and ring_inner
    %use circle fit to find the center and radius
    [ctr_x,ctr_y,circRad] = circfit(in_x,in_y);
    
    %translate x and y points so that the center is (0,0)
    in_x_tsl = in_x - ctr_x;
    in_y_tsl = in_y - ctr_y;
    
    %now increase the IR and find new and bigger ring_outer points
    ring_outer_x = in_x_tsl.*ring_outer/inner_radius;
    ring_outer_y = in_y_tsl.*ring_outer/inner_radius;
    
    %translate the points back
    ring_outer_x = ring_outer_x + ctr_x;
    ring_outer_y = ring_outer_y + ctr_y;
    
    %now increase the IR and find new and bigger ring_inner points
    ring_inner_x = in_x_tsl.*ring_inner/inner_radius;
    ring_inner_y = in_y_tsl.*ring_inner/inner_radius;
    
    %translate the points back
    ring_inner_x = ring_inner_x + ctr_x;
    ring_inner_y = ring_inner_y + ctr_y;
    
    
    %pre-allocate the array to save frame# and radius(cm) of turning in the
    %specified area
    fly_in_ring = nan(length(fly_x),2);
    turn_in_ring = nan(length(fly_x),2);%make the array biggest possible
    n=1;m=1;
    for i=1:length(fly_x)
        if inpolygon(fly_x(i),fly_y(i),ring_inner_x,ring_inner_y) == 0 %if the fly is outside the ring_inner
            if inpolygon(fly_x(i),fly_y(i),ring_outer_x,ring_outer_y) == 1 % and inside the ring_outer
                fly_in_ring(m,1) = i; %save frame # where fly is in the ring
                fly_in_ring(m,2) = radius_fly_cm(i);
                m=m+1;
                if isempty((intersect(i,curv_long_mat))) == 0 %if that frame is marked as 'turning/curving'
                    turn_in_ring(n,1) = i;
                    turn_in_ring(n,2) = radius_fly_cm(i);
                    n= n+1;
                end
            end
        end
    end
    
    %get rid of nans
    rows_nan=(find(isnan(turn_in_ring) ==1));
    turn_in_ring(rows_nan(1:(length(rows_nan)/2)),:) = [];
    rows_nan=(find(isnan(fly_in_ring) ==1));
    fly_in_ring(rows_nan(1:(length(rows_nan)/2)),:) = [];
    
    %if a fly did not go into the ring at all, the following calculation is
    %unnecessary
    
    if isempty(fly_in_ring) == 0 %if a fly did go in to the specified ring
        
        %all the frames where the fly is inside the ring (frame# +
        %radius_fly_cm)
        fly_in_ring_bf=nan(1,2); fly_in_ring_dr=nan(1,2); fly_in_ring_af=nan(1,2);
        
        n=1; m=1; l=1;
        AA = fly_in_ring(:,1);
        for i=1:length(AA)
            if AA(i) < timeperiods(2) %before
                fly_in_ring_bf(n,:) = fly_in_ring(i,:);
                n=n+1;
            elseif odoron_frame <= AA(i) && AA(i) < odoroff_frame
                fly_in_ring_dr(m,:) = fly_in_ring(i,:);
                m=m+1;
            elseif odoroff_frame <= AA(i)
                fly_in_ring_af(l,:) = fly_in_ring(i,:);
                l = l+1;
            end
        end
        
        if isempty(turn_in_ring) == 0 % if there is at least one turn
            %now, divide turns into periods, in VS out
            turn_in_ring_bf=nan(1,2); turn_in_ring_dr=nan(1,2); turn_in_ring_af=nan(1,2);
            n=1; m=1; l=1;
            
            AA = turn_in_ring(:,1);
            for i=1:length(AA)
                if AA(i) < timeperiods(2) %before
                    turn_in_ring_bf(n,:) = turn_in_ring(i,:);
                    n=n+1;
                elseif odoron_frame <= AA(i) && AA(i) < odoroff_frame
                    turn_in_ring_dr(m,:) = turn_in_ring(i,:);
                    m=m+1;
                elseif odoroff_frame <= AA(i)
                    turn_in_ring_af(l,:) = turn_in_ring(i,:);
                    l = l+1;
                end
            end
            
            % calculate the fraction of turning inside the ring / period===============
            turn_fr_ring = nan(3,1);
            
            %get the length of 'fly_in_ring_bf/dr/af' after excluding 'stops'
            for period = 1:3
                %get the array
                if period ==1
                    AA = fly_in_ring_bf(:,1);
                elseif period ==2
                    AA = fly_in_ring_dr(:,1);
                else
                    AA = fly_in_ring_af(:,1);
                end
                
                %check if the frame in the array is labeled as 'stop'
                n=1;BB = nan(1);
                if isnan(AA) == 0 %to avoid error in case AA only contains nan
                    for i=1:length(AA)
                        if velocity_classified(AA(i)) ~= 0 %if velocity_classified is not 0 (stop)
                            BB(n)=AA(i);%save that frame number
                            n=n+1;
                        end
                    end
                end
                
                %save arrays
                if period ==1
                    fly_in_ring_bf_run = BB;
                elseif period ==2
                    fly_in_ring_dr_run = BB;
                else
                    fly_in_ring_af_run = BB;
                end
                clear BB
            end
            
            turn_fr_ring(1) = length(turn_in_ring_bf)/length(fly_in_ring_bf_run);
            turn_fr_ring(2) = length(turn_in_ring_dr)/length(fly_in_ring_dr_run);
            turn_fr_ring(3) = length(turn_in_ring_af)/length(fly_in_ring_af_run);
        
        else %if there was no turn inside the ring
            turn_in_ring_bf=nan(1,2); turn_in_ring_dr=nan(1,2); turn_in_ring_af=nan(1,2);            
            turn_fr_ring = nan(3,1);
            
        end
        
    else %if there was no frame inside the ring
        fly_in_ring_bf=nan(1,2); fly_in_ring_dr=nan(1,2); fly_in_ring_af=nan(1,2);        
        turn_in_ring_bf=nan(1,2); turn_in_ring_dr=nan(1,2); turn_in_ring_af=nan(1,2);
        turn_fr_ring = nan(3,1);
        
    end
    


%==========================================================================


    %check if this works : mark the track inside the 'ring' and mark
    %'turns' inside the 'ring'
    
    figure
    set(gcf,'position',[100 100 1200 400]);
    
    for period =1:2
        if period ==1
            subplot(1,2,1)
            plot(fly_x(1:timeperiods(2)),fly_y(1:timeperiods(2)),'color',grey); %all the track 'before'
            hold on
            plot(fly_x(stop_before),fly_y(stop_before),'k.','markersize',3); %'stops'
            
            %turning
            if isnan(curv_before_in) ==0
            plot(fly_x(curv_before_in),fly_y(curv_before_in),'r.','markersize',3); %curving in'
            end
            
            plot(fly_x(curv_before_out),fly_y(curv_before_out),'g.','markersize',3); %curving out
            
            %turning near the IR
            plot(fly_x(fly_in_ring_bf(:,1)),fly_y(fly_in_ring_bf(:,1)),'bo','markersize',3);%all the frames when the fly was inside the ring
            plot(fly_x(turn_in_ring_bf(:,1)),fly_y(turn_in_ring_bf(:,1)),'ro','markersize',3);%frames when the fly was turning inside the ring
            
            text(50, 10, ['fraction of turning inside the ring is ' num2str(turn_fr_ring(1)) ' (only during runs)']);

            title({[fig_title ' walking track, turns between ' num2str(ring_inner) ' and ' num2str(ring_outer) 'cm']; 'before'});
    
        
        else
            subplot(1,2,2)
            plot(fly_x(odoron_frame:odoroff_frame),fly_y(odoron_frame:odoroff_frame),'color',grey); %all the track 'before'
            hold on
            plot(fly_x(stop_during),fly_y(stop_during),'k.','markersize',3); %'stops'
            
            %turning
            plot(fly_x(curv_during_in),fly_y(curv_during_in),'r.','markersize',3); %curving in'
            plot(fly_x(curv_during_out),fly_y(curv_during_out),'g.','markersize',3); %curving out
            
            %turning near the IR
            plot(fly_x(fly_in_ring_dr(:,1)),fly_y(fly_in_ring_dr(:,1)),'bo','markersize',3);
            plot(fly_x(turn_in_ring_dr(:,1)),fly_y(turn_in_ring_dr(:,1)),'ro','markersize',3);
 
            text(50, 10, ['fraction of turning inside the ring is ' num2str(turn_fr_ring(2))]);
            title( {'\color{red}-curved walk (in) \color{green}-curved walk(out)\color{black}-stops \color{blue} o track inside the ring \color{red} o turns'; '\color{black} during' });

        end
        
        %rims
        plot(in_x,in_y,'color',grey);
        hold on
        plot(out_x,out_y,'color',grey);
        
        %ring outlines
        plot(ring_inner_x,ring_inner_y,'b--');
        plot(ring_outer_x,ring_outer_y,'b--');
        
        set(gca,'box','off','Xtick',[],'Ytick',[]);

    end

    set(gcf,'paperpositionmode','auto','paperorientation','landscape');
    print('-dpsc2',[fig_title '.ps'],'-append');
    
   
    %% plot the fly's walking trajectory and mark the turns
    % to check if the curv in/out /period is correct
    
    
    figure
    set(gcf,'position',[100, 50, 1100, 750]);
    
    subplot(4,4,[1 6]) %before
    plot(in_x,in_y,'k');
    hold on
    plot(out_x,out_y,'k');
    
    plot(fly_x(1:timeperiods(2)),fly_y(1:timeperiods(2)),'color',grey); %all the track 'before'
    
    plot(fly_x(stop_before),fly_y(stop_before),'k.','markersize',3); %'stops'
    
    %turning
    plot(fly_x(curv_before_in),fly_y(curv_before_in),'r.','markersize',3); %curving in'
    plot(fly_x(curv_before_out),fly_y(curv_before_out),'g.','markersize',3); %curving out
    
    %sharp turns
    if isnan(turn_before_in) == 0
        plot(fly_x(turn_before_in),fly_y(turn_before_in),'mo');
    end
    plot(fly_x(turn_before_out),fly_y(turn_before_out),'bo');
    
    text(60,10, {'\color{red}-curved walk (in) \color{green}-curved walk(out)\color{black}-stops \color{magenta} o \color{blue} o sharp turn'});
    
    title({fig_title; 'before'});
    
    set(gca,'box','off','XTick',[],'YTick',[]);
    
    subplot(4,4,[3 8]) %during
    plot(in_x,in_y,'k');
    hold on
    plot(out_x,out_y,'k');
    
    plot(fly_x(odoron_frame:odoroff_frame),fly_y(odoron_frame:odoroff_frame),'color',grey);
    plot(fly_x(stop_during),fly_y(stop_during),'k.','markersize',3); %'stops'
    
    %turning
    plot(fly_x(curv_during_in),fly_y(curv_during_in),'r.','markersize',3);
    plot(fly_x(curv_during_out),fly_y(curv_during_out),'b.','markersize',3);
    
    %sharp turns
    if isnan(turn_during_in) == 0
        plot(fly_x(turn_during_in),fly_y(turn_during_in),'mo');
    end
    plot(fly_x(turn_during_out),fly_y(turn_during_out),'bo');
    
    title({['curv threshold = ' num2str(turn_th) ', sharp turn threshold = ' num2str(curv_th_s)];...
        'during'});
    set(gca,'box','off','XTick',[],'YTick',[]);
    
    %turn frequency (fraction, including both sharp and wide turns)
    subplot(4,4,9)
    for h=1:3
        b = bar(h,turn_frq(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
        set(b, 'FaceColor', color(:,h));
    end
    title('turn frequency fraction' ,'fontsize',8,'interpreter','none');
    ylim ([0 1]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
    
    subplot(4,4,10)
    for h=1:3
        b = bar(h,turn_frq_in(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
        set(b, 'FaceColor', color(:,h));
    end
    title('turn frequency fraction (inside)' ,'fontsize',8,'interpreter','none');
    ylim ([0 1]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
    
    subplot(4,4,11)
    for h=1:3
        b = bar(h,turn_frq_out(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
        set(b, 'FaceColor', color(:,h));
    end
    title('turn frequency fraction (outside)' ,'fontsize',8,'interpreter','none');
    ylim ([0 1]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
    
    %sharp turn frequency/rate (#/sec)
    subplot(4,4,13)
    for h=1:3
        b = bar(h,turn_rate(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
        set(b, 'FaceColor', color(:,h));
    end
    title('sharp turn (#/sec)' ,'fontsize',8,'interpreter','none');
    ylim ([0 1]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
    
    subplot(4,4,14)
    for h=1:3
        b = bar(h,turn_rate_in(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
        set(b, 'FaceColor', color(:,h));
    end
    title('sharp turn (#/sec) (inside)' ,'fontsize',8,'interpreter','none');
    ylim ([0 1]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
    
    subplot(4,4,15)
    for h=1:3
        b = bar(h,turn_rate_out(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
        set(b, 'FaceColor', color(:,h));
    end
    title('sharp turn (#/sec) (outside)' ,'fontsize',8,'interpreter','none');
    ylim ([0 1]);
    set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
    
    
    set(gcf,'paperpositionmode','auto','paperorientation','landscape');
    saveas(gcf,[fig_title,'_turn_quantified.eps']);
    print('-dpsc2',[fig_title '.ps'],'-append');
    
    %%
    % get the curvature information at crossings
    [curvature_io_before,curvature_io_during,curvature_io_after,...
        curvature_oi_before,curvature_oi_during,curvature_oi_after]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        k_run,framespertimebin, timeperiods, timebefore, timetotal);
    
    
    %% angle calculation
    % this might work equally well for picking the sharp turns
    % comment this part out if not used in the final analysis
    
    %first, get the vector x and y in two points
    v_x = diff(fly_x); v_x = [0;v_x];
    v_y = diff(fly_y); v_y = [0;v_y];
    
    %angle between two vectors, copied from the old program
    angle1 = zeros(length(v_x)-1,1);
    v_xy = [v_x,v_y];
    for n=2:length(v_x)-1
        v1 = v_xy(n,:);
        v2 = v_xy(n+1,:);
        if norm(v1)*norm(v2) == 0
            angle1(n) = pi;
            display('vector length=0');
        else
            angle1(n) = acos(dot(v1,v2)/(norm(v1)*norm(v2)));
            %angle(rad) between two vectors
        end
    end
    angle1 = [angle1;0];
    
    %make angle =0 when it is classified as 'stop'
    angle1_run = angle1.*velocity_classified_binary;
    
    %thresholding with angle info rather than curvature
    angle_th_s = .5;
    [peaks,frame_angle_sh] = findpeaks(abs(angle1_run),'MINPEAKHEIGHT',angle_th_s,'MINPEAKDISTANCE',10);
    
    %wide turns
    angle_th_w = .2;
    [peaks,frame_angle] = findpeaks(abs(angle1_run),'MINPEAKHEIGHT',angle_th_w,'MINPEAKDISTANCE',6);
    
    %wide turns that are not sharp turns
    frame_angle_w = setdiff(frame_angle,frame_angle_sh);
    
    
    % sum of angle with sliding windows==========================================
    
    angle_sum_win = nan(1,length(angle1_run));%pre-allocate an array to save sum of angle from sliding windows
    sizewin = 10; %set the size of the sliding window
    
    for i=1:sizewin %i = matrix ID
        n = floor(length(angle1_run(i:end))/sizewin); %how many columns? (or windows)
        temp = angle1_run(i:i-1+(sizewin*n));%get that part of data
        temp = temp';
        temp2 = reshape(temp,sizewin,n);%reshape to make the row# = sizewin
        angle1_reshp(i) = {temp2}; %save in a cell array
        angle_sum = sum(temp2);%for each window, get the sum of angle
        
        for n=1:length(angle_sum) %then save them according to the sliding window order
            angle_sum_win((n-1)*sizewin + i) = angle_sum(n);
        end
        
    end
    
    % angle_smoothed = smooth(angle1_run,10);
    %====================================================================================
    
    
    %%
    %plot radial velocity/total velocity as a function of radius , 3 periods
    % figure
    % set(gcf,'position',[200 100 800 700],'color','white');
    %
    % rad_vel_prop = zeros(length(rad_vel),1);
    % rad_vel_prop(2:end) = rad_vel_sqrt(2:end)./vel_total(2:end);
    %
    % subplot(4,1,1)
    %
    % plot(radius_fly(1:timeperiods(2)),rad_vel_prop(1:timeperiods(2)),'go-','markersize',2);hold on
    % set(gca,'box','off','tickdir','out','xlim',[0 max(radius_fly)],'xtick',[] );
    %
    % plot([0 max(radius_fly+2)],[0 0], 'k:');
    % plot([circRad circRad],[0 1],'k:');
    %
    % title({fig_title; 'radial velocity/velocity as a function of radius';'Before'});
    %
    % subplot(4,1,2)
    %
    % plot(radius_fly(odoron_frame:odoroff_frame),rad_vel_prop(odoron_frame:odoroff_frame) ,'ro-','markersize',2);hold on
    % set(gca,'box','off','tickdir','out','xlim',[0 max(radius_fly)],'xtick',[]);
    %
    % plot([0 max(radius_fly+2)],[0 0], 'k:');
    % plot([circRad circRad],[0 1],'k:');
    %
    % title(['During']);
    %
    % subplot(4,1,3)
    %
    % plot(radius_fly(odoroff_frame:timeperiods(4)),rad_vel_prop(odoroff_frame:timeperiods(4)) ,'o-','markersize',2);hold on
    % set(gca,'box','off','tickdir','out','xlim',[0 max(radius_fly)] );
    %
    % plot([0 max(radius_fly+2)],[0 0], 'k:');
    % plot([circRad circRad],[0 1],'k:');
    %
    % xlabel('radius (pixel)');
    % title(['After']);
    %
    % % subplot(4,1,4)
    % % plot(rad_vel_prop(1:timeperiods(2)),'go-','markersize',2);hold on
    % % plot(rad_vel_prop(odoron_frame:odoroff_frame) ,'ro-','markersize',2);
    % % set(gca,'box','off','tickdir','out');
    %
    %
    % title('Radial velocity as a function of time');
    %
    % set(gcf,'paperpositionmode','auto');
    % saveas(gcf,[fig_title ' vel_rad_plot2.png']);
    % print('-dpsc2',[fig_title '.ps'],'-append');
    %%
    close all;
    %%
    %save all the variables
    save([fig_title ' variables.mat']);
    %%
    %save multiple figures (postscript files) as one pdf file
    
    ps2pdf('psfile', [fig_title '.ps'], 'pdffile', [fig_title '.pdf'], 'gspapersize', 'letter');
    
    display('Pdf file is saved!');
else %if user wants the main analysis only
    close all;
    
    %save all the variables
    save([fig_title ' variables.mat']);
    
    %save multiple figures (postscript files) as one pdf file
    
    ps2pdf('psfile', [fig_title '.ps'], 'pdffile', [fig_title 'Main.pdf'], 'gspapersize', 'letter');
    
    display('Pdf file is saved!');
end

%% these additional plots show all the individual crossing event-related
%data so that they can be manually checked!
additional_plot = 2; %give an option to choose or skip it!

if additional_plot == 1
    %velocity
    crossing_plotter(velocity_in2out_before,velocity_in2out_during,velocity_in2out_after,...
        velocity_out2in_before,velocity_out2in_during,velocity_out2in_after,...
        x_range,fig_title,'velocity',vel_ylim,vel_unit);
    
    close all
    
    %run&stop : velocity classified (stop = 0)
    crossing_plotter(in2outrunstops{1},in2outrunstops{2},in2outrunstops{3},...
        out2inrunstops{1},out2inrunstops{2},out2inrunstops{3},...
        x_range,fig_title,'vel_classified',vel_ylim,vel_unit);
    
    close all
    
    %run&stop
    %first convert everything into either 1 (run) or 0 (stop)
    vector_length = timetotal*framespertimebin;
    %pre-allocate the arrays that will save run as 1 and stop as 0
    %in2out
    io_runstop_before = nan(vector_length,size(in2outrunstops{1},2));
    io_runstop_during = nan(vector_length,size(in2outrunstops{2},2));
    io_runstop_after = nan(vector_length,size(in2outrunstops{3},2));
    %out2in
    oi_runstop_before = nan(vector_length,size(out2inrunstops{1},2));
    oi_runstop_during = nan(vector_length,size(out2inrunstops{2},2));
    oi_runstop_after = nan(vector_length,size(out2inrunstops{3},2));
    
    for period = 1:3
        for hh = 1:size(in2outrunstops{1,period},2);
            temp1 = in2outrunstops{1,period}(:,hh);%make a temp array to save the one crossing
            runs_in_temp1 = find(temp1 > 0); %find the elements that are not zero (runs)
            temp1(runs_in_temp1)=1; %change it to 1
            %save them / period
            if period ==1 %before
                io_runstop_before(:,hh) = temp1;
            elseif period ==2 %during
                io_runstop_during(:,hh) = temp1;
            else
                io_runstop_after(:,hh) = temp1;
            end
        end
        
        for hh = 1:size(out2inrunstops{1,period},2);
            temp1 = out2inrunstops{1,period}(:,hh);%make a temp array to save the one crossing
            runs_in_temp1 = find(temp1 > 0); %find the elements that are not zero (runs)
            temp1(runs_in_temp1)=1; %change it to 1
            %save them / period
            if period ==1 %before
                oi_runstop_before(:,hh) = temp1;
            elseif period ==2 %during
                oi_runstop_during(:,hh) = temp1;
            else
                oi_runstop_after(:,hh) = temp1;
            end
            
        end
    end
    
    %run&stop : run =1 VS stop = 0
    crossing_plotter(io_runstop_before,io_runstop_during,io_runstop_after,...
        oi_runstop_before,oi_runstop_during,oi_runstop_after,...
        x_range,fig_title,'Run(1) or Stop(0)',[0 1.5],'run or stop');
    
    
    %%
    %individual crossing: acceleration plotting
    crossing_plotter(accel_in2out_before,accel_in2out_during,accel_in2out_after,...
        accel_out2in_before, accel_out2in_during,accel_out2in_after,...
        x_range,fig_title,'acceleration',accel_ylim,accel_unit);
    
    %%
    close all;
    
    %convert ps file to pdf file
    ps2pdf('psfile', [fig_title '_crossings.ps'], 'pdffile', [fig_title '_crossings.pdf'], 'gspapersize', 'letter');
    
    %% Curvature plotting
    
    %smooth curvature to reduce noise
    smoothing_size = 5;
    k_run_smoothed = smooth(k_run,smoothing_size);
    %now get the curvature information at crossings
    [curvature_io_before_smoothed,curvature_io_during_smoothed,curvature_io_after_smoothed,...
        curvature_oi_before_smoothed,curvature_oi_during_smoothed,curvature_oi_after_smoothed]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        k_run_smoothed,framespertimebin, timeperiods, timebefore, timetotal);
    
    
    
    %the following plots the changes of curvature (both non-smoothed and
    %smoothed curvature) at crossing, skip this if not necessary!==============
    
    %curvature
    % crossing_plotter(curvature_io_before,curvature_io_during,curvature_io_after,...
    %     curvature_oi_before,curvature_oi_during,curvature_oi_after,...
    %     x_range,fig_title,'curvature',[-.5 .5],'curvature');
    %
    % %smoothed curvature
    % crossing_plotter(curvature_io_before_smoothed,curvature_io_during_smoothed,curvature_io_after_smoothed,...
    %     curvature_oi_before_smoothed,curvature_oi_during_smoothed,curvature_oi_after_smoothed,...
    %     x_range,fig_title,['smoothed curvature ' num2str(smoothing_size)],[-.5 .5],'curvature');
    %==========================================================================
    
    %% %PLOT Curvature AT CROSSING
    figure
    set(gcf,'color','white','Position',[520 20 700 800]);
    
    %now get the curvature information at crossings
    [curvature_io_before_smoothed,curvature_io_during_smoothed,curvature_io_after_smoothed,...
        curvature_oi_before_smoothed,curvature_oi_during_smoothed,curvature_oi_after_smoothed]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        k_run_smoothed,framespertimebin, timeperiods, timebefore, timetotal);
    curv_ylim = [-.4 .4];
    %for crossing out2in
    %before
    for period = period_1:period_2
        subplot(4,2,2*period-1)
        if period == 1 %before
            for h = 1:size(curvature_oi_before_smoothed,2);
                p = rem(h,20)+1;
                plot (x_range,curvature_oi_before_smoothed(:,h) ,'color', cmap(p,:))
                hold on
            end
        elseif period ==2 %during
            for h = 1:size(curvature_oi_during_smoothed,2);
                p = rem(h,20)+1;
                plot (x_range,curvature_oi_during_smoothed(:,h) ,'color', cmap(p,:))
                hold on
            end
            
        else %after
            for h = 1:size(curvature_oi_after_smoothed,2);
                p = rem(h,20)+1;
                plot (x_range,curvature_oi_after_smoothed(:,h) ,'color', cmap(p,:))
                hold on
            end
        end
        xlim([min(x_range) max(x_range)]);
        ylim (curv_ylim)
        plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
        title(['Crossing in: ' period_name{period}],'fontsize',9);
        %     xlabel('frame number','fontsize',9);
        ylabel('curvature','fontsize',9);
        xlabel('time(sec)');
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    end
    
    %for crossing in2out
    %before
    for period = period_1:period_2
        subplot(4,2,2*period)
        if period == 1 %before
            for h = 1:size(curvature_io_before_smoothed,2);
                p = rem(h,20)+1;
                plot (x_range,curvature_io_before_smoothed(:,h) ,'color', cmap(p,:))
                hold on
            end
        elseif period ==2 %during for h = 1:size(velocity_out2in_during,2);
            for h = 1:size(curvature_io_during_smoothed,2);
                p = rem(h,20)+1;
                plot (x_range,curvature_io_during_smoothed(:,h) ,'color', cmap(p,:))
                hold on
            end
            
        else %after
            for h = 1:size(curvature_io_after_smoothed,2);
                p = rem(h,20)+1;
                plot (x_range,curvature_io_after_smoothed(:,h) ,'color', cmap(p,:))
                hold on
            end
        end
        xlim([min(x_range) max(x_range)]);
        ylim (curv_ylim)
        plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
        title(['Crossing Out: ' period_name{period}],'fontsize',9);
        %     xlabel('frame number','fontsize',9);
        ylabel('curvature','fontsize',9);
        xlabel('time(sec)');
        set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
        
    end
    
    subplot(4,2,7)
    bf_avg = nanmean(curvature_oi_before_smoothed,2);
    dr_avg = nanmean(curvature_oi_during_smoothed,2);
    
    plot(x_range,bf_avg,'g');
    hold on
    plot(x_range,dr_avg,'r');
    
    xlim([min(x_range) max(x_range)]);
    ylim ([curv_ylim(1)+.2 curv_ylim(2)-.2])
    plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
    title(['Means of curvature: Crossing In'],'fontsize',9);
    %     xlabel('frame number','fontsize',9);
    ylabel('curvature','fontsize',9);
    xlabel('time(sec)');
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    
    subplot(4,2,8)
    bf_avg = nanmean(curvature_io_before_smoothed,2);
    dr_avg = nanmean(curvature_io_during_smoothed,2);
    
    plot(x_range,bf_avg,'g');
    hold on
    plot(x_range,dr_avg,'r');
    
    xlim([min(x_range) max(x_range)]);
    ylim ([curv_ylim(1)+.2 curv_ylim(2)-.2])
    plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
    title(['Means of curvature: Crossing Out'],'fontsize',9);
    ylabel('curvature','fontsize',9);
    xlabel('time(sec)');
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8);
    
    ax = axes('position',[0,0,1,1],'visible','off');
    tx = text(0.3,0.97,[fig_title ' Curvature at crossing events']);
    set(tx,'fontweight','bold','interpreter','none');
    
    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
    print('-dpsc2',[fig_title '_curvatures.ps'],'-append');
    
    
    %% find sharp turns using 'findpeak' function (with a threshold: curv_th)
    % and calculate area under the curve or integral for the curvature
    
    curv_th = .15; %threshold to pick out sharp turns
    
    crossing_max = max(crossing_ins); %how many crossings?
    area_curv_io = nan(crossing_max,3); %array to save area of curvature
    area_curv_th = nan(crossing_max,3); %array to save area of curvature above the threshold
    curv_pk_frame = cell(crossing_max,3); %array to save the frame # above the threshold (peaks)
    curv_pk_value = cell(crossing_max,3); %array to save the height/curvature above the threshold (peaks)
    
    area_curv_io_ns = nan(crossing_max,3); %array to save area of curvature
    area_curv_th_ns = nan(crossing_max,3); %array to save area of curvature above the threshold
    curv_pk_frame_ns = cell(crossing_max,3); %array to save the frame # above the threshold (peaks)
    curv_pk_value_ns = cell(crossing_max,3); %array to save the height/curvature above the threshold (peaks)
    
    %smoothed and non-smoothed (ns) curvature data
    for period = period_1:period_2
        if period ==1 %before
            data_period = curvature_io_before_smoothed;
            data_period_ns = curvature_io_before;
        elseif period ==2 %during
            data_period = curvature_io_during_smoothed;
            data_period_ns = curvature_io_during;
        else %after
            data_period  = curvature_io_after_smoothed;
            data_period_ns = curvature_io_after;
        end
        
        plot_count = size(data_period,2);
        for i=1:plot_count
            curv_data = data_period(:,i); %get the data (one crossing)
            non_nans = find(~isnan(curv_data));    %only count non-nans
            x_range_curv = x_range(timebefore*framespertimebin+1:non_nans(end)); %from crossing out till the end (non-nans)
            curv_to_plot = curv_data(timebefore*framespertimebin+1:non_nans(end));
            area_curv_io(i,period) = trapz(x_range_curv,curv_to_plot); %get the area
            %non-smoothed
            curv_data_ns = data_period_ns(:,i);
            curv_to_plot_ns = curv_data_ns(timebefore*framespertimebin+1:non_nans(end));
            area_curv_io_ns(i,period) = trapz(x_range_curv,curv_to_plot_ns); %get the area
            
            if length(curv_to_plot) > 5
                %find the sharp turns using findpeaks
                %http://www.mathworks.com/help/toolbox/signal/ref/findpeaks.html
                [peaks,frame_no] = findpeaks(abs(curv_to_plot),'MINPEAKHEIGHT',curv_th,'MINPEAKDISTANCE',10);
                %curv_th : threshold to define peaks
                %minpeakdistance: at least 10 frames apart (this is the maximum) to avoid counting one peak multple times
                [peaks_ns,frame_no_ns] = findpeaks(abs(curv_to_plot_ns),'MINPEAKHEIGHT',curv_th,'MINPEAKDISTANCE',10);
                
                %then get the exact time and corresponding height of the peaks
                if isempty(peaks) == 0 %if it is not empty
                    curv_pk_frame{i,period} = x_range_curv(frame_no);
                    curv_pk_value{i,period} = curv_to_plot(frame_no);
                end
                
                if isempty(peaks_ns) == 0 %if it is not empty
                    curv_pk_frame_ns{i,period} = x_range_curv(frame_no_ns);
                    curv_pk_value_ns{i,period} = curv_to_plot_ns(frame_no_ns);
                end
                
                %         %now, get all the frame # above the threshold
                %         frame_no_th = find(curv_th <= abs(curv_to_plot));
                %         %then get the area?
                %         if length(frame_no_th) >2 %to avoid error
                %             cons_check = diff(frame_no_th); %check if these are consecutive numbers
                %             num_cons = length(find(cons_check ~= 1))+1; %how many non-consecutive numbers? (peaks)
                %             for p = 1:num_cons
                %             area_curv_th(i,period) = area_curv_th(i,period) + trapz(x_range_curv(,curv_to_plot(frame_no));
                %             end
                %         end
                
                h = rem(i,10);
                if h == 0
                    h = 10;
                end
                if h==1
                    figure
                    set(gcf,'position',[300 10 700 800]);
                end
                
                subplot(5,2,h)
                plot(x_range_curv,curv_to_plot_ns,'b');hold on
                plot(curv_pk_frame_ns{i,period},curv_pk_value_ns{i,period},'b*');
                plot(x_range_curv,curv_to_plot,'r');hold on
                plot(curv_pk_frame{i,period},curv_pk_value{i,period},'r*');
                
                plot([0 3],[0 0],'k:');
                plot([0 3],[curv_th curv_th],'b:');
                plot([0 3],[-curv_th -curv_th],'b:');
                ylim([-.7 .7]);
                set(gca,'box','off','tickdir','out');
                title([num2str(i) ' :' num2str(crossing_out_cell{period}(i))]);
            end
            if h==1
                title({[fig_title];[period_name{period} ' smoothed curvature ' num2str(smoothing_size)]});
            end
            
            if h == 10 || i == plot_count %if last plot, save the figure
                set(gcf, 'PaperPositionMode', 'auto');
                print('-dpsc2',[fig_title '_curvatures.ps'],'-append');
            end
            
        end
        
        clear data_period;
    end
    %% actual fly traces at crossing
    %aligning fly's track after crossing out
    [fly_x_aligned,fly_y_aligned,rotated_in_x,rotated_in_y,...
        short_fly_x_aligned,short_fly_y_aligned,crossing_in_cell,crossing_out_cell,...
        angle_bw_OI,period_1,period_2]...
        = traceplotter_I2O(crossing_in_before,crossing_in_during,crossing_in_after,...
        crossing_out_before,crossing_out_during,crossing_out_after,...
        in_x,in_y,fly_x,fly_y,how_short,framespertimebin,timeperiods);
    
    %get the x_range after crossing out
    x_range_cross = x_range(timebefore*framespertimebin+1:end); %from crossing out till the end (non-nans)
    
    for period = period_1:period_2;
        plot_count=length(crossing_in_cell{period});
        for h = 1:plot_count
            i = rem(h,9);
            if i==0
                i = 9; %to prevent error
            end
            if i==1 %if it is a first subplot, create a figure
                figure
                set(gcf,'position',[300 10 600 600],'color','white');
            end
            
            subplot(3,3,i)
            plot (fly_x_aligned{h, period},fly_y_aligned{h, period} ,':','color', [.3 .3 .3])
            hold on
            plot (short_fly_x_aligned{h, period},short_fly_y_aligned{h, period} )
            plot(rotated_in_x{h, period},rotated_in_y{h,period},'color',grey);
            %mark the sharp turns
            if ~isempty(curv_pk_frame_ns{h,period}) ==1 %only when there are sharp turns
                frame_temp = ismember(x_range_cross,curv_pk_frame_ns{h,period});%get the frame# (counting after crossing out)
                if ~isempty(find(frame_temp)) == 1 %if there are peaks
                    plot(short_fly_x_aligned{h, period}(frame_temp),short_fly_y_aligned{h, period}(frame_temp) ,'r*','markersize',4)
                end
            end
            title([num2str(h) ' :' num2str(crossing_out_cell{period}(h))]);
            set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1],'xtick',[],'ytick',[]);
            axis([min(rotated_in_x{1,2})-100 max(rotated_in_x{1,2})-60 min(rotated_in_y{1,2})-10 max(rotated_in_y{1,2})+20]);
            
            text(-100,100,['time (sec); ' num2str(length(short_fly_x_aligned{h,period})/framespertimebin)],'fontsize',8);
            
            if i== 1
                title([fig_title ' track: In2Out ' period_name{period}],'interpreter','none');
            end
            
            if i == 10 || h == plot_count %if last plot, save the figure
                set(gcf, 'PaperPositionMode', 'auto');
                print('-dpsc2',[fig_title '_curvatures.ps'],'-append');
            end
        end
        
    end
    
    
    %% smoothed with '15' as in curvature calculation
    [fly_x_alignedV,fly_y_alignedV,rotated_in_x,rotated_in_y,...
        short_fly_x_alignedV,short_fly_y_alignedV,crossing_in_cell,crossing_out_cell,...
        angle_bw_OI,period_1,period_2]...
        = traceplotter_I2O(crossing_in_before,crossing_in_during,crossing_in_after,...
        crossing_out_before,crossing_out_during,crossing_out_after,...
        in_x,in_y,Vertices(:,1),Vertices(:,2),how_short,framespertimebin,timeperiods);
    %%
    %get the x_range after crossing out
    x_range_cross = x_range(timebefore*framespertimebin+1:end); %from crossing out till the end (non-nans)
    for period = period_1:period_2;
        plot_count=length(crossing_in_cell{period});
        for h = 1:plot_count
            i = rem(h,9);
            if i==0
                i = 9; %to prevent error
            end
            if i==1 %if it is a first subplot, create a figure
                figure
                set(gcf,'position',[300 10 600 600],'color','white');
            end
            
            subplot(3,3,i)
            plot (fly_x_alignedV{h, period},fly_y_alignedV{h, period} ,':','color', [.3 .3 .3])
            hold on
            plot (short_fly_x_alignedV{h, period},short_fly_y_alignedV{h, period} )
            plot(rotated_in_x{h, period},rotated_in_y{h,period},'color',grey); %inner rim
            %mark the sharp turns
            if ~isempty(curv_pk_frame{h,period}) ==1 %only when there are sharp turns
                frame_temp = ismember(x_range_cross,curv_pk_frame{h,period});%get the frame# (counting after crossing out)
                if ~isempty(find(frame_temp)) == 1 %if there are peaks
                    plot(short_fly_x_alignedV{h, period}(frame_temp),short_fly_y_alignedV{h, period}(frame_temp) ,'r*','markersize',4)
                end
            end
            title([ num2str(h) ' :'  num2str(crossing_out_cell{period}(h))]);
            set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1],'xtick',[],'ytick',[]);
            axis([min(rotated_in_x{1,2})-100 max(rotated_in_x{1,2})-60 min(rotated_in_y{1,2})-40 max(rotated_in_y{1,2})+40]);
            text(-100,100,['time (sec); ' num2str(length(short_fly_x_alignedV{h,period})/framespertimebin)],'fontsize',8);
            
            if i== 1
                title({[fig_title ' 10 smoothed track: In2Out ' period_name{period}];...
                    ['curvature threshold ' num2str(curv_th)]},'interpreter','none','HorizontalAlignment','Left');
            end
            
            if i == 9 || h == plot_count %if last plot, save the figure
                set(gcf, 'PaperPositionMode', 'auto');
                print('-dpsc2',[fig_title '_curvatures.ps'],'-append');
            end
        end
    end
    
    %%
    figure
    set(gcf,'position',[600 200 400 600]);
    
    for period =1:3
        % for period =2
        for p = 1:crossing_max
            plot(period,area_curv_io(p,period),'o');
            hold on
            text(period+.2,area_curv_io(p,period),num2str(p),'fontsize',5);
            
            plot(period+.1,area_curv_th(p,period),'r+');
            text(period+.4,area_curv_th(p,period),num2str(p),'fontsize',5);
        end
    end
    
    set(gca,'Xtick',[1:3],'XTickLabel',{'Before','During','After'});
    set(gca,'box','off','tickdir','out');
    plot([0 4],[0 0],'k:');
    xlim([.5 3.5]);
    title({[filename_behavior(1:13)];...
        ['The area (integral) of curvature from crossing out till ' num2str(timetotal-timebefore) ' sec'];...
        ['The area above the curvature threshold ' num2str(curv_th)]},'interpreter','none');
    
    set(gcf, 'PaperPositionMode', 'auto');
    print('-dpsc2',[fig_title '_curvatures.ps'],'-append');
    
    %% find peaks in all the frames
    %sharp VS wide turns
    curv_th_s = 1;
    [peaks,frame_turn_sh] = findpeaks(abs(k_run),'MINPEAKHEIGHT',curv_th_s,'MINPEAKDISTANCE',10);
    
    %wide turns
    curv_th_w = .14;
    [peaks,frame_turn] = findpeaks(abs(k_run),'MINPEAKHEIGHT',curv_th_w,'MINPEAKDISTANCE',6);
    
    %wide turns that are not sharp turns
    frame_turn_cv_w = setdiff(frame_turn,frame_turn_sh);
    
    % [peaks,frame_turn] = findpeaks(abs(k_run_smoothed),'MINPEAKHEIGHT',curv_th,'MINPEAKDISTANCE',10);
    
    % plot(k_run_smoothed); hold on
    % plot(frame_turn, k_run_smoothed(frame_turn),'r*');
    % plot([1 16200],[-curv_th -curv_th],'k:');
    % plot([1 16200],[curv_th curv_th],'k:');
    % plot(crossing_in_during,.5,'bo');
    % plot(crossing_out_during,.54, 'ro');
    
    
    %%
    close all
    %convert ps file to pdf file
    ps2pdf('psfile', [fig_title '_curvatures.ps'], 'pdffile', [fig_title '_curvatures.pdf'], 'gspapersize', 'letter');
    save([fig_title ' variables.mat']);
    
end
