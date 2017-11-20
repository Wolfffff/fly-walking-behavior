function crossing_plotter(i2o_before,i2o_during,i2o_after,...
    o2i_before,o2i_during,o2i_after,...
    x_range,fig_title,plotname,vel_ylim,vel_unit)

period_name = {'Before','During','After'};

%how many events?
io_before_count = size(i2o_before,2);
io_during_count = size(i2o_during,2);
io_after_count = size(i2o_after,2);

oi_before_count = size(o2i_before,2);
oi_during_count = size(o2i_during,2);
oi_after_count = size(o2i_after,2);

file_exit = dir([fig_title '_crossings.ps']);
file_count = size(file_exit,1);

fig_count = 0;
%out2in first
for i=1:3
    %decide how many subplots to draw
    if i==1 %before
    plot_count = oi_before_count;
    elseif i == 2 %during
        plot_count = oi_during_count;
    else %after
        plot_count = oi_after_count;
    end
    
    if plot_count <= 10 %if less than 10, one figure
            figure
            fig_count = fig_count +1;
            set(gcf,'Position',[300 10 700 800]);
            
            for p = 1:plot_count
                subplot(5,2,p)
                if i==1 %before
                    plot(x_range,o2i_before(:,p));hold on
                elseif i==2 %during
                    plot(x_range,o2i_during(:,p));hold on
                else %after
                    plot(x_range,o2i_after(:,p));hold on
                end
                plot([0 0],[vel_ylim(1) vel_ylim(2)],'k:');
                plot([min(x_range) max(x_range)],[0 0],'k:');
                set(gca,'box','off','xlim',[min(x_range) max(x_range)],'ylim',[vel_ylim(1) vel_ylim(2)]);

                if p==1 
                    title([fig_title ' ' plotname ': Out2in ' period_name{i}],'interpreter','none');
                end
                if p== plot_count || p == 10 %if last plot, save the figure
                    xlabel('time (sec)');
                    ylabel(vel_unit);
                    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
                    if fig_count == 1 & file_count == 0 %first figure, create ps file
                    print('-dpsc2',[fig_title '_crossings.ps']);
                    else
                         print('-dpsc2',[fig_title '_crossings.ps'],'-append');
                    end

                end
            end
    elseif plot_count >10 %if more than 10 plots, create a new figure every 10 plot
            for p = 1:plot_count
                q = rem(p,10);
                if q == 1 
                    figure
                    fig_count = fig_count +1;
                    set(gcf,'Position',[300 10 700 800]);
                                
                elseif q == 0 %10th plot
                    q = 10; %change q to 10 instead of 0
                end
                
                subplot(5,2,q)
                if i==1 %before
                    plot(x_range,o2i_before(:,p));hold on
                elseif i==2 %during
                    plot(x_range,o2i_during(:,p));hold on
                else %after
                    plot(x_range,o2i_after(:,p));hold on
                end
                plot([0 0],[vel_ylim(1) vel_ylim(2)],'k:');
                plot([min(x_range) max(x_range)],[0 0],'k:');
                set(gca,'box','off','xlim',[min(x_range) max(x_range)],'ylim',[vel_ylim(1) vel_ylim(2)]);
                
                if q ==1 
                    title([fig_title ' ' plotname ': Out2in ' period_name{i}],'interpreter','none');
                end
                
                if q == 10 || p == plot_count %if last plot, save the figure
                    xlabel('time (sec)');
                    ylabel(vel_unit);
                    set(gcf, 'PaperPositionMode', 'auto','PaperOrientation', 'portrait');
                    if fig_count == 1 & file_count == 0 %first figure, create ps file
                        print('-dpsc2',[fig_title '_crossings.ps']);
                    else
                        print('-dpsc2',[fig_title '_crossings.ps'],'-append');
                    end
                end
            end
    end
end

%In2out
for i=1:3
    %decide how many subplots to draw
    if i==1 %before
    plot_count = io_before_count;
    elseif i == 2 %during
        plot_count = io_during_count;
    else %after
        plot_count = io_after_count;
    end
    
    if plot_count <= 10 %if less than 10, one figure
            figure
            fig_count = fig_count +1;
            set(gcf,'Position',[300 10 700 800]);
            
            for p = 1:plot_count
                subplot(5,2,p)
                if i==1 %before
                    plot(x_range,i2o_before(:,p));hold on
                elseif i==2 %during
                    plot(x_range,i2o_during(:,p));hold on
                else %after
                    plot(x_range,i2o_after(:,p));hold on
                end
                plot([0 0],[vel_ylim(1) vel_ylim(2)],'k:');
                 plot([min(x_range) max(x_range)],[0 0],'k:');
                set(gca,'box','off','xlim',[min(x_range) max(x_range)],'ylim',[vel_ylim(1) vel_ylim(2)]);

                if p==1 
                    title([fig_title ' ' plotname ': in2out ' period_name{i}],'interpreter','none');
                end
                if p== plot_count || p == 10 %if last plot, save the figure
                    xlabel('time (sec)');
                    ylabel(vel_unit);
                    set(gcf, 'PaperPositionMode', 'auto');
                    if fig_count == 1 & file_count == 0 %first figure, create ps file
                    print('-dpsc2',[fig_title '_crossings.ps']);
                    else
                         print('-dpsc2',[fig_title '_crossings.ps'],'-append');
                    end

                end
            end
    elseif plot_count >10 %if more than 10 plots, create a new figure every 10 plot
            for p = 1:plot_count
                q = rem(p,10);
                if q == 1 
                    figure
                    fig_count = fig_count +1;
                    set(gcf,'Position',[300 10 700 800]);
                                
                elseif q == 0 %10th plot
                    q = 10; %change q to 10 instead of 0
                end
                
                subplot(5,2,q)
                if i==1 %before
                    plot(x_range,i2o_before(:,p));hold on
                elseif i==2 %during
                    plot(x_range,i2o_during(:,p));hold on
                else %after
                    plot(x_range,i2o_after(:,p));hold on
                end
                plot([0 0],[vel_ylim(1) vel_ylim(2)],'k:');
                 plot([min(x_range) max(x_range)],[0 0],'k:');

                set(gca,'box','off','xlim',[min(x_range) max(x_range)],'ylim',[vel_ylim(1) vel_ylim(2)]);
                
                if q ==1 
                    title([fig_title  ' ' plotname ': in2out ' period_name{i}],'interpreter','none');
                end
                
                if q == 10 || p == plot_count %if last plot, save the figure
                    xlabel('time (sec)');
                    ylabel(vel_unit);
                    set(gcf, 'PaperPositionMode', 'auto');
                    if fig_count == 1 & file_count == 0 %first figure, create ps file
                        print('-dpsc2',[fig_title '_crossings.ps']);
                    else
                        print('-dpsc2',[fig_title '_crossings.ps'],'-append');
                    end
                end
            end
    end
end