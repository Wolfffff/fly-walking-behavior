%multiple_flies_analysis_V22_biggerIR by Seung-Hye (3/11/2013)

% Since the editor was running very slow,I disabled cell modes.
% for more information regarding speeding up the editor, click the site
% http://www.mathworks.com/support/solutions/en/data/1-6MBFQL/?solution=1-6MBFQL
%
% com.mathworks.services.Prefs.setBooleanPref('CodeParserServiceOn',false)


% All the behavior files ('*xypts_transformed.csv') and rim points for the
% same fly/odor/concentration need to be in one folder! and their names
% need to be consistent! (Most errors occur when the script cannot find the
% files. Check if all the csv files have corresponding transformed rim point files)
% *xypts_transformed.csv 
% *transformedrimpoints.mat
% (*inner_transformed.csv, *outer_transformed.csv :  not necessary if the
% mat file is present)


%%Changes in V22
%basically same as V21, smoothing of the tracks is back to the previous
%method!

%Changes in V21
% 1.Smoothing of tracks has been changed to use 'sgolay' (Savitzky-Golay
% filter)
% 2.runthreshold .16 to .10, stopthreshold .10 to .03!
% 3.velocity_classified has been replaced by velocity_classifier1 : this
% function is more sensitive for runs (first frame above the run threshold
% will be counted as a run)
% 4.curvature calculation has been changed: instead of LineCurvature2D, it
% uses LineNormal2D to get the normal unit vectors then get the angle

% This program needs following functions and scripts

% 1. period_def
% 2. crossingframes
% 3. radial_calculator_circle1
% 4. vel_calculator
% 5. velocityatcrossing_basic
% 6. velocityatcrossing_with_frames
% 7. run_stop_generator1 **V15
% 8. short_long_crossing
% 9. rad_velocity_binned
% 10. Velocity_Classifier1 (V21)
% 11. runprobabilitySJ
% 12. velocity_normalizer
% 13. mean_calculator
% 14. bin_ttest
% 15. crossing_beyond_threshold
% 16. vel_in_out_divider
% 17. turn_inside_ring (V17)
% 18. run_in_out_divider (V20)
% 19. curvature_magnitude_comparison
% 20. multiple_flies_inside_rim_plotter
% 21. multiple_flies_run_in_out_stats_plotter
% 22. LineNormals2D (V21)


clear all; close all;
warning('off');

prog_version =  'V22';

% set constants
framespertimebin =30;%how many frames/sec?
secsperperiod = 180;%how many seconds/period?

outer_radius = 3.2;
inner_radius = 1.2; %new chamber (cm)

%bigger inner_radius: change this number to see the effect
inner_radius_bigger = 1.9; %based on ACV0 data

%bin_number is always compared to 1.2 cm actual IR, so less than 5 might
%make the distributino look too noisy. (8/16/13)
bin_number = 5; %number of bins inside the odor zone for radial distribution calculation

%set the minimum number of crossings/fly, use that fly's data only if
%crossing number is bigger than this number
crossing_min = 2;

%first get the odor name and dilution info
user_answer = input('Use same fly and odor info? 1 for yes, 2 for no: ');
if user_answer == 1
    load('fly_odor_info.mat');
    fly_odor = user_input;
    display(fly_odor)
else
    user_input1= input('Enter the fly genotype : ','s');
    user_input2 = input('Enter the odor name and concentration : ' ,'s');
    user_input = [user_input1 ' ' user_input2];
    save('fly_odor_info.mat','user_input');
end

fig_title = [user_input ' ' prog_version 'biggerIR' num2str(inner_radius_bigger*10)];


%========loading the CSV + mat files=======================================

%load the newest previous behavior file name list to compare with the current one
d = dir('*behavior_file_names.mat');
if isempty(d) == 0
    dates = [d.datenum];
    [~, newestIndex] = max(dates);
    newest_file = d(newestIndex);
    most_current_file = load(newest_file.name, 'track_names');
end

% find behavior files in the folder and save the names in 'tracks'
behavior_list = dir('*xypts_transformed.csv');
tracks = {behavior_list.name};
numflies = length(tracks);
track_names = tracks';
save([num2str(fig_title) 'behavior_file_names'],'track_names');

%in case the current folder does not contain any csv file
if numflies == 0
    error('There is no behavior file (*xypts_transformed.csv) in this folder.');
end

%find the shortest video and use that frame number for all the files
file_length = nan(1,numflies);
for i=1:numflies
    filename_behavior = tracks{i};
    m = csvread(filename_behavior,2);
    file_length(i) = length(m);
end

file_min_length = min(file_length);
display(file_min_length)
numvals_original=nan(file_min_length,2*numflies);
numvals = nan(file_min_length, 2*numflies);
numvals_pi =cell(1,numflies);
numvals_po =cell(1,numflies);

%find rim points files (all the CSV and mat files) and save file names
inner_rim_csv_files = dir('*inner_transformed.csv');
inner = {inner_rim_csv_files.name};
outer_rim_csv_files = dir('*outer_transformed.csv');
outer = {outer_rim_csv_files.name};
rim_mat_files= dir('*transformedrimpoints.mat');
rims = {rim_mat_files.name};
inner_rim_names = cell(numflies,1); %save names of rim files used

%read fly track CSV files
for i=1:numflies
    filename_behavior = tracks{i};
    m = csvread(filename_behavior,2);%disregard the first point
    numvals_original(:,[2*i-1 2*i])=  m(1:file_min_length,:);
    
    %smoothing the fly tracks
    % CHANGED FROM V21!
    %     fly_x = smooth(numvals_original(:,2*i-1),10,'sgolay');%x
    %     fly_y = 480 - numvals_original(:,2*i); %flip y axis first
    %     fly_y =  smooth(fly_y,10,'sgolay');%y
    %     %second smoothing
    %     numvals(:,2*i-1) = smooth(fly_x,2);
    %     numvals(:,2*i) = smooth(fly_y,2);
    %V22
    numvals(:,2*i-1) = smooth(numvals_original(:,2*i-1),10);%x
    numvals(:,2*i) =  smooth(numvals_original(:,2*i),10);%y
    numvals(:,2*i) = 480 - numvals(:,2*i); %flip y axis
    
    
    clear fly_x fly_y
    
    %read rim mat / csv files
    exp_date = num2str(tracks{i}(1:6));
    match=[];
    for n=1:length(rims) %find the matching mat file for the behavior file
        match(n) = strcmp(exp_date,num2str(rims{n}(1:6)));
    end
    q = find(match); %non-zero element == matching file number
    
    if isempty(q) == 0 %if there is a matching mat file
        if length(q) >1 %if there are more than one mat files
            %             display(filename_behavior)
            %             display('first rim mat file is ')
            %             display(rims{q(1)})
            %             display('second rim mat file is')
            %             display(rims{q(2)})
            %             mat_answer = input('Type 1 if you want to use the first mat file, type 2 if you want to use the second mat file; ')
            %             j = q(mat_answer);
            secondDigit = filename_behavior(13); %check if the video number is two digits
            if strcmp(secondDigit, '_')==1 %if the video number is one digit
                j = q(2); %this will pick '130618_transformerimpoints.mat'file
            else % if the video number is two digits
                if str2num(filename_behavior(12:13))>30  %from T3600
                    j = q(1); %this will pick '130618_3transformedrimpoints.mat' file.
                else
                    j = q(2); %this will pick '130618_transformerimpoints.mat'file
                end
            end
            
        else
            j = q;
        end
        
        load(rims{j});
        inner_rim_names(i) = {rims{j}};%save the file name
        numvals_pi(:,i)= {inner_transformed};
        numvals_po(:,i)= {outer_transformed};
        %flip y axis
        numvals_pi{i}(:,2) = 480 -numvals_pi{i}(:,2);
        numvals_po{i}(:,2) = 480 -numvals_po{i}(:,2);
        
    else %if there is no matching mat file, start searching for csv files
        for n=1:length(inner) %find the inner rim file that matches the behavior file
            file_number(n) =strcmp(exp_date,num2str(inner{n}(1:6)));
        end
        p =find(file_number);%non-zero element == matching file number
        if length(p) >1 %if there are more than one csv files
            display(filename_behavior)
            display('first rim CSV file is ')
            display(inner{p(1)})
            display('second rim CSV file is')
            display(inner{p(2)})
            csv_answer = input('Type 1 if you want to use the first CSV file, type 2 if you want to use the second CSV file; ')
            k = p(csv_answer);
        else
            k = p;
        end
        
        filename_position_inner = inner{k};
        n = xlsread(filename_position_inner);
        numvals_pi(:,i) = {n};
        inner_rim_names{i} = inner{k};
        
        filename_position_outer =outer{k};
        m = xlsread(filename_position_outer);
        numvals_po(:,i) = {m};
        
        %flip y axis
        numvals_pi{i}(:,2) = 480 -numvals_pi{i}(:,2);
        numvals_po{i}(:,2) = 480 -numvals_po{i}(:,2);
        
    end
end;
save ([num2str(fig_title) 'inner_rim_names'], 'inner_rim_names');

% convert inner rim radius from 1.2 to 1.5 or 'inner_radius_bigger' variable

%save a copy of original numvals_pi for plotting
numvals_pi_ori = numvals_pi;

%change numvals_pi to make inner rim bigger
for i=1:numflies
    in_x = numvals_pi{i}(:,1);
    in_y = numvals_pi{i}(:,2);
    
    %use circle fit to find the center and radius
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
    numvals_pi{i}(:,1) = in_x_bigger;
    numvals_pi{i}(:,2) = in_y_bigger;
end


%pre-allocating matrices
inside_rim = zeros(file_min_length,numflies);
in_out_pts = zeros(file_min_length,numflies);

odoron_frame = zeros(1,numflies);
odoron_frame_bigger = zeros(1,numflies);

crossing_flies = cell(1,numflies);
crossing_in_flies =cell(1,numflies);
crossing_out_flies = cell(1,numflies);

time_in_flies = nan(numflies,3);
time_out_flies = nan(numflies,3);
crossing_number_flies =zeros(numflies,3);

time_in_transit_before_flies = cell(1,numflies);
time_in_transit_during_flies = cell(1,numflies);
time_in_transit_after_flies = cell(1,numflies);

time_out_transit_before_flies = cell(1,numflies);
time_out_transit_during_flies = cell(1,numflies);
time_out_transit_after_flies = cell(1,numflies);

mean_time_in_transit_flies = nan(numflies,3);
mean_time_out_transit_flies = nan(numflies,3);

avg_radius_flies = nan(numflies,3);

total_avg_vel_in_flies = nan(numflies,3);
total_avg_vel_out_flies = nan(numflies,3);

radius_flies = nan(file_min_length,numflies);
rad_vel_flies = nan(file_min_length,numflies);

for i=1:numflies
    %find out if the fly is inside the odor zone by using 'inpolygon' 1=in,0=out
    inside_rim(:,i) = inpolygon(numvals(:,2*i-1),numvals(:,2*i),numvals_pi{i}(:,1),numvals_pi{i}(:,2));
    
end
in_out_pts(2:end,:) = diff(inside_rim); % 1 or -1: frame #s of crossing

%copy the original variables
inside_rim_ori = inside_rim;
in_out_pts_ori = in_out_pts;

%calculate the velocity
%pre-allocate
velocity_flies = zeros(size(numvals,1),numflies);
vel_classified_flies= zeros(size(numvals,1),numflies);
runstops_flies = zeros(size(numvals,1),numflies);
vel_classified_binary_flies = zeros(size(numvals,1),numflies);

display('velocity unit is cm/sec')

for i=1:numflies %if start_no is bigger than numflies, it will skip this part
    vel_x_total = diff(numvals(:,2*i-1)); %smoothed already
    vel_y_total = diff(numvals(:,2*i));
    vel_total_temp = sqrt((vel_x_total.^2+vel_y_total.^2));
    
    %converting the unit of velocity to cm/sec
    %using circfit instead of ellipse fit to get the outer rim radius
    %(out_R)
    [out_xc,out_yc,out_R,out_a] = circfit(numvals_po{i}(:,1),numvals_po{i}(:,2));
    
    velocity = vel_total_temp.*outer_radius/(out_R)*framespertimebin;
    velocity_flies(2:end,i) = velocity; %save each fly's velocity
    
    %pixel to cm conversion : length of 1 pixel in cm
    pixel2cm(i) = outer_radius/(out_R);
    
end
% Run_stop_analysis: CLASSIFYING THE FIRST POINT by a user
%threshold was set empirically by comparing the velocity with the video by
%Catherine

%this has been changed from V20
% *** 1 pixel = ~.01 cm (.1 mm)
runthreshold = .10;
% stopthreshold = .03;

stopthreshold = .05;

%automatically load the previously saved mat file(s) and show which behavior
%files were already checked for run/stop
runstop_files = dir('*first_runstop.mat');

if isempty(runstop_files) == 0 %if there is a saved runstop file,
    [~,idx] = sort([runstop_files.datenum]);
    newest = runstop_files(idx(end));
    runstop_to_use = newest.name; %the most current name of file
    previous_file = load(runstop_to_use);
    display([runstop_to_use ' file contains previously saved run/stop information for the following behavior files'])
    
    % find which behavior files were already checked
    filename_list= {most_current_file.track_names{1:length(previous_file.first_runstop)}}; %display which files were already checked
    celldisp(filename_list)
    display('Do you want to use the previously saved initial run/stop decision? ')
    display('(Do not use the saved info if you added more files)')
    plot_decider = input('Enter for Yes, type 1 to manually check: ');
    
else
    display('There is no previously saved file for run/stop decision')
    plot_decider = 2;
    
end

if isempty(plot_decider) == 0 %user typed '1' to manually check run/stop and save the info
    %first check if there is any saved file to skip the ones that were
    %already saved
    if plot_decider ==1
        display('If more RECENT files were added, press 1')
        answer1 = input('if OLDER files were added, press 2');
        if answer1 == 1 %use the old saved info
            old_file_no = numel(filename_list);
        else %if start from the beginning
            old_file_no = 0;
        end
        start_no = old_file_no +1; %from which files to check?
    elseif plot_decider ==2 %there is no saved file
        start_no = 1;
    end
    
    %manually check the run/stop for the first frames
    for i=start_no:numflies %if start_no is bigger than numflies, it will skip this part
        
        velocity = velocity_flies(:,i); %load velocity data
        
        figure
        
        xlim1 = 1; %x limits for the initial plot
        xlim2 = 25;
        xincrem = 5;
        
        ylim1 = 0;
        ylim2 = 2;
        yincrem = .1;
        
        
        x1 = (xlim1:xlim2);
        
        plot(x1,velocity(xlim1:xlim2),'ro-'); hold on;
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
        
        %determine if the first four points are a run or a stop using the same
        %criteria used in velocity_classifier
        first_vel = velocity(1:4);
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
        first_point = input ('Type 1 if the first point is a RUN, 0 if a STOP; ');
        close all;
        
        first_runstop(i) = first_point;
    end
    save([fig_title 'first_runstop.mat'], 'first_runstop');
    
else %if want to skip manual checking, just load the variables
    load(runstop_to_use);
    save([fig_title 'first_runstop.mat'], 'first_runstop');
end

%now calculate the classified velocity
for i=1:numflies
    % CLASSIFYING POINTS
    %     for four consecutive frames, all four points are above stopthreshold, it
    %     is 'run'. if only the second frame is below stopthreshold, it is still
    %     'run'.
    %     velocity_classified is just turning the velocity during "stops"  to zero
    %     velocity_classified_binary: runs =1 and stops =0
    %     runstops: NaN vector except the points when run becomes stop or stop
    %     becomes run (1)(if the first frame is run, it is '1')
    
    velocity = velocity_flies(:,i); %load velocity data
    
    vel_total = velocity;
    first_point = first_runstop(i);
    
    %Velocity_Classifier1 from V21
    [velocity_classified, velocity_classified_binary, runstops] =...
        Velocity_Classifier1(vel_total, first_point, stopthreshold, runthreshold );
    
    vel_classified_flies (:,i) = velocity_classified;
    runstops_flies(:,i) = runstops;
    vel_classified_binary_flies(:,i) = velocity_classified_binary;
end




% using velocity_classified, check the crossing frames again, and remove the ones during the continuous stop
for fly = 1:numflies
    for i=2:length(in_out_pts)
        if in_out_pts(i,fly) ~= 0 && vel_classified_flies(i,fly) == 0 %if 'i'th frame is marked as crossing and classified as 'stop'
            if vel_classified_flies(i-1,fly) == 0 % and the previous frame is also a stop
                inside_rim(i,fly) = inside_rim(i-1,fly); %then do not change in to out or out to in
            end
            in_out_pts(2:end,fly) = diff(inside_rim(:,fly));%re-check in_out_pts after changing inside_rim (ou2in=1, in2out = -1)
        end
    end
end



%pre-allocate arrays

odoron_frame = nan(numflies,1);
% this part contains all the arrays in 'turning/curvature' part
curvature_flies = nan(file_min_length,numflies);
% frame_sharp_turn = cell(numflies,1);%frame# for all the sharp turns(one frame #/turn)
% frame_wide_turn = cell(numflies,1);%frame# for all the wide turns (one frame #/turn)
%
% k_sum_win_flies = nan(file_min_length,numflies);

curv_frame_flies = cell(numflies,1);
curv_flies = cell(numflies,1);
curv_time_flies = cell(numflies,1);
curv_totalturn_flies = cell(numflies,1);

curv_absturn_flies = cell(numflies,1);
reorient_flies = cell(numflies,1);
reorient_abs_flies = cell(numflies,1);

totalturn_flies = nan(file_min_length,numflies);
turn_curvewalk_flies = cell(numflies,1);
turn_reorientation_flies =cell(numflies,1);

time_bw_turns_flies = cell(numflies,1);


frame_all_curv = cell(numflies,1);%save frame# of every turning/curving
frame_in_flies = zeros(3,numflies);%how many frames inside/fly
frame_out_flies = zeros(3,numflies);%how many frames outside/fly

turn_flies = cell(3, numflies);%sharp turn frame # (one frame/one sharp turn))/period,
turn_in_flies = cell(3,numflies);%/in/out
turn_out_flies = cell(3,numflies);

NumTurn_flies = zeros(3, numflies);% # of sharp turns
NumTurn_in_flies = zeros(3, numflies);
NumTurn_out_flies = zeros(3,numflies);

turn_rate_flies = nan(3,numflies); % rate of sharp turns (#/sec)
turn_rate_in_flies = nan(3,numflies);
turn_rate_out_flies = nan(3,numflies);

curv_period_flies = cell(3, numflies); %frame# for all the curved walks
curv_in_flies = cell(3, numflies);
curv_out_flies = cell(3,numflies);

curv_fr_flies = nan(3,numflies); % fraction of curved walk/all the walk (excluding stops)
curv_fr_in_flies = nan(3,numflies);
curv_fr_out_flies = nan(3,numflies);


NumRings = 5; %number of rings

%frames inside the user-defined ring area
fly_in_ring_flies = cell(numflies,NumRings);
fly_in_ring_period_flies = cell(3, numflies,NumRings);
%frequency of sharp turns inside the ring area
turn_in_ring_flies = cell(numflies,NumRings);
turn_in_ring_period_flies = cell(3,numflies,NumRings);
turn_fr_ring_flies = nan(numflies,NumRings);
turn_fr_ring_period_flies = nan(3,numflies,NumRings);
%fraction of curved walk inside the pre-set ring area
curv_fr_ring_flies = nan(numflies,NumRings);
curv_fr_ring_period_flies = nan(3,numflies,NumRings);
curv_in_ring_flies = cell(numflies,NumRings);
curv_in_ring_period_flies = cell(3,numflies,NumRings);
%xy coordinates of rings
ring_inner_flies = nan(size(numvals_pi{1},1),2*numflies,NumRings);
ring_outer_flies = nan(size(numvals_pi{1},1),2*numflies,NumRings);

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% Repeating same calculation for each fly==================================
for i=1:numflies
    filename_behavior = tracks{i};
    fly_x = numvals(:,2*i-1); %already smoothed
    fly_y = numvals(:,2*i);
    
    %get the crossing frames, odoron_frames, and timeperiods
    [crossing,crossing_in,crossing_out,odoron_frame1,odoroff_frame,timeperiods]=...
        period_def(fly_x,framespertimebin,secsperperiod,inside_rim(:,i),in_out_pts(:,i));
    
    odoron_frame(i) = odoron_frame1;
    %save each fly's crossings in cell arrays
    crossing_flies(i) = {crossing};
    crossing_in_flies(i) = {crossing_in};
    crossing_out_flies(i) = {crossing_out};
    
    % calculate the time fly spent inside in each time period
    % actual frame numbers
    time_in_before_frames = sum(inside_rim(1:timeperiods(2),i));
    time_in_during_frames = sum(inside_rim(odoron_frame(i):odoroff_frame-1,i));
    time_in_after_frames = sum(inside_rim(odoroff_frame:end,i));
    
    
    % save each fly's data
    frame_in_flies(1,i) = time_in_before_frames;
    frame_in_flies(2,i) = time_in_during_frames;
    frame_in_flies(3,i) = time_in_after_frames;
    %frame_out: each fly's data
    frame_out_flies(1,i) = timeperiods(2) - time_in_before_frames;
    frame_out_flies(2,i) = (timeperiods(3)- odoron_frame1 +1) - time_in_during_frames;
    frame_out_flies(3,i) = (timeperiods(4) - timeperiods(3) +1) - time_in_after_frames;
    
    
    % in fraction: 1 means that the fly was inside for the entire period
    time_in_before = time_in_before_frames/timeperiods(2);
    time_in_during = time_in_during_frames/(odoroff_frame-odoron_frame(i)-1);
    time_in_after = time_in_after_frames/(timeperiods(4)-odoroff_frame-1);
    
    time_in_flies(i,1) = time_in_before;
    time_in_flies(i,2) = time_in_during;
    time_in_flies(i,3) = time_in_after;
    
    %calculate time fly spent outisde in each time period in fraction
    time_out_before = 1-time_in_before;
    time_out_during = 1-time_in_during;
    time_out_after = 1-time_in_after;
    
    time_out_flies = 1-time_in_flies;
    
    
    
    %find out the crossing frames in each period and the number of crossings
    [crossing_in_before, crossing_in_during, crossing_in_after,...
        crossing_out_before,crossing_out_during,crossing_out_after,crossing_before_No,crossing_during_No,crossing_after_No,...
        frames_in_before, frames_out_before,frames_in_during,frames_out_during,frames_in_after,frames_out_after]=...
        crossingframes(crossing,crossing_in,crossing_out,odoron_frame1,odoroff_frame,timeperiods,in_out_pts(:,i), fly_x, fly_y);
    
    %save data for all flies
    crossing_number_flies(i,1) = crossing_before_No;
    crossing_number_flies(i,2) = crossing_during_No;
    crossing_number_flies(i,3) = crossing_after_No;
    
    
    %get time(sec) spent inside per transit
    time_in_transit_before = frames_in_before/framespertimebin;
    time_out_transit_before = frames_out_before/framespertimebin;
    % get the average of all transits
    avg_time_in_transit_before = nanmean(time_in_transit_before);
    avg_time_out_transit_before = nanmean(time_out_transit_before);
    
    median_time_in_transit_before =nanmedian(time_in_transit_before);
    median_time_out_transit_before =nanmedian(time_out_transit_before);
    
    
    %get the time spent inside per transit in second
    time_in_transit_during = frames_in_during/framespertimebin;
    time_out_transit_during = frames_out_during/framespertimebin;
    % get the average
    avg_time_in_transit_during = nanmean(time_in_transit_during);
    avg_time_out_transit_during = nanmean(time_out_transit_during);
    
    median_time_in_transit_during =nanmedian(time_in_transit_during);
    median_time_out_transit_during =nanmedian(time_out_transit_during);
    
    
    %get the time spent inside per transit in second
    time_in_transit_after = frames_in_after/framespertimebin;
    time_out_transit_after = frames_out_after/framespertimebin;
    % get the average
    avg_time_in_transit_after = nanmean(time_in_transit_after);
    avg_time_out_transit_after = nanmean(time_out_transit_after);
    
    median_time_in_transit_after =nanmedian(time_in_transit_after);
    median_time_out_transit_after =nanmedian(time_out_transit_after);
    
    %save data for all the flies
    time_in_transit_before_flies(i) = {time_in_transit_before};
    time_in_transit_during_flies(i) = {time_in_transit_during};
    time_in_transit_after_flies(i) = {time_in_transit_after};
    
    time_out_transit_before_flies(i) = {time_out_transit_before};
    time_out_transit_during_flies(i) = {time_out_transit_during};
    time_out_transit_after_flies(i) = {time_out_transit_after};
    
    %mean
    mean_time_in_transit_flies(i,1)= avg_time_in_transit_before;
    mean_time_in_transit_flies(i,2)= avg_time_in_transit_during;
    mean_time_in_transit_flies(i,3)= avg_time_in_transit_after;
    
    mean_time_out_transit_flies(i,1)= avg_time_out_transit_before;
    mean_time_out_transit_flies(i,2)= avg_time_out_transit_during;
    mean_time_out_transit_flies(i,3)= avg_time_out_transit_after;
    
    %median
    median_time_in_transit_flies(i,1)= median_time_in_transit_before;
    median_time_in_transit_flies(i,2)= median_time_in_transit_during;
    median_time_in_transit_flies(i,3)= median_time_in_transit_after;
    
    median_time_out_transit_flies(i,1)= median_time_out_transit_before;
    median_time_out_transit_flies(i,2)= median_time_out_transit_during;
    median_time_out_transit_flies(i,3)= median_time_out_transit_after;
    
    
    %radial distribution===================================================
    
    out_x = numvals_po{i}(:,1);
    out_y = numvals_po{i}(:,2);
    %Changed from numvals_pi to numvals_pi_ori so that inner_radius =1.2 cm
    %is actually 1.2 cm (8/16/13)
    in_x = numvals_pi_ori{i}(:,1);
    in_y = numvals_pi_ori{i}(:,2);
    
    
    [out_R,fly_bin_probability, bin_radius, average_radius,fly_location_bin] = ...
        radial_calculator_circle1(fly_x,fly_y, out_x,out_y,in_x,in_y,bin_number,timeperiods,...
        odoron_frame1,odoroff_frame, inner_radius, outer_radius);
    
    bin_probability_flies(i) = {fly_bin_probability};
    radius_n(i) = length(fly_bin_probability);
    
    bin_radius_flies(i) = {bin_radius};
    avg_radius_flies(i,:) = average_radius;
    location_fly(:,i) = fly_location_bin;
    
    
    
    % total + average vel calculation
    [vel_total,velocity_fly_in, velocity_fly_out,avgvelocity_by_fly_in, avgvelocity_by_fly_out]=...
        vel_calculator(fly_x,fly_y,timeperiods,out_R, crossing, framespertimebin, inside_rim(:,i),outer_radius);
    
    vel_unit = 'velocity(cm/sec)';
    
    vel_total_flies(:,i) = vel_total;
    vel_in_flies{i} = velocity_fly_in;
    vel_out_flies{i} = velocity_fly_out;
    
    total_avg_vel_in_flies(i,:) = avgvelocity_by_fly_in;
    total_avg_vel_out_flies(i,:) = avgvelocity_by_fly_out;
    
    clear avgvelocity_by_fly_in avgvelocity_by_fly_out;
    
    
    %radial velocity calculation, radial and total velocity binned by
    %radius (fly's location
    bin_number1 = bin_number;
    
    [radius_fly,rad_vel,circRad,radius_binned,rad_vel_sqrt,...
        avg_vel_by_radius_before,avg_vel_by_radius_during,avg_vel_by_radius_after,...
        avg_radvel_by_radius_before,avg_radvel_by_radius_during,avg_radvel_by_radius_after,...
        avg_vel_by_radius_before_median,avg_vel_by_radius_during_median,avg_vel_by_radius_after_median,...
        avg_radvel_by_radius_before_median,avg_radvel_by_radius_during_median,avg_radvel_by_radius_after_median]...
        = rad_velocity_binned(in_x,in_y, fly_x,fly_y,out_x,out_y,bin_number,...
        timeperiods,odoron_frame1,odoroff_frame,vel_total,out_R,framespertimebin,outer_radius);
    
    %convert radius_fly (pixel) to cm unit
    radius_fly_cm = (radius_fly.*inner_radius)/circRad;
    
    radius_flies(:,i) = radius_fly;
    radius_cm_flies(:,i) = radius_fly_cm;
    rad_vel_flies(:,i) = rad_vel;
    circRad_flies(i) = circRad;
    
    radius_binned_flies(:,i) = radius_binned;
    rad_vel_sqrt_flies(:,i) = rad_vel_sqrt;
    
    %average (mean) of velocity by radius
    avg_vel_by_radius_flies{1,i} = avg_vel_by_radius_before;
    avg_vel_by_radius_flies{2,i} = avg_vel_by_radius_during;
    avg_vel_by_radius_flies{3,i} = avg_vel_by_radius_after;
    %rad_vel_sqrt average
    avg_radvel_by_radius_flies{1,i} = avg_radvel_by_radius_before;
    avg_radvel_by_radius_flies{2,i} = avg_radvel_by_radius_during;
    avg_radvel_by_radius_flies{3,i} = avg_radvel_by_radius_after;
    
    %get the individual bin data + standard deviation
    [vel_by_radius_before,vel_by_radius_during,vel_by_radius_after,...
        std_vel_by_radius_before,std_vel_by_radius_during,std_vel_by_radius_after,...
        radvel_by_radius_before,radvel_by_radius_during,radvel_by_radius_after]...
        = rad_velocity_binned_for_stats(in_x,in_y, fly_x,fly_y,out_x,out_y,bin_number,...
        timeperiods,odoron_frame1,odoroff_frame,vel_total,out_R,framespertimebin,outer_radius);
    
    %velocity difference in each bin between during and before (comparison of means)
    avg_vel_diff_by_bin = avg_vel_by_radius_during - avg_vel_by_radius_before;
    std_vel_diff_by_bin = std_vel_by_radius_during + std_vel_by_radius_before;
    
    avg_vel_diff_by_flies{i} = avg_vel_diff_by_bin;
    std_vel_diff_by_flies{i} = std_vel_diff_by_bin;
    
    
    % CLASSIFYING velocity into Run and Stop================================
    
    %since all the calculations were already done, just copy the specific
    %fly's data
    velocity_classified = vel_classified_flies(:,i);
    runstops = runstops_flies(:,i);
    velocity_classified_binary = vel_classified_binary_flies(:,i);
    
    % Dividing Data into Runs and stops
    %From V15, it has been replaced with run_stop_generator1
    [runs, stops] = run_stop_generator2(runstops, velocity_classified, timeperiods,odoron_frame1);
    
    runs_flies(i) = {runs};
    stops_flies(i) = {stops};
    
    % Run stop probability in VS out
    [vel_in_run, vel_in_stop, vel_out_run, vel_out_stop] =...
        vel_in_out_divider(velocity_classified, inside_rim(:,i),timeperiods,odoron_frame1);
    
    run_in_flies(i) = {vel_in_run};
    run_out_flies(i) = {vel_out_run};
    stops_in_flies(i) = {vel_in_stop};
    stops_out_flies(i) = {vel_out_stop};
    
    %================================================================
    %run_in_out_divider function (V20)
    %run_in_entire: frame # for before/during runs inside the rim (entirely)
    %run_out_entire: frame# for before/during runs outside the rim
    %(entirely)
    [run_in_entire,run_out_entire] =...
        run_in_out_divider(velocity_classified_binary,inside_rim(:,i),runstops,timeperiods,odoron_frame1);
    
    run_in_entire_flies{1,i} = run_in_entire{1};
    run_in_entire_flies{2,i} = run_in_entire{2};
    run_out_entire_flies{1,i} = run_out_entire{1};
    run_out_entire_flies{2,i} = run_out_entire{2};
    
    %================================================================
    % total and radial velocity plot at crossing============================
    %2 sec (timebefore) before and 3 sec after crossing!
    % this function uses vel_total from vel_calculator
    % this also outputs the frame numbers used in the velocity crossing
    
    %time (sec)  before the crossing to save the velocity info
    timebefore = 2;
    %total time (sec) to save the velocity including before and after
    %crossings
    timetotal = 5;
    how_long = timetotal*framespertimebin; %how many frames are needed for timetotal?
    
    [velocity_in2out_before,velocity_in2out_during,velocity_in2out_after,...
        velocity_out2in_before,velocity_out2in_during,velocity_out2in_after,...
        crossing_i2o_frames_bf,crossing_i2o_frames_dr,crossing_i2o_frames_af,...
        crossing_o2i_frames_bf,crossing_o2i_frames_dr,crossing_o2i_frames_af]...
        = velocityatcrossing_with_frames(filename_behavior,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        vel_total,framespertimebin, timeperiods, timebefore, timetotal);
    
    %save each fly's crossing frames in a cell array
    crossing_o2i_bf_frames_flies(i) = {crossing_o2i_frames_bf};
    crossing_o2i_dr_frames_flies(i) = {crossing_o2i_frames_dr};
    crossing_o2i_af_frames_flies(i) = {crossing_o2i_frames_af};
    
    crossing_i2o_bf_frames_flies(i) = {crossing_i2o_frames_bf};
    crossing_i2o_dr_frames_flies(i) = {crossing_i2o_frames_dr};
    crossing_i2o_af_frames_flies(i) = {crossing_i2o_frames_af};
    
    
    %save each fly's velocity data in a cell
    velocity_i2o_before_cell(i) = {velocity_in2out_before};
    velocity_i2o_during_cell(i) = {velocity_in2out_during};
    velocity_i2o_after_cell(i) = {velocity_in2out_after};
    
    velocity_o2i_before_cell(i) = {velocity_out2in_before};
    velocity_o2i_during_cell(i) = {velocity_out2in_during};
    velocity_o2i_after_cell(i) = {velocity_out2in_after};
    
    %   velocity_classified at crossings
    [vel_clsf_in2out_before,vel_clsf_in2out_during,vel_clsf_in2out_after,...
        vel_clsf_out2in_before,vel_clsf_out2in_during,vel_clsf_out2in_after]...
        = velocityatcrossing_basic(filename_behavior,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        velocity_classified,framespertimebin, timeperiods, timebefore, timetotal);
    
    %save each fly's velocity data in a cell
    vel_clsf_i2o_before_cell(i) = {vel_clsf_in2out_before};
    vel_clsf_i2o_during_cell(i) = {vel_clsf_in2out_during};
    vel_clsf_i2o_after_cell(i) = {vel_clsf_in2out_after};
    
    vel_clsf_o2i_before_cell(i) = {vel_clsf_out2in_before};
    vel_clsf_o2i_during_cell(i) = {vel_clsf_out2in_during};
    vel_clsf_o2i_after_cell(i) = {vel_clsf_out2in_after};
    
    
    %================================================================
    
    % runprobabilitySJ (copied, to avoid using the plotting part of function)
    
    [rs_in2out_before, rs_in2out_during,rs_in2out_after,...
        rs_out2in_before,rs_out2in_during,rs_out2in_after]...
        = velocityatcrossing_basic(filename_behavior,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        velocity_classified_binary,framespertimebin, timeperiods, timebefore, timetotal);
    
    
    in2outrunstops = {rs_in2out_before,rs_in2out_during,rs_in2out_after};
    out2inrunstops = {rs_out2in_before, rs_out2in_during,rs_out2in_after};
    
    %calculates run probability and plots
    probabilityin2out_others = nan(how_long,3);
    probabilityout2in_others = nan(how_long,3);
    
    for period = 1:3
        for hh = 1:how_long; %before crossing till 2 sec after crossing)
            a(hh,:) = in2outrunstops{period}(hh,:);%go through row-by-row (frame)
            probabilityin2out(hh,period) = (nansum(a(hh,:)>0)/sum(~isnan(a(hh,:))));
            %calculate how many runs(not 0 in velocity_classified/all events)
            
            aa(hh,:) = out2inrunstops{period}(hh,:);
            probabilityout2in(hh,period) = (nansum(aa(hh,:)>0)/sum(~isnan(aa(hh,:))));
            
            %crossings that are not the first
            
            if size(in2outrunstops{period},2) >1 %if there are more than 1 crossing
                b = in2outrunstops{period}(hh,2:end);
                probabilityin2out_others(hh,period) = (nansum(b>0)/sum(~isnan(b)));
            end
            
            if size(out2inrunstops{period},2) >1
                bb = out2inrunstops{period}(hh,2:end);
                probabilityout2in_others(hh,period) = (nansum(bb>0)/sum(~isnan(bb)));
            end
        end
        
        clear a aa b bb
    end
    
    
    %save each fly's crossing frames in a cell array
    probabilityin2out_flies(i) = {probabilityin2out};
    probabilityout2in_flies(i) = {probabilityout2in};
    
    %save fly's first crossing run & stop info
    first_i2o_rs_bf(:,i) = in2outrunstops{1}(:,1);
    first_i2o_rs_dr(:,i) = in2outrunstops{2}(:,1);
    first_o2i_rs_bf(:,i) = out2inrunstops{1}(:,1);
    first_o2i_rs_dr(:,i) = out2inrunstops{2}(:,1);
    
    %save fly's other crossings (not the first crossing) run & stop info
    probabilityin2out_others_flies(i) = {probabilityin2out_others};
    probabilityout2in_others_flies(i) = {probabilityout2in_others};
    
    %================================================================
    % radvel at crossing (absolute value, all +)
    [radvel_in2out_before,radvel_in2out_during,radvel_in2out_after,...
        radvel_out2in_before,radvel_out2in_during,radvel_out2in_after]...
        = velocityatcrossing_basic(filename_behavior,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        rad_vel_sqrt,framespertimebin, timeperiods, timebefore, timetotal);
    
    
    %save each fly's radial velocity data in a cell
    radvel_i2o_before_cell(i) = {radvel_in2out_before};
    radvel_i2o_during_cell(i) = {radvel_in2out_during};
    radvel_i2o_after_cell(i) = {radvel_in2out_after};
    
    radvel_o2i_before_cell(i) = {radvel_out2in_before};
    radvel_o2i_during_cell(i) = {radvel_out2in_during};
    radvel_o2i_after_cell(i) = {radvel_out2in_after};
    
    %======================================================================
    %% Turning analysis using curvature
    %======================================================================
    %     curvature calculation using lineNormal2D function
    % The following code is copied & pasted from
    % 'new_curvature_turn_analysis_SJ2.m'
    
    Vertices = horzcat(fly_x,fly_y);
    
    Lines=[(1:(size(Vertices,1)-1))' (2:size(Vertices,1))'];
    %get normal vectors
    N=LineNormals2D(Vertices,Lines);
    
    angle = zeros(1,length(fly_x)); %make it zero vector
    for p=1:(length(fly_x));
        %because normal is a unit vector. The x-component can be used
        % to determine the angle it makes with x-axis.
        angle(p)=acos(N(p,1));
        % the if loop converts from 0 to pi to -pi to pi
        if N(p,1)>0 && N(p,2)<0
            angle(p)=-angle(p);
        elseif N(p,1)<0 && N(p,2)<0
            angle(p)=-angle(p);
        end;
    end
    
    angle(isnan(angle)) = 0; %change Nan to zeros (when the centroid does not move, LineNormals2D assigns 'NaN')
    
    % get the change in normal (= change in tangent)
    %SJ: for angle changes from NW quadrant to SW quadrant, (i.e. .9*pi to
    %-.9*pi change is likely to be .2*pi change, rather than 1.8*pi change)
    curvature = diff(angle);
    curvature = [0 curvature];
    
    for p=2:length(angle)
        if angle(p-1)> 3*pi/4 && angle(p) < -3*pi/4 %NW to SW
            curvature(p) = 2*pi + angle(p) - angle(p-1);
        elseif angle(p-1) < -3*pi/4 && angle(p) > 3*pi/4 %SW to NW
            curvature(p) = angle(p) -angle(p-1) - 2*pi;
        end
    end
    
    %% redefining run stop for curvature. This recalculates stop beginning and end. Basically
    % all stops are stops + if velocity drops below 0.2 is also a stop + if
    % stop is less than 5 frames it is not counted for reorientation
    % calculation
    % make stop =0; Here the run threshold is higher to get rid of erroneous
    %turn when
    new_velocity_classified_binary=velocity_classified_binary;
    for p=1:length(velocity_classified_binary)
        if (vel_total(p)<0.2)
            new_velocity_classified_binary(p)=0;
        end
    end
    curvature=curvature.*(new_velocity_classified_binary)';
    curvature = curvature';
    %curvature=curvature./(vel_total)';
    
    %get the run/stop start and end frames again
    rs_trans=diff(new_velocity_classified_binary);
    run_start=find(rs_trans==1);
    stop_end=run_start-1;
    stop_start=find(rs_trans==-1);
    run_end=stop_start-1;
    
    
    if new_velocity_classified_binary(1) == 0
        stop_start=cat(1,1,stop_start);
    end
    
    if new_velocity_classified_binary(end)==0
        stop_end=cat(1,stop_end, length(new_velocity_classified_binary));
    end
    
    abc=stop_start;
    def=stop_end;
    size(stop_start);
    size(stop_end);
    j=0;
    for p=1:(length(abc))
        if((def(p)-abc(p))<5);
            stop_start(p-j)=[];stop_end(p-j)=[];
            j=j+1;
        end
    end
    size(stop_start);
    size(stop_end);
    
    angle_before=angle(stop_start);
    angle_after=angle(stop_end);
    
    reorientation=angle_after-angle_before;
    %-----------------------------------------------------------------------------------------------
    %correcting for pi to -pi conversion
    for  p=1:length(angle_before)
        if angle_before(p)> 3*pi/4 && angle_after(p) < -3*pi/4 %NW to SW
            reorientation(p) = 2*pi + angle_after(p) - angle_before(p);
        elseif angle_before(p) < -3*pi/4 && angle_after(p) > 3*pi/4 %SW to NW
            reorientation(p) = angle_after(p) - angle_before(p) - 2*pi;
        end
    end
    curvature(stop_end)=reorientation;
    
    ii=1; clear reorient_frame reorient
    %% only considering reorientations that are greater than 30 degrees
    for p=1:length(reorientation)
        if abs(reorientation(p))>0.5 % implying a reorientation>30 degrees
            reorient_frame(ii)=stop_end(p);
            reorient(ii)=reorientation(p);
            reori_stop_end(ii) = stop_end(p);
            ii=ii+1;
        end
    end
    
    %     %save end of stops in each fly
    %     reori_time_flies(i) = {reori_stop_end};
    
    
    % sum of  curvature with sliding windows===================================
    % window size = 5;
    curvature_sum = zeros(1,length(curvature));%pre-allocate an array to save sum of curvature from sliding windows
    
    for p = 1:length(curvature)
        if p < 3 %first 2 frames
            curvature_sum(p) = nansum(curvature(1:p));
        elseif p > (length(curvature) -2) %last 2 frames
            curvature_sum(p) = nansum(curvature(p:end));
        else
            curvature_sum(p) = nansum(curvature(p-2:p+2));
        end
    end
    
    % sharp turns and curved walks
    
    %sharp turns using curvature_sum
    curv_th_s = 1.3;
    [~,frame_turn_sh] = findpeaks(abs(curvature_sum),'MINPEAKHEIGHT',curv_th_s,'MINPEAKDISTANCE',8);
    
    %curved turns
    %==turning/curved walking analysis without using 'findpeaks'===============
    turn_th = 0.3; %set the threshold to define 'curving/turning' for sliding window-sum
    
    cv_frame_pos_CV = find(curvature_sum > turn_th); %get the frame #: +
    cv_frame_neg_CV = find(curvature_sum < -turn_th);
    
    % 1. if there is one frame between two turns, label that frame as also a
    % turn
    % 2. if one turning is less than 3 frame-long, discard those turns
    
    %if there is a period where only one frame is missing from the turn, also
    %label them as turn
    temp = cv_frame_pos_CV(find(diff(cv_frame_pos_CV) == 2));
    frame_bw_turn_pos = temp+1;
    temp = cv_frame_neg_CV(find(diff(cv_frame_neg_CV) == 2));
    frame_bw_turn_neg = temp+1;
    
    %make a new array to save frame # from both cv_frame_ and frame_bw_turn_
    temp = horzcat(cv_frame_pos_CV,frame_bw_turn_pos);
    cv_frame_pos_CV1 = sort(temp);
    temp = horzcat(cv_frame_neg_CV,frame_bw_turn_neg);
    cv_frame_neg_CV1 = sort(temp);
    
    %+ and - together
    cv_frame_CV = horzcat(cv_frame_pos_CV1,cv_frame_neg_CV1);
    cv_frame_CV = sort(cv_frame_CV); %this is the variable used for quantification
    
    %sort out individual curved walks
    temp = diff(cv_frame_CV);
    discontinuous = (find(temp ~= 1));%discontinous points; in between consecutive curving/turning (end of one turn)
    
    starts = [cv_frame_CV(1) cv_frame_CV(discontinuous+1)]; %start of each turn
    ends = [cv_frame_CV(discontinuous) cv_frame_CV(end)]; %end of each turn
    
    each_curv_CV = cell(length(starts),1);
    for p=1:length(starts)
        each_curv_CV{p} =(starts(p):ends(p))'; %this cell array contains all the curved walks, each as a cell
        each_curv_CV_turn{p}=curvature((starts(p)):(ends(p)))';
    end
    
    %get rid of 1-frame or 2 frame long curving/turning
    % to exclude other (e.g. 3 frame-long, or 4 frame-long), just add more
    % lines such as threeframeturn = find(curv_length ==3) etc...
    curv_length = cellfun(@length,each_curv_CV);
    curv_length1 = (cellfun(@length,each_curv_CV_turn))';
    oneframeturn = find(curv_length == 1); %which cell's length is one?
    oneframeturn1 = find(curv_length1 == 1);
    twoframeturn = find(curv_length ==2); %2 frame turn?
    twoframeturn1 = find(curv_length1 ==2); %2 frame turn?
    onetwo_turn = [oneframeturn; twoframeturn];
    onetwo_turn1 = [oneframeturn1; twoframeturn1];
    onetwo_turn = sort(onetwo_turn);%oneframeturn + twoframeturn
    onetwo_turn1 = sort(onetwo_turn1);
    
    long_turn = [1:length(each_curv_CV)];
    long_turn1 = [1:length(each_curv_CV_turn)];
    long_turn = setdiff(long_turn,onetwo_turn); %find turns that are not one or two frames-long
    long_turn1 = setdiff(long_turn1,onetwo_turn1);
    long_turn = long_turn'; %index for 3 or longer frame/turn
    long_turn1 = long_turn1';
    curv_long_CV = each_curv_CV(long_turn); %get turnings that are longer than 3 frames
    
    %curv_long_CV_turn stores the value of curvature for all frames assigned as
    %turn. curv_long_CV_totalturn asks how much the fly turned in each turning
    %episode.
    %% important variables
    curv_long_CV_turn = (each_curv_CV_turn(long_turn))'; %stores the value of curvature during all curved walk
    curv_long_times = cellfun(@(xxx)xxx(1),curv_long_CV)/framespertimebin;%start time  of each curved walk
    curv_long_ends = cellfun(@(xxx)xxx(end),curv_long_CV)/framespertimebin; %end time of each curved walk
    curv_long_CV_totalturn = cellfun(@sum,curv_long_CV_turn); % amount the fly turns in each curved walk, sign is preserved
    curv_long_CV_absturn = abs(curv_long_CV_totalturn); % amount the fly turns per curved walk irrespective of sign
    reorient_frame = reorient_frame; % frames at which reorientation takes place
    reorient = reorient; %reorientation angle
    reorient_abs = abs(reorient);
    
    totalturn = cumsum(curvature);
    turn_curvewalk = cumsum(curv_long_CV_totalturn); %create time axes to plot
    turn_reorientation = cumsum(reorient);
    
    abs_totalturn = abs(totalturn);
    abs_turn_curvewalk = cumsum(curv_long_CV_totalturn);
    abs_turn_reorientation = cumsum(curv_long_CV_totalturn);
    
    %time between each turns : curv_start (curv_long_times) - previous
    %curv_ends (curv_long_ends)
    time_between_turns = curv_long_times(2:end) - curv_long_ends(1:end-1);
    % plot a histogram of turn times
    %convert from cell array to matrix
    curv_long_mat = cell2mat(curv_long_CV);%this array contains all the frame # for curved walks
    
    %----------------------------------------------------------------------
    % save each fly's curvature/turn data in cell arrays
    curvature_flies(:,i) = curvature; %curvature
    curv_frame_flies(i) = {curv_long_mat}; %frame # for curved walks
    curv_flies(i) = {curv_long_CV_turn}; % curvature for curved walks
    curv_time_flies(i) = {curv_long_times}; %start time of each curved walk
    curv_totalturn_flies(i) = {curv_long_CV_totalturn}; %amount the fly turns in each curved walk, sign is preserved
    curv_absturn_flies(i) = {curv_long_CV_absturn}; % amount the fly turns per curved walk irrespective of sign
    
    reorient_flies(i) = {reorient};
    reorient_abs_flies(i) = {reorient_abs};
    reori_time_flies(i) = {reorient_frame};
    
    totalturn_flies(:,i) = totalturn';
    turn_curvewalk_flies(i) = {turn_curvewalk};
    turn_reorientation_flies(i) = {turn_reorientation};
    
    time_bw_turns_flies(i) = {time_between_turns};
    
    
    
    %==========================================================================
    
    % quantification of turns/straight walk/curved walk
    
    % TURN from k_run thresholding
    % how many sharp turns/period, in/out
    %quantify turns by 'periods' then by 'in' and 'out' (all turns)
    
    %how many frames (time) in/out in each period
    frame_in(1) = sum(inside_rim(1:timeperiods(2),i));
    frame_in(2) = sum(inside_rim(odoron_frame(i):odoroff_frame-1,i));
    frame_in(3) = sum(inside_rim(odoroff_frame:end,i));
    
    frame_out(1) = timeperiods(2) - frame_in(1);
    frame_out(2) = (odoroff_frame-odoron_frame(i)) - frame_in(2);
    frame_out(3) = (length(inside_rim(:,i)) - odoroff_frame+1) - frame_in(3);
    
    frame_in_flies(:,i) = frame_in;
    frame_out_flies(:,i) = frame_out;
    
    %SHARP TURNS : how many sharp turns/sec?==================================
    
    %pre-allocate arrays (save frame #)
    turn_before = nan(1); turn_during = nan(1); turn_after = nan(1);
    turn_before_in = nan(1); turn_during_in = nan(1); turn_after_in = nan(1);
    turn_before_out = nan(1); turn_during_out = nan(1); turn_after_out = nan(1);
    
    n=1;q=1;r=1;
    s=1; t=1; u=1; v=1; w=1; y=1;
    for p=1:length(frame_turn_sh)
        ft = frame_turn_sh(p);
        if ft <= timeperiods(2) %before
            turn_before(n) = ft; n=n+1;
            
            if inside_rim(ft,i) ==1 %in
                turn_before_in(s) = ft; s=s+1;
            else
                turn_before_out(t) = ft; t=t+1;
            end
            
        elseif odoron_frame(i) <= ft && ft < odoroff_frame %during
            turn_during(q) = ft; q=q+1;
            
            if inside_rim(ft,i) ==1 %in
                turn_during_in(u) = ft; u=u+1;
            else
                turn_during_out(v) = ft; v=v+1;
            end
            
        elseif odoroff_frame <= ft %after
            turn_after(r) = ft; r=r+1;
            
            if inside_rim(ft,i) ==1 %in
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
    
    % save each fly's data (frame # for turning)
    turn_flies(1,i) = {turn_before};
    turn_flies(2,i) = {turn_during};
    turn_flies(3,i) = {turn_after};
    
    turn_in_flies(1,i) = {turn_before_in};
    turn_in_flies(2,i) = {turn_during_in};
    turn_in_flies(3,i) = {turn_after_in};
    
    turn_out_flies(1,i) = {turn_before_out};
    turn_out_flies(2,i) = {turn_during_out};
    turn_out_flies(3,i) = {turn_after_out};
    
    %how many turns/period?
    NumTurn = zeros(3,1);
    for n=1:3
        if n==1
            AA = turn_before;
        elseif n==2
            AA = turn_during;
        else
            AA = turn_after;
        end
        
        if isnan(AA) == 0
            NumTurn(n) = length(AA);
        end
    end
    
    NumTurn_flies(:,i) = NumTurn;
    
    %calculate turn frequency (turn #/sec)/period
    turn_rate = zeros(3,1);
    
    turn_rate(1) = NumTurn(1)/(timeperiods(2)/framespertimebin); %in sec
    during_time = (odoroff_frame - odoron_frame(i)+1)/framespertimebin;
    turn_rate(2) = NumTurn(2)/during_time;%in sec
    turn_rate(3) = NumTurn(3)/((length(fly_x)-odoroff_frame+1)/framespertimebin);
    
    turn_rate_flies(:,i) = turn_rate;
    
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
    
    NumTurn_in_flies(:,i) = NumTurn_in;
    NumTurn_out_flies(:,i) = NumTurn_out;
    
    %arrays to save turn number in / out per fly
    turn_rate_in = nan(3,1);
    turn_rate_out = nan(3, 1);
    
    for p=1:3
        turn_rate_in(p) = NumTurn_in(p)/(frame_in(p)/framespertimebin);
        turn_rate_out(p) = NumTurn_out(p)/(frame_out(p)/framespertimebin);
    end
    
    turn_rate_in_flies(:,i) = turn_rate_in;
    turn_rate_out_flies(:,i) = turn_rate_out;
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
            
            if inside_rim(ft(n),i) ==1 %in
                curv_before_in(s) = ft(n); s=s+1;
            else
                curv_before_out(t) = ft(n); t=t+1;
            end
            
        elseif odoron_frame(i) <= ft(n) && ft(n) < odoroff_frame %during
            curv_during(q) = ft(n); q=q+1;
            
            if inside_rim(ft(n),i) ==1 %in
                curv_during_in(u) = ft(n); u=u+1;
            else
                curv_during_out(v) = ft(n); v=v+1;
            end
            
        elseif odoroff_frame <= ft(n) %after
            curv_after(r) = ft(n); r=r+1;
            
            if inside_rim(ft(n),i) ==1 %in
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
    
    %save each fly's data
    curv_period_flies{1,i} = curv_before;
    curv_period_flies{2,i} = curv_during;
    curv_period_flies{3,i} = curv_after;
    
    curv_in_flies{1,i} = curv_before_in;
    curv_in_flies{2,i} = curv_during_in;
    curv_in_flies{3,i} = curv_after_in;
    
    curv_out_flies{1,i} = curv_before_out;
    curv_out_flies{2,i} = curv_during_out;
    curv_out_flies{3,i} = curv_after_out;
    
    %get the mean or sum of curvature in each 'curved walk'
    for rep = 1:9
        if rep == 1
            curv_temp = curv_before;
        elseif rep ==2
            curv_temp = curv_during;
        elseif rep ==3
            curv_temp = curv_after;
        elseif rep == 4
            curv_temp = curv_before_in;
        elseif rep == 5
            curv_temp = curv_during_in;
        elseif rep == 6
            curv_temp = curv_after_in;
        elseif rep == 7
            curv_temp = curv_before_out;
        elseif rep == 8;
            curv_temp = curv_during_out;
        elseif rep == 9
            curv_temp = curv_after_out;
        end
        
        %find the first frame of each curvs
        diff_mat = diff(curv_temp); diff_mat = [1;diff_mat];
        start_frame = curv_temp(find(diff_mat ~= 1));%start of new curv
        start_frame = [curv_temp(1); start_frame];
        end_frame = curv_temp(find(diff_mat ~= 1)-1);%end of new curv
        end_frame = [end_frame; curv_temp(end)];
        
        %get the mean of curvatures in individual curves
        if isnan(start_frame) == 0
            clear curv_mean curv_sum
            curv_mean = zeros(length(start_frame),1);
            for x = 1:length(start_frame)
                curv_frag =curvature(start_frame(x):end_frame(x));%curvature data during the one curved walk
                curv_mean(x)= mean(curv_frag);%each curved frame's curvature mean
                curv_sum(x) = sum(curv_frag);
            end
        end
        curv_mean_all(rep) = median(abs(curv_mean));%median of all means
        curv_sum_all(rep) = sum(abs(curv_sum))/length(start_frame);%sum of curv/curved walk
    end
    
    curv_median_period_flies(i,:) = curv_mean_all(1:3);%MEDIAN!!!
    curv_median_in_flies(i,:) =  curv_mean_all(4:6);
    curv_median_out_flies(i,:) = curv_mean_all(7:9);
    
    curv_sum_period_flies(i,:) = curv_sum_all(1:3);
    curv_sum_in_flies(i,:) =  curv_sum_all(4:6);
    curv_sum_out_flies(i,:) = curv_sum_all(7:9);
    
    %==========================================================================
    
    % what fraction of trajectory is classified as 'curved' VS 'straight'
    % only use 'non-stop' or 'run' portion of trajectory
    
    %frames that are classified as 'stops'
    stop_frames = find(velocity_classified == 0);
    stop_before = find(velocity_classified(1:timeperiods(2)) == 0);
    stop_during = find(velocity_classified(odoron_frame(i):odoroff_frame-1) == 0)+ odoron_frame(i)-1;
    stop_after = find(velocity_classified(odoroff_frame:end) == 0) + odoroff_frame-1;
    
    %frames in each period that are classified as 'runs'
    run_frames = find(velocity_classified); %nonzeros in velocity_classified
    run_before = find(velocity_classified(1:timeperiods(2)));
    run_during = find(velocity_classified(odoron_frame(i):odoroff_frame-1))+ odoron_frame(i)-1;
    run_after = find(velocity_classified(odoroff_frame:end)) + odoroff_frame-1;
    
    %run in/out
    fly_inside = find(inside_rim(:,i));
    run_before_in = intersect(run_before,fly_inside);
    run_during_in = intersect(run_during,fly_inside);
    run_after_in = intersect(run_after,fly_inside);
    
    run_before_out = setdiff(run_before,run_before_in);
    run_during_out = setdiff(run_during,run_during_in);
    run_after_out = setdiff(run_after,run_after_in);
    % (stop and run frames # were confirmed by plotting them !)
    
    %how many curving/turning frames per period, in/out (fraction)
    curv_fr = nan(3,1);
    curv_fr(1) = length(curv_before)/length(run_before);
    curv_fr(2) = length(curv_during)/length(run_during);
    curv_fr(3) = length(curv_after)/length(run_after);
    
    curv_fr_in = nan(3,1);
    if isempty(run_before_in) == 0 %to prevent dividing by zero
        curv_fr_in(1) = length(curv_before_in)/length(run_before_in);
    end
    if isempty(run_during_in) == 0
        curv_fr_in(2) = length(curv_during_in)/length(run_during_in);
    end
    if isempty(run_after_in) == 0
        curv_fr_in(3) = length(curv_after_in)/length(run_after_in);
    end
    
    curv_fr_out = nan(3,1);
    curv_fr_out(1) = length(curv_before_out)/length(run_before_out);
    curv_fr_out(2) = length(curv_during_out)/length(run_during_out);
    curv_fr_out(3) = length(curv_after_out)/length(run_after_out);
    
    %save each fly's data (what fraction of walk is labeled as 'curving')
    curv_fr_flies(:,i) = curv_fr;
    
    curv_fr_in_flies(:,i) = curv_fr_in;
    curv_fr_out_flies(:,i) = curv_fr_out;
    
    %==========================================================================
    %==========================================================================
    
    % check what fraction of fly's walk is 'curved' in specific area (ring)
    
    %set the size of the area (a ring between two circles) (in cm)
    %     ring_outer_radius = 1.5;
    %     ring_inner_radius = 1.2;
    
    %this is the original 1.2 cm IR
    in_x_ori = numvals_pi_ori{i}(:,1);
    in_y_ori = numvals_pi_ori{i}(:,2);
    
    
    %change ring_outer_radius and compare turn frq and curved walk fraction
    ring_inner_radius_rings = linspace(1.0,1.6,NumRings);
    ring_outer_radius_rings = linspace(1.1,1.7,NumRings); %to repeat the function
    
    for n = 1:NumRings
        ring_outer_radius = ring_outer_radius_rings(n);
        ring_inner_radius = ring_inner_radius_rings(n);
        
        [fly_in_ring,fly_in_ring_bf,fly_in_ring_dr,fly_in_ring_af,...
            turn_in_ring,turn_in_ring_bf,turn_in_ring_dr,turn_in_ring_af,...
            turn_fr_ring_total,turn_fr_ring,...
            curv_in_ring,curv_in_ring_bf,curv_in_ring_dr,curv_in_ring_af,...
            curv_fr_ring_total,curv_fr_ring,...
            ring_outer_x,ring_outer_y,ring_inner_x,ring_inner_y] =...
            turn_inside_ring(ring_outer_radius,ring_inner_radius,in_x_ori,in_y_ori,inner_radius,fly_x,fly_y,...
            radius_fly_cm,timeperiods,odoron_frame(i),odoroff_frame,velocity_classified,...
            curv_long_mat,frame_turn_sh,framespertimebin);
        
        %save each fly's data : curved walk fraction (out of all the walk (not
        %stop) inside the ring
        curv_fr_ring_flies(i,n) = curv_fr_ring_total;
        curv_fr_ring_period_flies(:,i,n) = curv_fr_ring;
        %3D matrix: rows: period, columns: fly#, 3rd axis: ring#
        
        %frame numbers that were marked as 'curving'
        curv_in_ring_flies{i,n} =curv_in_ring;
        curv_in_ring_period_flies{1,i,n} = curv_in_ring_bf;
        curv_in_ring_period_flies{2,i,n} = curv_in_ring_dr;
        curv_in_ring_period_flies{3,i,n} = curv_in_ring_af;
        
        % turn frequency (turn #/sec)
        turn_fr_ring_flies(i,n) = turn_fr_ring_total;
        turn_fr_ring_period_flies(:,i,n) = turn_fr_ring;
        
        %frame numbers that were marked as 'sharp turns'
        turn_in_ring_flies{i,n} = turn_in_ring;
        turn_in_ring_period_flies{1,i,n} = turn_in_ring_bf;
        turn_in_ring_period_flies{2,i,n} = turn_in_ring_dr;
        turn_in_ring_period_flies{3,i,n} = turn_in_ring_af;
        
        %frame # when the fly is inside the ring
        fly_in_ring_flies{i,n} = fly_in_ring; %this variable contains the frame# and radius_fly_cm
        fly_in_ring_period_flies{1,i,n} = fly_in_ring_bf;
        fly_in_ring_period_flies{2,i,n} = fly_in_ring_dr;
        fly_in_ring_period_flies{3,i,n} = fly_in_ring_af;
        
        %xy coordinates of ring inner/outer for each fly
        ring_outer = horzcat(ring_outer_x,ring_outer_y);
        %         ring_outer_flies(:,2*i-1:2*i,n) = ring_outer;
        ring_inner = horzcat(ring_inner_x,ring_inner_y);
        %         ring_inner_flies(:,2*i-1:2*i,n) = ring_inner;
    end
    %=========================================================================
    
    %now get the curvature information at crossings
    [curvature_io_before_smoothed,curvature_io_during_smoothed,curvature_io_after_smoothed,...
        curvature_oi_before_smoothed,curvature_oi_during_smoothed,curvature_oi_after_smoothed]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        curvature,framespertimebin, timeperiods, timebefore, timetotal);
    
    %save each fly's curvature data in cell arrays
    curv_i2o_cell(1,i) = {curvature_io_before_smoothed};
    curv_i2o_cell(2,i) = {curvature_io_during_smoothed};
    curv_i2o_cell(3,i) = {curvature_io_after_smoothed};
    
    curv_o2i_cell(1,i) = {curvature_oi_before_smoothed};
    curv_o2i_cell(2,i) = {curvature_oi_during_smoothed};
    curv_o2i_cell(3,i) = {curvature_oi_after_smoothed};
    
    
    %save each fly's curvature (absolute values)
    curv_abs_i2o_cell(1,i) = {abs(curvature_io_before_smoothed)};
    curv_abs_i2o_cell(2,i) = {abs(curvature_io_during_smoothed)};
    curv_abs_i2o_cell(3,i) = {abs(curvature_io_after_smoothed)};
    
    curv_abs_o2i_cell(1,i) = {abs(curvature_oi_before_smoothed)};
    curv_abs_o2i_cell(2,i) = {abs(curvature_oi_during_smoothed)};
    curv_abs_o2i_cell(3,i) = {abs(curvature_oi_after_smoothed)};
    
    %% absolute angle between two vectors
    % copied from the old analysis V13 + modified in V20
    %calculate the angle between two vectors (three points each) and also
    %difference between angles(absolute value only)
    angle_abs = zeros(length(fly_x),1);
    
    angle2 = zeros(length(fly_x),1);
    
    diff_angle = zeros(length(fly_x)-1,1);
    
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
            display('if');
        else
            angle1(n) = acos(dot(v1,v2)/(norm(v1)*norm(v2)));
            %angle(rad) between two vectors
            %to prevent getting imaginary numbers, replace it with 0
            if isreal(angle1(n)) == 0
                angle1(n) = 0;
            end
        end
    end
    angle1 = [angle1;0];
    
    
    % this is the angle deviated from projected straight line of fly's tragectory
    %if fly is making a counter-clockwise turn, mark the angle as -
    %if fly is walking toward north,
    angle2 = angle1;
    for n=1:length(fly_x)-1
        if fly_y(n+1)- fly_y(n) > 0
            if fly_x(n+1) - fly_x(n) < 0
                angle2(n) = -angle2(n);
            end
        else %if fly is walking toward south,
            if fly_x(n+1) - fly_x(n) > 0
                angle2(n) = -angle2(n);
            end
        end
    end
    
    angle2_copy = angle2;
    %absolute value
    abs_angle2 = abs(angle2_copy);
    abs_angle2(1,1)= 0;%put zero in the first frame to avoid error in plotting
    %first get diff of angle, this will have + and - values, so get the
    %absolute values
    temp_diff_angle = diff(angle2);
    diff_angle =abs(temp_diff_angle);
    
    
    %==========================================================================
    
    % radial velocity (original value + or -)
    [radvel_in2out_before_ov,radvel_in2out_during_ov,radvel_in2out_after_ov,...
        radvel_out2in_before_ov,radvel_out2in_during_ov,radvel_out2in_after_ov]...
        = velocityatcrossing_basic(filename_behavior,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        rad_vel,framespertimebin, timeperiods, timebefore, timetotal);
    
    %save each fly's radial velocity data in a cell
    radvel_i2o_before_ov_cell(i) = {radvel_in2out_before_ov};
    radvel_i2o_during_ov_cell(i) = {radvel_in2out_during_ov};
    radvel_i2o_after_ov_cell(i) = {radvel_in2out_after_ov};
    
    radvel_o2i_before_ov_cell(i) = {radvel_out2in_before_ov};
    radvel_o2i_during_ov_cell(i) = {radvel_out2in_during_ov};
    radvel_o2i_after_ov_cell(i) = {radvel_out2in_after_ov};
    
    
    %==========================================================================
    
    %divide velocity data into two groups : short time in/transit vs long time in/transit
    %this assumes that the real crossing data is saved after 'timebefore' seconds in
    %arrays. Output 'avg_...' is MEDIAN VALUE!
    
    %set the time limit/threshold to use to separate short and long crossings
    how_short = 1*framespertimebin; %in frames
    
    [vel_o2i_before_short,vel_o2i_during_short,vel_o2i_after_short,...
        vel_o2i_before_long,vel_o2i_during_long,vel_o2i_after_long,...
        vel_i2o_before_short,vel_i2o_during_short,vel_i2o_after_short,...
        vel_i2o_before_long,vel_i2o_during_long,vel_i2o_after_long,...
        avg_vel_o2i_short,avg_vel_o2i_long,avg_vel_i2o_short,avg_vel_i2o_long]...
        = short_long_crossings(how_short,velocity_in2out_before,velocity_in2out_during,...
        velocity_in2out_after,velocity_out2in_before,velocity_out2in_during,velocity_out2in_after,...
        framespertimebin,timebefore,timetotal);
    
    %save each fly's data (this will contain at least one element per fly even
    %though there is no short/long crossing, and that element is composed of nans)
    %Out2in, short crossings
    vel_o2i_bf_sh_flies(i) = {vel_o2i_before_short};
    vel_o2i_dr_sh_flies(i) = {vel_o2i_during_short};
    vel_o2i_af_sh_flies(i) = {vel_o2i_after_short};
    
    %Out2in, long crossings
    vel_o2i_bf_lg_flies(i) = {vel_o2i_before_long};
    vel_o2i_dr_lg_flies(i) = {vel_o2i_during_long};
    vel_o2i_af_lg_flies(i) = {vel_o2i_after_long};
    
    %In2out, short crossings
    vel_i2o_bf_sh_flies(i) = {vel_i2o_before_short};
    vel_i2o_dr_sh_flies(i) = {vel_i2o_during_short};
    vel_i2o_af_sh_flies(i) = {vel_i2o_after_short};
    
    %In2out, long crossings
    vel_i2o_bf_lg_flies(i) = {vel_i2o_before_long};
    vel_i2o_dr_lg_flies(i) = {vel_i2o_during_long};
    vel_i2o_af_lg_flies(i) = {vel_i2o_after_long};
    
    %==========================================================================
    
    % get fly's location changes at crossing points
    
    [location_io_before,location_io_during,location_io_after,...
        location_oi_before,location_oi_during,location_oi_after]...
        = velocityatcrossing_basic(fig_title,crossing_in_before,crossing_in_during,...
        crossing_in_after, crossing_out_before,crossing_out_during,crossing_out_after,...
        location_fly(:,i),framespertimebin, timeperiods, timebefore, timetotal);
    
    %save each fly's location data at crossing points
    location_i2o_cell(1,i) = {location_io_before};
    location_i2o_cell(2,i) = {location_io_during};
    location_i2o_cell(3,i) = {location_io_after};
    
    location_o2i_cell(1,i) = {location_oi_before};
    location_o2i_cell(2,i) = {location_oi_during};
    location_o2i_cell(3,i) = {location_oi_after};
    
end
%=end of 'for loop' for each fly ============================================
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


%==========================================================================
% calculate average of velocity at crossing
%first convert everything to matrix (not used any longer in V15)
velocity_i2o_before_flies = cell2mat(velocity_i2o_before_cell);
velocity_i2o_during_flies = cell2mat(velocity_i2o_during_cell);
velocity_i2o_after_flies = cell2mat(velocity_i2o_after_cell);

velocity_o2i_before_flies = cell2mat(velocity_o2i_before_cell);
velocity_o2i_during_flies = cell2mat(velocity_o2i_during_cell);
velocity_o2i_after_flies = cell2mat(velocity_o2i_after_cell);

% 'mean_calculator' outputs mean velocity of individual flies,std and SEM.
% velocity_i2o_avg etc includes all the flies
% velocity_i2o_avg_sel only includes flies that had crossings more than the
% crossing_min set
[velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,velocity_i2o_ind_avg_af,...
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
    velocity_o2i_before_cell,velocity_o2i_during_cell,velocity_o2i_after_cell);

%==========================================================================

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
[vel_i2o_bin_mean,vel_o2i_bin_mean,vel_i2o_bin_SEM,vel_o2i_bin_SEM,...
    vel_i2o_by_bin_h,vel_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,...
    velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr);


%selected fly group
[vel_i2o_bin_mean_sel,vel_o2i_bin_mean_sel,vel_i2o_bin_SEM_sel,vel_o2i_bin_SEM_sel,...
    vel_i2o_by_bin_h_sel,vel_o2i_by_bin_h_sel]...
    = bin_ttest(numBins,whichBin,...
    velocity_i2o_avg_bf_sel,velocity_i2o_avg_dr_sel,...
    velocity_o2i_avg_bf_sel,velocity_o2i_avg_dr_sel);


%========================================================================
% bin# or radius/location at crossing VS velocity changes
total_bin_count = max(max(location_fly));

% first, pool all the velocity at crossing
velocity_i2o_cell = {velocity_i2o_before_cell;velocity_i2o_during_cell;velocity_i2o_after_cell};
velocity_o2i_cell = {velocity_o2i_before_cell;velocity_o2i_during_cell;velocity_o2i_after_cell};

location_i2o_vel_crossing = cell(3,numflies);%this will save velocity at the given bin#(locationID)/fly/period
location_o2i_vel_crossing = cell(3,numflies);

%for i2o
for period = 1:3
    for fly = 1:numflies
        AA = location_i2o_cell{period,fly};%get the given fly's location at crossing in a given period
        n=1;temp_vel = nan((how_long*size(AA,2)),total_bin_count);%pre-allocate a temp array big enough
        for i=1:size(AA,2) % for each crossing
            for p = 1:how_long %for 150 frames or whatever is set earlier
                locationID = AA(p,i); %which bin was the fly in at that frame?
                if isnan(locationID) == 0 %skip this if there is no location data
                    temp_vel(n,locationID) = velocity_i2o_cell{period}{fly}(p,i);%get the velocity info and save under corresponding bin# (locationID)
                    n=n+1;
                end
            end
        end
        %get mean of velocity in each bin# (locationID)/fly
        location_i2o_vel_crossing(period,fly) = {nanmean(temp_vel)};
        
        clear temp_vel
        
    end
end

%o2i
for period = 1:3
    for fly = 1:numflies
        AA = location_o2i_cell{period,fly};%get the given fly's location at crossing in a given period
        n=1;temp_vel = nan((how_long*size(AA,2)),total_bin_count);%pre-allocate a temp array big enough
        for i=1:size(AA,2) % for each crossing
            for p = 1:how_long %for 150 frames or whatever is set earlier
                locationID = AA(p,i); %which bin was the fly in at that frame?
                if isnan(locationID) == 0 %skip this if there is no location data
                    temp_vel(n,locationID) = velocity_o2i_cell{period}{fly}(p,i);%get the velocity info and save under corresponding bin# (locationID)
                    n=n+1;
                end
            end
        end
        %get mean of velocity in each bin# (locationID)/fly
        location_o2i_vel_crossing(period,fly) = {nanmean(temp_vel)};
        
        clear temp_vel
        
    end
end


%get the mean velocity /locationID for whole group========================
vel_location_i2o_mean = nan(total_bin_count,3);
vel_location_o2i_mean = nan(total_bin_count,3);

vel_location_i2o_std = nan(total_bin_count,3);
vel_location_o2i_std = nan(total_bin_count,3);

for period=1:3
    %i2o
    temp_cell=location_i2o_vel_crossing(period,:);
    temp_array = cell2mat(temp_cell);
    temp_array1 = reshape(temp_array,total_bin_count,numflies);
    %save each fly's averaged velocity/location as double arrays
    if period ==1 %before
        vel_location_i2o_mean_bf = temp_array1;
    elseif period ==2 %during
        vel_location_i2o_mean_dr = temp_array1;
    else %after
        vel_location_i2o_mean_af = temp_array1;
    end
    
    vel_location_i2o_mean(:,period) = nanmean(temp_array1,2);
    vel_location_i2o_std(:,period) = nanstd(temp_array1,0,2);
    
    %o2i
    temp_cell=location_o2i_vel_crossing(period,:);
    temp_array = cell2mat(temp_cell);
    temp_array1 = reshape(temp_array,total_bin_count,numflies);
    %save each fly's averaged velocity/location as double arrays
    if period ==1 %before
        vel_location_o2i_mean_bf = temp_array1;
    elseif period ==2 %during
        vel_location_o2i_mean_dr = temp_array1;
    else %after
        vel_location_o2i_mean_af = temp_array1;
    end
    
    vel_location_o2i_mean(:,period) = nanmean(temp_array1,2);
    vel_location_o2i_std(:,period) = nanstd(temp_array1,0,2);
end

vel_location_i2o_SEM = vel_location_i2o_std./sqrt(numflies);
vel_location_o2i_SEM = vel_location_o2i_std./sqrt(numflies);

%get the mean velocity /locationID for selected flies (>crossing min)=====

vel_location_i2o_mean_sel = nan(total_bin_count,3);
vel_location_o2i_mean_sel = nan(total_bin_count,3);
vel_location_i2o_std_sel = nan(total_bin_count,3);
vel_location_o2i_std_sel = nan(total_bin_count,3);

for period=1:3
    %i2o
    temp_cell=location_i2o_vel_crossing(period,flies_used);
    temp_array = cell2mat(temp_cell);
    temp_array1 = reshape(temp_array,total_bin_count,num_used_flies);
    vel_location_i2o_mean_sel(:,period) = nanmean(temp_array1,2);
    vel_location_i2o_std_sel(:,period) = nanstd(temp_array1,0,2);
    
    %o2i
    temp_cell=location_o2i_vel_crossing(period,flies_used);
    temp_array = cell2mat(temp_cell);
    temp_array1 = reshape(temp_array,total_bin_count,num_used_flies);
    vel_location_o2i_mean_sel(:,period) = nanmean(temp_array1,2);
    vel_location_o2i_std_sel(:,period) = nanstd(temp_array1,0,2);
    
end

vel_location_i2o_SEM_sel = vel_location_i2o_std_sel./sqrt(num_used_flies);
vel_location_o2i_SEM_sel = vel_location_o2i_std_sel./sqrt(num_used_flies);


%========================================================================

% velocity at crossing that excludes short crossings around the inner rim

%set the threshold so that crossings that did not go outside this threshold
%will be discarded
crossing_threshold = 1.5; %a boundary that is x mm bigger than real IR (1.2 cm)

%for Out2In crossings
%before

[vel_o2i_th_bf_flies]...
    = crossing_beyond_threshold(numflies,circRad_flies,crossing_threshold,...
    inner_radius,radius_flies,how_long,...
    crossing_o2i_bf_frames_flies,velocity_o2i_before_flies);

%during
[vel_o2i_th_dr_flies]...
    = crossing_beyond_threshold(numflies,circRad_flies,crossing_threshold,...
    inner_radius,radius_flies,how_long,...
    crossing_o2i_dr_frames_flies,velocity_o2i_during_flies);

%after
[vel_o2i_th_af_flies]...
    = crossing_beyond_threshold(numflies,circRad_flies,crossing_threshold,...
    inner_radius,radius_flies,how_long,...
    crossing_o2i_af_frames_flies,velocity_o2i_after_flies);


%for In2Out crossings
%before
[vel_i2o_th_bf_flies]...
    = crossing_beyond_threshold(numflies,circRad_flies,crossing_threshold,...
    inner_radius,radius_flies,how_long,...
    crossing_i2o_bf_frames_flies,velocity_i2o_before_flies);

%during
[vel_i2o_th_dr_flies]...
    = crossing_beyond_threshold(numflies,circRad_flies,crossing_threshold,...
    inner_radius,radius_flies,how_long,...
    crossing_i2o_dr_frames_flies,velocity_i2o_during_flies);

%after
[vel_i2o_th_af_flies]...
    = crossing_beyond_threshold(numflies,circRad_flies,crossing_threshold,...
    inner_radius,radius_flies,how_long,...
    crossing_i2o_af_frames_flies,velocity_i2o_after_flies);

%calculate means at each frame excluding nans (mean of individual fly
%means)

%first find out how many crossings above the threshold occurred
crossing_numbers_th = nan(numflies,3);
for i=1:numflies
    crossing_numbers_th(i,1) =  size(vel_o2i_th_bf_flies{i},2);
    crossing_numbers_th(i,2) =  size(vel_o2i_th_dr_flies{i},2);
    crossing_numbers_th(i,3) =  size(vel_o2i_th_af_flies{i},2);
end

% 'mean_calculator' outputs mean velocity of individual flies,std and SEM.
% velocity_i2o_avg etc includes all the flies
% velocity_i2o_avg_sel only includes flies that had crossings more than the
% crossing_min set
[velocity_i2o_th_ind_avg_bf,velocity_i2o_th_ind_avg_dr,velocity_i2o_th_ind_avg_af,...
    velocity_o2i_th_ind_avg_bf,velocity_o2i_th_ind_avg_dr,velocity_o2i_th_ind_avg_af,...
    vel_i2o_th_avg,vel_i2o_th_std,vel_i2o_th_SEM,...
    vel_o2i_th_avg,vel_o2i_th_std,vel_o2i_th_SEM,...
    velocity_i2o_th_ind_avg_bf_sel,velocity_i2o_th_ind_avg_dr_sel,velocity_i2o_th_ind_avg_af_sel,...
    velocity_o2i_th_ind_avg_bf_sel,velocity_o2i_th_ind_avg_dr_sel,velocity_o2i_th_ind_avg_af_sel,...
    vel_i2o_th_avg_sel,vel_i2o_th_std_sel,vel_i2o_th_SEM_sel,...
    vel_o2i_th_avg_sel,vel_o2i_th_std_sel,vel_o2i_th_SEM_sel,...
    flies_used_th,num_flies_th]...
    = mean_calculator(how_long,numflies,crossing_numbers_th,crossing_min,...
    vel_i2o_th_bf_flies,vel_i2o_th_dr_flies,vel_i2o_th_af_flies,...
    vel_o2i_th_bf_flies,vel_o2i_th_dr_flies,vel_o2i_th_af_flies);


%'bin_ttest'; bins data according to the pre-set binEdges,etc and performs
% paired student's t-test to compare 'before' and 'during' data, and
% outputs the binned data means and t-test results (h=1: significant
% difference, p<0.05)

%whole fly group
[vel_th_i2o_bin_mean,vel_th_o2i_bin_mean,vel_th_i2o_bin_SEM,vel_th_o2i_bin_SEM,...
    vel_th_i2o_by_bin_h,vel_th_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    velocity_i2o_th_ind_avg_bf,velocity_i2o_th_ind_avg_dr,...
    velocity_o2i_th_ind_avg_bf,velocity_o2i_th_ind_avg_dr);


%selected fly group
[vel_th_i2o_bin_mean_sel,vel_th_o2i_bin_mean_sel,vel_th_i2o_bin_SEM_sel,vel_th_o2i_bin_SEM_sel,...
    vel_th_i2o_by_bin_h_sel,vel_th_o2i_by_bin_h_sel]...
    = bin_ttest(numBins,whichBin,...
    velocity_i2o_avg_bf_sel,velocity_i2o_avg_dr_sel,...
    velocity_o2i_avg_bf_sel,velocity_o2i_avg_dr_sel);


%========================================================================

% calculate average of radial velocity at crossing

%first convert everything to matrix
% in V15: not necessary
radvel_i2o_before_flies = cell2mat(radvel_i2o_before_cell);
radvel_i2o_during_flies = cell2mat(radvel_i2o_during_cell);
radvel_i2o_after_flies = cell2mat(radvel_i2o_after_cell);

radvel_o2i_before_flies = cell2mat(radvel_o2i_before_cell);
radvel_o2i_during_flies = cell2mat(radvel_o2i_during_cell);
radvel_o2i_after_flies = cell2mat(radvel_o2i_after_cell);


%This function outputs mean velocity of individual flies,std and SEM.
% velocity_i2o_avg etc includes all the flies
% velocity_i2o_avg_sel only includes flies that had crossings more than the
% crossing_min set

[radvel_i2o_ind_avg_bf,radvel_i2o_ind_avg_dr,radvel_i2o_ind_avg_af,...
    radvel_o2i_ind_avg_bf,radvel_o2i_ind_avg_dr,radvel_o2i_ind_avg_af,...
    radvel_i2o_avg,radvel_i2o_std,radvel_i2o_SEM,...
    radvel_o2i_avg,radvel_o2i_std,radvel_o2i_SEM,...
    radvel_i2o_avg_bf_sel,radvel_i2o_avg_dr_sel,radvel_i2o_avg_af_sel,...
    radvel_o2i_avg_bf_sel,radvel_o2i_avg_dr_sel,radvel_o2i_avg_af_sel,...
    radvel_i2o_avg_sel,radvel_i2o_std_sel,radvel_i2o_SEM_sel,...
    radvel_o2i_avg_sel,radvel_o2i_std_sel,radvel_o2i_SEM_sel]...
    = mean_calculator(how_long,numflies,crossing_number_flies,crossing_min,...
    radvel_i2o_before_cell,radvel_i2o_during_cell,radvel_i2o_after_cell,...
    radvel_o2i_before_cell,radvel_o2i_during_cell,radvel_o2i_after_cell);

%'bin_ttest'; bins data according to the pre-set binEdges,etc and performs
% paired student's t-test to compare 'before' and 'during' data, and
% outputs the binned data means and t-test results (h=1: significant
% difference, p<0.05)

%whole fly group
[radvel_i2o_bin_mean,radvel_o2i_bin_mean,radvel_i2o_bin_SEM,radvel_o2i_bin_SEM,...
    radvel_i2o_by_bin_h,radvel_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    radvel_i2o_ind_avg_bf,radvel_i2o_ind_avg_dr,...
    radvel_o2i_ind_avg_bf,radvel_o2i_ind_avg_dr);


%selected fly group
[radvel_i2o_bin_mean_sel,radvel_o2i_bin_mean_sel,radvel_i2o_bin_SEM_sel,radvel_o2i_bin_SEM_sel,...
    radvel_i2o_by_bin_h_sel,radvel_o2i_by_bin_h_sel]...
    = bin_ttest(numBins,whichBin,...
    radvel_i2o_avg_bf_sel,radvel_i2o_avg_dr_sel,...
    radvel_o2i_avg_bf_sel,radvel_o2i_avg_dr_sel);


%========================================================================

%Velocity at crossing: divided into short and long crossings, getting
%average across flies

%------Refer to V14 to get the mean of the all crossing events--------

%==========================================================================
%==The following: means from ind. flies, then the mean of means ===========

%pre-allocate
vel_o2i_sh_mean_bf = nan(how_long, numflies);
vel_o2i_sh_mean_dr = nan(how_long, numflies);
vel_o2i_sh_mean_dr = nan(how_long, numflies);
vel_o2i_lg_mean_bf = nan(how_long, numflies);
vel_o2i_lg_mean_dr = nan(how_long, numflies);
vel_o2i_lg_mean_af = nan(how_long, numflies);

vel_i2o_sh_mean_bf = nan(how_long, numflies);
vel_i2o_sh_mean_dr = nan(how_long, numflies);
vel_i2o_sh_mean_af = nan(how_long, numflies);
vel_i2o_lg_mean_bf = nan(how_long, numflies);
vel_i2o_lg_mean_dr = nan(how_long, numflies);
vel_i2o_lg_mean_af = nan(how_long, numflies);

%first, get the individual fly's means (all flies)=========================
for fly = 1:numflies
    
    vel_o2i_sh_mean_bf(:,fly) = nanmean(vel_o2i_bf_sh_flies{fly},2);
    vel_o2i_sh_mean_dr(:,fly) = nanmean(vel_o2i_dr_sh_flies{fly},2);
    vel_o2i_sh_mean_af(:,fly) = nanmean(vel_o2i_af_sh_flies{fly},2);
    vel_o2i_lg_mean_bf(:,fly) = nanmean(vel_o2i_bf_lg_flies{fly},2);
    vel_o2i_lg_mean_dr(:,fly) = nanmean(vel_o2i_dr_lg_flies{fly},2);
    vel_o2i_lg_mean_af(:,fly) = nanmean(vel_o2i_af_lg_flies{fly},2);
    
    vel_i2o_sh_mean_bf(:,fly) = nanmean(vel_i2o_bf_sh_flies{fly},2);
    vel_i2o_sh_mean_dr(:,fly) = nanmean(vel_i2o_dr_sh_flies{fly},2);
    vel_i2o_sh_mean_af(:,fly) = nanmean(vel_i2o_af_sh_flies{fly},2);
    vel_i2o_lg_mean_bf(:,fly) = nanmean(vel_i2o_bf_lg_flies{fly},2);
    vel_i2o_lg_mean_dr(:,fly) = nanmean(vel_i2o_dr_lg_flies{fly},2);
    vel_i2o_lg_mean_af(:,fly) = nanmean(vel_i2o_af_lg_flies{fly},2);
    
end


%Then, get the mean of the means
vel_sh_o2i_avg(:,1) = nanmean(vel_o2i_sh_mean_bf,2);
vel_sh_o2i_avg(:,2) = nanmean(vel_o2i_sh_mean_dr,2);
vel_sh_o2i_avg(:,3) = nanmean(vel_o2i_sh_mean_af,2);

vel_lg_o2i_avg(:,1) = nanmean(vel_o2i_lg_mean_bf,2);
vel_lg_o2i_avg(:,2) = nanmean(vel_o2i_lg_mean_dr,2);
vel_lg_o2i_avg(:,3) = nanmean(vel_o2i_lg_mean_af,2);

vel_sh_i2o_avg(:,1) = nanmean(vel_i2o_sh_mean_bf,2);
vel_sh_i2o_avg(:,2) = nanmean(vel_i2o_sh_mean_dr,2);
vel_sh_i2o_avg(:,3) = nanmean(vel_i2o_sh_mean_af,2);

vel_lg_i2o_avg(:,1) = nanmean(vel_i2o_lg_mean_bf,2);
vel_lg_i2o_avg(:,2) = nanmean(vel_i2o_lg_mean_dr,2);
vel_lg_i2o_avg(:,3) = nanmean(vel_i2o_lg_mean_af,2);

%std
vel_sh_o2i_std(:,1) = nanstd(vel_o2i_sh_mean_bf,0,2);
vel_sh_o2i_std(:,2) = nanstd(vel_o2i_sh_mean_dr,0,2);
vel_sh_o2i_std(:,3) = nanstd(vel_o2i_sh_mean_af,0,2);

vel_lg_o2i_std(:,1) = nanstd(vel_o2i_lg_mean_bf,0,2);
vel_lg_o2i_std(:,2) = nanstd(vel_o2i_lg_mean_dr,0,2);
vel_lg_o2i_std(:,3) = nanstd(vel_o2i_lg_mean_af,0,2);

vel_sh_i2o_std(:,1) = nanstd(vel_i2o_sh_mean_bf,0,2);
vel_sh_i2o_std(:,2) = nanstd(vel_i2o_sh_mean_dr,0,2);
vel_sh_i2o_std(:,3) = nanstd(vel_i2o_sh_mean_af,0,2);

vel_lg_i2o_std(:,1) = nanstd(vel_i2o_lg_mean_bf,0,2);
vel_lg_i2o_std(:,2) = nanstd(vel_i2o_lg_mean_dr,0,2);
vel_lg_i2o_std(:,3) = nanstd(vel_i2o_lg_mean_af,0,2);

%SEM
%need to count how many flies /each array
%O2I
%short
A = vel_o2i_sh_mean_bf;
sh_bf_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_sh_o2i_SEM(:,1) = vel_sh_o2i_std(:,1)/sqrt(length(sh_bf_flies));

A = vel_o2i_sh_mean_dr;
sh_dr_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_sh_o2i_SEM(:,2) = vel_sh_o2i_std(:,2)/sqrt(length(sh_dr_flies));

A = vel_o2i_sh_mean_af;
sh_af_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_sh_o2i_SEM(:,3) = vel_sh_o2i_std(:,3)/sqrt(length(sh_af_flies));

%O2I, long
A = vel_o2i_lg_mean_bf;
lg_bf_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_lg_o2i_SEM(:,1) = vel_lg_o2i_std(:,1)/sqrt(length(lg_bf_flies));

A = vel_o2i_lg_mean_dr;
lg_dr_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_lg_o2i_SEM(:,2) = vel_lg_o2i_std(:,2)/sqrt(length(lg_dr_flies));

A = vel_o2i_lg_mean_af;
lg_af_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_lg_o2i_SEM(:,3) = vel_lg_o2i_std(:,3)/sqrt(length(lg_af_flies));

%I2O, short
A = vel_i2o_sh_mean_bf;
sh_bf_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_sh_i2o_SEM(:,1) = vel_sh_i2o_std(:,1)/sqrt(length(sh_bf_flies));

A = vel_i2o_sh_mean_dr;
sh_dr_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_sh_i2o_SEM(:,2) = vel_sh_i2o_std(:,2)/sqrt(length(sh_dr_flies));

A = vel_i2o_sh_mean_af;
sh_af_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_sh_i2o_SEM(:,3) = vel_sh_i2o_std(:,3)/sqrt(length(sh_af_flies));

A = vel_i2o_lg_mean_bf;
lg_bf_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_lg_i2o_SEM(:,1) = vel_lg_i2o_std(:,1)/sqrt(length(lg_bf_flies));

A = vel_i2o_lg_mean_dr;
lg_dr_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_lg_i2o_SEM(:,2) = vel_lg_i2o_std(:,2)/sqrt(length(lg_dr_flies));

A = vel_i2o_lg_mean_af;
lg_af_flies= find(sum(~isnan(A))); %if a column contains nans only, sum =0
vel_lg_i2o_SEM(:,3) = vel_lg_i2o_std(:,3)/sqrt(length(lg_af_flies));

%========================================================================

avg_vel_in_flies = nanmean(total_avg_vel_in_flies);
avg_vel_out_flies = nanmean(total_avg_vel_out_flies);

bin_probability_avg = nan(3,max(radius_n));
bin_probability_before = nan(numflies,max(radius_n));
bin_probability_during = nan(numflies,max(radius_n));
bin_probability_during = nan(numflies,max(radius_n));

for i=1:numflies
    bin_probability_before(i,1:length(bin_probability_flies{i})) = bin_probability_flies{i}(1,:);
    bin_probability_during(i,1:length(bin_probability_flies{i})) = bin_probability_flies{i}(2,:);
    bin_probability_after(i,1:length(bin_probability_flies{i})) = bin_probability_flies{i}(3,:);
end

bin_prob_avg(1,:) = nanmean(bin_probability_before);
bin_prob_avg(2,:) = nanmean(bin_probability_during);
bin_prob_avg(3,:) = nanmean(bin_probability_after);

%========================================================================

%calculate means of velocity or radial velocity (binned)
total_bin_count = max(max(radius_binned_flies));

%make empty arrays first
vel_bin_before = nan(numflies,total_bin_count);
vel_bin_during = nan(numflies,total_bin_count);
vel_bin_after = nan(numflies,total_bin_count);

radvel_bin_before = nan(numflies,total_bin_count);
radvel_bin_during = nan(numflies,total_bin_count);
radvel_bin_after = nan(numflies,total_bin_count);

avg_vel_by_radius_all = nan(3,total_bin_count);
avg_radvel_by_radius_all = nan(3, total_bin_count);

%first creat arrays that include average of each fly in each bin
for i=1:numflies
    vel_bin_before(i,1:length(avg_vel_by_radius_flies{1,i})) = avg_vel_by_radius_flies{1,i};
    vel_bin_during(i,1:length(avg_vel_by_radius_flies{1,i})) = avg_vel_by_radius_flies{2,i};
    vel_bin_after(i,1:length(avg_vel_by_radius_flies{1,i})) = avg_vel_by_radius_flies{3,i};
    
    radvel_bin_before(i,1:length(avg_vel_by_radius_flies{1,i})) = avg_radvel_by_radius_flies{1,i};
    radvel_bin_during(i,1:length(avg_vel_by_radius_flies{1,i})) = avg_radvel_by_radius_flies{2,i};
    radvel_bin_after(i,1:length(avg_vel_by_radius_flies{1,i})) = avg_radvel_by_radius_flies{3,i};
    
end

avg_vel_by_radius_all(1,:) = nanmean(vel_bin_before);
avg_vel_by_radius_all(2,:) = nanmean(vel_bin_during);
avg_vel_by_radius_all(3,:) = nanmean(vel_bin_after);

avg_radvel_by_radius_all(1,:) = nanmean(radvel_bin_before);
avg_radvel_by_radius_all(2,:) = nanmean(radvel_bin_during);
avg_radvel_by_radius_all(3,:) = nanmean(radvel_bin_after);

%========================================================================

%To see the distribution of rad_vel around the rim,
%group all the rad_vel_flies data per each radius bin

for n= 1: numflies
    for i=1:total_bin_count
        %before
        temp1 = find(radius_binned_flies(1:timeperiods(2),n) == i);%find frame numbers for each radius bin
        rad_vel_temp = rad_vel_flies(temp1,n);%then find rad_vel for those frames and store data
        radvel_binned_before_flies{n,i} = rad_vel_temp;
        
        %during
        temp1 = find(radius_binned_flies(odoron_frame(n):odoroff_frame,n) == i);%find frame numbers for each radius bin
        rad_vel_temp = rad_vel_flies(temp1,n);%then find rad_vel for those frames and store data
        radvel_binned_during_flies{n,i} = rad_vel_temp;
        
        %after
        temp1 = find(radius_binned_flies(odoroff_frame:end,n) == i);%find frame numbers for each radius bin
        rad_vel_temp = rad_vel_flies(temp1,n);%then find rad_vel for those frames and store data
        radvel_binned_after_flies{n,i} = rad_vel_temp;
    end
    
end


%get rid of empty cells and put them in one array that includes all 3
%periods
for i=1:total_bin_count
    temp = radvel_binned_before_flies(:,i);
    radvel_binned_all{1,i} = temp(~cellfun('isempty',temp));
    
    temp = radvel_binned_during_flies(:,i);
    radvel_binned_all{2,i} = temp(~cellfun('isempty',temp));
    
    temp = radvel_binned_after_flies(:,i);
    radvel_binned_all{3,i} = temp(~cellfun('isempty',temp));
    
end

%find out how many elements are in each bin
for i=1:total_bin_count
    temp1 = cell2mat(radvel_binned_all{1,i});
    length_before(i)=length(temp1);
    
    temp1 = cell2mat(radvel_binned_all{2,i});
    length_during(i)=length(temp1);
    
    temp1 = cell2mat(radvel_binned_all{3,i});
    length_after(i)=length(temp1);
end

%create arrays that can contain the longest array
radvel_binned_before = nan(max(length_before),total_bin_count);
radvel_binned_during = nan(max(length_during),total_bin_count);
radvel_binned_after = nan(max(length_after),total_bin_count);

%now convert cell to mat
for i=1:total_bin_count
    temp1 = cell2mat(radvel_binned_all{1,i});
    radvel_binned_before(1:length(temp1),i)=temp1;
    
    temp1 = cell2mat(radvel_binned_all{2,i});
    length_during(i)=length(temp1);
    radvel_binned_during(1:length(temp1),i)=temp1;
    
    temp1 = cell2mat(radvel_binned_all{3,i});
    length_after(i)=length(temp1);
    radvel_binned_after(1:length(temp1),i)=temp1;
end
%========================================================================

%now bin the radvel data points

%how many bins?
bin_number_y = 20;
%width of each bin
y_bin = linspace(-1,1,bin_number_y);

%before
[bincounts,binindx] = histc(radvel_binned_before,y_bin);%bin radvel data and save the results
radvel_binindx_before=binindx;%binindx tells you where the individual points were binned to
radvel_bincount_before= bincounts;%bincounts shows how many data points are in each bin

%during
[bincounts,binindx] = histc(radvel_binned_during,y_bin);%bin radvel data and save the results
radvel_binindx_during=binindx;%binindx tells you where the individual points were binned to
radvel_bincount_during= bincounts;%bincounts shows how many data points are in each bin

%after
[bincounts,binindx] = histc(radvel_binned_after,y_bin);%bin radvel data and save the results
radvel_binindx_after=binindx;%binindx tells you where the individual points were binned to
radvel_bincount_after= bincounts;%bincounts shows how many data points are in each bin

%calculate probability
for i=1:total_bin_count
    before_sum = sum(radvel_bincount_before);
    radvel_prob_before(:,i) = radvel_bincount_before(:,i)/before_sum(i);
    
    during_sum = sum(radvel_bincount_during);
    radvel_prob_during(:,i) = radvel_bincount_during(:,i)/during_sum(i);
    
    after_sum = sum(radvel_bincount_after);
    radvel_prob_after(:,i) = radvel_bincount_after(:,i)/after_sum(i);
    
end
%========================================================================

%combine some of columns where sample number is low
% radvel_bincount_before1(:,1) = sum(radvel_bincount_before(:,1:2),2);
% radvel_bincount_before1(:,2:5) = radvel_bincount_before(:,3:6);
% radvel_bincount_before1(:,6) = sum(radvel_bincount_before(:,7:9),2);
% radvel_bincount_before1(:,7) = sum(radvel_bincount_before(:,10:12),2);
% radvel_bincount_before1(:,8) = sum(radvel_bincount_before(:,13:15),2);
%
% %during
% radvel_bincount_during1(:,1) = sum(radvel_bincount_during(:,1:2),2);
% radvel_bincount_during1(:,2:5) = radvel_bincount_during(:,3:6);
% radvel_bincount_during1(:,6) = sum(radvel_bincount_during(:,7:9),2);
% radvel_bincount_during1(:,7) = sum(radvel_bincount_during(:,10:12),2);
% radvel_bincount_during1(:,8) = sum(radvel_bincount_during(:,13:15),2);
%
% %after
% radvel_bincount_after1(:,1) = sum(radvel_bincount_after(:,1:2),2);
% radvel_bincount_after1(:,2:5) = radvel_bincount_after(:,3:6);
% radvel_bincount_after1(:,6) = sum(radvel_bincount_after(:,7:9),2);
% radvel_bincount_after1(:,7) = sum(radvel_bincount_after(:,10:12),2);
% radvel_bincount_after1(:,8) = sum(radvel_bincount_after(:,13:15),2);
%
% %calculate probability
% for i=1:size(radvel_bincount_before1,2)
% before_sum1 = sum(radvel_bincount_before1);
% radvel_prob_before1(:,i) = radvel_bincount_before1(:,i)/before_sum1(i);
%
% during_sum1 = sum(radvel_bincount_during1);
% radvel_prob_during1(:,i) = radvel_bincount_during1(:,i)/during_sum1(i);
%
% after_sum1 = sum(radvel_bincount_after1);
% radvel_prob_after1(:,i) = radvel_bincount_after1(:,i)/after_sum1(i);

% end


%========================================================================

% figures

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


fig_count = 0; %count how many figures I created

fly_no = [1:numflies];
fig_no = 0;


for a = 1:numflies
    if rem(fly_no(a),8) == 1 %first subplot, create a figure window
        figure
        set(gcf,'Position',[434 58 1200 600],'color','white')
        fig_no = fig_no+1;
    end
    
    if rem(fly_no(a),8) == 0 %8th subplot
        sp = 8;
    else
        sp = rem(fly_no(a),8);
    end
    
    subplot(2,4,sp)
    x_for_fly = numvals(:,2*a-1);
    y_for_fly = numvals(:,2*a);
    
    hold on
    
    %plot before/during/after
    %     plot(x_for_fly(1:timeperiods(2)), y_for_fly(1:timeperiods(2)), '-g', 'LineWidth',1);hold on
    %
    %     plot(x_for_fly(odoroff_frame:timeperiods(4)), y_for_fly(odoroff_frame:timeperiods(4)), 'b', 'LineWidth',1);
    %
    %     plot(x_for_fly(timeperiods(2):odoron_frame(a)),...
    %         y_for_fly(timeperiods(2):odoron_frame(a)), 'color',grey, 'LineWidth',1);
    %     plot(x_for_fly(odoron_frame(a):timeperiods(3)),...
    %         y_for_fly(odoron_frame(a):timeperiods(3)), 'r', 'LineWidth',1);
    
    
    %plot only during
    
    plot(x_for_fly(timeperiods(2):odoron_frame(a)),...
        y_for_fly(timeperiods(2):odoron_frame(a)), 'color',grey, 'LineWidth',1);
    plot(x_for_fly(odoron_frame(a):timeperiods(3)),...
        y_for_fly(odoron_frame(a):timeperiods(3)), 'r', 'LineWidth',1);
    
    
    
    plot(numvals_pi{a}(:,1), numvals_pi{a}(:,2), 'k', 'LineWidth',1);
    plot(numvals_po{a}(:,1), numvals_po{a}(:,2), 'k', 'LineWidth',1);
    %original inner rim
    plot(numvals_pi_ori{a}(:,1), numvals_pi_ori{a}(:,2), 'k--', 'LineWidth',1);
    
    
    set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
    axis tight;
    
    namestring = tracks(a);
    namestring = cellfun(@(x)x(1:13), namestring, 'UniformOutput', false);
    
    b = rem(a,20)+1;
    xlabel(namestring{1},'fontsize',8,'color',cmap(b,:));
    
    if sp == 1
        title(fig_title,'fontsize',12);
    end
    
    if sp == 8 %every time the figure is full, save it
        set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
        if fig_no ==1 %first
            print('-dpsc2',[fig_title '.ps'],'-loose');
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_'  num2str(fig_count) '.fig']);
        else
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
            print('-dpsc2',[fig_title '.ps'],'-loose','-append');
        end
        
    elseif a == numflies %if this is the last fly, save the figure
        set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
        if fig_no ==1 %first
            print('-dpsc2',[fig_title '.ps'],'-loose');
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
        else
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
            print('-dpsc2',[fig_title '.ps'],'-loose','-append');
        end
    end
    
end
%========================================================================

%==plots the position of fly at each frame in bins=========================
fig_no=1;
for p = 1:numflies
    
    if rem(fly_no(p),8) == 1 %first subplot, create a figure window
        figure
        set(gcf,'Position',[134 10 1200 820],'color','white')
        fig_no = fig_no+1;
        title([fig_title, 'distance from the center (binned)'],'fontsize',9);
        
    end
    
    if rem(fly_no(p),8) == 0 %8th subplot
        sp = 8;
    else
        sp = rem(fly_no(p),8);
    end
    
    
    sbp_1=subplot(8,4,[4*(sp-1)+1 4*(sp-1)+3]);
    sbp_p=get(gca,'position');
    set(sbp_1,'Position',sbp_p+[0 .04 0 0]);
    
    plot(location_fly(1:timeperiods(2),p),'g');hold on
    plot([timeperiods(2):odoron_frame(p)],location_fly(timeperiods(2):odoron_frame(p),p),'color',grey);
    plot([odoron_frame(p):timeperiods(3)],location_fly(odoron_frame(p):timeperiods(3),p),'r');
    plot([timeperiods(3):odoroff_frame(1)],location_fly(timeperiods(3):odoroff_frame(1),p),'color',cmap(1,:));
    plot([odoroff_frame(1):timeperiods(4)],location_fly(odoroff_frame(1):timeperiods(4),p),'b');
    plot([0 timeperiods(4)],[bin_number bin_number],'-.','color',grey);
    
    %     plot(boundary_crossing_fly{1,p},27,'+b','markersize',2,'markerfacecolor',grey);
    
    ylim([0 length(bin_prob_avg)+2]);xlim([0 timeperiods(4)]);
    set(gca,'box','off','Ytick',[],'fontsize',6);
    
    ylabel('radius','fontsize',8);
    if sp ==1 %if this is the first subplot
        title([fig_title, 'distance from the center (binned)'],'fontsize',9);
    end
    
    sbp_2 = subplot(8,4,4*(sp-1)+4);
    sbp_p2=get(gca,'position');
    set(sbp_2,'Position',sbp_p2+[0 .04 0 0]);
    
    plot(time_out_transit_before_flies{1,p},'go-','markersize',2);hold on;
    plot([length(time_out_transit_before_flies{1,p})+1:...
        length(time_out_transit_before_flies{1,p})+length(time_out_transit_during_flies{1,p})],...
        time_out_transit_during_flies{1,p},'ro-','markersize',2);
    plot([length(time_out_transit_before_flies{1,p})+length(time_out_transit_during_flies{1,p})+1:...
        length(time_out_transit_before_flies{1,p})+length(time_out_transit_during_flies{1,p})+length(time_out_transit_after_flies{1,p})],...
        time_out_transit_after_flies{1,p},'o-','markersize',2);
    
    ylim([0 100]);
    XL=get(gca,'xlim');
    set(gca,'box','off','xlim',[0 XL(2)], 'yscale','log','fontsize',6);
    plot([0, XL(2)],[10,10],':','color',grey);%y=10
    namestring = tracks(p);
    namestring = cellfun(@(x)x(1:13), namestring, 'UniformOutput', false);
    
    q = rem(p,20)+1;
    ylabel(namestring{1},'fontsize',7,'color',cmap(q,:));%to match the color with figure 1
    
    if sp ==1
        title('time spent outside before re-entry (sec)','fontsize',9);
    end
    
    if sp == 8 %every time the figure is full, save it
        set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
        fig_count = fig_count+1;
        %         saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
        print('-dpsc2',[fig_title '.ps'],'-loose','-append');
    end
    
    if p == numflies %if this is the last fly, save the figure
        set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
        fig_count = fig_count+1;
        %         saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
        print('-dpsc2',[fig_title '.ps'],'-loose','-append');
        
    end
    
end


%===============Main Analysis==============================================
figure
set(gcf,'Position',[234 58 1200 763],'color','white');

subplot(4,5,1); % plots the average time each fly spends INSIDE as a bar with standard deviation
Ti_mean = mean(time_in_flies); %mean of Total time inside (capital Ti)
Ti_std = std(time_in_flies); %std
for h = 1:3,
    b = bar(h,Ti_mean(h) , 'BarWidth', .5, 'EdgeColor', 'none'); %plot mean value as bar graph
    hold on;
    set(b, 'FaceColor', color(:,h));
    
end;
errorbar(Ti_mean,Ti_std,'color',[.2 .2 .2]);

set(gca,'Box','off','TickDir','out','Ytick',(0:0.2:1),'YGrid','on','fontsize',7);
ylim([0 1]);
xlabel('total time spent inside odor zone' ,'fontsize',8);
title([fig_title ' (n=' num2str(numflies) ')'],'fontsize',10);

subplot(4,5,2) % plots the average time each fly spends OUTSIDE as a bar with standard deviation
To_mean = mean(time_out_flies);
To_std = std(time_out_flies);
for h = 1:3,
    b = bar(h,To_mean(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    
end;
eb = errorbar(To_mean,To_std);
set(eb,'color',[.2 .2 .2]);
set(gca,'Box','off','TickDir','out','Ytick',(0:0.2:1),'YGrid','on','fontsize',7);
xlabel('time spent outside odor zone' ,'fontsize',8);
ylim ([0 1]);

subplot(4,5,3);
cn_mean = mean(crossing_number_flies); %crossing number mean
cn_std = std(crossing_number_flies);
for h = 1:3
    b = bar(h,cn_mean(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:, h));
    
end;
errorbar(cn_mean,cn_std,'color',[.2 .2 .2]);
set(gca,'Box','off','TickDir','out','Ytick',(0:10:max(crossing_number_flies(:))),'YGrid','on','fontsize',7);
xlabel('No. of transits' ,'fontsize',8);
ylim ([0 2+max(crossing_number_flies(:))]);

subplot(4,5,6);
ti_mean = nanmean(mean_time_in_transit_flies);%time spent per each transit in sec, small ti
ti_std = nanstd(mean_time_in_transit_flies);
ti_median = nanmedian(mean_time_in_transit_flies);
for h = 1:3,
    b = bar(h,ti_median(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    
end;

for fly = 1:numflies
    q = rem(fly,20)+1;
    plot(mean_time_in_transit_flies(fly,:),'.-','color',cmap(q,:));
    hold on
end
% errorbar(ti_mean,ti_std,'color',[.2 .2 .2]);
set(gca,'Box','off','TickDir','out','Ytick',(0:5:2+max(mean_time_in_transit_flies(:))),'YGrid','on','fontsize',7);
xlabel('Time spent inside/transit # (median)' ,'fontsize',8);
ylabel('time (sec)','fontsize',8);
ylim ([0 (2+max(ti_mean)+max(ti_std))]);

subplot(4,5,7)
tr_mean = nanmean(mean_time_out_transit_flies);
tr_std= nanstd(mean_time_out_transit_flies);
tr_median = nanmedian(mean_time_out_transit_flies);
for h = 1:3,
    b = bar(h, tr_median(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    
end;
for fly = 1:numflies
    q = rem(fly,20)+1;
    plot(mean_time_out_transit_flies(fly,:),'.-','color',cmap(q,:));
    hold on
end
% errorbar(tr_mean,tr_std,'color',[.2 .2 .2]);

set(gca,'Box','off','TickDir','out','Ytick',(0:10:max(mean_time_out_transit_flies)),'YGrid','on','fontsize',7);
ylabel('time (sec)','fontsize',8);
xlabel('Time to return(sec)(median)','fontsize',8);

subplot(4,5,11);
% plots radial distribution before/during/after as a fraction of total
% frame# in that time period **normalized to bin area
%inner rim radius is 1.2cm, converting bin# to r(cm)

for j=1:numflies
    
    r = rem(j,20) +1;
    %     plot(bin_radius_flies{j},bin_probability_flies{j}(1,:),'Color',cmap(r,:));
    plot(bin_probability_flies{j}(1,:),'Color',cmap(r,:));
    
    hold on
    
end
plot([bin_number bin_number],[0 1],'r:');
axis([1 total_bin_count 0 0.5]);
xlabel('bin #','fontsize',8);
set(gca,'Box','off','TickDir','out','Ytick',(0:0.2:0.5),'Xtick',(0:1:100),'fontsize',6);
title('\bfBefore:distribution','fontsize',8);

subplot(4,5,12);
% plots radial distribution 'during'

for j=1:numflies
    r = rem(j,20) +1;
    %     plot(bin_radius_flies{j},bin_probability_flies{j}(2,:),'Color',cmap(r,:));
    plot(bin_probability_flies{j}(2,:),'Color',cmap(r,:));
    
    hold on
    
end
plot([bin_number bin_number],[0 1],'r:');
axis([1 total_bin_count 0 0.5]);
xlabel('bin #','fontsize',8);
set(gca,'Box','off','TickDir','out','Ytick',(0:0.2:0.5),'Xtick',(0:1:100),'fontsize',6);

title('\bfDuring:distribution','fontsize',8);

subplot(4,5,13);
for j=1:numflies
    r = rem(j,20) +1;
    %     plot(bin_radius_flies{j},bin_probability_flies{j}(3,:),'Color',cmap(r,:));
    plot(bin_probability_flies{j}(3,:),'Color',cmap(r,:));
    hold on
end

plot([bin_number bin_number],[0 1],'r:');
axis([1 total_bin_count 0 0.5]);
xlabel('bin #','fontsize',8);
set(gca,'Box','off','TickDir','out','Ytick',(0:0.2:0.5),'Xtick',(0:1:100),'fontsize',6);
title('\bfAfter:distribution','fontsize',8);

subplot(4,5,16)
%average over multiple flies

plot([bin_number bin_number],[0 0.4],'r:'); hold on;
plot(bin_prob_avg(3,:),'b','linewidth',2);hold on;
plot(bin_prob_avg(1,:),'g','linewidth',2);
plot(bin_prob_avg(2,:),'r','linewidth',2);

ylim([0 0.3]);
set(gca,'Box','off','TickDir','out','Ytick',(0:0.1:0.5),'fontsize',6);
title('\bfaverage radial distribution','fontsize',8);
xlabel(['bin# in the odor zone; ' num2str(bin_number)]);

subplot(4,5,17);
vi_mean = nanmean(total_avg_vel_in_flies);%mean of velocity inside
vi_std = nanstd(total_avg_vel_in_flies);
for h = 1:3,
    b = bar(h, vi_mean(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
end;
errorbar(vi_mean,vi_std,'color',[.2 .2 .2]);
set(gca,'Box','off','tickdir','out','ytick',(0:.5:20),'ygrid','on','fontsize',7);
xlabel('avg velocity inside' ,'fontsize',8);
ylabel(vel_unit,'fontsize',8);
ylim ([0 1.5]);

subplot(4,5,18);
vo_mean = nanmean(total_avg_vel_out_flies); %average velocity outside
vo_std = nanstd(total_avg_vel_out_flies);
for h = 1:3,
    b = bar(h, vo_mean(h), 'BarWidth', .5, 'EdgeColor', 'none');
    hold on;
    set(b, 'FaceColor', color(:,h));
    
end;
errorbar(vo_mean,vo_std,'color',[.2 .2 .2]);
set(gca,'Box','off','TickDir','out','Ytick',(0:.5:20),'YGrid','on','fontsize',7);
xlabel('avg velocity outside' ,'fontsize',8);
ylabel(vel_unit,'fontsize',8);
ylim ([0 1.5]);

% %average fold difference (not used from V15)
% %fold difference calculation : For time inside, average distance from the
% %center and velocity in and out, get the new matrix that saves the each
% %fly's during/before values
fold_time_inside = time_in_flies(:,2)./time_in_flies(:,1);
fold_time_in_per_transit = mean_time_in_transit_flies(:,2)./mean_time_in_transit_flies(:,1);
fold_transit = crossing_number_flies(:,2)./crossing_number_flies(:,1);
fold_time_bw_in = mean_time_out_transit_flies(:,2)./mean_time_out_transit_flies(:,1);
fold_avg_radius = avg_radius_flies(:,2)./avg_radius_flies(:,1);
fold_vel_in = total_avg_vel_in_flies(:,2)./total_avg_vel_in_flies(:,1);
fold_vel_out = total_avg_vel_out_flies(:,2)./total_avg_vel_out_flies(:,1);
%
%replace 'infinite number' that was generated by dividing by zero with
%'nan'
fold_time_inside(~isfinite(fold_time_inside)) = nan;
fold_transit(~isfinite(fold_transit)) = nan;

average_fold = [nanmean(fold_time_inside),nanmean(fold_time_in_per_transit)...
    ,nanmean(fold_transit),nanmean(fold_time_bw_in),nanmean(fold_avg_radius)...
    ,nanmean(fold_vel_in),nanmean(fold_vel_out)];
median_fold = [nanmedian(fold_time_inside),nanmedian(fold_time_in_per_transit)...
    ,nanmedian(fold_transit),nanmedian(fold_time_bw_in),nanmedian(fold_avg_radius),...
    nanmedian(fold_vel_in),nanmedian(fold_vel_out)];

%plotting data in 1/2/3D
%Ti only
subplot(4,5,4)
plot(time_in_flies(:,1),0,'g.','markersize',4);
hold on
plot(Ti_mean(1),0,'g*','markersize',4);
plot(time_in_flies(:,2),0,'r.','markersize',4);
plot(Ti_mean(2),0,'r*','markersize',4);

ylim([-.1 .1]); xlim([-.5 1])
set(gca,'box','off','Ycolor',[1 1 1]);
xlabel('Ti (probability)');
title('total time spent inside');

subplot(4,5,5)
plot(mean_time_out_transit_flies(:,1),mean_time_in_transit_flies(:,1),'g.');
hold on
plot(mean_time_out_transit_flies(:,2),mean_time_in_transit_flies(:,2),'r.');
set(gca,'Box','off','TickDir','out','fontsize',7);
xlabel('tr (sec)');
ylabel('ti (sec)');
title('time in VS time to return','fontsize',10);

subplot(4,5,9)
scatter3(mean_time_out_transit_flies(:,1),mean_time_in_transit_flies(:,1),total_avg_vel_in_flies(:,1),'g.');
hold on
scatter3(mean_time_out_transit_flies(:,2),mean_time_in_transit_flies(:,2),total_avg_vel_in_flies(:,2),'r.');
set(gca,'Box','off','TickDir','out','fontsize',7);
xlabel('tr (sec)');
ylabel('ti (sec)');
zlabel('vi (cm/sec)');
zlim([0 1]);
title('ti VS tr VS velocity inside','fontsize',10);

subplot(4,5,10)
scatter3(mean_time_out_transit_flies(:,1),mean_time_in_transit_flies(:,1),avg_radius_flies(:,1),'g.');
hold on
scatter3(mean_time_out_transit_flies(:,2),mean_time_in_transit_flies(:,2),avg_radius_flies(:,2),'r.');
set(gca,'Box','off','TickDir','out','fontsize',7);
xlabel('tr (sec)');
ylabel('ti (sec)');
zlabel('distance from center (cm)');
zlim([0 2]);
title('ti VS tr  VS distance from center','fontsize',10);


set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

%plot fraction of time inside VS time in (per transit)/time out (per
%transit)

%mean
ti_over_tr = nan(numflies,3);
ti_over_ti_tr = nan(numflies,3);
for i=1:numflies
    ti_over_tr(i,:) = mean_time_in_transit_flies(i,:)./(mean_time_out_transit_flies(i,:));
    %     ti_over_ti_tr(i,:) = mean_time_in_transit_flies(i,:)./(mean_time_in_transit_flies(i,:)+mean_time_out_transit_flies(i,:));
end

%getting the equation with the range
fit_x = [0:0.1:20];
fit_y = (fit_x)./(1 + fit_x);


%median
ti_over_tr_median = nan(numflies,3);
ti_over_ti_tr_median = nan(numflies,3);
for i=1:numflies
    ti_over_tr_median(i,:) = median_time_in_transit_flies(i,:)./(median_time_out_transit_flies(i,:));
    %     ti_over_ti_tr_median(i,:) = median_time_in_transit_flies(i,:)./(median_time_in_transit_flies(i,:)+median_time_out_transit_flies(i,:));
end

%===========================================================================
figure
set(gcf,'Position',[500 100 900 600],'color','white');
period_name = {'Before','During','After'};

for i=1:3
    subplot(3,3,3*i-2)
    plot(ti_over_tr(:,i),time_in_flies(:,i),'o','color',color(i,:),'markersize',2);hold on
    plot(ti_over_ti_tr(:,i),time_in_flies(:,i),'k+','markersize',4);
    
    plot(fit_x,fit_y,'color',grey);
    
    title(period_name{i});
    if i==1
        title({[fig_title ' (n= ' num2str(numflies) ')'];['Mean'];period_name{i}});
    end
    set(gca,'box','off','Tickdir','out');
    xlim([0 5]);ylim([0 ,1]);
end

xlabel('o: ti/tr');
ylabel('total time spent inside');

%median

for i=1:3
    subplot(3,3,3*i-1)
    plot(ti_over_tr_median(:,i),time_in_flies(:,i),'o','color',color(i,:),'markersize',2);hold on
    plot(ti_over_ti_tr_median(:,i),time_in_flies(:,i),'k+','markersize',4);
    %y= ti/(ti+tr)
    plot(fit_x,fit_y,'color',grey);
    
    title(period_name{i});
    if i==1
        title({'Median';period_name{i}});
    end
    
    set(gca,'box','off','Tickdir','out');
    xlim([0 5]);ylim([0 ,1]);
end

xlabel('o: ti/tr');
ylabel('total time spent inside');

%ti VS tr
fit_ti_tr = nan(3,2);
rsq_fit = nan(3,1);
for i=1:3
    ti_temp = mean_time_in_transit_flies(:,i)';
    tr_temp = mean_time_out_transit_flies(:,i)';
    tr = tr_temp(find(~isnan(tr_temp)));%get rid of nans
    ti = ti_temp(find(~isnan(tr_temp)));%get rid of nans % need to use ~(isnan(tr_trmp)) to make tr and ti vector same size
    
    [fit_ti_tr(i,:),S] = polyfit(ti,tr,1); %least-square
    
    %http://www.mathworks.com/help/techdoc/data_analysis/f1-5937.html#f1-15010
    
    yfit = polyval(fit_ti_tr(i,:),ti); %predict y
    yresid = tr - yfit; %residual value
    SSresid = sum(yresid.^2); %residual sum of squares
    SStotal = (length(tr)-1)*var(tr);%Compute the total sum of squares of y by multiplying the variance of y by the number of observations minus 1:
    rsq = 1 - SSresid/SStotal;%Compute R2 using the formula given in the introduction of this topic:
    rsq_fit(i) = rsq;
    %save results
    if i==1
        ti_bf = ti; tr_bf = tr; S_bf = S;
    elseif i==2
        ti_dr = ti; tr_dr = tr; S_dr = S;
    else
        ti_af = ti; tr_af = tr; S_af = S;
    end
end

%ti VS tr
for i=1:3
    
    x = [0:.1:100];
    y = polyval(fit_ti_tr(i,:),x);
    
    subplot(3,3,3*i)
    plot(mean_time_in_transit_flies(:,i),mean_time_out_transit_flies(:,i),'o',...
        'color',color(i,:),'markerfacecolor',color(i,:),'markersize',4);hold on
    plot(x,y,'color',grey);
    text(20,30,['R sqare = ' num2str(rsq_fit(i))]);
    title(period_name{i});
    if i==1
        title({'ti VS tr (mean)';period_name{i}});
    end
    
    set(gca,'box','off','Tickdir','out');
    xlim([0 30]);ylim([0 ,50]);
    xlabel('ti (sec)');
    ylabel('tr (sec)');
end

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%==========================================================================
%time_in_out_historgram.m
%histogram for time spent in/transit and time spent out/transit

%first put all the cell array data into one matrix
%time in /transit
every_ti_before = vertcat(time_in_transit_before_flies{:});
every_ti_during =  vertcat(time_in_transit_during_flies{:});
every_ti_after = vertcat(time_in_transit_after_flies{:});

%time out/transit (odor rediscovery time)
every_to_before = vertcat(time_out_transit_before_flies{:});
every_to_during =  vertcat(time_out_transit_during_flies{:});
every_to_after = vertcat(time_out_transit_after_flies{:});

%total number of samples
total_n_ti_before = length(every_ti_before);
total_n_ti_during = length(every_ti_during);
total_n_ti_after = length(every_ti_after);

total_n_to_before = length(every_to_before);
total_n_to_during = length(every_to_during);
total_n_to_after = length(every_to_after);

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
max_ti = max([n_ti_before;n_ti_during;n_ti_after]);
max_to = max([n_to_before;n_to_during;n_to_after]);

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
    
    
    %individual fly's mean time in/transit
    plot([mean_time_in_transit_flies(:,i),mean_time_in_transit_flies(:,i)],[0 100],'k:');
    ti_mean = nanmean(mean_time_in_transit_flies(:,i));%get the mean average in sec for all flies
    %plot the mean time in/transit for all the flies
    plot([ti_mean, ti_mean],[0 100],'r--');
    
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
    
    
    %individual fly's mean time in/transit
    plot([mean_time_out_transit_flies(:,i),mean_time_out_transit_flies(:,i)],[0 100],'k:');
    to_mean = nanmean(mean_time_out_transit_flies(:,i));%get the mean average in sec for all flies
    %plot the mean time in/transit for all the flies
    plot([to_mean, to_mean],[0 100],'r--');
    
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
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%========================================================================

%plot curvature, turns, reorientation
multiple_flies_curv_turn_reori_plotter;

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


multiple_flies_curv_turn_periods;

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

%plot turning/curved walking quantification
multiple_flies_turning_analysis_plotter;

%========================================================================
% plot Ti VS ti, tr, or turn frequency

figure
set(gcf,'position',[300 200 1200 500]);

%Ti VS ti
subplot(2,5,1)
for i=1:2
    plot(mean_time_in_transit_flies(:,i),time_in_flies(:,i),'.','color',color(i,:));
    hold on
end
ylim([0 1]);

set(gca,'Ytick',[0:.2:1],'tickdir','out','box','off');
xlabel('mean time inside per transit (sec)');
ylabel('total time inside (fraction)');

title('Ti VS ti');

% Correlation Coefficients
%
% The MATLAB function corrcoef produces a matrix of sample correlation coefficients for a data matrix (where each column represents a separate quantity). The correlation coefficients range from -1 to 1, where
%
% Values close to 1 indicate that there is a positive linear relationship between the data columns.
% Values close to -1 indicate that one column of data has a negative linear relationship to another column of data (anticorrelation).
% Values close to or equal to 0 suggest there is no linear relationship between the data columns.

[r_ti,p] =corrcoef(mean_time_in_transit_flies(:,2),time_in_flies(:,2)); % Compute sample correlation and p-values.
% [i,j] = find(p<0.05);  % Find significant correlations.
% [i,j]                % Display their (row,col) indices.

text(2,.9,['corr coeff =' num2str(r_ti(1,2))]);
text(2, .8, ['p value = '  num2str(p(1,2),'%1.2f')]);

%Ti VS tr
subplot(2,5,2)
for i=1:2
    plot(mean_time_out_transit_flies(:,i),time_in_flies(:,i),'.','color',color(i,:));
    hold on
end
ylim([0 1]);

set(gca,'Ytick',[0:.2:1],'tickdir','out','box','off');
xlabel('mean time out per transit (sec)');
ylabel('total time inside (fraction)');

title('Ti VS tr');

[r_tr,p] =corrcoef(mean_time_out_transit_flies(:,2),time_in_flies(:,2)); % Compute sample correlation and p-values.
text(1,.9,['corr coeff =' num2str(r_tr(1,2))]);
text(2, .8, ['p value = '  num2str(p(1,2),'%1.2f')]);


%Ti VS turns
subplot(2,5,3)
for i=1:2
    plot(turn_rate_in_flies(i,:),time_in_flies(:,i),'.','color',color(i,:));
    hold on
end
ylim([0 1]);

set(gca,'Ytick',[0:.2:1],'tickdir','out','box','off');
xlabel('sharp turn frequency(inside) (/sec)');
ylabel('total time inside (fraction)');

title('Ti VS Turn inside');

[r_turni,p] =corrcoef(turn_rate_in_flies(2,:),time_in_flies(:,2)); % Compute sample correlation and p-values.
text(.1,.9,['corr coeff =' num2str(r_turni(1,2))]);
text(.1,.8, ['p value = '  num2str(p(1,2),'%1.2f')]);


subplot(2,5,4)
for i=1:2
    plot(turn_rate_out_flies(i,:),time_in_flies(:,i),'.','color',color(i,:));
    hold on
end
ylim([0 1]);

set(gca,'Ytick',[0:.2:1],'tickdir','out','box','off');
xlabel('sharp turn frequency (outside) (/sec)');
ylabel('total time inside (fraction)');

title('Ti VS Turn outside');

[r_turno,p] =corrcoef(turn_rate_out_flies(2,:),time_in_flies(:,2)); % Compute sample correlation and p-values.
text(.1,.9,['corr coeff =' num2str(r_turno(1,2))]);
text(.1,.8, ['p value = '  num2str(p(1,2),'%1.2f')]);

%Sharp turns in specific rings

for ring=1:NumRings
    subplot(2,5,5+ring)
    plot(turn_fr_ring_bf(:,ring),time_in_flies(:,1),'g.');
    hold on
    plot(turn_fr_ring_dr(:,ring),time_in_flies(:,2),'r.');
    
    ylim([0 1]);
    
    set(gca,'Ytick',[0:.2:1],'tickdir','out','box','off');
    xlabel('sharp turn frequency (/sec)');
    ylabel('total time inside (fraction)');
    
    title(['Ti VS turn between ' num2str(ring_inner_radius_rings(ring)) ' and ' num2str(ring_outer_radius_rings(ring))]);
    
    [r_turn,p] =corrcoef(turn_fr_ring_dr(:,ring),time_in_flies(:,2)); % Compute sample correlation and p-values.
    text(.1,.9,['corr coeff =' num2str(r_turn(1,2))]);
    text(.1,.8, ['p value = '  num2str(p(1,2),'%1.2f')]);
    
end

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%========================================================================

%Run/Stop probability plot

% first out2in run/stop probability calculation========================
% first_i2o_rs_bf etc contains the first crossing's velocity_classified
for hh = 1:how_long; %before crossing till 2 sec after crossing)
    a = first_i2o_rs_bf(hh,:);%go through row-by-row (frame)
    prob_first_i2o_bf(hh) = (nansum(a>0)/sum(~isnan(a)));
    %calculate how many runs(not 0 in velocity_classified/all events)
    
    aa = first_o2i_rs_bf(hh,:);
    prob_first_o2i_bf(hh) = (nansum(aa>0)/sum(~isnan(aa)));
    
    aaa = first_i2o_rs_dr(hh,:);%go through row-by-row (frame)
    prob_first_i2o_dr(hh) = (nansum(aaa>0)/sum(~isnan(aaa)));
    %calculate how many runs(not 0 in velocity_classified/all events)
    
    aaaa = first_o2i_rs_dr(hh,:);
    prob_first_o2i_dr(hh) = (nansum(aaaa>0)/sum(~isnan(aaaa)));
end


%== other run/stop probability (excluding the first crossings)=============

%get the before /during i2o/o2i into one array
rs_others_i2o_bf = nan(how_long,numflies);
rs_others_i2o_dr = nan(how_long,numflies);
rs_others_o2i_bf = nan(how_long,numflies);
rs_others_o2i_dr = nan(how_long,numflies);

for period = 1:2
    for fly = 1:numflies
        if period ==1
            rs_others_i2o_bf(:,fly) = probabilityin2out_others_flies{fly}(:,period);
            rs_others_o2i_bf(:,fly) = probabilityout2in_others_flies{fly}(:,period);
            
        elseif period == 2
            rs_others_i2o_dr(:,fly) = probabilityin2out_others_flies{fly}(:,period);
            rs_others_o2i_dr(:,fly) = probabilityout2in_others_flies{fly}(:,period);
            
        end
    end
end

prob_others_i2o = nan(how_long,2);
prob_others_o2i = nan(how_long,2);

%mean of individual flies' means
prob_others_i2o(:,1) = nanmean(rs_others_i2o_bf,2);
prob_others_i2o(:,2) = nanmean(rs_others_i2o_dr,2);

prob_others_o2i(:,1) = nanmean(rs_others_o2i_bf,2);
prob_others_o2i(:,2) = nanmean(rs_others_o2i_dr,2);


%bin it
numBins = 30; %how many bins? if there are 150 frames, 5 frames/bin
topEdge = timetotal*framespertimebin; %define limits
botEdge = 1; %define limits

binEdges = linspace(botEdge,topEdge,numBins); %define edges of bins

[~,whichBin] = histc([botEdge:topEdge],binEdges); %do histc to bin x or frame#

[prob_others_i2o_bin_mean,prob_others_o2i_bin_mean,prob_others_i2o_bin_SEM,prob_others_o2i_bin_SEM,...
    prob_others_i2o_by_bin_h,prob_others_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    rs_others_i2o_bf,rs_others_i2o_dr,...
    rs_others_o2i_bf,rs_others_o2i_dr);


%calculate mean of individual fly's means================================
%pre-allocate
probabilityin2out_before = nan(numflies,how_long);
probabilityin2out_during = nan(numflies,how_long);
probabilityin2out_after = nan(numflies,how_long);
probabilityout2in_before = nan(numflies,how_long);
probabilityout2in_during = nan(numflies,how_long);
probabilityout2in_after = nan(numflies,how_long);

%collect all before/during/period data into matrix
%get mean value from fly, then get the mean of means
%it is basically same as values saved in  'probabilityin2out_flies' except
%that this only counts the flies that have more crossings than crossing_min
sample_no = 0;
for i=1:numflies
    if min(crossing_number_flies(i,1:2)) > crossing_min %only use ones with >2 crossings in before/during
        sample_no = sample_no+1;
        for period=1:3
            if period ==1
                probabilityin2out_before(i,:) = probabilityin2out_flies{i}(:,period);
                probabilityout2in_before(i,:) = probabilityout2in_flies{i}(:,period);
            elseif period ==2
                probabilityin2out_during(i,:) = probabilityin2out_flies{i}(:,period);
                probabilityout2in_during(i,:) = probabilityout2in_flies{i}(:,period);
            else %after
                probabilityin2out_after(i,:) = probabilityin2out_flies{i}(:,period);
                probabilityout2in_after(i,:) = probabilityout2in_flies{i}(:,period);
            end
        end
    end
end

%calculate the mean
mean_probabilityin2out = nan(3,how_long);
mean_probabilityout2in = nan(3,how_long);
%in2out
mean_probabilityin2out(1,:) = nanmean(probabilityin2out_before); %mean of means
mean_probabilityin2out(2,:) = nanmean(probabilityin2out_during);
mean_probabilityin2out(3,:) = nanmean(probabilityin2out_after);
%out2in
mean_probabilityout2in(1,:) = nanmean(probabilityout2in_before);
mean_probabilityout2in(2,:) = nanmean(probabilityout2in_during);
mean_probabilityout2in(3,:) = nanmean(probabilityout2in_after);

%std/SEM
%in2out
run_stop_prob_i2o_std = nanstd(probabilityin2out_before);
run_stop_prob_i2o_std(2,:) = nanstd(probabilityin2out_during);
run_stop_prob_i2o_std(3,:) = nanstd(probabilityin2out_after);
%SEM: sample (fly) number that is not nan : sample_no
run_stop_prob_i2o_SEM = run_stop_prob_i2o_std/(sqrt(sample_no));

%out2in
run_stop_prob_o2i_std = nanstd(probabilityout2in_before);
run_stop_prob_o2i_std(2,:) = nanstd(probabilityout2in_during);
run_stop_prob_o2i_std(3,:) = nanstd(probabilityout2in_after);
%SEM: sample (fly) number that is not nan : sample_no
run_stop_prob_o2i_SEM = run_stop_prob_o2i_std/(sqrt(sample_no));

% bin data and run t-test between 'before' and 'during'
numBins = 30; %how many bins? if there are 150 frames, 5 frames/bin
topEdge = timetotal*framespertimebin; %define limits
botEdge = 1; %define limits

binEdges = linspace(botEdge,topEdge,numBins); %define edges of bins

[h,whichBin] = histc([botEdge:topEdge],binEdges); %do histc to bin x or frame#
binMean = nan(numflies,numBins); %pre-allocate to save mean of each bin

%preallocate
bin_rs_i2o_bf = nan(numflies,numBins);
bin_rs_i2o_dr = nan(numflies,numBins);
bin_rs_o2i_bf = nan(numflies,numBins);
bin_rs_o2i_dr = nan(numflies,numBins);

for i=1:numBins
    flagBinMembers = (whichBin == i); %check each bin
    %i2o
    %before
    binMembers = probabilityin2out_before(:,flagBinMembers); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,2); %get the mean
    bin_rs_i2o_bf(:,i) = binMean;
    
    %during
    binMembers = probabilityin2out_during(:,flagBinMembers); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,2); %get the mean
    bin_rs_i2o_dr(:,i) = binMean;
    
    %o2i
    %before
    binMembers = probabilityout2in_before(:,flagBinMembers); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,2); %get the mean
    bin_rs_o2i_bf(:,i) = binMean;
    %during
    binMembers = probabilityout2in_during(:,flagBinMembers); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,2); %get the mean
    bin_rs_o2i_dr(:,i) = binMean;
end

%get rid of rows of nans
for fly = 1:numflies
    M = bin_rs_i2o_bf;
    M(all(isnan(M),2),:) = [];
    bin_rs_i2o_bf = M;
    
    M = bin_rs_i2o_dr;
    M(all(isnan(M),2),:) = [];
    bin_rs_i2o_dr = M;
    
    M = bin_rs_o2i_bf;
    M(all(isnan(M),2),:) = [];
    bin_rs_o2i_bf = M;
    
    M = bin_rs_o2i_dr;
    M(all(isnan(M),2),:) = [];
    bin_rs_o2i_dr = M;
    
end

%one sample, ttest
%pre-allocate
rs_i2o_by_bin_h = nan(1,numBins);
rs_i2o_by_bin_p = nan(1,numBins);
rs_i2o_by_bin_ci = nan(2,numBins);
rs_o2i_by_bin_h = nan(1,numBins);
rs_o2i_by_bin_p = nan(1,numBins);
rs_o2i_by_bin_ci = nan(2,numBins);


for i=1:numBins
    [h, p, ci] = ttest(bin_rs_i2o_bf(:,i),bin_rs_i2o_dr(:,i));
    rs_i2o_by_bin_h(i) = h;
    rs_i2o_by_bin_p(i) = p;
    rs_i2o_by_bin_ci(:,i) = ci;
    
    [h, p, ci] = ttest(bin_rs_o2i_bf(:,i),bin_rs_o2i_dr(:,i));
    rs_o2i_by_bin_h(i) = h;
    rs_o2i_by_bin_p(i) = p;
    rs_o2i_by_bin_ci(:,i) = ci;
end


figure
set(gcf,'color','white','Position',[300 10 700 900]);

%x axis range to convert frame# to time (sec)
x_range = [(-timebefore):1/framespertimebin:timetotal-timebefore-1/framespertimebin];

for period = 1:2;
    subplot(6,2,2*period-1)
    for fly = 1:numflies
        r = rem(fly,20)+1;
        if period ==1
            plot(x_range,probabilityout2in_before(fly,:),'color',cmap(r,:));hold on;
        elseif period ==2
            plot(x_range,probabilityout2in_during(fly,:),'color',cmap(r,:));hold on
        end
    end
    plot(x_range,mean_probabilityout2in(period,:),'color',color(period,:),'linewidth',2)
    xlabel('time (sec)','fontsize',9);
    ylabel('run probability','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
    xlim ([min(x_range) max(x_range)+1/framespertimebin])  %2 sec before crossing + 5 sec after crossing
    ylim ([0 1.2])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    if period==1
        title([fig_title ' run probability crossing in'],'interpreter','none','fontsize',10);
    end
    
    hold off
    
    
    % %for crossing in2out
    subplot(6,2,period*2)
    for fly = 1:numflies
        r = rem(fly,20)+1;
        if period ==1
            plot(x_range,probabilityin2out_before(fly,:),'color',cmap(r,:));hold on
        elseif period ==2
            plot(x_range,probabilityin2out_during(fly,:),'color',cmap(r,:));hold on
        end
    end
    plot(x_range,mean_probabilityin2out(period,:),'color',color(period,:),'linewidth',2)
    xlabel('time (sec)','fontsize',9);
    ylabel('run probability','fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
    hold on
    
    xlim ([min(x_range) max(x_range)+1/framespertimebin]);
    ylim ([0 1.2]);
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    if period ==1
        title('run probability crossing out','fontsize',10);
    end
end

subplot(6,2,5)
%out2in
%before
%first plot errobars using area function
%refer to average_errorbar_plotting.m
SEM_y_plot = [mean_probabilityout2in(1,:)- run_stop_prob_o2i_SEM(1,:);(2*run_stop_prob_o2i_SEM(1,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','g','EdgeColor','none');
alpha(.2);
hold on
plot(x_range,mean_probabilityout2in(1,:),'g','linewidth',1.5);

%during
SEM_y_plot = [mean_probabilityout2in(2,:)- run_stop_prob_o2i_SEM(2,:);(2*run_stop_prob_o2i_SEM(2,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','r','EdgeColor','none');
alpha(.2);
plot(x_range,mean_probabilityout2in(2,:),'r','linewidth',1.5);
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlim ([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 1.2])

xlabel('time (sec)','fontsize',9);
ylabel('run probability','fontsize',9);
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
title(['mean of means +/- SEM,crossing # >' num2str(crossing_min)]);

subplot(6,2,6)
%In2out
%before
%first plot errobars using area function
%refer to average_errorbar_plotting.m
SEM_y_plot = [mean_probabilityin2out(1,:)- run_stop_prob_i2o_SEM(1,:);(2*run_stop_prob_i2o_SEM(1,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','g','EdgeColor','none');
alpha(.2);
hold on
plot(x_range,mean_probabilityin2out(1,:),'g','linewidth',1.5);

%during
SEM_y_plot = [mean_probabilityin2out(2,:)- run_stop_prob_i2o_SEM(2,:);(2*run_stop_prob_i2o_SEM(2,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','r','EdgeColor','none');
alpha(.2);
plot(x_range,mean_probabilityin2out(2,:),'r','linewidth',1.5);
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlim ([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 1.2])

xlabel('time (sec)','fontsize',9);
ylabel('run probability','fontsize',9);
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);

%binned data, mark the bins that are significantly different
subplot(6,2,7)
before_mean = nanmean(bin_rs_o2i_bf);during_mean = nanmean(bin_rs_o2i_dr);
bin_x = linspace(-timebefore,timetotal-timebefore,numBins);
plot(bin_x,before_mean,'g.-','linewidth',1.5); hold on
plot(bin_x,during_mean,'r.-','linewidth',1.5);

for i=1:numBins
    if rs_o2i_by_bin_h(i) == 1
        y_value = during_mean(i)-.1;
        text(bin_x(i),y_value,'*','color','k');
    end
end
xlim ([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 1.2])
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlabel('time (sec)','fontsize',9);
ylabel('binned run probability','fontsize',9);
title(['binned (' num2str(timetotal*framespertimebin/numBins) 'frames/bin)']);

subplot(6,2,8)
before_mean = nanmean(bin_rs_i2o_bf);during_mean = nanmean(bin_rs_i2o_dr);
bin_x = linspace(-timebefore,timetotal-timebefore,numBins);
plot(bin_x,before_mean,'g.-','linewidth',1.5); hold on
plot(bin_x,during_mean,'r.-','linewidth',1.5);

for i=1:numBins
    if rs_i2o_by_bin_h(i) == 1
        y_value = during_mean(i)-.1;
        text(bin_x(i),y_value,'*','color','k');
    end
end
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlim ([min(x_range) max(x_range)+1/framespertimebin]);

ylim ([0 1.2])
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
hold off
xlabel('time (sec)','fontsize',9);
ylabel('binned run probability','fontsize',9);

%first crossing only ***NEED SEM ERROR BAR
subplot(6,2,9)
plot(x_range,prob_first_o2i_bf,'g','linewidth',1.5);
hold on
plot(x_range,prob_first_o2i_dr,'r','linewidth',1.5);
xlim ([min(x_range) max(x_range)+1/framespertimebin]);

ylim ([0 1.2])
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlabel('time (sec)','fontsize',9);
ylabel('run probability','fontsize',9);
title('First crossing: out2in');

subplot(6,2,10)
plot(x_range,prob_first_i2o_bf,'g','linewidth',1.5);
hold on
plot(x_range,prob_first_i2o_dr,'r','linewidth',1.5);
xlim ([min(x_range) max(x_range)+1/framespertimebin]);

ylim ([0 1.2])
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlabel('time (sec)','fontsize',9);
ylabel('run probability','fontsize',9);
title('First crossing: in2out');

%excluding first crossings
subplot(6,2,11)
bin_x = linspace(-timebefore,timetotal-timebefore,numBins);

%before
SEM_y_plot = [prob_others_o2i_bin_mean(:,1)'- prob_others_o2i_bin_SEM(:,1)';...
    (2*prob_others_o2i_bin_SEM(:,1)')];
h = area(bin_x,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','g','EdgeColor','none');
alpha(.2);
hold on

before_mean = prob_others_o2i_bin_mean(:,1);
plot(bin_x,before_mean,'g.-','linewidth',1.5); hold on

%during
SEM_y_plot = [prob_others_o2i_bin_mean(:,2)'- prob_others_o2i_bin_SEM(:,2)';...
    (2*prob_others_o2i_bin_SEM(:,2)')];
h = area(bin_x,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','r','EdgeColor','none');
alpha(.2);
hold on

during_mean = prob_others_o2i_bin_mean(:,2);
plot(bin_x,during_mean,'r.-','linewidth',1.5);

for i=1:numBins
    if prob_others_o2i_by_bin_h(i) == 1
        y_value = during_mean(i)-.1;
        text(bin_x(i),y_value,'*','color','k');
    end
end
xlim ([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 1.2])
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlabel('time (sec)','fontsize',9);
ylabel('binned run probability','fontsize',9);
title(['binned (' num2str(timetotal*framespertimebin/numBins) 'frames/bin)']);


subplot(6,2,12)
%before
SEM_y_plot = [prob_others_i2o_bin_mean(:,1)'- prob_others_i2o_bin_SEM(:,1)';...
    (2*prob_others_i2o_bin_SEM(:,1)')];
h = area(bin_x,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','g','EdgeColor','none');
alpha(.2);
hold on

before_mean = prob_others_i2o_bin_mean(:,1);
plot(bin_x,before_mean,'g.-','linewidth',1.5); hold on

%during
SEM_y_plot = [prob_others_i2o_bin_mean(:,2)'- prob_others_i2o_bin_SEM(:,2)';...
    (2*prob_others_i2o_bin_SEM(:,2)')];
h = area(bin_x,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','r','EdgeColor','none');
alpha(.2);
hold on

during_mean = prob_others_i2o_bin_mean(:,2);
plot(bin_x,during_mean,'r.-','linewidth',1.5);

for i=1:numBins
    if prob_others_i2o_by_bin_h(i) == 1
        y_value = during_mean(i)-.1;
        text(bin_x(i),y_value,'*','color','k');
    end
end
xlim ([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 1.2])
set(gca,'Box','off','Xtick',(-10:1:400),'tickdir','out','fontsize',8);
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlabel('time (sec)','fontsize',9);
ylabel('binned run probability','fontsize',9);
title(['binned (' num2str(timetotal*framespertimebin/numBins) 'frames/bin)']);


h=gcf;
set(h, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%========================================================================

% run & stop stats; collect all flies data and save them according to periods

for i=1:numflies
    
    for period =1:3
        if period ==1
            runs_before{i} = runs_flies{i}{period};
            stops_before_temp = stops_flies{i}{period};
            %exclude empty cells in stops_before
            stops_before{i} = stops_before_temp(~cellfun(@isempty,stops_before_temp));
            
        elseif period ==2
            runs_during{i} = runs_flies{i}{period};
            stops_during{i} = stops_flies{i}{period};
        else
            runs_after{i} = runs_flies{i}{period};
            stops_after{i} = stops_flies{i}{period};
        end
    end
end


%combine all of them and make one cell array
all_runs = {runs_before;runs_during;runs_after};
all_stops = {stops_before;stops_during;stops_after};

%go over the each element of cell array for calculations===================

%first, find out how many elements for each period for all flies
for i=1:numflies
    run_num_before(i) = numel(runs_before{i});
    run_num_during(i) = numel(runs_during{i});
    run_num_after(i) = numel(runs_after{i});
    
    stops_num_before(i) = numel(stops_before{i});
    stops_num_during(i) = numel(stops_during{i});
    stops_num_after(i) = numel(stops_after{i});
end

total_run_no(1)=sum(run_num_before);
total_run_no(2) = sum(run_num_during);
total_run_no(3) = sum(run_num_after);
max_total_run = max(total_run_no);

total_stop_no(1) = sum(stops_num_before);
total_stop_no(2) = sum(stops_num_during);
total_stop_no(3) = sum(stops_num_after);
max_total_stop = max(total_stop_no);

%pre-allocate
all_runsduration_secs = nan(3, max_total_run);
all_distance_final = nan(3, max_total_run);
all_avg_velocity = nan(3, max_total_run);
all_stopsduration_secs = nan(3,max_total_stop);

for period =1:3
    n=1;m=1;
    for i=1:numflies
        
        for p = 1:numel(all_runs{period}{i})
            %save how long each run is
            runsduration = length(all_runs{period}{i}{p});%in frame
            runsduration_secs = (runsduration)/framespertimebin;%in sec
            avg_velocity = nanmean(all_runs{period}{i}{p}); % average velocity of runs (cm/sec)
            distance_final = avg_velocity * runsduration_secs; % in cm
            
            %save each run data in one matrix
            all_runsduration_secs(period,n) = runsduration_secs;
            all_distance_final(period,n) = distance_final;
            all_avg_velocity(period,n) = avg_velocity;
            n=n+1;
            
            %individual fly's mean of run duration
            onefly_run(p) = runsduration_secs;
        end
        runduration_secs_fly(i,period) = mean(onefly_run);
        clear onefly_run
        
        for p = 1:numel(all_stops{period}{i})
            stopsduration = length(all_stops{period}{i}{p}); %frames
            stopsduration_secs = stopsduration/framespertimebin; %in sec
            
            all_stopsduration_secs(period,m) = stopsduration_secs;
            m=m+1;
            
            %individual fly's mean of stop duration
            onefly_stop(p) = stopsduration_secs;
        end
        stopduration_secs_fly(i,period) = mean(onefly_stop);
        clear onefly_stop;
    end
end


%how many runs or stops/period for all flies
numruns = total_run_no;
numstops = total_stop_no;

%average stop duration in sec and total time
avgstopduration = nanmean(all_stopsduration_secs,2);
stopduration_total = nansum(all_stopsduration_secs,2);

%average run duration in sec and total time
avgrunduration = nanmean(all_runsduration_secs,2);
runsduration_total = nansum(all_runsduration_secs,2);

%average velocity of all runs (excluding stops): mean of means (of each
%run)
avgavgvel = nanmean(all_avg_velocity,2);

%get the mean velocity of individual fly (from all the runs grouped) then get the
%mean of means
run_vel_avg_fly = nan(numflies,3);

for period =1:3
    for i=1:numflies
        run_vel_all_cell = all_runs{period}{i};
        run_vel_all = cell2mat(run_vel_all_cell);
        run_vel_avg_fly(i,period) = nanmean(run_vel_all); %individual fly's run vel average
    end
end
avgavgvel2 = nanmean(run_vel_avg_fly); %group mean from individual fly's means
avgavgvel2 = avgavgvel2';

%average distance / run
avgrunlength = nanmean(all_distance_final,2);
%total time (should be same as period time)
totaltime = runsduration_total+stopduration_total;
%then save it for all periods
matfortotaltime = totaltime;


figure
set(gcf, 'Position',[300 10 800 900]);

for odorpd = 1:3
    
    %histogram and plotting
    avg_velocity_hist = (0:(2/40):2);
    durationsecs_hist = (0:(40/40):40);
    stopsecs_hist = (0:(20/40):20);
    runlength_hist = (0:(17/40):17);%for what?
    
    %run duration plot
    subplot(4,3,odorpd)
    
    cc = histc(all_runsduration_secs(odorpd,:),durationsecs_hist); %this gives actual n, occurrence
    cc1 = cc./total_run_no(odorpd);
    %     bar(durationsecs_hist, cc, 'histc'); hold on
    stairs(durationsecs_hist,cc1,'color',color(odorpd,:));hold on
    plot([avgrunduration(odorpd) avgrunduration(odorpd) ],[0 100],':','color',color(odorpd,:));
    
    xlim([0,20])
    ylim([0,.4]);
    xlabel('Run Duration (secs)');
    ylabel('probability');
    if odorpd ==1
        title({fig_title; period_name{odorpd};[' ']},'interpreter','none','fontweight','bold');
    elseif odorpd ==2
        title({[' '];period_name{odorpd};['Run Duration']},'interpreter','none','fontweight','bold');
    else
        title({period_name{odorpd};[' ']},'fontweight','bold');
    end
    
    text(5, .25, ['# Runs = ' num2str(numruns(odorpd))], 'FontSize', 8);
    text(5, .2, ['Avg. Run = ' num2str(avgrunduration(odorpd),'%4.2f') 's'], 'FontSize',8);
    text(5, .15, ['Total Run Time = ' num2str(runsduration_total(odorpd),'%4.2f') 's'], 'FontSize', 8);
    
    set(gca,'box','off');
    
    
    %stop duration plot
    subplot(4,3,(odorpd +3));
    
    cc = histc(all_stopsduration_secs(odorpd,:),stopsecs_hist);
    cc1 = cc./total_stop_no(odorpd);
    %     bar(stopsecs_hist, cc, 'histc');hold on
    stairs(stopsecs_hist,cc1,'color',color(odorpd,:));hold on
    
    plot([avgstopduration(odorpd) avgstopduration(odorpd)],[0 100],':','color',color(odorpd,:));
    
    xlim([0,20])
    ylim([0,.6])
    xlabel('Stops Duration (secs)');
    ylabel('probability');
    if odorpd ==2
        title('Stop Duration','fontweight','bold');
    end
    
    text(5, .3, ['# Stops = ' num2str(numstops(odorpd))], 'FontSize', 8);
    text(5, .37, ['Avg. Stop = ' num2str(avgstopduration(odorpd),'%4.2f') 's'], 'FontSize', 8);
    text(5, .44, ['Total Stop Time = ' num2str(stopduration_total(odorpd),'%4.2f') 's'], 'FontSize',8);
    set(gca,'box','off');
    
    
    
    %average velocity plot
    subplot(4,3,odorpd+6);
    %find out how many velocity events /odor period
    for i=1:3
        A = all_avg_velocity(i,:);
        n_velocity(i) = sum(~isnan(A));
    end
    cc = histc(all_avg_velocity(odorpd,:),avg_velocity_hist);
    cc1 = cc./n_velocity(odorpd);
    %     bar(avg_velocity_hist, cc, 'histc');    hold on;
    stairs(avg_velocity_hist, cc1,'color',color(odorpd,:)); hold on
    
    plot([avgavgvel(odorpd) avgavgvel(odorpd)],[0 100],':','color',color(odorpd,:));
    
    xlabel('avg. run velocity (cm/sec)');
    ylabel('probability');
    ylim ([0 .15]);
    xlim ([0 2]);
    if odorpd ==2
        title('Average velocity of runs','fontweight','bold');
    end
    
    text(.5, .13, ['avg. vel./run = ' num2str(avgavgvel(odorpd),'%4.2f') 'cm/sec'], 'fontsize', 8);
    text(.5, .11, ['avg. vel./all runs = ' num2str(avgavgvel2(odorpd),'%4.2f') 'cm/sec'], 'fontsize', 8);
    set(gca,'box','off');
    
    %     statistics_eachvid(odorpd,:) = {runsduration_secs, stopsduration_secs, avg_velocity, distance_final};
    %
    %     clear runsduration runsduration_secs distance_final avg_velocity stopsduration stopsduration_secs
    
end

% run duration: distribution among flies
subplot(4,3,10)
h = boxplot([runduration_secs_fly(:,1),runduration_secs_fly(:,2),runduration_secs_fly(:,3)],'color',[0 0 0]);hold on
%get median value of the 'before' run velocity
baseline = median(runduration_secs_fly(:,1));
plot([0 4],[baseline baseline],'k:');
%individual fly's runduration
for i=1:3
    plot(i,runduration_secs_fly(:,i),'.','color',color(i,:));
end
% ylabel('velocity')

ylim([0 15]); xlim([.5 3.5]);
title(['distribution of run duration (median)']);
set(gca,'Xtick',1:3,'XTickLabel',{'before','during','after'},'Ytick',0:5:100);
set(gca,'box','off');

% stop duration: distribution among flies
subplot(4,3,11)
h = boxplot([stopduration_secs_fly(:,1),stopduration_secs_fly(:,2),stopduration_secs_fly(:,3)],'color','k');hold on
%get median value of the 'before' run velocity
baseline = median(stopduration_secs_fly(:,1));
plot([0 4],[baseline baseline],'k:');
%individual fly's runduration
for i=1:3
    plot(i,stopduration_secs_fly(:,i),'.','color',color(i,:));
end
% ylabel('velocity')

ylim([0 5]); xlim([.5 3.5]);
title(['distribution of stop duration (median)']);
set(gca,'Xtick',1:3,'XTickLabel',{'before','during','after'},'Ytick',0:1:100);
set(gca,'box','off');

%run velocity: distribution among flies
subplot(4,3,12)

h=boxplot([run_vel_avg_fly(:,1),run_vel_avg_fly(:,2),run_vel_avg_fly(:,3)],'color',[0 0 0]);hold on
%get median value of the 'before' run velocity
baseline = median(run_vel_avg_fly(:,1));
plot([0 4],[baseline baseline],'k:');
% ylabel('velocity')
%individual fly's runduration
for i=1:3
    h=plot(i,run_vel_avg_fly(:,i),'.','color',color(i,:));
end
ylim([0 1.5]); xlim([.5 3.5]);
title(['distribution of run velocity (median)']);
set(gca,'Xtick',1:3,'XTickLabel',{'before','during','after'},'Ytick',0:.5:2);
set(gca,'box','off');

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

% run stop probability : in VS out

%get the mean velocity of individual fly (from all the runs grouped) then get the
%mean of means
run_vel_in_avg_fly = nan(numflies,2);
run_vel_out_avg_fly = nan(numflies,2);

for period =1:2
    for i=1:numflies
        %IN
        run_vel_all_cell = run_in_flies{i}{period}; run_vel_all_cell = run_vel_all_cell';
        run_vel_all = cell2mat(run_vel_all_cell);
        run_vel_in_avg_fly(i,period) = nanmean(run_vel_all); %individual fly's run vel average
        %OUT
        run_vel_all_cell = run_out_flies{i}{period}; run_vel_all_cell = run_vel_all_cell';
        run_vel_all = cell2mat(run_vel_all_cell);
        run_vel_out_avg_fly(i,period) = nanmean(run_vel_all); %individual fly's run vel average
    end
end
run_vel_in_avg_all_flies = nanmean(run_vel_in_avg_fly); %group mean from individual fly's means
run_vel_in_avg_all_flies = run_vel_in_avg_all_flies';
run_vel_out_avg_all_flies = nanmean(run_vel_out_avg_fly); %group mean from individual fly's means
run_vel_out_avg_all_flies = run_vel_out_avg_all_flies';
%median
run_vel_in_median_all_flies = nanmedian(run_vel_in_avg_fly); %group mean from individual fly's means
run_vel_in_median_all_flies = run_vel_in_median_all_flies';
run_vel_out_median_all_flies = nanmedian(run_vel_out_avg_fly); %group mean from individual fly's means
run_vel_out_median_all_flies = run_vel_out_median_all_flies';

%========================================================================
%combine all data and get means, these arrays contain all runs and stops
%from the group, not individual flies
%one thing to be cautious: since I made one matrix to save both 'before'
%and 'during' data, some elements are filled with '0' as place holders.
%These place holding zeros should not be included in histogram calculation!

run_in_secs_fly = nan(numflies,2);
run_out_secs_fly = nan(numflies,2);

%RUN
for period = 1:2
    %run, in
    run_num = 0; %counter that counts each run /'in'
    for fly=1:numflies
        A = run_in_flies{fly}{period};
        for x = 1:numel(A)
            AA = A{x}; %each run data
            if isempty(AA) ~= 1 %if the array is not empty
                run_num = run_num +1;
                run_in_duration(period, run_num) =  length(AA); %whole group fly data
                run_in_secs(period,run_num) = length(AA)/framespertimebin;
                run_vel_in(period,run_num) = mean(AA);
                run_in_distance(period,run_num) = mean(AA) * (length(AA)/framespertimebin);%velocity * time
                
                %individual fly's mean of run duration (sec)
                onefly_run(x) = length(AA)/framespertimebin;
            end
        end
        %for all the runs (in) / fly
        if exist('onefly_run') == 1 %if there is 'run' data in the 'in'
            run_in_secs_fly(fly,period) = nanmean(onefly_run);
            run_in_secs_fly_median(fly,period) = nanmedian(onefly_run);
            clear onefly_run
        end
    end
    run_num_in(period) = run_num;
    
    
    %run, out
    run_num = 0;
    for fly=1:numflies
        A = run_out_flies{fly}{period};
        for x = 1:numel(A)
            AA = A{x}; %each run data
            if isempty(AA) ~= 1
                run_num = run_num +1;
                run_out_duration(period,run_num) =  length(AA);
                run_out_secs(period,run_num) = length(AA)/framespertimebin;
                run_vel_out(period,run_num) = mean(AA);
                run_out_distance(period,run_num) = mean(AA) * (length(AA)/framespertimebin);
                %individual fly's mean of run duration (sec)
                onefly_run(x) = length(AA)/framespertimebin;
            end
        end
        
        if exist('onefly_run') ==1
            run_out_secs_fly(fly,period) = nanmean(onefly_run);
            clear onefly_run
        end
    end
    run_num_out(period) = run_num;
    
end

%get averages
for i=1:2
    %run duration (sec)
    run_in_secs_mean(i) = nanmean(run_in_secs(i,1:run_num_in(i)));
    run_in_secs_median(i) = nanmedian(run_in_secs(i,1:run_num_in(i)));
    run_in_secs_total(i) = sum(run_in_secs(i,1:run_num_in(i)));
    
    run_out_secs_mean(i) = nanmean(run_out_secs(i,1:run_num_out(i)));
    run_out_secs_median(i) = nanmedian(run_out_secs(i,1:run_num_out(i)));
    run_out_secs_total(i) = sum(run_out_secs(i,1:run_num_out(i)));
    
    %run distance (cm)
    run_in_duration_mean(i) = nanmean(run_in_duration(i,1:run_num_in(i)));
    run_in_duration_median(i) = nanmedian(run_in_duration(i,1:run_num_in(i)));
    run_in_duration_total(i) = sum(run_in_duration(i,1:run_num_in(i)));
    
    run_out_duration_mean(i) = nanmean(run_out_duration(i,1:run_num_out(i)));
    run_out_duration_median(i) = nanmedian(run_out_duration(i,1:run_num_out(i)));
    run_out_duration_total(i) = sum(run_out_duration(i,1:run_num_out(i)));
end


%stop======================================================================
stop_in_sec_fly = nan(numflies,2);
stop_out_sec_fly = nan(numflies,2);

for period = 1:2
    stop_num = 0; %set stop # as 0
    
    for fly=1:numflies
        A = stops_in_flies{fly}{period};
        for x = 1:numel(A)
            AA = A{x}; %each stop data
            if isempty(AA) ~= 1 %if the array is not empty
                %to exclude empty arrays created after vel_in_out_divider function
                stop_num = stop_num +1;
                stop_in_duration(period,stop_num) =  length(AA);
                stop_in_secs(period,stop_num) = length(AA)/framespertimebin;
                
                %individual fly's mean of stop uration
                onefly_stop(x) = length(AA)/framespertimebin;
            end
        end
        %for all the stops (in)/fly
        if exist('onefly_stop') ==1
            stop_in_sec_fly(fly,period) = nanmean(onefly_stop);
            clear onefly_stop
        end
    end
    stop_num_in(period) = stop_num;
    
    %stop, out
    stop_num = 0;
    for fly=1:numflies
        A = stops_out_flies{fly}{period};
        for x = 1:numel(A)
            AA = A{x}; %each stop data
            if isempty(AA) ~= 1
                stop_num = stop_num +1;
                stop_out_duration(period,stop_num) =  length(AA);
                stop_out_secs(period,stop_num) = length(AA)/framespertimebin;
                %individual fly's mean of stop uration
                onefly_stop(x) = length(AA)/framespertimebin;
            end
        end
        if exist('onefly_stop') ==1
            stop_out_sec_fly(fly,period) = nanmean(onefly_stop);
            clear onefly_stop
        end
        
    end
    stop_num_out(period) = stop_num;
end

%get averages
for i=1:2 %before and during
    stop_in_secs_mean(i) = nanmean(stop_in_secs(i,1:stop_num_in(i)));
    stop_in_secs_median(i) = nanmedian(stop_in_secs(i,1:stop_num_in(i)));
    stop_in_secs_total(i) = sum(stop_in_secs(i,1:stop_num_in(i)));
    
    stop_out_secs_mean(i) = mean(stop_out_secs(i,1:stop_num_out(i)));
    stop_out_secs_median(i) = nanmedian(stop_out_secs(i,1:stop_num_out(i)));
    stop_out_secs_total(i) = sum(stop_out_secs(i,1:stop_num_out(i)));
end

%==========================================================================

%histogram and plotting
avg_velocity_hist = (0:(2/40):2);
durationsecs_hist = (0:(40/40):40);
stopsecs_hist = (0:(20/40):20);
runlength_hist = (0:(17/40):17);%for what?


figure
set(gcf,'position',[300 10 1000 800])

for period= 1:2
    % run in
    subplot(4,4,period)
    
    AA = run_in_secs(period,1:run_num_in(period));
    
    cc = histc(AA,durationsecs_hist);
    cc1 = cc./run_num_in(period);
    stairs(durationsecs_hist,cc1,'color',color(period,:));hold on
    plot([run_in_secs_mean(period) run_in_secs_mean(period) ],[0 100],':','color',color(period,:));
    plot([run_in_secs_median(period) run_in_secs_median(period) ],[0 100],'color',grey);
    
    xlim([0,20])
    ylim([0,.6]);
    xlabel('Run Duration (secs)');
    ylabel('probability');
    if period ==1
        title({['Run Duration (IN)'];period_name{period}},'interpreter','none','fontweight','bold');
    elseif period ==2
        title({fig_title; period_name{period}},'interpreter','none','fontweight','bold')
    else
        title({period_name{period};[' ']},'fontweight','bold');
    end
    
    text(5, .5, ['# Runs = ' num2str(run_num_in(period))], 'FontSize', 8);
    text(5, .44, ['Avg. Run = ' num2str(run_in_secs_mean(period),'%4.2f') 's'], 'FontSize',8);
    text(5, .38, ['median Run = ' num2str(run_in_secs_median(period),'%4.2f') 's'], 'FontSize',8);
    text(5, .3, ['Avg. Run distance = ' num2str(run_in_secs_total(period),'%4.2f') 's'], 'FontSize', 8);
    text(5, .22, ['Total Run Time = ' num2str(run_in_secs_total(period),'%4.2f') 's'], 'FontSize', 8);
    
    set(gca,'box','off');
    
    % run out
    subplot(4,4,period+2)
    
    AA = run_out_secs(period,1:run_num_out(period));
    
    cc = histc(AA,durationsecs_hist);
    cc1 = cc./run_num_out(period);
    stairs(durationsecs_hist,cc1,'color',color(period,:));hold on
    plot([run_out_secs_mean(period) run_out_secs_mean(period) ],[0 100],':','color',color(period,:));
    plot([run_out_secs_median(period) run_out_secs_median(period) ],[0 100],'color',grey);
    
    xlim([0,20])
    ylim([0,.6]);
    xlabel('Run Duration (secs)');
    ylabel('probability');
    if period ==1
        title(['Run Duration (OUT)'],'interpreter','none','fontweight','bold');
    end
    
    text(5, .5, ['# Runs = ' num2str(run_num_out(period))], 'FontSize', 8);
    text(5, .44, ['Avg. Run = ' num2str(run_out_secs_mean(period),'%4.2f') 's'], 'FontSize',8);
    text(5, .38, ['median Run = ' num2str(run_out_secs_median(period),'%4.2f') 's'], 'FontSize',8);
    text(5, .3, ['Avg. Run distance = ' num2str(run_out_secs_total(period),'%4.2f') 's'], 'FontSize', 8);
    text(5, .22, ['Total Run Time = ' num2str(run_out_secs_total(period),'%4.2f') 's'], 'FontSize', 8);
    
    
    set(gca,'box','off');
    
    
    %stop, IN
    subplot(4,4,period+4)
    
    AA = stop_in_secs(period,1:stop_num_in(period));
    
    cc = histc(AA,stopsecs_hist);
    cc1 = cc./stop_num_in(period);
    %     bar(stopsecs_hist, cc, 'histc');hold on
    stairs(stopsecs_hist,cc1,'color',color(period,:));hold on
    
    plot([stop_in_secs_mean(period) stop_in_secs_mean(period)],[0 100],':','color',color(period,:));
    plot([stop_in_secs_median(period) stop_in_secs_median(period)],[0 100],'color',grey);
    
    xlim([0,20])
    ylim([0,.6])
    xlabel('Stops Duration (secs)');
    ylabel('probability');
    if period ==1
        title('Stop Duration(IN)','fontweight','bold');
    end
    
    text(5, .5, ['# Stops = ' num2str(stop_num_in(period))], 'FontSize', 8);
    text(5, .44, ['Avg. Stop = ' num2str(stop_in_secs_mean(period),'%4.2f') 's'], 'FontSize', 8);
    text(5, .38, ['median Stop = ' num2str(stop_in_secs_median(period),'%4.2f') 's'], 'FontSize', 8);
    text(5, .32, ['Total Stop Time = ' num2str(stop_in_secs_total(period),'%4.2f') 's'], 'FontSize',8);
    set(gca,'box','off');
    
    %stop, OUT
    subplot(4,4,period+6)
    
    AA = stop_out_secs(period,1:stop_num_out(period));
    
    cc = histc(AA,stopsecs_hist);
    cc1 = cc./stop_num_out(period);
    %     bar(stopsecs_hist, cc, 'histc');hold on
    stairs(stopsecs_hist,cc1,'color',color(period,:));hold on
    
    plot([stop_out_secs_mean(period) stop_out_secs_mean(period)],[0 100],':','color',color(period,:));
    plot([stop_out_secs_median(period) stop_out_secs_median(period)],[0 100],'color',grey);
    
    xlim([0,20])
    ylim([0,.6])
    xlabel('Stops Duration (secs)');
    ylabel('probability');
    if period ==1
        title('Stop Duration(OUT)','fontweight','bold');
    end
    
    text(5, .5, ['# Stops = ' num2str(stop_num_out(period))], 'FontSize', 8);
    text(5, .44, ['Avg. Stop = ' num2str(stop_out_secs_mean(period),'%4.2f') 's'], 'FontSize', 8);
    text(5, .38, ['median Stop = ' num2str(stop_out_secs_median(period),'%4.2f') 's'], 'FontSize', 8);
    text(5, .32, ['Total Stop Time = ' num2str(stop_out_secs_total(period),'%4.2f') 's'], 'FontSize',8);
    set(gca,'box','off');
    
    
    %run velocity , IN
    subplot(4,4,period+8)
    
    AA = run_vel_in(period,1:run_num_in(period));
    
    cc = histc(AA,avg_velocity_hist);
    cc1 = cc./run_num_in(period);
    %     bar(stopsecs_hist, cc, 'histc');hold on
    stairs(avg_velocity_hist,cc1,'color',color(period,:));hold on
    
    plot([mean(AA) mean(AA)],[0 100],':','color',color(period,:));
    
    xlim([0,2])
    ylim([0,.2])
    xlabel('velocity (cm/secs)');
    ylabel('probability');
    if period ==1
        title('Run velocity(IN)','fontweight','bold');
    end
    
    text(.2, .18, ['avg velocity = ' num2str(mean(AA),'%4.2f') 'cm/sec'], 'FontSize', 8);
    set(gca,'box','off');
    
    %run velocity , OUT
    subplot(4,4,period+10)
    
    AA = run_vel_out(period,1:run_num_out(period));
    
    cc = histc(AA,avg_velocity_hist);
    cc1 = cc./run_num_out(period);
    %     bar(stopsecs_hist, cc, 'histc');hold on
    stairs(avg_velocity_hist,cc1,'color',color(period,:));hold on
    
    plot([mean(AA) mean(AA)],[0 100],':','color',color(period,:));
    
    xlim([0,2])
    ylim([0,.2])
    xlabel('velocity (cm/secs)');
    ylabel('probability');
    if period ==1
        title('Run velocity(out)','fontweight','bold');
    end
    
    text(.2, .18, ['avg velocity = ' num2str(mean(AA),'%4.2f') 'cm/sec'], 'FontSize', 8);
    set(gca,'box','off');
    
end

%box plots for individual flies + group median

%run duration
subplot(4,4,13)
h = boxplot([run_in_secs_fly(:,1),run_in_secs_fly(:,2),...
    run_out_secs_fly(:,1),run_out_secs_fly(:,2)],'color',[0 0 0]);hold on

%get median value of the 'before' run velocity
baseline = median(run_in_secs_fly(:,1));
plot([0 5],[baseline baseline],'b:');

baseline = median(run_out_secs_fly(:,1));
plot([3 4],[baseline baseline],'k:');

%individual fly's runduration
for i=1:2
    plot(i,run_in_secs_fly(:,i),'.','color',color(i,:));
end

for i=1:2
    plot(i+2,run_out_secs_fly(:,i),'.','color',color(i,:));
end
% ylabel('velocity')

ylim([0 10]); xlim([.5 4.5]);
title(['Distribution of run duration']);
set(gca,'Xtick',1:4,'XTickLabel',{'before','during','before', 'during'},'Ytick',0:5:100,'tickdir','out');
set(gca,'box','off');
text(1.5, 9, ['IN'], 'FontSize', 8);
text(3.5, 9, ['OUT'], 'FontSize', 8);

%stop duration
subplot(4,4,14)
h = boxplot([stop_in_sec_fly(:,1),stop_in_sec_fly(:,2),...
    stop_out_sec_fly(:,1),stop_out_sec_fly(:,2)],'color',[0 0 0]);hold on

%get median value of the 'before' run velocity
baseline = nanmedian(stop_in_sec_fly(:,1));
plot([0 5],[baseline baseline],'b:');

baseline = nanmedian(stop_out_sec_fly(:,1));
plot([3 4],[baseline baseline],'k:');

%individual fly's runduration
for i=1:2
    plot(i,stop_in_sec_fly(:,i),'.','color',color(i,:));
end

for i=1:2
    plot(i+2,stop_out_sec_fly(:,i),'.','color',color(i,:));
end

ylim([0 10]); xlim([.5 4.5]);
title(['Distribution of stop duration']);
set(gca,'Xtick',1:4,'XTickLabel',{'before','during','before', 'during'},'Ytick',0:5:100,'tickdir','out');
set(gca,'box','off');
text(1.5, 9, ['IN'], 'FontSize', 8);
text(3.5, 9, ['OUT'], 'FontSize', 8);


% velocity: distribution among flies
subplot(4,4,15)
h = boxplot([run_vel_in_avg_fly(:,1),run_vel_in_avg_fly(:,2),...
    run_vel_out_avg_fly(:,1),run_vel_out_avg_fly(:,2)],'color',[0 0 0]);hold on

%get median value of the 'before' run velocity
baseline = median(run_vel_in_avg_fly(:,1));
plot([0 5],[baseline baseline],'b:');

baseline = median(run_vel_out_avg_fly(:,1));
plot([3 4],[baseline baseline],'k:');

%individual fly's run velocity
for i=1:2
    plot(i,run_vel_in_avg_fly(:,i),'.','color',color(i,:));
end

for i=1:2
    plot(i+2,run_vel_out_avg_fly(:,i),'.','color',color(i,:));
end

ylim([0 2]); xlim([.5 4.5]);
title(['Distribution of run velocity']);
set(gca,'Xtick',1:4,'XTickLabel',{'before','during','before', 'during'},'Ytick',0:1:100);
set(gca,'box','off');
text(1.5, 1.8, ['IN'], 'FontSize', 8);
text(3.5, 1.8, ['OUT'], 'FontSize', 8);


set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%========================================================================
%runs that are entirely in or out of IR (V20)
multiple_flies_run_in_out_stats_plotter;

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%========================================================================

% velocity at crossing plots
% first two rows show the individual flies' averages (means).
%**ALL THE FLIES!

%==========================================================================
%Various velocity plots mostly use the following functions to make one figure
% 1. duration : plots ind fly mean plots (before /during), group
% mean plot, binned mean with t-test results
% 2. velocity_normalizer : normalize the velocity data
% 3. bin_ttest : binning + t-test
% 4. velocity_multiplots2: plots normalized group means, binned+t-test results
%==========================================================================

vel_ylim = [0 2.5];
radvel_ylim = [0 2];

plots_row = 6;
plots_column = 2;
figure_title = [fig_title ' velocity at crossing (all the flie)'];

%plots the first four rows of subplots
velocity_multiplots1(velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr,...
    velocity_o2i_ind_avg_af,velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,...
    velocity_i2o_ind_avg_af,velocity_o2i_avg,velocity_i2o_avg,velocity_o2i_SEM,...
    velocity_i2o_SEM,vel_o2i_bin_mean,vel_i2o_bin_mean,...
    vel_o2i_bin_SEM,vel_i2o_bin_SEM,...
    vel_o2i_by_bin_h,vel_i2o_by_bin_h,...
    framespertimebin,how_long,x_range,bin_x,vel_unit,vel_ylim,crossing_min,numBins,...
    plots_row,plots_column);


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec (or frame_norm), then subtract from original
%velocity

%frame_norm defines which time period to use to set the baseline
% frame_norm =((timebefore-2)*framespertimebin +1):((timebefore-1)*framespertimebin);
frame_norm =(1:10);

[vel_norm_o2i_avg,vel_norm_i2o_avg,vel_norm_o2i_SEM,vel_norm_i2o_SEM,...
    vel_o2i_norm_before_flies,vel_o2i_norm_during_flies,vel_o2i_norm_after_flies,...
    vel_i2o_norm_before_flies,vel_i2o_norm_during_flies,vel_i2o_norm_after_flies] =...
    velocity_normalizer(velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr,velocity_o2i_ind_avg_af,...
    velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,velocity_i2o_ind_avg_af,...
    frame_norm,numflies);

%bin data and perform t-test for normalized data
[vel_norm_i2o_bin_mean,vel_norm_o2i_bin_mean,vel_norm_i2o_bin_SEM,vel_norm_o2i_bin_SEM,...
    vel_norm_i2o_by_bin_h,vel_norm_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    vel_i2o_norm_before_flies,vel_i2o_norm_during_flies,...
    vel_o2i_norm_before_flies,vel_o2i_norm_during_flies);

y_lim_for_plot = [-.6 .6];

%the rest of the figure
velocity_multiplots2(vel_norm_o2i_avg,vel_norm_i2o_avg,...
    vel_norm_o2i_SEM,vel_norm_i2o_SEM,...
    vel_norm_o2i_bin_mean,vel_norm_i2o_bin_mean,...
    vel_norm_o2i_by_bin_h,vel_norm_i2o_by_bin_h,...
    numBins,plots_row,plots_column,frame_norm,...
    framespertimebin,x_range,bin_x,how_long,y_lim_for_plot)

ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

% velocity at crossing plots, showing only flies that crossed more than 'crossing_min'

figure_title = [fig_title ' velocity at crossing: crossing >' num2str(crossing_min)];

%plots the first four rows of subplots
velocity_multiplots1(velocity_o2i_avg_bf_sel,velocity_o2i_avg_dr_sel,...
    velocity_o2i_avg_af_sel,velocity_i2o_avg_bf_sel,velocity_i2o_avg_dr_sel,...
    velocity_i2o_avg_af_sel,velocity_o2i_avg_sel,velocity_i2o_avg_sel,velocity_o2i_SEM_sel,...
    velocity_i2o_SEM_sel,vel_o2i_bin_mean_sel,vel_i2o_bin_mean_sel,...
    vel_o2i_bin_SEM_sel,vel_i2o_bin_SEM_sel,...
    vel_o2i_by_bin_h_sel,vel_i2o_by_bin_h_sel,...
    framespertimebin,how_long,x_range,bin_x,vel_unit,vel_ylim,crossing_min,numBins,...
    plots_row,plots_column);


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec (or frame_norm), then subtract from original
%velocity

%frame_norm defines which time period to use to set the baseline
% frame_norm =((timebefore-2)*framespertimebin +1):((timebefore-1)*framespertimebin);

[vel_norm_o2i_avg_sel,vel_norm_i2o_avg_sel,vel_norm_o2i_SEM_sel,vel_norm_i2o_SEM_sel,...
    vel_o2i_norm_before_flies_sel,vel_o2i_norm_during_flies_sel,vel_o2i_norm_after_flies_sel,...
    vel_i2o_norm_before_flies_sel,vel_i2o_norm_during_flies_sel,vel_i2o_norm_after_flies_sel] = ...
    velocity_normalizer(velocity_o2i_avg_bf_sel,velocity_o2i_avg_dr_sel,velocity_o2i_avg_af_sel,...
    velocity_i2o_avg_bf_sel,velocity_i2o_avg_dr_sel,velocity_i2o_avg_af_sel,...
    frame_norm,num_used_flies);

%bin data and perform t-test for normalized data
[vel_norm_i2o_bin_mean_sel,vel_norm_o2i_bin_mean_sel,vel_norm_i2o_bin_SEM_sel,vel_norm_o2i_bin_SEM_sel,...
    vel_norm_i2o_by_bin_h_sel,vel_norm_o2i_by_bin_h_sel]...
    = bin_ttest(numBins,whichBin,...
    vel_i2o_norm_before_flies_sel,vel_i2o_norm_during_flies_sel,...
    vel_o2i_norm_before_flies_sel,vel_o2i_norm_during_flies_sel);

y_lim_for_plot = [-.6 .6];

%the rest of the figure
velocity_multiplots2(vel_norm_o2i_avg_sel,vel_norm_i2o_avg_sel,...
    vel_norm_o2i_SEM_sel,vel_norm_i2o_SEM_sel,...
    vel_norm_o2i_bin_mean_sel,vel_norm_i2o_bin_mean_sel,...
    vel_norm_o2i_by_bin_h_sel,vel_norm_i2o_by_bin_h_sel,...
    numBins,plots_row,plots_column,frame_norm,...
    framespertimebin,x_range,bin_x,how_long,y_lim_for_plot)

ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

%save
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

% velocity at crossing : pooled by location / bin#

figure_title = [fig_title ' velocity at crossing VS location (all the flies)'];

figure
set(gcf,'color','white','Position',[520 20 700 800]);
%for crossing out2in
for i=1:2 %before and during only
    
    subplot(3,2,2*i-1)
    for h = 1:numflies
        p = rem(h,20)+1;
        plot (location_o2i_vel_crossing{i,h},'color', cmap(p,:));hold on
    end
    
    plot(vel_location_o2i_mean(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([1 total_bin_count]);
    ylim ([0 vel_ylim(2)])
    plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
    
    if i==1
        title(['Crossing in: ' period_name{i} ' (fly#=' num2str(numflies) ')'],'fontsize',9);
    else
        title(period_name{i});
    end
    xlabel('location (bin#)','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
    
end


%for crossing in2out:
for i=1:2 %before and during only
    
    subplot(3,2,2*i)
    for h = 1:numflies
        p = rem(h,20)+1;
        plot (location_i2o_vel_crossing{i,h},'color', cmap(p,:));hold on
        
    end
    
    plot(vel_location_i2o_mean(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([1 total_bin_count]);
    ylim ([0 vel_ylim(2)])
    plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
    if i==1
        title(['Crossing Out: ' period_name{i}],'fontsize',9);
    else
        title(period_name{i});
    end
    xlabel('location (bin#)','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
    
end


%one sample, ttest to compare before VS during velocity in the same
%locations
%pre-allocate
vel_location_i2o_by_bin_h = nan(1,total_bin_count);
vel_location_i2o_by_bin_p = nan(1,total_bin_count);
vel_location_i2o_by_bin_ci = nan(2,total_bin_count);
vel_location_o2i_by_bin_h = nan(1,total_bin_count);
vel_location_o2i_by_bin_p = nan(1,total_bin_count);
vel_location_o2i_by_bin_ci = nan(2,total_bin_count);

for i=1:total_bin_count
    [h, p, ci] = ttest(vel_location_i2o_mean_bf(i,:),vel_location_i2o_mean_dr(i,:));
    vel_location_i2o_by_bin_h(i) = h;
    vel_location_i2o_by_bin_p(i) = p;
    vel_location_i2o_by_bin_ci(:,i) = ci;
    
    [h, p, ci] = ttest(vel_location_o2i_mean_bf(i,:),vel_location_o2i_mean_dr(i,:));
    vel_location_o2i_by_bin_h(i) = h;
    vel_location_o2i_by_bin_p(i) = p;
    vel_location_o2i_by_bin_ci(:,i) = ci;
end


%average + SEM
vel_location_o2i_avg_trans = vel_location_o2i_mean';
vel_location_o2i_SEM_trans = vel_location_o2i_SEM';
vel_location_i2o_avg_trans = vel_location_i2o_mean';
vel_location_i2o_SEM_trans = vel_location_i2o_SEM';

subplot(3,2,5)
for i=1:2
    %find non-nan elements only
    avg_to_plot = vel_location_o2i_avg_trans(i,~isnan(vel_location_o2i_avg_trans(i,:)));
    SEM_to_plot = vel_location_o2i_SEM_trans(i,~isnan(vel_location_o2i_SEM_trans(i,:)));
    
    SEM_y_plot = [avg_to_plot- SEM_to_plot;(2*SEM_to_plot)];
    h = area([1:size(SEM_y_plot,2)],SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(vel_location_o2i_mean(:,i),'color',color(i,:),'linewidth',1.5); hold on
end

%mark bin#/locations where velocity difference is significant
for bin_no= 1:total_bin_count
    if vel_location_o2i_by_bin_h(bin_no) ==1
        text(bin_no,vel_location_o2i_mean(bin_no,2)+.05, '*','fontsize',12);
    end
end
xlim([1 total_bin_count]);
ylim ([0 vel_ylim(2)-1])
plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing in');

subplot(3,2,6)
for i=1:2
    avg_to_plot = vel_location_i2o_avg_trans(i,~isnan(vel_location_i2o_avg_trans(i,:)));
    SEM_to_plot = vel_location_i2o_SEM_trans(i,~isnan(vel_location_i2o_SEM_trans(i,:)));
    
    SEM_y_plot = [avg_to_plot- SEM_to_plot;(2*SEM_to_plot)];
    h = area([1:size(SEM_y_plot,2)],SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(vel_location_i2o_mean(:,i),'color',color(i,:),'linewidth',1.5); hold on
end
%mark bin#/locations where velocity difference is significant
for bin_no= 1:total_bin_count
    if vel_location_i2o_by_bin_h(bin_no) ==1
        text(bin_no,vel_location_i2o_mean(bin_no,2)+.05, '*','fontsize',12);
    end
end
xlim([1 total_bin_count]);
ylim ([0 vel_ylim(2)-1])
plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing out');

ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

%save
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

% velocity at crossing : pooled by location / bin#

figure_title = [fig_title ' velocity at crossing VS location (crossing #>'  num2str(crossing_min) ')'];

figure
set(gcf,'color','white','Position',[520 20 700 800]);
%for crossing out2in
for i=1:2 %before and during only
    
    subplot(3,2,2*i-1)
    for h = flies_used
        p = rem(h,20)+1;
        plot (location_o2i_vel_crossing{i,h},'color', cmap(p,:));hold on
    end
    
    plot(vel_location_o2i_mean_sel(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([1 total_bin_count]);
    ylim ([0 vel_ylim(2)])
    plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
    
    if i==1
        title(['Crossing in: ' period_name{i} ' (fly#=' num2str(num_used_flies) ')'],'fontsize',9);
    else
        title(period_name{i});
    end
    xlabel('location (bin#)','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
    
end


%for crossing in2out:
for i=1:2 %before and during only
    
    subplot(3,2,2*i)
    for h = flies_used
        p = rem(h,20)+1;
        plot (location_i2o_vel_crossing{i,h},'color', cmap(p,:));hold on
        
    end
    
    plot(vel_location_i2o_mean_sel(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([1 total_bin_count]);
    ylim ([0 vel_ylim(2)])
    plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
    if i==1
        title(['Crossing Out: ' period_name{i}],'fontsize',9);
    else
        title(period_name{i});
    end
    xlabel('location (bin#)','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
    
end


%one sample, ttest to compare before VS during velocity in the same
%locations
%pre-allocate
vel_location_i2o_by_bin_h_sel = nan(1,total_bin_count);
vel_location_i2o_by_bin_p_sel = nan(1,total_bin_count);
vel_location_i2o_by_bin_ci_sel = nan(2,total_bin_count);
vel_location_o2i_by_bin_h_sel = nan(1,total_bin_count);
vel_location_o2i_by_bin_p_sel = nan(1,total_bin_count);
vel_location_o2i_by_bin_ci_sel = nan(2,total_bin_count);

vel_location_i2o_mean_bf_sel = vel_location_i2o_mean_bf(:,flies_used);
vel_location_i2o_mean_dr_sel = vel_location_i2o_mean_dr(:,flies_used);
vel_location_o2i_mean_bf_sel = vel_location_o2i_mean_bf(:,flies_used);
vel_location_o2i_mean_dr_sel = vel_location_o2i_mean_dr(:,flies_used);

for i=1:total_bin_count
    [h, p, ci] = ttest(vel_location_i2o_mean_bf_sel(i,:),vel_location_i2o_mean_dr_sel(i,:));
    vel_location_i2o_by_bin_h_sel(i) = h;
    vel_location_i2o_by_bin_p_sel(i) = p;
    vel_location_i2o_by_bin_ci_sel(:,i) = ci;
    
    [h, p, ci] = ttest(vel_location_o2i_mean_bf_sel(i,:),vel_location_o2i_mean_dr_sel(i,:));
    vel_location_o2i_by_bin_h_sel(i) = h;
    vel_location_o2i_by_bin_p_sel(i) = p;
    vel_location_o2i_by_bin_ci_sel(:,i) = ci;
end


%average + SEM
vel_location_o2i_avg_trans = vel_location_o2i_mean_sel';
vel_location_o2i_SEM_trans = vel_location_o2i_SEM_sel';
vel_location_i2o_avg_trans = vel_location_i2o_mean_sel';
vel_location_i2o_SEM_trans = vel_location_i2o_SEM_sel';

subplot(3,2,5)
for i=1:2
    %find non-nan elements only
    avg_to_plot = vel_location_o2i_avg_trans(i,~isnan(vel_location_o2i_avg_trans(i,:)));
    SEM_to_plot = vel_location_o2i_SEM_trans(i,~isnan(vel_location_o2i_SEM_trans(i,:)));
    
    SEM_y_plot = [avg_to_plot- SEM_to_plot;(2*SEM_to_plot)];
    h = area([1:size(SEM_y_plot,2)],SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(vel_location_o2i_mean_sel(:,i),'color',color(i,:),'linewidth',1.5); hold on
end

%mark bin#/locations where velocity difference is significant
for bin_no= 1:total_bin_count
    if vel_location_o2i_by_bin_h_sel(bin_no) ==1
        text(bin_no,vel_location_o2i_mean_sel(bin_no,2)+.05, '*','fontsize',12);
    end
end
xlim([1 total_bin_count]);
ylim ([0 vel_ylim(2)-1])
plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing in');

subplot(3,2,6)
for i=1:2
    avg_to_plot = vel_location_i2o_avg_trans(i,~isnan(vel_location_i2o_avg_trans(i,:)));
    SEM_to_plot = vel_location_i2o_SEM_trans(i,~isnan(vel_location_i2o_SEM_trans(i,:)));
    
    SEM_y_plot = [avg_to_plot- SEM_to_plot;(2*SEM_to_plot)];
    h = area([1:size(SEM_y_plot,2)],SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(vel_location_i2o_mean_sel(:,i),'color',color(i,:),'linewidth',1.5); hold on
end
%mark bin#/locations where velocity difference is significant
for bin_no= 1:total_bin_count
    if vel_location_i2o_by_bin_h_sel(bin_no) ==1
        text(bin_no,vel_location_i2o_mean_sel(bin_no,2)+.05, '*','fontsize',12);
    end
end
xlim([1 total_bin_count]);
ylim ([0 vel_ylim(2)-1])
plot([bin_number bin_number],[0 2],'k:') %dotted line marking IR
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing out');

axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

%save
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

% velocity at crossing : only those crossings when flies walked outside 1.4
%or 1.5 cm

%ALL FLIES
figure_title = [fig_title ' velocity going beyond ' num2str(crossing_threshold) 'cm (all the flie)'];

%plots the first four rows of subplots
velocity_multiplots1(velocity_o2i_th_ind_avg_bf,velocity_o2i_th_ind_avg_dr,...
    velocity_o2i_th_ind_avg_af,velocity_i2o_th_ind_avg_bf,velocity_i2o_th_ind_avg_dr,...
    velocity_i2o_th_ind_avg_af,vel_o2i_th_avg,vel_i2o_th_avg,vel_o2i_th_SEM,...
    vel_i2o_th_SEM,vel_th_o2i_bin_mean,vel_th_i2o_bin_mean,...
    vel_th_o2i_bin_SEM,vel_th_i2o_bin_SEM,...
    vel_th_o2i_by_bin_h,vel_th_i2o_by_bin_h,...
    framespertimebin,how_long,x_range,bin_x,vel_unit,vel_ylim,crossing_min,numBins,...
    plots_row,plots_column);


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec (or frame_norm), then subtract from original
%velocity

%frame_norm defines which time period to use to set the baseline
% frame_norm =((timebefore-2)*framespertimebin +1):((timebefore-1)*framespertimebin);

[vel_th_norm_o2i_avg,vel_th_norm_i2o_avg,vel_th_norm_o2i_SEM,vel_th_norm_i2o_SEM,...
    vel_th_o2i_norm_before_flies,vel_th_o2i_norm_during_flies,vel_th_o2i_norm_after_flies,...
    vel_th_i2o_norm_before_flies,vel_th_i2o_norm_during_flies,vel_th_i2o_norm_after_flies] =...
    velocity_normalizer(velocity_o2i_th_ind_avg_bf,velocity_o2i_th_ind_avg_dr,velocity_o2i_th_ind_avg_af,...
    velocity_i2o_th_ind_avg_bf,velocity_i2o_th_ind_avg_dr,velocity_i2o_th_ind_avg_af,...
    frame_norm,numflies);

%bin data and perform t-test for normalized data
[vel_th_norm_i2o_bin_mean,vel_th_norm_o2i_bin_mean,vel_th_norm_i2o_bin_SEM,vel_th_norm_o2i_bin_SEM,...
    vel_th_norm_i2o_by_bin_h,vel_th_norm_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    vel_th_i2o_norm_before_flies,vel_th_i2o_norm_during_flies,...
    vel_th_o2i_norm_before_flies,vel_th_o2i_norm_during_flies);

y_lim_for_plot = [-.6 .6];

%the rest of the figure
velocity_multiplots2(vel_th_norm_o2i_avg,vel_th_norm_i2o_avg,...
    vel_th_norm_o2i_SEM,vel_th_norm_i2o_SEM,...
    vel_th_norm_o2i_bin_mean,vel_th_norm_i2o_bin_mean,...
    vel_th_norm_o2i_by_bin_h,vel_th_norm_i2o_by_bin_h,...
    numBins,plots_row,plots_column,frame_norm,...
    framespertimebin,x_range,bin_x,how_long,y_lim_for_plot)

axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

%save
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

%velocity at crossing : only those crossings when flies walked outside 1.4
%or 1.5 cm

%selected flies that crossed more than crossing_min
figure_title = [fig_title ' velocity going beyond ' num2str(crossing_threshold) 'cm (selected flie)'];

%plots the first four rows of subplots
velocity_multiplots1(velocity_o2i_th_ind_avg_bf_sel,velocity_o2i_th_ind_avg_dr_sel,...
    velocity_o2i_th_ind_avg_af_sel,velocity_i2o_th_ind_avg_bf_sel,velocity_i2o_th_ind_avg_dr_sel,...
    velocity_i2o_th_ind_avg_af_sel,vel_o2i_th_avg_sel,vel_i2o_th_avg_sel,vel_o2i_th_SEM_sel,...
    vel_i2o_th_SEM_sel,vel_th_o2i_bin_mean_sel,vel_th_i2o_bin_mean_sel,...
    vel_th_o2i_bin_SEM_sel,vel_th_i2o_bin_SEM_sel,...
    vel_th_o2i_by_bin_h_sel,vel_th_i2o_by_bin_h_sel,...
    framespertimebin,how_long,x_range,bin_x,vel_unit,vel_ylim,crossing_min,numBins,...
    plots_row,plots_column);


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec (or frame_norm), then subtract from original
%velocity

%frame_norm defines which time period to use to set the baseline
% frame_norm =((timebefore-2)*framespertimebin +1):((timebefore-1)*framespertimebin);
how_many =size(velocity_o2i_th_ind_avg_bf_sel,2);

[vel_th_norm_o2i_avg_sel,vel_th_norm_i2o_avg_sel,vel_th_norm_o2i_SEM_sel,vel_th_norm_i2o_SEM_sel,...
    vel_th_o2i_norm_before_flies_sel,vel_th_o2i_norm_during_flies_sel,vel_th_o2i_norm_after_flies_sel,...
    vel_th_i2o_norm_before_flies_sel,vel_th_i2o_norm_during_flies_sel,vel_th_i2o_norm_after_flies_sel] =...
    velocity_normalizer(velocity_o2i_th_ind_avg_bf_sel,velocity_o2i_th_ind_avg_dr_sel,velocity_o2i_th_ind_avg_af_sel,...
    velocity_i2o_th_ind_avg_bf_sel,velocity_i2o_th_ind_avg_dr_sel,velocity_i2o_th_ind_avg_af_sel,...
    frame_norm,how_many);

%bin data and perform t-test for normalized data
[vel_th_norm_i2o_bin_mean_sel,vel_th_norm_o2i_bin_mean_sel,...
    vel_th_norm_i2o_bin_SEM_sel,vel_th_norm_o2i_bin_SEM_sel,...
    vel_th_norm_i2o_by_bin_h_sel,vel_th_norm_o2i_by_bin_h_sel]...
    = bin_ttest(numBins,whichBin,...
    vel_th_i2o_norm_before_flies_sel,vel_th_i2o_norm_during_flies_sel,...
    vel_th_o2i_norm_before_flies_sel,vel_th_o2i_norm_during_flies_sel);

y_lim_for_plot = [-.6 .6];

%the rest of the figure
velocity_multiplots2(vel_th_norm_o2i_avg_sel,vel_th_norm_i2o_avg_sel,...
    vel_th_norm_o2i_SEM_sel,vel_th_norm_i2o_SEM_sel,...
    vel_th_norm_o2i_bin_mean_sel,vel_th_norm_i2o_bin_mean_sel,...
    vel_th_norm_o2i_by_bin_h_sel,vel_th_norm_i2o_by_bin_h_sel,...
    numBins,plots_row,plots_column,frame_norm,...
    framespertimebin,x_range,bin_x,how_long,y_lim_for_plot)

axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

%save
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');



%========================================================================

% plot velocity at crossing : short  VS long
%Out2In only(did not select for 'crossing_min')
% only shows the mean + SEM plots, no binned data

figure
set(gcf,'color','white','Position',[520 20 700 750]);

period_name = {'Before','During','After'};

%for crossing out2in
for i=1:2
    subplot(4,2,2*i-1)
    if i==1 %before
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_o2i_sh_mean_bf(:,h) ,'color', cmap(p,:))
            hold on
        end
    elseif i==2 %during
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_o2i_sh_mean_dr(:,h) ,'color', cmap(p,:))
            hold on
        end
        
    else %after
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_o2i_sh_mean_af(:,h) ,'color', cmap(p,:))
            hold on
        end
    end
    plot(x_range,vel_sh_i2o_avg(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([min(x_range) max(x_range)+1/framespertimebin]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    title([period_name{i} ': Short Crossing In (shorter than ' num2str(how_short/framespertimebin) ' sec)'],'fontsize',9);
    %     xlabel('frame number','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
end


%for crossing out2in, LONG
for i=1:2
    subplot(4,2,2*i)
    if i==1 %before
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_o2i_lg_mean_bf(:,h) ,'color', cmap(p,:))
            hold on
        end
    elseif i==2 %during
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_o2i_lg_mean_dr(:,h) ,'color', cmap(p,:))
            hold on
        end
        
    else %after
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_o2i_lg_mean_af(:,h) ,'color', cmap(p,:))
            hold on
        end
    end
    plot(x_range,vel_lg_o2i_avg(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([min(x_range) max(x_range)+1/framespertimebin]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    title([period_name{i} ': Long Crossing In (longer than ' num2str(how_short/framespertimebin) ' sec)'],'fontsize',9);
    %     xlabel('frame number','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
end

%group mean + SEM plot

vel_sh_o2i_avg_trans = vel_sh_o2i_avg';
vel_sh_o2i_SEM_trans = vel_sh_o2i_SEM';
vel_lg_o2i_avg_trans = vel_lg_o2i_avg';
vel_lg_o2i_SEM_trans = vel_lg_o2i_SEM';

subplot(4,2,5)
for i=1:2
    SEM_y_plot_temp = [vel_sh_o2i_avg_trans(i,:)- vel_sh_o2i_SEM_trans(i,:);(2*vel_sh_o2i_SEM_trans(i,:))];
    %get rid of nans
    real_number =~isnan(SEM_y_plot_temp(1,:));
    x_length = sum(real_number);
    SEM_y_plot = SEM_y_plot_temp(1:2,1:x_length);
    
    h = area(x_range(1:x_length),SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    
    plot(x_range,vel_sh_o2i_avg(:,i),'linewidth',1.5,'color',color(i,:));
end
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
title('mean of means: short crossings','fontsize',9);
ylabel(vel_unit,'fontsize',9);
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');

subplot(4,2,6)
for i=1:2
    SEM_y_plot_temp = [vel_lg_o2i_avg_trans(i,:)- vel_lg_o2i_SEM_trans(i,:);(2*vel_lg_o2i_SEM_trans(i,:))];
    %get rid of nans
    real_number =~isnan(SEM_y_plot_temp(1,:));
    x_length = sum(real_number);
    SEM_y_plot = SEM_y_plot_temp(1:2,1:x_length);
    
    h = area(x_range(1:x_length),SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    
    plot(x_range,vel_lg_o2i_avg(:,i),'linewidth',1.5,'color',color(i,:));
end
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
title('mean of means: long crossings','fontsize',9);
ylabel(vel_unit,'fontsize',9);
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec, then subtract from original
%velocity
[vel_norm_o2i_sh,vel_norm_o2i_lg,vel_norm_o2i_sh_SEM,vel_norm_o2i_lg_SEM] =...
    velocity_normalizer(vel_o2i_sh_mean_bf,vel_o2i_sh_mean_dr,vel_o2i_sh_mean_af,...
    vel_o2i_lg_mean_bf,vel_o2i_lg_mean_dr,vel_o2i_lg_mean_af,...
    frame_norm,numflies);

y_lim_for_plot = [-.6 .6];

subplot(4,2,7)
vel_norm_o2i_sh_trans = vel_norm_o2i_sh';
vel_norm_o2i_sh_SEM_trans = vel_norm_o2i_sh_SEM';

for i=1:2
    SEM_y_plot_temp = [vel_norm_o2i_sh_trans(i,:)- vel_norm_o2i_sh_SEM_trans(i,:);(2*vel_norm_o2i_sh_SEM_trans(i,:))];
    %get rid of nans
    real_number =~isnan(SEM_y_plot_temp(1,:));
    x_length = sum(real_number);
    SEM_y_plot = SEM_y_plot_temp(1:2,1:x_length);
    
    h = area(x_range(1:x_length),SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(x_range,vel_norm_o2i_sh(:,i),'color',color(i,:),'linewidth',1.5)
end

plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')

xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('normalized from average of an individual fly');

subplot(4,2,8)

vel_norm_o2i_lg_trans = vel_norm_o2i_lg';
vel_norm_o2i_lg_SEM_trans = vel_norm_o2i_lg_SEM';

for i=1:2
    SEM_y_plot = [vel_norm_o2i_lg_trans(i,:)- vel_norm_o2i_lg_SEM_trans(i,:);(2*vel_norm_o2i_lg_SEM_trans(i,:))];
    h = area(x_range,SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(x_range,vel_norm_o2i_lg(:,i),'color',color(i,:),'linewidth',1.5)
end

plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')

xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');

title(['normalized for frames ' num2str(frame_norm(1)) ' to ' num2str(frame_norm(end))]);

%The title for the whole plots
axes('position',[0,0,1,1],'visible','off');
tx = text(0.2,0.97,[fig_title ' velocity (short and long) Out2In crossing events']);
set(tx,'fontweight','bold');

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');



%========================================================================

% plot velocity at crossing : short  VS long
% In2OUt (did not select for 'crossing_min')
% only shows the mean + SEM plots, no binned data

figure
set(gcf,'color','white','Position',[520 20 700 750]);

period_name = {'Before','During','After'};

%for crossing out2in
for i=1:2
    subplot(4,2,2*i-1)
    if i==1 %before
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_i2o_sh_mean_bf(:,h) ,'color', cmap(p,:))
            hold on
        end
    elseif i==2 %during
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_i2o_sh_mean_dr(:,h) ,'color', cmap(p,:))
            hold on
        end
        
    else %after
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_i2o_sh_mean_af(:,h) ,'color', cmap(p,:))
            hold on
        end
    end
    plot(x_range,vel_sh_i2o_avg(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([min(x_range) max(x_range)+1/framespertimebin]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    title([period_name{i} ': Short Crossing In (shorter than ' num2str(how_short/framespertimebin) ' sec)'],'fontsize',9);
    %     xlabel('frame number','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
end


%for crossing out2in, LONG
for i=1:2
    subplot(4,2,2*i)
    if i==1 %before
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_i2o_lg_mean_bf(:,h) ,'color', cmap(p,:))
            hold on
        end
    elseif i==2 %during
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_i2o_lg_mean_dr(:,h) ,'color', cmap(p,:))
            hold on
        end
        
    else %after
        for h = 1:numflies;
            p = rem(h,20)+1;
            plot (x_range,vel_i2o_lg_mean_af(:,h) ,'color', cmap(p,:))
            hold on
        end
    end
    plot(x_range,vel_lg_i2o_avg(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([min(x_range) max(x_range)+1/framespertimebin]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    title([period_name{i} ': Long Crossing In (longer than ' num2str(how_short/framespertimebin) ' sec)'],'fontsize',9);
    %     xlabel('frame number','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
end

%group mean + SEM plot

vel_sh_i2o_avg_trans = vel_sh_i2o_avg';
vel_sh_i2o_SEM_trans = vel_sh_i2o_SEM';
vel_lg_i2o_avg_trans = vel_lg_i2o_avg';
vel_lg_i2o_SEM_trans = vel_lg_i2o_SEM';

subplot(4,2,5)
for i=1:2
    SEM_y_plot_temp = [vel_sh_i2o_avg_trans(i,:)- vel_sh_i2o_SEM_trans(i,:);(2*vel_sh_i2o_SEM_trans(i,:))];
    %get rid of nans
    real_number =~isnan(SEM_y_plot_temp(1,:));
    x_length = sum(real_number);
    SEM_y_plot = SEM_y_plot_temp(1:2,1:x_length);
    if x_length ~= 0
        h = area(x_range(1:x_length),SEM_y_plot');
        set(h(1),'visible','off');
        set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
        alpha(.2);
    end
    hold on
    
    plot(x_range,vel_sh_i2o_avg(:,i),'linewidth',1.5,'color',color(i,:));
end
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
title('mean of means: short crossings','fontsize',9);
ylabel(vel_unit,'fontsize',9);
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');

subplot(4,2,6)
for i=1:2
    SEM_y_plot_temp = [vel_lg_i2o_avg_trans(i,:)- vel_lg_i2o_SEM_trans(i,:);(2*vel_lg_i2o_SEM_trans(i,:))];
    %get rid of nans
    real_number =~isnan(SEM_y_plot_temp(1,:));
    x_length = sum(real_number);
    SEM_y_plot = SEM_y_plot_temp(1:2,1:x_length);
    
    h = area(x_range(1:x_length),SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    
    plot(x_range,vel_lg_i2o_avg(:,i),'linewidth',1.5,'color',color(i,:));
end
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
title('mean of means: long crossings','fontsize',9);
ylabel(vel_unit,'fontsize',9);
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec, then subtract from original
%velocity
[vel_norm_i2o_sh,vel_norm_i2o_lg,vel_norm_i2o_sh_SEM,vel_norm_i2o_lg_SEM] =...
    velocity_normalizer(vel_i2o_sh_mean_bf,vel_i2o_sh_mean_dr,vel_i2o_sh_mean_af,...
    vel_i2o_lg_mean_bf,vel_i2o_lg_mean_dr,vel_i2o_lg_mean_af,...
    frame_norm,numflies);

y_lim_for_plot = [-.6 .6];

subplot(4,2,7)
vel_norm_i2o_sh_trans = vel_norm_i2o_sh';
vel_norm_i2o_sh_SEM_trans = vel_norm_i2o_sh_SEM';

for i=1:2
    SEM_y_plot_temp = [vel_norm_i2o_sh_trans(i,:)- vel_norm_i2o_sh_SEM_trans(i,:);(2*vel_norm_i2o_sh_SEM_trans(i,:))];
    %get rid of nans
    real_number =~isnan(SEM_y_plot_temp(1,:));
    x_length = sum(real_number);
    SEM_y_plot = SEM_y_plot_temp(1:2,1:x_length);
    if x_length ~= 0
        h = area(x_range(1:x_length),SEM_y_plot');
        set(h(1),'visible','off');
        set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
        alpha(.2);
    end
    hold on
    plot(x_range,vel_norm_i2o_sh(:,i),'color',color(i,:),'linewidth',1.5)
end

plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')

xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('normalized from average of an individual fly');

subplot(4,2,8)

vel_norm_i2o_lg_trans = vel_norm_i2o_lg';
vel_norm_i2o_lg_SEM_trans = vel_norm_i2o_lg_SEM';

for i=1:2
    SEM_y_plot = [vel_norm_i2o_lg_trans(i,:)- vel_norm_i2o_lg_SEM_trans(i,:);(2*vel_norm_i2o_lg_SEM_trans(i,:))];
    h = area(x_range,SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(x_range,vel_norm_i2o_lg(:,i),'color',color(i,:),'linewidth',1.5)
end

plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')

xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');

title(['normalized for frames ' num2str(frame_norm(1)) ' to ' num2str(frame_norm(end))]);

%The title for the whole plots
axes('position',[0,0,1,1],'visible','off');
tx = text(0.2,0.97,[fig_title ' velocity (short and long) In2Out crossing events']);
set(tx,'fontweight','bold');

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

% Radial velocity at crossing
%**ALL THE FLIES!

figure_title = [fig_title ' radial velocity at crossing (all the flie)'];
radvel_ylim = [0 1];

%plots the first four rows of subplots
velocity_multiplots1(radvel_o2i_ind_avg_bf,radvel_o2i_ind_avg_dr,...
    radvel_o2i_ind_avg_af,radvel_i2o_ind_avg_bf,radvel_i2o_ind_avg_dr,...
    radvel_i2o_ind_avg_af,radvel_o2i_avg,radvel_i2o_avg,radvel_o2i_SEM,...
    radvel_i2o_SEM,radvel_o2i_bin_mean,radvel_i2o_bin_mean,...
    radvel_o2i_bin_SEM,radvel_i2o_bin_SEM,...
    radvel_o2i_by_bin_h,radvel_i2o_by_bin_h,...
    framespertimebin,how_long,x_range,bin_x,vel_unit,radvel_ylim,crossing_min,numBins,...
    plots_row,plots_column);


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec (or frame_norm), then subtract from original
%velocity

%frame_norm defines which time period to use to set the baseline
% frame_norm =((timebefore-2)*framespertimebin +1):((timebefore-1)*framespertimebin);

[radvel_norm_o2i_avg,radvel_norm_i2o_avg,radvel_norm_o2i_SEM,radvel_norm_i2o_SEM,...
    radvel_o2i_norm_before_flies,radvel_o2i_norm_during_flies,radvel_o2i_norm_after_flies,...
    radvel_i2o_norm_before_flies,radvel_i2o_norm_during_flies,radvel_i2o_norm_after_flies] =...
    velocity_normalizer(radvel_o2i_ind_avg_bf,radvel_o2i_ind_avg_dr,radvel_o2i_ind_avg_af,...
    radvel_i2o_ind_avg_bf,radvel_i2o_ind_avg_dr,radvel_i2o_ind_avg_af,...
    frame_norm,numflies);

%bin data and perform t-test for normalized data
[radvel_norm_i2o_bin_mean,radvel_norm_o2i_bin_mean,radvel_norm_i2o_bin_SEM,radvel_norm_o2i_bin_SEM,...
    radvel_norm_i2o_by_bin_h,radvel_norm_o2i_by_bin_h]...
    = bin_ttest(numBins,whichBin,...
    radvel_i2o_norm_before_flies,radvel_i2o_norm_during_flies,...
    radvel_o2i_norm_before_flies,radvel_o2i_norm_during_flies);

y_lim_for_plot = [-.4 .4];

%the rest of the figure
velocity_multiplots2(radvel_norm_o2i_avg,radvel_norm_i2o_avg,...
    radvel_norm_o2i_SEM,radvel_norm_i2o_SEM,...
    radvel_norm_o2i_bin_mean,radvel_norm_i2o_bin_mean,...
    radvel_norm_o2i_by_bin_h,radvel_norm_i2o_by_bin_h,...
    numBins,plots_row,plots_column,frame_norm,...
    framespertimebin,x_range,bin_x,how_long,y_lim_for_plot)

axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

%save
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================

% Radial velocity at crossing
%*Selected flies that crossed more than crossing_min
flyno = size(radvel_o2i_avg_bf_sel,2);
figure_title = [fig_title ' radial velocity at crossing (crossing#>' num2str(crossing_min) ')'];
radvel_ylim = [0 1];

%plots the first four rows of subplots
velocity_multiplots1(radvel_i2o_avg_bf_sel,radvel_i2o_avg_dr_sel,...
    radvel_i2o_avg_af_sel,radvel_o2i_avg_bf_sel,radvel_o2i_avg_dr_sel,...
    radvel_o2i_avg_af_sel,radvel_o2i_avg_sel,radvel_i2o_avg_sel,radvel_o2i_SEM_sel,...
    radvel_i2o_SEM_sel,radvel_o2i_bin_mean_sel,radvel_i2o_bin_mean_sel,...
    radvel_o2i_bin_SEM_sel,radvel_i2o_bin_SEM_sel,...
    radvel_o2i_by_bin_h_sel,radvel_i2o_by_bin_h_sel,...
    framespertimebin,how_long,x_range,bin_x,vel_unit,radvel_ylim,crossing_min,numBins,...
    plots_row,plots_column);


%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec (or frame_norm), then subtract from original
%velocity

%frame_norm defines which time period to use to set the baseline
% frame_norm =((timebefore-2)*framespertimebin +1):((timebefore-1)*framespertimebin);

[radvel_norm_o2i_avg_sel,radvel_norm_i2o_avg_sel,radvel_norm_o2i_SEM_sel,radvel_norm_i2o_SEM_sel,...
    radvel_o2i_norm_before_flies_sel,radvel_o2i_norm_during_flies_sel,radvel_o2i_norm_after_flies_sel,...
    radvel_i2o_norm_before_flies_sel,radvel_i2o_norm_during_flies_sel,radvel_i2o_norm_after_flies_sel] =...
    velocity_normalizer(radvel_o2i_avg_bf_sel,radvel_o2i_avg_dr_sel,radvel_o2i_avg_af_sel,...
    radvel_i2o_avg_bf_sel,radvel_i2o_avg_dr_sel,radvel_i2o_avg_af_sel,...
    frame_norm,flyno);

%bin data and perform t-test for normalized data
[radvel_norm_i2o_bin_mean_sel,radvel_norm_o2i_bin_mean_sel,radvel_norm_i2o_bin_SEM_sel,radvel_norm_o2i_bin_SEM_sel,...
    radvel_norm_i2o_by_bin_h_sel,radvel_norm_o2i_by_bin_h_sel]...
    = bin_ttest(numBins,whichBin,...
    radvel_i2o_norm_before_flies_sel,radvel_i2o_norm_during_flies_sel,...
    radvel_o2i_norm_before_flies_sel,radvel_o2i_norm_during_flies_sel);

y_lim_for_plot = [-.4 .4];

%the rest of the figure
velocity_multiplots2(radvel_norm_o2i_avg_sel,radvel_norm_i2o_avg_sel,...
    radvel_norm_o2i_SEM_sel,radvel_norm_i2o_SEM_sel,...
    radvel_norm_o2i_bin_mean_sel,radvel_norm_i2o_bin_mean_sel,...
    radvel_norm_o2i_by_bin_h_sel,radvel_norm_i2o_by_bin_h_sel,...
    numBins,plots_row,plots_column,frame_norm,...
    framespertimebin,x_range,bin_x,how_long,y_lim_for_plot)

ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,figure_title);
set(tx,'fontweight','bold');

%save
set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');

fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');



%========================================================================

%plot velocity/radial velocity as a function of radius
figure
set(gcf,'position',[400 100 900 700],'color','white');

%total velocity
for i=1:3
    subplot(4,2,2*i-1)
    plot([bin_number1 bin_number1],[0 2],'k--');hold on
    
    for in=1:numflies
        p = rem(in,20)+1;
        plot(avg_vel_by_radius_flies{i,in},'color',cmap(p,:));hold on
        
        set(gca,'xlim',[0 max(radius_binned) + 1],'ylim',[0 vel_ylim(2)],'box','off','tickdir','out','xtick',(1:2:100));
    end
    if i==1 %before
        title({[fig_title ' velocity VS radius'];period_name{i}});
    else
        title(period_name{i});
    end
end

%radial velocity
for i=1:3
    subplot(4,2,2*i)
    plot([bin_number1 bin_number1],[0 2],'k--');hold on
    for in=1:numflies
        p = rem(in,20)+1;
        plot(avg_radvel_by_radius_flies{i,in},'color',cmap(p,:));hold on
        
        set(gca,'xlim',[0 max(radius_binned) + 1],'ylim',[0 radvel_ylim(2)-.5],'box','off','tickdir','out','xtick',(1:2:100));
    end
    if i==1%before
        title('Radial velocity VS radius');
    end
end


subplot(4,2,7)
plot([bin_number1 bin_number1],[0 2],'k--');hold on
for in=1:3
    plot(avg_vel_by_radius_all(in,:),'o-','markersize',2,'color',color(in,:));hold on
    
    set(gca,'xlim',[0 max(radius_binned) + 1],'ylim',[0 vel_ylim(2)-.5],'box','off','tickdir','out','xtick',(1:2:100));
end
xlabel('radius (binned)');
ylabel(vel_unit);
title('Mean of velocity')

% t-test: compare before VS during velocity at each bin

%first collect velocity in each bin from all the flies
vel_avg_by_bin_bf = nan(numflies,total_bin_count);
vel_avg_by_bin_dr = nan(numflies,total_bin_count);
vel_avg_by_bin_af = nan(numflies,total_bin_count);

for period =1:3
    for fly=1:numflies
        for bin_n=1:length(avg_vel_by_radius_flies{period,fly})
            %first copy and save velocity average at given bin from all the
            %flies
            if period ==1 %before
                vel_avg_by_bin_bf(fly,bin_n) = avg_vel_by_radius_flies{period,fly}(bin_n);
            elseif period ==2 %during
                vel_avg_by_bin_dr(fly,bin_n) = avg_vel_by_radius_flies{period,fly}(bin_n);
            else %after
                vel_avg_by_bin_af(fly,bin_n) = avg_vel_by_radius_flies{period,fly}(bin_n);
            end
        end
    end
end

%then perform paired t-test between 'before' and 'during' in each bin
vel_by_bin_h = nan(1,bin_n);
vel_by_bin_p = nan(1,bin_n);
vel_by_bin_ci = nan(2,bin_n);

%http://www.mathworks.com/help/toolbox/stats/ttest.html
%h = ttest(x,y) performs a paired t-test of the null hypothesis that data
%in the difference x-y are a random sample from a normal distribution with
%mean 0 and unknown variance, against the alternative that the mean is not
%0. x and y must be vectors of the same length, or arrays of the same size.
% The result of the test is returned in h. h = 1 indicates a rejection of
% the null hypothesis at the 5% significance level. h = 0 indicates a
% failure to reject the null hypothesis at the 5% significance level.

for bin_n=1:total_bin_count
    [h, p, ci] = ttest(vel_avg_by_bin_bf(:,bin_n),vel_avg_by_bin_dr(:,bin_n));
    vel_by_bin_h(bin_n) = h;
    vel_by_bin_p(bin_n) = p;
    vel_by_bin_ci(:,bin_n) = ci;
end

%mark the bins where h=1 (significant difference between during and before)
y_value = max(avg_vel_by_radius_all);

for bin_n=1:total_bin_count
    if vel_by_bin_h(bin_n) == 1 %there is a significant difference
        plot(bin_n,y_value(bin_n)+ .15,'k*');
        p_value =  sprintf('%0.2f', vel_by_bin_p(bin_n));
        text(bin_n,y_value(bin_n)+ .26,num2str(p_value),'fontsize',6);
    end
end

subplot(4,2,8)
plot([bin_number1 bin_number1],[0 2],'k--');hold on
for in=1:3
    plot(avg_radvel_by_radius_all(in,:),'o-','markersize',2,'color',color(in,:));hold on
    
    set(gca,'xlim',[0 max(radius_binned) + 1],'ylim',[0 radvel_ylim(2)-.5],'box','off','tickdir','out','xtick',(1:2:100));
end
xlabel('radius (binned)');
ylabel(vel_unit);
title('Mean of radial velocity')
% t-test: compare before VS during velocity at each bin

%first collect velocity in each bin from all the flies
radvel_avg_by_bin_bf = nan(numflies,total_bin_count);
radvel_avg_by_bin_dr = nan(numflies,total_bin_count);
radvel_avg_by_bin_af = nan(numflies,total_bin_count);

for period =1:3
    for fly=1:numflies
        for bin_n=1:length(avg_radvel_by_radius_flies{period,fly})
            %first copy and save radvelocity average at given bin from all the
            %flies
            if period ==1 %before
                radvel_avg_by_bin_bf(fly,bin_n) = avg_radvel_by_radius_flies{period,fly}(bin_n);
            elseif period ==2 %during
                radvel_avg_by_bin_dr(fly,bin_n) = avg_radvel_by_radius_flies{period,fly}(bin_n);
            else %after
                radvel_avg_by_bin_af(fly,bin_n) = avg_radvel_by_radius_flies{period,fly}(bin_n);
            end
        end
    end
end

%then perform paired t-test between 'before' and 'during' in each bin
radvel_by_bin_h = nan(1,bin_n);
radvel_by_bin_p = nan(1,bin_n);
radvel_by_bin_ci = nan(2,bin_n);

%http://www.mathworks.com/help/toolbox/stats/ttest.html
%h = ttest(x,y) performs a paired t-test of the null hypothesis that data
%in the difference x-y are a random sample from a normal distribution with
%mean 0 and unknown variance, against the alternative that the mean is not
%0. x and y must be vectors of the same length, or arrays of the same size.
% The result of the test is returned in h. h = 1 indicates a rejection of
% the null hypothesis at the 5% significance leradvel. h = 0 indicates a
% failure to reject the null hypothesis at the 5% significance level.

for bin_n=1:total_bin_count
    [h, p, ci] = ttest(radvel_avg_by_bin_bf(:,bin_n),radvel_avg_by_bin_dr(:,bin_n));
    radvel_by_bin_h(bin_n) = h;
    radvel_by_bin_p(bin_n) = p;
    radvel_by_bin_ci(:,bin_n) = ci;
end

%mark the bins where h=1 (significant difference between during and before)
y_value = max(avg_radvel_by_radius_all);

for bin_n=1:total_bin_count
    if radvel_by_bin_h(bin_n) == 1 %there is a significant difference
        plot(bin_n,y_value(bin_n)+ .05,'k*');
        p_value =  sprintf('%0.2f', radvel_by_bin_p(bin_n));
        text(bin_n,y_value(bin_n)+ .12,num2str(p_value),'fontsize',6);
    end
end

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');


%========================================================================
% run probability in VS out
multiple_flies_run_prob_in_out;

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%========================================================================
%plots mean of 'inside_rim' : shows the probability of fly being inside

multiple_flies_inside_rim_plotter_V2;

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
fig_count = fig_count+1;
% saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');

%========================================================================

close all;

save([fig_title ' ' date '.mat']);
%save multiple figures in one pdf

ps2pdf('psfile', [fig_title '.ps'], 'pdffile', [fig_title '.pdf'], 'gspapersize', 'letter');

display('Pdf file is saved!');
