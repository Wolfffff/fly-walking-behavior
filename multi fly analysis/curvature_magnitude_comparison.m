% curvature_magnitude_comparison

% compare curvature during 'curved walks' 
% (curv_in_flies, curv_out_flies)
% (these are frame numbers)


%inside the odor zone
curv_in_sum = nan(numflies,3);
curv_in_sum_norm = nan(numflies,3);

for fly=1:numflies
    for period =1:3
        clear curv_fly
        curv_fly = curv_in_flies{period,fly};
        if isnan(curv_fly) == 0
            curv_fly_sum = sum(k_run_flies(curv_fly,fly));
            curv_in_sum(fly,period) = curv_fly_sum;
            %normalize by frame #
            curv_in_sum_norm(fly,period) = curv_fly_sum/length(curv_fly);
            %absolute curvature
            curv_fly_sum_abs = sum(abs(k_run_flies(curv_fly,fly)));
            curv_in_sum_abs(fly,period) = curv_fly_sum_abs;

        end
    end
end

%means + std
curv_in_mean = nanmean(curv_in_sum);
curv_in_median = nanmedian(curv_in_sum);
curv_in_std = nanstd(curv_in_sum);

curv_in_norm_mean = nanmean(curv_in_sum_norm);
curv_in_norm_median = nanmedian(curv_in_sum_norm);
curv_in_norm_std = nanstd(curv_in_sum_norm);

curv_in_mean_abs = nanmean(curv_in_sum_abs);
curv_in_std_abs = nanstd(curv_in_sum_abs);


%outside the odor zone
curv_out_sum = nan(numflies,3);
curv_out_sum_norm = nan(numflies,3);

for fly=1:numflies
    for period =1:3
        curv_fly = curv_out_flies{period,fly};
        if isnan(curv_fly) == 0
            curv_fly_sum = sum(k_run_flies(curv_fly,fly));
            curv_out_sum(fly,period) = curv_fly_sum;            
            %normalize by frame #
            curv_out_sum_norm(fly,period) = curv_fly_sum/length(curv_fly);

            curv_fly_sum_abs = sum(abs(k_run_flies(curv_fly,fly)));
            curv_out_sum_abs(fly,period) = curv_fly_sum_abs;

        end
    end
end

%means + std
curv_out_mean = nanmean(curv_out_sum);
curv_out_median = nanmedian(curv_out_sum);
curv_out_std = nanstd(curv_out_sum);

curv_out_norm_mean = nanmean(curv_out_sum_norm);
curv_out_norm_median = nanmedian(curv_out_sum_norm);
curv_out_norm_std = nanstd(curv_out_sum_norm);

curv_out_mean_abs = nanmean(curv_out_sum_abs);
curv_out_std_abs = nanstd(curv_out_sum_abs);


%plots

figure
set(gcf,'Position',[100 10 600 1200]);

%in, mean
subplot(4,2,1)
for period =1:2
    b = bar(period,curv_in_mean(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
    plot(period,curv_in_sum(:,period),'k.');
end
ylim([-3000 100]);
set(gca,'box','off');
xlabel('mean');
title({fig_title; ['Sum of curvature INSIDE']});

%in, median
subplot(4,2,3)
for period =1:2
    b = bar(period,curv_in_median(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
    plot(period,curv_in_sum(:,period),'k.');
end
ylim([-100 100]);
set(gca,'box','off');
xlabel('median');
title('Sum of curvature INSIDE');

%in, normalized, mean
subplot(4,2,5)
for period =1:2
    b = bar(period,curv_in_norm_mean(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
    plot(period,curv_in_sum_norm(:,period),'k.');
end
set(gca,'box','off');
ylim([-3 1]);
xlabel('mean');

title('Normalized sum of curvature INSIDE');

%in, normalized, median
subplot(4,2,7)
for period =1:2
    b = bar(period,curv_in_norm_median(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
    plot(period,curv_in_sum_norm(:,period),'k.');
end
set(gca,'box','off');
ylim([-.3 .3]);
xlabel('median');

%t-test
[h,p]= ttest(curv_in_sum_norm(:,1),curv_in_sum_norm(:,2));
if h==1 %rejects null hypothesis
    text(2,curv_in_norm_median+.05,'b*');
end
title('Normalized sum of curvature INSIDE');


%OUT
%mean
subplot(4,2,2)
for period =1:2
    b = bar(period,curv_out_mean(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on   
    plot(period,curv_out_sum(:,period),'k.');
end
set(gca,'box','off');
xlabel('mean');
ylim([-100 1000]);
title('Sum of curvature OUTSIDE');

%median
subplot(4,2,4)
for period =1:2
    b = bar(period,curv_out_median(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
    plot(period,curv_out_sum(:,period),'k.');
end
ylim([-100 100]);
set(gca,'box','off');
xlabel('median');
title('Sum of curvature OUTSIDE');

%in, normalized, mean
subplot(4,2,6)
for period =1:2
    b = bar(period,curv_out_norm_mean(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
    plot(period,curv_out_sum_norm(:,period),'k.');
end
set(gca,'box','off');
ylim([-1 1]);
xlabel('mean')
title('Normalized sum of curvature OUTSIDE');

%in, normalized, median
subplot(4,2,8)
for period =1:2
    b = bar(period,curv_out_norm_median(:,period));
    set(b,'facecolor',color(period,:),'edgecolor','w');
    hold on
    plot(period,curv_out_sum_norm(:,period),'k.');
end
set(gca,'box','off');
ylim([-.3 .3]);
xlabel('median');

%t-test
[h,p]= ttest(curv_out_sum_norm(:,1),curv_out_sum_norm(:,2));
if h==1 %rejects null hypothesis
    text(2,curv_out_norm_median+.05,'b*');
end

title('Normalized sum of curvature OUTSIDE');

