function [out_R,fly_bin_probability, bin_radius, average_radius,fly_location_bin] = ...
    radial_calculator(fly_x,fly_y, out_x,out_y,in_x,in_y,bin_number,timeperiods,...
    odoron_frame,odoroff_frame, inner_radius, outer_radius)

%radial distribution calculation

%using circfit instead of ellipse fit
[out_xc,out_yc,out_R,out_a] = circfit(out_x,out_y);
[in_xc,in_yc,in_R,in_a] = circfit(in_x,in_y);

bin_width_c = in_R/bin_number; %thickness of each bin
total_bin_no = ceil(out_R/bin_width_c)-1; % decide how many bins total
%Make the last bin very big so that there is no overlap between the biggest
%projected circle and the actual outer rim

circle_x = nan(length(out_x),total_bin_no-1);
circle_y = nan(length(out_y),total_bin_no-1);

%generate a series of circle points by using inner rim points (in_x,
%in_y) until bin number so that that matches with the actual IR
for n=1:total_bin_no-1
    circle_x(1:length(in_x),n) = (in_x-in_xc)*n/bin_number + in_xc;
    circle_y(1:length(in_x),n) = (in_y-in_yc)*n/bin_number + in_yc;
end


%indicate a fly's location as 0 or 1 in each circle
fly_in = ones(timeperiods(4),total_bin_no);
circle_area = zeros(1,total_bin_no);
for i=1:total_bin_no-1
    fly_in(:,i) = inpolygon(fly_x,fly_y,circle_x(:,i),circle_y(:,i));
    
    %calculate the circle_area of the each circle
    circle_area(i) = pi*(in_R/bin_number*i).^2;

end
%actual area of the outer rim
circle_area(total_bin_no) = polyarea(out_x,out_y);

%now calculate the area of each bin
bin_area = nan(1,total_bin_no);
bin_area(1)= circle_area(1); 
bin_area(2:end) = diff(circle_area);

% get the difference between column(each bin) so that 1 indicates that a fly is inside that specific bin
fly_location = diff(fly_in,1,2);
%If fly is inside 10th circle but outside of 11th circle (this could happen
%occasionally at the transition from inner to outer R at total_bin_no-4)
% fly_location(find(fly_location <0)) =1;
fly_location = [fly_in(:,1) fly_location];

%actual bin number for fly's location at every frame
for i=1:timeperiods(4)
fly_in_bins=find(fly_location(i,:));
fly_location_bin_temp(i) = fly_in_bins(1);
end
fly_location_bin = fly_location_bin_temp'; 

%now count how many times fly is found in each bin / period
fly_bin_count = zeros(3,total_bin_no);

fly_bin_count(1,:)= sum(fly_location(1:timeperiods(2),:));%before odor period
%during odor (from the first time fly enters the odor zone till odor off)
fly_bin_count(2,:)= sum(fly_location(odoron_frame:odoroff_frame-1,:));
fly_bin_count(3,:)= sum(fly_location(odoroff_frame:end,:));%after

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
