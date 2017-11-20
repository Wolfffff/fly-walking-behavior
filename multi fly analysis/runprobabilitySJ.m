function [ll, in2outrunstops, out2inrunstops]...
    = runprobabilitySJ (in2outbefore,in2outduring,in2outafter,...
    out2inbefore,out2induring,out2inafter, framespertimebin,fig_title,timebefore,totaltime)

%calculates run probability and plots
% in2outrunstops = {vel_clsf_in2out_before,vel_clsf_in2out_during,vel_clsf_in2out_after};
% 
% out2inrunstops = {vel_clsf_out2in_before, vel_clsf_out2in_during,vel_clsf_out2in_after};

in2outrunstops = {in2outbefore, in2outduring, in2outafter};

out2inrunstops = {out2inbefore, out2induring, out2inafter};
% %==========================================================================
vector_length = totaltime*framespertimebin;
%calculate probability
for period = 1:3
    for hh = 1:vector_length; 
        a(hh,:) = in2outrunstops{period}(hh,:);%go through row-by-row (frame)
        probabilityin2out{period}(hh) = (nansum(a(hh,:)>0)/sum(~isnan(a(hh,:))));
        %calculate how many runs(not 0 in velocity_classified/all events)        
        aa(hh,:) = out2inrunstops{period}(hh,:);
        probabilityout2in{period}(hh) = (nansum(aa(hh,:)>0)/sum(~isnan(aa(hh,:))));
    end
    
    clear a
    clear aa
end

figure
set(gcf,'color','white','Position',[520 82 997 716]);
for period = 1:3;
    subplot(3,2,2*period-1)
    plot(probabilityout2in{period})
    hold on
    xlabel('frame number','fontsize',9);
    ylabel('run probability','fontsize',9);
    set(gca,'Box','off','Xtick',(0:30:300),'fontsize',8);
    xlim ([0 totaltime*framespertimebin])  %2 sec before crossing + 5 sec after crossing
    ylim ([0 1.3])
    plot([timebefore*framespertimebin+1 timebefore*framespertimebin+1],[0 1.3],'k:') %dotted line marking 0 (crossing)
    if period==1
        title([fig_title ' run probability crossing in'],'interpreter','none','fontsize',10);
    end
    
    hold off
    
    %
    % %for crossing in2out
    subplot(3,2,period*2)
    
    plot(probabilityin2out{period})
    xlabel('frame number','fontsize',9);
    ylabel('run probability','fontsize',9);
    set(gca,'Box','off','Xtick',(0:30:300),'fontsize',8);
    hold on
    
    xlim ([0 totaltime*framespertimebin])  %2 sec before crossing + 5 sec after crossing
    ylim ([0 1.3])
    plot([timebefore*framespertimebin+1 timebefore*framespertimebin+1],[0 1.3],'k:') %dotted line marking 0
    if period ==1
        title('run probability crossing out','fontsize',10);
    end
    
    hold off
end
ll = gcf;


% saveas(gcf, [fig_title '_runprobability.png']);

