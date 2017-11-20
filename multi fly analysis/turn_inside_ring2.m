function [fly_in_ring,fly_in_ring_bf,fly_in_ring_dr,fly_in_ring_af,...
    turn_in_ring,turn_in_ring_bf,turn_in_ring_dr,turn_in_ring_af,...
    turn_fr_ring_total,turn_fr_ring,...
    curv_in_ring,curv_in_ring_bf,curv_in_ring_dr,curv_in_ring_af,...
    curv_fr_ring_total,curv_fr_ring,...
    ring_outer_x,ring_outer_y,ring_inner_x,ring_inner_y] =...
    turn_inside_ring2(ring_outer,ring_inner,in_x,in_y,inner_radius,fly_x,fly_y,...
    radius_fly_cm,timeperiods,odoron_frame,odoroff_frame,velocity_classified,...
    curv_long_mat,frame_turn_sh,framespertimebin)

% to check the function
% odoron_frame = odoron_frame(i);
% ring_outer = ring_outer_radius;
% ring_inner = ring_inner_radius;


%This function calculates the turn rate (turn#/sec) and curved walk
%fraction (curved walk/ all walk (excluding stops)) for the frames where
%the fly is inside the specified ring (pre-set with ring_inner_radius and
%ring_outer_radius by a user)

%error checking
if ring_outer <= ring_inner
    display('ring_outer_radius has to be bigger than ring_inner_radius');
end

%get xy coordinates for ring_outer and ring_inner
%use circle fit tfly find the center and radius
[ctr_x,ctr_y,~] = circfit(in_x,in_y);

%translate x and y points so that the center is (0,0)
in_x_tsl = in_x - ctr_x;
in_y_tsl = in_y - ctr_y;

%now increase the IR and find new and bigger ring_outer points
ring_outer_x = in_x_tsl.*ring_outer/inner_radius;
ring_outer_y = in_y_tsl.*ring_outer/inner_radius;

%translate the points back
ring_outer_x = ring_outer_x + ctr_x;
ring_outer_y = ring_outer_y + ctr_y;

%now increase the IR and find new and bigger ring_inner points
ring_inner_x = in_x_tsl.*ring_inner/inner_radius;
ring_inner_y = in_y_tsl.*ring_inner/inner_radius;

%translate the points back
ring_inner_x = ring_inner_x + ctr_x;
ring_inner_y = ring_inner_y + ctr_y;


%pre-allocate the arrays
%fly_in_ring: saves the frame# and fly's distance from the center at that
%frame (bf/dr/af variables only save the frame#)
%turn_in_ring: saves the frame# for sharp turns that belong to'fly_in_ring'
%curv_in_ring: saves the frame# for curved walks that belong to'fly_in_ring'

fly_in_ring = nan(length(fly_x),2);%make the array biggest possible
fly_in_ring_bf=nan(1); fly_in_ring_dr=nan(1); fly_in_ring_af=nan(1);
fly_in_ring_run_bf = nan(1);fly_in_ring_run_dr = nan(1); fly_in_ring_run_af = nan(1);

m=1;n=1;o=1;q=1;r=1;s=1;t=1;u=1;
for p=1:length(fly_x)
    if inpolygon(fly_x(p),fly_y(p),ring_inner_x,ring_inner_y) == 0 %if the fly is outside the ring_inner
        if inpolygon(fly_x(p),fly_y(p),ring_outer_x,ring_outer_y) == 1 % and inside the ring_outer
            fly_in_ring(m,1) = p; %save frame # where fly is in the ring
            fly_in_ring(m,2) = radius_fly_cm(p);
            m=m+1;
            if velocity_classified(p) ~= 0 %fly was not stopping at this frame
                fly_in_ring_run(r) = p;
                r = r+1;
            end
            
            
            %dividing into three periods
            if p < timeperiods(2) %before
                fly_in_ring_bf(n) = p;
                n=n+1;
                if velocity_classified(p) ~= 0 %'run'
                    fly_in_ring_run_bf(s) = p;
                    s=s+1;
                end
            elseif (odoron_frame <= p) && (p < odoroff_frame)
                fly_in_ring_dr(o) = p;
                o=o+1;
                if velocity_classified(p) ~= 0
                    fly_in_ring_run_dr(t) = p;
                    t=t+1;
                end
            elseif timeperiods(3) <= p
                fly_in_ring_af(q) = p;
                q=q+1;
                if velocity_classified(p) ~= 0;
                    fly_in_ring_run_af(u) = p;
                    u = u+1;
                end
            end
            
        end
    end
end

%get rid of nans
rows_nan=(find(isnan(fly_in_ring) ==1));
fly_in_ring(rows_nan(1:(length(rows_nan)/2)),:) = [];


%which sharp turns were inside the ring?
turn_in_ring = intersect(fly_in_ring(:,1),frame_turn_sh);
if isempty(turn_in_ring) ==1 %if there is no turn inside etc...
    if isempty(fly_in_ring) == 1 %if fly is not inside the ring
        turn_in_ring = [nan];
    else
        turn_in_ring = [0]; %if fly is in the ring but there is no sharp turns
    end
end
%which curved walks were inside the ring?
curv_in_ring = intersect(fly_in_ring(:,1),curv_long_mat);
if isempty(curv_in_ring) ==1 %if there is no turn inside etc...
    if isempty(fly_in_ring) == 1 %if fly is not inside the ring
        curv_in_ring = [nan];
    else
        curv_in_ring = [0];
    end
end


%divide those into periods/ in & out=======================================

turn_in_ring_bf = nan(1); turn_in_ring_dr=nan(1); turn_in_ring_af=nan(1);
curv_in_ring_bf = nan(1); curv_in_ring_dr=nan(1); curv_in_ring_af=nan(1);
turn_fr_ring_total = nan(1);
turn_fr_ring = nan(3,1);
curv_fr_ring_total = nan(1);
curv_fr_ring = nan(3,1);

if isempty(fly_in_ring) == 0 %if a fly did go in to the specified ring
    if isnan(turn_in_ring) == 0 % if there is at least one turn
        %now, divide turns into periods, in VS out
        n=1; m=1; l=1;
        AA = turn_in_ring;
        for p=1:length(AA)
            if AA(p) < timeperiods(2) %before
                turn_in_ring_bf(n) = AA(p);
                n=n+1;
            elseif odoron_frame <= AA(p) && AA(p) < odoroff_frame
                turn_in_ring_dr(m) = AA(p);
                m=m+1;
            elseif odoroff_frame <= AA(p)
                turn_in_ring_af(l) = AA(p);
                l = l+1;
            end
        end
        
        
        % calculate the frequency of sharp turns inside the ring / period===============
        % the unit is time^-1
        turn_fr_ring_total = length(turn_in_ring)/(length(fly_in_ring_run)/framespertimebin);
        if sum(isnan(turn_in_ring_bf)) == 0 %if there is turns inside the ring
        turn_fr_ring(1) = length(turn_in_ring_bf)/(length(fly_in_ring_run_bf)/framespertimebin);
        else %if there was no turn inside the ring
            if sum(isnan(fly_in_ring_run_bf)) == 0 %if fly was inside the ring
                turn_fr_ring(1) = 0; %then turn rate is zero, not nan
            end
        end
        
        if sum(isnan(turn_in_ring_dr)) == 0 
        turn_fr_ring(2) = length(turn_in_ring_dr)/(length(fly_in_ring_run_dr)/framespertimebin);
        else 
            if sum(isnan(fly_in_ring_run_dr)) == 0
                turn_fr_ring(2) = 0;
            end
        end
        
        if sum(isnan(turn_in_ring_af)) == 0 
        turn_fr_ring(3) = length(turn_in_ring_af)/(length(fly_in_ring_run_af)/framespertimebin);
        else
            if sum(isnan(fly_in_ring_run_af)) ==0
                turn_fr_ring(3) = 0;
            end
        end
        
        %==========================================================================
        %now calculate the fraction of curved walk
        if isnan(curv_in_ring) == 0
            n=1; m=1; l=1;
            AA = curv_in_ring;
            for p=1:length(AA)
                if AA(p) < timeperiods(2) %before
                    curv_in_ring_bf(n) = AA(p);
                    n=n+1;
                elseif odoron_frame <= AA(p) && AA(p) < odoroff_frame
                    curv_in_ring_dr(m) = AA(p);
                    m=m+1;
                elseif odoroff_frame <= AA(p)
                    curv_in_ring_af(l) = AA(p);
                    l = l+1;
                end
            end
            
            % calculate the fraction of turning inside the ring / period===============
            curv_fr_ring_total = length(curv_in_ring)/length(fly_in_ring_run);
            if sum(isnan(curv_in_ring_bf)) == 0 
            curv_fr_ring(1) = length(curv_in_ring_bf)/length(fly_in_ring_run_bf);
            else
                if  sum(isnan(fly_in_ring_run_bf)) == 0
                    curv_fr_ring(1) = 0;
                end
            end
            
            if sum(isnan(curv_in_ring_dr)) == 0  
            curv_fr_ring(2) = length(curv_in_ring_dr)/length(fly_in_ring_run_dr);
            else
                if sum(isnan(fly_in_ring_run_dr)) == 0
                    curv_fr_ring(2) = 0;
                end
            end
            
            if sum(isnan(curv_in_ring_af)) == 0 
            curv_fr_ring(3) = length(curv_in_ring_af)/length(fly_in_ring_run_af);
            else
                if sum(isnan(fly_in_ring_run_af)) == 0
                    curv_fr_ring(3) = 0;
                end
            end
        end
        
    end
    
end
