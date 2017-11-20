function [crossing_in_before, crossing_in_during, crossing_in_after,...
    crossing_out_before,crossing_out_during,crossing_out_after,crossing_before_No,crossing_during_No,crossing_after_No,...
    frames_in_before, frames_out_before,frames_in_during,frames_out_during,frames_in_after,frames_out_after, vel_in_before,...
    vel_out_before, vel_in_during, vel_out_during, vel_in_after, vel_out_after]=...
    crossingframes(crossing,crossing_in,crossing_out,odoron_frame,odoroff_frame,timeperiods,in_out_pts,fly_x, fly_y)

%calculate the number of transits (out2in & in2out)
crossing_in_before = crossing_in(crossing_in<odoron_frame);
crossing_out_before = crossing_out(crossing_out<odoron_frame);
crossing_before_No = length(crossing_in_before);%out2in

crossing_in_during = crossing_in(crossing_in >= odoron_frame & crossing_in < odoroff_frame);
crossing_out_during = crossing_out(crossing_out >= odoron_frame & crossing_out <odoroff_frame);
crossing_during_No = length(crossing_in_during);

crossing_in_after = crossing_in(crossing_in >= odoroff_frame);
crossing_out_after = crossing_out(crossing_out >= odoroff_frame);
crossing_after_No = length(crossing_in_after);

%%
%calculate the individual and average time spent in & out per transit
%before====================================================================
crossing_before = (crossing(crossing < timeperiods(2)));
%frame numbers between two crossings (real crossings only)
frames_bw_crossing_before = diff(crossing_before);

crossing_before(end+1) = timeperiods(2);
% crossing_before(end+1) = timeperiods(1);
crossing_before = sort(crossing_before);

frame_vel_before = cell(1, length(crossing_before)-1);
for n = 1:length(crossing_before)-1
    frame_vel_before{n}(:,1) = (fly_x(crossing_before(n):crossing_before(n+1))); %raw position values for the length of all crossings
    frame_vel_before{n}(:,2)= fly_y(crossing_before(n):crossing_before(n+1));
    
end
if crossing_before_No == 0 %if there was no crossing
    frames_in_before = nan;
    frames_out_before = nan;
    vel_in_before = nan;
    vel_out_before = nan;
else
    if in_out_pts(crossing(1)) == 1 %first crossing is going out2in
        %every odd number is frame# inside between crossing out2in and in2out
        frames_in_before = frames_bw_crossing_before (1:2:end);
        %every even number is frame# outside between crossings in2out and
        %out2in
        frames_out_before = frames_bw_crossing_before (2:2:end);
        vel_in_before = frame_vel_before(1:2:end); %raw position values for each crossing in
        vel_out_before = frame_vel_before(2:2:end);
    else %fly is going from inside to outside
        frames_in_before = frames_bw_crossing_before (2:2:end);
        frames_out_before = frames_bw_crossing_before (1:2:end);
        vel_in_before = frame_vel_before(2:2:end);
        vel_out_before = frame_vel_before(1:2:end);
    end
end


%during====================================================================
crossing_during =(crossing(crossing>=odoron_frame & crossing<=odoroff_frame));
%frame numbers between two crossings (real crossings only)
frames_bw_crossing_during = ...
    diff(crossing_during);

crossing_during(end+1) = timeperiods(3);

frame_vel_during = cell(1, length(crossing_during));
for n = 1:length(crossing_during)-1
    frame_vel_during{n}(:,1) = (fly_x(crossing_during(n):crossing_during(n+1)));
    frame_vel_during{n}(:,2)= fly_y(crossing_during(n):crossing_during(n+1));
end
if in_out_pts(crossing_during(1)) == 1 %fly is going from out2in
    frames_in_during = frames_bw_crossing_during (1:2:end);
    frames_out_during = frames_bw_crossing_during (2:2:end);
    vel_in_during = frame_vel_during(1:2:end);
    vel_out_during = frame_vel_during(2:2:end);
elseif in_out_pts(crossing_during(1))== -1 %fly is going from in2out
    frames_in_during = frames_bw_crossing_during (2:2:end);
    frames_out_during = frames_bw_crossing_during (1:2:end);
    vel_in_during = frame_vel_during(2:2:end);
    vel_out_during = frame_vel_during(1:2:end);
else %if it is not a real crossing (this happens when the fly is inside the odor zone at the beginning of 3 min+5 sec)
    frames_in_during = frames_bw_crossing_during (3:2:end);
    frames_out_during = frames_bw_crossing_during (2:2:end);
    vel_in_during = frame_vel_during(2:2:end);
    vel_out_during = frame_vel_during(1:2:end);
end


%after=====================================================================

crossing_after =(crossing(crossing>=odoroff_frame));
%frame numbers between two crossings (real crossings only)
frames_bw_crossing_after = diff(crossing_after);
if isempty(crossing_after) == 0 %if there is any crossing in 'after' period
first_cross =crossing_after(1);
end

crossing_after(end+1) = odoroff_frame;
crossing_after(end+1) = timeperiods(4);
crossing_after = sort(crossing_after);

frame_vel_after = cell(1, length(crossing_after));
for n = 1:length(crossing_after)-1
    frame_vel_after{n}(:,1) = (fly_x(crossing_after(n):crossing_after(n+1)));
    frame_vel_after{n}(:,2)= fly_y(crossing_after(n):crossing_after(n+1));
end


if isempty(crossing_in_after)== 0 %if array is not empty
    if in_out_pts(first_cross) == 1 %fly is going from out2in
        frames_in_after = frames_bw_crossing_after (1:2:end);
        frames_out_after = frames_bw_crossing_after (2:2:end);

        vel_in_after = frame_vel_after(1:2:end);
        vel_out_after = frame_vel_after(2:2:end);
    else %fly is going from in2out
        frames_in_after = frames_bw_crossing_after (2:2:end);
        frames_out_after = frames_bw_crossing_after(1:2:end);
        vel_in_after = nan;
        vel_out_after = nan;
    end
else %if fly did not enter 'after', then no frame #
    frames_in_after = nan;
    frames_out_after = nan;
    
end
%    keyboard