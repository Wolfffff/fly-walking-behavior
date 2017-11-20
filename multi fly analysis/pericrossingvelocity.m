function [jj, velocitytoplot_out2in, velocitytoplot_in2out] = pericrossingvelocity (vel_total, crossing_in_cell, crossing_out_cell, timeperiods)
frames = 30;
%% Pre-allocating crossing matrices
for a = 1:3
    b(a) = length(crossing_in_cell{a});
    c(a) = length(crossing_out_cell{a});
end
lengthin = max(b); %find the timeperiod with the most crossings
lengthout= max(c);
%
 velocitytoplot_out2in = cell(3, lengthin);
 velocitytoplot_in2out = cell(3,lengthout);
% velocitytoplotfinal_out2in = cell(3, lengthin);
% velocitytoplotfinal_in2out = cell(3, lengthout);

for period = 1:3
    
    if crossing_in_cell{period,1}(1) < crossing_out_cell{period,1}(1) ;
        display ('fly is going in first')
        if numel(crossing_in_cell{period,1}) > numel(crossing_out_cell{period});
            crossing_out_cell{period,1}(end+1) = timeperiods(period+1);
            display ('make crossing out time the end of the odorperiod')
        end
        
        for h = 1;
            try
                if  crossing_in_before(1) < 2*frames %if there is less than 2 sec before the first crossing in the before period
                    nannumber = 60 - (crossing_in_cell{period}(h)-(1));%how many nans will it take to make this vector the same length?
                    sizetoplot = length((vel_total(1:((crossing_out_cell{period}(h))))));
                    velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h-1)+1):((crossing_out_cell{period}(h))))); %just take the portion that is outsid
                else
                    nannumber = 0;%how many nans will it take to make this vector the same length?
                    sizetoplot = length((vel_total((crossing_in_cell{period}(h)-60):((crossing_out_cell{period}(h))))));
                    velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_in_cell{period}(h)-60):((crossing_out_cell{period}(h))))); %just take the portion that is outside
                end
            catch
            end
        end
        
        for h = 2:length(crossing_in_cell{period});
            if crossing_in_cell{period}(h)-(2*frames) < crossing_out_cell{period}(h-1); %if 2 seconds before the crossing in is before the last crossing ou
                nannumber = 60 - (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h-1)+1));%how many nans will it take to make this vector the same length?
                sizetoplot = length((vel_total((crossing_out_cell{period}(h-1)+1):((crossing_out_cell{period}(h))))));
                velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h-1)+1):((crossing_out_cell{period}(h))))); %just take the portion that is outside
                
            else
                nannumber = 0; %how many nans will it take to make this vector the same length?
                sizetoplot = length((vel_total((crossing_in_cell{period}(h)-60):((crossing_out_cell{period}(h))))));
                velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_in_cell{period}(h)-60):((crossing_out_cell{period}(h))))); %just take the portion that is outside
            end
        end
        
        for h = 1:(length(crossing_out_cell{period})-1);
            if crossing_out_cell{period}(h)-(2*frames) < crossing_in_cell{period}(h); %if 2 seconds before the crossing out is before the last crossing in
                nannumber = 60 - (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h)+1));%how many nans will it take to make this vector the same length?
                sizetoplot = length((vel_total((crossing_in_cell{period}(h)+1):((crossing_in_cell{period}(h+1))))));
                velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_in_cell{period}(h)+1):((crossing_in_cell{period}(h+1))))); %just take the portion that is outside
            else
                nannumber = 0;%how many nans will it take to make this vector the same length?
                try
                    sizetoplot = length((vel_total((crossing_out_cell{period}(h)-60):((crossing_in_cell{period}(h+1))))));
                    velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h)-60):((crossing_in_cell{period}(h+1))))); %just take the portion that is outside
                catch
                    sizetoplot = length((vel_total((crossing_out_cell{period}(h)-60):length(vel_total))));
                    velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h)-60):length(vel_total))); %just take the portion that is outside
                end
            end
        end
    else
        display('fly is coming out first');
        
        if numel(crossing_in_cell{period}) > numel(crossing_out_cell{period})
            crossing_out_cell{period}(end+1)= timeperiods(period+1);
            display('making crossing out time the end of the odorperiod');
        end
%         in2outf(b) = crossing_in_cell{period}(b)-crossing_out_cell{period}(b);
    end
    for h = 1;
        try
            if  crossing_out_before(1) < 2*frames %if there is less than 2 sec before the first crossing in the before period
                nannumber = 60 - (crossing_out_cell{period}(h)-(1));%how many nans will it take to make this vector the same length?
                sizetoplot = length((vel_total(1:((crossing_in_cell{period}(h))))));
                velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((1):((crossing_in_cell{period}(h))))); %just take the portion that is outside
                
            else
                nannumber = 0;%how many nans will it take to make this vector the same length?
                sizetoplot = length((vel_total((crossing_out_cell{period}(h)-60):((crossing_in_cell{period}(h))))));
                velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h)-60):((crossing_in_cell{period}(h))))); %just take the portion that is outside
                
            end
        catch
        end
    end
    
    for h = 1:length(crossing_in_cell{period});
        %             if crossing_in_cell{period}(h) -crossing_out_cell{period}(h) ~= 1;
        
        if crossing_in_cell{period}(h)-(2*frames) < crossing_out_cell{period}(h); %if 2 seconds before the crossing in is before the last crossing ou
            nannumber = 60 - (crossing_in_cell{period}(h)-(crossing_out_cell{period}(h)));%how many nans will it take to make this vector the same length?
            try
                sizetoplot = length((vel_total((crossing_out_cell{period}(h)+1):((crossing_out_cell{period}(h+1))))));
                velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h)+1):((crossing_out_cell{period}(h+1))))); %just take the portion that is outside
                
                
            catch
                
                sizetoplot = length((vel_total((crossing_out_cell{period}(h)+1):length(vel_total))));
                velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h)+1):length(vel_total))); %just take the portion that is outside
                
            end
        else
            
            nannumber = 0; %how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_in_cell{period}(h)-60):((crossing_out_cell{period}(h+1))))));
            velocitytoplot_out2in{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_in_cell{period}(h)-60):((crossing_out_cell{period}(h+1))))); %just take the portion that is outside
            
            
        end
        
        
    end
    
    for h = 2:length(crossing_out_cell{period})-1;
        if crossing_out_cell{period}(h)-(2*frames) < crossing_in_cell{period}(h-1); %if 2 seconds before the crossing out is before the last crossing in
            %             velocitytoplot_in2out{period, h} = nan(timeperiods(2)-timeperiods(1),1);
            nannumber = 60 - (crossing_out_cell{period}(h)-(crossing_in_cell{period}(h-1)+1));%how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_in_cell{period}(h-1)+1):((crossing_in_cell{period}(h))))));
            velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_in_cell{period}(h-1)+1):((crossing_in_cell{period}(h))))); %just take the portion that is outside
            
            
        else
            
            nannumber = 0;%how many nans will it take to make this vector the same length?
            sizetoplot = length((vel_total((crossing_out_cell{period}(h)-60):((crossing_in_cell{period}(h))))));
            velocitytoplot_in2out{period, h}(nannumber+1:nannumber+1+sizetoplot-1,1) = (vel_total((crossing_out_cell{period}(h)-60:((crossing_in_cell{period}(h)))))); %just take the portion that is outside
            
            
        end
        
    end
    
end



cmap=[0.5781  0         0.8242;
    0.5451    0.5373    0.5373;
    1.0000    0.6471         0
    0         0.8078    0.8196;
    1         .02       0.2;
    0.3922    0.5843    0.9294;
    0.1961    0.8039    0.1961;
    0.9000    0.6471         0;
    0.5176    0.4392    1.0000;
    0.4196    0.5569    0.1373;
    0.7216    0.5255    0.0431;
    0.2745    0.5098    0.7059;
    0.4000    0.8039    0.6667;
    0.9333    0.7961    0.6784;
    0.6471    0.1647    0.1647;
    0         0.7490    1.0000;
    0.8588    0.4392    0.5765;
    0.5765    0.4392    0.8588;
    0.9804    0.5020    0.4471;
    0.5137    0.5451    0.5137];


figure
set(gcf,'color','white','Position',[520 82 997 716]);
jj =gcf;
for period = 1:3;
    %for crossing out2in
    subplot(3,2,period*2-1)
    %         subplot(5,1,1)
    for h = 1:length(crossing_in_cell{period});
        if h <= 20
            plot (velocitytoplot_out2in{period, h} ,'color', cmap(h,:))
        else
            plot (velocitytoplot_out2in{period, h} ,'color', cmap(h-20,:))
        end
        hold on
        xlim ([0 3*frames]) %2 sec before crossing + 5 sec after crossing
        ylim ([0 2])
        plot([2*frames+1 2*frames+1],[0 2],'k:') %dotted line marking 0
        title('Crossing in','fontsize',9);
        xlabel('frame number','fontsize',9);
        ylabel('velocity(cm/sec)','fontsize',9);
        set(gca,'Box','off','Xtick',(0:30:300),'fontsize',8);
    end 
        
        
        
        %for crossing in2out
        subplot(3,2,period*2)
        for h = 1:length(crossing_out_cell{period})-1;
            if h <= 20
                plot (velocitytoplot_in2out{period, h} ,'color', cmap(h,:))
            else
                plot (velocitytoplot_in2out{period, h} ,'color', cmap(h-20,:))
            end
            hold on
            xlim ([0 3*frames])  %2 sec before crossing + 5 sec after crossing
            ylim ([0 2])
            plot([2*frames+1 2*frames+1],[0 2],'k:') %dotted line marking 0
            plot([76 76],[0 2],'k:')
            title('Crossing out ','fontsize',9);
            xlabel('frame number','fontsize',9);
            ylabel('velocity(cm/sec)','fontsize',9);
            set(gca,'Box','off','Xtick',(0:30:300),'fontsize',8);
            
        end
        
    end
    ax = axes('position',[0,0,1,1],'visible','off');
    tx = text(0.3,0.97,[ 'velocity at crossing events']);
    set(tx,'fontweight','bold');

    set(gcf, 'PaperPositionMode', 'auto');
    saveas(gcf, ['pericrossingvelocityplot.png']);
    
   