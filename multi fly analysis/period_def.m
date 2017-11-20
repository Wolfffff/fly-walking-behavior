function [crossing,crossing_in,crossing_out,odoron_frame,odoroff_frame,timeperiods]=...
    period_def(fly_x,framespertimebin,secsperperiod,inside_rim,in_out_pts)


crossing = find(in_out_pts);%find the nonzeros: crossing points
crossing_in = find(in_out_pts>0); %1 means out to in
crossing_out = find(in_out_pts<0);%-1 means in to out

%set time periods: assumes that it takes 5 seconds for air to reach the
%chamber after the valve switches
timeperiods = [1 framespertimebin*secsperperiod+5*framespertimebin...
    2*(framespertimebin*secsperperiod)+5*framespertimebin length(fly_x)];

if (inside_rim(timeperiods(2)) == 1)%if fly is inside when odor turns on
    odoron_frame = timeperiods(2);
else
    crossings_afterOdor = crossing((crossing>=timeperiods(2) & crossing<timeperiods(3)));
    if isempty(crossings_afterOdor) == 1 %if fly did not go into the odor zone
        odoron_frame = timeperiods(2);
    else
        odoron_frame  =crossings_afterOdor(1);%first time fly entered the odor zone
    end
end
odoroff_frame = timeperiods(3);

% if ismember(crossing, odoron_frame) == 0;
%  crossing(end+1) = odoron_frame;
%  crossing = sort(crossing);
% else 
% end
