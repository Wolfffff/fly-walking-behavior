function [runs, stops] = run_stop_generator2(runstops, velocity_classified, timeperiods,odoron_frame)
%% Dividing Data into Runs and stops
% run_stop_generator1 uses 'timeperiods' and 'before' ends at 3 min

%velocity_parsed... divides the tracks into runs and stops.
%runs_before_odor.... isolates the runs
%stops_before_odor...isolates the stops
% avg_data_saver(vel_total, crossing_in_cell, crossing_out_cell, timeperiods, frames, nv)
% runstops_before_odor = [];
% runstops_during_odor = [];
% runstops_after_odor = [];

%get the frames of transition
runstops_before = ~isnan(runstops(1:(timeperiods(2)-1)));%1: transition, 0: continuous run or stop
runstops_before_odor = (find(runstops_before));%only get the transition points
%delete the first frame
if length(runstops_before_odor) > 1 %if fly stopped for more than once 
    if runstops_before_odor(2) - runstops_before_odor(1) == 1 % since the first frame's velocity is always 0, avoid adding this as a run
        runstops_before_odor(1) =[];
    end
end

runstops_during= ~isnan(runstops(odoron_frame:timeperiods(3)-1));
%to avoid making an empty cell in 'velocity_parsed_during_odor', get rid of odoron_frame
if runstops_during(1) == 1
    runstops_during(1) = 0;
end
runstops_during_odor = (find(runstops_during)+(odoron_frame-1));

runstops_after = ~isnan(runstops(timeperiods(3):length(velocity_classified)));
runstops_after_odor = (find(runstops_after)+(timeperiods(3)-1));

%for every run or stop, save the velocity during run or stop===============
%pre-allocate
velocity_parsed_before_odor = cell ((length(runstops_before_odor))+1,1);
velocity_parsed_during_odor = cell ((length(runstops_during_odor))+1,1);
velocity_parsed_after_odor = cell ((length(runstops_after_odor))+1,1);
%fixed by SJ(8/28/12)
if isempty(runstops_before_odor) == 0 %if there is at least one crossing
    for rr = 1:(length(velocity_parsed_before_odor));
        if rr==1; %first transition
            velocity_parsed_before_odor(rr)= {velocity_classified(2:(runstops_before_odor(rr)-1))}; %exclude the first frame, vel is always 0
            %take the first point of the transition through to the point before the next transition
            
        elseif rr == length(velocity_parsed_before_odor)%last transition
            velocity_parsed_before_odor(rr)={velocity_classified(runstops_before_odor(rr-1):(timeperiods(2)-1))};
            
        else %in between
            velocity_parsed_before_odor(rr)= {velocity_classified(runstops_before_odor(rr-1):(runstops_before_odor(rr)-1))};
        end
    end
end
%during
if isempty(runstops_during_odor) == 0 %if there is at least one crossing
    for rr = 1:(length(velocity_parsed_during_odor));
        if rr==1;
            velocity_parsed_during_odor(rr)= {velocity_classified((odoron_frame):(runstops_during_odor(rr)-1))};
            %take the first point of the transition through to the point before the next transition
            
        elseif rr == (length(velocity_parsed_during_odor));
            velocity_parsed_during_odor(rr) = {velocity_classified(runstops_during_odor(rr-1):(timeperiods(3)-1))};
        else
            velocity_parsed_during_odor(rr)= {velocity_classified(runstops_during_odor(rr-1):(runstops_during_odor(rr)-1))};
        end
    end
end
%after
if isempty(runstops_after_odor) == 0 %if there is at least one crossing
    for rr = 1:length(velocity_parsed_after_odor);
        if rr==1;
            velocity_parsed_after_odor(rr)= {velocity_classified(timeperiods(3):(runstops_after_odor(rr)-1))}; %take the first point of the transition through to the point before the next transition
        elseif rr == (length(velocity_parsed_after_odor));
            velocity_parsed_after_odor(rr)={velocity_classified(runstops_after_odor(rr-1):end)};
        else
            velocity_parsed_after_odor(rr)= {velocity_classified(runstops_after_odor(rr-1):(runstops_after_odor(rr)-1))};
        end
    end
end
%===========================================================================

%before
sums = 1:length(velocity_parsed_before_odor);
for rr = 1:length(velocity_parsed_before_odor);
    sums(rr) = cellfun(@sum,velocity_parsed_before_odor(rr)) ;%add up all the velocity data (if all 0 (stop), then sum is 0)
end

%RUN
runind = find(sums);%save the index for run
runs_before_odor = cell(length(runind),1); %finding the indices of the run cells
for j = 1:length(runind);
    m = runind(j);
    runs_before_odor{j} = velocity_parsed_before_odor{m}; %separating out the run cells
end

%in case the fly never stopped
if isempty(runs_before_odor) == 1 
    runs_before_odor{1} = velocity_classified(1:timeperiods(2));
end

%Stop
stopind = find(sums ==0);
stops_before_odor = cell(length(stopind),1); %finding the indices of the stop cells
for j = 1:length(stopind);
    m = stopind(j);
    stops_before_odor{j} = velocity_parsed_before_odor{m}; %separating out the stop cells
end

%DURING
sums = 1:length(velocity_parsed_during_odor);
for rr = 1:length(velocity_parsed_during_odor);
    sums(rr) = cellfun(@sum,velocity_parsed_during_odor(rr)) ;
end

%RUN
runind = find(sums);
runs_during_odor = cell(length(runind),1); %finding the indices of the run cells
for j = 1:length(runind);
    m = runind(j);
    runs_during_odor{j} = velocity_parsed_during_odor{m}; %separating out the run cells
end

%in case the fly never stopped
if isempty(runs_during_odor) == 1 
    runs_during_odor{1} = velocity_classified(odoron_frame:timeperiods(3));
end

%Stop
stopind = find(sums ==0);
stops_during_odor = cell(length(stopind),1); %finding the indices of the stop cells
for j = 1:length(stopind);
    m = stopind(j);
    stops_during_odor{j} = velocity_parsed_during_odor{m}; %separating out the stop cells
end

%AFTER
sums = 1:length(velocity_parsed_after_odor);
for rr = 1:length(velocity_parsed_after_odor);
    sums(rr) = cellfun(@sum,velocity_parsed_after_odor(rr)) ;
end

% ind = 1:length(runstops_after_odor);
%Run
runind = find(sums);
runs_after_odor = cell(length(runind),1); %finding the indices of the run cells

for j = 1:length(runind);
    m = runind(j);
    runs_after_odor{j} = velocity_parsed_after_odor{m}; %separating out the run cells
end

%in case the fly never stopped
if isempty(runs_after_odor) == 1 
    runs_after_odor{1} = velocity_classified(timeperiods(3):end);
end

%Stop
stopind = find(sums ==0);
stops_after_odor = cell(length(stopind),1); %finding the indices of the stop cells
for j = 1:length(stopind);
    m = stopind(j);
    stops_after_odor{j} = velocity_parsed_after_odor{m}; %separating out the stop cells
end

%These arrays contain all the run velocity and stop velocity (all 0, but
%length information)
runs = {runs_before_odor runs_during_odor runs_after_odor};
stops = {stops_before_odor stops_during_odor stops_after_odor};
