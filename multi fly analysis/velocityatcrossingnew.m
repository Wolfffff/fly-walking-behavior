function [velocity_in2out_before,velocity_in2out_during,velocity_in2out_after,...
    velocity_out2in_before,velocity_out2in_during,velocity_out2in_after]...
    = velocityatcrossing (filename,crossing_in_before,crossing_in_during, crossing_in_after, crossing_out_before,...
    crossing_out_during,crossing_out_after, fly_x,fly_y, framespertimebin, timeperiods)
%calculates velocity at crossing including 2 sec before crossing
%for average calculation, it might not be accurate if there is no before crossing
%info longer than 2 sec 


display('velocity unit is pixel/frame')

velx = diff(fly_x);
vely = diff(fly_y);
vel_total= sqrt((velx).^2+(vely.^2));
vel_total=[0;vel_total];

crossing_in_cell = {crossing_in_before; crossing_in_during; crossing_in_after};
crossing_out_cell = {crossing_out_before; crossing_out_during; crossing_out_after};

%to avoid errors that occur when there is no crossing======================
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
%==========================================================================
period_name ={'Before','During','After'};
velocitytoplot_out2in = cell(3,1);
velocitytoplot_in2out = cell(3,1);

%to make crossing in before than crossing outs=============================
for period = periodNo_1:periodNo_2 %each odor period (only the ones with at least one crossing event)
    if crossing_in_cell{period,1}(1) < crossing_out_cell{period,1}(1) ;
        display (period_name{period});
        display ([filename ' fly is going in first'])
        if numel(crossing_in_cell{period,1}) > numel(crossing_out_cell{period});
            crossing_out_cell{period,1}(end+1) = timeperiods(period+1);
            display ('make crossing out time the end of the odorperiod')
        end
    else
        display (period_name{period});
        display([filename 'fly is coming out first']);
        crossing_out_cell{period,1}(1) = [];
        display('remove first crossing out')
        if numel(crossing_in_cell{period}) > numel(crossing_out_cell{period})
            crossing_out_cell{period}(end+1)= timeperiods(period+1);
            display('making crossing out time the end of the odorperiod');
        end
    end
    %======================================================================
    
    %out2in events first===================================================
    
    %for the very first crossing out2in in 'before' period
    if isempty(crossing_in_before) == 0
        if crossing_in_before(1) < 2*framespertimebin+1 %if there is less than 2 sec before the first crossing in the before period
            %first pre-allocate the matrix so that the crossing frame is at 2
            %second
            velocitytoplot_out2in{1,1} = nan((crossing_out_cell{1,1}(1)-crossing_in_cell{1,1}(1)+2*framespertimebin),1);
            %then add the values
            velocitytoplot_out2in{1, 1}(((2*framespertimebin)-crossing_in_before(1)+2):end) =...
                vel_total(1:(crossing_out_cell{1}(1))-1);
        else %if there is longer than 2 sec before the first crossing in
            velocitytoplot_out2in{1,1} =...
                vel_total((crossing_in_cell{1}(1))-(2*framespertimebin):(crossing_out_cell{1}(1))-1);
        end
    end
    %for the first crossing in other periods
    if period > 1
        if isempty(crossing_out_cell{period-1}) == 0 %if there was any crossing in 'before'
            if (crossing_in_cell{period}(1)-(2*framespertimebin)) < (crossing_out_cell{period-1}(end)); %if 2 seconds before the crossing in is before the last crossing out
                maxrow = max(diff(crossing_in_cell{period}));
                velocitytoplot_out2in{period, 1} = nan(maxrow+(2*framespertimebin),1);
                nannumber = 2*framespertimebin- (crossing_in_cell{period}(1)-(crossing_out_cell{period-1}(end)));%how many nans will it take to make this vector the same length?
                sizetoplot = length((vel_total((crossing_out_cell{period-1}(end)+1):((crossing_out_cell{period}(1))))));
                velocitytoplot_out2in{period, 1}(nannumber+1:nannumber+sizetoplot)...
                    = vel_total((crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1); %just take the portion that is outside
            else
                velocitytoplot_out2in{period, 1} =...
                    vel_total((crossing_in_cell{period}(1))-(2*framespertimebin):(crossing_out_cell{period}(1)-1));
                
            end
        else %if there was no crossins in 'before'
            velocitytoplot_out2in{period, 1} =...
                vel_total((crossing_in_cell{period}(1))-(2*framespertimebin):(crossing_out_cell{period}(1)-1));
        end
    end
    
    %for second crossing and afterwards
    for h = 2:length(crossing_in_cell{period});
        
        if crossing_in_cell{period}(h)-(2*framespertimebin) < crossing_out_cell{period}(h-1); %if 2 seconds before the crossing in is before the last crossing out
            maxrow = max(diff(crossing_in_cell{period}));
            velocitytoplot_out2in{period, h} = nan(maxrow+(2*framespertimebin),1);
            nannumber = 2*framespertimebin- (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h-1)));%how many nans will it take to make this vector the same length?
            sizetoplot = (crossing_out_cell{period}(h))-(crossing_out_cell{period}(h-1)+1);
            velocitytoplot_out2in{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = vel_total((crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1)); %just take the portion that is outside
            
        else
            velocitytoplot_out2in{period, h} =...
                vel_total((crossing_in_cell{period}(h))-(2*framespertimebin):(crossing_out_cell{period}(h)-1));
            
        end
    end
    
    
    %for in2out events====================================================
    
    for h = 1:length(crossing_in_cell{period})-1;
        if crossing_out_cell{period}(h)-(2*framespertimebin) < crossing_in_cell{period}(h); %if 2 seconds before the crossing out is before the last crossing in
            maxrow = max(diff(crossing_out_cell{period}));
            velocitytoplot_in2out{period, h} = nan(maxrow+(2*framespertimebin),1);
            nannumber = 2*framespertimebin- (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)));%how many nans will it take to make this vector the same length?
            sizetoplot = (crossing_in_cell{period}(h+1))-(crossing_in_cell{period}(h)+1);
            velocitytoplot_in2out{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = vel_total((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside
            
        else
            velocitytoplot_in2out{period, h} =...
                (vel_total((crossing_out_cell{period}(h))-(2*framespertimebin):((crossing_in_cell{period}(h+1)-1))));
            
        end
    end
    
    %for the last in2out crossing
    if crossing_out_cell{period}(end)-(2*framespertimebin) < crossing_in_cell{period}(end); %there is less than 2 sec before last crossing out and period end
        maxrow = max(diff(crossing_out_cell{period}));
        velocitytoplot_in2out{period, end+1} = nan(maxrow+(2*framespertimebin),1);
        nannumber = 2*framespertimebin- (crossing_out_cell{period}(end)-crossing_in_cell{period}(end));%how many nans will it take to make this vector the same length?
        sizetoplot = (timeperiods(period+1) - crossing_in_cell{period}(end));
        velocitytoplot_in2out{period, end}(nannumber+1:nannumber+sizetoplot+1)...
            = vel_total((crossing_in_cell{period}(end)):timeperiods(period+1)); %just take the portion that is outside
        
    else
        velocitytoplot_in2out{period, end+1} =...
            (vel_total((crossing_out_cell{period}(end))-(2*framespertimebin):timeperiods(period+1)));
        
    end
    
end

%deleting the empty elements in the cell array
%before
velocitytoplot_in2out_before = velocitytoplot_in2out(1,:);
vel_i2o_before = velocitytoplot_in2out_before(~cellfun('isempty',velocitytoplot_in2out_before));

velocitytoplot_out2in_before = velocitytoplot_out2in(1,:);
vel_o2i_before = velocitytoplot_out2in_before(~cellfun('isempty',velocitytoplot_out2in_before));

%during
velocitytoplot_in2out_during = velocitytoplot_in2out(2,:);
vel_i2o_during = velocitytoplot_in2out_during(~cellfun('isempty',velocitytoplot_in2out_during));

velocitytoplot_out2in_during = velocitytoplot_out2in(2,:);
vel_o2i_during = velocitytoplot_out2in_during(~cellfun('isempty',velocitytoplot_out2in_during));

%after
velocitytoplot_in2out_after = velocitytoplot_in2out(3,:);
vel_i2o_after = velocitytoplot_in2out_after(~cellfun('isempty',velocitytoplot_in2out_after));

velocitytoplot_out2in_after = velocitytoplot_out2in(3,:);
vel_o2i_after = velocitytoplot_out2in_after(~cellfun('isempty',velocitytoplot_out2in_after));


%copying everything to matrix (2 sec before crossing + 5 sec after
%crossing)
if periodNo_1 == 2 %no crossing in the before period
    velocity_in2out_before = nan(7*framespertimebin,1);
else
    nb = length(vel_i2o_before);
    velocity_in2out_before = nan(7*framespertimebin,nb);
    for n=1:nb
        if length(vel_i2o_before{1,n}) >= 7*framespertimebin
            velocity_in2out_before(1:7*framespertimebin,n) = vel_i2o_before{1,n}(1:7*framespertimebin,:);
        else
            velocity_in2out_before(1:length(vel_i2o_before{1,n}),n) = vel_i2o_before{1,n};
        end
    end
end
vel_i2o_avg(:,1) = nanmean(velocity_in2out_before,2);

nd = length(vel_i2o_during);
velocity_in2out_during = nan(7*framespertimebin,nd);
for n=1:nd
    if length(vel_i2o_during{1,n}) >= 7*framespertimebin
        velocity_in2out_during(1:7*framespertimebin,n) = vel_i2o_during{1,n}(1:7*framespertimebin,:);
    else
        velocity_in2out_during(1:length(vel_i2o_during{1,n}),n) = vel_i2o_during{1,n};
    end
end
vel_i2o_avg(:,2) = nanmean(velocity_in2out_during,2);

if periodNo_2 == 2 %if there is no crossing in 'after' period
    velocity_in2out_after = nan(7*framespertimebin,1);
else
    na = length(vel_i2o_after);
    velocity_in2out_after = nan(7*framespertimebin,na);
    for n=1:na
        if length(vel_i2o_after{1,n}) >= 7*framespertimebin
            velocity_in2out_after(1:7*framespertimebin,n) = vel_i2o_after{1,n}(1:7*framespertimebin,:);
        else
            velocity_in2out_after(1:length(vel_i2o_after{1,n}),n) = vel_i2o_after{1,n};
        end
    end
end
vel_i2o_avg(:,3)= nanmean(velocity_in2out_after,2);

%Out2in
if periodNo_1 == 2 % no crossing in the before period
    velocity_out2in_before = nan(7*framespertimebin,1);
else
    nb = length(vel_o2i_before);
    velocity_out2in_before = nan(7*framespertimebin,nb);
    for n=1:nb
        if length(vel_o2i_before{1,n}) >= 7*framespertimebin
            velocity_out2in_before(1:7*framespertimebin,n) = vel_o2i_before{1,n}(1:7*framespertimebin,:);
        else
            velocity_out2in_before(1:length(vel_o2i_before{1,n}),n) = vel_o2i_before{1,n};
        end
    end
end
vel_o2i_avg(:,1) = nanmean(velocity_out2in_before,2);

nd = length(vel_o2i_during);
velocity_out2in_during = nan(7*framespertimebin,nd);
for n=1:nd
    if length(vel_o2i_during{1,n}) >= 7*framespertimebin
        velocity_out2in_during(1:7*framespertimebin,n) = vel_o2i_during{1,n}(1:7*framespertimebin,:);
    else
        velocity_out2in_during(1:length(vel_o2i_during{1,n}),n) = vel_o2i_during{1,n};
    end
end
vel_o2i_avg(:,2) = nanmean(velocity_out2in_during,2);

if periodNo_2 == 2 %no crossing in the 'after' period
    velocity_out2in_after = nan(7*framespertimebin,1);
else
    na = length(vel_o2i_after);
    velocity_out2in_after = nan(7*framespertimebin,na);
    for n=1:na
        if length(vel_o2i_after{1,n}) >= 7*framespertimebin
            velocity_out2in_after(1:7*framespertimebin,n) = vel_o2i_after{1,n}(1:7*framespertimebin,:);
        else
            velocity_out2in_after(1:length(vel_o2i_after{1,n}),n) = vel_o2i_after{1,n};
        end
    end
end
vel_o2i_avg(:,3) = nanmean(velocity_out2in_after,2);
