function [major_axo, minor_axo,major_axi, minor_axi,fly_bin_probability, bin_radius, average_radius,fly_location_bin] = ...
    radial_calculator(fly_x,fly_y, out_x,out_y,in_x,in_y,bin_number,timeperiods,...
    odoron_frame,odoroff_frame, inner_radius, outer_radius)

%radial distribution calculation

%Use 'ellipse_fit' function to determine inner/outer rims' major/minor axes etc.
[major_axo, minor_axo, ~, ~, ~] =ellipse_fit(out_x,out_y);
[major_axi, minor_axi, ctr_xi, ctr_yi, ~] =ellipse_fit(in_x,in_y);

bin_width = major_axi/bin_number; %thickness of each bin

%this is to make the biggest ellipse (projected from the inner rim)
%smaller than the actual outer rim
total_bin_no = ceil(minor_axo/bin_width);

%generate a series of ellipses points by using inner rim points (in_x,
%in_y)
ellipse_x = zeros(length(in_x),total_bin_no-1);
ellipse_y = zeros(length(in_y),total_bin_no-1);
for n=1:total_bin_no-1
    ellipse_x(:,n) = (in_x-ctr_xi)*n/bin_number + ctr_xi;
    ellipse_y(:,n) = (in_y-ctr_yi)*n/bin_number + ctr_yi;
end

%indicate a fly's location as 0 or 1 in each ellipse
fly_in = ones(timeperiods(4),total_bin_no);
ellipse_area = zeros(1,total_bin_no);
for i=1:total_bin_no-1
    fly_in(:,i) = inpolygon(fly_x,fly_y,ellipse_x(:,i),ellipse_y(:,i));
    
    %calculate the ellipse_area of the each ellipse
    ellipse_area(i) = pi*(major_axi/bin_number*i)*(minor_axi/bin_number*i);
end

%actual area of the outer rim
ellipse_area(total_bin_no) = polyarea(out_x,out_y);
%now calculate the area of each bin
bin_area = nan(1,total_bin_no);
bin_area(1)=ellipse_area(1); 
bin_area(2:end) = diff(ellipse_area);

% get the difference between column(each bin) so that 1 indicates that a fly is inside that specific bin
fly_location = diff(fly_in,1,2);
fly_location = [fly_in(:,1) fly_location];

%actual bin number for fly's location at every frame
for i=1:timeperiods(4)
fly_location_bin_temp(i) = find(fly_location(i,:));
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

