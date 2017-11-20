function velocity_multiplots1(velocity_o2i_ind_avg_bf,velocity_o2i_ind_avg_dr,...
    velocity_o2i_ind_avg_af,velocity_i2o_ind_avg_bf,velocity_i2o_ind_avg_dr,...
    velocity_i2o_ind_avg_af,velocity_o2i_avg,velocity_i2o_avg,velocity_o2i_SEM,...
    velocity_i2o_SEM,vel_o2i_bin_mean,vel_i2o_bin_mean,...
    vel_o2i_bin_SEM,vel_i2o_bin_SEM,...
    vel_o2i_by_bin_h,vel_i2o_by_bin_h,...
    framespertimebin,how_long,x_range,bin_x,vel_unit,vel_ylim,crossing_min,numBins,...
    plots_row,plots_column)
% This function generates a figure with 6X2 subplots that include 
% 1. individual fly's average (mean) velocity, that only include flies that
% went into OZ more than 'crossing_min' : Before and During. 
% To show 'after' period as well, change the for loop from i=1:2 to 1:3
% 2. Average (mean of means) for 'before' and 'during' and standard error
% of means (SEM) iindicated as shaded area
% 3. Binned data, t-tested, then points with p<0.05 are marked

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
set(gcf,'color','white','Position',[520 20 700 1000]);

period_name = {'Before','During','After'};

%for crossing out2in
for i=1:2 %before and during only
    
    subplot(plots_row,plots_column,plots_column*i-1)
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
    title(['Crossing in: ' period_name{i} ' (fly#=' num2str(numflies_used) ')'],'fontsize',9);
    else
        title(period_name{i});
    end
    xlabel('time (sec)','fontsize',9);
    ylabel(vel_unit,'fontsize',9);
    set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
    
end


%for crossing in2out:
for i=1:2 %before and during only
    
    subplot(plots_row,plots_column,plots_column*i)
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

subplot(plots_row,plots_column,5)
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
ylim ([0 vel_ylim(2)/2])

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing in');

subplot(plots_row,plots_column,6)
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
ylim ([0 vel_ylim(2)/2])

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('Mean of velocity at crossing out');

%binned and t-tested
%average + SEM
vel_o2i_bin_mean_trans= vel_o2i_bin_mean';
vel_o2i_bin_SEM_trans = vel_o2i_bin_SEM';
vel_i2o_bin_mean_trans =vel_i2o_bin_mean';
vel_i2o_bin_SEM_trans = vel_i2o_bin_SEM';

%OUT2IN
subplot(plots_row,plots_column,7)
for i=1:2
    SEM_y_plot = [vel_o2i_bin_mean_trans(i,:)- vel_o2i_bin_SEM_trans(i,:);(2*vel_o2i_bin_SEM_trans(i,:))];
    h = area(bin_x,SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    
    plot(bin_x,vel_o2i_bin_mean(:,i),'.-','color',color(i,:),'linewidth',1.5); hold on
end

for bin_no = 1:numBins
   if vel_o2i_by_bin_h(bin_no) == 1
       text(bin_x(bin_no),vel_o2i_bin_mean(bin_no,2), '*','fontsize',12);
   end
end
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)/2])
title(['binned data (' num2str(how_long/numBins) ' frames/bin)']);

%IN2OUT
subplot(plots_row,plots_column,8)
for i=1:2
    SEM_y_plot = [vel_i2o_bin_mean_trans(i,:)- vel_i2o_bin_SEM_trans(i,:);(2*vel_i2o_bin_SEM_trans(i,:))];
    h = area(bin_x,SEM_y_plot');
    set(h(1),'visible','off');
    set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
    alpha(.2);
    hold on
    
    plot(bin_x,vel_i2o_bin_mean(:,i),'.-','color',color(i,:),'linewidth',1.5); hold on
end

for bin_no = 1:numBins
   if vel_i2o_by_bin_h(bin_no) == 1
       text(bin_x(bin_no),vel_i2o_bin_mean(bin_no,2), '*','fontsize',12);
   end
end
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0

set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)+1/framespertimebin]);
ylim ([0 vel_ylim(2)/2])
title('p< .05');
