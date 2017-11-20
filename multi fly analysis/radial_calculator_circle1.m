function [out_R,fly_bin_probability, bin_radius, average_radius,radius_binned] = ...
    radial_calculator1(fly_x,fly_y, out_x,out_y,in_x,in_y,bin_number,timeperiods,...
    odoron_frame,odoroff_frame, inner_radius, outer_radius)

%radial distribution calculation

%using circfit instead of ellipse fit
[out_xc,out_yc,out_R,out_a] = circfit(out_x,out_y);
%find the center and radius (in pixel) of inner rim
[ctr_x,ctr_y,in_R] = circfit(in_x,in_y);

%translate all the points so that the center is (0,0)
fly_x_tsl = fly_x - ctr_x;
fly_y_tsl = fly_y - ctr_y;

%how far is the fly from the center (in pixel)
radius_fly = sqrt(fly_x_tsl.^2 + fly_y_tsl.^2);
%bin it 
radius_binned = (radius_fly.*bin_number)/in_R;
radius_binned = ceil(radius_binned);

bin_width_c = in_R/bin_number; %thickness of each bin
total_bin_no = ceil(out_R/bin_width_c)-1; % decide how many bins total
%Make the last bin very big so that there is no overlap between the biggest
%projected circle and the actual outer rim

circle_x = nan(length(in_x),total_bin_no-1);
circle_y = nan(length(in_y),total_bin_no-1);

%generate a series of circle points by using inner rim points (in_x,
%in_y) until bin number so that that matches with the actual IR
for n=1:total_bin_no-1
    circle_x(1:length(in_x),n) = (in_x-ctr_x)*n/bin_number + ctr_x;
    circle_y(1:length(in_x),n) = (in_y-ctr_y)*n/bin_number + ctr_y;
end

%find the area of each circle
circle_area = zeros(1,total_bin_no);
for i=1:total_bin_no-1
    %calculate the circle_area of the each circle
    circle_area(i) = polyarea(circle_x(:,i),circle_y(:,i));
end
%actual area of the outer rim
circle_area(total_bin_no) = polyarea(out_x,out_y);

%now calculate the area of each bin
bin_area = nan(1,total_bin_no);
bin_area(1)= circle_area(1); 
bin_area(2:end) = diff(circle_area);


%now count how many times fly is found in each bin / period
fly_bin_count = zeros(3,total_bin_no);

for period =1:3
    %get the data for each period
    if period ==1 %before
        AA=radius_binned(1:timeperiods(2));
    elseif period ==2 %during
        AA = radius_binned(odoron_frame:odoroff_frame-1);
    else
        AA = radius_binned(odoroff_frame :end);
    end
    
    %count how many times there are corresponding bin # 
    for i=1:total_bin_no
        fly_bin_count(period,i) = length(find(AA == i));
    end
end

% normalize so that all bin area is same as the first bin area
fly_bin_normalized = zeros(3,total_bin_no);
for i=1:3
    fly_bin_normalized(i,:) = fly_bin_count(i,:)./(bin_area/bin_area(1));
end

%calculate the probability (1 means that a fly stayed in that bin for the entire
%period)
fly_bin_probability=zeros(3,total_bin_no);
for i=1:3
    fly_bin_probability(i,:) = fly_bin_normalized(i,:)/sum(fly_bin_normalized(i,:),2);
end

%convert bin # to cm
%inner rim radius is 1.2cm, converting bin# to r(cm)
bin_radius = zeros(1,total_bin_no);
for n=1:total_bin_no-1
    bin_radius(n)=inner_radius*n/bin_number;
end
%last radius is outer radius
bin_radius(end)=outer_radius;

%get fly's average location (as bin #) in each period
avg_bin_no=zeros(1,3);
for n=1:3
    avg_bin_no(n)= fly_bin_probability(n,:)*[1:total_bin_no]';
end
% convert it to cm unit
average_radius = inner_radius*avg_bin_no/bin_number;
