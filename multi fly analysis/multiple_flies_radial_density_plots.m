%multiple flies radial density plots (8/16/13 SJ) this script plots radial
%density with s.d. for group data (before VS during) using
%'distribution.mat' files. (in cm, not bin#)

%make sure that you make new distribution.mat file using the newer analysis
%V22 mat file that uses in_x = numvals_pi_ori instead of numvals_pi! (this
%was changed on 8/16/13)
% since numvals_pi changes according to inner_radius_bigger variable, bin #
% 10 could be 1.2, 1.5 or 1.9 etc. and bin_radius will incorrectly.
% From now on, calculate bin# = 1.2 cm always.


%%
%type in genotypes of flies
genotype = {'WT'};
%type in odor names
odor = {'PAR','water'};

%un-abbreviated odor names in case it is necessary
odor_long = {'paraffin oil','water'};


%how many groups?
groupNo = length(genotype)*length(odor);
%make cell array to save all the group data
groupData = cell(groupNo,1);

groupName = cell(1,groupNo);

distData = cell(groupNo,2);
distCMdata = cell(groupNo,1);
distDataMod = cell(groupNo,2);
distCMdataMod = cell(groupNo,1);

%find out how many bins are used (look at the first file)
filename = [genotype{1} ' ' odor{1} 'distribution.mat'];
load(filename);
binNo=size(Bin2Cm,2);

distMedian = nan(groupNo,binNo-1,2);%3D arrays for bef/dur
distSD = nan(groupNo,binNo-1,2);%3D arrays for bef/dur
distSEM = nan(groupNo,binNo-1,2);%3D arrays for bef/dur

n=0;
for i=1:length(genotype);
    for j=1:length(odor);
        n=n+1;
        mainfilename=[genotype{i} ' ' odor{j}];
        groupName{n} = mainfilename;
        %load variables in distribution file
        distfile = [mainfilename 'distribution.mat'];
        load(distfile);
        for p = 1:2 % 'before' and 'during' data
            distData{n,1} = distributionAll(:,:,1); %before
            distData{n,2} = distributionAll(:,:,2); %during
        end
        distCMdata{n} = Bin2Cm;%corresponding distance from the center(cm)
        
        flyNo = size(distData{n,1},1);
        binNo = size(distData{n,1},2);
        
        %modify distCMdata so that there is no NaN
        temp = distCMdata{n}; %fly's distribution,distance from center(cm)
        temp1 = temp(:,1:end-1);
        temp1(:,end) = 3.2; % last bin is always 3.2cm (outer rim)
        distCMdataMod{n} = temp1;
        
        
        %since the total bin # varies (only by 1), I will add last bin +
        %one before together
        for p=1:2 %before and during
            temp = distData{n,p}; %fly's before or during distribution
            temp1 = temp(:,1:end-1); %copy excluding the last column
            temp1(:,end)= nansum(temp(:,end-1:end),2);%adding the last two bins
            
            distDataMod{n,p} = temp1;
            %get median value of distribution
            distMedian(n,:,p) = (median(temp1));
            %sd values
            distSD(n,:,p) = std(temp1);
            distSEM(n,:,p) = std(temp1)/sqrt(flyNo);
        end
    end
end


%% plots radial density plot
%shows distribution

%color
grb = [0 1 0; 1 0 0; 0 0 1];

figure
set(gcf,'Position',[100 10 800 800]);

for i = 1:groupNo
    subplot(4,1,i)
    for p = 1:2 %before and during
        SEM_y_plot= [distMedian(i,:,p)-distSEM(i,:,p);2*distSEM(i,:,p)];
        h = area(distCMdataMod{i}(1,:),SEM_y_plot');
        set(h(1),'visible','off');
        set(h(2),'FaceColor',grb(p,:),'EdgeColor','none');
        alpha(.15);
        hold on
        plot(distCMdataMod{i}(1,:),distMedian(i,:,p),'color',grb(p,:),'linewidth',2);
    end
    plot([1.2 1.2],[0 1],'k:');
    xlim([.24,3.2]);
    ylim([0,0.3])
    set(gca,'box','off','tickdir','out');
    title(groupName{i});
end

%%
png_name = horzcat(groupName{:});
set(gcf,'PaperPositionMode','auto'); 
set(gcf,'paperorientation','portrait');
print(gcf,'-dpdf','-r300',[png_name ' rad_dist' ' ' date '.pdf']);


