%%
% plot turn frq and curved walk fraction in various rings
%set the size of the area (a ring between two circles) (in cm)
ring_inner_radius = 1.0;

NumRings = 5;
ring_outer_radius_rings = linspace(1.1,1.5,NumRings); %to repeat the function

%pre-allocate arrays

for i = 1:numflies
    %load each fly's data
    fly_x = numvals(:,2*i-1);
    fly_y = numvals(:,2*i);
    radius_fly_cm = radius_cm_flies(:,i);
    velocity_classified = vel_classified_flies(:,i);
    curv_long_mat = frame_all_curv{i};
    frame_turn_sh = frame_sharp_turn{i};
    
    %this is the original 1.2 cm IR
    in_x_ori = numvals_pi_ori{i}(:,1);
    in_y_ori = numvals_pi_ori{i}(:,2);    
      
    
    %change ring_outer_radius and compare turn frq and curved walk fraction

%     ring_outer_radius_rings = linspace(1.1,1.5,NumRings); %to repeat the function
    
    for n = 1:NumRings
        ring_outer_radius = ring_outer_radius_rings(n);
        
        [fly_in_ring,fly_in_ring_bf,fly_in_ring_dr,fly_in_ring_af,...
            turn_in_ring,turn_in_ring_bf,turn_in_ring_dr,turn_in_ring_af,...
            turn_fr_ring_total,turn_fr_ring,...
            curv_in_ring,curv_in_ring_bf,curv_in_ring_dr,curv_in_ring_af,...
            curv_fr_ring_total,curv_fr_ring,...
            ring_outer_x,ring_outer_y,ring_inner_x,ring_inner_y] =...
            turn_inside_ring(ring_outer_radius,ring_inner_radius,in_x_ori,in_y_ori,inner_radius,fly_x,fly_y,...
            radius_fly_cm,timeperiods,odoron_frame(i),odoroff_frame,velocity_classified,...
            curv_long_mat,frame_turn_sh,framespertimebin);
        
        %save each fly's data : curved walk fraction (out of all the walk (not
        %stop) inside the ring
        curv_fr_ring_flies(i,n) = curv_fr_ring_total;
        curv_fr_ring_period_flies(:,i,n) = curv_fr_ring;
        
        curv_in_ring_flies{i,n} =curv_in_ring;
        curv_in_ring_period_flies{1,i,n} = curv_in_ring_bf;
        curv_in_ring_period_flies{2,i,n} = curv_in_ring_dr;
        curv_in_ring_period_flies{3,i,n} = curv_in_ring_af;
        
        % turn frequency (turn #/sec)
        turn_fr_ring_flies(i,n) = turn_fr_ring_total;
        turn_fr_ring_period_flies(:,i,n) = turn_fr_ring;
        
        turn_in_ring_flies{i,n} = turn_in_ring;
        turn_in_ring_period_flies{1,i,n} = turn_in_ring_bf;
        turn_in_ring_period_flies{2,i,n} = turn_in_ring_dr;
        turn_in_ring_period_flies{3,i,n} = turn_in_ring_af;
        
        %frame # when the fly is inside the ring
        fly_in_ring_flies{i,n} = fly_in_ring; %this variable contains the frame# and radius_fly_cm
        fly_in_ring_period_flies{1,i,n} = fly_in_ring_bf;
        fly_in_ring_period_flies{2,i,n} = fly_in_ring_dr;
        fly_in_ring_period_flies{3,i,n} = fly_in_ring_af;
        
        %xy coordinates of ring inner/outer for each fly
        ring_outer = horzcat(ring_outer_x,ring_outer_y);
        ring_outer_flies(:,2*i-1:2*i,n) = ring_outer;
        ring_inner = horzcat(ring_inner_x,ring_inner_y);
        ring_inner_flies(:,2*i-1:2*i,n) = ring_inner;
    end
    
    
end

save([fig_title '_turn_inside_ring' date '.mat']);