function [ velocity_classified,velocity_classified_binary, runstops ]...
    = Velocity_Classifier( velocity, first_point, stopthreshold, runthreshold )
%Velocity_Classifier
%   takes velocity points and thresholds and outputs classified velocity
%   and crossing points.


velocity_classified = nan (size(velocity));
velocity_classified_binary = nan (size(velocity));
runstops =  nan (size(velocity));

%first_points is given by a user
if first_point == 0;
    velocity_classified(1,1) = 0;
    velocity_classified_binary(1,1) = 0;
else
    velocity_classified(1,1) = velocity(1,1);
    velocity_classified_binary(1,1) = 1;
end

%three consecutive points below stop threshold is defined as 'stop'

for framenum = 2:(length(velocity)-2); %first point can't be less than 2
    if velocity_classified_binary((framenum-1)) == 1; %previous frame is run
        if velocity(framenum,1) >= stopthreshold; % and next point is not below stop threshold,
            velocity_classified(framenum,1) = velocity(framenum,1); % then the next point is a run, save the velocity
            velocity_classified_binary(framenum) = 1;
        else %if previous frame was run, but this point is below stop threshold
            if velocity(framenum+1) <= stopthreshold && velocity(framenum+2) <= stopthreshold; % if the next two points are stops,
                velocity_classified(framenum) = 0; % then the point in question is also a stop
                velocity_classified_binary(framenum) = 0;
                runstops(framenum) = 1; %this is the point where run becomes stop 
            else %if this frame was stop but next two points are not stops
                velocity_classified(framenum) = velocity(framenum);%it is still a run
                velocity_classified_binary(framenum) = 1;
            end
        end
        
        
    else % if the previous point was a stop
        if velocity(framenum) < runthreshold; % and this point is not above the run threshold,
            velocity_classified(framenum) = 0; % then this point is still a stop
            velocity_classified_binary(framenum) = 0;
        else % this point is above the run threshold
            if velocity(framenum+1) >= runthreshold && velocity(framenum+2) >= runthreshold; % if the next two points are runs;
                velocity_classified(framenum) = velocity(framenum); % then the point in question is also a run
                velocity_classified_binary(framenum) = 1;
                runstops(framenum) = 1;%this is the point when stop becomes run
            else %even if this point is above the run threshold, the next two points are not runs,
                velocity_classified(framenum) = 0; % it is still a stop
                velocity_classified_binary(framenum) = 0;
            end
        end
    end
end


