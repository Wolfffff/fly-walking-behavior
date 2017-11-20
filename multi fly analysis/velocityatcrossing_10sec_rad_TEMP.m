function [velocity_in2out_before,velocity_in2out_during,velocity_in2out_after,...
    velocity_out2in_before,velocity_out2in_during,velocity_out2in_after...
    radvel_in2out_before, radvel_in2out_during, radvel_in2out_after,...
    radvel_out2in_before, radvel_out2in_during, radvel_out2in_after...
    crossing_i2o_frames_bf,crossing_i2o_frames_dr,crossing_i2o_frames_af,...
    crossing_o2i_frames_bf,crossing_o2i_frames_dr,crossing_o2i_frames_af,  runstop_in2out_before,runstop_in2out_during,runstop_in2out_after,...
    runstop_out2in_before, runstop_out2in_during,runstop_out2in_after]...
    = velocityatcrossing_10sec_rad(filename,crossing_in_before,crossing_in_during, crossing_in_after, crossing_out_before,...
    crossing_out_during,crossing_out_after, vel_total,velocity_classified, rad_vel_sqrt, framespertimebin, timeperiods, timebefore, totaltime)
%calculates velocity at crossing including 10 sec before crossing
%for average calculation, it might not be accurate if there is no before crossing
%info longer than 10 sec 
timeperiods(4) = length(vel_total);

% filename = fig_title;

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
runstoptoplot_out2in = cell(3,1);
runstoptoplot_in2out = cell(3,1);
radvel_out2in = cell(3,1);
radvel_in2out = cell(3,1);

notreal_out = zeros(1,3);

crossing_o2i_frames = cell(3,1);
crossing_i2o_frames = cell(3,1);

%to make crossing in before than crossing outs=============================
for period = periodNo_1:periodNo_2 %each odor period (only the ones with at least one crossing event)
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
    %======================================================================
    
    %out2in events first===================================================
    
    %for the very first crossing out2in in 'before' period
    if isempty(crossing_in_before) == 0
        if crossing_in_before(1) < timebefore*framespertimebin+1 %if there is less than timebefore sec before the first crossing in the before period
            %first pre-allocate the matrix so that the crossing frame is at
            %10 seconds
            velocitytoplot_out2in{1,1} = nan((crossing_out_cell{1,1}(1)-crossing_in_cell{1,1}(1)+timebefore*framespertimebin),1);
            %then add the values
            velocitytoplot_out2in{1,1}(((timebefore*framespertimebin)-crossing_in_before(1)+2):end) =...
                vel_total(1:(crossing_out_cell{1}(1))-1);
             runstoptoplot_out2in{1,1} = nan((crossing_out_cell{1,1}(1)-crossing_in_cell{1,1}(1)+timebfore*framespertimebin),1);
            runstoptoplot_out2in{1, 1}(((timebefore*framespertimebin)-crossing_in_before(1)+2):end) =...
                velocity_classified(1:(crossing_out_cell{1}(1))-1);

            %save which frames I used to get the velocity
            crossing_o2i_frames{1,1} = 1:(crossing_out_cell{1}(1))-1;
            
            %radial velocity calculation
            radvel_out2in{1,1} = nan((crossing_out_cell{1,1}(1)-crossing_in_cell{1,1}(1)+timebefore*framespertimebin),1);
            %then add the values
            radvel_out2in{1,1}(((timebefore*framespertimebin)-crossing_in_before(1)+2):end) =...
                rad_vel_sqrt(1:(crossing_out_cell{1}(1))-1);
            
        else %if there is longer than 10 sec before the first crossing in
            velocitytoplot_out2in{1,1} =...
                vel_total((crossing_in_cell{1}(1))-(timebefore*framespertimebin):(crossing_out_cell{1}(1))-1);
            
            radvel_out2in{1,1} =...
                rad_vel_sqrt((crossing_in_cell{1}(1))-(timebefore*framespertimebin):(crossing_out_cell{1}(1))-1);
             runstoptoplot_out2in{1,1} =...
                velocity_classified((crossing_in_cell{1}(1))-(timebefore*framespertimebin):(crossing_out_cell{1}(1))-1);

            %save which frames I used to get the velocity
            crossing_o2i_frames{1,1} = (crossing_in_cell{1}(1))-(timebefore*framespertimebin):(crossing_out_cell{1}(1))-1;

        end
    end
    %for the first crossing in other periods
    if period > 1
        if isempty(crossing_out_cell{period-1}) == 0 %if there was any crossing in 'before'
            if (crossing_in_cell{period}(1)-(timebefore*framespertimebin)) < (crossing_out_cell{period-1}(end)); %if timebefore seconds before the crossing in is before the last crossing out
                maxrow = max(diff(crossing_in_cell{period}));
                velocitytoplot_out2in{period, 1} = nan(maxrow+(timebefore*framespertimebin),1);
                               runstoptoplot_out2in{period, 1} = nan(maxrow+(timebefore*framespertimebin),1);

                nannumber = timebefore*framespertimebin- (crossing_in_cell{period}(1)-(crossing_out_cell{period-1}(end)));%how many nans will it take to make this vector the same length?
                sizetoplot = length((vel_total((crossing_out_cell{period-1}(end)+1):((crossing_out_cell{period}(1))))));
                velocitytoplot_out2in{period, 1}(nannumber+1:nannumber+sizetoplot)...
                    = vel_total((crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1); %just take the portion that is outside
                                              runstoptoplot_out2in{period, 1}(nannumber+1:nannumber+sizetoplot)...
                    = velocity_classified((crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1); %just take the portion that is outside

                %radial velocity calculation
                radvel_out2in{period, 1} = nan(maxrow+(timebefore*framespertimebin),1);
                radvel_out2in{period, 1}(nannumber+1:nannumber+sizetoplot)...
                    = rad_vel_sqrt((crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1); %just take the portion that is outside
                
                %save which frames I used to get the velocity
                crossing_o2i_frames{period,1} = (crossing_out_cell{period-1}(end)):crossing_out_cell{period}(1)-1;

            else
                velocitytoplot_out2in{period, 1} =...
                    vel_total((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));
                %radial velocity calculation
                radvel_out2in{period, 1} =...
                    rad_vel_sqrt((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));
                                runstoptoplot_out2in{period, 1} =...
                    velocity_classified((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));

                %save which frames I used to get the velocity
                crossing_o2i_frames{period,1} = (crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1);
                runstoptoplot_out2in{period, 1} =...
                    velocity_classified((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));

 
            end
        else %if there was no crossins in 'before'
            velocitytoplot_out2in{period, 1} =...
                vel_total((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));
            
            %rad vel
            radvel_out2in{period, 1} =...
                rad_vel_sqrt((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));
            
            %save which frames I used to get the velocity
            crossing_o2i_frames{period,1} = (crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1);
            runstoptoplot_out2in{period, 1} =...
                velocity_classified((crossing_in_cell{period}(1))-(timebefore*framespertimebin):(crossing_out_cell{period}(1)-1));

        end
    end
    
    %for second crossing and afterwards
    for h = 2:length(crossing_in_cell{period});
        
        if crossing_in_cell{period}(h)-(timebefore*framespertimebin) < crossing_out_cell{period}(h-1); %if 2 seconds before the crossing in is before the last crossing out
            maxrow = max(diff(crossing_in_cell{period}));
            velocitytoplot_out2in{period, h} = nan(maxrow+(timebefore*framespertimebin),1);
            nannumber = timebefore*framespertimebin- (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h-1)));%how many nans will it take to make this vector the same length?
            sizetoplot = (crossing_out_cell{period}(h))-(crossing_out_cell{period}(h-1)+1);
            velocitytoplot_out2in{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = vel_total((crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1)); %just take the portion that is outside
            %rad vel calculation
                       runstoptoplot_out2in{period, h} = nan(maxrow+(timebefore*framespertimebin),1);
            runstoptoplot_out2in{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = velocity_classified((crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1)); %just take the portion that is outside

            radvel_out2in{period, h} = nan(maxrow+(timebefore*framespertimebin),1);
            
            radvel_out2in{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = rad_vel_sqrt((crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1)); %just take the portion that is outside
           
            %save which frames I used to get the velocity
            crossing_o2i_frames{period,h} = (crossing_out_cell{period}(h-1)):(crossing_out_cell{period}(h)-1);

        else
            velocitytoplot_out2in{period, h} =...
                vel_total((crossing_in_cell{period}(h))-(timebefore*framespertimebin):(crossing_out_cell{period}(h)-1));
            %rad vel calculation
            radvel_out2in{period, h} =...
                rad_vel_sqrt((crossing_in_cell{period}(h))-(timebefore*framespertimebin):(crossing_out_cell{period}(h)-1));
            
            %save which frames I used to get the velocity
            crossing_o2i_frames{period,h} = (crossing_in_cell{period}(h))-(timebefore*framespertimebin):(crossing_out_cell{period}(h)-1);
                       runstoptoplot_out2in{period, h} =...
                velocity_classified((crossing_in_cell{period}(h))-(timebefore*framespertimebin):(crossing_out_cell{period}(h)-1));

        end
    end
    
    
    %for in2out events====================================================
    
    for h = 1:length(crossing_in_cell{period})-1;
        if crossing_out_cell{period}(h)-(timebefore*framespertimebin) < crossing_in_cell{period}(h); %if timebefore seconds before the crossing out is before the last crossing in
            maxrow = max(diff(crossing_out_cell{period}));
            velocitytoplot_in2out{period, h} = nan(maxrow+(timebefore*framespertimebin),1);
                        runstoptoplot_in2out{period, h} = nan(maxrow+(timebefore*framespertimebin),1);

            nannumber = timebefore*framespertimebin- (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)));%how many nans will it take to make this vector the same length?
            sizetoplot = (crossing_in_cell{period}(h+1))-(crossing_in_cell{period}(h)+1);
            velocitytoplot_in2out{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = vel_total((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside
            %rad vel calculation
            radvel_in2out{period, h} = nan(maxrow+(timebefore*framespertimebin),1);
            radvel_in2out{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = rad_vel_sqrt((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside
            %save which frames I used to get the velocity
            crossing_i2o_frames{period,h} = (crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1);
            runstoptoplot_in2out{period, h}(nannumber+1:nannumber+sizetoplot+1)...
                = velocity_classified((crossing_in_cell{period}(h)):(crossing_in_cell{period}(h+1)-1)); %just take the portion that is outside

        else
            velocitytoplot_in2out{period, h} =...
                vel_total((crossing_out_cell{period}(h))-(timebefore*framespertimebin):((crossing_in_cell{period}(h+1)-1)));
            %rad vel calculation
            radvel_in2out{period, h} =...
                (rad_vel_sqrt((crossing_out_cell{period}(h))-(timebefore*framespertimebin):((crossing_in_cell{period}(h+1)-1))));
            %save which frames I used to get the velocity
            crossing_i2o_frames{period,h} = (crossing_out_cell{period}(h))-(timebefore*framespertimebin):((crossing_in_cell{period}(h+1)-1));
            
                        runstoptoplot_in2out{period, h} =...
                (velocity_classified((crossing_out_cell{period}(h))-(timebefore*framespertimebin):((crossing_in_cell{period}(h+1)-1))));

        end
    end
    
    if notreal_out(period) == 0 %do the following only when last crossing_out is real crossing
        %for the last in2out crossing
        if crossing_out_cell{period}(end)-(timebefore*framespertimebin) < crossing_in_cell{period}(end); %there is less than timebefore sec before last crossing out and period end
            maxrow = max(diff(crossing_out_cell{period}));
            velocitytoplot_in2out{period, end+1} = nan(maxrow+(timebefore*framespertimebin),1);
                     runstoptoplot_in2out{period, end+1} = nan(maxrow+(timebefore*framespertimebin),1);

            nannumber = timebefore*framespertimebin- (crossing_out_cell{period}(end)-crossing_in_cell{period}(end));%how many nans will it take to make this vector the same length?
            sizetoplot = (timeperiods(period+1) - crossing_in_cell{period}(end));
          
            velocitytoplot_in2out{period, end}(nannumber+1:nannumber+sizetoplot+1)...
                = vel_total((crossing_in_cell{period}(end)):timeperiods(period+1)); %just take the portion that is outside
            %rad vel calculation
            radvel_in2out{period, end+1} = nan(maxrow+(timebefore*framespertimebin),1);
            radvel_in2out{period, end}(nannumber+1:nannumber+sizetoplot+1)...
                = rad_vel_sqrt((crossing_in_cell{period}(end)):timeperiods(period+1)); %just take the portion that is outside
            %save which frames I used to get the velocity
            crossing_i2o_frames{period,end+1}=(crossing_in_cell{period}(end)):timeperiods(period+1);
            runstoptoplot_in2out{period, end}(nannumber+1:nannumber+sizetoplot+1)...
                = velocity_classified((crossing_in_cell{period}(end)):timeperiods(period+1)); %just take the portion that is outside

        else
            velocitytoplot_in2out{period, end+1} =...
                (vel_total((crossing_out_cell{period}(end))-(timebefore*framespertimebin):timeperiods(period+1)));
            %rad vel calculation
            radvel_in2out{period, end+1} =...
                (rad_vel_sqrt((crossing_out_cell{period}(end))-(timebefore*framespertimebin):timeperiods(period+1)));
            %save which frames I used to get the velocity
            crossing_i2o_frames{period,end+1}=(crossing_out_cell{period}(end))-(timebefore*framespertimebin):timeperiods(period+1);
            runstoptoplot_in2out{period, end+1} =(velocity_classified(((crossing_out_cell{period}(end))-(timebefore*framespertimebin)):timeperiods(period+1)-1));

        end
    end
end
%%
%deleting the empty elements in the cell array
for i=1:3
    new_array = {crossing_i2o_frames{i,:}};
    new_array2 = new_array(~cellfun('isempty',new_array));
    if i==1
    crossing_i2o_frames_bf = new_array2;
    elseif i==2
        crossing_i2o_frames_dr = new_array2;
    else
        crossing_i2o_frames_af = new_array2;
    end
    
    new_array = {crossing_o2i_frames{i,:}};
    new_array2 = new_array(~cellfun('isempty',new_array));
    if i==1
        crossing_o2i_frames_bf = new_array2;
    elseif i==2
        crossing_o2i_frames_dr = new_array2;
    else
        crossing_o2i_frames_af = new_array2;
    end

end

%% clean up velocitytoplot, get rid of empty cells
%before
velocitytoplot_in2out_before = velocitytoplot_in2out(1,:);
vel_i2o_before = velocitytoplot_in2out_before(~cellfun('isempty',velocitytoplot_in2out_before));

velocitytoplot_out2in_before = velocitytoplot_out2in(1,:);
vel_o2i_before = velocitytoplot_out2in_before(~cellfun('isempty',velocitytoplot_out2in_before));

runstoptoplot_in2out_before = runstoptoplot_in2out(1,:);
run_i2o_before = runstoptoplot_in2out_before(~cellfun('isempty',runstoptoplot_in2out_before));

runstoptoplot_out2in_before = runstoptoplot_out2in(1,:);
run_o2i_before = runstoptoplot_out2in_before(~cellfun('isempty',runstoptoplot_out2in_before));

%during
velocitytoplot_in2out_during = velocitytoplot_in2out(2,:);
vel_i2o_during = velocitytoplot_in2out_during(~cellfun('isempty',velocitytoplot_in2out_during));

velocitytoplot_out2in_during = velocitytoplot_out2in(2,:);
vel_o2i_during = velocitytoplot_out2in_during(~cellfun('isempty',velocitytoplot_out2in_during));
runstoptoplot_in2out_during = runstoptoplot_in2out(2,:);
run_i2o_during = runstoptoplot_in2out_during(~cellfun('isempty',runstoptoplot_in2out_during));

runstoptoplot_out2in_during = runstoptoplot_out2in(2,:);
run_o2i_during = runstoptoplot_out2in_during(~cellfun('isempty',runstoptoplot_out2in_during));

%after
velocitytoplot_in2out_after = velocitytoplot_in2out(3,:);
vel_i2o_after = velocitytoplot_in2out_after(~cellfun('isempty',velocitytoplot_in2out_after));

velocitytoplot_out2in_after = velocitytoplot_out2in(3,:);
vel_o2i_after = velocitytoplot_out2in_after(~cellfun('isempty',velocitytoplot_out2in_after));

runstoptoplot_in2out_after = runstoptoplot_in2out(3,:);
run_i2o_after = runstoptoplot_in2out_after(~cellfun('isempty',runstoptoplot_in2out_after));

runstoptoplot_out2in_after = runstoptoplot_out2in(3,:);
run_o2i_after = runstoptoplot_out2in_after(~cellfun('isempty',runstoptoplot_out2in_after));


%copying everything to matrix (timebefore sec before crossing + timebefore sec after
%crossing)
if periodNo_1 == 2 %no crossing in the before period
    velocity_in2out_before = nan(totaltime*framespertimebin,1);
        runstop_in2out_before = nan(totaltime*framespertimebin,1);

else
    nb = length(vel_i2o_before);
    velocity_in2out_before = nan(totaltime*framespertimebin,nb);
        runstop_in2out_before = nan(totaltime*framespertimebin,nb);

    for n=1:nb
        if length(vel_i2o_before{1,n}) >= totaltime*framespertimebin
            velocity_in2out_before(1:totaltime*framespertimebin,n) = vel_i2o_before{1,n}(1:totaltime*framespertimebin,:);
                    runstop_in2out_before(1:totaltime*framespertimebin,n) = run_i2o_before{1,n}(1:totaltime*framespertimebin,:);

        else
            velocity_in2out_before(1:length(vel_i2o_before{1,n}),n) = vel_i2o_before{1,n};
                   runstop_in2out_before(1:length(run_i2o_before{1,n}),n) =run_i2o_before{1,n};

        end
    end
end
vel_i2o_avg(:,1) = nanmean(velocity_in2out_before,2);

nd = length(vel_i2o_during);
velocity_in2out_during = nan(totaltime*framespertimebin,nd);
runstop_in2out_during = nan(totaltime*framespertimebin,nd);

for n=1:nd
    if length(vel_i2o_during{1,n}) >= totaltime*framespertimebin
        velocity_in2out_during(1:totaltime*framespertimebin,n) = vel_i2o_during{1,n}(1:totaltime*framespertimebin,:);
            runstop_in2out_during(1:totaltime*framespertimebin,n) = run_i2o_during{1,n}(1:totaltime*framespertimebin,:);

    else
        velocity_in2out_during(1:length(vel_i2o_during{1,n}),n) = vel_i2o_during{1,n};
            runstop_in2out_during(1:length(run_i2o_during{1,n}),n) = run_i2o_during{1,n};

    end
end
vel_i2o_avg(:,2) = nanmean(velocity_in2out_during,2);

if periodNo_2 == 2 %if there is no crossing in 'after' period
    velocity_in2out_after = nan(totaltime*framespertimebin,1);
    runstop_in2out_after = nan(totaltime*framespertimebin,1);

else
    na = length(vel_i2o_after);
    velocity_in2out_after = nan(totaltime*framespertimebin,na);
        runstop_in2out_after = nan(totaltime*framespertimebin,na);

    for n=1:na
        if length(vel_i2o_after{1,n}) >= totaltime*framespertimebin
            velocity_in2out_after(1:totaltime*framespertimebin,n) = vel_i2o_after{1,n}(1:totaltime*framespertimebin,:);
                    runstop_in2out_after(1:totaltime*framespertimebin,n) = run_i2o_after{1,n}(1:totaltime*framespertimebin,:);

        else
            velocity_in2out_after(1:length(vel_i2o_after{1,n}),n) = vel_i2o_after{1,n};
                    runstop_in2out_after(1:length(run_i2o_after{1,n}),n) = run_i2o_after{1,n};

        end
    end
end
vel_i2o_avg(:,3)= nanmean(velocity_in2out_after,2);

%Out2in
if periodNo_1 == 2 % no crossing in the before period
    velocity_out2in_before = nan(totaltime*framespertimebin,1);
    runstop_out2in_before = nan(totaltime*framespertimebin,1);
else
    nb = length(vel_o2i_before);
    velocity_out2in_before = nan(totaltime*framespertimebin,nb);
    runstop_out2in_before = nan(totaltime*framespertimebin,nb);
    for n=1:nb
        if length(vel_o2i_before{1,n}) >= totaltime*framespertimebin
            velocity_out2in_before(1:totaltime*framespertimebin,n) = vel_o2i_before{1,n}(1:totaltime*framespertimebin,:);
                  runstop_out2in_before(1:totaltime*framespertimebin,n) = run_o2i_before{1,n}(1:totaltime*framespertimebin,:);

        else
            velocity_out2in_before(1:length(vel_o2i_before{1,n}),n) = vel_o2i_before{1,n};
                   runstop_out2in_before(1:length(run_o2i_before{1,n}),n) = run_o2i_before{1,n};

        end
    end
end
vel_o2i_avg(:,1) = nanmean(velocity_out2in_before,2);

nd = length(vel_o2i_during);
velocity_out2in_during = nan(totaltime*framespertimebin,nd);
runstop_out2in_during = nan(totaltime*framespertimebin,nd);

for n=1:nd
    if length(vel_o2i_during{1,n}) >= totaltime*framespertimebin
        velocity_out2in_during(1:totaltime*framespertimebin,n) = vel_o2i_during{1,n}(1:totaltime*framespertimebin,:);
            runstop_out2in_during(1:totaltime*framespertimebin,n) = run_o2i_during{1,n}(1:totaltime*framespertimebin,:);

    else
        velocity_out2in_during(1:length(vel_o2i_during{1,n}),n) = vel_o2i_during{1,n};
        runstop_out2in_during(1:length(run_o2i_during{1,n}),n) = run_o2i_during{1,n};

    end
end
vel_o2i_avg(:,2) = nanmean(velocity_out2in_during,2);

if periodNo_2 == 2 %no crossing in the 'after' period
    velocity_out2in_after = nan(totaltime*framespertimebin,1);
        runstop_out2in_after = nan(totaltime*framespertimebin,1);

else
    na = length(vel_o2i_after);
    velocity_out2in_after = nan(totaltime*framespertimebin,na);
        runstop_out2in_after = nan(totaltime*framespertimebin,na);

    for n=1:na
        if length(vel_o2i_after{1,n}) >= totaltime*framespertimebin
            velocity_out2in_after(1:totaltime*framespertimebin,n) = vel_o2i_after{1,n}(1:totaltime*framespertimebin,:);
                    runstop_out2in_after(1:totaltime*framespertimebin,n) = run_o2i_after{1,n}(1:totaltime*framespertimebin,:);

        else
            velocity_out2in_after(1:length(vel_o2i_after{1,n}),n) = vel_o2i_after{1,n};
                   runstop_out2in_after(1:length(run_o2i_after{1,n}),n) = run_o2i_after{1,n};

        end
    end
end
vel_o2i_avg(:,3) = nanmean(velocity_out2in_after,2);

%%
%radial velocity array clean up and grouping
%deleting the empty elements in the cell array
%before
radvel_in2out_bf = radvel_in2out(1,:);
radvel_i2o_before = radvel_in2out_bf(~cellfun('isempty',radvel_in2out_bf));

radvel_out2in_bf = radvel_out2in(1,:);
radvel_o2i_before = radvel_out2in_bf(~cellfun('isempty',radvel_out2in_bf));

%during
radvel_in2out_dr = radvel_in2out(2,:);
radvel_i2o_during = radvel_in2out_dr(~cellfun('isempty',radvel_in2out_dr));

radvel_out2in_dr = radvel_out2in(2,:);
radvel_o2i_during = radvel_out2in_dr(~cellfun('isempty',radvel_out2in_dr));

%after
radvel_in2out_aft = radvel_in2out(3,:);
radvel_i2o_after = radvel_in2out_aft(~cellfun('isempty',radvel_in2out_aft));

radvel_out2in_aft = radvel_out2in(3,:);
radvel_o2i_after = radvel_out2in_aft(~cellfun('isempty',radvel_out2in_aft));


%copying everything to matrix (2 sec before crossing + 5 sec after
%crossing)
if periodNo_1 == 2 %no crossing in the before period
    radvel_in2out_before = nan(totaltime*framespertimebin,1);
else
    nb = length(radvel_i2o_before);
    radvel_in2out_before = nan(totaltime*framespertimebin,nb);
    for n=1:nb
        if length(radvel_i2o_before{1,n}) >= totaltime*framespertimebin
            radvel_in2out_before(1:totaltime*framespertimebin,n) = radvel_i2o_before{1,n}(1:totaltime*framespertimebin,:);
        else
            radvel_in2out_before(1:length(radvel_i2o_before{1,n}),n) = radvel_i2o_before{1,n};
        end
    end
end
radvel_i2o_avg(:,1) = nanmean(radvel_in2out_before,2);

nd = length(radvel_i2o_during);
radvel_in2out_during = nan(totaltime*framespertimebin,nd);
for n=1:nd
    if length(radvel_i2o_during{1,n}) >= totaltime*framespertimebin
        radvel_in2out_during(1:totaltime*framespertimebin,n) = radvel_i2o_during{1,n}(1:totaltime*framespertimebin,:);
    else
        radvel_in2out_during(1:length(radvel_i2o_during{1,n}),n) =radvel_i2o_during{1,n};
    end
end
radvel_i2o_avg(:,2) = nanmean(velocity_in2out_during,2);

if periodNo_2 == 2 %if there is no crossing in 'after' period
    radvel_in2out_after = nan(totaltime*framespertimebin,1);
else
    na = length(radvel_i2o_after);
    radvel_in2out_after = nan(totaltime*framespertimebin,na);
    for n=1:na
        if length(radvel_i2o_after{1,n}) >= totaltime*framespertimebin
            radvel_in2out_after(1:totaltime*framespertimebin,n) = radvel_i2o_after{1,n}(1:totaltime*framespertimebin,:);
        else
            radvel_in2out_after(1:length(radvel_i2o_after{1,n}),n) = radvel_i2o_after{1,n};
        end
    end
end
radvel_i2o_avg(:,3)= nanmean(radvel_in2out_after,2);

%Out2in
if periodNo_1 == 2 % no crossing in the before period
    radvel_out2in_before = nan(totaltime*framespertimebin,1);
else
    nb = length(radvel_o2i_before);
    radvel_out2in_before = nan(totaltime*framespertimebin,nb);
    for n=1:nb
        if length(vel_o2i_before{1,n}) >= totaltime*framespertimebin
            radvel_out2in_before(1:totaltime*framespertimebin,n) = radvel_o2i_before{1,n}(1:totaltime*framespertimebin,:);
        else
            radvel_out2in_before(1:length(radvel_o2i_before{1,n}),n) = radvel_o2i_before{1,n};
        end
    end
end
radvel_o2i_avg(:,1) = nanmean(radvel_out2in_before,2);

nd = length(radvel_o2i_during);
radvel_out2in_during = nan(totaltime*framespertimebin,nd);
for n=1:nd
    if length(radvel_o2i_during{1,n}) >= totaltime*framespertimebin
        radvel_out2in_during(1:totaltime*framespertimebin,n) = radvel_o2i_during{1,n}(1:totaltime*framespertimebin,:);
    else
        radvel_out2in_during(1:length(radvel_o2i_during{1,n}),n) = radvel_o2i_during{1,n};
    end
end
radvel_o2i_avg(:,2) = nanmean(radvel_out2in_during,2);

if periodNo_2 == 2 %no crossing in the 'after' period
    radvel_out2in_after = nan(totaltime*framespertimebin,1);
else
    na = length(vel_o2i_after);
    radvel_out2in_after = nan(totaltime*framespertimebin,na);
    for n=1:na
        if length(radvel_o2i_after{1,n}) >= totaltime*framespertimebin
            radvel_out2in_after(1:totaltime*framespertimebin,n) = radvel_o2i_after{1,n}(1:totaltime*framespertimebin,:);
        else
            radvel_out2in_after(1:length(radvel_o2i_after{1,n}),n) = radvel_o2i_after{1,n};
        end
    end
end

