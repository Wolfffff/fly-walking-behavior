function fig1compressed = fig1compressed_plotter (out_x,out_y, in_x, in_y, fly_x, fly_y, avgvelocity_by_fly_in, avgvelocity_by_fly_out, median_time_out_transit_before,median_time_out_transit_during, median_time_out_transit_after, time_in, time_out,fig_title, crossing_before_No, crossing_during_No, crossing_after_No)
    color = [0 1 0;1 0 0;0 0 1];
out2in = vertcat(crossing_before_No, crossing_during_No, crossing_after_No);
total_out2in_sum = sum(out2in);
time_outside_per_transit = [median_time_out_transit_before,median_time_out_transit_during,median_time_out_transit_after];

time_bw_sum = (nanmean(time_outside_per_transit));


avg_vel_in = nanmean(avgvelocity_by_fly_in(:));
avg_vel_out = nanmean(avgvelocity_by_fly_out(:));


figure(1);
fig1compressed = gcf;
set(gcf,'Position',[434 58 1180 540])
suptitle(['\bf' fig_title]);
subplot (2,7,[1 2]);

% x_for_fly = numvals(:,1);
% y_for_fly = numvals(:,2);
% 
% 
plot(fly_x, fly_y, 'g', 'LineWidth',1);
hold on;
axis auto;
set(gca,'Box','off','Xtick',[],'Ytick',[],'XColor',[1,1,1],'YColor',[1,1,1]);
plot(in_x,in_y,'k');hold on
plot(out_x,out_y,'k');

% plot(fly_x(1:timeperiods(2)),fly_y(1:timeperiods(2)),'g','linewidth',0.5);

axis tight;

% time_inside_raw = vertcat(time_in_before_frames, time_in_during_frames, time_in_after_frames);
% total_time_inside_normalized_sum = (sum(time_in))/timeperiods(4);
% total_time_inside = (sum(time_inside_raw));
% total_time_outside_normalized_sum = (sum(time_out))/timeperiods(4);

subplot(2,7,3)

b = bar(1, time_in, 'BarWidth', .5, 'EdgeColor', 'none');
hold on;
set(b, 'FaceColor', color(:,1));
xlabel('time spent inside (fraction)' ,'fontsize',8);
ylim ([0 1]);
set(gca,'Box','off','Xtick',[],'Ytick',(time_in),'YGrid','on');
 
        h1 = gca;
        h2 = axes('Position', get(h1,'Position'));
%         plot(1,[ratio, ratio]);
        %                 set(h2, 'Color', 'none', 'XTickLabel', [] );
        set(h2,'Box','off', 'Color', 'none', 'XTickLabel', [], 'YTickLabel', [], 'Ylim' ,[0 1] );
        set(h2,'Visible','off')
    
        
subplot(2,7,4) % plots the average time each fly spends OUTSIDE as a bar and individual flies as markers

b = bar(1,time_out, 'BarWidth', .5, 'EdgeColor', 'none');
hold on;
set(b, 'FaceColor', color(:,1));
xlabel('time spent outside (fraction)' ,'fontsize',8);
ylim ([0 1]);
set(gca,'Box','off','Xtick',[],'Ytick',(time_out),'YGrid','on');

subplot(2,7,5);

b = bar(1, total_out2in_sum, 'BarWidth', .5, 'EdgeColor', 'none');
hold on;
set(b, 'FaceColor', color(:, 1));
xlabel('No. of transits' ,'fontsize',8);
ylim ([0 total_out2in_sum+5]);
set(gca,'Box','off','Xtick',[],'Ytick',(total_out2in_sum),'YGrid','on');


subplot(2,7,6);

b = bar(1,  time_bw_sum, 'BarWidth', .5, 'EdgeColor', 'none');
hold on;
set(b, 'FaceColor', color(:,1));
xlabel('Mean time to return' ,'fontsize',8);
if isnan(time_bw_sum) == 1;
    ylim ([0 1]);
set(gca,'Box','off','Xtick',[],'Ytick',(1),'YGrid','on');
else
    
ylim ([0 time_bw_sum+5]);
set(gca,'Box','off','Xtick',[],'Ytick',(time_bw_sum),'YGrid','on');

end
subplot(2,7,9);

b = bar(1, total_time_inside/total_out2in_sum, 'BarWidth', .5, 'EdgeColor', 'none');
hold on;
set(b, 'FaceColor', color(:,1));
xlabel('Time spent inside/transit #(s)' ,'fontsize',8);
if isnan(total_time_inside/total_out2in_sum) == 1;
    ylim ([0 1])
else
ylim ([0 total_time_inside/total_out2in_sum+10]);
set(gca,'Box','off','Xtick',[],'Ytick',(total_time_inside/total_out2in_sum),'YGrid','on');
end
hold off;

subplot(2,7,10);
b = bar(1, avg_vel_in, 'BarWidth', .5, 'EdgeColor', 'none');
hold on;
set(b, 'FaceColor', color(:,1));
ylabel('velocity (cm/s)','fontsize',8);
xlabel('avg velocity inside','fontsize',8);
if isnan(avg_vel_in) == 1;
       ylim ([0 1])
else
ylim ([0 avg_vel_in+.5]);
set(gca,'Box','off','Xtick',[],'Ytick',(avg_vel_in),'YGrid','on','fontsize',7);
end


subplot(2,7,11);

b = bar(1, avg_vel_out, 'BarWidth', .5, 'EdgeColor', 'none');
hold on;
set(b, 'FaceColor', color(:,1));
ylabel('velocity (cm/s)','fontsize',8);
xlabel('avg velocity outside','fontsize',8);
if isnan(avg_vel_out) == 1;
       ylim ([0 1])
else
ylim ([0 avg_vel_out+.5]);
set(gca,'Box','off','Xtick',[],'Ytick',(avg_vel_out),'YGrid','on','fontsize',7);
end
%  figure1 = area_plotter_novac(inner_radius, outer_radius, frames_in, frames_out, color);


set(fig1compressed,'color','white');
set(fig1compressed, 'PaperPositionMode', 'auto');
saveas(fig1compressed, [fig_title ' figure 1.png']);

ps2pdf('psfile', [fig_title '.ps'], 'pdffile', [fig_title '.pdf'], 'gspapersize', 'letter');

display('Pdf file is saved!');
