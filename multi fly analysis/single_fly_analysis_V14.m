% single_fly_analysis_V14 by Seung-Hye :repeat the single fly analysis for
% all the files in the folder (same experimental date)

%% Big changes in V14
% 1.The 'inside_rim','in_out_pts' and all the variables that are computed from those
%two variables will be different from V13. It checks 'velocity_classified'
%before deciding 'crossing' and if the fly is stopping, inside_rim and
%in_out_pts won't change until the fly moves again.
% 2. The run velocity calculation has changed. Instead of getting mean of
% means of each run velocity, it now pools the whole run velocity and get
% the mean from them.
% 3.replaced run_stop_generator with run_stop_generator1
% run/stop into in and out in before/during

% All the averages plotted are median values for a single fly analysis.
%% instructions
% 1. run the script
% 2. if this is the first time running the script, type '2' and follow the
% prompts and type in all the necessary info first
% 3. enter '1' to plot only the main analysis plot or
% press 'Return' to plot the entire analyses
% 4. enter '1' to manually decide 'run' or 'stop' for the first point,
% if you already saved a file (for example "120628_runstop_info"),
% then enter 'Return'
% 5. When it is done, it will generate two pdf files; one that contains the
% analysis and the other that contains individual crossing-related plots
% The additional crossing plots and pdf file will not be generated unless
% 'additional_plot' variable is set as '1'!

%% This program needs following functions

% 1. period_def
% 2. crossingframes
% 3. radial_calculator_circle
% 4. vel_calculator
% 5. velocityatcrossing_basic
% 6. velocityatcrossing_with_frames
% 7. traceplotter_I2O, traceplotter_O2I
% 8. crossing_plotter
% 9. run_stop_generator1** from V14
% 10. short_long_crossing
% 11. rad_velocity_binned
% 12. Velocity_Classifier
% 13. LineCurvature2D
% 14. runprobabilitySJ
%%
clear all; close all;
warning('off');

prog_version =  'V14';

% set constants
framespertimebin =30;%how many frames/sec?
secsperperiod = 180;%how many seconds/period?

outer_radius = 3.2;
inner_radius = 1.2; %new chamber (cm)

velocity_threshold = 0.1;
bin_number = 5; %number of bins inside the odor zone for radial distribution calculation

%run/stop thresholds
runthreshold = .14*2;
stopthreshold = .06*2;

currentfolder = pwd;
day = currentfolder(end-5:end);

%% initalizing parameters
initializeyn = input('if you want to repeat this analysis with exactly the same parameters, press 1, otherwise 2');

if initializeyn == 1;
    load([num2str(day) 'fly_info']); %struct containing previous initialized parameters
    startvideo = flyinfo.first_video;
    endvideo = flyinfo.last_video;
    day = flyinfo.date;
    genotype = flyinfo.genotype;
    multiflyyn = flyinfo.multiple_flies_yn;
    noairfly = flyinfo.no_air_fly;
    fly_no = endvideo - startvideo +1;
    if multiflyyn ==1;
        fly_number = ones(endvideo-startvideo+1,1); %if there is only one fly in the experiment, assign "1" to fly number for all videos
    else
        load([num2str(day) 'flynames.mat']); %load the saved fly numbers
        
    end
    
    load([num2str(day) 'odornames.mat']);
    
elseif initializeyn == 2;
    startvideo = input('what is the first video?');
    endvideo = input('what is the last video?');
    genotype = input('what is the fly genotype?', 's');
    %     multiflyyn = input('are there multiple flies in this set of videos?, press 1 if no, 2 if yes');
    %     %     day_info = pwd;
    %     %     day = day_info(end-5:end);
    %
    %     if multiflyyn ==1;
    multiflyyn=1;
    fly_no = endvideo - startvideo +1;
    fly_number =ones(endvideo-startvideo+1,1);
    %     else
    %         flynameyn = input('if you have already saved the fly names , press 1, otherwise 2');
    %         if flynameyn == 1;
    %             load([num2str(day) 'flynames.mat']);
    %         else
    %
    %             fly_number = nan(endvideo-startvideo+1,1);
    %             for iteration = 1:(endvideo-startvideo+1);
    %                 fly_number(iteration) = input(['what number fly is in this video?' num2str(iteration) '?']);
    %             end
    %
    %             save ([num2str(day) 'flynames'], 'fly_number');
    %         end
    %     end
    
    odornameyn = input('if you have already saved the odor names , press 1, otherwise 2');
    if odornameyn == 1;
        load([num2str(day) 'odornames.mat']);
        
    else
        if startvideo ~= 1 %since VBLAB3 videos start from 31, add empty arrays from 1 to 30
            odorname = cell(endvideo,1);
            for iteration = 1:(endvideo-startvideo+1);
                odorname{startvideo-1+iteration} =...
                    input(['what is the odorname and concentration for video' num2str(startvideo-1+iteration) '?'], 's');
            end
        else
            odorname = cell(endvideo-startvideo+1,1);
            for iteration = 1:(endvideo-startvideo+1);
                odorname{iteration} =...
                    input(['what is the odorname and concentration for video' num2str(iteration) '?'], 's');
            end
        end
        
        save ([num2str(day) 'odornames'], 'odorname');
    end
    
    %     noairfly = input('enter the numbers of any videos without air');
    noairfly = [];
    
    flyinfo = struct('first_video', startvideo, 'last_video', endvideo, 'date', day, 'genotype', genotype, 'multiple_flies_yn', multiflyyn, 'odor_yn', odornameyn, 'no_air_fly', noairfly);
    save([num2str(day) 'fly_info'], 'flyinfo')
end

%give an option to plot only main analysis or go through the whole analysis
display('Do you need only main anlaysis or the whole thing?');
analysis_option = input('If you need only the main anlaysis, press 1, otherwise type Enter: ');

%Automatically find rim points files (all the CSV and mat files)
%Since there is only one rim file, do this once for all the files in
%the same folder

rimnametag_mat = [num2str(day) 'transformedrimpoints.mat'];

rimnametag_csv_in = [num2str(day) 'video1_inner_rim.csv'];
rimnametag_csv_out = [num2str(day) 'video1_outer_rim.csv'];

rimmatfiles = dir('*transformedrimpoints.mat');

rimmat = {rimmatfiles.name};

if find(strcmp(rimmat,rimnametag_mat)) ~= 0 % if there is a matching mat file
    display('Rim points file used is mat file')
    display(rimnametag_mat)
    load(rimnametag_mat);
    in_x = inner_transformed(:,1);
    in_y = 480-inner_transformed(:,2);%flip y axis to match with video
    out_x = outer_transformed(:,1);
    out_y = 480-outer_transformed(:,2);%flip y axis to match with video
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


display('do you want to re-use the saved run/stop determination info?');
user_answer1 = input('if yes, press enter, if no, press 1');
if isempty(user_answer1) == 1 % if 'yes, no previously saved run stop info file'
    run_stop_info = [num2str(day) 'runstop_info.mat'];
    load(run_stop_info);
    first_point = run_stop_info;
else
    run_stop_info = nan(fly_no,1);
    % run_stop_analysis for the first point
    % classifying the first point
    %threshold was set empirically by comparing the velocity with the video by
    %catherine
    %if run/stop info was not loaded from previously saved mat file, do the following
    
    %first, get the xy coordinates for all the flies
    for nv = startvideo:endvideo
        filename_behavior = [num2str(day) 'video' num2str(nv) '_xypts_transformed.csv'];
        numvals = csvread(filename_behavior,2);
        
        fly_x1 = numvals(:,1);
        fly_y1 = 480-numvals(:,2);  %flip y axis to match with the video
        %smoothingfor 30 fps video
        fly_x1 = smooth(fly_x1,10);
        fly_y1 = smooth(fly_y1,10);
        
        %get the total velocity (same as vel_calculator)
        measured_axis = outer_radius; %diameter of outer circle in printed top registration template
        vel_x_total = diff(fly_x1);
        vel_y_total = diff(fly_y1);
        vel_total_temp = sqrt((vel_x_total.^2+vel_y_total.^2));
        
        %converting the unit of velocity to cm/sec
        [out_xc,out_yc,out_R,out_a] = circfit(out_x,out_y);
        vel_total = vel_total_temp.*measured_axis/(out_R)*framespertimebin;
        vel_total=[0;vel_total];
        
        %plot the first ~30 frame-long velocity
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
        set(gca,'xtick', xlim1:xincrem:xlim2);
        set(gca,'ytick', ylim1:yincrem:ylim2);
        ylabel ('velocity (cm/frame)');
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
        
        display('matlab determined the first point is ');
        if first_input1 == 1
            display('run');
        else
            display('stop');
        end
        
        % first_point = first_input1;
        
        %if it is accurate, get rid of this part later
        first_point_temp = input ('type 1 if the first point is a run, 0 if a stop: ');
        close all;
        run_stop_info(nv) = first_point_temp;
        if nv == fly_no %if this is the last video
            save([num2str(day) 'runstop_info.mat'], 'run_stop_info');
        end
        
    end
    first_point = run_stop_info;
end



%  noair = input('enter 1 if no air turned on during the video');
%========loading the CSV + mat files=======================================
iteration = 1;
for nv=startvideo:endvideo %loop through first video
    
    %try
    % filename_behavior = uigetfile('*.csv', 'Select the file for FLY track');
    % numvals = csvread(filename_behavior,2);%discard the first frame
    
    fig_title1 = [num2str(genotype) '_' num2str(odorname{nv})] ;
    
    filename_behavior = [num2str(day) 'video' num2str(nv) '_xypts_transformed.csv'];
    numvals = csvread(filename_behavior,2);
    
    
    %==========================================================================
    if length(numvals) >= 10000; %to distinguish between 1 minute and 9 minute videos
        secsperperiod = 180;%how many seconds/period
        framespertimebin = 30;
    else
        secsperperiod = 20;
        framespertimebin = 10;
    end
    
    %no smoothing for 3 fps video
    fly_x = numvals(:,1);
    fly_y = 480-numvals(:,2);  %flip y axis to match with the video
    %smoothingfor 30 fps video
    fly_x = smooth(fly_x,10);
    fly_y = smooth(fly_y,10);
    
    
    fig_title = [filename_behavior(1:13),' ', fig_title1,' ', prog_version];
    
    
    %%
    inside_rim = inpolygon(fly_x,fly_y,in_x,in_y);%in=1, out=0
    in_out_pts = zeros(1,length(fly_x));
    in_out_pts(2:end) = diff(inside_rim);%ou2in=0, in2out = -1
    
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
    
    
    %%
    %This function outputs crossing events, odoron_frame etc.
    [crossing,crossing_in,crossing_out,odoron_frame,odoroff_frame,timeperiods]=...
        period_def(fly_x,framespertimebin,secsperperiod,inside_rim,in_out_pts);
    
    %%
    % This function outputs crossing in/out in each period, frames in/out in
    % each period: it uses only real crossing events.
    % If crossing in occurs in during period and crossing out occurs in after period,
    % that event will not be included!
    
    [crossing_in_before, crossing_in_during, crossing_in_after,...
        crossing_out_before,crossing_out_during,crossing_out_after,crossing_before_No,crossing_during_No,crossing_after_No,...
        frames_in_before, frames_out_before,frames_in_during,frames_out_during,frames_in_after,frames_out_after]=...
        crossingframes(crossing,crossing_in,crossing_out,odoron_frame,odoroff_frame,timeperiods,in_out_pts, fly_x, fly_y);
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
        radial_calculator_circle(fly_x,fly_y, out_x,out_y,in_x,in_y,bin_number,timeperiods,odoron_frame,odoroff_frame,inner_radius, outer_radius);
    
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
        how_short = 2;
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
            plot([0 0],'k+','markersize',10);
            
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
            plot([0 0],'k+','markersize',10);
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
                    if p(1)> 0
                        all_fly_x_aligned_bf(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                        all_fly_y_aligned_bf(1:length(fly_y_aligned{i,period}),i) = fly_y_aligned{i,period};
                    else
                        all_fly_x_aligned_bf(1:length(fly_x_aligned{i,period}),i) = fly_x_aligned{i,period};
                        all_fly_y_aligned_bf(1:length(fly_y_aligned{i,period}),i) = -fly_y_aligned{i,period};
                    end
                end
                avg_fly_x_aligned_bf = nanmean(all_fly_x_aligned_bf,2);
                avg_fly_y_aligned_bf = nanmean(all_fly_y_aligned_bf,2);
                
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
        
        if exist('avg_fly_x_aligned_af') ~= 0
        if frametoplot <= sum(~isnan(avg_fly_x_aligned_af)) %if avg data length is longer than frametoplot
            plot(avg_fly_x_aligned_af(1:frametoplot),avg_fly_y_aligned_af(1:frametoplot),'b');
        else
            plot(avg_fly_x_aligned_af,avg_fly_y_aligned_af,'b');
        end
        plot([0 0],'k+','markersize',10);
        end
        
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
        
        set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
        print('-dpsc2',[fig_title '.ps'],'-append');
        %%
        %time_in_out_historgram.m
        %histogram for time spent in/transit and time spent out/transit
        
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
        
        % plot histogram
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
        max_ti = max(max([n_ti_before;n_ti_during;n_ti_after]));
        max_to = max(max([n_to_before;n_to_during;n_to_after]));
        
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
                title({[fig_title ' Time spent inside/transit'];period_name{i}},'interpreter','none')
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
                title({[fig_title ' Time to return/transit'];period_name{i}},'interpreter','none')
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
        
        
        %% CLASSIFYING POINTS
        % for four consecutive frames, all four points are above stopthreshold, it
        % is 'run'. if only the second frame is below stopthreshold, it is still
        % 'run'.
        % velocity_classified is just turning the velocity during "stops"  to zero
        % velocity_classified_binary: runs =1 and stops =0
        % runstops: NaN vector except the points when run becomes stop or stop
        % becomes run (1)(if the first frame is run, it is '1')
        [velocity_classified, velocity_classified_binary, runstops] = Velocity_Classifier(vel_total, first_point(nv), stopthreshold, runthreshold );
        
        % clear velocitytoplot_out2in velocitytoplot_in2out
        
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
        [runs, stops] = run_stop_generator1(runstops, velocity_classified,timeperiods, odoron_frame);
        
        
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
        %IN
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
            run_vel_in_cell = vel_in_run{period};
            run_vel_in_cell = run_vel_in_cell';
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
        
        %%
        %divide velocity data into two groups : short time in/transit vs long time in/transit
        %this assumes that the real crossing data is saved after 10 seconds in
        %arrays. Output 'avg_...' is MEDIAN VALUE!
        
        %set the time limit/threshold to use to separate short and long crossings
        how_short = framespertimebin; %1 sec
        
        [vel_o2i_before_short,vel_o2i_during_short,vel_o2i_after_short,...
            vel_o2i_before_long,vel_o2i_during_long,vel_o2i_after_long,...
            vel_i2o_before_short,vel_i2o_during_short,vel_i2o_after_short,...
            vel_i2o_before_long,vel_i2o_during_long,vel_i2o_after_long,...
            avg_vel_o2i_short,avg_vel_o2i_long,avg_vel_i2o_short,avg_vel_i2o_long]...
            = short_long_crossings(how_short,velocity_in2out_before,velocity_in2out_during,...
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
        accel_ylim = [-.2 .2];
        
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
        ylim ([accel_ylim(1) accel_ylim(2)]);
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
        ylim ([accel_ylim(1) accel_ylim(2)]);
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
        
        %% these additional plots show all the individual crossing event-related
        %information so that they can be manually checked!
        
        additional_plot = 2; % change this to 1 if additional crossing analysis is needed!
        
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
            %%        curvature calculation
            %the initial 10 frames moving window smoothing is not enough,
            %VB empirically decided that 25 works fairly well
            Vertices = nan(length(fly_x),2);
            Vertices(:,1)= fly_x;
            Vertices(:,2)= fly_y;
            
            %Check the following link for information about linecurvature2D
            %http://www.mathworks.com/matlabcentral/fileexchange/32696
            k = LineCurvature2D(Vertices);
            k= k(1:end-1);%remove the last point
            k=[0;k]; %add 0 for the first point
            
            
            k_run=k.*(velocity_classified_binary); %makes all the curvature data during stops as 0
            
            %now get the curvature information at crossings
            [curvature_io_before,curvature_io_during,curvature_io_after,...
                curvature_oi_before,curvature_oi_during,curvature_oi_after]...
                = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
                crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
                k_run,framespertimebin, timeperiods, timebefore, timetotal);
            
            %smooth curvature to reduce noise
            smoothing_size = 5;
            k_run_smoothed = smooth(k_run,smoothing_size);
            %now get the curvature information at crossings
            [curvature_io_before_smoothed,curvature_io_during_smoothed,curvature_io_after_smoothed,...
                curvature_oi_before_smoothed,curvature_oi_during_smoothed,curvature_oi_after_smoothed]...
                = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
                crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
                k_run_smoothed,framespertimebin, timeperiods, timebefore, timetotal);
            
            
            %curvature
            crossing_plotter(curvature_io_before,curvature_io_during,curvature_io_after,...
                curvature_oi_before,curvature_oi_during,curvature_oi_after,...
                x_range,fig_title,'curvature',[-.5 .5],'curvature');
            
            %smoothed curvature
            crossing_plotter(curvature_io_before_smoothed,curvature_io_during_smoothed,curvature_io_after_smoothed,...
                curvature_oi_before_smoothed,curvature_oi_during_smoothed,curvature_oi_after_smoothed,...
                x_range,fig_title,['smoothed curvature ' num2str(smoothing_size)],[-.5 .5],'curvature');
            
            %% actual fly traces at crossing
            
            for period = period_1:period_2;
                plot_count=length(crossing_in_cell{period});
                for h = 1:plot_count
                    i = rem(h,10);
                    if i==0
                        i = 10; %to prevent error
                    end
                    if i==1 %if it is a first subplot, create a figure
                        figure
                        set(gcf,'position',[300 10 500 800]);
                    end
                    
                    subplot(5,2,i)
                    plot (short_fly_x_aligned{h, period},short_fly_y_aligned{h, period} ,'color', color(period,:))
                    hold on
                    
                    plot(rotated_in_x{h, period},rotated_in_y{h,period},'color',grey);
                    set(gca,'box','off','XColor',[1,1,1],'YColor',[1,1,1],'xtick',[],'ytick',[]);
                    xlim([min(rotated_in_x{1,2})-100 min(rotated_in_x{1,2})+50]);
                    ylim([min(rotated_in_y{1,2})-50 max(rotated_in_y{1,2})+50]);
                    text(-100,100,['time (sec); ' num2str(length(short_fly_x_aligned{h,period})/framespertimebin)],'fontsize',8);
                    
                    if i== 1
                        title([fig_title ' track: In2Out ' period_name{period}],'interpreter','none');
                    end
                    
                    if i == 10 || h == plot_count %if last plot, save the figure
                        set(gcf, 'PaperPositionMode', 'auto');
                        print('-dpsc2',[fig_title '_crossings.ps'],'-append');
                    end
                end
                
            end
                
                
            %% plot angle change at each point after crossing compared to x axis
            %
            % for period = period_1:period_2;
            %
            %     for h = 1:length(crossing_in_cell{period});
            %         repetition= length(short_fly_y_aligned{h,period});
            %         for p=1:repetition
            %         theta = atan2(short_fly_y_aligned{h,period}(p),short_fly_x_aligned{h,period}(p));
            %         theta_array(p) = theta;
            %         end
            %         angle_crossing_out{h,period} = theta_array;
            %         clear theta_array;
            %     end
            % end
            
            %%
            % for period = period_1:period_2;
            %
            %     for h = 1:length(crossing_in_cell{period});
            %         p = rem(h,10);
            %         if p==0
            %              p=10;
            %         end
            %         if p==1
            %             figure
            %         end
            %         subplot(5,2,p)
            %         plot(angle_crossing_out{h,period});hold on
            %         plot([0 1000],[0 0],'k:');
            %         ylim([-pi pi]);
            %         xlim([0 how_short*framespertimebin]);
            %     end
            % end
            
            %%
            %individual crossing: acceleration plotting
            crossing_plotter(accel_in2out_before,accel_in2out_during,accel_in2out_after,...
                accel_out2in_before, accel_out2in_during,accel_out2in_after,...
                x_range,fig_title,'acceleration',accel_ylim,accel_unit);
            
            %%
            close all;
            
            %convert ps file to pdf file
            ps2pdf('psfile', [fig_title '_crossings.ps'], 'pdffile', [fig_title '_crossings.pdf'], 'gspapersize', 'letter');
        end
    else %if user wants the main analysis only
        close all;
        
        %save all the variables
        save([fig_title ' variables.mat']);
        
        %save multiple figures (postscript files) as one pdf file
        
        ps2pdf('psfile', [fig_title '.ps'], 'pdffile', [fig_title 'Main.pdf'], 'gspapersize', 'letter');
        
        display('Pdf file is saved!');
    end
end

