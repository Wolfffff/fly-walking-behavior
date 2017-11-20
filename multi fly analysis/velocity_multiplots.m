% function [vel_fig] = velocity_multiplots(velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr,...
%     velocity_o2i_ind_avg_af,velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,...
%     velocity_i2o_ind_avg_af,velocity_o2i_avg,velocity_i2o_avg,velocity_o2i_SEM,...
%     velocity_i2o_SEM,...
%     framespertimebin,x_range,vel_unit,vel_ylim,frame_norm,crossing_min)
% This function generates a figure with 6X2 subplots that include 
% 1. individual fly's average (mean) velocity, that only include flies that
% went into OZ more than 'crossing_min' : Before and During. 
% To show 'after' period as well, change the for loop from i=1:2 to 1:3
% 2. Average (mean of means) for 'before' and 'during' and standard error
% of means (SEM) iindicated as shaded area
% 3. Binned data, t-tested, then points with p<0.05 are marked
% 4. normalized average + SEM
% 5. t-test for normalized + binned data

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

numflies_used = size(velocity_o2i_ind_avg_bf,2);

figure
set(gcf,'color','white','Position',[520 20 700 750]);

period_name = {'Before','During','After'};

%for crossing out2in
for i=1:2 %before and during only
    
    subplot(6,2,2*i-1)
    if i==1 %before
        for h = 1:numflies_used
            p = rem(h,20)+1;
            plot (x_range,velocity_o2i_ind_avg_bf(:,h),'color', cmap(p,:));hold on
            
        end
    elseif i==2 %during
        for h = 1:numflies_used
            p = rem(h,20)+1;
            plot (x_range,velocity_o2i_ind_avg_dr(:,h),'color', cmap(p,:)); hold on
            
        end
    else %after
        for h = 1:numflies_used
            p = rem(h,20)+1;
            plot (x_range,velocity_o2i_ind_avg_af(:,h),'color', cmap(p,:)); hold on        
        end
    end
    plot(x_range,velocity_o2i_avg(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([min(x_range) max(x_range)+1/framespertimebin]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    if i==1
    title(['Crossing in: ' period_name{i} ' (crossing #>' num2str(crossing_min) ', fly#=' num2str(numflies_used) ')'],'fontsize',9);
    else
        title(period_name{i});
    end
    xlabel('time (sec)','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
    
end


%for crossing in2out:
for i=1:2 %before and during only
    
    subplot(6,2,2*i)
    if i==1 %before
       for h = 1:numflies_used
            p = rem(h,20)+1;
            plot (x_range,velocity_i2o_ind_avg_bf(:,h),'color', cmap(p,:));hold on
        end
    elseif i==2 %during
        for h = 1:numflies_used
            p = rem(h,20)+1;
            plot (x_range,velocity_i2o_ind_avg_dr(:,h),'color', cmap(p,:)); hold on
        end
    else %after
         for h = 1:numflies_used
            p = rem(h,20)+1;
            plot (x_range,velocity_i2o_ind_avg_af(:,h),'color', cmap(p,:)); hold on        
        end
    end
    plot(x_range,velocity_i2o_avg(:,i),'linewidth',1.5,'color',color(i,:));
    xlim([min(x_range) max(x_range)+1/framespertimebin]);
    ylim ([0 vel_ylim(2)])
    plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
    if i==1
    title(['Crossing Out: ' period_name{i}],'fontsize',9);
    else
        title(period_name{i});
    end
    xlabel('frame number','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
end

%average + SEM
velocity_o2i_avg_trans = velocity_o2i_avg';
velocity_o2i_SEM_trans = velocity_o2i_SEM';
velocity_i2o_avg_trans = velocity_i2o_avg';
velocity_i2o_SEM_trans = velocity_i2o_SEM';

subplot(6,2,5)
for i=1:2
    SEM_y_plot = [velocity_o2i_avg_trans(i,:)- velocity_o2i_SEM_trans(i,:);(2*velocity_o2i_SEM_trans(i,:))];
    h = area(x_range,SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    plot(x_range,velocity_o2i_avg(:,i),'color',color(i,:),'linewidth',1.5); hold on
end
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing in');

subplot(6,2,6)
for i=1:2
    SEM_y_plot = [velocity_i2o_avg_trans(i,:)- velocity_i2o_SEM_trans(i,:);(2*velocity_i2o_SEM_trans(i,:))];
    h = area(x_range,SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on

    plot(x_range,velocity_i2o_avg(:,i),'color',color(i,:),'linewidth',1.5); hold on
end
plot([1/framespertimebin 1/framespertimebin],[0 2],'k:') %dotted line marking 0
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing out');

%binned and t-tested
subplot(6,2,7)
plot(bin_x,vel_o2i_bin_mean(:,1),'g.-'); hold on
plot(bin_x,vel_o2i_bin_mean(:,2),'r.-')

for bin_no = 1:numBins
   if vel_o2i_by_bin_h(bin_no) == 1
       text(bin_x(bin_no),vel_o2i_bin_mean(bin_no,2), '*','fontsize',12);
   end
end
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])
title(['binned data (' num2str(how_long/numBins) ' frames/bin)']);

subplot(6,2,8)
plot(bin_x,vel_i2o_bin_mean(:,1),'g.-'); hold on
plot(bin_x,vel_i2o_bin_mean(:,2),'r.-')

for bin_no = 1:numBins
   if vel_i2o_by_bin_h(bin_no) == 1
       text(bin_x(bin_no),vel_i2o_bin_mean(bin_no,2), '*','fontsize',12);
   end
end
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)-1])
title(['p< .05']);

%normalization of velocity so that velocity right before crossing is similar
%get the average between -1 and 0 sec, then subtract from original
%velocity

%frame_norm defines which time period to use to get the average

%To use the flies that crossed more than pre-set crossing numbers, use
%'flies_used', not 'numflies'

[vel_norm_o2i,vel_norm_i2o,vel_norm_o2i_SEM,vel_norm_i2o_SEM,...
    vel_o2i_norm_before_flies,vel_o2i_norm_during_flies,vel_o2i_norm_after_flies,...
    vel_i2o_norm_before_flies,vel_i2o_norm_during_flies,vel_i2o_norm_after_flies] = ...
    velocity_normalizer(velocity_o2i_avg,velocity_i2o_avg,...
    velocity_o2i_before_cell,velocity_o2i_during_cell,velocity_o2i_after_cell,...
    velocity_i2o_before_cell,velocity_i2o_during_cell,velocity_i2o_after_cell,...
    frame_norm,flies_used);

y_lim_for_plot = [-.6 .6];


subplot(6,2,9)
%first plot errobars using area function
%refer to average_errorbar_plotting.m
%first transpose the arrays
vel_norm_o2i_trans = vel_norm_o2i';
vel_norm_o2i_SEM_trans = vel_norm_o2i_SEM';

SEM_y_plot = [vel_norm_o2i_trans(1,:)- vel_norm_o2i_SEM_trans(1,:);(2*vel_norm_o2i_SEM_trans(1,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','g','EdgeColor','none');
alpha(.2);
hold on
plot(x_range,vel_norm_o2i(:,1),'g','linewidth',1.5)

SEM_y_plot= [vel_norm_o2i_trans(2,:)- vel_norm_o2i_SEM_trans(2,:);(2*vel_norm_o2i_SEM_trans(2,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','r','EdgeColor','none');
alpha(.2);
plot(x_range,vel_norm_o2i(:,2),'r','linewidth',1.5)
% plot(x_range,vel_norm_o2i(:,3))
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')

xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('normalized from average of an individual fly');

subplot(6,2,10)

vel_norm_i2o_trans = vel_norm_i2o';
vel_norm_i2o_SEM_trans = vel_norm_i2o_SEM';

SEM_y_plot = [vel_norm_i2o_trans(1,:)- vel_norm_i2o_SEM_trans(1,:);(2*vel_norm_i2o_SEM_trans(1,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','g','EdgeColor','none');
alpha(.2);
hold on
plot(x_range,vel_norm_i2o(:,1),'g','linewidth',1.5)

SEM_y_plot = [vel_norm_i2o_trans(2,:)- vel_norm_i2o_SEM_trans(2,:);(2*vel_norm_i2o_SEM_trans(2,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','r','EdgeColor','none');
alpha(.2);
plot(x_range,vel_norm_i2o(:,2),'r','linewidth',1.5)
% plot(x_range,vel_norm_i2o(:,3))

plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)
title(['baseline: from ' num2str(frame_norm(1)) ' to ' num2str(frame_norm(end))]);

%bin normalized velocity data
%preallocate
bin_norm_vel_i2o_bf = nan(numBins,num_used_flies);
bin_norm_vel_i2o_dr = nan(numBins,num_used_flies);
bin_norm_vel_o2i_bf = nan(numBins,num_used_flies);
bin_norm_vel_o2i_dr = nan(numBins,num_used_flies);

for i=1:numBins
    flagBinMembers = (whichBin == i); %check each bin
    %i2o
    %before
    binMembers = vel_i2o_norm_before_flies(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_norm_vel_i2o_bf(i,:) = binMean;
    
    %during
    binMembers = vel_i2o_norm_during_flies(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_norm_vel_i2o_dr(i,:) = binMean;
    
    %o2i
    %before
    binMembers = vel_o2i_norm_before_flies(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_norm_vel_o2i_bf(i,:) = binMean;
    %during
    binMembers = vel_o2i_norm_during_flies(flagBinMembers,:); %get the corresponding run/stop probability for the bin
    binMean = nanmean(binMembers,1); %get the mean
    bin_norm_vel_o2i_dr(i,:) = binMean;
end


%mean of binned data
vel_norm_i2o_bin_mean(:,1) =  nanmean(bin_norm_vel_i2o_bf,2);
vel_norm_i2o_bin_mean(:,2) =  nanmean(bin_norm_vel_i2o_dr,2);
vel_norm_o2i_bin_mean(:,1) =  nanmean(bin_norm_vel_o2i_bf,2);
vel_norm_o2i_bin_mean(:,2) =  nanmean(bin_norm_vel_o2i_dr,2);


%one sample, ttest
%pre-allocate
vel_norm_i2o_by_bin_h = nan(1,numBins);
vel_norm_i2o_by_bin_p = nan(1,numBins);
vel_norm_i2o_by_bin_ci = nan(2,numBins);
vel_norm_o2i_by_bin_h = nan(1,numBins);
vel_norm_o2i_by_bin_p = nan(1,numBins);
vel_norm_o2i_by_bin_ci = nan(2,numBins);


for i=1:numBins
    [h, p, ci] = ttest(bin_norm_vel_i2o_bf(i,:),bin_norm_vel_i2o_dr(i,:));
    vel_norm_i2o_by_bin_h(i) = h;
    vel_norm_i2o_by_bin_p(i) = p;
    vel_norm_i2o_by_bin_ci(:,i) = ci;
    
    [h, p, ci] = ttest(bin_norm_vel_o2i_bf(i,:),bin_norm_vel_o2i_dr(i,:));
    vel_norm_o2i_by_bin_h(i) = h;
    vel_norm_o2i_by_bin_p(i) = p;
    vel_norm_o2i_by_bin_ci(:,i) = ci;
end

%binned and t-tested
subplot(6,2,11)
plot(bin_x,vel_norm_o2i_bin_mean(:,1),'g.-'); hold on
plot(bin_x,vel_norm_o2i_bin_mean(:,2),'r.-')

for bin_no = 1:numBins
   if vel_norm_o2i_by_bin_h(bin_no) == 1
       text(bin_x(bin_no),vel_norm_o2i_bin_mean(bin_no,2), '*','fontsize',12);
   end
end
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim(y_lim_for_plot)
title(['binned data (' num2str(how_long/numBins) ' frames/bin)']);

subplot(6,2,12)
plot(bin_x,vel_norm_i2o_bin_mean(:,1),'g.-'); hold on
plot(bin_x,vel_norm_i2o_bin_mean(:,2),'r.-')

for bin_no = 1:numBins
   if vel_norm_i2o_by_bin_h(bin_no) == 1
       text(bin_x(bin_no),vel_norm_i2o_bin_mean(bin_no,2), '*','fontsize',12);
   end
end
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim(y_lim_for_plot)
title(['p< .05']);

ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,[fig_title ' velocity at crossing events']);
set(tx,'fontweight','bold');

vel_fig = gcf;