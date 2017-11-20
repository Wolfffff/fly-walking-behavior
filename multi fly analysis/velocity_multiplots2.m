function velocity_multiplots2(vel_norm_o2i_avg,vel_norm_i2o_avg,...
    vel_norm_o2i_SEM,vel_norm_i2o_SEM,...
    vel_norm_o2i_bin_mean,vel_norm_i2o_bin_mean,...
    vel_norm_o2i_by_bin_h,vel_norm_i2o_by_bin_h,...
    numBins,plots_row,plots_column,frame_norm,...
    framespertimebin,x_range,bin_x,how_long,y_lim_for_plot)

%Add additional subplots after multiplots1
%normalized average data, binned data

color = [0 1 0;1 0 0;0 0 1];

subplot(plots_row,plots_column,9)
%first plot errobars using area function
%refer to average_errorbar_plotting.m
%first transpose the arrays
vel_norm_o2i_trans = vel_norm_o2i_avg';
vel_norm_o2i_SEM_trans = vel_norm_o2i_SEM';

for i=1:2
SEM_y_plot = [vel_norm_o2i_trans(i,:)- vel_norm_o2i_SEM_trans(i,:);(2*vel_norm_o2i_SEM_trans(i,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
alpha(.2);
hold on
end
plot(x_range,vel_norm_o2i_avg(:,1),'g','linewidth',1.5)
plot(x_range,vel_norm_o2i_avg(:,2),'r','linewidth',1.5)
% plot(x_range,vel_norm_o2i(:,3))
plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')

xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
title('normalized from average of an individual fly');

subplot(plots_row,plots_column,10)

vel_norm_i2o_trans = vel_norm_i2o_avg';
vel_norm_i2o_SEM_trans = vel_norm_i2o_SEM';

for i=1:2
SEM_y_plot = [vel_norm_i2o_trans(i,:)- vel_norm_i2o_SEM_trans(i,:);(2*vel_norm_i2o_SEM_trans(i,:))];
h = area(x_range,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor',color(i,:),'EdgeColor','none');
alpha(.2);
hold on
end
plot(x_range,vel_norm_i2o_avg(:,1),'g','linewidth',1.5)
plot(x_range,vel_norm_i2o_avg(:,2),'r','linewidth',1.5)
% plot(x_range,vel_norm_i2o(:,3))

plot([1/framespertimebin 1/framespertimebin],[-2 2],'k:') %dotted line marking 0
plot([min(x_range) max(x_range)],[0 0],'k:')
set(gca,'Box','off','Xtick',(-10:1:600),'fontsize',8,'tickdir','out');
xlim([min(x_range) max(x_range)]);
ylim(y_lim_for_plot)
title(['baseline: from ' num2str(frame_norm(1)) ' to ' num2str(frame_norm(end))]);

%bin normalized velocity data
%binned and t-tested
subplot(plots_row,plots_column,11)
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

subplot(plots_row,plots_column,12)
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
title('p< .05');

