
Ti_WT0 = median(WT(1,:));
Ti_HU = median(HU(1,:)); 
% Ti_Orco0 = median(Orco(1,:));
% Ti_antcut = median(antcutOrco(1,:));

% Ti_WT3 = median(WT3(1,:));
% Ti_Orco3 = median(Orco3(1,:));

% y = [Ti_WT0,Ti_Orco0,Ti_antcut];
y = [Ti_WT0,Ti_HU];
    
figure

b=bar(y);hold on
set(b,'FaceColor',[1 1 1]);

plot(1,WT(1,:),'bo');hold on
plot(2,HU(1,:),'ro');
% plot(2,WT0(1,:),'bo');
% plot(2,Orco(1,:),'ro');hold on
% plot(3,antcutOrco(1,:),'ro');

xlim([0 3])
ylim([-.4 1]);
set(gca,'Box','off','TickDir','out','Ytick',(-1:0.2:1),'fontsize',14);
% set(gca,'XTickLabel',{'WT ACV0','Orco ACV0','antenna cut Orco ACV0'})
set(gca,'XTickLabel',{'WT ACV0','HU ACV0'});
    
t = title('Total time inside (0 = no change)');
set(t,'fontsize',15)

%%
Ti_IROR = median(IROR);
Ti_WT0 = median(WT(1,:));
Ti_antcut = median(antcut(1,:));
Ti_Orco0 = median(Orco(1,:));

y = [Ti_WT0,Ti_Orco0,Ti_antcut,Ti_IROR];


figure
b = bar(y); hold on
set(b,'FaceColor',[1 1 1]);
plot(1,WT(1,:),'bo');
plot(2,Orco(1,:),'ro');
plot(3,antcut(1,:),'go');
plot(4,IROR,'mo');

xlim([0 5])
ylim([-.4 1]);
set(gca,'Box','off','TickDir','out','Ytick',(-1:0.2:1),'fontsize',14);
set(gca,'XTickLabel',{'WT','ORco','ant-cut ORco','IR8a-ORc'})

t = title('ACV0: Total time inside (0 = no change)');
set(t,'fontsize',15)
