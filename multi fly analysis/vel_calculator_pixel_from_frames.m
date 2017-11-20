function [vel_total,velocity_fly_in, velocity_fly_out,avgvelocity_by_fly_in, avgvelocity_by_fly_out]=...
    vel_calculator_pixel(fly_x,fly_y,timeperiods,odoron_frame,odoroff_frame, inside_rim)
%calculate the average velocity

vel_x_total = diff(fly_x);
vel_y_total = diff(fly_y);
vel_total = sqrt(vel_x_total.^2+vel_y_total.^2);

%does not convert to cm/sec, use pixel/frame
vel_total=[0;vel_total];

%making nan arrays (first column: frame#, second column: corresponding
%velocity at that frame)
vel_before_in = nan(1,2);vel_before_out = nan(1,2);
vel_during_in = nan(1,2);vel_during_out = nan(1,2);
vel_after_in = nan(1,2);vel_after_out = nan(1,2);
%this way, if there is no entry, there will be no velocity data rather than
%'0' as a velocity, which could mean that a fly did not move.

%checking each velocity from the first frame and store the frame number and
%corresponding velocity in separate arrays. Since there is a frame number
%for each velocity, if we need, we can check if it was a continuous run or
%not.
k=1;l=1; m=1;n=1; o=1;p=1;
for i=1:timeperiods(4)
    if i < timeperiods(2) %before
        if inside_rim(i) == 1 %if fly is inside
            vel_before_in(k,1) = i;
            vel_before_in(k,2) = vel_total(i);
            k = k+1;
        else % if fly is outside
            vel_before_out(l,1) = i;
            vel_before_out(l,2) = vel_total(i);
            l=l+1;
        end
    elseif i >= odoron_frame & i < odoroff_frame %during
        if inside_rim(i) == 1 %if fly is inside
            vel_during_in(m,1) = i;
            vel_during_in(m,2) = vel_total(i);
            m = m+1;
        else % if fly is outside
            vel_during_out(n,1) = i;
            vel_during_out(n,2) = vel_total(i);
            n=n+1;
        end
    else %after
        if inside_rim(i) == 1 %if fly is inside
            vel_after_in(o,1) = i;
            vel_after_in(o,2) = vel_total(i);
            o = o+1;
        else % if fly is outside
            vel_after_out(p,1) = i;
            vel_after_out(p,2) = vel_total(i);
            p=p+1;
        end
    end
end
lengthcheck1 = [length(vel_before_in(:,2)), length(vel_during_in(:,2)), length(vel_after_in(:,2))];
preall = max(lengthcheck1);
velocity_fly_in = nan(preall, 3);

velocity_fly_in(1:length(vel_before_in(:,2)),1) = vel_before_in(:,2);
velocity_fly_in(1:length(vel_during_in(:,2)),2) = vel_during_in(:,2);
velocity_fly_in(1:length(vel_after_in(:,2)),3) = vel_after_in(:,2);

lengthcheck2 = [length(vel_before_out(:,2)), length(vel_during_out(:,2)), length(vel_after_out(:,2))];
preall = max(lengthcheck2);
velocity_fly_out= nan(preall, 3);

velocity_fly_out(1:length(vel_before_out(:,2)),1) = vel_before_out(:,2);
velocity_fly_out(1:length(vel_during_out(:,2)),2) = vel_during_out(:,2);
velocity_fly_out(1:length(vel_after_out(:,2)),3) = vel_after_out(:,2);


avgvelocity_by_fly_in(:,1) =  nanmean(vel_before_in(:,2));
avgvelocity_by_fly_in(:,2) =  nanmean(vel_during_in(:,2));
avgvelocity_by_fly_in(:,3) =  nanmean(vel_after_in(:,2));

avgvelocity_by_fly_out(:,1) =  nanmean(vel_before_out(:,2));
avgvelocity_by_fly_out(:,2) =  nanmean(vel_during_out(:,2));
avgvelocity_by_fly_out(:,3) =  nanmean(vel_after_out(:,2));