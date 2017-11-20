% crossing out till next crossing in data analysis by VB
% annotated by SJ (8/30/2013)

% For each crossing out ~ in, grabs data for before and during periods
% 1. frames for each crossing out ~ in,
% 2. total speed
% 3. how far is the fly from the center, and radial speed
% 4. angular speed (curvature)

%first, load data mat file after multiple flies analysis

%load('Or42b ACV0 V21biggerIR19 12-Feb-2013.mat');

%correcting the error from initial analysis: curvature data contains NaNs.
%change all NaNs to zeros (since they occur when flies don't move)
curvature_flies(isnan(curvature_flies)) = 0;

%pre-allocate arrays (100 is more than enough for maximum crossings)
data.distance_traveled_outside_before=nan(100,numflies);
data.velocity_before=nan(100,numflies);
data.returntime_before=nan(100,numflies);
data.curvature_before=nan(100,numflies);
data.r_before=nan(5000,100,numflies);
data.drdt_before=nan(5000,100,numflies);
data.r_bytrial_before=nan(100,numflies);
data.drdt_bytrial_before=nan(100,numflies);

for i=1:numflies %each fly
    for j=1:length(crossing_i2o_bf_frames_flies{1,i}) %before, crossing #
        data.frames=crossing_i2o_bf_frames_flies{1,i}{1,j};%actual frame #s of crossing out till next crossing in
        data.returntime_before(j,i)=length(data.frames)/30;%time (sec) from frame #, 30 fps
        data.velocity=vel_total_flies(data.frames,i) ;%velocity for those frames
        xposition=numvals(data.frames,2*i-1);
        yposition=numvals(data.frames,2*i);
        in_x = numvals_pi{i}(:,1);
        in_y = numvals_pi{i}(:,2);
        %use circle fit to find the center and radius
        [ctr_x,ctr_y,circRad] = circfit(in_x,in_y);
        %translate x and y points so that the center is (0,0)
        x_translated = xposition-ctr_x;
        y_translated = yposition-ctr_y;
        display(length(x_translated));%display how long the crossing out/in event is
        r=sqrt(x_translated.^2+y_translated.^2);%get the distance from the center
        data.r_before(1:length(x_translated),j,i)=r;
        data.drdt_before(1:length(x_translated),j,i)=[0 ;diff(r)]; %radial speed (changes in distance from the center)
        data.r_bytrial_before(j,i)=mean(r);%mean of r, 
        data.drdt_bytrial_before(j,i)=mean(diff(r));
        data.curvature=abs(curvature_flies(data.frames,i));
        data.curvature_before(j,i)=mean(data.curvature); %mean of curvature
        data.velocity_before(j,i)=mean(data.velocity);
        data.distance_traveled_outside_before(j,i)=sum(data.velocity); %this is relative, NOT absolute distance in cm
        
    end
end

%same analysis for during
data.distance_traveled_outside_during =nan(100,numflies);
data.velocity_during =nan(100,numflies);
data.returntime_during =nan(100,numflies);
data.curvature_during =nan(100,numflies);
data.r_during=nan(5000,100,numflies);
data.drdt_during=nan(5000,100,numflies);
data.r_bytrial_during=nan(100,numflies);
data.drdt_bytrial_during=nan(100,numflies);
for i=1:numflies
    for j=1:length(crossing_i2o_dr_frames_flies{1,i})
        data.frames=crossing_i2o_dr_frames_flies{1,i}{1,j};
        data.returntime_during(j,i)=length(data.frames)/30;
        data.velocity=vel_total_flies(data.frames,i) ;
        xposition=numvals(data.frames,2*i-1);
        yposition=numvals(data.frames,2*i);
        in_x = numvals_pi{i}(:,1);
        in_y = numvals_pi{i}(:,2);
        %use circle fit to find the center and radius
        [ctr_x,ctr_y,circRad] = circfit(in_x,in_y);
        %translate x and y points so that the center is (0,0)
        x_translated = xposition-ctr_x;
        y_translated = yposition-ctr_y;
        display(length(x_translated));
        r=sqrt(x_translated.^2+y_translated.^2);
        data.r_during(1:length(x_translated),j,i)=r;
        data.drdt_during(1:length(x_translated),j,i)=[0 ;diff(r)];
        data.r_bytrial_during(j,i)=mean(r);
        data.drdt_bytrial_during(j,i)=mean(diff(r));
        data.curvature=abs(curvature_flies(data.frames,i));
        data.curvature_during(j,i)=mean(data.curvature);
        data.velocity_during(j,i)=mean(data.velocity);
        data.distance_traveled_outside_during(j,i)=sum(data.velocity);
    end
end

%save the average for two periods (median and mean are mixed)
data.avg_distance_during=nanmedian(data.distance_traveled_outside_during);
data.avg_vel_during=nanmean(data.velocity_during);
data.avg_return_time_during=nanmedian(data.returntime_during);
data.avg_curvature_during=nanmean(data.curvature_during);

data.avg_distance_before=nanmedian(data.distance_traveled_outside_before);
data.avg_vel_before=nanmean(data.velocity_before);
data.avg_return_time_before=nanmedian(data.returntime_before);
data.avg_curvature_before=nanmean(data.curvature_before);

ab=[data.avg_distance_before' data.avg_distance_during'];
cd=[data.avg_vel_before' data.avg_vel_during'];
ef=[data.avg_return_time_before',data.avg_return_time_during'];
gh=[data.avg_curvature_before' data.avg_curvature_during'];

%%
figure(1)
set(gcf,'Position',[500 10 1200 900],'color','white');

%distance between out/in
subplot(6,2,2);
boxplot(ab); hold on;
%boxplot([data.b],'notch','on','whisker',1)
h = boxplot(ab,'color',[0 0 0]);hold on
plot(1,data.avg_distance_before, 'og'); hold on; plot(2,data.avg_distance_during,'or');
xlim ([0.5 2.5]);
ylim ([0 500]);
[h,p]=ranksum(data.avg_distance_before,data.avg_distance_during)
set(gca,'box','off','tickdir','out','ytick',[0:100:500]);
title([user_input ' avg distance/fly']);
text(1.2,300,['p = ' num2str(h)]);

subplot(6,2,1);
data.x=reshape(data.distance_traveled_outside_during,(100*numflies),1);
data.x(isnan(data.x))=[];
data.y=reshape(data.distance_traveled_outside_before,(100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (0:(3000/90):3000);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);

stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
set(gca, 'Xscale', 'log')
ylim ([0 0.31]);
title('distance/crossing');

subplot(6,2,4);
%boxplot([data.b],'notch','on','whisker',1)
bar(1,mean(data.avg_vel_before),'facecolor',[1 1 1]);
hold on
bar(2,mean(data.avg_vel_during),'facecolor',[1 1 1]); hold on
plot(1,data.avg_vel_before, 'og'); hold on; plot(2,data.avg_vel_during,'or');
xlim ([0.5 2.5]);
ylim ([0 2]);
[h,p]=ranksum(data.avg_vel_before,data.avg_vel_during)
set(gca,'box','off','tickdir','out');
title('average velocity');
text(1.2,1.8,['p = ' num2str(h)]);

subplot(6,2,3);
data.x=reshape(data.velocity_during,(100*numflies),1);
data.x(isnan(data.x))=[];
data.y=reshape(data.velocity_before,(100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (0:(3/20):3);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);
stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
%set(gca, 'Xscale', 'log')
ylim ([0 0.4]);
title('velocity/crossing');

subplot(6,2,6);
h = boxplot(ef,'color',[0 0 0]);hold on
plot(1,data.avg_return_time_before, 'og'); hold on; plot(2,data.avg_return_time_during,'or');
xlim ([0.5 2.5]);
ylim ([0 20]);
set(gca,'box','off','tickdir','out');
[h,p]=ranksum(data.avg_return_time_before,data.avg_return_time_during);
text(1.2,20,['p = ' num2str(h)]);
title('return time/crossing');

subplot(6,2,5);
data.x=reshape(data.returntime_during,(100*numflies),1);
data.x(isnan(data.x))=[];
data.y=reshape(data.returntime_before,(100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (0:(100/100):100);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);

stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
%set(gca, 'Xscale', 'log')
title(' time outside/transit');

subplot(6,2,8);
h = boxplot(gh,'color',[0 0 0]);hold on
plot(1,data.avg_curvature_before, 'og'); hold on; plot(2,data.avg_curvature_during,'or');
xlim ([0.5 2.5]);
ylim ([0.04 0.1]);
set(gca,'box','off','tickdir','out');
[h,p]=ttest(data.avg_curvature_before,data.avg_curvature_during)
title(' avg curvature');
text(1.2,0.07,['p = ' num2str(p)]);

subplot(6,2,7);
data.x=reshape(data.curvature_during,(100*numflies),1);
data.x(isnan(data.x))=[];
data.y=reshape(data.curvature_before,(100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (0:(0.3/50):.3);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);

stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
title(' curvature/transit');

subplot(6,2,9);
data.x=reshape(data.r_bytrial_during,(100*numflies),1);
data.x(isnan(data.x))=[];
size(data.x)
data.y=reshape(data.r_bytrial_before,(100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (0:(10/1):300);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);

stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
title('radial dist/transit');

subplot(6,2,10);
data.x=reshape(data.drdt_bytrial_during,(100*numflies),1);
data.x(isnan(data.x))=[];
data.y=reshape(data.drdt_bytrial_before,(100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (-2:(0.1/4):2);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);

stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
title('radial vel/transit');

subplot(6,2,11);
data.x=reshape(data.r_during,(5000*100*numflies),1);
data.x(isnan(data.x))=[];
size(data.x)
data.y=reshape(data.r_before,(5000*100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (0:(3/1):220);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);

stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
title('radial dist');

subplot(6,2,12);
data.x=reshape(data.drdt_during,(5000*100*numflies),1);
data.x(isnan(data.x))=[];
data.y=reshape(data.drdt_before,(5000*100*numflies),1);
data.y(isnan(data.y))=[];
hist_bins = (-2:(0.1/4):2);
cc = histc(data.y,hist_bins);
cc1 = cc./length(data.y);

stairs(hist_bins,cc1,'color','g');hold on
cc = histc(data.x,hist_bins);
cc1 = cc./length(data.x);
stairs(hist_bins,cc1,'color','r');hold on
title('radial vel');

%save in ps file
print('-dpsc2',[fig_title ' crossing outs.ps'],'-loose');
%%
figure (2)
set(gcf,'Position',[500 100 900 600],'color','white');
data.x=reshape(data.returntime_during,(100*numflies),1);
data.x(isnan(data.x))=[];
% datain.y=reshape(datain.curvature_during,(100*numflies),1);
% datain.y(isnan(datain.y))=[];
data.y=reshape(data.drdt_bytrial_during,(100*numflies),1);
data.y(isnan(data.y))=[];
subplot(5,1,1)

plot(data.x, data.y, 'or');
title([user_input 'tr vs drdt']);

data.y=reshape(data.distance_traveled_outside_during,(100*numflies),1);
data.y(isnan(data.y))=[];
%size(datain.x), size(datain.y)
subplot(5,1,2)
R = corrcoef(data.x,data.y)

plot(data.x, data.y, 'or');
text(100,500,['R = ' num2str(R(1,2))]);
title('tr vs distance');

data.y=reshape(data.velocity_during,(100*numflies),1);
data.y(isnan(data.y))=[];
%size(datain.x), size(datain.y)
subplot(5,1,3)
R = corrcoef(data.x,data.y)
plot(data.x, data.y, 'or');
text(100,1,['R = ' num2str(R(1,2))]);
title('tr vs vel');

data.y=reshape(data.r_bytrial_during,(100*numflies),1);
data.y(isnan(data.y))=[];
%size(datain.x), size(datain.y)
subplot(5,1,4)
R = corrcoef(data.x,data.y)
plot(data.x, data.y, 'or');
text(100,50,['R = ' num2str(R(1,2))]);
title('tr vs radial distance');

data.y=reshape(data.curvature_during,(100*numflies),1);
data.y(isnan(data.y))=[];
%size(datain.x), size(datain.y)
subplot(5,1,5)
R = corrcoef(data.x,data.y)
plot(data.x, data.y, 'or');
text(100,0.1,['R = ' num2str(R(1,2))]);
title('tr vs curvature');

%save the figure
print('-dpsc2',[fig_title ' crossing outs.ps'],'-loose','-append');
%convert ps to pdf
ps2pdf('psfile', [fig_title ' crossing outs.ps'], 'pdffile', [fig_title ' crossing outs.ps'], 'gspapersize', 'letter');
