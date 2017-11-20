function [fly_x_aligned,fly_y_aligned,rotated_in_x,rotated_in_y,...
    short_fly_x_aligned,short_fly_y_aligned,crossing_in_cell,crossing_out_cell...
    angle_bw_crosses,period_1,period_2]...
    = traceplotter_O2I(crossing_in_before,crossing_in_during,crossing_in_after,...
    crossing_out_before,crossing_out_during,crossing_out_after,...
    in_x,in_y,fly_x,fly_y,how_short,framespertimebin,timeperiods)

%This function plots fly tracks at crossing points and align them so that the
%entry points are all same
%traceplotter by Catherine
%annotated and modified by SJ
%This function is slightly different from traceplotter_SJ.m file!!
%(6/11/12)

crossing_in_cell = {crossing_in_before;crossing_in_during; crossing_in_after};
crossing_out_cell = {crossing_out_before;crossing_out_during; crossing_out_after};
fly_aligned = cell(max(length(crossing_in_cell)),6); %pre-allocate
angle_bw_crosses = nan(1,3);

%get the center of the inner rim circle
% meanx = mean(in_x);
% meany = mean(in_y);
%get the center of the inner rim using 'circlefitbytaubin' function
XY = horzcat(in_x,in_y);
circ = CircleFitByTaubin(XY);
circ_x = circ(1);
circ_y = circ(2);

%translated fly_x/y so that the center is '0'
xypoints = [fly_x-circ_x fly_y-circ_y];
new_in_x = in_x - circ_x;
new_in_y = in_y - circ_y;

%pre-allocate
firstframesx = cell(max(length(crossing_in_cell)),3);
firstframesy = cell(max(length(crossing_in_cell)),3);
theta = cell(max(length(crossing_in_cell)),3);

if isempty(crossing_in_before) == 1 %no crossing in 'before'
    period_1 = 2;
    period_2 = 3;
elseif isempty(crossing_in_after) ==1 %no crossing in 'after'
    period_1= 1;
    period_2 = 2;
else
    period_1 =1;
    period_2 =3;
end

for period = period_1:period_2 %each odor period
    if isempty(crossing_out_cell{period})==1 %if there is no crossing out,use the end of time period as crossing out
        crossing_out_cell{period}(1) = timeperiods(period+1);
    end
    if (crossing_in_cell{period}(1)) < (crossing_out_cell{period}(1)) ;
        %         display ('fly is going in first')
        %if there is no crossing out but one crossing in,
        %use the end of time period as crossing out
        if  crossing_in_cell{period}(end) > crossing_out_cell{period}(end)
            %if the fly does not come out at the odor period,
            %use the end fot time period as crossing out
            crossing_out_cell{period}(end+1) = timeperiods(period+1);
            %             display('Last crossing is I2O');
        end
    else %fly was inside and first crossing was I2O
        %         display('fly is coming out first');
        crossing_out_cell{period}(1) = [];
        %         display('remove first crossing out')
        if crossing_out_cell{period}(end) < crossing_in_cell{period}(end);
            crossing_out_cell{period}(end+1) = timeperiods(period+1);
            %             display('use end of timeperiod as the last crossing out as fly will not leave again');
        end
    end
    
    for h = 1:length(crossing_in_cell{period});
        %get the crossing point xy coordinates
        firstframesx{h,period} = xypoints((crossing_in_cell{period}(h)),1);
        firstframesy{h,period} = xypoints((crossing_in_cell{period}(h)),2);
        
        %use atan2 (inverse tangent) to get the angle from the center to the
        %crossing point (radians from -pi to pi)
        theta = atan2(firstframesy{h,period}, firstframesx{h,period});
        
        %get the xy coordinates from the crossing in to crossing out
        x = (xypoints(crossing_in_cell{period}(h):(crossing_out_cell{period}(h)),1));
        y = (xypoints(crossing_in_cell{period}(h):(crossing_out_cell{period}(h)),2));
        
        %use theta angle to rotate the xy coordinates so that they are on x
        %axis
        flyalignedx{h,period} = x*cos(pi-theta)-y*sin(pi-theta);
        flyalignedy{h,period} = x*sin(pi-theta)+y*cos(pi-theta);
        
        %rotate the inner rim
        rotated_in_x{h,period} = new_in_x*cos(pi-theta)-new_in_y*sin(pi-theta);
        rotated_in_y{h,period} = new_in_x*sin(pi-theta)+new_in_y*cos(pi-theta);
    end
    
    %translate all the points so that crossing points is (0,0)
    for h = 1:length(crossing_in_cell{period});
        aligningfactorx = (0-flyalignedx{h, period}(1));
        fly_x_aligned{h,period} = (flyalignedx{h,period}+aligningfactorx);
        aligningfactory = (0-flyalignedy{h, period}(1));
        fly_y_aligned{h,period} = (flyalignedy{h,period}+aligningfactory);
        %rim translation
        rotated_in_x{h,period} = rotated_in_x{h,period} +aligningfactorx;
        rotated_in_y{h,period} = rotated_in_y{h,period}+aligningfactory;
        
        %only show the 2 second after crossing in
        track_length = how_short*framespertimebin;
        if length(fly_x_aligned{h,period}) > track_length
            short_fly_x_aligned{h,period} = fly_x_aligned{h,period}(1:track_length);
            short_fly_y_aligned{h,period} = fly_y_aligned{h,period}(1:track_length);
        else
            short_fly_x_aligned{h,period} = fly_x_aligned{h,period};
            short_fly_y_aligned{h,period} = fly_y_aligned{h,period};
        end
        
    end
    
    %calculate the angle between crossing in and next crossing out:
    %first, get the next crossing out exit point (last element of
    %flyalignedx and flyalignedy) then check if that point
    %is outside the inner rim. If inside the inner rim, that is not a real
    %entry point.(probably point at the end of the time period)
    
    for h=1:length(crossing_in_cell{period})
        real_crossing = inpolygon(fly_x_aligned{h,period}(end),fly_y_aligned{h,period}(end),rotated_in_x{h,period},rotated_in_y{h,period});
        if real_crossing == 0 %it is a real crossing
            theta2 = atan2(flyalignedy{h,period}(end), flyalignedx{h,period}(end));
            if theta2 >= 0
                angle_bw_crosses(h,period)= pi - theta2;%since the exit point was -pi
            else
                angle_bw_crosses(h,period)= -pi - theta2;
            end
        end
    end
    
end