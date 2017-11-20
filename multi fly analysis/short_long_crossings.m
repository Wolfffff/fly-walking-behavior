function [vel_o2i_before_short,vel_o2i_during_short,vel_o2i_after_short,...
    vel_o2i_before_long,vel_o2i_during_long,vel_o2i_after_long,...
    vel_i2o_before_short,vel_i2o_during_short,vel_i2o_after_short,...
    vel_i2o_before_long,vel_i2o_during_long,vel_i2o_after_long,...
    avg_vel_o2i_short,avg_vel_o2i_long,avg_vel_i2o_short,avg_vel_i2o_long]...
    = short_long_crossings(how_short,velocity_in2out_before,velocity_in2out_during,...
    velocity_in2out_after,velocity_out2in_before,velocity_out2in_during,velocity_out2in_after,...
    framespertimebin,timebefore,timetotal)

%divide velocity data into two groups : short time in/transit vs long time in/transit
%this assumes that the real crossing data is saved after 10 seconds in
%arrays. Output 'avg_...' is MEDIAN VALUE!

a = timetotal*framespertimebin;
    
vel_i2o_before_long = nan(a,1);
vel_i2o_during_long = nan(a,1);
vel_i2o_after_long = nan(a,1);

vel_i2o_before_short = nan(a,1);
vel_i2o_during_short = nan(a,1);
vel_i2o_after_short = nan(a,1);

vel_o2i_before_long = nan(a,1);
vel_o2i_during_long = nan(a,1);
vel_o2i_after_long = nan(a,1);

vel_o2i_before_short = nan(a,1);
vel_o2i_during_short = nan(a,1);
vel_o2i_after_short = nan(a,1);


%before
%in2out
n1=1; n2=1;
for i=1:size(velocity_in2out_before,2)
    %how many real numbers? (not nans)
    if sum(~isnan(velocity_in2out_before((timebefore*framespertimebin+1):end,i)))> how_short
        vel_i2o_before_long(:,n1) = velocity_in2out_before(:,i);
        n1=n1+1;
    else %short
        vel_i2o_before_short(:,n2) = velocity_in2out_before(:,i);
        n2=n2+1;
    end
    
end

%before
%out2in
n1=1; n2=1;
for i=1:size(velocity_out2in_before,2)
    if sum(~isnan(velocity_out2in_before((timebefore*framespertimebin+1):end,i)))> how_short
        vel_o2i_before_long(:,n1) = velocity_out2in_before(:,i);
        n1=n1+1;
    else %short
        vel_o2i_before_short(:,n2) = velocity_out2in_before(:,i);
        n2=n2+1;
    end
    
end

%during
%in2out
n1=1; n2=1;

for i=1:size(velocity_in2out_during,2)
    if sum(~isnan(velocity_in2out_during((timebefore*framespertimebin+1):end,i)))> how_short
        vel_i2o_during_long(:,n1) = velocity_in2out_during(:,i);
        n1=n1+1;
    else %short
        vel_i2o_during_short(:,n2) = velocity_in2out_during(:,i);
        n2=n2+1;
    end
    
end

%during
%out2in
n1=1; n2=1;
for i=1:size(velocity_out2in_during,2)
    if sum(~isnan(velocity_out2in_during((timebefore*framespertimebin+1):end,i)))> how_short
        vel_o2i_during_long(:,n1) = velocity_out2in_during(:,i);
        n1=n1+1;
    else %short
        vel_o2i_during_short(:,n2) = velocity_out2in_during(:,i);
        n2=n2+1;
    end
    
end

%after
%in2out
n1=1; n2=1;

for i=1:size(velocity_in2out_after,2)
    if sum(~isnan(velocity_in2out_after((timebefore*framespertimebin+1):end,i)))> how_short
        vel_i2o_after_long(:,n1) = velocity_in2out_after(:,i);
        n1=n1+1;
    else %short
        vel_i2o_after_short(:,n2) = velocity_in2out_after(:,i);
        n2=n2+1;
    end
    
end

%after
%out2in
n1=1; n2=1;
for i=1:size(velocity_out2in_after,2)
    if sum(~isnan(velocity_out2in_after((timebefore*framespertimebin+1):end,i)))> how_short
        vel_o2i_after_long(:,n1) = velocity_out2in_after(:,i);
        n1=n1+1;
    else %short
        vel_o2i_after_short(:,n2) = velocity_out2in_after(:,i);
        n2=n2+1;
    end
    
end

%get the average of those crossings:MEDIAN
%short
avg_vel_o2i_short(:,1) = nanmedian(vel_o2i_before_short,2);
avg_vel_i2o_short(:,1) = nanmedian(vel_i2o_before_short,2);

avg_vel_o2i_short(:,2) = nanmedian(vel_o2i_during_short,2);
avg_vel_i2o_short(:,2) = nanmedian(vel_i2o_during_short,2);

avg_vel_o2i_short(:,3) = nanmedian(vel_o2i_after_short,2);
avg_vel_i2o_short(:,3) = nanmedian(vel_i2o_after_short,2);

%long
avg_vel_o2i_long(:,1) = nanmedian(vel_o2i_before_long,2);
avg_vel_i2o_long(:,1) = nanmedian(vel_i2o_before_long,2);

avg_vel_o2i_long(:,2) = nanmedian(vel_o2i_during_long,2);
avg_vel_i2o_long(:,2) = nanmedian(vel_i2o_during_long,2);

avg_vel_o2i_long(:,3) = nanmedian(vel_o2i_after_long,2);
avg_vel_i2o_long(:,3) = nanmedian(vel_i2o_after_long,2);
