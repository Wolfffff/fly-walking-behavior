%for NoAirNoVac etc controls, plot Ti together
clear all
%type in group names
GroupName ={'NoAirNoVac','AirVac','WT water','WT PAR'};
GroupNo = length(GroupName);
fraction_in = cell(GroupNo,1);
fraction_in_median = zeros(GroupNo,1);

%get file, save Ti variables
for i = 1:GroupNo
    filename = uigetfile(['*V22*.mat'],'Select the mat file that you want to use');
    maindata=load(filename);
    fraction_in(i)= {maindata.fraction_in};
    fraction_in_median(i) = median(fraction_in{i});
    
    if i ==1
        inner_radius_bigger = maindata.inner_radius_bigger;
        outer_radius = maindata.outer_radius;
    end
end

%%
figure

set(gcf,'position',[400 500 GroupNo*150+200 400]);

%calculated fraction inside from area of odor zone
predicted=(inner_radius_bigger^2)/(outer_radius^2);
%color
cmap=[0.5781  0  0.8242;
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

subplot(1,4,[1 3])
for i = 1: GroupNo
    
    plot(i,fraction_in{i},'o','color',cmap(i,:));
    hold on
    plot(i,fraction_in_median(i),'k+','markersize',14);
end

plot([.5 GroupNo+.5],[predicted predicted],':','color',[.5 .5 .5]);

ylim([0 1]);
xlim([.5 GroupNo+.5]);

set(gca,'box','off','tickdir','out','ytick',[0:.2:1],'xtick',[])
set(gca,'Xtick',[1:GroupNo],'XTickLabel',GroupName,'fontsize',10);

title(['Total fraction inside: IR=' num2str(inner_radius_bigger)],'fontsize',15);

subplot(1,4,4)
for i = 1:GroupNo
    t=text(.1,100-10*i, [GroupName{i} ': n =' num2str(length(fraction_in{i}))],'Color','k');
    hold on
end
ylim([0 100]);
set(gca,'box','off','ytick',[],'xtick',[],'XColor',[1 1 1],'YColor',[1 1 1])


png_name = horzcat(GroupName{:});
set(gcf,'PaperPositionMode','auto'); 
set(gcf,'paperorientation','landscape');
print(gcf,'-dpdf','-r300',[png_name  ' IR' num2str(inner_radius_bigger) ' Ti ' date '.pdf']);
