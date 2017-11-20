%multiple_flies_curv_turn_periods.m

%compare how curvature changes in 'before' VS 'during'

%pre-allocate arrays to save the starts of turns divided into 'before' and 'during'
turn_time_bef = cell(numflies,1);
turn_time_dr = cell(numflies,1);

turn_fr_bef = cell(numflies,1);
turn_fr_dr = cell(numflies,1);

figure
set(gcf,'position',[100 10 800 800]);

for period = 1:2
    for fly = 1:numflies

        q = rem(fly,20)+1;%to assign different colors
        
        %==================================================================
        %abs of cumulative sum of curvature
        totalcurv = (totalturn_flies(:,fly));
        
        subplot(4,2,period)
        %get the start and end of period (frame #)
        if period ==1 %before
            periodst = timeperiods(1); periodend = timeperiods(2);
            title({fig_title;['abs(cumulative sum of curvature)']});
        elseif period == 2 %during
            periodst = odoron_frame(fly); periodend = timeperiods(3);
        end
        
        curvchange = totalcurv(periodst:periodend);
        curvchange = curvchange - curvchange(1); %to make the baseline = 0
        abs_curv = abs(curvchange);
        x_time = (periodst:periodend)/(framespertimebin*60);%time in 'min'
        
        plot(x_time,abs_curv,'color',cmap(q,:));
        hold on
        
        xlim([(period-1)*3 (period-1)*3+3]);
        ylim([0 100]);

        
        %==================================================================
        
        subplot(4,2,period+2)

        %abs of cumulative sum of (curvature)/turn
        turn_curve = (turn_curvewalk_flies{fly}); %turn_curvewalk_flies: cumsum(curv_long_CV_totalturn)
        %cumulative sum of curvature in turns : all + instead of +/-
        turn_abscurv  = (curv_absturn_flies{fly});%curv_absturn_flies:abs(curv_long_CV_totalturn), not cumsum
        turn_abscum = cumsum(turn_abscurv); %cumulative sum of each turns

        %time of turn (start of turns)
        turn_time = curv_time_flies{fly}; % second
        
        %dividing them into before and during
        if period ==1 %before
            time_per = (turn_time < (periodend/framespertimebin));
            turn_curve_per = turn_curve(time_per);
            turn_curv_abs = abs(turn_curve_per);%sum up +/- together 
            turn_abscurv = turn_abscum(time_per);%sum +
            x_time = turn_time(time_per)/60; %min
            turn_time_bef(fly) = {turn_time(time_per)}; %save the times in arrays
            turn_fr_bef(fly) = {time_per}; %save the frame # in arrays
            title('abs(cumulative sum of curvature in turns)');

        elseif period ==2 %during
            time_per1 = find(turn_time >= (periodst/framespertimebin));
            time_per2 = find(turn_time < (periodend/framespertimebin));
            time_per = intersect(time_per1,time_per2);
            turn_curve_per = turn_curve(time_per);
            turn_curve_per = turn_curve_per - turn_curve_per(1); %to make the baseline= 0
            turn_curv_abs = abs(turn_curve_per);
            turn_abscurv = turn_abscum(time_per);%sum +
            turn_abscurv = turn_abscurv - turn_abscurv(1); % to make the baseline = 0

            x_time = turn_time(time_per)/60; %min
            x_time = x_time -x_time(1)+3; %to make them all start at the same time
            turn_time_dr(fly) = {turn_time(time_per)};%sec
            turn_fr_dr(fly) = {time_per};
        end
        
        plot(x_time,turn_curv_abs,'color',cmap(q,:));
        hold on
        
        xlim([(period-1)*3 (period-1)*3+3]);
        ylim([0 100]);

        
        %==================================================================
        %cumsum of curvature/turns (all +)
        
        subplot(4,2,period+4)
        if period ==1
            plot(turn_time_bef{fly}/60,turn_abscurv,'color',cmap(q,:));
            
            title('cum sum of abs(sum(curvature in turns))');
        elseif period ==2
            ttime = turn_time_dr{fly}/60;
            ttime = ttime - ttime(1) + 3; %to make them all start at the same time
            plot(ttime,turn_abscurv,'color',cmap(q,:));
        end
        hold on
        
        xlim([(period-1)*3 (period-1)*3+3]);
        ylim([0 500]);
       

        %==================================================================
        %reorientation
        subplot(4,2,period+6)

        reori = turn_reorientation_flies{fly};
        reori_time = reori_time_flies{fly}; %frame #
        
        if period == 1 %before
            time_per = (reori_time < periodend);
            reori_per = reori(time_per);
            x_time = reori_time(time_per)/(framespertimebin*60);%sec
            
            title('reorientation');
            
        elseif period == 2 %during
            time_per1 = find(reori_time >= periodst);
            time_per2 = find(reori_time < periodend);
            time_per = intersect(time_per1,time_per2);
            reori_per = reori(time_per);
            reori_per = reori_per - reori_per(1); %to make the baseline = 0
            x_time = reori_time(time_per)/(framespertimebin*60);%sec
            x_time = x_time -x_time(1)+3; %to make them all start at the same time

        end
        
        plot(x_time,reori_per,'color',cmap(q,:));
        hold on
        
        xlim([(period-1)*3 (period-1)*3+3]);
        ylim([-40 40]);

    
    end
end

%%
%time between turns 1. beginning of turns 2. time in between turns


%before
%make an array to save data from all flies
a=0;
for fly = 1:numflies
diff_turn = diff(turn_time_bef{fly}); %turn interval: time between beginning of turns (sec)
turnIntbef(a+1:a+length(diff_turn)) =  diff_turn;

%time between turns (between the end of first turn and the start of next
%turn)
timebw = time_bw_turns_flies{fly};
timebwbef = timebw(1:length(turn_time_bef{fly})-1); %# time between turns  = total turns -1
turnBWbef(a+1:a+length(diff_turn)) = timebwbef;

a = a+ length(diff_turn);

end

%histogram
botEdge = 0;
topEdge = 2;
NoBar = 20;
x=linspace(botEdge,topEdge,NoBar);
A = hist(turnIntbef,x);
histbef = A/length(turnIntbef); %proportion rather than actual number of incidents

B = hist(turnBWbef,x);
histBWbef = B/length(turnBWbef);


%during
a=0;
for fly = 1:numflies
diff_turn = diff(turn_time_dr{fly}); %turn interval: time between turns (sec)
turnIntdr(a+1:a+length(diff_turn)) =  diff_turn;

%time between turns (between the end of first turn and the start of next
%turn)
timebw = time_bw_turns_flies{fly};
timebwdr = timebw(turn_fr_dr{fly}(2:end));
turnBWdr(a+1:a+length(diff_turn)) = timebwdr;

a = a+ length(diff_turn);
end

A = hist(turnIntdr,x);
histdr = A/length(turnIntdr);

B = hist(turnBWdr,x);
histBWdr = B/length(turnBWdr);

figure

subplot(1,2,1)
stairs(x - (topEdge - botEdge)/NoBar/2, histbef,'color','g'); hold on
stairs(x-(topEdge - botEdge)/NoBar/2, histdr,'color','r');

xlim([botEdge topEdge]);

title('time between turns (start of turns)');

subplot(1,2,2)
stairs(x - (topEdge - botEdge)/NoBar/2, histBWbef,'color','g'); hold on
stairs(x-(topEdge - botEdge)/NoBar/2, histBWdr,'color','r');

xlim([botEdge topEdge]);
title('time between turns (in between turns)');
