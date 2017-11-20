function [runstop_in2out_before,runstop_in2out_during,runstop_in2out_after,...
   runstop_out2in_before, runstop_out2in_during,runstop_out2in_after]...
    = runstopatcrossing (filename,crossing_in_before,crossing_in_during, crossing_in_after, crossing_out_before,...
    crossing_out_during,crossing_out_after, velocity_classified, framespertimebin, timeperiods)
%calculates velocity at crossing including 2 sec before crossing
%for average calculation, it might not be accurate if there is no before crossing
%info longer than 2 sec 


display('velocity unit is pixel/frame')

% velx = diff(fly_x);
% vely = diff(fly_y);
% velocity_classified= sqrt((velx).^2+(vely.^2));
 velocity_classified=[0;velocity_classified];

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
runstoptoplot_out2in = cell(3,1);
runstoptoplot_in2out = cell(3,1);

notreal_out = zeros(1,3);

%to make crossing in before than crossing outs=============================
for period = periodNo_1:periodNo_2 %each odor period (only the ones with at least one crossing event)
     if isempty(crossing_out_cell{period});
      crossing_out_cell{period,1}(1) = timeperiods(period+1);
            display ('make crossing out time the end of the odorperiod')
            notreal_out(period) = 1; 
   else
    if crossing_in_cell{period,1}(1) < crossing_out_cell{period,1}(1) ;
        display (period_name{period});
        display ([filename ' fly is going in first'])
        if numel(crossing_in_cell{period,1}) > numel(crossing_out_cell{period});
            crossing_out_cell{period,1}(end+1) = timeperiods(period+1);
            display ('make crossing out time the end of the odorperiod')
            notreal_out(period) = 1;
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
     end
     
    %======================================================================
    
    %out2in events first===================================================
    
    %for the very first crossing out2in in 'before' period
    if isempty(crossing_in_before) == 0
        if crossing_in_before(1) < 2*framespertimebin+1 %if there is less than 2 sec before the first crossing in the before period
            %first pre-allocate the matrix so that the crossing frame is at 2
            %second
            runstoptoplot_out2in{1,1} = nan((crossing_out_cell{1,1}(1)-crossing_in_cell{1,1}(1)+2*framespertimebin),1);
            %then add the values
            runstoptoplot_out2in{1, 1}(((2*framespertimebin)-crossing_in_before(1)+2):end) =...
                velocity_classified(1:(crossing_out_cell{1}(1))-1);
        else %if there is longer than 2 sec before the first crossing in
            runstoptoplot_out2in{1,1} =...
                velocity_classified((crossing_in_cell{1}(1))-(2*framespertimebin):(crossing_out_cell{1}(1))-1);
        end
    end
    %for the first crossing in other periods
    if period > 1
        if isempty(crossing_out_cell{period-1}) == 0 %if there was any crossing in 'before'
            if (crossing_in_cell{period}(1)-(2*framespertimebin)) < (crossing_out_cell{period-1}(end)); %if 2 seconds before the crossing in is before the last crossing out
                maxrow = max(diff(crossing_in_cell{period}));
                runstoptoplot_out2in{period, 1} = nan(maxrow+(2*framespertimebin),1);
                nannumber = 2*framespertimebin- (crossing_in_cell{period}(1)-(crossing_out_cell{period-1}(end)));%how many nans will it take to make this vector the same length?
                sizetoplot = length((velocity_classified((crossing_out_cell{period-1}(end)+1):((crossing_out_cell{period}(1))))));
                runstoptoplot_out2in{period, 1}(nannumber+1:nannumber+sizetoplot)...
                    = velocity_classified((crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1); %just take the portion that is outside
            else
                runstoptoplot_out2in{period, 1} =...
                    velocity_classified((crossing_in_cell{period}(1))-(2*framespertimebin):(crossing_out_cell{period}(1)-1));
                
            end
        else %if there was no crossins in 'before'
            runstoptoplot_out2in{period, 1} =...
                velocity_classified((crossing_in_cell{period}(1))-(2*framespertimebin):(crossing_out_cell{period}(1)-1));
        end
    end
    
    %for second crossing and afterwards
    for h = 2:length(crossing_in_cell{period});
        
        if crossing_in_cell{period}(h)-(2*framespertimebin) < crossing_out_cell{period}(h-1); %if 2 seconds before the crossing in is before the last crossing out
            maxrow = max(diff(crossing_in_cell{period}));
            runstoptoplot_out2in{period, h} = nan(maxrow+(2*framespertimebin),1);
            nannumber = 2*framespertimebin- (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h-1)));%how many nans will it take to make this vector the same length?
            sizetoplot = (crossing_out_cell{period}(h))-(crossing_out_cell{period}(h-1)+1);
            runstoptoplot_out2in{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = velocity_classified((crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1)); %just take the portion that is outside
            
        else
            runstoptoplot_out2in{period, h} =...
                velocity_classified((crossing_in_cell{period}(h))-(2*framespertimebin):(crossing_out_cell{period}(h)-1));
            
        end
    end
    
    
    %for in2out events====================================================
    
    for h = 1:length(crossing_in_cell{period})-1;
        if crossing_out_cell{period}(h)-(2*framespertimebin) < crossing_in_cell{period}(h); %if 2 seconds before the crossing out is before the last crossing in
            maxrow = max(diff(crossing_out_cell{period}));
            runstoptoplot_in2out{period, h} = nan(maxrow+(2*framespertimebin),1);
            nannumber = 2*framespertimebin- (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)));%how many nans will it take to make this vector the same length?
            sizetoplot = (crossing_in_cell{period}(h+1))-(crossing_in_cell{period}(h)+1);
            runstoptoplot_in2out{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = velocity_classified((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside
            
        else
            runstoptoplot_in2out{period, h} =...
                (velocity_classified((crossing_out_cell{period}(h))-(2*framespertimebin):((crossing_in_cell{period}(h+1)-1))));
            
        end
    end

    if notreal_out(period) == 0 %do the following only when last crossing_out is real crossing
    %for the last in2out crossing
    if crossing_out_cell{period}(end)-(2*framespertimebin) < crossing_in_cell{period}(end); %there is less than 2 sec before last crossing out and period end
        maxrow = max(diff(crossing_out_cell{period}));
        runstoptoplot_in2out{period, end+1} = nan(maxrow+(2*framespertimebin),1);
        nannumber = 2*framespertimebin- (crossing_out_cell{period}(end)-crossing_in_cell{period}(end));%how many nans will it take to make this vector the same length?
        sizetoplot = (timeperiods(period+1) - crossing_in_cell{period}(end));
        runstoptoplot_in2out{period, end}(nannumber+1:nannumber+sizetoplot+1)...
            = velocity_classified((crossing_in_cell{period}(end)):timeperiods(period+1)); %just take the portion that is outside
        
    else
        runstoptoplot_in2out{period, end+1} =...
            (velocity_classified((crossing_out_cell{period}(end))-(2*framespertimebin):timeperiods(period+1)));
        
    end
    end
  
end
%%
%deleting the empty elements in the cell array
%before
runstoptoplot_in2out_before = runstoptoplot_in2out(1,:);
vel_i2o_before = runstoptoplot_in2out_before(~cellfun('isempty',runstoptoplot_in2out_before));

runstoptoplot_out2in_before = runstoptoplot_out2in(1,:);
vel_o2i_before = runstoptoplot_out2in_before(~cellfun('isempty',runstoptoplot_out2in_before));

%during
runstoptoplot_in2out_during = runstoptoplot_in2out(2,:);
vel_i2o_during = runstoptoplot_in2out_during(~cellfun('isempty',runstoptoplot_in2out_during));

runstoptoplot_out2in_during = runstoptoplot_out2in(2,:);
vel_o2i_during = runstoptoplot_out2in_during(~cellfun('isempty',runstoptoplot_out2in_during));

%after
runstoptoplot_in2out_after = runstoptoplot_in2out(3,:);
vel_i2o_after = runstoptoplot_in2out_after(~cellfun('isempty',runstoptoplot_in2out_after));

runstoptoplot_out2in_after = runstoptoplot_out2in(3,:);
vel_o2i_after = runstoptoplot_out2in_after(~cellfun('isempty',runstoptoplot_out2in_after));


%copying everything to matrix (2 sec before crossing + 5 sec after
%crossing)
if periodNo_1 == 2 %no crossing in the before period
    runstop_in2out_before = nan(7*framespertimebin,1);
else
    nb = length(vel_i2o_before);
    runstop_in2out_before = nan(7*framespertimebin,nb);
    for n=1:nb
        if length(vel_i2o_before{1,n}) >= 7*framespertimebin
            runstop_in2out_before(1:7*framespertimebin,n) = vel_i2o_before{1,n}(1:7*framespertimebin,:);
        else
            runstop_in2out_before(1:length(vel_i2o_before{1,n}),n) = vel_i2o_before{1,n};
        end
    end
end
% vel_i2o_avg(:,1) = nanmean(runstop_in2out_before,2);

nd = length(vel_i2o_during);
runstop_in2out_during = nan(7*framespertimebin,nd);
for n=1:nd
    if length(vel_i2o_during{1,n}) >= 7*framespertimebin
        runstop_in2out_during(1:7*framespertimebin,n) = vel_i2o_during{1,n}(1:7*framespertimebin,:);
    else
        runstop_in2out_during(1:length(vel_i2o_during{1,n}),n) = vel_i2o_during{1,n};
    end
end
% vel_i2o_avg(:,2) = nanmean(runstop_in2out_during,2);

if periodNo_2 == 2 %if there is no crossing in 'after' period
    runstop_in2out_after = nan(7*framespertimebin,1);
else
    na = length(vel_i2o_after);
    runstop_in2out_after = nan(7*framespertimebin,na);
    for n=1:na
        if length(vel_i2o_after{1,n}) >= 7*framespertimebin
            runstop_in2out_after(1:7*framespertimebin,n) = vel_i2o_after{1,n}(1:7*framespertimebin,:);
        else
            runstop_in2out_after(1:length(vel_i2o_after{1,n}),n) = vel_i2o_after{1,n};
        end
    end
end
% vel_i2o_avg(:,3)= nanmean(runstop_in2out_after,2);

%Out2in
if periodNo_1 == 2 % no crossing in the before period
    runstop_out2in_before = nan(7*framespertimebin,1);
else
    nb = length(vel_o2i_before);
    runstop_out2in_before = nan(7*framespertimebin,nb);
    for n=1:nb
        if length(vel_o2i_before{1,n}) >= 7*framespertimebin
            runstop_out2in_before(1:7*framespertimebin,n) = vel_o2i_before{1,n}(1:7*framespertimebin,:);
        else
            runstop_out2in_before(1:length(vel_o2i_before{1,n}),n) = vel_o2i_before{1,n};
        end
    end
end
% vel_o2i_avg(:,1) = nanmean(runstop_out2in_before,2);

nd = length(vel_o2i_during);
runstop_out2in_during = nan(7*framespertimebin,nd);
for n=1:nd
    if length(vel_o2i_during{1,n}) >= 7*framespertimebin
        runstop_out2in_during(1:7*framespertimebin,n) = vel_o2i_during{1,n}(1:7*framespertimebin,:);
    else
        runstop_out2in_during(1:length(vel_o2i_during{1,n}),n) = vel_o2i_during{1,n};
    end
end
% vel_o2i_avg(:,2) = nanmean(runstop_out2in_during,2);

if periodNo_2 == 2 %no crossing in the 'after' period
    runstop_out2in_after = nan(7*framespertimebin,1);
else
    na = length(vel_o2i_after);
    runstop_out2in_after = nan(7*framespertimebin,na);
    for n=1:na
        if length(vel_o2i_after{1,n}) >= 7*framespertimebin
            runstop_out2in_after(1:7*framespertimebin,n) = vel_o2i_after{1,n}(1:7*framespertimebin,:);
        else
            runstop_out2in_after(1:length(vel_o2i_after{1,n}),n) = vel_o2i_after{1,n};
        end
    end
end
% vel_o2i_avg(:,3) = nanmean(runstop_out2in_after,2);
keyboard
