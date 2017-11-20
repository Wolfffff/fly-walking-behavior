%multiple_flies_analysis_V22_biggerIR for control by Seung-Hye (8/15/2013)

%goal: to analyze control data (no air no vacuum etc.)
% Since there are files that are only 5 minutes long, I cannot run the
% regular V22 analysis. Instead, I will just get the fly tracks, determine
% whether the fly is in or out and count the total frame numbers in VS out.


% All the behavior files ('*xypts_transformed.csv') and rim points for the
% same fly/odor/concentration need to be in one folder! and their names
% need to be consistent! (Most errors occur when the script cannot find the
% files. Check if all the csv files have corresponding transformed rim point files)
% *xypts_transformed.csv
% *transformedrimpoints.mat
% (*inner_transformed.csv, *outer_transformed.csv :  not necessary if the
% mat file is present)


clear all; close all;
warning('off');

prog_version =  'V22';

% set constants
framespertimebin =30;%how many frames/sec?
secsperperiod = 300;%how many seconds/period? % 5 min of before period

outer_radius = 3.2;
inner_radius = 1.2; %new chamber (cm)

%bigger inner_radius: change this number to see the effect
inner_radius_bigger = 1.9; %based on ACV0 data

bin_number = 10; %number of bins inside the odor zone for radial distribution calculation


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
        
        %Automatic R/S decision
%         figure
%         
%         xlim1 = 1; %x limits for the initial plot
%         xlim2 = 25;
%         xincrem = 5;
%         
%         ylim1 = 0;
%         ylim2 = 2;
%         yincrem = .1;
%         
%         
%         x1 = (xlim1:xlim2);
%         
%         plot(x1,velocity(xlim1:xlim2),'ro-'); hold on;
%         %run threshold
%         plot([xlim1,xlim2],[runthreshold, runthreshold],'k');
%         %stop threshold
%         plot([xlim1,xlim2],[stopthreshold, stopthreshold],'k');
%         
%         ylim ([ylim1 ylim2]);
%         xlim ([xlim1 xlim2]);
%         set(gca,'XTick', xlim1:xincrem:xlim2);
%         set(gca,'YTick', ylim1:yincrem:ylim2);
%         ylabel ('Velocity (cm/frame)');
%         hold off;
        
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
        
        first_point = first_input1;
        
        %if it is accurate, get rid of this part later
%         first_point = input ('Type 1 if the first point is a RUN, 0 if a STOP; ');
%         close all;
%         
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

%% plot all the data together

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
    
    
    %plot fly's location as dots
    plot(x_for_fly, y_for_fly, 'b.', 'markersize',2);
    
    
    
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
            print('-dpsc2',[fig_title ' Control.ps'],'-loose');
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_'  num2str(fig_count) '.fig']);
        else
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
            print('-dpsc2',[fig_title ' Control.ps'],'-loose','-append');
        end
        
    elseif a == numflies %if this is the last fly, save the figure
        set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
        if fig_no ==1 %first
            print('-dpsc2',[fig_title ' Control.ps'],'-loose');
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
        else
            fig_count = fig_count+1;
            %             saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
            print('-dpsc2',[fig_title ' Control.ps'],'-loose','-append');
        end
    end
    
end
%==========================
%all flies together : the outlines do not perfectly overlap
figure
fig_no = fig_no + 1;

for i = 1:numflies
    plot(numvals_pi{i}(:,1),numvals_pi{i}(:,2),'k-');
    hold on
    plot(numvals_po{i}(:,1),numvals_po{i}(:,2),'k-');
    plot(numvals(:,2*i-1),numvals(:,2*i), 'b.', 'markersize',2);
    
end

set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
axis tight;

title([fig_title ' overlapped']);

print('-dpsc2',[fig_title ' Control.ps'],'-loose','-append');


%%
%all of flies together
frames_in = sum(inside_rim);
fraction_in = frames_in/size(inside_rim,1);
fraction_in_med = median(fraction_in);

figure
fig_no = fig_no+1;

set(gcf,'position',[300 300 300 300]);

plot(1,fraction_in,'o');
hold on
plot(1,fraction_in_med,'+','markersize',10);
%calculated fraction inside from area of odor zone
predicted=(inner_radius_bigger^2)/(outer_radius^2);
plot([.5 1.5],[predicted predicted],':','color',grey);

ylim([0 1]);
xlim([.5 1.5]);

set(gca,'box','off','tickdir','out','ytick',[0:.2:1],'xtick',[])

title([fig_title ' Total fraction inside']);

%             saveas(gcf,[fig_title '_' num2str(fig_count) '.fig']);
print('-dpsc2',[fig_title ' Control.ps'],'-loose','-append');

%%
close all;

save([fig_title ' Control' date '.mat']);
%save multiple figures in one pdf

ps2pdf('psfile', [fig_title ' Control.ps'], 'pdffile', [fig_title ' Control' date '.pdf'], 'gspapersize', 'letter');

display('Pdf file is saved!');
