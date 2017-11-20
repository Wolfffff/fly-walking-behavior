function [run_in_entire,run_out_entire] =...
    run_in_out_divider(velocity_classified_binary, inside_rim,runstops,timeperiods,odoron_frame)
% %divide velocity data into in VS out and run VS stop (before, during)

%for testing function
% odoron_frame = odoron_frame(end);inside_rim=inside_rim(:,end);

odoroff_frame = timeperiods(3);
display(odoron_frame)

%get the start and end of each runs and stops
rs_trans = find(isnan(runstops) == 0);%run/stop transition frames

if velocity_classified_binary(1) == 1 %start from run
    run_start = rs_trans(2:2:end);run_start = [1;run_start];
    stop_start = rs_trans(1:2:end);
    
    run_end = stop_start -1;
    stop_end = run_start(2:end) -1;
    
else %if the first frame is stop
    run_start = rs_trans(1:2:end);
    stop_start = rs_trans(2:2:end);stop_start = [1;stop_start];
    
    run_end = stop_start(2:end) -1;
    stop_end = run_start -1;
    
end

%discard the last run or stop
if length(run_start) > length(run_end)
    run_start = run_start(1:end-1);
elseif length(stop_start) > length(stop_end)
    stop_start = stop_start(1:end-1)
end

run_st_end = horzcat(run_start,run_end);

%before VS during
run_start_bf = run_start((run_start < timeperiods(2)));
run_end_bf = run_st_end((run_start < timeperiods(2)),2);

if length(run_start_bf) > length(run_end_bf) %last run goes beyond 3 min
    run_start_bf = run_start_bf(1:end-1); %do not include the last run
end

run_start_dr = (intersect(run_start,[odoron_frame:timeperiods(3)]))';
run_end_dr = run_st_end(find(run_start >= odoron_frame & run_start < timeperiods(3)),2);

if length(run_start_dr) > length(run_end_dr) %last run goes beyond 6 min
    run_start_dr = run_start_dr(1:end-1); %do not include the last run
end


%now collect the inside_rim info for each run using run_start and run_end etc.
runs_bf_inside_rim = cell(length(run_start_bf),1);
for x = 1:length(run_start_bf)
    runs_bf_inside_rim(x) =  {inside_rim(run_start_bf(x):run_end_bf(x))};
end

runs_dr_inside_rim = cell(length(run_start_dr),1);
for x = 1:length(run_start_dr)
    runs_dr_inside_rim(x) =  {inside_rim(run_start_dr(x):run_end_dr(x))};
end

%check if the sum of inside_rim matches with the run length
%i.e. run is ~30 frames long and sum of inside_rim during that run is 30,
%that means the fly was entirely inside during that run
% if it is entirely out or entirely in, save the frame info.
runs_before_in = cell(1);
runs_before_out = cell(1);
runs_during_in = cell(1);
runs_during_out = cell(1);

y=1;z=1;
for x = 1:length(run_start_bf)
    if length(runs_bf_inside_rim{x}) == sum(runs_bf_inside_rim{x}) %entirely inside
        runs_before_in{y} = [run_start_bf(x):run_end_bf(x)];
        y=y+1;
    elseif sum(runs_bf_inside_rim{x}) == 0 %entirely out
        runs_before_out{z} = [run_start_bf(x):run_end_bf(x)];
        z=z+1;
    end
end

y=1;z=1;
for x = 1:length(run_start_dr)
    if length(runs_dr_inside_rim{x}) == sum(runs_dr_inside_rim{x}) %entirely inside
        runs_during_in{y} = [run_start_dr(x):run_end_dr(x)];
        y=y+1;
    elseif sum(runs_dr_inside_rim{x}) == 0 %entirely out
        runs_during_out{z} = [run_start_dr(x):run_end_dr(x)];
        z=z+1;
    end
end


%% now save the 'before' data in the first row, 'during' data in the second row
run_in_entire = {runs_before_in; runs_during_in};
run_out_entire = {runs_before_out; runs_during_out};

