% multiple_flies_inside_rim_plotter
% inside_rim : 0 = outside, 1 = inside

inside_rim_mean = mean(inside_rim,2);

%bin them : 6 frames/bin
%define limits
framesinBin = 6; %6 frames = 200 ms
topEdge = length(inside_rim_mean);
botEdge = 1;
binEdges = [botEdge:framesinBin:topEdge];
NumBins = length(binEdges)-1;

[~,whichBin] = histc([botEdge:topEdge],binEdges); %do histc to bin x or frame#

bin_inside_rim = nan(NumBins,numflies);%define edges of bins

for fly=1:numflies
    for i=1:NumBins
        flagBinMembers = (whichBin == i); %check each bin
        binMembers = inside_rim(flagBinMembers,fly); %get the corresponding run/stop probability for the bin
        binMean = nanmean(binMembers,1); %get the mean
        bin_inside_rim(i,fly) = binMean;
    end
end

%mean of binned data
bin_inside_rim_mean =  nanmean(bin_inside_rim,2);

%std of binned data
bin_inside_rim_std = nanstd(bin_inside_rim,0,2);

%SEM
bin_inside_rim_SEM = bin_inside_rim_std./(sqrt(numflies));


%==========================================================================
%sliding bins with 6 frames/bin
bin_inside_rim_sliding = zeros(length(inside_rim_mean),numflies);

for fly=1:numflies
    for i = 1:length(inside_rim_mean)
        if i< 3 % get the average of frames 1~i
        bin_inside_rim_sliding(i,fly) = mean(inside_rim(1:i,fly));  
        elseif i > (length(inside_rim_mean) -3)
            bin_inside_rim_sliding(i,fly) = mean(inside_rim(i-2:end,fly));
        else
        bin_inside_rim_sliding(i,fly) = mean(inside_rim(i-2:i+3,fly));
        end
    end
end
        
%mean of binned data
bin_inside_rim_sliding_mean =  nanmean(bin_inside_rim_sliding,2);

%std of binned data
bin_inside_rim_sliding_std = nanstd(bin_inside_rim_sliding,0,2);

%SEM
bin_inside_rim_sliding_SEM = bin_inside_rim_sliding_std./(sqrt(numflies));


%% plot Before VS during after aligning them all at the beginning of 'during' period
%(0 = odoron_frame)
% no binning

%before
inside_rim_bf = inside_rim(1:timeperiods(2),:);
inside_rim_bf_mean = mean(inside_rim_bf,2);

%pre-allocate, the longest possible frames is timeperiods(2) (3 min)
inside_rim_dr = nan(timeperiods(2),numflies);
%during
for fly = 1:numflies
    temp = inside_rim(odoron_frame(fly):timeperiods(3),fly);
    inside_rim_dr(1:length(temp),fly) = temp;
end

inside_rim_dr_mean = nanmean(inside_rim_dr,2);

%% 
figure
set(gcf,'position',[500 10 900 800]);

%convert x range from frame # to time (min)
xrange_min = linspace(1/framespertimebin,(size(inside_rim,1)/(60*framespertimebin)),size(inside_rim,1));

subplot(4,1,1)
plot(xrange_min,inside_rim_mean);
hold on
plot([3 3],[0 1],'r:');%odor on
plot([6 6],[0 1],':'); %odor off

xlabel('time (min)');
ylabel('probability of being inside');
title([fig_title ' :mean of inside_rim'],'interpreter','none');

ylim([0 1]);

set(gca,'box','off','tickdir','out','ytick',[0:.2:1]);

subplot(4,1,2)
%convert x range from frame # to time (min)
xrange_min = linspace(1/framespertimebin,((size(bin_inside_rim,1)*framesinBin)/(60*framespertimebin)),size(bin_inside_rim,1));

SEM_y_plot = [bin_inside_rim_mean'- bin_inside_rim_SEM';(2*bin_inside_rim_SEM')];
h = area(xrange_min,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','b','EdgeColor','none');
alpha(.2);
hold on

plot(xrange_min,bin_inside_rim_mean,'b','linewidth',1.5);

plot([3 3],[0 1],'r:');%odor on
plot([6 6],[0 1],':'); %odor off

xlabel('time (min)');
ylabel('probability of being inside');

ylim([0 1]);
set(gca,'box','off','tickdir','out','ytick',[0:.2:1]);
title(['Probability of being inside (binned), ' num2str(framesinBin/framespertimebin*1000) ' msec/bin ' ]);

subplot(4,1,3)
%convert x range from frame # to time (min)
xrange_min = linspace(1/framespertimebin,(size(inside_rim,1)/(60*framespertimebin)),size(inside_rim,1));

SEM_y_plot = [bin_inside_rim_sliding_mean'- bin_inside_rim_sliding_SEM';(2*bin_inside_rim_sliding_SEM')];
h = area(xrange_min,SEM_y_plot');
set(h(1),'visible','off');
set(h(2),'FaceColor','g','EdgeColor','none');
alpha(.2);
hold on

plot(xrange_min,bin_inside_rim_sliding_mean,'g','linewidth',1.5);

plot([3 3],[0 1],'r:');%odor on
plot([6 6],[0 1],':'); %odor off

xlabel('time (min)');
ylabel('probability of being inside');

ylim([0 1]);
set(gca,'box','off','tickdir','out','ytick',[0:.2:1]);
title(['Probability of being inside (sliding bins), ' num2str(framesinBin/framespertimebin*1000) ' msec/bin ' ]);

subplot(4,1,4)
x_range = [1:timeperiods(2)]/(framespertimebin * 60);
plot(x_range,inside_rim_bf_mean,'b');

hold on
plot(x_range,inside_rim_dr_mean,'r');

set(gca,'box','off','tickdir','out');
xlim([0 3]);

xlabel('time (min)');
ylabel('probability');
title([' Before VS During (aligned at 1st entry)']);

set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'landscape');
saveas(gcf,[fig_title '_aligned_inside_rim.png']);
