% single_fly_analysis_V2 by Seung-Hye (2/29/2012)
% This program needs following functions
%1. radial_calculator.m
%2. vel_calculator.m
%3. velocityplotter.m

clear all; close all;
warning('off');

prog_version =  'V2';
currentfolder = pwd;
day = currentfolder(end-5:end);

%% set constants
framespertimebin =30;%how many frames/sec?
secsperperiod = 180;%how many seconds/period?

outer_radius = 3.2;
inner_radius = 1.2; %new chamber (cm)
odor_zone_area = pi*(inner_radius)^2;
outer_zone_area = (pi*(outer_radius)^2);
ratio = odor_zone_area/outer_zone_area;
velocity_threshold = 0.1;
bin_number = 5; %number of bins inside the odor zone for radial distribution calculation
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
    multiflyyn = input('are there multiple flies in this set of videos?, press 1 if no, 2 if yes');
    
    if multiflyyn ==1;
        fly_number =ones(endvideo-startvideo+1,1);
    else
        flynameyn = input('if you have already saved the fly names , press 1, otherwise 2');
        if flynameyn == 1;
            load([num2str(day) 'flynames.mat']);
        else
            
            fly_number = nan(endvideo-startvideo+1,1);
            for iteration = 1:(endvideo-startvideo+1);
                fly_number(iteration) = input(['what number fly is in this video?' num2str(iteration) '?']);
            end
            
            save ([num2str(day) 'flynames'], 'fly_number');
        end
    end
    
    odornameyn = input('if you have already saved the odor names , press 1, otherwise 2');
    if odornameyn == 1;
        load([num2str(day) 'odornames.mat']);
        
    else
        odorname = cell(endvideo-startvideo+1,1);
        for iteration = 1:(endvideo-startvideo+1);
            odorname{iteration} = input(['what is the odorname and concentration for video' num2str(iteration) '?'], 's');
        end
        
        save ([num2str(day) 'odornames'], 'odorname');
    end
    
    noairfly = input('enter the numbers of any videos without air');
    
    
    flyinfo = struct('first_video', startvideo, 'last_video', endvideo, 'date', day, 'genotype', genotype, 'multiple_flies_yn', multiflyyn, 'odor_yn', odornameyn, 'no_air_fly', noairfly);
    save([num2str(day) 'fly_info'], 'flyinfo')
end
%  fig_title1=input('Enter the fly genotype and odor with concentration: ','s');
%  noair = input('enter 1 if no air turned on during the video');
%========loading the CSV + mat files=======================================
iteration = 1;
for nv=startvideo:endvideo %loop through first video
  
%     try 
        % filename_behavior = uigetfile('*.csv', 'Select the file for FLY track');
    % numvals = csvread(filename_behavior,2);%discard the first frame

     fig_title = [num2str(day) ' ' num2str(genotype) ' video' num2str(nv) ', ' num2str(odorname{iteration})] ;
    
    filename_behavior = [num2str(day) 'video' num2str(nv) '_xypts_transformed.csv'];
    
    % filename_behavior = uigetfile('*.csv', 'Select the file for FLY track');
    %this now reads from the second frame to avoid the sudden jump
    numvals = csvread(filename_behavior,2);
    
    
    %==========================================================================
    %      if length(numvals) >= 10000; %to distinguish between 1 minute and 9 minute videos
    %         secsperperiod = 180;%how many seconds/period
    %     framespertimebin = 30;
    %      else
    %          secsperperiod = 20;
    %          framespertimebin = 10;
    %      end
    fly_x = numvals(:,1);
    fly_y = numvals(:,2);
    
    % fig_title = [filename_behavior(1:13),' ', fig_title1];
    
    %Automatically find rim points files (all the CSV and mat files)
    rimnametag_mat = [filename_behavior(1:6) 'transformedrimpointstest.mat'];
    rimnametag_csv_in = [filename_behavior(1:6) '_xypts_inner_transformedtest.csv'];
    rimnametag_csv_out = [filename_behavior(1:6) '_xypts_outer_transformedtest.csv'];
    
    rimmatfiles = dir('*transformedrimpointstest.mat');
    rimmat = {rimmatfiles.name};
    
    if find(strcmp(rimmat,rimnametag_mat)) == 1 % if there is a matching mat file
        display('Rim points file used')
        display(rimnametag_mat)
        load(rimnametag_mat);
        in_x= inner_transformed(:,1);
        in_y= inner_transformed(:,2);
        out_x= outer_transformed(:,1);
        out_y= outer_transformed(:,2);
    else % if there is no matching mat file, search for CSV files
        display('Rim points file used')
        display(rimnametag_csv_in)
        csv_in = csvread(rimnametag_csv_in,1);
        in_x= csv_in(:,1);
        in_y = csv_in(:,2);
        csv_out = csvread(rimnametag_csv_out,1);
        out_x = csv_out(:,1);
        out_y = csv_out(:,2);
    end
     
    if length(numvals) >= 10000; %to distinguish between 1 minute and 9 minute videos
        secsperperiod = 180;%how many seconds/period
        framespertimebin = 30;
    else
        secsperperiod = 20;
        framespertimebin = 10;
    end
    %%
    %find out if the fly is inside the odor zone by using 'inpolygon' 1=in,0=out
    inside_rim = inpolygon(fly_x,fly_y,in_x,in_y);
    in_out_pts = zeros(1,length(fly_x));
    in_out_pts(2:end) = diff(inside_rim);
    
    crossing = find(in_out_pts);%find the nonzeros: crossing points
    crossing_in = find(in_out_pts>0); %1 means out to in
    crossing_out = find(in_out_pts<0);%-1 means in to out
    
    %set time periods: assumes that it takes 5 seconds for air to reach the
    %chamber after the valve switches
    timeperiods = [1 framespertimebin*secsperperiod+5*framespertimebin...
        2*(framespertimebin*secsperperiod)+5*framespertimebin length(numvals)];
    
    if (inside_rim(timeperiods(2)) == 1)%if fly is inside when odor turns on
        odoron_frame = timeperiods(2);
    else
        crossings_afterOdor = crossing(crossing>=timeperiods(2) & crossing<timeperiods(3));
        if isempty(crossings_afterOdor) == 1 %if fly did not go into the odor zone
            odoron_frame = timeperiods(2);
        else
            odoron_frame  =crossings_afterOdor(1);%first time fly entered the odor zone
        end
    end
    odoroff_frame = timeperiods(3);
   
    % calculate the time fly spent inside in each time period
    % actual frame numbers
    time_in_before_frames = sum(inside_rim(1:timeperiods(2)));
    time_in_during_frames = sum(inside_rim(odoron_frame:odoroff_frame-1));
    time_in_after_frames = sum(inside_rim(odoroff_frame:end));
    % in probability: 1 means that the fly was inside the entire period
    time_in_before = time_in_before_frames/timeperiods(2);
    time_in_during = time_in_during_frames/(odoroff_frame-odoron_frame-1);
    time_in_after = time_in_after_frames/(timeperiods(4)-odoroff_frame-1);

    %calculate time fly spent outisde in each time period
    % in probability
    time_out_before = 1-time_in_before;
    time_out_during = 1-time_in_during;
    time_out_after = 1-time_in_after;
    
    %calculate the number of transits (out2in & in2out)
    crossing_in_before = crossing_in(crossing_in<timeperiods(2));
    crossing_out_before = crossing_out(crossing_out<timeperiods(2));
    crossing_before_No = length(crossing_in_before);%out2in
    
    crossing_in_during = crossing_in(crossing_in >= odoron_frame & crossing_in < odoroff_frame);
    crossing_out_during = crossing_out(crossing_out >= odoron_frame & crossing_out <odoroff_frame);
    crossing_during_No = length(crossing_in_during);
    
    crossing_in_after = crossing_in(crossing_in >= odoroff_frame);
    crossing_out_after = crossing_out(crossing_out >= odoroff_frame);
    crossing_after_No = length(crossing_in_after);
 
    %%
    %calculate the individual and average time spent in & out per transit
    %before====================================================================
    frames_bw_crossing_before = ...
        diff(crossing(crossing < timeperiods(2)));
    
    if crossing_before_No == 0 %if there was no crossing
        frames_in_before = nan;
        frames_out_before = nan;
    else
        if in_out_pts(crossing(1)) == 1 %first crossing is going out2in
            %every odd number is frame# inside between crossing out2in and in2out
            frames_in_before = frames_bw_crossing_before (1:2:end);
            %every even number is frame# outside between crossings in2out and
            %out2in
            frames_out_before = frames_bw_crossing_before (2:2:end);
        else %fly is going from inside to outside
            frames_in_before = frames_bw_crossing_before (2:2:end);
            frames_out_before = frames_bw_crossing_before (1:2:end);
        end
    end
    %get the individual time(sec) spent inside per transit
    time_in_transit_before = frames_in_before/framespertimebin;
    time_out_transit_before = frames_out_before/framespertimebin;
    % get the average
    median_time_in_transit_before = median(time_in_transit_before);
    median_time_out_transit_before = median(time_out_transit_before);
    
    %get the individual time spent inside per transit relative to the total
    %time period
    each_in_transit_before = frames_in_before/timeperiods(2);
    each_out_transit_before = frames_out_before/timeperiods(2);
    % calculating the average time spent inside per transit relative to the
    % total time period
    in_per_transit_before = mean(frames_in_before)/timeperiods(2);
    out_per_transit_before = mean(frames_out_before)/timeperiods(2);
    
    %during====================================================================
    frames_bw_crossing_during = ...
        diff(crossing(crossing>=odoron_frame & crossing<=odoroff_frame));
    try
    if in_out_pts(crossing_in_during(1)) == 1 %fly is going from out2in
        frames_in_during = frames_bw_crossing_during (1:2:end);
        frames_out_during = frames_bw_crossing_during (2:2:end);
    else %fly is going from in2out
        frames_in_during = frames_bw_crossing_during (2:2:end);
        frames_out_during = frames_bw_crossing_during (1:2:end);
    end
    
    %get the time spent inside per transit in second
    time_in_transit_during = frames_in_during/framespertimebin;
    time_out_transit_during = frames_out_during/framespertimebin;
    % get the average
    median_time_in_transit_during = median(time_in_transit_during);
    median_time_out_transit_during = median(time_out_transit_during);
    
    %get the individual time spent inside per transit relative to the total
    %time period
    each_in_transit_during = frames_in_during/(odoroff_frame-odoron_frame);
    each_out_transit_during = frames_out_during/(odoroff_frame-odoron_frame);
    % calculating the time spent inside per transit relative to the total time
    % period
    in_per_transit_during = mean(frames_in_during)/(odoroff_frame-odoron_frame);
    out_per_transit_during = mean(frames_out_during)/(odoroff_frame-odoron_frame);
    catch
         median_time_out_transit_during = [];  
    end
    %after=====================================================================
    frames_bw_crossing_after = diff(crossing(crossing>=odoroff_frame));
    
    if isempty(crossing_in_after)== 0 %if array is not empty
        if in_out_pts(crossing_in_after(1)) == 1 %fly is going from out2in
            frames_in_after = frames_bw_crossing_after (1:2:end);
            frames_out_after = frames_bw_crossing_after (2:2:end);
        else %fly is going from in2out
            frames_in_after = frames_bw_crossing_after (2:2:end);
            frames_out_after = frames_bw_crossing_after(1:2:end);
        end
    else %if fly did not enter 'after', then no frame #
        frames_in_after = nan;
        frames_out_after = nan;
    end
    
    %get the time spent inside per transit in second
    time_in_transit_after = frames_in_after/framespertimebin;
    time_out_transit_after = frames_out_after/framespertimebin;
    % get the average
    median_time_in_transit_after = median(time_in_transit_after);
    median_time_out_transit_after = median(time_out_transit_after);
       
    %get the individual time spent inside per transit relative to the total
    %time period
    each_in_transit_after = frames_in_after/(timeperiods(4)-odoroff_frame);
    each_out_transit_after = frames_out_after/(timeperiods(4)-odoroff_frame);
    % calculating the time spent inside per transit relative to the total time
    % period
    in_per_transit_after = mean(frames_in_after)/(timeperiods(4)-odoroff_frame);
    out_per_transit_after = mean(frames_out_after)/(timeperiods(4)-odoroff_frame);
    
    %%
    %radial distribution calculation
 
    [major_axo, minor_axo,major_axi, minor_axi,fly_bin_probability, bin_radius, average_radius] = ...
        radial_calculator(numvals, out_x,out_y,in_x,in_y,bin_number,timeperiods,odoron_frame,odoroff_frame,inner_radius, outer_radius);

    %velocity calculation
[vel_total,velocity_fly_in, velocity_fly_out,avgvelocity_by_fly_in, avgvelocity_by_fly_out]=...
    vel_calculator(numvals,timeperiods,major_axo, crossing, framespertimebin, inside_rim);
            
    time_in =[time_in_before;time_in_during;time_in_after];
     time_out = [time_out_before;time_out_during;time_out_after];


    if find(noairfly==nv)
fig1compressed = fig1compressed_plotter (out_x,out_y, in_x, in_y, fly_x, fly_y, timeperiods, avgvelocity_by_fly_in, avgvelocity_by_fly_out, median_time_out_transit_before,median_time_out_transit_during, median_time_out_transit_after, time_in, time_out,time_in_before_frames, time_in_during_frames, time_in_after_frames, ratio, fig_title, crossing_before_No, crossing_during_No, crossing_after_No);
   iteration = iteration+1
    else
        
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
        set(gcf,'Position',[434 58 1180 760],'color','white')
        
        subplot(4,6,[1 8])
        plot(in_x,in_y,'k');hold on
        plot(out_x,out_y,'k');
        
        plot(fly_x(1:timeperiods(2)),fly_y(1:timeperiods(2)),'g','linewidth',0.5);
        plot(fly_x(timeperiods(2):odoron_frame),fly_y(timeperiods(2):odoron_frame),'color',grey,'linewidth',0.5);
        plot(fly_x(odoron_frame:odoroff_frame),fly_y(odoron_frame:odoroff_frame),'r','linewidth',0.5);
        plot(fly_x(odoroff_frame:timeperiods(4)),fly_y(odoroff_frame:timeperiods(4)),'b','linewidth',0.5);
        
        set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
        axis tight;
        title([fig_title, ' ',prog_version],'fontsize',12,'fontweight','bold');
        
        subplot(4,6,[13 20])
        plot(in_x,in_y,'k');hold on
        plot(out_x,out_y,'k');
        
        plot(fly_x(1:timeperiods(2)),fly_y(1:timeperiods(2)),'go-','markersize',2);
        set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
        axis tight;
        xlabel('BEFORE','color','k');
        
        subplot(4,6,[15 22])
        plot(in_x,in_y,'k');hold on
        plot(out_x,out_y,'k');
        
        plot(fly_x(timeperiods(2):odoron_frame),fly_y(timeperiods(2):odoron_frame),'o-', 'color',grey, 'markersize',2);
        plot(fly_x(odoron_frame:odoroff_frame),fly_y(odoron_frame:odoroff_frame),'ro-', 'markersize',2);
        set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
        axis tight;
        xlabel('DURING','color','k');
        
        subplot(4,6,[17 24])
        plot(in_x,in_y,'k');hold on
        plot(out_x,out_y,'k');
        
        plot(fly_x(odoroff_frame:timeperiods(4)),fly_y(odoroff_frame:timeperiods(4)),'bo-','markersize',2);
        set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
        axis tight;
        xlabel('AFTER','color','k');
        
        %plot radial distribution
        subplot(4,6,3);
        
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
        subplot(4,6,4)
        for h=1:3
            b = bar(h,time_in(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
            set(b, 'FaceColor', color(:,h));
            display(time_in(2))
        end
        title('time spent inside odor zone' ,'fontsize',8);
        ylim ([0 1]);
        set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
        
        subplot(4,6,5)
        for h=1:3
            b = bar(h,time_out(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
            set(b, 'FaceColor', color(:,h));
        end
        title('time spent outside odor zone' ,'fontsize',8);
        ylim ([0 1]);
        set(gca,'Box','off','Xtick',[],'Ytick',(0:.2:1),'YGrid','on','fontsize',8);
        
        %plot number of transits (out2in)
        subplot(4,6,6)
        crossing_ins = [crossing_before_No; crossing_during_No; crossing_after_No];
        for h=1:3
            b = bar(h,crossing_ins(h),'BarWidth', .5, 'EdgeColor', 'none'); hold on
            set(b, 'FaceColor', color(:,h));
            display(crossing_ins(2))
        end
        title('number of transits (out to in)' ,'fontsize',8);
        ylim ([0 30]);
        set(gca,'Box','off','Xtick',[],'Ytick',(0:5:40),'YGrid','on','fontsize',8);
        
        %plot time spent inside per transit(1 means entire period)
        time_inside_per_transit = [median_time_in_transit_before,median_time_in_transit_during,median_time_in_transit_after];
        subplot(4,6,9);
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
        %plot the average
        for h = 1:3,
            b = bar(h, time_inside_per_transit(h), 'BarWidth', .5, 'EdgeColor', 'none');
            hold on;
            set(b, 'FaceColor', color(:,h));
            p = plot(h, time_inside_per_transit(h), 'o', 'MarkerSize', 4, 'MarkerEdgeColor', 'w');
            set(p, 'MarkerFaceColor', color(:,h));
        end;
        plot(time_inside_per_transit, 'k');
        display(time_inside_per_transit(2));
        title('Time spent inside/transit' ,'fontsize',8);
        ylabel('time(s)','fontsize',7);
        maxlimit= max(time_inside_per_transit);
        ylim ([0 maxlimit+2]);
        if maxlimit+2>10
            set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((maxlimit+2/5),1)/2:maxlimit+2),'YGrid','on','fontsize',7);
        else
            set(gca,'Box','off','Xtick',[],'Ytick',(0:2:10),'YGrid','on','fontsize',7);
        end
        
        %plot odor rediscovery time (1 means entire period)
        time_outside_per_transit = [median_time_out_transit_before,median_time_out_transit_during,median_time_out_transit_after];
        
        subplot(4,6,10);
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
        for h = 1:3,
            b = bar(h, time_outside_per_transit(h), 'BarWidth', .5, 'EdgeColor', 'none');
            hold on;
            set(b, 'FaceColor', color(:,h));
            p = plot(h, time_outside_per_transit(h), 'o', 'MarkerSize', 5, 'MarkerEdgeColor', 'w');
            set(p, 'MarkerFaceColor', color(:,h));
            
        end;
        plot(time_outside_per_transit, 'k');
        display(time_outside_per_transit(2))
        title('odor re-discovery time/transit' ,'fontsize',8);
        ylabel('time(s)','fontsize',7);
        maxlimit= max(time_outside_per_transit);
        ylim ([0 maxlimit+2]);
        if maxlimit+2>10
            set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((maxlimit+2/5),1)/2:maxlimit+2),'YGrid','on','fontsize',7);
        else
            set(gca,'Box','off','Xtick',[],'Ytick',(0:2:10),'YGrid','on','fontsize',7);
        end
        
        subplot(4,6,11);
        for h = 1:3,
            b = bar(h, avgvelocity_by_fly_in(h), 'BarWidth', .5, 'EdgeColor', 'none');
            hold on;
            set(b, 'FaceColor', color(:,h));
            
            p = plot(1:3, avgvelocity_by_fly_in, 'ko-', 'MarkerSize', 5, 'MarkerEdgeColor', 'w','markerfacecolor','k');
            
            ylabel('velocity (cm/s)','fontsize',8);
            xlabel('avg velocity inside','fontsize',8);
            ylim ([0 max(avgvelocity_by_fly_out)+.05]);
            set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((max(avgvelocity_by_fly_out+2)/5),-1):max(avgvelocity_by_fly_out)+.5),'YGrid','on','fontsize',7);
            
        end;
        display(avgvelocity_by_fly_in(2))
        subplot(4,6,12);
        for h = 1:3,
            b = bar(h, avgvelocity_by_fly_out(h), 'BarWidth', .5, 'EdgeColor', 'none');
            hold on;
            set(b, 'FaceColor', color(:,h));
            p = plot(1:3, avgvelocity_by_fly_out, 'ko-', 'MarkerSize', 5, 'MarkerEdgeColor', 'w','markerfacecolor','k');
            
            ylabel('velocity (cm/s)','fontsize',8);
            xlabel('avg velocity outside','fontsize',8);
            ylim ([0 max(avgvelocity_by_fly_out)+.05]);
            set(gca,'Box','off','Xtick',[],'Ytick',(0:roundn((max(avgvelocity_by_fly_out+2)/5),-1):max(avgvelocity_by_fly_out)+.5),'YGrid','on','fontsize',7);
            
        end;
        display(avgvelocity_by_fly_out(2))
        %save the figure as png file
        set(gcf, 'PaperPositionMode', 'auto');
        saveas(gcf, [fig_title ' Main_analysis.png']);
        
        %%
        %calculation to plot the moment-by-moment velocity change at crossing + 2
        %seconds before crossing
        try
        [smooth_vel_total,velocitytoplot_out2in,velocitytoplot_in2out] = ...
            velocityplotter (crossing_in_before, crossing_in_during, crossing_in_after,...
            crossing_out_before,crossing_out_during,crossing_out_after, vel_total,...
            framespertimebin, timeperiods, fig_title);
         
        catch
        end
 
iteration = iteration+1
    end
%     catch

    close all
%     clearvars  -except  startvideo endvideo day genotype multiflyy noairfly iteration fly_number odorname
end