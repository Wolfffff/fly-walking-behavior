%This script combines 3 scripts from Vikas
% 1) hD_runstophistogramplotter,
% 2) multiple_flies_angular_periods, 
% 3) multiple_flies_turning_analysis_plotter_new
%
% Once all the variables are saved in one mat file/fly_odor, those variables can be used
% to make plots to compare among different odors or flies.

analysis_file = uigetfile('*.mat','Select the mat file that contains V22 data');
load(analysis_file);

%% hD_runstophistogramplotter

% user_input1= input('Enter the fly genotype : ','s');
%  user_input2 = input('Enter the odor name and concentration : ' ,'s');
%  user_input = [user_input1 ' ' user_input2];

% run & stop stats; collect all flies data and save them according to periods
rundistribution_fly=cell(numflies,3,1);
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
        if exist('onefly_run')==1
            runduration_secs_fly(i,period) = median(onefly_run);
            rundistribution_fly{i,period}= onefly_run;
            clear onefly_run
        end
        
        for p = 1:numel(all_stops{period}{i})
            stopsduration = length(all_stops{period}{i}{p}); %frames
            stopsduration_secs = stopsduration/framespertimebin; %in sec
            
            all_stopsduration_secs(period,m) = stopsduration_secs;
            m=m+1;
            
            %individual fly's mean of stop duration
            onefly_stop(p) = stopsduration_secs;
        end
        stopduration_secs_fly(i,period) = median(onefly_stop);
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

for odorpd = 1:2
    
    %histogram and plotting
    avg_velocity_hist = (0:(2/40):2);
    durationsecs_hist = (0:(40/100):40);
    stopsecs_hist = (0:(20/80):20);
    runlength_hist = (0:(17/40):17);%for what?
    
    %run duration plot
    subplot(2,3,1)
    
    cc = histc(all_runsduration_secs(odorpd,:),durationsecs_hist); %this gives actual n, occurrence
    cc1 = cc./total_run_no(odorpd);
    %     bar(durationsecs_hist, cc, 'histc'); hold on
    stairs(durationsecs_hist,cc1,'color',color(odorpd,:));hold on
    plot([avgrunduration(odorpd) avgrunduration(odorpd) ],[0 100],':','color',color(odorpd,:));
    
    xlim([0.1,40])
    ylim([0,.4]);
    set(gca, 'Xscale', 'log')
    
    xlabel('Run Duration (secs)');
    ylabel('probability');
    if odorpd ==1
        title({fig_title; period_name{odorpd};[' ']},'interpreter','none','fontweight','bold');
    elseif odorpd ==2
        title({[' '];period_name{odorpd};['Run Duration']},'interpreter','none','fontweight','bold');
    else
        title({period_name{odorpd};[' ']},'fontweight','bold');
    end
    
    %text(5, .25, ['# Runs = ' num2str(numruns(odorpd))], 'FontSize', 8);
    %text(5, .2, ['Avg. Run = ' num2str(avgrunduration(odorpd),'%4.2f') 's'], 'FontSize',8);
    %text(5, .15, ['Total Run Time = ' num2str(runsduration_total(odorpd),'%4.2f') 's'], 'FontSize', 8);
    
    set(gca,'box','off');
    
    
    %stop duration plot
    subplot(2,3,2);
    
    cc = histc(all_stopsduration_secs(odorpd,:),stopsecs_hist);
    cc1 = cc./total_stop_no(odorpd);
    %     bar(stopsecs_hist, cc, 'histc');hold on
    stairs(stopsecs_hist,cc1,'color',color(odorpd,:));hold on
    
    plot([avgstopduration(odorpd) avgstopduration(odorpd)],[0 100],':','color',color(odorpd,:));
    
    xlim([0.2,20])
    ylim([0,.5])
    set(gca, 'Xscale', 'log')
    xlabel('Stops Duration (secs)');
    ylabel('probability');
    if odorpd ==2
        title('Stop Duration','fontweight','bold');
    end
    
    % text(5, .3, ['# Stops = ' num2str(numstops(odorpd))], 'FontSize', 8);
    % text(5, .37, ['Avg. Stop = ' num2str(avgstopduration(odorpd),'%4.2f') 's'], 'FontSize', 8);
    % text(5, .44, ['Total Stop Time = ' num2str(stopduration_total(odorpd),'%4.2f') 's'], 'FontSize',8);
    set(gca,'box','off');
    
    rundata.all_stopsduration_secs=all_stopsduration_secs;
    rundata.all_avg_velocity=all_avg_velocity;
    rundata.all_runsduration_secs=all_runsduration_secs;
    %average velocity plot
    subplot(2,3,3);
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
    ylim ([0 .5]);
    xlim ([0.1 2]);
    set(gca, 'Xscale', 'log')
    if odorpd ==2
        title('Average velocity of runs','fontweight','bold');
    end
    
    % text(.5, .13, ['avg. vel./run = ' num2str(avgavgvel(odorpd),'%4.2f') 'cm/sec'], 'fontsize', 8);
    %text(.5, .11, ['avg. vel./all runs = ' num2str(avgavgvel2(odorpd),'%4.2f') 'cm/sec'], 'fontsize', 8);
    set(gca,'box','off');
    
    %     statistics_eachvid(odorpd,:) = {runsduration_secs, stopsduration_secs, avg_velocity, distance_final};
    %
    %     clear runsduration runsduration_secs distance_final avg_velocity stopsduration stopsduration_secs
    
end

% run duration: distribution among flies
subplot(2,3,4)
h = boxplot([runduration_secs_fly(:,1),runduration_secs_fly(:,2),runduration_secs_fly(:,3)],'color',[0 0 0]);hold on
%get median value of the 'before' run velocity
baseline = median(runduration_secs_fly(:,1));
plot([0 4],[baseline baseline],'k:');
%individual fly's runduration
for i=1:numflies
    ratio_run_duration=runduration_secs_fly(i,1)/runduration_secs_fly(i,2);
end
for i=1:3
    plot(i,runduration_secs_fly(:,i),'.','color',color(i,:));
end
% ylabel('velocity')

ylim([0 30]); xlim([.5 3.5]);
title(['distribution of run duration (median)']);
set(gca,'Xtick',1:3,'XTickLabel',{'before','during','after'},'Ytick',0:5:100);
set(gca,'box','off');

% stop duration: distribution among flies
subplot(2,3,5)
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
subplot(2,3,6)

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

set(gcf,'PaperPositionMode','auto'); 
set(gcf,'paperorientation','landscape');
print(gcf,'-dpdf','-r300',[analysis_file(1:end-15) ' run_stop.pdf']);

durationsecs_hist = (0:(40/80):40);
rundata.run_vel_avg_fly=run_vel_avg_fly;
rundata.stopduration_secs_fly=stopduration_secs_fly;
rundata.runduration_secs_fly=runduration_secs_fly;


figure
set(gcf,'position',[200 200 800 600]);

runhist_before=nan(numflies,length(durationsecs_hist));
runhist_during=nan(numflies,length(durationsecs_hist));

subplot(2,1,1)
for i=1:numflies
    %subplot(4,7,i)
    run_before=rundistribution_fly{i,1};
    if length(run_before)>0
        length(run_before)
        bb= histc(run_before,durationsecs_hist);
        bb1= bb./length(run_before);
        runhist_before(i,:)=bb1;
        plot(durationsecs_hist,bb1,'color',color(1,:));hold on
    end
    
    run_during=rundistribution_fly{i,2};
    if length(run_during)>0
        length(run_during)
        bbb=histc(run_during,durationsecs_hist);
        bbb1= bbb./length(run_during);
        runhist_during(i,:)=bbb1;
        plot(durationsecs_hist,bbb1,'color',color(2,:));%hold on
    end
end
%set(gca, 'Xscale', 'log')

%subplot(2,1,2)
% for i=1:numflies
%     subplot(3,7,i)
%  run_during=rundistribution_fly{i,2};
%   if length(run_during)>1
%       length(run_during)
%       bbb=histc(run_during,durationsecs_hist);
%       bbb1= bbb./length(run_during);
%       runhist_during(i,:)=bbb1;
%      plot(durationsecs_hist,bbb1,'color',color(2,:));%hold on
%   end
% end
set(gca, 'Xscale', 'log')
runhist_before_avg=nanmean(runhist_before,1);
runhist_during_avg=nanmean(runhist_during,1);
rundata.runhist_before=runhist_before;
rundata.runhist_during=runhist_during;
rundata.runhist_before_avg=runhist_before_avg;
rundata.runhist_during_avg=runhist_during_avg;

%subplot(4,7,[25 28])
subplot(2,1,2)
plot(durationsecs_hist,runhist_before_avg,'-*','color',color(1,:));hold on;
plot(durationsecs_hist,runhist_during_avg,'-*','color',color(2,:));hold on;
ylim([0 .25]);
%set(gca, 'Xscale', 'log')
%  cc = histc(all_runsduration_secs(odorpd,:),durationsecs_hist); %this gives actual n, occurrence
%     cc1 = cc./total_run_no(odorpd);
%     %     bar(durationsecs_hist, cc, 'histc'); hold on
%     stairs(durationsecs_hist,cc1,'color',color(odorpd,:));hold on
%     plot([avgrunduration(odorpd) avgrunduration(odorpd) ],[0 100],':','color',color(odorpd,:));
%
%     xlim([0.1,40])
%     ylim([0,.4]);
%     set(gca, 'Xscale', 'log')
for i=1:numflies
    ratio_run_duration(i)=runduration_secs_fly(i,1)/runduration_secs_fly(i,2);
    ratio_stop_duration(i)=stopduration_secs_fly(i,1)/stopduration_secs_fly(i,2);
    ratio_run_vel(i)=run_vel_avg_fly(i,1)/run_vel_avg_fly(i,2);
end
title([fig_title 'Run_duration']);

set(gcf,'PaperPositionMode','auto'); 
set(gcf,'paperorientation','landscape');
print(gcf,'-dpdf','-r300',[analysis_file(1:end-15) ' run_histogram.pdf']);


figure
set(gcf,'position',[100 300 1000 400]);

subplot(1,3,1)
plot(1,ratio_run_duration,'*');set(gca, 'yscale', 'log');
hold on
plot([0.5 1.5],[1 1],'k:');
title('during/before run duration');

subplot(1,3,2)
plot(1,ratio_stop_duration,'*');set(gca, 'yscale', 'log')
hold on
plot([0.5 1.5],[1 1],'k:');
title('during/before stop duration');

subplot(1,3,3)
plot(1,ratio_run_vel,'*');set(gca, 'yscale', 'log')
hold on
plot([0.5 1.5],[1 1],'k:');
title('during/before run velocity');

set(gcf,'PaperPositionMode','auto'); 
set(gcf,'paperorientation','landscape');
print(gcf,'-dpdf','-r300',[analysis_file(1:end-15) ' run_velocity.pdf']);


filename=[user_input '_runhist'];
save(filename,'rundata');

%% multiple_flies_angular_periods

% user_input1= input('Enter the fly genotype : ','s');
% user_input2 = input('Enter the odor name and concentration : ' ,'s');
% user_input = [user_input1 ' ' user_input2];
curv_before_in=nan(10950,numflies);
curv_during_in=nan(10950,numflies);
curv_during_out=nan(10950,numflies);
curv_before_out=nan(10950,numflies);
k=1;l=1;m=1;n=1;
for i=1:numflies
    curvature=curvature_flies(:,i);
    odoron=odoron_frame(i);
    insiderim=inside_rim(:,i);
    for ii=1:timeperiods(3)
        if ii<odoron
            if inside_rim(ii) == 1 %if fly is inside
                curv_before_in(k,i) = curvature(ii);
                k = k+1;
            else % if fly is outside
                curv_before_out(l,i) = curvature(ii);
                l=l+1;
            end
            
        elseif (ii >= odoron && ii < timeperiods(3)) %during
            if inside_rim(ii) == 1 %if fly is inside
                curv_during_in(m,i) = curvature(ii);
                m = m+1;
            else % if fly is outside
                curv_during_out(n,i) = curvature(ii);
                n=n+1;
            end
        end
    end
    k=1;l=1;m=1;n=1;
end
abs_curv_before_in=abs(curv_before_in);
abs_curv_during_in=abs(curv_during_in);
abs_curv_during_out=abs(curv_during_out);
abs_curv_before_out=abs(curv_before_out);

angular_velocity_before_in=nanmean(abs_curv_before_in,1);
angular_velocity_during_in=nanmean(abs_curv_during_in,1);
angular_velocity_during_out=nanmean(abs_curv_during_out,1);
angular_velocity_before_out=nanmean(abs_curv_before_out,1);

data.angular_velocity_before_in=angular_velocity_before_in;
data.angular_velocity_during_in=angular_velocity_during_in;
data.angular_velocity_during_out=angular_velocity_during_out;
data.angular_velocity_before_out=angular_velocity_before_out;

avg_angular_velocity_before_in=mean(angular_velocity_before_in);
avg_angular_velocity_during_in=mean(angular_velocity_during_in);
avg_angular_velocity_during_out=mean(angular_velocity_during_out);
avg_angular_velocity_before_out=mean(angular_velocity_before_out);

avg_ang_out=[avg_angular_velocity_before_out avg_angular_velocity_during_out];
avg_ang_in=[avg_angular_velocity_before_in avg_angular_velocity_during_in];

ang_out=[angular_velocity_before_out ;angular_velocity_during_out];
ang_in=[angular_velocity_before_in; angular_velocity_during_in];

%%
figure

subplot(2,1,1)
for n=1:2
    b=bar(n,avg_ang_in(n));
    set(b,'edgecolor','w','facecolor',color(n,:));
    hold on
    plot(n,ang_in(n,:),'.');
end

for n=1:numflies
    plot(ang_in(:,n));
end

xlim([0 3]);
title('angular velocity inside');

subplot(2,1,2)
for n=1:2
    b=bar(n,avg_ang_out(n));
    set(b,'edgecolor','w','facecolor',color(n,:));
    hold on
    plot(n,ang_out(n,:),'.');
end

for n=1:numflies
    plot(ang_out(:,n));
end
xlim([0 3]);
title('angular velocity outside');

set(gcf,'PaperPositionMode','auto'); 
set(gcf,'paperorientation','landscape');
print(gcf,'-dpdf','-r300',[analysis_file(1:end-15) ' angular_velocity.pdf']);


%xlim([0.5 2.5]);
%ylim([0 120]);
filename=[user_input '_angular_velocity'];
save(filename,'data');

%% multiple_flies_turning_analysis_plotter_new

%for multiple_flies_analysis_V17
% 1. This script plots the sharp turns + curved walking in  'during' period
% 2. turn/curving frequency or fraction in three periods

% plot the 'during' period fly's walking trajectory + sharp turns (red, o)
% + curving/turning (blue dots) for all the flies
%
% fig_count1 = 0;
% for a = 1:numflies
%     if rem(fly_no(a),8) == 1 %first subplot, create a figure window
%         figure
%         set(gcf,'Position',[434 58 1200 600],'color','white')
%         fig_no = fig_no+1;
%     end
%
%     if rem(fly_no(a),8) == 0 %8th subplot
%         sp = 8;
%     else
%         sp = rem(fly_no(a),8);
%     end
%
%     subplot(2,4,sp)
%     %     for a=1:1
%     x_for_fly = numvals(:,2*a-1);
%     y_for_fly = numvals(:,2*a);
%
%
%     %     plot(x_for_fly(1:timeperiods(2)), y_for_fly(1:timeperiods(2)), '-g', 'LineWidth',1);hold on
%     %
%     %     plot(x_for_fly(odoroff_frame:timeperiods(4)), y_for_fly(odoroff_frame:timeperiods(4)), 'b', 'LineWidth',1);
%     hold on
%     %     plot(x_for_fly(timeperiods(2):odoron_frame(a)),...
%     %         y_for_fly(timeperiods(2):odoron_frame(a)), 'color',grey, 'LineWidth',1);
%     plot(x_for_fly(odoron_frame(a):timeperiods(3)),...
%         y_for_fly(odoron_frame(a):timeperiods(3)),'color',grey, 'LineWidth',1);
%
%     plot(numvals_pi{a}(:,1), numvals_pi{a}(:,2), 'k', 'LineWidth',1);
%     plot(numvals_po{a}(:,1), numvals_po{a}(:,2), 'k', 'LineWidth',1);
%     %original inner rim
%     plot(numvals_pi_ori{a}(:,1), numvals_pi_ori{a}(:,2), 'k--', 'LineWidth',1);
%
%     curving = curv_period_flies{2,a};
%     plot(x_for_fly(curving), y_for_fly(curving),'b.','markersize',2);
%
%     sh_turn = turn_flies{2,a};
%     plot(x_for_fly(sh_turn),y_for_fly(sh_turn),'mo');
%
%     set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
%     axis tight;
%
%     namestring = tracks(a);
%     namestring = cellfun(@(x)x(1:13), namestring, 'UniformOutput', false);
%
%     b = rem(a,20)+1;
%     xlabel(namestring{1},'fontsize',8,'color',cmap(b,:));
%
%     if sp == 1
%         title(fig_title,'fontsize',12);
%     end
%
%     if sp == 8 %every time the figure is full, save it
%         set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
%         if fig_no ==1 %first
%             print('-dpsc2',[fig_title '.ps'],'-loose');
%             fig_count1 = fig_count1+1;
%             saveas(gcf,[fig_title '_during_turning'  num2str(fig_count) '.fig']);
%         else
%             fig_count1 = fig_count1+1;
%             saveas(gcf,[fig_title '_during_turning'  num2str(fig_count) '.fig']);
%             print('-dpsc2',[fig_title '.ps'],'-loose','-append');
%         end
%
%     elseif a == numflies %if this is the last fly, save the figure
%         set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
%         if fig_no ==1 %first
%             print('-dpsc2',[fig_title '.ps'],'-loose');
%             fig_count1 = fig_count1+1;
%             saveas(gcf,[fig_title '_during_turning'  num2str(fig_count) '.fig']);
%         else
%             fig_count1 = fig_count1+1;
%             saveas(gcf,[fig_title '_during_turning' num2str(fig_count) '.fig']);
%             print('-dpsc2',[fig_title '.ps'],'-loose','-append');
%         end
%     end
%
% end
%


%%

figure
set(gcf,'position',[200 20 700 1000])

%turning/curving fraction
subplot(4,3,1)
%curving, frq avg + std
curv_rate_avg = nanmean(curv_fr_flies,2);
curv_rate_std = nanstd(curv_fr_flies,0,2);
curv_rate_SEM = curv_rate_std/(sqrt(numflies -1));

for period = 1:3
    b = bar(period,curv_rate_avg(period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
end
errorbar(curv_rate_avg,curv_rate_std,'k');

h = ttest(curv_fr_flies(1,:),curv_fr_flies(2,:));
if h== 1
    text(2,curv_rate_avg(2)+.1,'*','fontsize',12);
end

set(gca,'Box','off','TickDir','out','Ytick',(0:.2:1));
ylim([0,1]);

title({fig_title;'fraction of curved walking'});

subplot(4,3,2)
%sharp turn, frq avg + std
curv_rate_in_avg = nanmean(curv_fr_in_flies,2);
curv_rate_in_std = nanstd(curv_fr_in_flies,0,2);
curv_rate_in_SEM = curv_rate_std/(sqrt(numflies -1));
radial.curv_fr_in_flies=curv_fr_in_flies;

for period = 1:3
    b = bar(period,curv_rate_in_avg(period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
end
errorbar(curv_rate_in_avg,curv_rate_in_std,'k');

h= ttest(curv_fr_in_flies(1,:),curv_fr_in_flies(2,:));
if h== 1
    text(2,curv_rate_in_avg(2)+.2,'*','fontsize',12);
end

set(gca,'Box','off','TickDir','out','Ytick',(0:.2:1));
ylim([0,1]);

title('fraction of curved walking (Inside)');


subplot(4,3,3)
%sharp turn, frq avg + std (in only)
curv_rate_out_avg = nanmean(curv_fr_out_flies,2);
curv_rate_out_std = nanstd(curv_fr_out_flies,0,2);
curv_rate_out_SEM = curv_rate_out_std/(sqrt(numflies -1));
radial.curv_fr_out_flies=curv_fr_out_flies;
for period = 1:3
    b = bar(period,curv_rate_out_avg(period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
end
errorbar(curv_rate_out_avg,curv_rate_out_std,'k');

h = ttest(curv_fr_out_flies(1,:),curv_fr_out_flies(2,:));
if h== 1
    text(2,curv_rate_out_avg(2)+.2,'*','fontsize',12);
end

set(gca,'Box','off','TickDir','out','Ytick',(0:.2:1));
ylim([0,1]);

title('fraction of curved walking (Outside)');

subplot(4,3,4)
%sharp turn, frq avg + std
turn_rate_avg = nanmean(turn_rate_flies,2);
turn_rate_std = nanstd(turn_rate_flies,0,2);
turn_rate_SEM = turn_rate_std/(sqrt(numflies -1));

for period = 1:3
    b = bar(period,turn_rate_avg(period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
end
errorbar(turn_rate_avg,turn_rate_std,'k');

h = ttest(turn_rate_flies(1,:),turn_rate_flies(2,:));
if h==1
    text(2,turn_rate_avg(2)+.1,'*','fontsize',12);
end

set(gca,'Box','off','TickDir','out','Ytick',(0:.2:1));
ylim([0,1]);

title('turn frequency (#/sec)');

subplot(4,3,5)
%sharp turn, frq avg + std (in only)
turn_rate_in_avg = nanmean(turn_rate_in_flies,2);
turn_rate_in_std = nanstd(turn_rate_in_flies,0,2);
turn_rate_in_SEM = turn_rate_in_std/(sqrt(numflies -1));
radial.turn_rate_in_flies=turn_rate_in_flies;
for period = 1:3
    b = bar(period,turn_rate_in_avg(period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
end
errorbar(turn_rate_in_avg,turn_rate_in_std,'k');

h = ttest(turn_rate_in_flies(1,:),turn_rate_in_flies(2,:));
if h== 1
    text(2,turn_rate_in_avg(2)+.1,'*','fontsize',12);
end

set(gca,'Box','off','TickDir','out','Ytick',(0:.2:1));
ylim([0,1]);

title('turn frequency INSIDE(#/sec)');

subplot(4,3,6)
%sharp turn, frq avg + std (in only)
turn_rate_out_avg = nanmean(turn_rate_out_flies,2);
turn_rate_out_std = nanstd(turn_rate_out_flies,0,2);
turn_rate_out_SEM = turn_rate_out_std/(sqrt(numflies -1));
radial.turn_rate_out_flies=turn_rate_out_flies;
for period = 1:3
    b = bar(period,turn_rate_out_avg(period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
end
errorbar(turn_rate_out_avg,turn_rate_out_std,'k');

h = ttest(turn_rate_out_flies(1,:),turn_rate_out_flies(2,:));
if h== 1
    text(2,turn_rate_out_avg(2)+.1,'*','fontsize',12);
end

set(gca,'Box','off','TickDir','out','Ytick',(0:.2:1));
ylim([0,1]);

title('turn frequency OUTSIDE(#/sec)');



%==========================================================================
%sharp turnings inside the specified ring area

% Curved walk fraction, sharp turn frequency inside the ring
% ring_outer_radius_rings = linspace(1.5,1.9,NumRings);

subplot(4,3,7) %before VS during, in all the rings (mean +/- std)

%first get bf/dr/af data from 3d matrix, convert them to 2d arrays
curv_fr_ring_period_bf = curv_fr_ring_period_flies(1,:,:);
curv_fr_ring_bf =squeeze(curv_fr_ring_period_bf);
curv_fr_ring_period_dr = curv_fr_ring_period_flies(2,:,:);
curv_fr_ring_dr =squeeze(curv_fr_ring_period_dr);
curv_fr_ring_period_af = curv_fr_ring_period_flies(3,:,:);
curv_fr_ring_af =squeeze(curv_fr_ring_period_af);

%get the average for each period
bf = nanmean(curv_fr_ring_bf);
dr = nanmean(curv_fr_ring_dr);
af = nanmean(curv_fr_ring_af);
curv_fr_ring_period_avg = vertcat(bf,dr,af);
%std
bf = nanstd(curv_fr_ring_bf);
dr = nanstd(curv_fr_ring_dr);
af = nanstd(curv_fr_ring_af);
curv_fr_ring_period_std = vertcat(bf,dr,af);

%before VS during comparison
curv_h = nan(1,NumRings);
curv_p = nan(1,NumRings);
for  n=1:NumRings
    [h,p] = ttest(curv_fr_ring_bf(:,n),curv_fr_ring_dr(:,n))
    curv_h(n) = h;
    curv_p(n) = p;
end


%individual fly data
for n=1:NumRings
    plot(n,curv_fr_ring_bf(:,n),'go','markersize',2);
    hold on
    plot(n,curv_fr_ring_dr(:,n),'ro','markersize',2);
end

%mean + std
for n=1:2
    plot(curv_fr_ring_period_avg(n,:),'s-','color',color(n,:));
    hold on
    errorbar(curv_fr_ring_period_avg(n,:),curv_fr_ring_period_std(n,:),'color',color(n,:));
end

for n=1:NumRings
    if curv_h(n) > 0 %if the null hypothesis is rejected
        text(n+.2,curv_fr_ring_period_avg(2,n)+.01,'*');
    end
end

xlim([0.5 5.5]);
ylim([0 1]);
set(gca,'ytick',(0:.2:2),'box','off','xtick',[1:5],'xticklabel',ring_outer_radius_rings);
xlabel('radius of outer ring');
title({'Mean of curved walk fraction'; 'in Before and During periods'});


subplot(4,3,8) % During only, mean + individual flies

curv_fr_ring_period_dr = curv_fr_ring_period_flies(2,:,:);%during
curv_fr_ring_dr =squeeze(curv_fr_ring_period_dr);

curv_fr_ring_avg = nanmean(curv_fr_ring_dr);%mean
curv_fr_ring_std = nanstd(curv_fr_ring_dr);%std

for n=1:NumRings
    b = bar(n,curv_fr_ring_avg(n));hold on
    set(b,'Edgecolor','w','FaceColor',grey);
    plot(n,curv_fr_ring_flies(:,n),'.');
    
end
errorbar(curv_fr_ring_avg,curv_fr_ring_std,'k');

for n=1:numflies
    plot(curv_fr_ring_flies(n,:),'color',cmap(rem(n,20)+1,:));
end
xlim([0.5 5.5]);
ylim([0 1]);
set(gca,'ytick',(0:.2:2),'box','off','xtick',[1:5],'xticklabel',ring_outer_radius_rings);
xlabel('radius of outer ring');

title(' fraction of curved walk (during)');


subplot(4,3,9) %before VS during in one ring
ringID = 1;%which ring to choose

curv_fr_ring_oneRing(:,1) = curv_fr_ring_bf(:,ringID);%before
curv_fr_ring_oneRing(:,2) = curv_fr_ring_dr(:,ringID); %during

for n=1:2
    b=bar(n,curv_fr_ring_period_avg(n,ringID));
    set(b,'edgecolor','w','facecolor',color(n,:));
    hold on
    plot(n,curv_fr_ring_oneRing(:,n),'.');
end

for n=1:numflies
    plot(curv_fr_ring_oneRing(n,:),'color',cmap(rem(n,20)+1,:));
end

xlim([0.5 2.5]);
ylim([0 1]);
set(gca,'xtick',[],'ytick',(0:.2:1),'box','off');

title({'Before VS During in a ring' ;...
    ['radius between ' num2str(ring_inner_radius_rings(ringID)) ' and ' num2str(ring_outer_radius_rings(ringID))]});


%Sharp turns
subplot(4,3,10) %before VS during, in all the rings (mean +/- std)
%multiplying to get the number and not fraction
mult_fact=cellfun(@length,fly_in_ring_period_flies);
turn_fr_ring_period_flies=(times(turn_fr_ring_period_flies,mult_fact))/30;

%first get bf/dr/af data from 3d matrix, convert them to 2d arrays
turn_fr_ring_period_bf = turn_fr_ring_period_flies(1,:,:);
turn_fr_ring_bf =squeeze(turn_fr_ring_period_bf);
turn_fr_ring_period_dr = turn_fr_ring_period_flies(2,:,:);
turn_fr_ring_dr =squeeze(turn_fr_ring_period_dr);
turn_fr_ring_period_af = turn_fr_ring_period_flies(3,:,:);
turn_fr_ring_af =squeeze(turn_fr_ring_period_af);

%get the average for each period
bf = nanmean(turn_fr_ring_bf);
dr = nanmean(turn_fr_ring_dr);
af = nanmean(turn_fr_ring_af);
turn_fr_ring_period_avg = vertcat(bf,dr,af);
%std
bf = nanstd(turn_fr_ring_bf);
dr = nanstd(turn_fr_ring_dr);
af = nanstd(turn_fr_ring_af);
turn_fr_ring_period_std = vertcat(bf,dr,af);

turn_h = nan(1,NumRings);
turn_p = nan(1,NumRings);
for  n=1:NumRings
    [h,p] = ttest(turn_fr_ring_bf(:,n),turn_fr_ring_dr(:,n))
    turn_h(n) = h;
    turn_p(n) = p;
end

%individual fly data
for n=1:NumRings
    plot(n,turn_fr_ring_bf(:,n),'go','markersize',2);
    hold on
    plot(n,turn_fr_ring_dr(:,n),'ro','markersize',2);
end

for n=1:2
    plot(turn_fr_ring_period_avg(n,:),'s-','color',color(n,:));
    hold on
    errorbar(turn_fr_ring_period_avg(n,:),turn_fr_ring_period_std(n,:),'color',color(n,:));
end


for n=1:NumRings
    if turn_h(n) > 0 %if the null hypothesis is rejected
        text(n+.2,turn_fr_ring_period_avg(2,n)+.01,'*');
    end
end
xlim([0.5 5.5]);
ylim([0 20]);
set(gca,'ytick',(0:.2:2),'box','off','xtick',[1:5],'xticklabel',ring_outer_radius_rings);
xlabel('radius of outer ring');
title({'Mean of sharp turn frequency'; 'in Before and During periods'});

radial.turnbefore=turn_fr_ring_bf;
radial.turnduring=turn_fr_ring_dr;
radial.rings = ring_outer_radius_rings;
filename=[user_input '_radialturn'];
save(filename,'radial');
subplot(4,3,11) % During only, mean + individual flies

for n=1:NumRings
    b = bar(n,turn_fr_ring_period_avg(2,n));hold on
    set(b,'Edgecolor','w','FaceColor',grey);
    plot(n,turn_fr_ring_dr(:,n),'.');
    
end
errorbar(turn_fr_ring_period_avg(2,:),turn_fr_ring_period_std(2,:),'k');

for n=1:numflies
    plot(turn_fr_ring_dr(n,:),'color',cmap(rem(n,20)+1,:));
end
xlim([0.5 5.5]);
ylim([0 50]);
set(gca,'ytick',(0:.2:2),'box','off','xtick',[1:5],'xticklabel',ring_outer_radius_rings);
xlabel('radius of outer ring');

title(' frequency of sharp turns(during)');


subplot(4,3,12) %before VS during in one ring
ringID = 1;%which ring to choose

turn_fr_ring_oneRing(:,1) = turn_fr_ring_bf(:,ringID);%before
turn_fr_ring_oneRing(:,2) = turn_fr_ring_dr(:,ringID); %during

for n=1:2
    b=bar(n,turn_fr_ring_period_avg(n,ringID));
    set(b,'edgecolor','w','facecolor',color(n,:));
    hold on
    plot(n,turn_fr_ring_oneRing(:,n),'.');
end

for n=1:numflies
    plot(turn_fr_ring_oneRing(n,:),'color',cmap(rem(n,20)+1,:));
end

xlim([0.5 2.5]);
ylim([0 50]);
set(gca,'xtick',[],'ytick',(0:.2:2),'box','off');

title({'Before VS During in a ring' ;...
    ['radius between  ' num2str(ring_inner_radius_rings(ringID)) ' and ' num2str(ring_outer_radius_rings(ringID))]});

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
saveas(gcf,[fig_title '_turn_analysis.png']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');
print('-depsc2',[fig_title 'turns.eps']);
close all
