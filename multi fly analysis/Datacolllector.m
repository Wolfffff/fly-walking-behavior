%% High-dimensional representation of behaviors.
%Each fly is a 2D matrix. Different odors in the 3rd dimension.
% Parameters
% 1. time inside
% 2. time inside/transit
% 3. redisovery time
% 4. radial density
% 5. velocity inside
% 6. velocity outside
% 7. angular velocity inside
% 8. angular velocity outside
% 9. fraction time curve walking inside
%10.  fraction time fraction time curve walking inside
%11.  radial distribution of sharp turn
%12.  sharp turn frequency
%13. run prob crossing in
%14. run prob crossing out
%15, run prob 1st time in
%16. fractional time running inside
%17. fraction time running outside
%18. median run duration
%19. median stop duration
%20.meadian vel of run
%21. run velocity crossing in
%22. vrun velocity crossing out

clear all
close all

%genotype={'WT' 'Or42b'};
genotype={'WT'};
% genotype={'Or42b'};

%odor ={'ETA8' 'ETA7' 'ETA6' 'ETA4' 'BUN3' 'BUN4' 'BUN5' 'ACV0' 'ACV1' 'ACV2' 'ACV3' 'ACV4'};
%odor ={ 'ETA6'  'BUN4' 'ETA6BUN4'};
odor ={ 'PAR'  };

for i=1:length(genotype);
    for j=1:length(odor);
        mainfilename=[genotype{i} ' ' odor{j}];
        anglefilename=[mainfilename '_angular_velocity.mat'];
        runstopfilename=[mainfilename '_runhist.mat'];
        radialfilename=[mainfilename '_radialturn.mat'];
        
        % a=dir([mainfilename ' V22*.mat']); %this doesn't work when there are
        % multiple V22***.mat files!
        % filename=a.name;
        
        filename = uigetfile([mainfilename ' V22*.mat'],'Select the mat file that you want to use');
        maindata=load(filename);
        angledata=load(anglefilename);
        runstopdata=load(runstopfilename);
        radialdata=load(radialfilename);
        %WT_BUN3=load('WT BUN3 V21biggerIR19 20-Feb-2013.mat');
        %WT_BUN3_angular=load('WT BUN3_angular_velocity.mat');
        %time inside; avg_vel_in; vel_out; ang. vel; run probin;
        
        data=NaN(17,maindata.numflies);
        %WT_BUN3data=NaN(100,numflies);
        % parameter 1 = time inside
        data(1,:)=(maindata.time_in_flies(:,2)-maindata.time_in_flies(:,1));
        
        % parameter 2= time inside/transit
        data(2,:)=(maindata.median_time_in_transit_flies(:,2)-maindata.median_time_in_transit_flies(:,1))./(maindata.median_time_in_transit_flies(:,1));
        
        %parameter 3= recovery time
        data(3,:)= (maindata.median_time_out_transit_flies(:,2)-maindata.median_time_out_transit_flies(:,1))./maindata.median_time_out_transit_flies(:,1);
        
        % radial density
        [C,I]=max(maindata.bin_probability_during,[],2);
        data(4,:)=I;
        
        %Velocity inside
        data(5,:)=maindata.total_avg_vel_in_flies(:,2)./maindata.total_avg_vel_in_flies(:,1);
        
        %velocity outside
        data(6,:)=maindata.total_avg_vel_out_flies(:,2)./maindata.total_avg_vel_out_flies(:,1);
        
        %angular velocity inside
        data(7,:)=angledata.data.angular_velocity_during_in./angledata.data.angular_velocity_before_in;
        
        %angular velocity outside
        data(8,:)=angledata.data.angular_velocity_during_out./angledata.data.angular_velocity_before_out;
        
        % run probability inside
        data(9,:)=maindata.run_prob_in(:,2)./maindata.run_prob_in(:,1);
        
        % run probability outside
        data(10,:)=maindata.run_prob_out(:,2)./maindata.run_prob_out(:,1);
        
        % run duration
        data(11,:)=runstopdata.rundata.runduration_secs_fly(:,2)./runstopdata.rundata.runduration_secs_fly(:,1);
        
        % stop duration
        data(12,:)=runstopdata.rundata.stopduration_secs_fly(:,2)./runstopdata.rundata.stopduration_secs_fly(:,1);
        
        % curv walk in
        data(13,:)=radialdata.radial.curv_fr_in_flies(2,:)./radialdata.radial.curv_fr_in_flies(1,:);
        
        % curv walk out
        data(14,:)=radialdata.radial.curv_fr_out_flies(2,:)./radialdata.radial.curv_fr_out_flies(1,:);
        
        % sharp turn at border
        data(15,:)=radialdata.radial.turnduring(:,2);
        
        % velocity crossing in
        before=nanmean(maindata.velocity_o2i_ind_avg_dr(1:60,:));
        during=nanmean(maindata.velocity_o2i_ind_avg_dr(90:150,:));
        data(16,:)=(during-before)./before;
        
        % velocity crossing out
        before=nanmean(maindata.velocity_i2o_ind_avg_dr(1:60,:));
        during=nanmean(maindata.velocity_i2o_ind_avg_dr(90:150,:));
        data(17,:)=(during-before)./before;
        
        filename=[mainfilename 'data.mat'];
        save([filename],'data');
        
        % radial density : median of whole distribution        
        %median
        distribution(1,:) = nanmedian(maindata.bin_probability_before);
        distribution(2,:)= nanmedian(maindata.bin_probability_during);
        
        %bin# to cm conversion
        %there is slight differences in length of vectors
        temp = maindata.bin_radius_flies;
        %transpose cell array
        FlyNo = size(temp,2);
        for p = 1:FlyNo
            temp2(p,1) = temp(1,p);
            BinNo(p) = length(temp{p});
        end
        %cell to array
        %first check how long each vectors are
        maxBin = max(BinNo);
        Bin2Cm = NaN(FlyNo,maxBin);
        distributionAll = NaN(FlyNo,maxBin,2); % to save whole distribution data, 3D matrix
        distributionAll(:,:,1) = maindata.bin_probability_before;
        distributionAll(:,:,2) = maindata.bin_probability_during;
        
        for p = 1:FlyNo
            Bin2Cm(p,1:BinNo(p)) = temp2{p};        %whole data
        end
        

        
        filename=[mainfilename 'distribution.mat'];
        save([filename],'distribution','distributionAll','Bin2Cm');
        
        
    end;
end;