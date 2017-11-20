%for multiple_flies_analysis_V17
% 1. This script plots the sharp turns + curved walking in  'during' period
% 2. turn/curving frequency or fraction in three periods

% plot the 'during' period fly's walking trajectory + sharp turns (red, o)
% + curving/turning (blue dots) for all the flies

fig_count1 = 0;
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
    %     for a=1:1
    x_for_fly = numvals(:,2*a-1);
    y_for_fly = numvals(:,2*a);
    
    
    %     plot(x_for_fly(1:timeperiods(2)), y_for_fly(1:timeperiods(2)), '-g', 'LineWidth',1);hold on
    %
    %     plot(x_for_fly(odoroff_frame:timeperiods(4)), y_for_fly(odoroff_frame:timeperiods(4)), 'b', 'LineWidth',1);
    hold on
    %     plot(x_for_fly(timeperiods(2):odoron_frame(a)),...
    %         y_for_fly(timeperiods(2):odoron_frame(a)), 'color',grey, 'LineWidth',1);
    plot(x_for_fly(odoron_frame(a):timeperiods(3)),...
        y_for_fly(odoron_frame(a):timeperiods(3)),'color',grey, 'LineWidth',1);
    
    plot(numvals_pi{a}(:,1), numvals_pi{a}(:,2), 'k', 'LineWidth',1);
    plot(numvals_po{a}(:,1), numvals_po{a}(:,2), 'k', 'LineWidth',1);
    %original inner rim
    plot(numvals_pi_ori{a}(:,1), numvals_pi_ori{a}(:,2), 'k--', 'LineWidth',1);
    
    curving = curv_period_flies{2,a};
    plot(x_for_fly(curving), y_for_fly(curving),'b.','markersize',2);
    
    sh_turn = turn_flies{2,a};
    plot(x_for_fly(sh_turn),y_for_fly(sh_turn),'mo');
    
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
            print('-dpsc2',[fig_title '.ps'],'-loose');
            fig_count1 = fig_count1+1;
            saveas(gcf,[fig_title '_during_turning'  num2str(fig_count) '.fig']);
        else
            fig_count1 = fig_count1+1;
            saveas(gcf,[fig_title '_during_turning'  num2str(fig_count) '.fig']);
            print('-dpsc2',[fig_title '.ps'],'-loose','-append');
        end
        
    elseif a == numflies %if this is the last fly, save the figure
        set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
        if fig_no ==1 %first
            print('-dpsc2',[fig_title '.ps'],'-loose');
            fig_count1 = fig_count1+1;
            saveas(gcf,[fig_title '_during_turning'  num2str(fig_count) '.fig']);
        else
            fig_count1 = fig_count1+1;
            saveas(gcf,[fig_title '_during_turning' num2str(fig_count) '.fig']);
            print('-dpsc2',[fig_title '.ps'],'-loose','-append');
        end
    end
    
end



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
ylim([0 1.4]);
set(gca,'ytick',(0:.2:2),'box','off','xtick',[1:5],'xticklabel',ring_outer_radius_rings);
xlabel('radius of outer ring');
title({'Mean of sharp turn frequency'; 'in Before and During periods'});


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
ylim([0 1.4]);
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
ylim([0 1.4]);
set(gca,'xtick',[],'ytick',(0:.2:2),'box','off');

title({'Before VS During in a ring' ;...
    ['radius between  ' num2str(ring_inner_radius_rings(ringID)) ' and ' num2str(ring_outer_radius_rings(ringID))]});

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
saveas(gcf,[fig_title '_turn_analysis.png']);
print('-dpsc2',[fig_title '.ps'],'-loose','-append');
