function [ vel_in_after_final, vel_out_after_final...
    vel_in_during_final, vel_out_during_final, vel_in_before_final, vel_out_before_final,  vel_in_a, vel_out_a...
    vel_in_d, vel_out_d, vel_in_b, vel_out_b, velocity_fly_in, velocity_fly_out ...
    avgvelocity_by_fly_in, avgvelocity_by_fly_out]=...
    crossingframesvelocity(vel_in_before, vel_out_before, vel_in_during, vel_out_during, vel_in_after, vel_out_after)

for nn = 1:max(length(vel_in_before), length(vel_out_before));
    try
        vel_in_before_temp{nn}(:,1) = diff(vel_in_before{nn}(:,1));
        vel_in_before_temp{nn}(:,2) = diff(vel_in_before{nn}(:,2));
    catch
    end
    try
        vel_out_before_temp{nn}(:,1) = diff(vel_out_before{nn}(:,1));
        vel_out_before_temp{nn}(:,2) = diff(vel_out_before{nn}(:,2));
        
    catch
    end
end
for nn = 1:max(length(vel_in_before_temp), length(vel_out_before_temp))
    try
        vel_in_b{nn}(:,1) = sqrt((vel_in_before_temp{nn}(:,1)).^2+(vel_in_before_temp{nn}(:,2)).^2);
    catch
    end
    try
        vel_out_b{nn}(:,1) = sqrt((vel_out_before_temp{nn}(:,1)).^2+(vel_out_before_temp{nn}(:,2)).^2);
    catch
    end
end

for nn = 1:max(length(vel_in_during), length(vel_out_during))
    try
        vel_in_during_temp{nn}(:,1) = diff(vel_in_during{nn}(:,1));
        vel_in_during_temp{nn}(:,2) = diff(vel_in_during{nn}(:,2));
    catch
    end
    try
        vel_out_during_temp{nn}(:,1) = diff(vel_out_during{nn}(:,1));
        vel_out_during_temp{nn}(:,2) = diff(vel_out_during{nn}(:,2));
    catch
    end
end

for nn = 1:max(length(vel_in_during_temp), length(vel_out_during_temp))
    try
        vel_in_d{nn}(:,1) = sqrt((vel_in_during_temp{nn}(:,1)).^2+(vel_in_during_temp{nn}(:,2)).^2);
    catch
    end
    try
        vel_out_d{nn}(:,1) = sqrt((vel_out_during_temp{nn}(:,1)).^2+(vel_out_during_temp{nn}(:,2)).^2);
    catch
    end
end

for nn = 1:max(length(vel_in_after), length(vel_out_after));
    try
        vel_in_after_temp{nn}(:,1) = diff(vel_in_after{nn}(:,1));
        vel_in_after_temp{nn}(:,2) = diff(vel_in_after{nn}(:,2));
        
    catch
    end
    try
        vel_out_after_temp{nn}(:,1) = diff(vel_out_after{nn}(:,1));
        vel_out_after_temp{nn}(:,2) = diff(vel_out_after{nn}(:,2));
    catch
    end
end

for nn = 1:max(length(vel_in_after_temp), length(vel_out_after_temp));
    try
        vel_in_a{nn}(:,1) = sqrt((vel_in_after_temp{nn}(:,1)).^2+(vel_in_after_temp{nn}(:,2)).^2);
    catch
    end
    try
        vel_out_a{nn}(:,1) = sqrt((vel_out_after_temp{nn}(:,1)).^2+(vel_out_after_temp{nn}(:,2)).^2);
    catch
    end
end
vel_in_a = vel_in_a';
vel_in_after_final = cell2mat(vel_in_a);
vel_in_b = vel_in_b';
vel_in_before_final = cell2mat(vel_in_b);
vel_in_d= vel_in_d';
vel_in_during_final = cell2mat(vel_in_d);
vel_out_a = vel_out_a';
vel_out_after_final = cell2mat(vel_out_a);
vel_out_b= vel_out_b';
vel_out_before_final = cell2mat(vel_out_b);
vel_out_d = vel_out_d';
vel_out_during_final = cell2mat(vel_out_d);
lengthcheck1 = [length(vel_in_before_final), length(vel_in_during_final), length(vel_in_after_final)];
preall = max(lengthcheck1);
velocity_fly_in = nan(preall, 3);

velocity_fly_in(1:length(vel_in_before_final),1) = vel_in_before_final;
velocity_fly_in(1:length(vel_in_during_final),2) = vel_in_during_final;
velocity_fly_in(1:length(vel_in_after_final),3) = vel_in_after_final;

lengthcheck2 = [length(vel_out_before_final), length(vel_out_during_final), length(vel_out_after_final)];
preall = max(lengthcheck2);
velocity_fly_out= nan(preall, 3);

velocity_fly_out(1:length(vel_out_before_final),1) = vel_out_before_final;
velocity_fly_out(1:length(vel_out_during_final),2) = vel_out_during_final;
velocity_fly_out(1:length(vel_out_after_final),3) = vel_out_after_final;


avgvelocity_by_fly_in(:,1) =  nanmean(vel_in_before_final);
avgvelocity_by_fly_in(:,2) =  nanmean(vel_in_during_final);
avgvelocity_by_fly_in(:,3) =  nanmean(vel_in_after_final);

avgvelocity_by_fly_out(:,1) =  nanmean(vel_out_before_final);
avgvelocity_by_fly_out(:,2) =  nanmean(vel_out_during_final);
avgvelocity_by_fly_out(:,3) =  nanmean(vel_out_after_final);
