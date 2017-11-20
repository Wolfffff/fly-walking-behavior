function  [radius_fly,rad_vel,circRad] = rad_velocity(in_x,in_y, fly_x,fly_y,out_x,out_y)

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

% %linear regression and slope(p(1))
% [p,S] = polyfit(radius_fly,vel_total,1);
% display(p(1));

%get the radial diff of location x,y 

rad_vel = diff(radius_fly);
rad_vel = [0;rad_vel];