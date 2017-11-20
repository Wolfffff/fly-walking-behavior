%multiple_flies_curv_turn_reori_plotter.m

figure
set(gcf,'position',[100 20 1000 800]);

%get the y range so that plot looks nice
%for total turn
y_max= max(max(totalturn_flies));
y_min = min(min(totalturn_flies));
ymax= max(y_max,abs(y_min));

%getting y range
%for turn_curvewalk & reorientation
max1 = zeros(numflies,1);
max2 = zeros(numflies,1);
for fly = 1:numflies
    max1(fly) =max(turn_curvewalk_flies{fly});
    max2(fly) = max(turn_reorientation_flies{fly});
end
ymax1 = max(max1);
ymax2 = max(max2);

for fly = 1:numflies
    totalturn = totalturn_flies(:,fly);
    abs_totalturn = abs(totalturn);
    turn_curve = turn_curvewalk_flies{fly};
    turn_time = curv_time_flies{fly};
    turn_reorientation = turn_reorientation_flies{fly};
    reori_time = reori_time_flies{fly}/framespertimebin; %in sec
    
    q = rem(fly,20)+1;

    subplot(3,1,1)
    %totalturn: accumulative curvature at every walk
    x_time = (1:length(totalturn))/framespertimebin/60; %x: min
    plot(x_time,totalturn,'color',cmap(q,:));
    hold on
    
    plot([3 3],[-ymax ymax],'r:');
    plot([6 6],[-ymax ymax],'b:');
    
    ylim([-ymax ymax]);
    
    set(gca,'box','off','tickdir','out');
    xlabel('time (min)');
    ylabel('curvature');
    title({fig_title;'accumulated sum of curvature'});
    
    
    subplot(3,1,2)
    %turn_curve
    plot(turn_time/60,turn_curve,'color',cmap(q,:));
    hold on
    plot([3 3],[-ymax1 ymax1],'r:');
    plot([6 6],[-ymax1 ymax1],'b:');
    
    ylim([-ymax1 ymax1]);
    set(gca,'box','off','tickdir','out');
    xlabel('time (min)');
    ylabel('curvature');
    title('Sum of curvature/turn');
    
    subplot(3,1,3)
    %turn_reorientation
    plot(reori_time/60,turn_reorientation,'color',cmap(q,:));
    hold on
    plot([3 3],[-ymax2 ymax2],'r:');
    plot([6 6],[-ymax2 ymax2],'b:');
    
    ylim([-ymax2 ymax2]);
    set(gca,'box','off','tickdir','out');
    xlabel('time (min)');
    ylabel('curvature');
    title('re-orientation/stop');

    
end