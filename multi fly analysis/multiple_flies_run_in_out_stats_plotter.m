% multiple_flies_run_in_out_stats_plotter

% use variables saved from multiple_flies_analysis_V20_biggerIR
% need 'run_in_entire_flies, run_out_entire_flies
% the arrays contain the frame numbers for runs that are entirely inside
% the rim or entirely outside the rim

% individual fly's averages..: run velocity, run duration, distance
% traveled (total VS linear)
% and pooling all the flies' run data

%pre-allocate arrays
%run velocity
run_in_flies_vel_mean = nan(numflies,2);
run_out_flies_vel_mean = nan(numflies,2);
run_in_flies_vel_median = nan(numflies,2);
run_out_flies_vel_median = nan(numflies,2);

%run duration (sec)
run_in_flies_dur_mean = nan(numflies,2);
run_out_flies_dur_mean = nan(numflies,2);
run_in_flies_dur_median = nan(numflies,2);
run_out_flies_dur_median = nan(numflies,2);

%run distance (cm)
run_in_flies_dist_mean = nan(numflies,2);
run_out_flies_dist_mean = nan(numflies,2);
run_in_flies_dist_median = nan(numflies,2);
run_out_flies_dist_median = nan(numflies,2);

%linear run distance (cm)
run_in_flies_lindist_mean = nan(numflies,2);
run_out_flies_lindist_mean = nan(numflies,2);
run_in_flies_lindist_median = nan(numflies,2);
run_out_flies_lindist_median = nan(numflies,2);

% run in
for period =1:2
    p = 0;
    for fly = 1:numflies
        A = run_in_entire_flies{period,fly};%get the frame # for runs
        for x = 1:numel(A)
            AA = A{x}; %each run data
            if isempty(AA) == 0 % if not empty
                
                %velocity of runs
                onefly_vel(x)= mean(vel_classified_flies(AA,fly));
                %save this run in the array
                p = p+1;
                run_flies_vel(p) = mean(vel_classified_flies(AA,fly));
                
                %get the duration of the run (sec)
                onefly_dur(x)= length(AA)/framespertimebin;
                run_flies_dur(p) = length(AA)/framespertimebin;
                
                %run distance  = velocity * time (cm) (total length
                %traveled)
                onefly_dist(x)= onefly_vel(x) * onefly_dur(x);
                run_flies_dist(p) = onefly_vel(x) * onefly_dur(x);
                
                %run distance: linear distance between run start and end
                %points
                %starting point x and y coordinates
                run_st_x = numvals(AA(1),fly*2-1);
                run_st_y = numvals(AA(1),fly*2);
                run_end_x = numvals(AA(end),fly*2-1);
                run_end_y = numvals(AA(end),fly*2);
                run_dist = sqrt((run_end_x - run_st_x)^2 + (run_end_y - run_st_y)^2); %in pixel
                %pixel to cm conversion: use 'pixeltocm'
                run_dist = run_dist * pixel2cm(fly);
                
                onefly_lindist(x) = run_dist;
                run_flies_lindist(p) = run_dist;
            end
        end
        
        if exist('onefly_vel') ==1
            run_in_flies_vel_mean(fly,period) = nanmean(onefly_vel);
            run_in_flies_dur_mean(fly,period) = nanmean(onefly_dur);
            run_in_flies_dist_mean(fly,period) = nanmean(onefly_dist);
            run_in_flies_lindist_mean(fly,period) = nanmean(onefly_lindist);
            clear onefly_vel onefly_dur onefly_dist onefly_lidnist
        end
    end
        
     run_num_in(period) = p;
   
    %save each period's data
    if period ==1
        run_in_flies_vel_bf = run_flies_vel';
        run_in_flies_dur_bf = run_flies_dur';
        run_in_flies_dist_bf = run_flies_dist';
        run_in_flies_lindist_bf = run_flies_lindist';
    elseif period ==2
        run_in_flies_vel_dr = run_flies_vel';
        run_in_flies_dur_dr= run_flies_dur';
        run_in_flies_dist_dr = run_flies_dist';
        run_in_flies_lindist_dr = run_flies_lindist';
    end
    clear run_flies_vel run_flies_dur run_flies_dist run_flies_lindist
    
    
end

%run out
for period =1:2
    p = 0;
    for fly = 1:numflies
        A = run_out_entire_flies{period,fly};%get the frame # for runs
        for x = 1:numel(A)
            AA = A{x}; %each run data
            if isempty(AA) == 0 % if not empty
                
                %velocity of runs
                onefly_vel(x)= mean(vel_classified_flies(AA,fly));
                %save this run in the array
                p = p+1;
                run_flies_vel(p) = mean(vel_classified_flies(AA,fly));
                
                %get the duration of the run (sec)
                onefly_dur(x)= length(AA)/framespertimebin;
                run_flies_dur(p) = length(AA)/framespertimebin;
                
                %run distance  = velocity * time (cm) (total length
                %traveled)
                onefly_dist(x)= onefly_vel(x) * onefly_dur(x);
                run_flies_dist(p) = onefly_vel(x) * onefly_dur(x);
                
                %run distance: linear distance between run start and end
                %points
                %starting point x and y coordinates
                run_st_x = numvals(AA(1),fly*2-1);
                run_st_y = numvals(AA(1),fly*2);
                run_end_x = numvals(AA(end),fly*2-1);
                run_end_y = numvals(AA(end),fly*2);
                run_dist = sqrt((run_end_x - run_st_x)^2 + (run_end_y - run_st_y)^2); %in pixel
                %pixel to cm conversion: use 'pixeltocm'
                run_dist = run_dist * pixel2cm(fly);
                
                onefly_lindist(x) = run_dist;
                run_flies_lindist(p) = run_dist;
            end
        end
        
        if exist('onefly_vel') ==1
            run_out_flies_vel_mean(fly,period) = nanmean(onefly_vel);
            run_out_flies_dur_mean(fly,period) = nanmean(onefly_dur);
            run_out_flies_dist_mean(fly,period) = nanmean(onefly_dist);
            run_out_flies_lindist_mean(fly,period) = nanmean(onefly_lindist);
            clear onefly_vel onefly_dur onefly_dist onefly_lidnist
        end
    end
        
     run_num_out(period) = p;
   
    %save each period's data
    if period ==1
        run_out_flies_vel_bf = run_flies_vel';
        run_out_flies_dur_bf = run_flies_dur';
        run_out_flies_dist_bf = run_flies_dist';
        run_out_flies_lindist_bf = run_flies_lindist';
    elseif period ==2
        run_out_flies_vel_dr = run_flies_vel';
        run_out_flies_dur_dr= run_flies_dur';
        run_out_flies_dist_dr = run_flies_dist';
        run_out_flies_lindist_dr = run_flies_lindist';
    end
    clear run_flies_vel run_flies_dur run_flies_dist run_flies_lindist
    
    
end


%for some reason, duration has '0' instead of nan, replace them
ind = (run_in_flies_dur_mean == 0);
run_in_flies_dur_mean(ind) = nan;
ind = (run_out_flies_dur_mean == 0);
run_out_flies_dur_mean(ind) = nan;


%get the median of all flies
run_in_flies_vel_mean_median = nanmedian(run_in_flies_vel_mean);
run_in_flies_dur_mean_median = nanmedian(run_in_flies_dur_mean);
run_in_flies_dist_mean_median = nanmedian(run_in_flies_dist_mean);

run_out_flies_vel_mean_median = nanmedian(run_out_flies_vel_mean);
run_out_flies_dur_mean_median = nanmedian(run_out_flies_dur_mean);
run_out_flies_dist_mean_median = nanmedian(run_out_flies_dist_mean);



%%
%histogram and plotting
avg_velocity_hist = (0:(2/20):2);
durationsecs_hist = (0:(20/20):20);
runlength_hist = (0:(10/20):10);%for what?
lindist_hist = (0:(5/20):5);

figure
set(gcf,'position',[100 20 1200 800]);

%plot how the run duration changes in all runs

for period= 1:2
    % run in
    subplot(4,5,period)
    
    if period ==1 %before
    AA = run_in_flies_dur_bf;
    elseif period ==2 %during
        AA = run_in_flies_dur_dr;
    end
    
    cc = histc(AA,durationsecs_hist);
    cc1 = cc./run_num_in(period);
    stairs(durationsecs_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA) ],[0 100],':','color',color(period,:));
    plot([median(AA) median(AA) ],[0 100],'color',grey);
    
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
    text(5, .44, ['Avg. Run = ' num2str(mean(AA),'%4.2f') 's'], 'FontSize',8);
    text(5, .38, ['median Run = ' num2str(median(AA),'%4.2f') 's'], 'FontSize',8);
    
    set(gca,'box','off');
    
    % run out
    subplot(4,5,period+2)
    if period ==1 %before
    AA = run_out_flies_dur_bf;
    elseif period ==2 %during
        AA = run_out_flies_dur_dr;
    end
    
    cc = histc(AA,durationsecs_hist);
    cc1 = cc./run_num_out(period);
    stairs(durationsecs_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA) ],[0 100],':','color',color(period,:));
    plot([median(AA) median(AA) ],[0 100],'color',grey);
    
    xlim([0,20])
    ylim([0,.6]);
    xlabel('Run Duration (secs)');
    ylabel('probability');
    if period ==1
        title({['Run Duration (OUT)'];period_name{period}},'interpreter','none','fontweight','bold');
    elseif period ==2
        title([period_name{period}],'interpreter','none','fontweight','bold')
    else
        title({period_name{period};[' ']},'fontweight','bold');
    end
    
    text(5, .5, ['# Runs = ' num2str(run_num_out(period))], 'FontSize', 8);
    text(5, .44, ['Avg. Run = ' num2str(mean(AA),'%4.2f') 's'], 'FontSize',8);
    text(5, .38, ['median Run = ' num2str(median(AA),'%4.2f') 's'], 'FontSize',8);

    set(gca,'box','off');

end

%individual fly's run duration (cm)
subplot(4,5,5)
h = boxplot([run_in_flies_dur_mean(:,1),run_in_flies_dur_mean(:,2),...
    run_out_flies_dur_mean(:,1),run_out_flies_dur_mean(:,2)],'color',[0 0 0]);hold on

for i=1:2
    plot(i,run_in_flies_dur_mean(:,i),'.','color',color(i,:));
end

for i=1:2
    plot(i+2,run_out_flies_dur_mean(:,i),'.','color',color(i,:));
end
ylim([0 10]); xlim([.5 4.5]);
set(gca,'Xtick',1:4,'XTickLabel',{'bef','dur','bef', 'dur'},'Ytick',0:2:10,'tickdir','out');
set(gca,'box','off');
text(1.3, 9, ['IN'], 'FontSize', 8);
text(3.3, 9, ['OUT'], 'FontSize', 8);

title('runs entirely in/out','fontweight','bold');

%RUN length/distance (cm) : total distance travelled
%all the runs
for period= 1:2
    % run in
    subplot(4,5,period+5)
    
    if period ==1 %before
    AA = run_in_flies_dist_bf;
    elseif period ==2 %during
        AA = run_in_flies_dist_dr;
    end
    
    cc = histc(AA,runlength_hist);
    cc1 = cc./run_num_in(period);
    stairs(runlength_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA) ],[0 100],':','color',color(period,:));
    plot([median(AA) median(AA) ],[0 100],'color',grey);
    
    xlim([0,10])
    ylim([0,.6]);
    xlabel('Run Length(cm)');
    ylabel('probability');
    if period ==1
        title(['Run length(IN)'],'interpreter','none','fontweight','bold');
    end
    
    text(2, .44, ['Avg. Run = ' num2str(mean(AA),'%4.2f') 's'], 'FontSize',8);
    text(2, .34, ['median Run = ' num2str(median(AA),'%4.2f') 's'], 'FontSize',8);
    
    set(gca,'box','off');
    
    % run out
     subplot(4,5,period+7)
    
    if period ==1 %before
    AA = run_out_flies_dist_bf;
    elseif period ==2 %during
        AA = run_out_flies_dist_dr;
    end
    
    cc = histc(AA,runlength_hist);
    cc1 = cc./run_num_out(period);
    stairs(runlength_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA) ],[0 100],':','color',color(period,:));
    plot([median(AA) median(AA) ],[0 100],'color',grey);
    
    xlim([0,10])
    ylim([0,.6]);
    xlabel('Run Length(cm)');
    ylabel('probability');
    if period ==1
        title(['Run length(OUT)'],'interpreter','none','fontweight','bold');
    end
    
    text(2, .44, ['Avg. Run = ' num2str(mean(AA),'%4.2f') 's'], 'FontSize',8);
    text(2, .34, ['median Run = ' num2str(median(AA),'%4.2f') 's'], 'FontSize',8);
    
    set(gca,'box','off');

end

subplot(4,5,10)
h = boxplot([run_in_flies_dist_mean(:,1),run_in_flies_dist_mean(:,2),...
    run_out_flies_dist_mean(:,1),run_out_flies_dist_mean(:,2)],'color',[0 0 0]);hold on

%individual fly's run distance/length
for i=1:2
    plot(i,run_in_flies_dist_mean(:,i),'.','color',color(i,:));
end

for i=1:2
    plot(i+2,run_out_flies_dist_mean(:,i),'.','color',color(i,:));
end
ylim([0 8]); xlim([.5 4.5]);
set(gca,'Xtick',1:4,'XTickLabel',{'bef','dur','bef', 'dur'},'Ytick',0:2:10,'tickdir','out');
set(gca,'box','off');
text(1.3, 7, ['IN'], 'FontSize', 8);
text(3.3, 7, ['OUT'], 'FontSize', 8);

%RUN length/distance (cm) : linear distance
%all the runs
for period= 1:2
    % run in
    subplot(4,5,period+10)
    
    if period ==1 %before
    AA = run_in_flies_lindist_bf;
    elseif period ==2 %during
        AA = run_in_flies_lindist_dr;
    end
    
    cc = histc(AA,lindist_hist);
    cc1 = cc./run_num_in(period);
    stairs(lindist_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA) ],[0 100],':','color',color(period,:));
    plot([median(AA) median(AA) ],[0 100],'color',grey);
    
    xlim([0,5])
    ylim([0,.6]);
    xlabel('distance(cm)');
    ylabel('probability');
    if period ==1
        title(['linear distance(IN)'],'interpreter','none','fontweight','bold');
    end
    
    text(1, .44, ['Avg. Run = ' num2str(mean(AA),'%4.2f') 's'], 'FontSize',8);
    text(1, .34, ['median Run = ' num2str(median(AA),'%4.2f') 's'], 'FontSize',8);
    
    set(gca,'box','off');
    
    % run out
     subplot(4,5,period+12)
    
    if period ==1 %before
    AA = run_out_flies_lindist_bf;
    elseif period ==2 %during
        AA = run_out_flies_lindist_dr;
    end
    
    cc = histc(AA,lindist_hist);
    cc1 = cc./run_num_out(period);
    stairs(lindist_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA) ],[0 100],':','color',color(period,:));
    plot([median(AA) median(AA) ],[0 100],'color',grey);
    
    xlim([0,5])
    ylim([0,.6]);
    xlabel('distance(cm)');
    ylabel('probability');
    if period ==1
        title(['linear distance(OUT)'],'interpreter','none','fontweight','bold');
    end
    
    text(1, .44, ['Avg. Run = ' num2str(mean(AA),'%4.2f') 's'], 'FontSize',8);
    text(1, .34, ['median Run = ' num2str(median(AA),'%4.2f') 's'], 'FontSize',8);
    
    set(gca,'box','off');
 
end

subplot(4,5,15)
h = boxplot([run_in_flies_lindist_mean(:,1),run_in_flies_lindist_mean(:,2),...
    run_out_flies_lindist_mean(:,1),run_out_flies_lindist_mean(:,2)],'color',[0 0 0]);hold on

%individual fly's run distance/length
for i=1:2
    plot(i,run_in_flies_lindist_mean(:,i),'.','color',color(i,:));
end

for i=1:2
    plot(i+2,run_out_flies_lindist_mean(:,i),'.','color',color(i,:));
end
ylim([0 1.5]); xlim([.5 4.5]);
set(gca,'Xtick',1:4,'XTickLabel',{'bef','dur','bef', 'dur'},'Ytick',0:.5:10,'tickdir','out');
set(gca,'box','off');
text(1.3,1.2, ['IN'], 'FontSize', 8);
text(3.3,1.2, ['OUT'], 'FontSize', 8);


%plot how the run velocity changes in all the runs 

for period= 1:2
    % run in
    subplot(4,5,period+15)
    
    if period ==1 %before
    AA = run_in_flies_vel_bf;
    elseif period ==2 %during
        AA = run_in_flies_vel_dr;
    end
    
    cc = histc(AA,avg_velocity_hist);
    cc1 = cc./run_num_in(period);
    stairs(avg_velocity_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA)],[0 100],':','color',color(period,:));

    xlim([0,2])
    ylim([0,.3]);
    xlabel('velocity (cm/secs)');
    ylabel('probability');
    if period ==1
        title(['Run velocity (IN)'],'interpreter','none','fontweight','bold');
    end
    
    text(.2, .25, ['avg velocity = ' num2str(mean(AA),'%4.2f') 'cm/sec'], 'FontSize', 8);
    
    set(gca,'box','off');
    
    % run out
    subplot(4,5,period+17)
    
    if period ==1 %before
    AA = run_out_flies_vel_bf;
    elseif period ==2 %during
        AA = run_out_flies_vel_dr;
    end
    
    cc = histc(AA,avg_velocity_hist);
    cc1 = cc./run_num_out(period);
    stairs(avg_velocity_hist,cc1,'color',color(period,:));hold on
    plot([mean(AA) mean(AA)],[0 100],':','color',color(period,:));

    xlim([0,2])
    ylim([0,.3]);
    xlabel('velocity (cm/secs)');
    ylabel('probability');
    if period ==1
        title(['Run velocity (OUT)'],'interpreter','none','fontweight','bold');
    end
    
    text(.2, .25, ['avg velocity = ' num2str(mean(AA),'%4.2f') 'cm/sec'], 'FontSize', 8);
    
    set(gca,'box','off');

end

%run velocity in individual flies
subplot(4,5,20)
h = boxplot([run_in_flies_vel_mean(:,1),run_in_flies_vel_mean(:,2),...
    run_out_flies_vel_mean(:,1),run_out_flies_vel_mean(:,2)],'color',[0 0 0]);hold on

%individual fly's run velocity
for i=1:2
    plot(i,run_in_flies_vel_mean(:,i),'.','color',color(i,:));
end

for i=1:2
    plot(i+2,run_out_flies_vel_mean(:,i),'.','color',color(i,:));
end
ylim([0 1.5]); xlim([.5 4.5]);
set(gca,'Xtick',1:4,'XTickLabel',{'bef','dur','bef', 'dur'},'Ytick',0:.5:10,'tickdir','out');
set(gca,'box','off');
text(1.3, 1.4, ['IN'], 'FontSize', 8);
text(3.3, 1.4, ['OUT'], 'FontSize', 8);






