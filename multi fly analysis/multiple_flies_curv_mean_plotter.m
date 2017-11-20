%multiple_flies_curv_mean_plotter

%mean of curvature in each curved run (means of each curvs, median of all
%flies)

%median/std calculation
curv_in_median = nanmedian(curv_median_in_flies);
curv_out_median = nanmedian(curv_median_out_flies);

subplot(2,2,1)
plot(curv_in_median,'ms-'); hold on
for fly = 1:numflies
    q=rem(fly,20)+1;
    plot(curv_median_in_flies(fly,:),'.','color',cmap(q,:));
end
xlim([.5 3.5]);
set(gca,'box','off');
title({fig_title;['Median of medians (IN)']});

subplot(2,2,2)
plot(curv_out_median,'ms-'); hold on
for fly = 1:numflies
     q=rem(fly,20)+1;
    plot(curv_median_out_flies(fly,:),'.','color',cmap(q,:));
end
xlim([.5 3.5]);
set(gca,'box','off');

title('Median of medians (OUT)');


curv_sum_in_median = nanmedian(curv_sum_in_flies);
curv_sum_out_median = nanmedian(curv_sum_out_flies);

subplot(2,2,3)
plot(curv_sum_in_median,'ms-'); hold on
for fly = 1:numflies    
     q=rem(fly,20)+1;
    plot(curv_sum_in_flies(fly,:),'.','color',cmap(q,:));
end
xlim([.5 3.5]);ylim([0 10]);
set(gca,'box','off');

title('Median of sums (IN)');

subplot(2,2,4)
plot(curv_sum_out_median,'ms-'); hold on
for fly = 1:numflies
     q=rem(fly,20)+1;
    plot(curv_sum_out_flies(fly,:),'.','color',cmap(q,:));
end
xlim([.5 3.5]);ylim([0 10]);
set(gca,'box','off');

title('Median of sums (OUT)');


%%

%sum of the total curvature (k_run), all +

curv_total_flies = nansum(abs(k_run_flies));
curv_total_flies = curv_total_flies';

curv_period_flies = nan(numflies,3);
curv_total_curv_flies = nan(numflies,1);

for fly = 1:numflies
    curv_period_flies(fly,1)= nansum(abs(k_run_flies(1:timeperiods(2)-1,fly)));
    curv_period_flies(fly,2) = nansum(abs(k_run_flies(odoron_frame(fly):timeperiods(3)-1,fly)));
    curv_period_flies(fly,3) = nansum(abs(k_run_flies(timeperiods(3):end,fly)));
    
    %curv total during 'curved walks'
    curv_frames = frame_all_curv{fly};
    curv_total_curv_flies(fly)= sum(abs(k_run(curv_frames)));
end

curv_total_straight_flies = curv_total_flies - curv_total_curv_flies;


%calculate the fraction: how much curvature changes are coming from 'curved
%walk'
curv_fr_curv_flies = curv_total_curv_flies./curv_total_flies;
curv_fr_curv_mean = mean(curv_fr_curv_flies);
curv_fr_curv_median = median(curv_fr_curv_flies);
curv_fr_curv_std = std(curv_fr_curv_flies);

subplot(2,1,1)

for fly= 1:numflies
    q = rem(fly,20) +1;
    plot(1,curv_total_flies(fly),'o','color',cmap(q,:));    hold on
    plot(2,curv_total_straight_flies(fly),'o','color',cmap(q,:));
    plot(3,curv_total_curv_flies(fly),'o','color',cmap(q,:));
end
xlim([.5 3.5]);ylim([0 10000]);
set(gca,'box','off','tickdir','out');
set(gca,'xtick',1:3,'XTickLabel',{'curv total','curv straight','curv in curv'});
title({fig_title; ['sum of curvature']});

subplot(2,1,2)
plot(1,curv_fr_curv_flies,'o');hold on
plot(1,curv_fr_curv_mean,'k*','markersize',10);
plot(1,curv_fr_curv_median,'b*','markersize',10);

set(gca,'box','off','tickdir','out','xtick',[]);
title('Fraction of curvature in curved walks / total walk');
xlabel('black: mean, blue: median');