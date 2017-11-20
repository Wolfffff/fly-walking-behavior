clear all
load('120619video31 Or42b_PAR V13 variables.mat');

figure

plot(vel_total,'k'); hold on
for period = 1:3
    if period ==1
        for p = 1:length(crossing_in_before)
            plot([crossing_in_before(p),crossing_in_before(p)],[0 4],'r:');hold on

        end
        for i=1:length(crossing_out_before)
            plot([crossing_out_before(i),crossing_out_before(i)],[0 4],'b:');
        end
    end
    if period ==2
        for i = 1:length(crossing_in_during)
            plot([crossing_in_during(i),crossing_in_during(i)],[0 4],'r:');
        end
        for i=1:length(crossing_out_during)
            plot([crossing_out_during(i),crossing_out_during(i)],[0 4],'b:');
        end
    end
    if period ==3
        for i = 1:length(crossing_in_after)
            plot([crossing_in_after(i),crossing_in_after(i)],[0 4],'r:');
        end
        for i=1:length(crossing_out_after)
            plot([crossing_out_after(i),crossing_out_after(i)],[0 4],'b:');
        end
    end
end

plot(velocity_classified+2,'g');hold on
for period = 1:3
    if period ==1
        for p = 1:length(crossing_in_before)
            plot([crossing_in_before(p),crossing_in_before(p)],[0 4],'r:');hold on

        end
        for i=1:length(crossing_out_before)
            plot([crossing_out_before(i),crossing_out_before(i)],[0 4],'b:');
        end
    end
    if period ==2
        for i = 1:length(crossing_in_during)
            plot([crossing_in_during(i),crossing_in_during(i)],[0 4],'r:');
        end
        for i=1:length(crossing_out_during)
            plot([crossing_out_during(i),crossing_out_during(i)],[0 4],'b:');
        end
    end
    if period ==3
        for i = 1:length(crossing_in_after)
            plot([crossing_in_after(i),crossing_in_after(i)],[0 4],'r:');
        end
        for i=1:length(crossing_out_after)
            plot([crossing_out_after(i),crossing_out_after(i)],[0 4],'b:');
        end
    end
end
ylim([0 4]);