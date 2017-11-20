function [vel_in_run, vel_in_stop, vel_out_run, vel_out_stop] =...
    vel_in_out_divider(velocity, inside_rim,timeperiods,odoron_frame)
% % %divide velocity data into in VS out and run VS stop (before, during)

%for testing function
% velocity = velocity_classified; odoron_frame = odoron_frame(1);inside_rim=inside_rim(:,1);


odoroff_frame = timeperiods(3);
display(odoron_frame)

%making nan arrays (first column: frame#, second column: corresponding
%velocity at that frame)
vel_before_in = nan(1,2);vel_before_out = nan(1,2);
vel_during_in = nan(1,2);vel_during_out = nan(1,2);
vel_after_in = nan(1,2);vel_after_out = nan(1,2);
%this way, if there is no entry, there will be no velocity data rather than
%'0' as a velocity, which could mean that a fly did not move.

%checking each velocity from the first frame and store the frame number and
%corresponding velocity in separate arrays. Since there is a frame number
%for each velocity, if we need, we can check if it was a continuous run or
%not.
k=1;l=1; m=1;n=1; o=1;p=1;
for i=1:timeperiods(4)
    if i < timeperiods(2) %before
        if inside_rim(i) == 1 %if fly is inside
            vel_before_in(k,1) = i;
            vel_before_in(k,2) = velocity(i);
            k = k+1;
        else % if fly is outside
            vel_before_out(l,1) = i;
            vel_before_out(l,2) = velocity(i);
            l=l+1;
        end
    elseif i >= odoron_frame && i < odoroff_frame %during
        if inside_rim(i) == 1 %if fly is inside
            vel_during_in(m,1) = i;
            vel_during_in(m,2) = velocity(i);
            m = m+1;
        else % if fly is outside
            vel_during_out(n,1) = i;
            vel_during_out(n,2) = velocity(i);
            n=n+1;
        end
    elseif i >= odoroff_frame %after
        if inside_rim(i) == 1 %if fly is inside
            vel_after_in(o,1) = i;
            vel_after_in(o,2) = velocity(i);
            o = o+1;
        else % if fly is outside
            vel_after_out(p,1) = i;
            vel_after_out(p,2) = velocity(i);
            p=p+1;
        end
    end
end

%% divide velocity into in/out
%check how many discontinuous points there are
%and make cell arrays to save the continuous velocity data

%before, in
if sum(find(diff(vel_before_in(:,1)) ~= 1)) ~= 0 %there is at least one discontinuous point
    disc_point = find(diff(vel_before_in(:,1)) ~= 1)+1;
    disc_point = [1;disc_point];
    vel_before_in_cont = cell(length(disc_point),1);
    for i=2:length(disc_point)
        vel_before_in_cont(i-1)={vel_before_in(disc_point(i-1):disc_point(i)-1,2)};
    end
    vel_before_in_cont(end) ={vel_before_in(disc_point(end):end,2)};
else % if there is only one continuous stretch of data
    vel_before_in_cont = {vel_before_in(:,2)};
end

%before, out
if sum(find(diff(vel_before_out(:,1)) ~= 1)) ~= 0 %there is at least one discontinuous point
    disc_point = find(diff(vel_before_out(:,1)) ~= 1)+1;
    disc_point = [1;disc_point];
    vel_before_out_cont = cell(length(disc_point),1);
    for i=2:length(disc_point)
        vel_before_out_cont(i-1)={vel_before_out(disc_point(i-1):disc_point(i)-1,2)};
    end
    vel_before_out_cont(end) = {vel_before_out(disc_point(end):end,2)};
else % if there is only one continuous stretch of data
    vel_before_out_cont = {vel_before_out(:,2)};
end


%then, divide runs and stops

%pre-allocate
vel_before_in_stop = cell(1);
vel_before_in_run = cell(1);
vel_before_out_stop = cell(1);
vel_before_out_run = cell(1);
vel_during_in_stop = cell(1);
vel_during_in_run = cell(1);
vel_during_out_stop = cell(1);
vel_during_out_run = cell(1);

n=1;m=1;
if exist('vel_before_in_cont') == 1 %#ok<EXIST> %if the fly went inside the OZ in 'before'
    for i=1:numel(vel_before_in_cont)
        
        A = vel_before_in_cont{i};
        if isnan(A) ~= 1
            frameStop = find(~A); %zero elements of A array (stops)
            frameRun = find(A);
            if isempty(frameStop) == 0
                if i==1 && frameStop(1) == 1 %velocity of the first frame is always 0, do not count it as a stop
                    frameStop(1) =[];
                end
            end
            
            ss_trans = frameStop(find(diff(frameStop) ~= 1)+1);%frame number of stops (start of new stop)
            ss_trans = [ss_trans; frameStop(find(diff(frameStop) ~= 1))];%frame number for the end of stop
            rr_trans =frameRun(find(diff(frameRun) ~= 1)+1); %frame number of runs
            rr_trans = [rr_trans; frameRun(find(diff(frameRun) ~= 1))];
            
            if numel(frameStop) ~= 0
                ss_trans = [frameStop(1); ss_trans; frameStop(end)];
                ss_trans = sort(ss_trans);
            end
            if numel(frameRun) ~= 0
                rr_trans = [frameRun(1); rr_trans; frameRun(end)];
                rr_trans = sort(rr_trans);
            end
            numStop = length(ss_trans)/2; % how many stops?
            numRun = length(rr_trans)/2;
            
            %pre-allocate cell arrays
            vel_stop = cell(1,numStop);
            vel_run = cell(1,numRun);
            
            if numStop ~= 0 %if there is at least one stop
                
                for p=1:numStop
                    vel_stop = A(ss_trans(2*p-1):ss_trans(2*p));
                    vel_before_in_stop{n} = vel_stop; n=n+1;
                end
            end
            
            if numRun ~= 0 %if tehre is at least one run
                
                for p=1:numRun
                    vel_run = A(rr_trans(2*p-1):rr_trans(2*p));
                    vel_before_in_run{m} = vel_run; m=m+1;
                end
            end
        end
        
    end
else % if there is no velocity data 'in' in 'before'
    vel_before_in_stop = cell(1);
    vel_before_in_run = cell(1);
end

%out
n=1; m=1;
for i=1:numel(vel_before_out_cont)
    
    A = vel_before_out_cont{i};
    frameStop = find(~A); %zero elements of A array (stops)
    frameRun = find(A);
    if isempty(frameStop) == 0
        if i==1 & frameStop(1) == 1 %velocity of the first frame is always 0, do not count it as a stop
            frameStop(1) =[];
        end
    end
    
    ss_trans = frameStop(find(diff(frameStop) ~= 1)+1);%frame number of stops (start of new stop)
    ss_trans = [ss_trans; frameStop(find(diff(frameStop) ~= 1))];%frame number for the end of stop
    rr_trans =frameRun(find(diff(frameRun) ~= 1)+1); %frame number of runs
    rr_trans = [rr_trans; frameRun(find(diff(frameRun) ~= 1))];
    
    if numel(frameStop) ~= 0
        ss_trans = [frameStop(1); ss_trans; frameStop(end)];
        ss_trans = sort(ss_trans);
    end
    if numel(frameRun) ~= 0
        rr_trans = [frameRun(1); rr_trans; frameRun(end)];
        rr_trans = sort(rr_trans);
    end
    numStop = length(ss_trans)/2; % how many stops?
    numRun = length(rr_trans)/2;
    
    %pre-allocate cell arrays
    vel_stop = cell(1,numStop);
    vel_run = cell(1,numRun);
    
    if numStop ~= 0
        
        for p=1:numStop
            vel_stop = A(ss_trans(2*p-1):ss_trans(2*p));
            vel_before_out_stop{n} = vel_stop; n=n+1;
            
        end
    end
    
    if numRun ~= 0
        
        for p=1:numRun
            vel_run = A(rr_trans(2*p-1):rr_trans(2*p));
            vel_before_out_run{m} = vel_run; m=m+1;
            
        end
    end
    
    clear ss_trans rr_trans
end
%%
%during,
%in
if sum(find(diff(vel_during_in(:,1)) ~= 1)) ~= 0 %there is at least one discontinuous point
    disc_point = find(diff(vel_during_in(:,1)) ~= 1)+1;
    disc_point = [1;disc_point];
    vel_during_in_cont = cell(length(disc_point),1);
    for i=2:length(disc_point)
        vel_during_in_cont(i-1)={vel_during_in((disc_point(i-1):disc_point(i)-1),2)};
    end
    vel_during_in_cont(end) ={vel_during_in(disc_point(end):end,2)};
else % if there is only one crossing
    vel_during_in_cont = {vel_during_in(:,2)};
end

% out
if sum(find(diff(vel_during_out(:,1)) ~= 1)) ~= 0 %there is at least one discontinuous point
    disc_point = find(diff(vel_during_out(:,1)) ~= 1)+1;
    disc_point = [1;disc_point];
    vel_during_out_cont = cell(length(disc_point),1);
    for i=2:length(disc_point)
        vel_during_out_cont(i-1)={vel_during_out((disc_point(i-1):disc_point(i)-1),2)};
    end
    vel_during_out_cont(end) = {vel_during_out(disc_point(end):end,2)};
else % if there is only one crossing
    vel_during_out_cont = {vel_during_out(:,2)};
end

%then, divide runs and stops
n=1; m=1;
for i=1:numel(vel_during_in_cont)
    A = vel_during_in_cont{i};
    frameStop = find(~A); %zero elements of A array (stops)
    frameRun = find(A);
    ss_trans = frameStop(find(diff(frameStop) ~= 1)+1);%frame number of stops (start of new stop)
    ss_trans = [ss_trans; frameStop(find(diff(frameStop) ~= 1))];%frame number for the end of stop
    rr_trans =frameRun(find(diff(frameRun) ~= 1)+1); %frame number of runs
    rr_trans = [rr_trans; frameRun(find(diff(frameRun) ~= 1))];
    
    if numel(frameStop) ~= 0
        ss_trans = [frameStop(1); ss_trans; frameStop(end)];
        ss_trans = sort(ss_trans);
    end
    if numel(frameRun) ~= 0
        rr_trans = [frameRun(1); rr_trans; frameRun(end)];
        rr_trans = sort(rr_trans);
    end
    numStop = length(ss_trans)/2; % how many stops? each stop has start+end frames
    numRun = length(rr_trans)/2;
    
    %pre-allocate cell arrays
    vel_stop = cell(1,numStop);
    vel_run = cell(1,numRun);
    
    if numStop ~= 0
        
        for p=1:numStop
            vel_stop = A(ss_trans(2*p-1):ss_trans(2*p));
            vel_during_in_stop{n} = vel_stop; n=n+1;
        end
    end
    
    if numRun ~= 0
        
        for p=1:numRun
            vel_run = A(rr_trans(2*p-1):rr_trans(2*p));
            vel_during_in_run{m} = vel_run; m=m+1;
        end
    end
    
end

%out
n=1; m=1;
for i=1:numel(vel_during_out_cont)
    A = vel_during_out_cont{i};
    if isnan(A) ~= 1
        frameStop = find(~A); %zero elements of A array (stops)
        frameRun = find(A);
        ss_trans = frameStop(find(diff(frameStop) ~= 1)+1);%frame number of stops (start of new stop)
        ss_trans = [ss_trans; frameStop(find(diff(frameStop) ~= 1))];%frame number for the end of stop
        rr_trans =frameRun(find(diff(frameRun) ~= 1)+1); %frame number of runs
        rr_trans = [rr_trans; frameRun(find(diff(frameRun) ~= 1))];
        
        if numel(frameStop) ~= 0
            ss_trans = [frameStop(1); ss_trans; frameStop(end)];
            ss_trans = sort(ss_trans);
        end
        if numel(frameRun) ~= 0
            rr_trans = [frameRun(1); rr_trans; frameRun(end)];
            rr_trans = sort(rr_trans);
        end
        numStop = length(ss_trans)/2; % how many stops?
        numRun = length(rr_trans)/2;
        
        %pre-allocate cell arrays
        vel_stop = cell(1,numStop);
        vel_run = cell(1,numRun);
        
        if numStop ~= 0            
            for p=1:numStop
                vel_stop = A(ss_trans(2*p-1):ss_trans(2*p));
                vel_during_out_stop{n} = vel_stop; n=n+1;
            end
        end
        
        if numRun ~= 0            
            for p=1:numRun
                vel_run = A(rr_trans(2*p-1):rr_trans(2*p));
                vel_during_out_run{m} = vel_run; m=m+1;
            end
        end
        
        clear ss_trans rr_trans
    end
end


%%
vel_out_stop = {vel_before_out_stop; vel_during_out_stop};
vel_out_run = {vel_before_out_run; vel_during_out_run};

vel_in_stop = {vel_before_in_stop; vel_during_in_stop};
vel_in_run = {vel_before_in_run; vel_during_in_run};
