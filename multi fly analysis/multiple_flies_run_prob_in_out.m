% multiple_flies_run_prob_in_and_out.m
% quantify the probability of run in 'before' and 'during', 'in' and 'out'


run_length_in_flies = nan(numflies,2);
run_length_out_flies = nan(numflies,2);

stop_length_in_flies = nan(numflies,2);
stop_length_out_flies = nan(numflies,2);

%run
for fly = 1:numflies

    for period = 1:2
        run_fly = run_in_flies{fly}{period};
        clear temp
 
        for n = 1: numel(run_fly) 
            temp(n)= length(run_fly{n}); %save length of each run
        end
        run_length_fly = sum(temp); %add them up
        run_length_in_flies(fly,period) = run_length_fly; %save in a new array
        
        run_fly = run_out_flies{fly}{period};
        clear temp
        for n=1:numel(run_fly)
            
            temp(n) = length(run_fly{n});
        end
        run_length_fly = sum(temp);
        run_length_out_flies(fly,period) = run_length_fly;
    end
end

%stop
for fly = 1:numflies
    
    for period = 1:2
        stop_fly = stops_in_flies{fly}{period};
        clear temp
        for n = 1: numel(stop_fly)
            temp(n)= length(stop_fly{n});
        end
        stop_length_fly = sum(temp);
        stop_length_in_flies(fly,period) = stop_length_fly;
        
        stop_fly = stops_out_flies{fly}{period};
        clear temp
        for n=1:numel(stop_fly)
            temp(n) = length(stop_fly{n});
        end
        stop_length_fly = sum(temp);
        stop_length_out_flies(fly,period) = stop_length_fly;
    end
end

%calculate percentage of run in/out
in_length_flies =run_length_in_flies + stop_length_in_flies;%all runs
out_length_flies = run_length_out_flies + stop_length_out_flies;%all stops
period_length_flies = in_length_flies + out_length_flies;

period_length_flies2 = timeperiods(3) - odoron_frame; %to check if the calculation is correct

run_prob_in = run_length_in_flies./in_length_flies;
run_prob_out = run_length_out_flies./out_length_flies;
stop_prob_in = stop_length_in_flies./in_length_flies;
stop_prob_out = stop_length_out_flies./out_length_flies;

%mean and median
run_prob_in_mean = nanmean(run_prob_in);
run_prob_in_median = nanmedian(run_prob_in);

run_prob_out_mean = nanmean(run_prob_out);
run_prob_out_median = nanmedian(run_prob_out);

%to check if the calculation is correct (it should be all 1)
prob_in = run_prob_in + stop_prob_in;
prob_out = run_prob_out + stop_prob_out;


%stats
figure
set(gcf,'position',[200 200 800 400]);

subplot(1,2,1)
for fly = 1:numflies
    q = rem(fly,20) +1;
    plot(run_prob_in(fly,:),'.-','color',cmap(q,:));
    hold on
end
plot(run_prob_in_mean,'k*','markersize',12);
plot(run_prob_in_median,'b*','markersize',12);
xlabel('black:mean blue:median');
xlim([.5 2.5]);ylim([0 1]);
set(gca,'box','off','xtick',[],'tickdir','out');
title({fig_title; ['run probability INSIDE']});

subplot(1,2,2)
for fly = 1:numflies
    q = rem(fly,20) +1;
    plot(run_prob_out(fly,:),'.-','color',cmap(q,:));
    hold on
end
plot(run_prob_out_mean,'k*','markersize',12);
plot(run_prob_out_median,'b*','markersize',12);

xlim([.5 2.5]);ylim([0 1]);
set(gca,'box','off','xtick',[],'tickdir','out');
title('run probability OUTSIDE');

