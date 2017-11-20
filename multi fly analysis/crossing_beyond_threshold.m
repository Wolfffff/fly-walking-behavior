function [vel_o2i_th_bf_flies]...
    = crossing_beyond_threshold(numflies,circRad_flies,crossing_threshold,...
    inner_radius,radius_flies,how_long,...
    crossing_o2i_bf_frames_flies,velocity_o2i_before_flies)
%This function checks each crossing and decides whether the fly went past
%the crossing_threshold (1.4 or 1.5 cm)

counter = 1;p=1;
for i=1:numflies
    %convert the threshold unit to pixel
    IR_big = circRad_flies(i)*crossing_threshold/inner_radius;
    q=1;
    vel_o2i_th_temp =nan(how_long,1);
    for n = 1:numel(crossing_o2i_bf_frames_flies{i})%each crossing
        
        %get the radius at those frames (this checks between 10sec frames before and to next out)
        check1 = radius_flies(crossing_o2i_bf_frames_flies{1,i}{1,n},i);
        %is there any radius that is bigger than the threshold?
        check2 = find(check1 >= IR_big);
        %if there is
        if isempty(check2) == 0
            velocity_o2i_bf_th(:,p) = velocity_o2i_before_flies(:,counter);
            
            p=p+1;
            %make cell arrays so that i can use data per fly
            vel_o2i_th_temp(:,q) = velocity_o2i_before_flies(:,counter);
            q=q+1;
            counter = counter+1;
        else% if it is empty
            counter = counter+1;
        end
    end
    vel_o2i_th_bf_flies(i) = {vel_o2i_th_temp};
    clear vel_o2i_th_temp;
end