function  [vel_by_radius_before,vel_by_radius_during,vel_by_radius_after,...
    std_vel_by_radius_before,std_vel_by_radius_during,std_vel_by_radius_after,...
    radvel_by_radius_before,radvel_by_radius_during,radvel_by_radius_after]...
    = rad_velocity_binned_for_stats(in_x,in_y, fly_x,fly_y,out_x,out_y,bin_number,...
    timeperiods,odoron_frame,odoroff_frame,vel_total,major_axo,framespertimebin,outer_rim)

%find the center and radius (in pixel) of inner rim
[ctr_x,ctr_y,circRad] = circfit(in_x,in_y);

%translate all the points so that the center is (0,0)
fly_x_tsl = fly_x - ctr_x;
fly_y_tsl = fly_y - ctr_y;
in_x_tsl = in_x - ctr_x;
in_y_tsl = in_y - ctr_y;
out_x_tsl = out_x - ctr_x;
out_y_tsl = out_y - ctr_y;


%how far is the fly from the center (in pixel)
radius_fly = sqrt(fly_x_tsl.^2 + fly_y_tsl.^2);
%bin it so that I can calculate the average etc of velocity
radius_binned = (radius_fly.*bin_number)/circRad;
radius_binned = ceil(radius_binned);

%get the radial diff of location x,y
rad_vel = diff(radius_fly);
rad_vel = [0;rad_vel];
%converting the unit of velocity to cm/sec
measured_axis = outer_rim; %diameter of outer circle in printed top registration template
rad_vel = rad_vel.*(measured_axis/(major_axo*2)*framespertimebin);

%get the absolute value (variable name doesn't make sense, but there are so many uses
%of this variable, so I will just keep it as it is now)
rad_vel_sqrt = abs(rad_vel);

%group vel_total by radius_binned
for i=1:max(radius_binned)
    %total 9 minutes
    vel_by_radius_total{i} = vel_total(find(radius_binned == i));
    
    %before
    vel_total_before = vel_total(1:timeperiods(2));
    radius_binned_before = radius_binned(1:timeperiods(2));
    vel_by_radius_before{i} = vel_total_before(find(radius_binned_before == i));
    %during
    vel_total_during = vel_total(odoron_frame:odoroff_frame);
    radius_binned_during = radius_binned(odoron_frame:odoroff_frame);
    vel_by_radius_during{i} = vel_total_during(find(radius_binned_during == i));
    %after
    vel_total_after = vel_total(odoroff_frame:end);
    radius_binned_after = radius_binned(odoroff_frame:end);
    vel_by_radius_after{i} = vel_total_after(find(radius_binned_after == i));
    
end

%get the mean
avg_vel_by_radius = cellfun(@mean,vel_by_radius_total);
avg_vel_by_radius_before = cellfun(@mean,vel_by_radius_before);
avg_vel_by_radius_during = cellfun(@mean,vel_by_radius_during);
avg_vel_by_radius_after = cellfun(@mean,vel_by_radius_after);

%get the standard deviation
std_vel_by_radius_before = cellfun(@std,vel_by_radius_before);
std_vel_by_radius_during = cellfun(@std,vel_by_radius_during);
std_vel_by_radius_after = cellfun(@std,vel_by_radius_after);


%get the median
avg_vel_by_radius_median = cellfun(@median,vel_by_radius_total);
avg_vel_by_radius_before_median = cellfun(@median,vel_by_radius_before);
avg_vel_by_radius_during_median = cellfun(@median,vel_by_radius_during);
avg_vel_by_radius_after_median = cellfun(@median,vel_by_radius_after);


%group rad_vel_sqrt by radius_binned
for i=1:max(radius_binned)
    %total 9 minutes
    radvel_by_radius_total{i} = rad_vel_sqrt(find(radius_binned == i));
    
    %before
    radvel_before = rad_vel_sqrt(1:timeperiods(2));
    radvel_by_radius_before{i} = radvel_before(find(radius_binned_before == i));
    
    %during
    radvel_during = rad_vel_sqrt(odoron_frame:odoroff_frame);
    radvel_by_radius_during{i} = radvel_during(find(radius_binned_during == i));
    %after
    radvel_after = rad_vel_sqrt(odoroff_frame:end);
    radvel_by_radius_after{i} = radvel_after(find(radius_binned_after == i));
    
end
%get the mean
avg_radvel_by_radius = cellfun(@mean,radvel_by_radius_total);
avg_radvel_by_radius_before = cellfun(@mean,radvel_by_radius_before);
avg_radvel_by_radius_during = cellfun(@mean,radvel_by_radius_during);
avg_radvel_by_radius_after = cellfun(@mean,radvel_by_radius_after);

%get the stadard deviation
std_radvel_by_radius_before = cellfun(@std,radvel_by_radius_before);
std_radvel_by_radius_during = cellfun(@std,radvel_by_radius_during);
std_radvel_by_radius_after = cellfun(@std,radvel_by_radius_after);

%get the median
avg_radvel_by_radius = cellfun(@median,radvel_by_radius_total);
avg_radvel_by_radius_before_median = cellfun(@median,radvel_by_radius_before);
avg_radvel_by_radius_during_median  = cellfun(@median,radvel_by_radius_during);
avg_radvel_by_radius_after_median  = cellfun(@median,radvel_by_radius_after);
