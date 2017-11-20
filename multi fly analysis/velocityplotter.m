function [vel_total,velocitytoplot_out2in,velocitytoplot_in2out,...
    velocity_in2out_before,velocity_in2out_during,velocity_in2out_after,...
    velocity_out2in_before,velocity_out2in_during,velocity_out2in_after]...
    = velocityplotter (crossing_in_before,crossing_in_during, crossing_in_after, crossing_out_before,...
    crossing_out_during,crossing_out_after, vel_total, framespertimebin, timeperiods, fig_title)
%calculates velocity at crossing including 2 sec before crossing
%for average calculation, it might not be accurate if there is no before crossing
%info longer than 2 sec


% fly_x = numvals(:,1);
% fly_y = numvals(:,2);
% velx = diff(fly_x);
% vely = diff(fly_y);
% vel_total= sqrt((velx).^2+(vely.^2));
% vel_total= smooth(vel_total,3); %running average of three frames

crossing_in_cell = {crossing_in_before; crossing_in_during; crossing_in_after};
crossing_out_cell = {crossing_out_before; crossing_out_during; crossing_out_after};

if isempty(crossing_in_before) ==1
    periodNo_1 = 2; %skip the 'before' period
    display('There is no crossing in the before period');
else
    periodNo_1 = 1;
end

if isempty(crossing_in_after) == 1
    periodNo_2 = 2; %if there is no crossing in 'after' period
    display('There is no crossing in the after period');
else
    periodNo_2 = 3;
end
period_name ={'Before','During','After'};

for period = periodNo_1:periodNo_2 %each odor period (only the ones with at least one crossing event)
    if crossing_in_cell{period,1}(1) < crossing_out_cell{period,1}(1) ;
        display (period_name{period});
        display ('fly is going in first')
        if numel(crossing_in_cell{period,1}) > numel(crossing_out_cell{period});
            crossing_out_cell{period,1}(end+1) = timeperiods(period+1);
            display ('make crossing out time the end of the odorperiod')
        end
    else
        display (period_name{period});
        display('fly is coming out first');
        crossing_out_cell{period,1}(1) = [];
        display('remove first crossing out')
        if numel(crossing_in_cell{period}) > numel(crossing_out_cell{period})
            crossing_out_cell{period}(end+1)= timeperiods(period+1);
            display('making crossing out time the end of the odorperiod');
        end
    end
    
    %for first crossing
    
    for h = 1;
        if period == 1 & crossing_in_before(1) < 2*framespertimebin %if there is less than 2 sec before the first crossing in the before period
            velocitytoplot_out2in{period, h} =...
                (vel_total(1:((crossing_out_cell{period}(h)))-1));
        else
            velocitytoplot_out2in{period, h} =...
                (vel_total((crossing_in_cell{period}(h))-(2*framespertimebin+1):((crossing_out_cell{period}(h)))-1));
        end
        
    end
    
    for h = 2:length(crossing_in_cell{period});
        
        if crossing_in_cell{period}(h)-(2*framespertimebin) < crossing_out_cell{period}(h-1); %if 2 seconds before the crossing in is before the last crossing out
            maxrow = max(diff(crossing_in_cell{period}));
            velocitytoplot_out2in{period, h} = nan(maxrow,1);
            nannumber = 2*framespertimebin- (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h-1)));%how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_out_cell{period}(h-1)+1):((crossing_out_cell{period}(h))))));
            velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1)...
                = vel_total((crossing_out_cell{period}(h-1)):crossing_out_cell{period}(h)-1); %just take the portion that is outside
            
        else
            velocitytoplot_out2in{period, h} =...
                vel_total((crossing_in_cell{period}(h))-(2*framespertimebin):(crossing_out_cell{period}(h)-1));
            
        end
    end
    
    for h = 1:length(crossing_in_cell{period})-1;
        if crossing_out_cell{period}(h)-(2*framespertimebin) < crossing_in_cell{period}(h); %if 2 seconds before the crossing out is before the last crossing in
            velocitytoplot_in2out{period, h} = nan(timeperiods(2)-timeperiods(1),1);
            nannumber = 2*framespertimebin- (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)));%how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_in_cell{period}(h)+1):((crossing_in_cell{period}(h+1))))));
            velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1)...
                = vel_total((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside
            
        else
            velocitytoplot_in2out{period, h} =...
                (vel_total((crossing_out_cell{period}(h))-(2*framespertimebin):((crossing_in_cell{period}(h+1)-1))));
            
        end
    end
end


% fly_x = numvals(:,1);
% fly_y = numvals(:,2);
% velx = diff(fly_x);
% vely = diff(fly_y);
% vel_total= sqrt((velx).^2+(vely.^2));
% vel_total= smooth(vel_total,3); %running average of three frames

crossing_in_cell = {crossing_in_before; crossing_in_during; crossing_in_after};
crossing_out_cell = {crossing_out_before; crossing_out_during; crossing_out_after};

if isempty(crossing_in_before) ==1
    periodNo_1 = 2; %skip the 'before' period
    display('There is no crossing in the before period');
else
    periodNo_1 = 1;
end

if isempty(crossing_in_after) == 1
    periodNo_2 = 2; %if there is no crossing in 'after' period
    display('There is no crossing in the after period');
else
    periodNo_2 = 3;
end
period_name ={'Before','During','After'};

for period = periodNo_1:periodNo_2 %each odor period (only the ones with at least one crossing event)
    if crossing_in_cell{period,1}(1) < crossing_out_cell{period,1}(1) ;
        display (period_name{period});
        display ('fly is going in first')
        if numel(crossing_in_cell{period,1}) > numel(crossing_out_cell{period});
            crossing_out_cell{period,1}(end+1) = timeperiods(period+1);
            display ('make crossing out time the end of the odorperiod')
        end
    else
        display (period_name{period});
        display('fly is coming out first');
        crossing_out_cell{period,1}(1) = [];
        display('remove first crossing out')
        if numel(crossing_in_cell{period}) > numel(crossing_out_cell{period})
            crossing_out_cell{period}(end+1)= timeperiods(period+1);
            display('making crossing out time the end of the odorperiod');
        end
    end
    
    %for first crossing
    
    for h = 1;
        if period == 1 && crossing_in_before(1) < 2*framespertimebin %if there is less than 2 sec before the first crossing in the before period
            velocitytoplot_out2in{period, h} =...
                (vel_total(1:((crossing_out_cell{period}(h)))-1));
        else
            velocitytoplot_out2in{period, h} =...
                (vel_total((crossing_in_cell{period}(h))-(2*framespertimebin+1):((crossing_out_cell{period}(h)))-1));
        end
        
    end
    
    for h = 2:length(crossing_in_cell{period});
        
        if crossing_in_cell{period}(h)-(2*framespertimebin) < crossing_out_cell{period}(h-1); %if 2 seconds before the crossing in is before the last crossing out
            maxrow = max(diff(crossing_in_cell{period}));
            velocitytoplot_out2in{period, h} = nan(maxrow,1);
            nannumber = 2*framespertimebin- (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h-1)));%how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_out_cell{period}(h-1)+1):((crossing_out_cell{period}(h))))));
            velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1)...
                = vel_total((crossing_out_cell{period}(h-1)):crossing_out_cell{period}(h)-1); %just take the portion that is outside
            
        else
            velocitytoplot_out2in{period, h} =...
                vel_total((crossing_in_cell{period}(h))-(2*framespertimebin):(crossing_out_cell{period}(h)-1));
            
        end
    end
    
    for h = 1:length(crossing_in_cell{period})-1;
        if crossing_out_cell{period}(h)-(2*framespertimebin) < crossing_in_cell{period}(h); %if 2 seconds before the crossing out is before the last crossing in
            velocitytoplot_in2out{period, h} = nan(timeperiods(2)-timeperiods(1),1);
            nannumber = 2*framespertimebin- (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)));%how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_in_cell{period}(h)+1):((crossing_in_cell{period}(h+1))))));
            velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1)...
                = vel_total((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside
            
        else
            velocitytoplot_in2out{period, h} =...
                (vel_total((crossing_out_cell{period}(h))-(2*framespertimebin):((crossing_in_cell{period}(h+1)-1))));
            
        end
    end
    
    if length(crossing_out_cell{period}) == 1 % if there is only one crossing
        if crossing_out_cell{period}(1)-(2*framespertimebin) < crossing_in_cell{period}(1); %if 2 seconds before the crossing out is before the last crossing in
            velocitytoplot_in2out{period, 1} = nan(timeperiods(2)-timeperiods(1),1);
            nannumber = 2*framespertimebin- (crossing_out_cell{period}(1)-(crossing_in_cell{period}(1)));%how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_in_cell{period}(1)+1):(timeperiods(period+1)))));
            velocitytoplot_in2out{period, 1}(nannumber+1:nannumber+1+sizetoplot-1)...
                = vel_total((crossing_in_cell{period}(1)):(timeperiods(period+1)-1)); %just take the portion that is outside
            
        else
            velocitytoplot_in2out{period, 1} =...
                (vel_total((crossing_out_cell{period}(1))-(2*framespertimebin):(timeperiods(period+1)-1)));
            
        end
    end
    
end


%copying everything to matrix (2 sec before crossing + 5 sec after
%crossing)
if periodNo_1 == 2 %no crossing in the before period
    velocity_in2out_before = nan(7*framespertimebin,1);
else
    nb = length(find(~cellfun('isempty',velocitytoplot_in2out(1,:))));
    velocity_in2out_before = nan(7*framespertimebin,nb);
    for n=1:nb
        if length(velocitytoplot_in2out{1,n}) >= 7*framespertimebin
            velocity_in2out_before(1:7*framespertimebin,n) = velocitytoplot_in2out{1,n}(1:7*framespertimebin,:);
        else
            velocity_in2out_before(1:length(velocitytoplot_in2out{1,n}),n) = velocitytoplot_in2out{1,n};
        end
    end
end
vel_i2o_avg(:,1) = nanmean(velocity_in2out_before,2);

nd = length(find(~cellfun('isempty',velocitytoplot_in2out(2,:))));
velocity_in2out_during = nan(7*framespertimebin,nd);
for n=1:nd
    if length(velocitytoplot_in2out{2,n}) >= 7*framespertimebin
        velocity_in2out_during(1:7*framespertimebin,n) = velocitytoplot_in2out{2,n}(1:7*framespertimebin,:);
    else
        velocity_in2out_during(1:length(velocitytoplot_in2out{2,n}),n) = velocitytoplot_in2out{2,n};
    end
end
vel_i2o_avg(:,2) = nanmean(velocity_in2out_during,2);

if periodNo_2 == 2 %if there is no crossing in 'after' period
    velocity_in2out_after = nan(7*framespertimebin,1);
else
    na = length(find(~cellfun('isempty',velocitytoplot_in2out(3,:))));
    velocity_in2out_after = nan(7*framespertimebin,na);
    for n=1:na
        if length(velocitytoplot_in2out{3,n}) >= 7*framespertimebin
            velocity_in2out_after(1:7*framespertimebin,n) = velocitytoplot_in2out{3,n}(1:7*framespertimebin,:);
        else
            velocity_in2out_after(1:length(velocitytoplot_in2out{3,n}),n) = velocitytoplot_in2out{3,n};
        end
    end
end
vel_i2o_avg(:,3)= nanmean(velocity_in2out_after,2);

%Out2in
if periodNo_1 == 2 % no crossing in the before period
    velocity_out2in_before = nan(7*framespertimebin,1);
else
    nb = length(find(~cellfun('isempty',velocitytoplot_out2in(1,:))));
    velocity_out2in_before = nan(7*framespertimebin,nb);
    for n=1:nb
        if length(velocitytoplot_out2in{1,n}) >= 7*framespertimebin
            velocity_out2in_before(1:7*framespertimebin,n) = velocitytoplot_out2in{1,n}(1:7*framespertimebin,:);
        else
            velocity_out2in_before(1:length(velocitytoplot_out2in{1,n}),n) = velocitytoplot_out2in{1,n};
        end
    end
end
vel_o2i_avg(:,1) = nanmean(velocity_out2in_before,2);

nd = length(find(~cellfun('isempty',velocitytoplot_out2in(2,:))));
velocity_out2in_during = nan(7*framespertimebin,nd);
for n=1:nd
    if length(velocitytoplot_out2in{2,n}) >= 7*framespertimebin
        velocity_out2in_during(1:7*framespertimebin,n) = velocitytoplot_out2in{2,n}(1:7*framespertimebin,:);
    else
        velocity_out2in_during(1:length(velocitytoplot_out2in{2,n}),n) = velocitytoplot_out2in{2,n};
    end
end
vel_o2i_avg(:,2) = nanmean(velocity_out2in_during,2);

if periodNo_2 == 2 %no crossing in the 'after' period
    velocity_out2in_after = nan(7*framespertimebin,1);
else
    na = length(find(~cellfun('isempty',velocitytoplot_out2in(3,:))));
    velocity_out2in_after = nan(7*framespertimebin,na);
    for n=1:na
        if length(velocitytoplot_out2in{3,n}) >= 7*framespertimebin
            velocity_out2in_after(1:7*framespertimebin,n) = velocitytoplot_out2in{3,n}(1:7*framespertimebin,:);
        else
            velocity_out2in_after(1:length(velocitytoplot_out2in{3,n}),n) = velocitytoplot_out2in{3,n};
        end
    end
end
vel_o2i_avg(:,3) = nanmean(velocity_out2in_after,2);


cmap=[0.5781  0         0.8242;
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


figure
set(gcf,'color','white','Position',[520 82 997 716]);

for period = periodNo_1:periodNo_2;
    %for crossing out2in
    subplot(3,2,period*2-1)
    for h = 1:length(crossing_in_cell{period});
        if h <= 20
            plot (velocitytoplot_out2in{period, h} ,'color', cmap(h,:))
        else
            plot (velocitytoplot_out2in{period, h} ,'color', cmap(h-20,:))
        end
        hold on
        plot(vel_o2i_avg(:,period),'linewidth',2);
        xlim ([0 7*framespertimebin]) %2 sec before crossing + 5 sec after crossing
        ylim ([0 1])
        plot([2*framespertimebin+1 2*framespertimebin+1],[0 2],'k:') %dotted line marking 0
        title(['Crossing in: ' period_name{period}],'fontsize',9);
        xlabel('frame number','fontsize',9);
        ylabel('velocity(cm/sec)','fontsize',9);
        set(gca,'Box','off','Xtick',(0:30:300),'fontsize',8);
    end
    
    %for crossing in2out
    subplot(3,2,period*2)
    for h = 1:length(crossing_out_cell{period})-1;
        if h <= 20
            plot (velocitytoplot_in2out{period, h} ,'color', cmap(h,:))
        else
            plot (velocitytoplot_in2out{period, h} ,'color', cmap(h-20,:))
        end
        hold on
        plot(vel_o2i_avg(:,period),'g','linewidth',2);
        xlim ([0 7*framespertimebin])  %2 sec before crossing + 5 sec after crossing
        ylim ([0 1])
        plot([2*framespertimebin+1 2*framespertimebin+1],[0 2],'k:') %dotted line marking 0
        title(['Crossing out: ' period_name{period}],'fontsize',9);
        xlabel('frame number','fontsize',9);
        ylabel('velocity(cm/sec)','fontsize',9);
        set(gca,'Box','off','Xtick',(0:30:300),'fontsize',8);
        
    end
end
ax = axes('position',[0,0,1,1],'visible','off');
tx = text(0.3,0.97,[fig_title ' velocity at crossing events']);
set(tx,'fontweight','bold');

set(gcf, 'PaperPositionMode', 'auto');
saveas(gcf, [fig_title ' velocityplot.png']);