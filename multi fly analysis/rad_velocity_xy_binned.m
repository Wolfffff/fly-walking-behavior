function  [radius_fly,rad_vel,circRad,radius_binned,rad_vel_sqrt,avg_vel_by_radius_before,...
    avg_vel_by_radius_during,avg_vel_by_radius_after,...
    avg_radvel_by_radius_before,avg_radvel_by_radius_during,avg_radvel_by_radius_after...
    radvel_binned_before,radvel_binned_during,radvel_binned_after,...
    radvel_bincount_before,radvel_bincount_during,radvel_bincount_after]...
    = rad_velocity_xy_binned(in_x,in_y, fly_x,fly_y,out_x,out_y,bin_number,timeperiods,odoron_frame,odoroff_frame,vel_total)

%This function calculates fly's radial distance from the center of inner
%rim, radial velocity (rad_vel), rad_vel_sqrt(absolute value or modulus).
%Then, it bins the vel_total and rad_vel by radius to get the distribution
%data/radius

%find the center of inner rim
[ctr_x,ctr_y,circRad] = circfit(in_x,in_y);

%translate all the points so that the center is (0,0)
fly_x_tsl = fly_x - ctr_x;
fly_y_tsl = fly_y - ctr_y;
in_x_tsl = in_x - ctr_x;
in_y_tsl = in_y - ctr_y;
out_x_tsl = out_x - ctr_x;
out_y_tsl = out_y - ctr_y;


%get the diff of location x,y
vel_x_tsl = diff(fly_x_tsl);
vel_x_tsl = [0;vel_x_tsl];
vel_y_tsl = diff(fly_y_tsl);
vel_y_tsl = [0;vel_y_tsl];

%how far is the fly from the center
radius_fly = sqrt(fly_x_tsl.^2 + fly_y_tsl.^2);
%bin it so that I can calculate the average etc of velocity
radius_binned = (radius_fly.*bin_number)/circRad;
radius_binned = ceil(radius_binned);
% %linear regression and slope(p(1))
% [p,S] = polyfit(radius_fly,vel_total,1);
% display(p(1));

%get the radial diff of location x,y
rad_vel = diff(radius_fly);
rad_vel = [0;rad_vel];
rad_vel_sqrt = sqrt(rad_vel.^2);

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

%group rad_vel by radius_binned
for i=1:max(radius_binned)
    %total 9 minutes
    radvel_ori_by_radius_total{i} = rad_vel(find(radius_binned == i));
    
    %before
    radvel_before = rad_vel(1:timeperiods(2));
    radvel_ori_by_radius_before{i} = radvel_before(find(radius_binned_before == i));
    
    %during
    radvel_during = rad_vel(odoron_frame:odoroff_frame);
    radvel_ori_by_radius_during{i} = radvel_during(find(radius_binned_during == i));
    %after
    radvel_after = rad_vel(odoroff_frame:end);
    radvel_ori_by_radius_after{i} = radvel_after(find(radius_binned_after == i));
    
end

%bin the rad_vel_ori_by_radius by rad_vel (y axis)
bin_number_y = 20;
y_bin = linspace(-2,2,bin_number_y);

%before
radvel_bincount_before = nan(bin_number_y,numel(radvel_ori_by_radius_before));
for i=1:numel(radvel_ori_by_radius_before)
[bincounts,binindx] = histc(radvel_ori_by_radius_before{i},y_bin);%bin data and save the results
radvel_binned_before{i}=binindx;%binindx tells you where the individual points were binned to
radvel_bincount_before(:,i) = bincounts;%bincounts shows how many data points are in each bin
end

%during
radvel_bincount_during = nan(bin_number_y,numel(radvel_ori_by_radius_during));
for i=1:numel(radvel_ori_by_radius_during)
[bincounts,binindx] = histc(radvel_ori_by_radius_during{i},y_bin);%bin data and save the results
radvel_binned_during{i}=binindx;%binindx tells you where the individual points were binned to
radvel_bincount_during(:,i) = bincounts;
end

%after
radvel_bincount_after = nan(bin_number_y,numel(radvel_ori_by_radius_after));
for i=1:numel(radvel_ori_by_radius_after)
[bincounts,binindx] = histc(radvel_ori_by_radius_after{i},y_bin);%bin data and save the results
radvel_binned_after{i}=binindx;%binindx tells you where the individual points were binned to
radvel_bincount_after(:,i) = bincounts;
end

